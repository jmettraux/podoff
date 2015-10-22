
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

  describe '#source' do

    it 'returns the source behind the obj' do

      o = @d.objs['20 0']

      expect(o.source).to eq(%{
20 0 obj [21 0 R]
endobj
      }.strip)
    end
  end

  describe '#match' do

    it 'returns a MatchData instance if there is a match' do

      o = @d.objs['1 0']

      m = o.match(/\/Contents ([^\n]+)/)

      expect(m).not_to eq(nil)
      expect(m[1]).to eq('3 0 R')
    end

    it 'returns nil if the match exits the obj' do

      o = @d.objs['1 0']

      m = o.match(/3 0 obj/)

      expect(m).to eq(nil)
    end

    it 'returns nil if there is no match' do

      o = @d.objs['1 0']

      m = o.match(/nada/)

      expect(m).to eq(nil)
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

    it 'returns the Contents references (single)' do

      expect(@d.objs['1 0'].contents).to eq([ '3 0' ])
    end

    it 'returns the Contents references (array)' do

      expect(@d.objs['16 0'].contents).to eq([ '17 0' ])
    end

    it 'returns an empty list if none' do

      expect(@d.objs['224 0'].contents).to eq([])
    end
  end

  describe '#font_names' do

    it 'returns a list of font names visible in this obj' do

      expect(
        @d.objs.values.first.font_names
      ).to eq(%w[
        C2_0 TT2 TT1 TT0 C2_2 C2_1 Helv
      ])
    end
  end

  describe '#index' do

    it 'returns the for a given line' do

      o = @d.objs['3 0']

      expect(o.index('stream')).to eq(4)
      expect(o.index('BT')).to eq(14)
    end

    it 'returns nil when it doesn\'t find' do

      o = @d.objs['3 0']

      expect(o.index('nada')).to eq(nil)
    end

    it 'accepts regexes' do

      o = @d.objs['1 0']

      i = o.index(/^\/B.+Box /)

      expect(i).to eq(40)
      expect(o.lines[i]).to eq('/BleedBox [0.0 0.0 612.0 792.0]')
    end

    it 'accepts a start index' do

      o = @d.objs['1 0']

      i = o.index(/^\/.+Box /, 3)

      expect(i).to eq(5)
      expect(o.lines[i]).to eq('/TrimBox [0.0 0.0 612.0 792.0]')
    end
  end

  describe '#find' do

    it 'returns the first sub obj that matches the given block' do

      o = @d.objs['1 0']

      o1 = o.find { |o| o.index('stream') }

      expect(o1).not_to eq(nil)
      expect(o1.lines.first).to eq('3 0 obj ')
    end

    it 'accept a :skip_root option'
  end

  describe '#gather' do

    it 'returns a list of sub obj that match the given block'
    it 'accept a :skip_root option'
  end

  describe '#crop_box' do

    it 'returns the [ x, y, w, h ] box for the obj' do

      o = @d.objs['1 0']

      expect(o.crop_box).to eq([ 0.0, 0.0, 612.0, 792.0 ])
    end

    it 'defaults to the MediaBox' do

      o = @d.objs['16 0']

      expect(o.crop_box).to eq([ 0.0, 0.0, 612.0, 792.0 ])
    end
  end

  describe '#crop_dims' do

    it 'returns [ w, h ]' do

      o = @d.objs['1 0']

      expect(o.crop_dims).to eq([ 612.0, 792.0 ])
    end

    it 'defaults to the MediaBox' do

      o = @d.objs['16 0']

      expect(o.crop_dims).to eq([ 612.0, 792.0 ])
    end
  end
end

