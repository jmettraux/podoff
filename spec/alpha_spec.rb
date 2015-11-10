
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
end

