
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
      p1.prepend_text(10, 10, 'hello world!', size: 35)

      d.write('tmp/out.pdf')
    end
  end
end

