
require 'uri'
require 'net/http'
require 'oauth'
require 'json'
require 'yaml'
require 'typhoeus'
require 'oauth/request_proxy/typhoeus_request'
require 'dotenv/load'

# YAMLから認証内容を読み込む
config_data = YAML.load_file('config.yaml')

# YAMLからツイート内容を読み込む
# tweet_data = YAML.load_file('tweet_data.yml')
# tweet_text = tweet_data['text']
tweet_text = "テスト2024-03-011 23:11"

# Twitter認証情報
consumer_key = config_data['twitter']['CONSUMER_KEY']
consumer_secret = config_data['twitter']['CONSUMER_SECRET']
access_token = config_data['twitter']['ACCESS_TOKEN']
access_token_secret  = config_data['twitter']['ACCESS_TOKEN_SECRET']


create_tweet_url = "https://api.twitter.com/2/tweets"

# Be sure to add replace the text of the with the text you wish to Tweet.
# You can also add parameters to post polls, quote Tweets, Tweet with reply settings, and Tweet to Super Followers in addition to other features.
@json_payload = {"text": tweet_text}

def create_tweet(url, oauth_params)
	options = {
	    :method => :post,
	    headers: {
	     	"User-Agent": "v2CreateTweetRuby",
        "content-type": "application/json"
	    },
	    body: JSON.dump(@json_payload)
	}
	request = Typhoeus::Request.new(url, options)
	oauth_helper = OAuth::Client::Helper.new(request, oauth_params.merge(:request_uri => url))
	request.options[:headers].merge!({"Authorization" => oauth_helper.header}) # Signs the request
	response = request.run

	return response
end

# OAuth Consumerオブジェクトを作成
consumer = OAuth::Consumer.new(consumer_key, consumer_secret,
	:site => 'https://api.twitter.com',
	:debug_output => false)

# OAuth Access Tokenオブジェクトを作成
access_token = OAuth::AccessToken.new(consumer, access_token, access_token_secret)

# OAuthパラメータをまとめたハッシュを作成
oauth_params = {
:consumer => consumer,
:token => access_token,
}

response = create_tweet(create_tweet_url, oauth_params)
puts response.code, JSON.pretty_generate(JSON.parse(response.body))
