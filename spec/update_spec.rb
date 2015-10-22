
#
# specifying podoff
#
# Tue Oct 20 17:25:49 JST 2015
#

require 'spec_helper'


describe Podoff do

  before :all do

    @d0 = Podoff.load('pdfs/udocument0.pdf')
    @t0 = Podoff.load('pdfs/t0.pdf')
  end

#  describe 'Obj#prepend_text' do
#
#    it 'adds text at the beginning of an obj' do
#
#      d = @d.dup
#
#      p1 = d.page(1)
#      p1.prepend_text(0, 500, 'hello world! xxx', size: 35, font: 'Helv')
#      #p1.prepend_text(0, 450, '"stuff NADA"', size: 35, font: 'Helv')
#
#      d.write('tmp/out.pdf')
#
#      s = `grep -a "hello world!" tmp/out.pdf`.strip
#
#      expect(s).to eq('BT 0 500 Td /Helv 35 Tf (hello world! xxx)Tj ET')
#    end
#  end

  describe 'Obj#add_free_text' do

    it 'annotates an object with free text' do

      doc = @t0.dup
      page = doc.page(1)

      puts page.source
      page.add_free_text(100, 100, 'free text', :helvetica, 15)

      expect(doc.objs.size).to eq(7)
      expect(doc.additions.size).to eq(2)

      doc.write('tmp/out.pdf')
    end
  end
end

