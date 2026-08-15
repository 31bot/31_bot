require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'openssl'
require 'yaml'
require 'time'
require 'aws-sdk-s3'

# 31bot script ver 1.5

# 1.5
# Misskey.ioに対応

# 1.02
# twitterでは読みを削除

# 1.01
# twittrでは140文字以内、bskyではそれ以上の文字数が可能に設定

def redact_for_log(value, secrets)
  redacted = value.to_s.dup.force_encoding("UTF-8")
  secrets.compact.reject { |secret| secret.to_s.empty? }.each do |secret|
    redacted.gsub!(secret.to_s, "[REDACTED]")
  end
  redacted.gsub!(/("(?:accessJwt|refreshJwt|access_token|token|password|authorization)"\s*:\s*")[^"]*(")/i, '\1[REDACTED]\2')
  redacted.gsub!(/Bearer\s+[^\s",}]+/i, "Bearer [REDACTED]")
  redacted
end

def lambda_handler(event:, context:)
  
  puts "31bot Script を開始します……"
  
  #### AWS S3からデータを得る
  puts "S3に接続します"
  s3_client = Aws::S3::Client.new(region: "ap-northeast-1")
  
  # S3のバケット名を指定
  bucket_name = '31bot'
  
  file_list = []
  
  puts bucket_name
  
  puts "バケットの中身を取り出します"
  # 配列にS3 バケットの中身(ファイルのリスト)を格納
  s3_client.list_objects(:bucket => bucket_name).contents.each do |object|
    file_list << object.key if object.key.match?(/\.ya?ml\z/i)
  end
  
  puts file_list.to_s
  
  if file_list.empty?
    puts "投稿候補がありません: S3オブジェクト=(なし), 理由=.ymlまたは.yamlのオブジェクトがありません"
    return false
  end

  # バケットの中身(ファイルのリスト)からランダムにファイルを指定、中身を取り出す
  selected_key = file_list.sample
  file_body = s3_client.get_object(:bucket => bucket_name, :key => selected_key).body
  
  puts file_body
  
  ### 投稿文生成
  # バケットの中身がYAMLファイルなので、Rubyのオブジェクトに変換する
  begin
    yamlbody = YAML.load(file_body)
  rescue Psych::SyntaxError => e
    puts "YAML構文エラー: S3オブジェクト=#{selected_key}, エラー=#{e.message}"
    return false
  end

  required_fields = ["source", "number", "詞書(現代訳)", "歌", "author"]
  candidates = (yamlbody.is_a?(Array) ? yamlbody : []).each_with_object([]) do |record, matches|
    next unless record.is_a?(Hash)
    next unless required_fields.all? { |field| !record[field].nil? && !record[field].to_s.strip.empty? }

    text = "#{record["source"]}#{record["number"]}\n#{record["詞書(現代訳)"]}\n#{record["歌"].to_s.delete(" ")}\n#{record["author"]}"
    matches << text if text.scan(/\X/).length <= 300 && text.bytesize <= 3_000
  end

  if candidates.empty?
    puts "投稿候補がありません: S3オブジェクト=#{selected_key}, 理由=必須項目の欠落、Bluesky完成本文が300書記素超過、または3,000バイト超過"
    return false
  end

  post_text = candidates.sample

# AWS S3を使わずにプログラムが動くか確認するためのダミー投稿文生成
#  t_time = Time.now.to_s
#  post_text = "test post: #{t_time}"
  
  
  ### 認証情報生成
  # ここでは環境変数から取り出している
  # Bluesky認証情報
  bs_username = ENV["bs_username"]
  bs_password = ENV["bs_password"]
  bs_pds_url = "https://bsky.social"
  
  ### 投稿前準備完了
  puts "投稿準備"
  puts "投稿用テキスト: #{post_text}"
  
  
  ###
  # Blueskyへの投稿
  stage = "セッション作成"
  access_jwt = nil
  begin
    uri = URI.parse("#{bs_pds_url}/xrpc/com.atproto.server.createSession")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
    request.body = { identifier: bs_username, password: bs_password }.to_json
    session_response = http.request(request)

    unless session_response.is_a?(Net::HTTPSuccess)
      secrets = [bs_username, bs_password]
      response_body = redact_for_log(session_response.body, secrets)
      puts "Bluesky HTTPエラー: 処理段階=#{stage}, 応答コード=#{session_response.code}, 応答本文=#{response_body}"
      return false
    end

    stage = "セッション応答解析"
    session = JSON.parse(session_response.body)
    access_jwt = session['accessJwt']
    did = session['did']
    unless access_jwt.is_a?(String) && !access_jwt.strip.empty?
      raise "Blueskyセッション応答にaccessJwtがありません"
    end
    unless did.is_a?(String) && !did.strip.empty?
      raise "Blueskyセッション応答にdidがありません"
    end

    stage = "投稿"
    uri = URI.parse("#{bs_pds_url}/xrpc/com.atproto.repo.createRecord")
    request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{access_jwt}")
    request.body = {
      collection: 'app.bsky.feed.post',
      repo: did,
      record: {
        text: post_text,
        createdAt: Time.now.utc.iso8601
      }
    }.to_json

    bluesky_response = http.request(request)
    if bluesky_response.is_a?(Net::HTTPSuccess)
      puts "Blueskyに投稿しました"
    else
      secrets = [bs_username, bs_password, access_jwt]
      response_body = redact_for_log(bluesky_response.body, secrets)
      puts "Bluesky HTTPエラー: 処理段階=#{stage}, 応答コード=#{bluesky_response.code}, 応答本文=#{response_body}"
      return false
    end
  rescue => e
    secrets = [bs_username, bs_password, access_jwt]
    error_message = redact_for_log(e.message, secrets)
    puts "Bluesky投稿エラー: 処理段階=#{stage}, 例外=#{e.class}, メッセージ=#{error_message}"
    return false
  end
  
end
