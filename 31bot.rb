require 'net/http'
require 'uri'
require 'base64'
require 'openssl'
require 'yaml'
require 'time'
require 'aws-sdk-s3'

# 31bot script ver 1.0

def lambda_handler(event:, context:)
  
  puts "Starting test"
  
  #### S3からデータを得る
  # API client for S3
  s3_client = Aws::S3::Client.new(region: "ap-northeast-1")
  
  
  ##### 引数を格納
  # S3のバケット名
  bucket_name = '31bot'
  
  file_list = []
  
  puts bucket_name
  
  s3_client.list_objects(:bucket => bucket_name).contents.each do |object|
    file_list << object.key
  end
  
  puts file_list.to_s
  
  file_body = s3_client.get_object(:bucket => bucket_name, :key => file_list[rand(1..file_list.size)-1]).body
  
  puts file_body
  
  yamlbody = YAML.load(file_body)
  
  waka = yamlbody[rand(yamlbody.size - 1)]
  
  puts waka
  
  
  post_text = "#{waka["source"]}: #{waka["number"]}\n#{waka["詞書(現代訳)"]}\n#{waka["歌"]}\n#{waka["author"]}".force_encoding('UTF-8').slice(0, 140)

#  t_time = Time.now.to_s
#  post_text = "test post: #{t_time}"
  
  tw_consumer_key = ENV["tw_consumer_key"]
  tw_consumer_secret = ENV["tw_consumer_secret"]
  tw_access_token = ENV["tw_access_token"]
  tw_access_token_secret  = ENV["tw_access_token_secret"]
  tw_create_tweet_url = "https://api.twitter.com/2/tweets"
  
  
  bs_username = ENV["bs_username"]
  bs_password = ENV["bs_password"]
  bs_pds_url = "https://bsky.social"
  
  puts "投稿準備"
  puts "投稿用テキスト: #{post_text}"
  
  # Twitterへの投稿
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
  body = { text: post_text }.to_json

  uri = URI.parse(tw_create_tweet_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri, headers)
  request.body = body
  puts "request.body: #{request.body}"
  
  begin
    twitter_response = http.request(request)
    puts "twitterに投稿しました"
  rescue => e
    puts "twitter投稿エラー"
    puts e.class
    puts e.message
    puts e.backtrace
  end
  
  
#  puts twitter_response
#  puts twitter_response.body

  
  # Blueskyへの投稿
  uri = URI.parse("#{bs_pds_url}/xrpc/com.atproto.server.createSession")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
  request.body = { identifier: bs_username, password: bs_password }.to_json
  response = http.request(request)
  session = JSON.parse(response.body)

  uri = URI.parse("#{bs_pds_url}/xrpc/com.atproto.repo.createRecord")
  request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{session['accessJwt']}")
  request.body = {
  collection: 'app.bsky.feed.post',
  repo: session['did'],
  record: {
    text: post_text,
    createdAt: Time.now.utc.iso8601
  }
  }.to_json

  begin
    bluesky_response = http.request(request)
    puts "blueskyに投稿しました"
  rescue => e
    puts "bluesky投稿エラー"
    puts e.class
    puts e.message
    puts e.backtrace
  end


#  puts bluesky_response
#  puts bluesky_response.body
end

