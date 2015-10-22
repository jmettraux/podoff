
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

  def self.load(path, encoding='iso-8859-1')

    Podoff::Document.load(path, encoding)
  end

  OBJ_ATTRIBUTES =
    { type: 'Type', subtype: 'Subtype',
      parent: 'Parent', kids: 'Kids', contents: 'Contents', annots: 'Annots',
      pagenum: 'pdftk_PageNum' }

  class Document

    def self.load(path, encoding='iso-8859-1')

      Podoff::Document.new(File.open(path, 'r:' + encoding) { |f| f.read })
    end

    attr_reader :source
    attr_reader :xref
    attr_reader :objs
    attr_reader :obj_counters
    #
    attr_reader :additions

    def initialize(s)

      fail ArgumentError.new('not a PDF file') \
        unless s.match(/\A%PDF-\d+\.\d+\n/)

      @source = s
      @xref = nil
      @objs = {}
      @obj_counters = {}
      @additions = []

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
          @obj_counters[obj.ref] = (@obj_counters[obj.ref] || 0) + 1
          index = obj.end_index + 1
        else
          @xref = sxrm[1].to_i
          index = sxrm.offset(0).last + 1
          matches.delete(:startxref)
        end
      end
    end

    def updated?

      @additions.any?
    end

    def dup

      o = self

      self.class.allocate.instance_eval do

        @source = o.source
        @xref = o.xref
        @objs = o.objs.inject({}) { |h, (k, v)| h[k] = v.dup(self); h }

        self
      end
    end

    def pages

      @objs.values.select { |o| o.type == '/Page' }
    end

    def page(index)

      return nil if index == 0

      pas = pages
      return nil if pas.empty?

      return (
        index > 0 ? pas.at(index - 1) : pas.at(index)
      ) unless pas.first.attributes[:pagenum]

      if index < 0
        max = pas.inject(0) { |n, pa| [ n, pa.page_number ].max }
        index = max + 1 + index
      end

      pas.find { |pa| pa.page_number == index }
    end

    def write(path)

      File.open(path, 'wb') { |f| f.write(@source) }

      fail "implement me!" if updated?
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

      Podoff::Obj.new(doc, re, st, en, atts)
    end

    attr_reader :document
    attr_reader :ref
    attr_reader :start_index, :end_index
    attr_reader :attributes

    def initialize(doc, ref, st, en, atts, source=nil)

      @document = doc
      @ref = ref
      @start_index = st
      @end_index = en
      @attributes = atts
      @source = source
    end

    def dup(new_doc)

      self.class.new(new_doc, ref, start_index, end_index, attributes.dup)
    end

    def self.create(doc, ref, source)

      self.new(doc, ref, nil, nil, nil, source)
    end

    def replicate

      self.class.create(document, ref, source.dup)
    end

    def to_a

      [ @ref, @start_index, @end_index, @attributes ]
    end

    def source

      @source || @document.source[@start_index..@end_index]
    end

    def addition?

      @source != nil
    end

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

    def add_free_text(x, y, text, font, size)

      fail ArgumentError.new('target is not a page') unless type == '/Page'

      o = self.replicate

      pp o.source.split("\n")
    end
  end
end

