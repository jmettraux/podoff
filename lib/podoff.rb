
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

  VERSION = '1.0.1'

  def self.load(path, encoding='iso-8859-1')

    Podoff::Document.load(path, encoding)
  end

  def self.parse(s)

    Podoff::Document.new(s)
  end

  #OBJ_ATTRIBUTES =
  #  { type: 'Type', subtype: 'Subtype',
  #    parent: 'Parent', kids: 'Kids', contents: 'Contents', annots: 'Annots',
  #    pagenum: 'pdftk_PageNum' }
  OBJ_ATTRIBUTES =
    { type: 'Type', contents: 'Contents', pagenum: 'pdftk_PageNum' }

  class Document

    def self.load(path, encoding='iso-8859-1')

      Podoff::Document.new(File.open(path, 'r:' + encoding) { |f| f.read })
    end

    def self.parse(s)

      Podoff::Document.new(s)
    end

    attr_reader :source
    attr_reader :xref
    attr_reader :objs
    attr_reader :obj_counters
    attr_reader :root
    #
    attr_reader :additions

    def initialize(s)

      fail ArgumentError.new('not a PDF file') \
        unless s.match(/\A%PDF-\d+\.\d+\n/)

      @source = s
      @xref = nil
      @objs = {}
      @obj_counters = {}
      @root = nil

      @additions = {}

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

        @root = nil if @root && index > @root.offset(0).last
        @root ||= s.match(/\/Root (\d+ \d+) R\b/, index)

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

      fail ArgumentError.new('found no /Root') unless @root
      @root = @root[1]
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
        @obj_counters = o.obj_counters.dup

        @root = o.root

        @additions =
          o.additions.inject({}) { |h, (k, v)| h[k] = v.dup(self); h }

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

    def new_ref

      "#{
        @objs.keys.inject(-1) { |i, r| [ i, r.split(' ').first.to_i ].max } + 1
      } 0"
    end

    def add(obj)

      @objs[obj.ref] = obj
      @additions[obj.ref] = obj

      obj
    end

    def add_base_font(name)

      name = name[1..-1] if name[0] == '/'

      ref = new_ref

      add(
        Obj.create(
          self,
          ref,
          [
            "#{ref} obj",
            "<< /Type /Font /Subtype /Type1 /BaseFont /#{name} >>",
            "endobj"
          ].join(' ')))
    end

    def add_stream(s=nil, &block)

      ref = new_ref

      s = s || make_stream(&block)

      s = [
        "#{ref} obj",
        "<< /Length #{s.length} >>",
        "stream\n#{s}\nendstream",
        "endobj"
      ].join("\n") if s.is_a?(String)

      o = add(Obj.create(self, ref, s))

      s.is_a?(Podoff::Stream) ? s : o
    end

    def re_add(obj_or_ref)

      obj = obj_or_ref.is_a?(String) ? @objs[obj_or_ref] : obj_or_ref

      obj = obj.replicate unless obj.replica?

      add(obj)
    end

    def write(path)

      f = (path == :string) ? StringIO.new : File.open(path, 'wb')

      f.write(@source)

      if @additions.any?

        pointers = {}

        @additions.values.each do |o|
          f.write("\n")
          pointers[o.ref] = f.pos + 1
          if o.source.is_a?(String)
            f.write(o.source)
          else # Stream
            s = o.source.to_s
            f.write("#{o.ref} obj\n<< /Length #{s.length} >>\n")
            f.write("stream\n#{s}\nendstream\nendobj")
          end
        end
        f.write("\n\n")

        xref = f.pos + 1

        f.write("xref\n")
        f.write("0 1\n")
        f.write("0000000000 65535 f\n")

        pointers.each do |k, v|
          f.write("#{k.split(' ').first} 1\n")
          f.write(sprintf("%010d 00000 n\n", v))
        end

        f.write("trailer\n")
        f.write("<<\n")
        f.write("/Prev #{self.xref}\n")
        f.write("/Size #{objs.size}\n")
        f.write("/Root #{root} R\n")
        f.write(">>\n")
        f.write("startxref #{xref}\n")
        f.write("%%EOF\n")
      end

      f.close

      f.is_a?(StringIO) ? f.string : nil
    end

    def rewrite(path=:string)

      f =
        (path == :string || path == '-') ?
        StringIO.new :
        File.open(path, 'wb')

      v = source.match(/%PDF-\d+\.\d+/)[0]
      f.write(v)
      f.write("\n")

      ptrs = {}

      objs.keys.sort.each do |k|
        ptrs[k] = f.pos + 1
        f.write(objs[k].source)
        f.write("\n")
      end

      xref = f.pos + 1
      max = objs.keys.inject(-1) { |i, k| [ i, k.split(' ')[0].to_i ].max }

      f.write("xref\n0 #{max}\n0000000000 65535 f\n")

      (1..max).each do |i|
        k = "#{i} 0"
        k = ptrs.has_key?(k) ?  k : objs.keys.find { |k| k.match(/^#{i} \d+$/) }
        if k
          f.write(sprintf("%010d 00000 n\n", ptrs[k]))
        else
          f.write("0000000000 00000 n\n")
        end
      end

      f.write("trailer\n")
      f.write("<<\n")
      f.write("/Size #{objs.size}\n")
      f.write("/Root #{root} R\n")
      f.write(">>\n")
      f.write("startxref #{xref}\n")
      f.write("%%EOF\n")

      f.close

      f.is_a?(StringIO) ? f.string : nil
    end

    private

    def make_stream(&block)

      s = Stream.new
      s.instance_exec(&block) if block

      s
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

      recompute_attributes if @source.is_a?(String)
      @source.obj = self if @source.is_a?(Podoff::Stream)
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

    def replica?

      @source != nil
    end

    def type

      @attributes && @attributes[:type]
    end

    def page_number

      r = @attributes && @attributes[:pagenum]
      r ? r.to_i : nil
    end

#    def parent
#
#      r = @attributes[:parent]
#      r ? r[0..-2].strip : nil
#    end
#
#    def kids
#
#      r = @attributes[:kids]
#      (r || '').split(/[\[\]R]/).collect(&:strip).reject(&:empty?)
#    end
#
#    def contents
#
#      r = @attributes[:contents]
#      (r || '').split(/[\[\]R]/).collect(&:strip).reject(&:empty?)
#    end

#    def add_annotation(ref)
#
#      if annots = @attributes[:annots]
#        fail "implement me!"
#      else
#        i = @source.index('/Type ')
#        @source.insert(i, "/Annots [#{ref} R]\n")
#      end
#      recompute_attributes
#    end

#    def add_free_text(x, y, text, font, size)
#
#      fail ArgumentError.new('target is not a page') unless type == '/Page'
#
#      nref = document.new_ref
#
#      s = [
#        "#{nref} obj <<",
#        "/Type /Annot",
#        "/Subtype /FreeText",
#        "/Da (/F1 70 Tf 0 100 Td)",
#        "/Rect [0 0 500 600]",
#        "/Contents (#{text})",
#        ">>",
#        "endobj"
#      ].join("\n")
#      anno = Obj.create(document, nref, s)
#
#      page = self.replicate
#      page.add_annotation(nref)
#
#      document.add(anno)
#      document.add(page)
#
#      anno
#    end

    def insert_font(nick, obj_or_ref)

      fail ArgumentError.new("target '#{ref}' not a replica") \
        unless @source

      nick = nick[1..-1] if nick[0] == '/'

      re = obj_or_ref
      re = re.ref if re.respond_to?(:ref)

      @source = @source.gsub(/\/Font\s*<</, "/Font\n<<\n/#{nick} #{re} R")
    end

    def insert_contents(obj_or_ref)

      fail ArgumentError.new("target '#{ref}' not a replica") \
        unless @source
      fail ArgumentError.new("target '#{ref}' doesn't have /Contents") \
        unless @attributes[:contents]

      re = obj_or_ref
      re = re.obj if re.respond_to?(:obj) # Stream
      re = re.ref if re.respond_to?(:ref)

      add_to_attribute(:contents, re)
    end
    alias :insert_content :insert_contents

    protected

    def recompute_attributes

      @attributes =
        OBJ_ATTRIBUTES.inject({}) do |h, (k, v)|
          m = @source.match(/\/#{v} (\/?[^\/\n<>]+)/)
          h[k] = m[1] if m
          h
        end
    end

    def concat(refs, ref)

      refs = refs.strip
      refs = refs[1..-2] if refs[0] == '['

      "[#{refs} #{ref} R]"
    end

    def add_to_attribute(key, ref)

      fail ArgumentError.new("obj not replicated") unless @source

      pkey = OBJ_ATTRIBUTES[key]

      if v = @attributes[key]
        v = concat(v, ref)
        @source = @source.gsub(/#{pkey} ([\[\]0-9 R]+)/, "#{pkey} #{v}")
      else
        i = @source.index('/Type ')
        @source.insert(i, "/#{pkey} [#{ref} R]\n")
      end
      recompute_attributes
    end
  end

  class Stream

    attr_accessor :obj

    def initialize

      @font = nil
      @content = StringIO.new
    end

    #def document; obj.document; end
    #def ref; obj.ref; end
    #def source; self; end

    def tf(font_name, font_size)

      n = font_name[0] == '/' ? font_name[1..-1] : font_name

      @font = "/#{n} #{font_size} Tf "
    end
    alias :font :tf

    def bt(x, y, text)

      @content.write "\n" if @content.size > 0
      @content.write "BT "
      @content.write @font if @font
      @content.write "#{x} #{y} Td (#{escape(text)}) Tj"
      @content.write " ET"
    end
    alias :text :bt

    def write(text)

      @content.write(text)
    end

    def to_s

      @content.string
    end

    protected

    def escape(s)

      s.gsub(/\(/, '\(').gsub(/\)/, '\)')
    end
  end
end

