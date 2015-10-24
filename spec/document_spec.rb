
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

        expect(@d.additions.size).to eq(1)
        expect(@d.objs.keys).to eq((1..7).map { |i| "#{i} 0" })
        expect(@d.additions.keys).to eq([ '7 0' ])

        expect(fo.document).to eq(@d)
        expect(fo.ref).to eq('7 0')

        expect(fo.source).to eq(
          '7 0 obj ' +
          '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj')

        s = @d.write(:string)
        d = Podoff.parse(s)

        expect(d.xref).to eq(682)
      end

      it 'doesn\'t mind a slash in front of the font name' do

        fo = @d.add_base_font('/Helvetica')

        expect(@d.additions.size).to eq(1)
        expect(@d.objs.keys).to eq((1..7).map { |i| "#{i} 0" })
        expect(@d.additions.keys).to eq([ '7 0' ])

        expect(fo.document).to eq(@d)
        expect(fo.ref).to eq('7 0')

        expect(fo.source).to eq(
          '7 0 obj ' +
          '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj')
      end
    end

    describe '#add_stream' do

      it 'adds a new obj with a stream to the document' do

        st = @d.add_stream('BT 70 80 Td /Helvetica 35 Tf (Hello!) Tj ET')

        expect(@d.additions.size).to eq(1)
        expect(@d.objs.keys).to eq((1..7).map { |i| "#{i} 0" })
        expect(@d.additions.keys).to eq([ '7 0' ])

        expect(st.document).to eq(@d)
        expect(st.ref).to eq('7 0')

        expect(st.source).to eq(%{
7 0 obj
<< /Length 43 >>
stream
BT 70 80 Td /Helvetica 35 Tf (Hello!) Tj ET
endstream
endobj
        }.strip)

        d = Podoff.parse(@d.write(:string))

        expect(d.xref).to eq(705)
      end

      it 'accepts a block' do

        st =
          @d.add_stream {
            tf '/Helvetica', 35
            bt 10, 20, 'thirty here'
            bt 40, 50, 'sixty there'
          }

        expect(st.obj.document).to eq(@d)
        expect(st.obj.ref).to eq('7 0')

        expect(st.obj.source.to_s).to eq(%{
BT /Helvetica 35 Tf 10 20 Td (thirty here) Tj ET
BT /Helvetica 35 Tf 40 50 Td (sixty there) Tj ET
        }.strip)

        d = Podoff.parse(@d.write(:string))

        expect(d.source.index('<< /Length 97 >>')).to eq(618)
        expect(d.xref).to eq(759)
      end

      it 'returns the open stream when no arg given' do

        st = @d.add_stream

        expect(st.class).to eq(Podoff::Stream)
      end
    end

    describe '#re_add' do

      it 'replicates an obj and adds the replica to the document' do

        pa = @d.page(1)
        re = @d.re_add(pa)

        expect(@d.additions.size).to eq(1)
        expect(@d.objs.keys).to eq((1..6).map { |i| "#{i} 0" })
        expect(@d.additions.keys).to eq([ '3 0' ])

        expect(re.document).to eq(@d)
        expect(re.ref).to eq(pa.ref)
        expect(re.source).to eq(pa.source)
        expect(re.source).not_to equal(pa.source)
      end

      it 'accepts a ref' do

        pa = @d.page(1)
        re = @d.re_add(pa.ref)

        expect(@d.additions.size).to eq(1)
        expect(@d.objs.keys).to eq((1..6).map { |i| "#{i} 0" })
        expect(@d.additions.keys).to eq([ '3 0' ])

        expect(re.document).to eq(@d)
        expect(re.ref).to eq(pa.ref)
        expect(re.source).to eq(pa.source)
        expect(re.source).not_to equal(pa.source)
      end

      it 'recomputes the attributes correctly' do

        d = Podoff.load('pdfs/qdocument0.pdf')

        pa = d.re_add(d.page(1))

        expect(pa.attributes).to eq(
          { type: '/Page', contents: '151 0 R', pagenum: '1' })
      end
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

    it 'writes open streams as well' do

      d = Podoff.load('pdfs/t0.pdf')

      pa = d.re_add(d.page(1))
      st = d.add_stream
      st.bt(10, 20, 'hello open stream')
      pa.insert_contents(st)

      s = d.write(:string)

      expect(
        d.write(:string).index(%{
7 0 obj
<< /Length 37 >>
stream
BT 10 20 Td (hello open stream) Tj ET
endstream
endobj
        }.strip)
      ).to eq(722)
    end
  end

  describe '#rewrite' do

    it 'rewrites a document in one go' do

      d = Podoff.load('pdfs/t2.pdf')

      s = d.rewrite(:string)

      expect(s.strip).to eq(%{
%PDF-1.4
1 0 obj <</Type /Catalog /Pages 2 0 R>>
endobj
2 0 obj <</Type /Pages /Kids [3 0 R] /Count 1>>
endobj
3 0 obj <</Type /Page /Parent 2 0 R /Resources 4 0 R /MediaBox [0 0 500 800] /Contents [6 0 R 7 0 R]>>
endobj
4 0 obj <</Font <</F1 5 0 R>>>>
endobj
5 0 obj <</Type /Font /Subtype /Type1 /BaseFont /Helvetica>>
endobj
6 0 obj
<</Length 44>>
stream
BT /F1 24 Tf 175 720 Td (Hello Nadaa!)Tj ET
endstream
endobj
7 0 obj
<</Length 44>>
stream
BT /F1 24 Tf 175 520 Td (Smurf Megane)Tj ET
endstream
endobj
xref
0 1
0000000000 65535 f
1 7
0000000010 00000 n
0000000057 00000 n
0000000112 00000 n
0000000222 00000 n
0000000261 00000 n
0000000329 00000 n
0000000420 00000 n
trailer
<<
/Size 7
/Root 1 0 R
>>
startxref 511
%%EOF
      }.strip)
    end
  end
end

