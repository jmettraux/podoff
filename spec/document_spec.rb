
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

  describe '#page' do

    it 'returns a page given an index (starts at 1)' do

      p = @d.page(1)
      expect(p.class).to eq(Podoff::Obj)
      expect(p.type).to eq('/Page')
      expect(p.attributes[:pagenum]).to eq('1')
      expect(p.page_number).to eq(1)
    end

    it 'returns nil if the page doesn\'t exist' do

      expect(@d.page(0)).to eq(nil)
      expect(@d.page(9)).to eq(nil)
    end

    it 'returns the page, even for a doc without pdftk_PageNum' do

      d = Podoff::Document.load('pdfs/t2.pdf')

      expect(d.page(1).ref).to eq('3 0')
      expect(d.page(1).page_number).to eq(nil)

      expect(d.page(0)).to eq(nil)
      expect(d.page(2)).to eq(nil)
    end

    it 'returns pages from the last when the index is negative' do

      expect(@d.page(-1).ref).to eq('33 0')
      expect(@d.page(-1).page_number).to eq(3)
    end

    it 'returns pages from the last when the index is negative (no PageNum)' do

      d = Podoff::Document.load('pdfs/t2.pdf')

      expect(d.page(-1).ref).to eq('3 0')
      expect(d.page(-1).page_number).to eq(nil)
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

      expect(d.class).to eq(Podoff::Document)
      expect(d.hash).not_to eq(@d.hash)

      expect(d.objs.hash).not_to eq(@d.objs.hash)

      expect(d.objs.values.first.hash).not_to eq(@d.objs.values.first.hash)
      expect(d.objs.values.first.class).to eq(Podoff::Obj)
      expect(d.objs.values.first.document.class).to eq(Podoff::Document)

      expect(d.objs.values.first.document).to equal(d)
      expect(@d.objs.values.first.document).to equal(@d)

      expect(d.root).to eq('65 0')
    end
  end

  context 'additions' do

    before :each do

      @d = Podoff.load('pdfs/t0.pdf')
    end

    describe '#add_base_font' do

      it 'adds a new /Font obj to the document' do

        fo = @d.add_base_font('Helvetica')

        expect(fo.ref).to eq('7 0')

        expect(fo.source).to eq(
          '7 0 obj ' +
          '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj')

        s = @d.write(:string)
        d = Podoff.parse(s)

        expect(d.xref).to eq(682)
      end
    end
  end
end

