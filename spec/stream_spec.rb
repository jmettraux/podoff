
#
# specifying podoff
#
# Fri Oct 23 08:36:38 JST 2015
#

require 'spec_helper'


describe Podoff::Stream do

  describe '#tf' do

    it 'sets the current font' do

      st = Podoff::Stream.new

      st.tf('/Helvetica', 35)
      st.bt(10, 20, 'helvetic')
      st.tf('/ZapfDingbats', 21)
      st.bt(10, 50, 'zapfesque')

      expect(st.to_s).to eq(%{
BT /Helvetica 35 Tf 10 20 Td (helvetic) Tj ET
BT /ZapfDingbats 21 Tf 10 50 Td (zapfesque) Tj ET
      }.strip)
    end
  end

  describe '#bt' do

    it 'works' do

      st = Podoff::Stream.new
      st.bt(10, 20, 'hello world')

      expect(st.to_s).to eq('BT 10 20 Td (hello world) Tj ET')
    end

    it 'escapes the text' do

      st = Podoff::Stream.new
      st.bt(10, 20, 'hello()world')

      expect(st.to_s).to eq('BT 10 20 Td (hello\(\)world) Tj ET')
    end
  end
end

