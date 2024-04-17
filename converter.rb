require 'yaml'

p ARGV

o = []

file = File.open(ARGV[0])
# file = File.open("古今和歌集巻二春下.yaml")

o = YAML.load_file(file)



wo = []
wo << '<ul class="wakas">' << "\n"

o.each do |ob|
    wo << '  <li>' << "\n"
    wo << '    <ul class="waka">' << "\n"
    wo << '      <li class="w_num">' << ob["number"] << '</li>' << "\n"
    wo << '      <li class="w_author">' << ob["author"] << '</li>' << "\n"
    wo << '      <li class="w_waka">' << ob["歌"] << '</li>' << "\n"
    wo << '      <li class="w_kai">' << ob["歌意"] << '</li>' << "\n"
    wo << '      <li class="w_kotobagaki">' << ob["詞書(現代訳)"] << '</li>' << "\n"
    wo << '      <li class="w_kaisetu">' << ob["解説"] << '</li>' << "\n"
    wo << '    </ul>' << "\n"
    wo << '  </li>' << "\n"
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
