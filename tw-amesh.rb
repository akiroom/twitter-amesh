#!/usr/bin/env ruby
require 'open-uri'
require 'rubygems'
require 'twitter'
require 'RMagick'
include Magick

# カレントディレクトリをソースコード(このファイル)と同じディレクトリに変更
Dir::chdir(File.expand_path(File.dirname(__FILE__)))

# twitter用のOAuthキーの設定
YOUR_CONSUMER_KEY       = "Consumer Key"
YOUR_CONSUMER_SECRET    = "Consumer Secret"
YOUR_OAUTH_TOKEN        = "OAuth Token"
YOUR_OAUTH_TOKEN_SECRET = "OAuth Token Secret"

# アメッシュの最新画像のURLを取得してRMagickで読み込む
# 参考: http://qiita.com/items/efb42dd452f2a950e8b1
times_url = "http://tokyo-ame.jwa.or.jp/scripts/mesh_index.js"
times_js = open(times_url).read()
times = times_js.sub("Amesh.setIndexList([", "").sub(");", "").chomp!.chomp!.split(",").map!{|t| t[1..-2].to_i}
time = times[0]
gif_url = "http://tokyo-ame.jwa.or.jp/mesh/100/#{time}.gif"
amesh_gif = open(gif_url).read()
img_amesh = Magick::Image.from_blob(amesh_gif).first

# 加工していないアメッシュの画像を保存したい時はコメントを外す
# img_amesh.write('./amesh.png')

# ベースの画像の読み込み
img_base = Magick::Image.read('./background.png').first

# ベースの画像に合うサイズに切り出してリサイズ
img_amesh.crop!(197*4, 126*4, img_base.columns*4, img_base.rows*4).resize!(img_base.columns, img_base.rows)

# ベースの画像と合成
img_result = img_base.composite(img_amesh, 0, 0, OverCompositeOp)

# ベースの画像に時刻を出力
draw = Draw.new
draw.pointsize = 32
draw.font_style = NormalStyle
draw.fill = "#FFFFFF"
draw.gravity = SouthEastGravity
/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/ =~ time.to_s
draw.annotate(img_result, 0, 0, 0, 0, "#{$1}/#{$2}/#{$3} #{$4}:#{$5}")

# 画像を保存
img_result.write('./amesh-icon.png')

# 参考: http://d.hatena.ne.jp/yoshidaa/20110112/1294846937
Twitter.configure do |config|
  config.consumer_key = YOUR_CONSUMER_KEY
  config.consumer_secret = YOUR_CONSUMER_SECRET
  config.oauth_token = YOUR_OAUTH_TOKEN
  config.oauth_token_secret = YOUR_OAUTH_TOKEN_SECRET
end
client = Twitter::Client.new
pic = open("./amesh-icon.png")
client.update_profile_image(pic)

