
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

#  describe '#match' do
#
#    it 'returns a MatchData instance if there is a match' do
#
#      o = @d.objs['1 0']
#
#      m = o.match(/\/Contents ([^\n]+)/)
#
#      expect(m).not_to eq(nil)
#      expect(m[1]).to eq('3 0 R')
#      expect(m.offset(0)).to eq([ 123, 138 ]) # /!\
#    end
#
#    it 'returns nil if the match exits the obj' do
#
#      o = @d.objs['1 0']
#
#      m = o.match(/3 0 obj/)
#
#      expect(m).to eq(nil)
#    end
#
#    it 'returns nil if there is no match' do
#
#      o = @d.objs['1 0']
#
#      m = o.match(/nada/)
#
#      expect(m).to eq(nil)
#    end
#  end
#
#  describe '#dmatch' do
#
#    it 'matches with the zero offset set to the document' do
#
#      o = @d.objs['1 0']
#
#      m = o.dmatch(/\/Contents ([^\n]+)/)
#
#      expect(m).not_to eq(nil)
#      expect(m[1]).to eq('3 0 R')
#      expect(m.offset(0)).to eq([ 138, 153 ]) # /!\
#    end
#  end

  describe '#type' do

    it 'returns the type of the obj' do

      expect(@d.objs['23 0'].type).to eq('/Font')
    end

    it 'returns nil if there is no type' do

      expect(@d.objs['17 0'].type).to eq(nil)
    end

    it 'works on open streams' do

      st = @d.add_stream

      expect(st.obj.type).to eq(nil)
    end
  end

#  describe '#parent' do
#
#    it 'returns the parent ref if any' do
#
#      expect(@d.objs.values.first.parent).to eq('2 0')
#    end
#
#    it 'returns nil if there is no parent' do
#
#      expect(@d.objs['2 0'].parent).to eq(nil)
#    end
#  end

#  describe '#kids' do
#
#    it 'returns a list of refs' do
#
#      expect(@d.objs['2 0'].kids).to eq([ '1 0', '16 0', '33 0' ])
#    end
#
#    it 'returns an empty list if there are no kids' do
#
#      expect(@d.objs['224 0'].kids).to eq([])
#    end
#  end
#
#  describe '#contents' do
#
#    it 'returns the Contents references (single)' do
#
#      expect(@d.objs['1 0'].contents).to eq([ '3 0' ])
#    end
#
#    it 'returns the Contents references (array)' do
#
#      expect(@d.objs['16 0'].contents).to eq([ '17 0' ])
#    end
#
#    it 'returns an empty list if none' do
#
#      expect(@d.objs['224 0'].contents).to eq([])
#    end
#  end

  context 'insertions' do

    before :each do

      @d = Podoff.load('pdfs/udocument0.pdf')
    end

    describe '#insert_contents' do

      it 'fails if the target hasn\'t been replicated' do

        expect {
          @d.objs['23 0'].insert_contents('-1 0')
        }.to raise_error(ArgumentError, "target '23 0' not a replica")
      end

      it 'fails if the target doesn\'t have /Contents' do

        expect {
          ta = @d.re_add('23 0')
          ta.insert_contents('-1 0')
        }.to raise_error(ArgumentError, "target '23 0' doesn't have /Contents")
      end

      it 'accepts an obj' do

        pa = @d.re_add(@d.page(1))

        st = @d.add_stream('BT 70 80 Td /Font0 35 Tf (content is king!) Tj ET')

        pa.insert_contents(st)

        expect(pa.source).to match(/\/Contents \[3 0 R #{st.ref} R\]\n/)
      end

      it 'accepts an obj ref' do

        pa = @d.re_add(@d.page(1))

        st = @d.add_stream('BT 70 80 Td /Font0 35 Tf (content is king!) Tj ET')

        pa.insert_contents(st.ref)

        expect(pa.source).to match(/\/Contents \[3 0 R #{st.ref} R\]\n/)
      end
    end

    describe '#insert_font' do

      it 'fails if the target hasn\'t been replicated' do

        expect {
          @d.objs['23 0'].insert_font('/Helvetica', '-1 0')
        }.to raise_error(ArgumentError, "target '23 0' not a replica")
      end

      it 'accepts name, obj' do

        fo = @d.add_base_font('/Helvetica')
        pa = @d.re_add(@d.page(1))

        pa.insert_font('MyHelv', fo)

        expect(pa.source).to match(/\/Font\s+<<\s+\/MyHelv #{fo.ref} R\s+/)
      end

      it 'accepts name, obj ref' do

        fo = @d.add_base_font('/Helvetica')
        pa = @d.re_add(@d.page(1))

        pa.insert_font('MyHelv', fo.ref)

        expect(pa.source).to match(/\/Font\s+<<\s+\/MyHelv #{fo.ref} R\s+/)
      end

      it 'accepts a slash in front of the name' do

        fo = @d.add_base_font('/Helvetica')
        pa = @d.re_add(@d.page(1))

        pa.insert_font('/MyHelv', fo.ref)

        expect(pa.source).to match(/\/Font\s+<<\s+\/MyHelv #{fo.ref} R\s+/)
      end
    end

    describe '#add_to_attribute' do

      it 'adds to a list of references' do

        d = Podoff.load('pdfs/qdocument0.pdf')

        o = d.re_add('56 0')

        o.send(:add_to_attribute, :contents, '9999 0')

        expect(o.attributes).to eq(
          { type: '/Page', contents: '[151 0 R 9999 0 R]' })
      end
    end
  end
end

