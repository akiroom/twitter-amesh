#!/usr/bin/env ruby
require 'bundler'
Bundler.require
require 'open-uri'

include Magick

# 利用するファイル名の定数
PROFILE_IMG_FILENAME = './profile-image.png'
MAP_IMG_FILENAME = './map-image.png'
RESULT_IMG_FILENAME = './amesh-icon.png'

# カレントディレクトリをソースコード(このファイル)と同じディレクトリに変更
Dir::chdir(File.expand_path(File.dirname(__FILE__)))

# Twitterクライアントを設定
CONSUMER_KEY = ENV['CONSUMER_KEY']
CONSUMER_SECRET = ENV['CONSUMER_SECRET']
YOUR_ACCESS_TOKEN = ENV['YOUR_ACCESS_TOKEN']
YOUR_ACCESS_TOKEN_SECRET = ENV['YOUR_ACCESS_TOKEN_SECRET']
tw_client = Twitter::REST::Client.new do |config|
  config.consumer_key = CONSUMER_KEY
  config.consumer_secret = CONSUMER_SECRET
  config.access_token = YOUR_ACCESS_TOKEN
  config.access_token_secret = YOUR_ACCESS_TOKEN_SECRET
end

# 未ダウンロードの場合、元のプロフィール画像をダウンロードして保存
unless File.exist?(PROFILE_IMG_FILENAME)
  prof_base_uri = tw_client.user.profile_image_uri(:original)
  open(PROFILE_IMG_FILENAME, 'wb') do |output|
    open(prof_base_uri) do |data|
      output.write(data.read)
    end
  end
end

# プロフィールのベース画像を開いて暗くしておく
img_prof_base = Magick::Image.read(PROFILE_IMG_FILENAME).first
# http://stackoverflow.com/questions/19774405/rmagick-adjust-brightness
img_prof_base = img_prof_base.level(-Magick::QuantumRange * 0.25, Magick::QuantumRange * 3.0, 1.0)

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
img_base = Magick::Image.read(MAP_IMG_FILENAME).first

# ベースの画像に合うサイズにプロフィール画像をリサイズ
img_prof_base.resize!(img_base.columns, img_base.rows)
# ベースの画像に合うサイズにアメッシュを切り出してリサイズ
img_amesh.crop!(197*4, 126*4, img_base.columns*4, img_base.rows*4).resize!(img_base.columns, img_base.rows)

# プロフィール画像にベース画像を重ねる
img_result = img_prof_base.composite(img_base, 0, 0, OverCompositeOp)
# ↑の画像にアメッシュの画像を重ねる
img_result = img_result.composite(img_amesh, 0, 0, OverCompositeOp)

# 画像に時刻を出力
draw = Draw.new
draw.pointsize = 32
draw.font_style = NormalStyle
draw.fill = "#FFFFFF"
draw.gravity = SouthEastGravity
/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/ =~ time.to_s
draw.annotate(img_result, 0, 0, 0, 0, "#{$1}/#{$2}/#{$3} #{$4}:#{$5}")

# 画像を保存
img_result.write(RESULT_IMG_FILENAME)

pic = open(RESULT_IMG_FILENAME)
tw_client.update_profile_image(pic)
