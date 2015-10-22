
require 'podoff'

d = Podoff.load('tmp/uig.pdf')

p1 = d.page(1)

fo = d.add_base_font('Helvetica')

st =
  d.add_stream(%{
    BT
      100 650 Td /Helvetica 35 Tf
      (Hello World Again!) Tj
    ET
    BT
      300 750 Td /Helvetica 35 Tf
      (Stuff NADA) Tj
    ET
  }.strip)

p1 = p1.insert_content(st)
p1.add_to_fonts('Helvetica', fo.ref)

d.write('tmp/out.pdf')

