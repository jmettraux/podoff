
require 'strscan'

#s = File.read('/Users/jmettraux/tmp/sgpdfs/ig.pdf')
s =
  File.open('/Users/jmettraux/tmp/sgpdfs/ig.pdf', 'r:iso-8859-1') { |f|
    f.read
  }
p s.size


class Scanner < ::StringScanner

  def scan_object
    m = skip_until(/(\d+ \d+ obj)/)
    return nil unless m
    st = pos - matched.length + 1
    ref = matched[0..-5]
    m = skip_until(/endobj/)
    en = pos
    [ ref, st, en ]
  end

  def scan_xref
  end

  def scan_root
  end
end

sca = Scanner.new(s)
version = sca.scan(/%PDF-\d+\.\d+/)
p version

loop do
  o = sca.scan_object
  p o
  x = sca.scan_xref
  r = sca.scan_root
  break unless o
end

