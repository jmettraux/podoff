
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

      p1 = @d.page(1)

      pp p1.lines
      pp p1.kids

      #p1.prepend_text(
    end
  end
end

