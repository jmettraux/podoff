
#
# Specifying podoff
#
# Tue Oct 20 13:10:29 JST 2015
#

require 'pp'
require 'ostruct'

require 'podoff'


RSpec::Matchers.define :be_encoded_as do |encoding|

  match do |path|

    fail ArgumentError.new("expecting a path (String) not a #{path.class}") \
      unless path.is_a?(String)

    $vic_r =
      `(vim -c 'execute \"silent !echo \" . &fileencoding . " > _enc.txt" | q' #{path} > /dev/null 2>&1); cat _enc.txt; rm _enc.txt`.strip.downcase

    $vic_r == encoding.downcase
  end

  failure_message do |path|

    "expected #{encoding.downcase.inspect}, got #{$vic_r.to_s.inspect}"
  end
end


RSpec::Matchers.define :be_a_valid_pdf do

  match do |o|

    path =
      if /\A%PDF-\d/.match(o)
        File.open('tmp/_under_check.pdf', 'wb') { |f| f.write(o) }
        'tmp/_under_check.pdf'
      else
        o
      end

    file_cmd =
      /darwin/.match(RUBY_PLATFORM) ? 'file -I' : 'file -i'
    vim_cmd =
      "vim -c 'execute \"silent !echo \" . &fileencoding | q'"

    cmd = [
      "echo '* vim :'",
      "#{vim_cmd} #{path}",
      "echo '* #{file_cmd} :'",
      "#{file_cmd} #{path}",
      "echo",
      "qpdf --check #{path}"
    ]
    $qpdf_r = `(#{cmd.join('; ')}) 2>&1`
      `#{file_cmd} #{path}; echo; qpdf --check #{path} 2>&1`

    $qpdf_r = "#{$qpdf_r}\nexit: #{$?.exitstatus}"
#puts "." * 80
#puts $qpdf_r

    $qpdf_r.match(/exit: 0$/)
  end

  failure_message do |o|

    %{
--- qpdf ---------------------------------------------------------------------->
#{$qpdf_r}
<-- qpdf -----------------------------------------------------------------------
    }.strip
  end
end

