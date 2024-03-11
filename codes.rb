#!ruby


# ---- Goole Geminiくんの答え ----

# Ruby
require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'oauth2'

# YAMLから認証内容を読み込む
config_data = YAML.load_file('config.yaml')
config_twitter = config_data['twitter']


# YAMLからツイート内容を読み込む
# tweet_data = YAML.load_file('tweet_data.yml')
# tweet_text = tweet_data['text']
tweet_text = "テスト2024-03-09 "

# Twitter認証情報
CONSUMER_KEY = 'YOUR_CONSUMER_KEY'
CONSUMER_SECRET = 'YOUR_CONSUMER_SECRET'
ACCESS_TOKEN = 'YOUR_ACCESS_TOKEN'
ACCESS_TOKEN_SECRET = 'YOUR_ACCESS_TOKEN_SECRET'

# リクエストパラメータ
params = {
  'status' => tweet_text,
}
# OAuth認証
oauth = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, {:signature_method => 'HMAC-SHA1'})
access_token = OAuth::AccessToken.new(oauth, ACCESS_TOKEN, ACCESS_TOKEN_SECRET)

# HTTPリクエスト送信
uri = URI.parse('https://api.twitter.com/1.1/statuses/update.json')
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
request = Net::HTTP::Post.new(uri.request_uri)
request.oauth!(access_token, :post, uri, params)
request.set_form_data(params)
response = http.request(request)

# レスポンス処理
if response.code == '200'
  puts '投稿成功しました！'
else
  puts "投稿失敗しました: #{response.code} #{response.message}"
end
# ---- Google Geminiくんの答え終わり ----# ---- Google Geminiくんの答え終わり ----


# ---- Claude3 Opusくんの答え ----


require 'net/http'
require 'uri'
require 'yaml'
require 'base64'
require 'openssl'

# YAMLからツイート内容を読み込む
tweet_data = YAML.load_file('tweet_data.yml')
tweet_text = tweet_data['text']

# 認証情報を設定
consumer_key = 'YOUR_API_KEY'
consumer_secret = 'YOUR_API_SECRET'
token = 'YOUR_ACCESS_TOKEN'
token_secret = 'YOUR_ACCESS_TOKEN_SECRET'

# OAuthの認証ヘッダーを作成
nonce = OpenSSL::Random.random_bytes(32).unpack('H*')[0]
ts = Time.now.to_i.to_s
parameter_string = "oauth_consumer_key=#{consumer_key}&oauth_nonce=#{nonce}&oauth_signature_method=HMAC-SHA1&oauth_timestamp=#{ts}&oauth_token=#{token}&oauth_version=1.0"
base_string = "POST&https%3A%2F%2Fapi.twitter.com%2F1.1%2Fstatuses%2Fupdate.json&#{URI.encode_www_form_component(parameter_string)}"
signing_key = URI.encode_www_form_component(consumer_secret) + "&" + URI.encode_www_form_component(token_secret)
digest = OpenSSL::HMAC.digest('sha1', signing_key, base_string)
oauth_signature = Base64.encode64(digest).gsub(/\n/, '')
auth_header = "OAuth oauth_consumer_key=\"#{consumer_key}\", oauth_nonce=\"#{nonce}\", oauth_signature=\"#{oauth_signature}\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"#{ts}\", oauth_token=\"#{token}\", oauth_version=\"1.0\""

# ツイートを投稿するリクエストを送信
uri = URI.parse('https://api.twitter.com/1.1/statuses/update.json')
request = Net::HTTP::Post.new(uri)
request['Authorization'] = auth_header
request.set_form_data('status' => tweet_text)

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
response = http.request(request)

# レスポンスを処理
if response.code == '200'
  puts 'ツイートが投稿されました'
else
  puts "エラー: #{response.body}"
end
# ---- Claude3 Opusくんの答え終わり ----