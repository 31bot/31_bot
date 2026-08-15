require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'openssl'
require 'yaml'
require 'time'
require 'securerandom'
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
    text = text.gsub(/〈[^〉]*〉/, "")
    matches << text if text.length <= 140
  end

  if candidates.empty?
    puts "投稿候補がありません: S3オブジェクト=#{selected_key}, 理由=必須項目の欠落またはTwitter完成本文が140文字超過"
    return false
  end

  post_text = candidates.sample

# AWS S3を使わずにプログラムが動くか確認するためのダミー投稿文生成
#  t_time = Time.now.to_s
#  post_text = "test post: #{t_time}"
  
  
  ### 認証情報生成
  # ここでは環境変数から取り出している
  # Twitter認証情報
  tw_consumer_key = ENV["tw_consumer_key"]
  tw_consumer_secret = ENV["tw_consumer_secret"]
  tw_access_token = ENV["tw_access_token"]
  tw_access_token_secret  = ENV["tw_access_token_secret"]
  tw_create_tweet_url = "https://api.twitter.com/2/tweets"
  
  
  ### 投稿前準備完了
  puts "投稿準備"
  puts "投稿用テキスト: #{post_text}"
  
  ### Twitterへ投稿
  timestamp = Time.now.to_i
  nonce = SecureRandom.hex
  signature_params = {
  oauth_consumer_key: tw_consumer_key,
  oauth_nonce: nonce,
  oauth_signature_method: 'HMAC-SHA1',
  oauth_timestamp: timestamp,
  oauth_token: tw_access_token,
  oauth_version: '1.0'
  }
  signature_base_string = "POST&#{URI.encode_www_form_component(tw_create_tweet_url)}&#{URI.encode_www_form_component(signature_params.map { |k, v| "#{k}=#{v}" }.join('&'))}"
  signing_key = "#{URI.encode_www_form_component(tw_consumer_secret)}&#{URI.encode_www_form_component(tw_access_token_secret)}"
  signature = Base64.strict_encode64(OpenSSL::HMAC.digest('sha1', signing_key, signature_base_string))

  headers = {
    'Authorization' => "OAuth oauth_consumer_key=\"#{tw_consumer_key}\", oauth_nonce=\"#{nonce}\", oauth_signature=\"#{URI.encode_www_form_component(signature)}\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"#{timestamp}\", oauth_token=\"#{tw_access_token}\", oauth_version=\"1.0\"",
  'Content-Type' => 'application/json'
  }
  body = {text: post_text}.to_json

  uri = URI.parse(tw_create_tweet_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri, headers)
  request.body = body

  stage = "投稿"
  begin
    twitter_response = http.request(request)
    if twitter_response.is_a?(Net::HTTPSuccess)
      puts "Twitterに投稿しました"
      # 投稿終わり
      puts "投稿スクリプト終わり。Well done!"
    else
      secrets = [tw_consumer_key, tw_consumer_secret, tw_access_token, tw_access_token_secret]
      response_body = redact_for_log(twitter_response.body, secrets)
      puts "Twitter HTTPエラー: 処理段階=#{stage}, 応答コード=#{twitter_response.code}, 応答本文=#{response_body}"
      return false
    end
  rescue => e
    secrets = [tw_consumer_key, tw_consumer_secret, tw_access_token, tw_access_token_secret]
    error_message = redact_for_log(e.message, secrets)
    puts "Twitter投稿エラー: 処理段階=#{stage}, 例外=#{e.class}, メッセージ=#{error_message}"
    return false
  end
end
