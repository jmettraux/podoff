
#
# specifying podoff
#
# Sat Oct 24 06:59:22 JST 2015
#

require 'spec_helper'


describe Podoff::Scanner do

  before :each do

    @sca = Podoff::Scanner.new('the green fox jumped the puddle')
  end

  describe '.peekch' do

    it 'returns the next char' do

      c = @sca.peekch

      expect(c).to eq('t')
      expect(@sca.pos).to eq(0)
    end

    it 'returns nil if there is no next char' do

      @sca.skip_until(/$/)

      c = @sca.peekch

      expect(c).to eq(nil)
      expect(@sca.pos).to eq(30)
    end
  end

  describe '.bakc' do

    it 'looks backward for a given char' do

      @sca.skip_until(/$/)

      @sca.bakc('p')

      expect(@sca.rest).to eq('puddle')
    end

    it 'looks backward for a given char a number of time' do

      @sca.skip_until(/$/)

      @sca.bakc('d', 3)

      expect(@sca.rest).to eq('d the puddle')
    end

    it 'stops at pos 0' do

      @sca.bakc('z')

      expect(@sca.pos).to eq(0)
    end

    it 'stops at pos 0' do

      @sca.bakc('z', 2)

      expect(@sca.pos).to eq(0)
    end

    it 'backs 1 char when no argument' do

      @sca.forc('j')

      @sca.bakc

      expect(@sca.rest).to eq(' jumped the puddle')
    end

    it 'back n chars when the first arg is a Fixnum' do

      @sca.forc('j')

      @sca.bakc(3)

      expect(@sca.rest).to eq('ox jumped the puddle')
    end

    it 'fails when fixnum backing over 0' do

      expect {
        @sca.bakc(3)
      }.to raise_error(RangeError, 'index out of range -3')
    end
  end

  describe '.forc' do

    it 'looks forward for a given char' do

      @sca.forc('f')

      expect(@sca.rest).to eq('fox jumped the puddle')
    end

    it 'looks forward for a given char a number of time' do

      @sca.forc('e', 4)

      expect(@sca.rest).to eq('ed the puddle')
    end

    it 'stops at the end' do

      @sca.forc('Z')

      expect(@sca.pos).to eq(30)
    end

    it 'stops at the end' do

      @sca.forc('Z', 2)

      expect(@sca.pos).to eq(30)
    end

    it 'steps 1 char when no argument' do

      @sca.forc

      expect(@sca.pos).to eq(1)
    end

    it 'steps n chars when the first arg is a Fixnum' do

      @sca.forc(3)

      expect(@sca.pos).to eq(3)
    end

    it 'fails if pos + fixnum arg out of range' do

      expect {
        @sca.forc(100)
      }.to raise_error(RangeError, 'index out of range')
    end
  end

  describe '.baks' do

    it 'backs as long as it finds a char from the given string' do

      sca = Podoff::Scanner.new('/Blah 618 0 obj/Nada')

      sca.forc('/', 2)
      sca.bakc(3)
      sca.baks("0123456789 ")

      expect(sca.rest).to eq(' 618 0 obj/Nada')
    end

    it 'doesn\'t back over 0' do

      @sca.baks('0123456789 ')

      expect(@sca.pos).to eq(0)
    end
  end
end

