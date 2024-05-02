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
    file_list << object.key
  end
  
  puts file_list.to_s
  
  # バケットの中身(ファイルのリスト)からランダムにファイルを指定、中身を取り出す
  file_body = s3_client.get_object(:bucket => bucket_name, :key => file_list[rand(1..file_list.size)-1]).body
  
  puts file_body
  
  ### 投稿文生成
  # バケットの中身がYAMLファイルなので、Rubyのオブジェクトに変換する
  yamlbody = YAML.load(file_body)
  
  # バケットの中身は、和歌のデータの配列なので、ランダムに指定し取り出す
  waka = yamlbody[rand(yamlbody.size - 1)]
  
  puts waka
  
  # 取り出した和歌のデータから投稿するテキストを生成する。最後に140文字以内にカットしている
  post_text = "#{waka["source"]}#{waka["number"]}\n#{waka["詞書(現代訳)"]}\n#{waka["歌"].delete(" ")}\n#{waka["author"]}"

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
  body = {text: post_text.gsub(/〈[^〉]*〉/, "").slice(0, 140)}.to_json

  uri = URI.parse(tw_create_tweet_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri, headers)
  request.body = body
  puts "request.body: #{request.body}"
  
  begin
    twitter_response = http.request(request)
    puts "twitterに投稿しました"
    puts twitter_response.to_s
    puts twitter_response.body.force_encoding("UTF-8")
    # 投稿終わり
    puts "投稿スクリプト終わり。Well done!"
  rescue => e
    puts "twitter投稿エラー"
    puts twitter_response.to_s
    puts twitter_response.body.force_encoding("UTF-8")
    puts e.class
    puts e.message
    puts e.backtrace
  end
end

