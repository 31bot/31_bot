require 'yaml'

p ARGV

o = []

# usage
# $ruby converter_volume.rb 古今和歌集巻二春下.yaml ./_kokinwakashu/vol2.html vol2

file = File.open(ARGV[0])
# file = File.open("古今和歌集巻二春下.yaml")
vol = ARGV[2]

o = YAML.load_file(file)

puts "from: " << ARGV[0]
puts "to: " << ARGV[1]
puts "with " << ARGV[2]

wo = []
wo << "<ul class='wakas'>\n"

o.each do |ob|
    wo << "  <li>\n"
    wo << "    <ul class='waka'>\n"
    wo << "      <li class='w_num'><p><a href='#{ob["number"]}'>#{ob["number"]}</a></p></li>\n"
    wo << "      <li class='w_author'><p><a href='#{ob["number"]}'>#{ob["author"]}</a></p></li>\n".gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")
    wo << "      <li class='w_waka'><p><a href='#{ob["number"]}'>#{ob["歌"]}</a></p></li>\n".gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")
#    wo << "      <li class='w_kai'><p>#{ob["歌意"]}</p></li>\n".gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")
    wo << "      <li class='w_kotobagaki'><p><a href='#{ob["number"]}'>#{ob["詞書(現代訳)"]}</p></li>\n".gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")
#    wo << "      <li class='w_kaisetu'><p>#{ob["解説"]}</p></li>\n".gsub(/〈/, "<sup>").gsub(/〉/, "</sup>")
    wo << "    </ul>\n"
    wo << "  </li>\n"
end

wo << "</ul>\n"


a = File.open(ARGV[1], "a")
# a = File.open("vol2.html", "a") 

wo.each do |line|
  a << line
#  p line
end

a.close

# p o

# p ARGV[1]
