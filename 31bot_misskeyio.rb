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
  candidates = (yamlbody.is_a?(Array) ? yamlbody : []).select do |record|
    record.is_a?(Hash) && required_fields.all? do |field|
      !record[field].nil? && !record[field].to_s.strip.empty?
    end
  end

  if candidates.empty?
    puts "投稿候補がありません: S3オブジェクト=#{selected_key}, 理由=必須項目が欠落しています"
    return false
  end

  waka = candidates.sample

  # 取り出した和歌のデータから投稿するテキストを生成する
  post_text = "#{waka["source"]}#{waka["number"]}\n#{waka["詞書(現代訳)"]}\n#{waka["歌"].to_s.delete(" ")}\n#{waka["author"]}"

# AWS S3を使わずにプログラムが動くか確認するためのダミー投稿文生成
#  t_time = Time.now.to_s
#  post_text = "test post: #{t_time}"
  
  
  ### 認証情報生成
  # ここでは環境変数から取り出している
  # Misskey認証情報
  mk_access_token = ENV["mk_access_token"]
  
  ### 投稿前準備完了
  puts "投稿準備"
  puts "投稿用テキスト: #{post_text}"
  
  
  ###
  # misskeyへの投稿
  uri = URI.parse("https://misskey.io/api/notes/create")
  request = Net::HTTP::Post.new(uri)
  request.content_type = "application/json"
  request["Authorization"] = "Bearer #{mk_access_token}"
  request.body = {"text": post_text}.to_json

  req_options = {use_ssl: uri.scheme == "https"}
  
  stage = "投稿"
  begin
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    
    if response.is_a?(Net::HTTPSuccess)
      # 投稿が成功しました
      puts "Misskeyへの投稿が成功しました。"
    else
      response_body = redact_for_log(response.body, [mk_access_token])
      puts "Misskey HTTPエラー: 処理段階=#{stage}, 応答コード=#{response.code}, 応答本文=#{response_body}"
      raise "Misskey APIがHTTP #{response.code}を返しました"
    end

    # 投稿終わり
    puts "投稿スクリプト終わり。Well done!"

  rescue => e
    error_message = redact_for_log(e.message, [mk_access_token])
    puts "Misskey投稿エラー: 処理段階=#{stage}, 例外=#{e.class}, メッセージ=#{error_message}"
    return false
  end
  
  
end
