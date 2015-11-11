
#
# specifying podoff
#
# Tue Nov 10 21:01:51 JST 2015
#

require 'spec_helper'


describe 'fixtures:' do

  Dir['pdfs/*.pdf'].each do |path|

    describe path do

      it 'is a valid pdf document' do

        expect(path).to be_a_valid_pdf
      end
    end
  end

  describe 'pdfs/t0.pdf' do

    it 'is encoded as UTF-8' do

      expect('pdfs/t0.pdf').to be_encoded_as('utf-8')
    end
  end

  describe 'pdfs/udocument0.pdf' do

    it 'is encoded as ISO-8859-1' do

      expect('pdfs/udocument0.pdf').to be_encoded_as('latin1')
    end
  end
end

