
#
# specifying podoff
#
# Tue Oct 20 17:25:49 JST 2015
#

require 'spec_helper'


describe Podoff do

  before :all do

    @d = Podoff.load('pdfs/udocument0.pdf')
  end

  describe 'Obj.prepend_text' do

    it 'adds text at the beginning of an obj' do

      d = @d.dup

      p1 = d.page(1)
      p1.prepend_text(0, 500, 'hello world!', size: 35)
      #p1.prepend_text(0, 450, '"stuff NADA"', size: 35, font: 'C2_0')

      d.write('tmp/out.pdf')

      s = `grep "hello world!" tmp/out.pdf`.strip

      expect(s).to eq('BT 10 10 Td /TT0 35 Tf (hello world!)Tj ET')
    end
  end
end

