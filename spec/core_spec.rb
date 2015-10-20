
#
# specifying podoff
#
# Tue Oct 20 13:11:38 JST 2015
#

require 'spec_helper'


describe Podoff do

  describe '.load' do

    it 'loads a PDF document' do

      d = Podoff.load('pdfs/udocument0.pdf')

      expect(d.class).to eq(Podoff::Document)
    end

    it 'rejects items that are not PDF documents' do

      expect {
        Podoff.load('spec/spec_helper.rb')
      }.to raise_error(ArgumentError, 'not a PDF file')
    end
  end
end

