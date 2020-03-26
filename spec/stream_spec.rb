
#
# specifying podoff
#
# Fri Oct 23 08:36:38 JST 2015
#

require 'spec_helper'


describe Podoff::Stream do

  describe '#tf' do

    it 'sets the current font' do

      st = Podoff::Stream.new(OpenStruct.new(ref: '1 0'))

      st.tf('/Helvetica', 35)
      st.bt(10, 20, 'helvetic')
      st.tf('/ZapfDingbats', 21)
      st.bt(10, 50, 'zapfesque')

      expect(st.to_s).to eq(%{
1 0 obj
<</Length 95>>
stream
BT /Helvetica 35 Tf 10 20 Td (helvetic) Tj ET
BT /ZapfDingbats 21 Tf 10 50 Td (zapfesque) Tj ET
endstream
endobj
      }.strip)
    end
  end

  describe '#bt' do

    it 'works' do

      st = Podoff::Stream.new(OpenStruct.new(ref: '1 0'))
      st.bt(10, 20, 'hello world')

      expect(st.to_s).to eq(%{
1 0 obj
<</Length 31>>
stream
BT 10 20 Td (hello world) Tj ET
endstream
endobj
      }.strip)
    end

    it 'escapes the text' do

      st = Podoff::Stream.new(OpenStruct.new(ref: '1 0'))
      st.bt(10, 20, 'hello()world')

      expect(st.to_s).to eq(%{
1 0 obj
<</Length 34>>
stream
BT 10 20 Td (hello\\(\\)world) Tj ET
endstream
endobj
      }.strip)
    end

     it 'does not mind being given a nil text' do

      st = Podoff::Stream.new(OpenStruct.new(ref: '1 0'))
      st.bt(10, 20, nil)

      expect(st.to_s).to eq(%{
1 0 obj
<</Length 0>>
stream

endstream
endobj
      }.strip)
     end
  end

  describe '#rg' do

    it 'sets the color for the text' do

      st = Podoff::Stream.new(OpenStruct.new(ref: '1 0'))
      st.rg(1, 0, 0)
      st.bt(10, 20, 'hello()world')

      expect(st.to_s).to eq(%{
1 0 obj
<</Length 43>>
stream
BT 1 0 0 rg 10 20 Td (hello\\(\\)world) Tj ET
endstream
endobj
      }.strip)
    end
  end

  describe '#write' do

    it 'injects text into the stream' do

      st = Podoff::Stream.new(OpenStruct.new(ref: '1 0'))
      st.bt(10, 20, 'abc')
      st.write("\nBT 25 35 Td (ABC) Tj ET")
      st.bt(30, 40, 'def')

      expect(st.to_s).to eq(%{
1 0 obj
<</Length 71>>
stream
BT 10 20 Td (abc) Tj ET
BT 25 35 Td (ABC) Tj ET
BT 30 40 Td (def) Tj ET
endstream
endobj
      }.strip)
    end
  end

  describe '#re' do

    it 'adds a rectangle to the stream' do

      st = Podoff::Stream.new(OpenStruct.new(ref: '1 0'))
      st.re(10, 20, 30, 40, rgb: [ 0.0, 0.0, 0.0 ])
      st.rect(11, 21, w: 31, h: 41, rgb: [ 0.1, 0.1, 0.1 ])
      st.rectangle(12, 22, 32, 42, rgb: [ 0.2, 0.2, 0.2 ])

      expect(st.to_s).to eq(%{
1 0 obj
<</Length 95>>
stream
0.0 0.0 0.0 rg 10 20 30 40 re f
0.1 0.1 0.1 rg 11 21 31 41 re f
0.2 0.2 0.2 rg 12 22 32 42 re f
endstream
endobj
      }.strip)
    end
  end

  describe '#line' do

    it 'adds a line to the stream' do

      st = Podoff::Stream.new(OpenStruct.new(ref: '1 0'))
      st.line(1, 1, 2, 2)
      st.line([ 1, 1 ], [ 2, 2 ], [ 3, 3 ], rgb: [ 0.5, 0.5, 0.5 ])
      st.line(1, 1, 2, 2, rgb: [ 0.7, 0.7, 0.7 ])

      expect(st.to_s).to eq(%{
1 0 obj
<</Length 83>>
stream
1 1 m 2 2 l h S
0.5 0.5 0.5 rg 1 1 m 2 2 l 3 3 l h S
0.7 0.7 0.7 rg 1 1 m 2 2 l h S
endstream
endobj
      }.strip)
    end

    it 'accepts a width:/w: option' do

      st = Podoff::Stream.new(OpenStruct.new(ref: '1 0'))
      st.line(1, 1, [ 2, 2 ], 3, 3, rgb: [ 0.5, 0.5, 0.5 ], w: 5)
      st.line([ 1, 1 ], [ 2, 2 ], [ 3, 3 ], rgb: [ 0.5, 0.5, 0.5 ], w: 0.05)

      expect(st.to_s).to eq(%{
1 0 obj
<</Length 84>>
stream
5 w 0.5 0.5 0.5 rg 1 1 m 2 2 l 3 3 l h S
0.05 w 0.5 0.5 0.5 rg 1 1 m 2 2 l 3 3 l h S
endstream
endobj
      }.strip)
    end
  end

  describe '#to_s' do

    it 'applies /Filter /FlateDecode if stream.size > 98' do

      st = Podoff::Stream.new(OpenStruct.new(ref: '1 0'))
      st.write("BT /Helvetica 35 Tf 123 456 Td (Hello Nada) Tj ET\n" * 4)

      expect(st.to_s).to match(
        /^1 0 obj\n<<\/Length 60 \/Filter \/FlateDecode>>/)
    end
  end
end

