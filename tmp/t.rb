
require 'podoff'

d = Podoff.load('tmp/uig.pdf')

p1 = d.page(1)

  # additions
  #
#o = document.add_base_font(x)
#o = document.add_stream(x)
#o = document.re_add(o0) # replicate

  # object tweaking
  #
#obj.insert_content(o / o.ref)
#obj.insert_font(nick, o / o.ref)

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

  # idea
  #
#st = d.add_stream {
#  tf '/Helvetica', 35
#  bt 100, 650, 'Hello World Again!'
#  bt 300, 750, 'Stuff NADA',
#}

p1 = p1.insert_content(st)
p1.add_to_fonts('Helvetica', fo.ref)

d.write('tmp/out.pdf')

