
#
# specifying podoff
#
# Tue Oct 20 13:30:16 JST 2015
#

require 'spec_helper'


describe Podoff::Document do

  before :all do

    @d = Podoff.load('pdfs/udocument0.pdf')
  end

  describe '#objs' do

    it 'returns a hash of PDF "obj"' do

      expect(@d.objs.class).to eq(Hash)
      expect(@d.objs.values.first.class).to eq(Podoff::Obj)
      expect(@d.objs.size).to eq(273)
    end
  end

  describe '#pages' do

    it 'returns the pages' do

      expect(@d.pages.size).to eq(3)
      expect(@d.pages.first.class).to eq(Podoff::Obj)
    end
  end
end

