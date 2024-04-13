p ARGV

o = []

file = File.open(ARGV[0])
# file = File.open("古今和歌集巻二春下.yaml")


file.each do |line|  
  case line
  when /^\s*title:\s([^:]+)$/
    o << {"title": $+}
  when /^\s*-\snumber: (\d+)$/
    o << {"number": $1}
  when /author: (\S+)$/
    o.last["author"]=$1
  when /詞書: (\S+)$/
    o.last["kotobagaki"]=$1
  when /詞書\(現代訳\): (\S+)$/
    o.last["gkotobagaki"]=$1
  when /歌: (.+)$/
    o.last["uta"]=$1
  when /返し先: (\S+)$/
    o.last["kaesi"]=$1
  when /続き先: (\S+)$/
    o.last["tsuduki"]=$1
  when /tags: (\S+)$/
    o.last["tags"]=$1
  end
end
file.close

wo = []
wo << '<ul class="wakas">' << "\n"
o.each do |ob|
  if ob.key?('title') then
    p "タイトルは……" << ob["title"] << "\n"
    next
  end
#  elsif ob.key?("number") and ob.key?("author") and ob.key?("gkotobagaki") and ob.key?("uta") then
    wo << '  <li>' << "\n"
    wo << '    <ul class="waka">' << "\n"
    wo << '      <li class="w_num">' << ob[:number] << '</li>' << "\n"
    wo << '      <li class="w_author">' << ob["author"] << '</li>' << "\n"
    wo << '      <li class="w_waka">' << ob["uta"] << '</li>' << "\n"
    wo << '      <li class="w_kotobagaki">' << ob["gkotobagaki"] << '</li>' << "\n"
    wo << '    </ul>' << "\n"
    wo << '  </li>' << "\n"
#  else
#    p "エラー。妙なデータが見つかりました"
#  end
end

wo << '</ul>' << "\n"


a = File.open(ARGV[1], "a")
# a = File.open("vol2.html", "a") 

wo.each do |line|
  a << line
#  p line
end

a.close

# p o

# p ARGV[1]
