
#--
# Copyright (c) 2015-2015, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


module Podoff

  VERSION = '0.9.0'

  def self.load(path)

    Podoff::Document.new(
      File.open(path, 'r:iso8859-1') { |f| f.read })
  end

  class Document

    attr_reader :header
    attr_reader :objs
    attr_reader :footer

    def initialize(s)

      fail ArgumentError.new('not a PDF file') \
        unless s.match(/\A%PDF-\d+\.\d+\n/)

      @header = []
      #
      @objs = {}
      cur = nil
      #
      @footer = nil

      s.split("\n").each do |l|

        if @footer
          @footer << l
        elsif m = /^(\d+ \d+) obj\b/.match(l)
          cur = (@objs[m[1]] = Obj.new(m[1]))
          cur << l
        elsif m = /^xref\b/.match(l)
          @footer = []
          @footer << l
        elsif cur
          cur << l
        else
          @header << l
        end
      end
    end

    def pages

      @objs.values.select(&:is_page?)
    end
  end

  class Obj

    attr_reader :ref
    attr_reader :lines

    def initialize(ref)

      @ref = ref
      @lines = []
    end

    def <<(l)

      @lines << l
    end

    def page_number

      m = @lines.find { |l| l.match(/^\/pdftk_PageNum (\d+)\b/) }
      m ? m[1].to_i : nil
    end

    def is_page?

      page_number != nil
    end
  end
end

