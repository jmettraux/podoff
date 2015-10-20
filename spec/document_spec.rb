
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

  describe '#fonts' do

    it 'returns the font obj' do

      expect(@d.fonts.size).to eq(35)
      expect(@d.fonts.first.class).to eq(Podoff::Obj)

      pp @d.fonts.first
    end
  end

  describe '#write' do

    it 'writes the document to a given path' do

      @d.write('tmp/out.pdf')

      s = File.open('tmp/out.pdf', 'r:iso8859-1') { |f| f.read }
      lines = s.split("\n")

      expect(lines.first).to match(/^%PDF-1.7$/)
      expect(lines.last).to match(/^%%EOF$/)
    end
  end

  describe '#dup' do

    it 'produces a shallow copy of the document' do

      d = @d.dup

      expect(d.class
        ).to eq(Podoff::Document)
      expect(d.objs.hash
        ).not_to eq(@d.objs.hash)
      expect(d.objs.values.first.hash
        ).not_to eq(@d.objs.values.first.hash)
      #expect(d.objs.values.first.lines.hash
      #  ).not_to eq(@d.objs.values.first.lines.hash)
    end
  end
end

