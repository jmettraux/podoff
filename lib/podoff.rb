
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
          cur = (@objs[m[1]] = Obj.new(self, m[1]))
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

    def fonts; @objs.values.select(&:is_font?); end
    def pages; @objs.values.select(&:is_page?); end

    def page(i)

      i < 1 ? nil : @objs.values.find { |o| o.page_number == i }
    end

    def dup

      d0 = self

      d = d0.class.allocate

      d.instance_eval do
        @header = d0.header.dup
        @foort = d0.footer.dup
        @objs = d0.objs.values.inject({}) { |h, v| h[v.ref] = v.dup(d); h }
      end

      d
    end

    def write(path)

      File.open(path, 'wb') do |f|

        @header.each { |l| f.print(l); f.print("\n") }

        @objs.values.each do |o|
          o.lines.each { |l| f.print(l); f.print("\n") }
        end

        @footer.each { |l| f.print(l); f.print("\n") }
      end
    end
  end

  class Obj

    attr_reader :document
    attr_reader :ref
    attr_reader :lines

    def initialize(doc, ref)

      @document = doc
      @ref = ref
      @lines = []
    end

    def <<(l)

      @lines << l
    end

    def lookup(k)

      @lines.each do |l|

        m = l.match(/^\/#{k} (.*)$/)
        return m[1] if m
      end

      nil
    end

    def type

      t = lookup('Type')
      t ? t[1..-1] : nil
    end

    def page_number

      @lines.each do |l|
        if m = l.match(/^\/pdftk_PageNum (\d+)\b/); return m[1].to_i; end
      end

      nil
    end

    def is_page?

      page_number != nil
    end

    def is_font?

      type() == 'Font'
    end

    def parent

      # /Parent 2 0 R

      @lines.each do |l|
        if m = l.match(/^\/Parent (\d+ \d+) R\b/); return m[1]; end
      end

      nil
    end

    def kids

      # /Kids [1 0 R 16 0 R 33 0 R]

      @lines.find do |l|
        m = l.match(/^\/Kids \[(.*)\]/)
        return m[1].split('R').collect(&:strip) if m
      end

      []
    end

    def contents

      r = lookup('Contents')

      r ? r[0..-2].strip : nil
    end

    def font_names

      @lines.inject(nil) do |names, l|

        if names
          return names if l == '>>'
          if m = l.match(/\/([^ ]+) /); names << m[1]; end
        elsif l.match(/\/Font\s*$/)
          names = []
        end

        names
      end

      []
    end

    def dup(new_doc)

      o0 = self
      o = o0.class.new(new_doc, @ref)
      o.instance_eval { @lines = o0.lines.dup }

      o
    end

    def prepend_text(x, y, text)
    end
  end
end

