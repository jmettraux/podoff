
require 'strscan'

#s = File.read('/Users/jmettraux/tmp/sgpdfs/ig.pdf')
s =
  File.open('/Users/jmettraux/tmp/sgpdfs/ig.pdf', 'r:iso-8859-1') { |f|
    f.read
  }
p s.size

#keywords = %w[ obj endobj /Type stream endstream ]

#s.scan(/(endobj|obj)/) do |m|
#  p m.class
#end

ss = StringScanner.new(s)
version = ss.scan(/%PDF-\d+\.\d+/)
p version
objs = []
loop do
  m = ss.scan_until(/\d+ \d+ obj/); break unless m
  ref = m.match(/\d+ \d+/)[0]
  st = ss.pos - ref.length - 3
  m = ss.scan_until(/endobj\s/); break unless m
  en = ss.pos - 1
  objs << [ ref, st, en ]
end
p objs

class << ss
  def peekch
    c = getch
    self.pos = self.pos - 1
    c
  end
  def bkw(char)
    loop do
      self.pos = self.pos - 1
      break if self.pos < 0 || peekch == char
    end
  end
  def frw(char)
    loop do
      c = peekch
      break if c == nil || c == char
      self.pos = self.pos + 1
    end
  end
end

root = nil
ss.pos = 0
loop do
  c = ss.skip_until(/\/Root([\s0-9R]+)/)
  break unless c
  #ss.bkw('/'); ss.frw(' ')
  3.times { ss.bkw(' ') }; ss.pos += 1
  root = ss.scan(/\d+ \d+/)
end
p [ :root, root ]

