require 'yaml'

file_name = '古今和歌集巻一春上.yaml'
puts file_name
body = YAML.load_file(file_name)

max_author_count = 0
max_author_num = 0
max_koto_count = 0
max_koto_num = 0
max_uta_count = 0
max_uta_num = 0
max_m_uta_count = 0
max_m_uta_num = 0

body.each do |waka|
  if waka['author'].gsub(/〈[^〉]*〉/, "").size > max_author_count then
    max_author_count = waka['author'].gsub(/〈[^〉]*〉/, "").size
    max_author_num = waka['number']
  end
  if waka['詞書(現代訳)'].gsub(/〈[^〉]*〉/, "").size > max_koto_count then
    max_koto_count = waka['詞書(現代訳)'].gsub(/〈[^〉]*〉/, "").size
    max_koto_num = waka['number']
  end
  if waka['歌'].gsub(/〈[^〉]*〉/, "").size > max_uta_count then
    max_uta_count = waka['歌'].gsub(/〈[^〉]*〉/, "").size
    max_uta_num = waka['number']
  end
  if waka['歌意'] && waka['歌意'].gsub(/〈[^〉]*〉/, "").size > max_m_uta_count then
    max_m_uta_count = waka['歌意'].gsub(/〈[^〉]*〉/, "").size
    max_m_uta_num = waka['number']
  end
  
end


puts "Max Author Count = #{max_author_count}, #{max_author_num}"
puts "Max 詞書(現代) Count = #{max_koto_count}, #{max_koto_num}"
puts "Max 歌 Count = #{max_uta_count}, #{max_uta_num}"
puts "Max 歌意 Count = #{max_m_uta_count}, #{max_m_uta_num}"
