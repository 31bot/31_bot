title = '巻一　春上　テスト'
waka1 = {"author": "在原元方", "詞書": "ふるとしに", "詞書(現代訳)": "旧年中に"}

object = [title, waka1]

p object


# title: 巻一 春上
#   - number: 1
#     author: 在原元方〈ありはらのもとかた〉
#     詞書: 古るとしに春立ちける日よめる
#     詞書(現代訳): 旧年中に立春を迎えた日に詠んだ歌
#     歌: 年の内に春は来にけり一年〈ひととせ〉を去年〈こぞ〉とやいはむ今年とやいはむ
#     返し先: 
#     続き先: 
#     tags: [春, ふるとし, 立つ, 日, 年, 内, 来る, 一年, 去年, 今年]
#   - number: 2
#     ……

o = []
i = 0

file = File.open("古今和歌集巻一春上.yaml")

file.each do |line|
  p i
  
  case line
  when /^\s*title:\s([^:]+)$/
    o << {title: $+}
    p $+
  when /^\s*-\snumber: (\d+)$/
    o << {"number": $1}
    p $1
  when /author: (\S+)$/
    o.last["author"]=$1
    p $1
  when /詞書: (\S+)$/
    o.last["詞書"]=$1
    p $1
  when /詞書\(現代訳\): (\S+)$/
    o.last["詞書(現代訳)"]=$1
    p $1
  when /歌: (\S+)$/
    o.last["歌"]=$1
    p $1
  when /返し先: (\S+)$/
    o.last["返し先"]=$1
    p $1
  when /続き先: (\S+)$/
    o.last["続き先"]=$1
    p $1
  when /tags: (\S+)$/
    o.last["tags"]=$1
    p $1
  end
  i += 1
end
file.close

p o

