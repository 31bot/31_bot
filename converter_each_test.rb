a
b
c
d
e


ofile = File.open(test_o.txt, "r")
lines = ofile.take(50)
ofile.close
lines.push("7" << "\n")
wfile = File.open(test_w.txt, "w")
wfile.puts(lines)
wfile.close