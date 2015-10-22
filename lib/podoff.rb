
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

  VERSION = '1.0.0'

  def self.load(path)

    Podoff::Document.new(
      File.open(path, 'r:iso8859-1') { |f| f.read })
  end

  OBJ_ATTRIBUTES =
    { type: 'Type', subtype: 'Subtype',
      parent: 'Parent', kids: 'Kids', contents: 'Contents', annots: 'Annots',
      pagenum: 'pdftk_PageNum' }

  class Document

    attr_reader :source
    attr_reader :xref
    attr_reader :objs

    def initialize(s)

      fail ArgumentError.new('not a PDF file') \
        unless s.match(/\A%PDF-\d+\.\d+\n/)

      @source = s
      @xref = nil
      @objs = {}

      index = 0
      matches = {}
      #
      loop do

        matches[:obj] ||= s.match(/^(\d+ \d+) obj\b/, index)
        matches[:endobj] ||= s.match(/\bendobj\b/, index)
        #
        OBJ_ATTRIBUTES.each do |k, v|
          matches[k] ||= s.match(/\/#{v} (\/?[^\/\n<>]+)/, index)
        end
        #
        matches[:startxref] ||= s.match(/\bstartxref\s+(\d+)\s*%%EOF/, index)

        objm = matches[:obj]
        sxrm = matches[:startxref]

        break unless sxrm || objm

        fail ArgumentError.new('failed to find "startxref"') unless sxrm

        sxri = sxrm.offset(0).first
        obji = objm ? objm.offset(0).first : sxri + 1

        if obji < sxri
          obj = Podoff::Obj.extract(self, matches)
          @objs[obj.ref] = obj
          index = obj.end_index + 1
        else
          @xref = sxrm[1].to_i
          index = sxrm.offset(0).last + 1
          matches.delete(:startxref)
        end
      end
    end

    def pages

      @objs.values.select { |o| o.type == '/Page' }
    end

    def page(index)

      pas = pages
      return nil if pas.empty?

      if pas.first.attributes[:pagenum]
        pas.find { |pa| pa.page_number == index }
      else
        pas.at(index - 1)
      end
    end

    def write(path)

      # TODO
    end
  end

  class Obj

    def self.extract(doc, matches)

      re = matches[:obj][1]
      st = matches[:obj].offset(0).first
      en = matches[:endobj].offset(0).last - 1

      atts = {}

      OBJ_ATTRIBUTES.keys.each do |k|
        m = matches[k]
        if m && m.offset(0).last < en
          atts[k] = m[1].strip
          matches.delete(k)
        end
      end

      matches.delete(:obj)
      matches.delete(:endobj)

      Podoff::Obj.new(doc, re, st, en, atts, false)
    end

    attr_reader :document
    attr_reader :ref
    attr_reader :start_index, :end_index
    attr_reader :attributes

    def initialize(doc, ref, st, en, atts, addition)

      @document = doc
      @ref = ref
      @start_index = st
      @end_index = en
      @attributes = atts
      @addition = addition
    end

    def addition?; @addition; end

    def to_a

      [ @ref, @start_index, @end_index, @attributes ]
    end

    def source

      @source ||= @document.source[@start_index..@end_index]
    end

    def match(regex)

      source.match(regex)
    end

    def dmatch(regex)

      if m = @document.source.match(regex, @start_index)
        m.offset(0).last > @end_index ? nil : m
      else
        nil
      end
    end

#    def lines
#
#      @lines ||= @document.source[@start_index, @end_index].split("\n")
#    end

#    def lookup(k)
#
#      #p [ @ref, lines.size ]
#
#      lines.each do |l|
#
#        m = l.match(/^\/#{k} (.*)$/)
#        return m[1] if m
#      end
#
#      nil
#    end

#    def index(o, start=0)
#
#      lines[start..-1].each_with_index do |l, i|
#
#        if o.is_a?(String)
#          return start + i if l == o
#        else
#          return start + i if l.match(o)
#        end
#      end
#
#      nil
#    end

    def type; @attributes[:type]; end

    def page_number

      r = @attributes[:pagenum]
      r ? r.to_i : nil
    end

    def is_page?

      @attributes[:type] == '/Page'
    end

    def parent

      r = @attributes[:parent]
      r ? r[0..-2].strip : nil
    end

    def kids

      r = @attributes[:kids]
      (r || '').split(/[\[\]R]/).collect(&:strip).reject(&:empty?)
    end

    def contents

      r = @attributes[:contents]
      (r || '').split(/[\[\]R]/).collect(&:strip).reject(&:empty?)
    end

#    def dup(new_doc)
#
#      o0 = self
#      o = o0.class.new(new_doc, @ref)
#      o.instance_eval { @lines = o0.lines.dup }
#
#      o
#    end

    def find(opts={}, &block)

      return self if block.call(self)

      (kids + contents).compact.each do |k|
        o = @document.objs[k]
        return o if o && block.call(o)
      end

      nil
    end

#    def crop_box
#
#      r = lookup('CropBox') || lookup('MediaBox')
#
#      r ? r.strip[1..-2].split(' ').collect(&:strip).collect(&:to_f) : nil
#    end
#
#    def crop_dims
#
#      x, y, w, h = crop_box
#
#      x ? [ w - x, h - y ] : nil
#    end
  end
end

