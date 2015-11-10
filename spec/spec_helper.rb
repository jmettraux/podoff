
#
# Specifying podoff
#
# Tue Oct 20 13:10:29 JST 2015
#

require 'pp'
require 'ostruct'

require 'podoff'


RSpec::Matchers.define :be_a_valid_pdf do

  match do |o|

    path =
      if /\A%PDF-\d/.match(o)
        File.open('tmp/_under_check.pdf', 'wb') { |f| f.write(o) }
        'tmp/_under_check.pdf'
      else
        o
      end

    $qpdf_r = `qpdf --check #{path} 2>&1`
    $qpdf_r = "#{$qpdf_r}\nexit: #{$?.exitstatus}"

    $qpdf_r.match(/exit: 0$/)
  end

  failure_message do |o|

    puts '--- qpdf ---------------------------------------------------------------------->'
    puts $qpdf_r
    puts '<-- qpdf -----------------------------------------------------------------------'
  end
end

