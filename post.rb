#!ruby

Ruby
require 'net/http'
require 'uri'
require 'json'

# Twitter認証情報
CONSUMER_KEY = 'YOUR_CONSUMER_KEY'
CONSUMER_SECRET = 'YOUR_CONSUMER_SECRET'
ACCESS_TOKEN = 'YOUR_ACCESS_TOKEN'
ACCESS_TOKEN_SECRET = 'YOUR_ACCESS_TOKEN_SECRET'

# 投稿するデータ
text = 'これはテスト投稿です。'

# リクエストパラメータ
params = {
  'status' => text,
}

# OAuth認証ヘッダー生成
oauth_header = generate_oauth_header(CONSUMER_KEY, CONSUMER_SECRET, ACCESS_TOKEN, ACCESS_TOKEN_SECRET, params)

# HTTPリクエスト送信
uri = URI.parse('https://api.twitter.com/1.1/statuses/update.json')
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
request = Net::HTTP::Post.new(uri.request_uri)
request['Authorization'] = oauth_header
request.set_form_data(params)
response = http.request(request)

# レスポンス処理
if response.code == '200'
  puts '投稿成功しました！'
else
  puts "投稿失敗しました: #{response.code} #{response.message}"
end

# OAuth認証ヘッダー生成
def generate_oauth_header(consumer_key, consumer_secret, access_token, access_token_secret, params)
  oauth = OAuth::HMAC::Consumer.new(consumer_key, consumer_secret, {:signature_method => 'HMAC-SHA1'})
  token = OAuth::AccessToken.new(oauth, access_token, access_token_secret)
  nonce = OAuth::Nonce.new
  timestamp = OAuth::Timestamp.new
  signature = token.sign(:post, 'https://api.twitter.com/1.1/statuses/update.json', params, {:nonce => nonce, :timestamp => timestamp})
  header = 'OAuth realm="Twitter API", '
  header << 'oauth_consumer_key="%s", ' % [consumer_key]
  header << 'oauth_token="%s", ' % [access_token]
  header << 'oauth_nonce="%s", ' % [nonce]
  header << 'oauth_timestamp="%s", ' % [timestamp]
  header << 'oauth_signature_method="HMAC-SHA1", '
  header << 'oauth_signature="%s"' % [signature]
  header
end