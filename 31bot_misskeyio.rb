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
  
  # 取り出した和歌のデータから投稿するテキストを生成する
  post_text = "#{waka["source"]}#{waka["number"]}\n#{waka["詞書(現代訳)"]}\n#{waka["歌"].delete(" ")}\n#{waka["author"]}"

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
  
  begin
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    
    if response.code == '200' then
      # 投稿が成功しました
      puts "Misskeyへの投稿が成功しました。"
    else
      puts "Misskeyへの投稿が失敗しました。"
      raise
    end
    
    puts response.to_s
    puts response.body.force_encoding("UTF-8")
    # 投稿終わり
    puts "投稿スクリプト終わり。Well done!"

  rescue => e
    puts "bluesky投稿エラー"
    puts e.class
    puts e.message
    puts e.backtrace
    puts response.to_s
    puts response.body.force_encoding("UTF-8")
    return false
  end
  
  
end

