
s =
  %{
BT /SgZapf 12 Tf 468 301.5 Td (3) Tj ET
BT /SgZapf 12 Tf 468 227 Td (3) Tj ET
BT /SgZapf 12 Tf 468 143 Td (3) Tj ET
BT /SgZapf 12 Tf 468 705.5 Td (3) Tj ET
BT /SgHelv 10 Tf 492 113 Td (71) Tj ET
  }.strip

p s.length

require 'zlib'

s1 = Zlib::Deflate.deflate(s)
p s1.length
puts s1

