require 'yaml'

### usage
# $ruby converter_volume.rb sourcefile output_directory 
# $ruby converter_volume.rb './_kokinwakashu/古今和歌集　巻二　春下.yaml' ./_kokinwakashu/vol2



def main()
  
### テスト用ダミーデータ
#   waka={"number": "366", "詞書(現代訳)": "題知らず", "author": "詠み人知らず", "歌": "似我蜂〈すがる〉鳴く 秋の萩原〈はぎはら〉 朝立ちて 旅行く人を いつとか待たむ", "歌意": "似我蜂〈すがる〉の鳴く秋の萩原に朝早く立ち、旅行く人(あなた)をいつかと待とう", "解説": "すがるはジガバチのこと。"}
#   prev_waka={"number": "365", "詞書(現代訳)": "題知らず", "author": "在原行平朝臣〈ありはらのゆきひらのあそん〉", "歌": "立ち別れ 因幡〈いなば〉の山の 峰に生ふる〈おふる〉 まつ(松、待つ)とし聞かば今 帰へり〈かへり〉来む〈こむ〉", "歌意": "別れて旅立つ因幡の山の峰に生える松(待っている)と聞いたらば今帰って来よう", "解説": ""}
#   next_waka={"number": "367", "詞書(現代訳)": "題知らず", "author": "詠み人知らず", "歌": "限りなき 雲居〈くもゐ)の他所〈よそ〉に 別る〈わかる〉とも 人を心に 後らさむ〈おくらさむ〉やは", "歌意": "限りなく雲居〈くもゐ〉の他所(遠いところ)に別れたとしても、人(あなた)を心に置き去りにすることなどがあろうか", "解説": ""}
#   volume="vol8"
#   dir="_kokinwakashu/vol8"
#   data_file = "_kokinwakashu/古今和歌集　巻八　離別.yaml"
#   volume_label = File.basename(data_file).delete('.yaml')

  puts "引数をセット"
  data_file = ARGV[0]
  volume_label = File.basename(ARGV[0]).delete('.yaml')
  dir = ARGV[1]
  volume = File.basename(ARGV[1])
  
  puts ARGV
  puts "Input FILE: " << data_file
  puts "Output Dir: " << dir
  puts "Volume: " << volume
  puts "Volume Label " << volume_label
  
  puts "入力ファイルを開きます"
  puts data_file
  file = File.open(data_file)
  puts "入力ファイルを読み込みます"
  wakas = YAML.load_file(file)
  puts "入力ファイルを読み込みました"
  file.close
  
  puts "ループに入ります"
  puts "エントリ数: " << wakas.size.to_s
  (0...(wakas.size)).each do |index|
    puts "NOW INDEX…………" << index.to_s
    puts index
    puts "歌情報、前の歌情報、次の歌情報をセットする"
    if 0 == index then
      puts "ループが最初のとき、前の歌情報はnilにする"
      prev_waka = nil
      waka = wakas[index]
      next_waka = wakas[(index+1)]
    elsif ((wakas.size) -1) == index then
      puts "ループが最後のとき、次の歌情報はnilにする"
      prev_waka = wakas[(index-1)]
      waka = wakas[index]
      next_waka = nil
    else
      puts "ループが最初でも最後でもないときの処理"
      prev_waka = wakas[(index-1)]
      waka = wakas[index]
      next_waka = wakas[(index+1)]
    end
    
    
    puts put_waka_file(waka, volume, volume_label, prev_waka, next_waka, dir)
    
    next
    
  end
  
end


### 出力関数
# waka、volume(例: vol8)、volume_label(例: 古今和歌集　巻八　離別)、prev_waka、next_waka、dirを受け取って、
### waka, prev_waka、next_waka
# - number: 365
#   source: 古今
#   author: 在原行平朝臣〈ありはらのゆきひらのあそん〉
#   詞書: 題知らず
#   詞書(現代訳): 題知らず
#   歌: 立ち別れ 因幡〈いなば〉の山の 峰に生ふる〈おふる〉 まつ(松、待つ)とし聞かば今 帰へり〈かへり〉来む〈こむ〉
#   歌意: 別れて旅立つ因幡の山の峰に生える松(待っている)と聞いたらば今帰って来よう
#   fav: true
###
# 以下の内容をdir/#{waka['number']}.htmlに出力する
# ---
# layout: single-layout
# title: 古今和歌集　巻八　離別　365　立ち別れ因幡の山の峰に生ふるまつとし聞かば今帰へり来む
# label: 365
# order: 365
# volume: vol8
# prev_url: 
# next_url: 366
# prev_label: 
# next_label: 似我蜂鳴く…
# seo_description: 立ち別れ因幡の山の峰に生ふるまつとし聞かば今帰へり来む
# ---
# 
# <ul class="wakas">
#   <li>
#     <ul class="waka">
#       <li class="w_num">365</li>
#       <li class="w_author">在原行平朝臣〈ありはらのゆきひらのあそん〉</li>
#       <li class="w_waka">立ち別れ 因幡〈いなば〉の山の 峰に生ふる〈おふる〉 <br />まつ(松、待つ)とし聞かば今 帰へり〈かへり〉来む〈こむ〉</li>
#       <li class="w_kai">別れて旅立つ因幡の山の峰に生える松(待っている)と聞いたらば今帰って来よう</li>
#       <li class="w_kotobagaki">題知らず</li>
#       <li class="w_kaisetu"></li>
#     </ul>
#   </li>
# 
def put_waka_file(waka, volume, volume_label, prev_waka, next_waka, dir)
puts "和歌データ: " << waka.to_s
puts "Volume: " << volume
puts "Volume_label" << volume_label
puts "prev和歌データ: " << prev_waka.to_s
puts "next和歌データ: " << next_waka.to_s
puts "dir: " << dir
output_path = "#{dir}/#{waka["number"]}.html"
puts "output_path: " << output_path
ku = waka["歌"].split(' ')
puts "句s: " << ku.to_s


wo = []
wo << "---\n"
wo << "layout: single-layout\n"
wo << "title: #{volume_label}　#{waka["number"]}　#{waka["歌"].gsub(" ", "").gsub(/〈[^〉]+〉/,"")}\n"
wo << "label: #{waka["number"]}\n"
wo << "order: #{waka["number"]}\n"
wo << "volume: #{volume}\n"
if prev_waka then
  wo << "prev_url: #{prev_waka["number"]}\n"
  wo << "prev_label: #{prev_waka["number"]}　#{prev_waka["歌"].split(' ')[0]}\n"
else
  wo << "prev_url: \n"
  wo << "prev_label: \n"
end
if next_waka
  wo << "next_url: #{next_waka["number"]}\n"
  wo << "next_label: #{next_waka["number"]}　#{next_waka["歌"].split(' ')[0]}\n"
else
  wo << "next_url: \n"
  wo << "next_label: \n"
end
wo << "seo_description: #{volume_label}　#{waka["number"]}　#{waka["歌"].gsub(" ", "").gsub(/〈[^〉]+〉/,"")}\n"
wo << "---\n"
wo << "<ul class='wakas'>\n"
wo << "  <li>\n"
wo << "    <ul class='waka'>\n"
wo << "      <li class='w_num'><p>#{waka["number"]}</p></li>\n"
wo << "      <li class='w_author'><p>#{waka["author"]}</p></li>\n".gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")
wo << "      <li class='w_waka'>\n"
wo << "        <p class='w1'>#{ku[0].gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")}</p>\n"
wo << "        <p class='w2'>#{ku[1].gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")}</p>\n"
wo << "        <p class='w3'>#{ku[2].gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")}</p>\n"
wo << "        <p class='w4'>#{ku[3].gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")}</p>\n"
wo << "        <p class='w5'>#{ku[4].gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")}</p>\n"
wo << "      </li>\n"
wo << "      <li class='w_kai'><p>#{waka["歌意"].gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")}</p></li>\n"
wo << "      <li class='w_kotobagaki'><p>#{waka["詞書(現代訳)"].gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")}</p></li>\n"
if waka["解説"]
  wo << "      <li class='w_kaisetu'><p>#{waka["解説"].gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")}</p></li>\n"
end
wo << "    </ul>\n"
wo << "  </li>\n"
wo << "</ul>\n"
#  puts wo
  puts "ファイル出力を開始します " << output_path
  a = File.open(output_path, "w")
  a.puts(wo)
  a.close
  puts "ファイル出力を完了しました"
end
### 出力関数終わり




main
