
#
# specifying podoff
#
# Tue Oct 20 15:08:59 JST 2015
#

require 'spec_helper'


describe Podoff::Obj do

  before :all do

    @d = Podoff.load('pdfs/udocument0.pdf')
  end

  describe '#document' do

    it 'points to the Podoff::Document owning this Obj' do

      expect(@d.objs.values.first.document).to eq(@d)
    end
  end

  describe '#type' do

    it 'returns the type of the obj' do

      expect(@d.objs['23 0'].type).to eq('Font')
    end

    it 'returns nil if there is no type' do

      expect(@d.objs['17 0'].type).to eq(nil)
    end
  end

  describe '#parent' do

    it 'returns the parent ref if any' do

      expect(@d.objs.values.first.parent).to eq('2 0')
    end

    it 'returns nil if there is no parent' do

      expect(@d.objs['2 0'].parent).to eq(nil)
    end
  end

  describe '#kids' do

    it 'returns a list of refs' do

      expect(@d.objs['2 0'].kids).to eq([ '1 0', '16 0', '33 0' ])
    end

    it 'returns an empty list if there are no kids' do

      expect(@d.objs['224 0'].kids).to eq([])
    end
  end

  describe '#contents' do

    it 'returns the Contents reference' do

      expect(@d.objs['1 0'].contents).to eq('3 0')
    end

    it 'returns nil if none' do

      expect(@d.objs['224 0'].contents).to eq(nil)
    end
  end

  describe '#font_names' do

    it 'returns a list of font names visible in this obj' do

      expect(
        @d.objs.values.first.font_names
      ).to eq(%w[
        C2_0 TT2 TT1 TT0 C2_2 C2_1
      ])
    end
  end
end
