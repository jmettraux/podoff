
#
# specifying podoff
#
# Tue Oct 20 13:11:38 JST 2015
#

require 'spec_helper'


describe Podoff do

  describe '.load' do

    it 'loads a PDF document' do

      d = Podoff.load('pdfs/t1.pdf')

      expect(d.class).to eq(Podoff::Document)
      expect(d.xref).to eq(698)
      expect(d.objs.keys).to eq([ '1 0', '2 0', '3 0', '4 0', '5 0', '6 0' ])
    end

    it 'rejects items that are not PDF documents' do

      expect {
        Podoff.load('spec/spec_helper.rb')
      }.to raise_error(ArgumentError, 'not a PDF file')
    end
  end
end

