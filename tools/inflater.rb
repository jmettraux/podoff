
require 'zlib'


File.open('out.txt', 'wb') { |out|

  start = -1
  lines = nil

  File.readlines(ARGV[0]).each_with_index { |line, i|

    if lines && (line.match(/^endstream\n/) rescue nil)
      c = lines[1..-1].join('')[0..-2]
      c = (Zlib::Inflate.inflate(c) rescue '(could not deflate)')
      out.puts '-' * 80
      out.puts "stream line: #{start}"
      out.puts c
      out.puts '-' * 80
      out.flush
      lines = nil
    elsif lines && (line.match(/endstream\n/) rescue nil)
      lines = nil
    elsif lines
      lines << line
    elsif (line.match(/ \/Filter \/FlateDecode/) rescue nil)
      start = i
      lines = []
    #else
      # do nothing
    end
  }
}

