
require 'zlib'
require 'strscan'
require 'stringio'


module Podoff

  VERSION = '1.2.4'

  def self.load(path, encoding)

    Podoff::Document.load(path, encoding)
  end

  def self.parse(s, encoding)

    Podoff::Document.new(s, encoding)
  end

  class Document

    def self.load(path, encoding)

      Podoff::Document.new(
        File.open(path, 'rb:' + encoding) { |f| f.read },
        encoding
      )
    end

    def self.parse(s)

      Podoff::Document.new(s)
    end

    attr_reader :encoding

    attr_reader :scanner
    attr_reader :version
    attr_reader :xref
    attr_reader :objs
    attr_reader :obj_counters
    attr_reader :root
    #
    attr_reader :additions

    def initialize(s, encoding)

      fail ArgumentError.new('not a PDF file') \
        unless s.match(/\A%PDF-\d+\.\d+\s/)

      @encoding = encoding

      @scanner = ::StringScanner.new(s)
      @version = nil
      @xref = nil
      @objs = {}
      @obj_counters = {}
      @root = nil

      @additions = {}

      @version = @scanner.scan(/%PDF-\d+\.\d+/)

      loop do

        @scanner.skip_until(
          /(startxref\s+\d+|\d+\s+\d+\s+obj|\/Root\s+\d+\s+\d+\s+R)/)

        m = @scanner.matched
        break unless m

        if m[0] == 's'
          @xref = m.split(' ').last.to_i
        elsif m[0] == '/'
          @root = extract_ref(m)
        else
          obj = Podoff::Obj.extract(self)
          @objs[obj.ref] = obj
          @obj_counters[obj.ref] = (@obj_counters[obj.ref] || 0) + 1
        end
      end

      if @root == nil
        @scanner.pos = 0
        loop do
          @scanner.skip_until(/\/Root\s+\d+\s+\d+\s+R/)
          break unless @scanner.matched
          @root = extract_ref(@scanner.matched)
        end
      end
    end

    def source

      @scanner.string
    end

    def updated?

      @additions.any?
    end

    def dup

      o = self

      self.class.allocate.instance_eval do

        @encoding = o.encoding

        @scanner = ::StringScanner.new(o.source)
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

      #@objs.values.select { |o| o.type == '/Page' }

      ps = @objs.values.find { |o| o.type == '/Pages' }

      fail ArgumentError.new(
        "no /Pages, the PDF is not usable by Podoff as is, you have to do " +
        "`qpdf --object-streams=disable original.pdf unpacked.pdf` " +
        "and use unpacked.pdf instead of original.pdf"
      ) unless ps

      extract_refs(ps.attributes[:kids]).collect { |r| @objs[r] }
    end

    def page(index)

      if index < 0
        pages[index]
      elsif index == 0
        nil
      else
        pages[index - 1]
      end
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

      r = new_ref
      s = "#{r} obj <</Type /Font /Subtype /Type1 /BaseFont /#{name}>> endobj"

      add(Obj.new(self, r, source: s))
    end

    def add_stream(src=nil, &block)

      ref = new_ref

      src =
        src &&
        [
          "#{ref} obj",
          "<< /Length #{src.size} >>\nstream\n#{src}\nendstream",
          "endobj"
        ].join("\n")

      str =
        src ?
        nil :
        make_stream(&block)

      obj = add(Obj.new(self, ref, source: src, stream: str))

      str || obj
    end

    def re_add(obj_or_ref)

      obj = obj_or_ref.is_a?(String) ? @objs[obj_or_ref] : obj_or_ref

      obj = obj.replicate unless obj.replica?

      add(obj)
    end

    def write(path=:string, encoding=nil)

      encoding ||= @encoding

      f =
        case path
          when :string, '-' then StringIO.new
          when String then File.open(path, 'wb')
          else path
        end
      f.set_encoding(encoding) # internal encoding: nil
      #f.set_encoding(encoding, encoding)

      f.write(source)

      if @additions.any?

        pointers = {}

        @additions.values.each do |o|
          f.write("\n")
          pointers[o.ref.split(' ').first.to_i] = f.pos
          f.write(o.to_s.force_encoding(encoding))
        end
        f.write("\n\n")

        xref = f.pos

        write_xref(f, pointers)

        f.write("trailer\n")
        f.write("<<\n")
        f.write("/Prev #{self.xref}\n")
        f.write("/Size #{objs.size + 1}\n")
        f.write("/Root #{root} R\n")
        f.write(">>\n")
        f.write("startxref #{xref}\n")
        f.write("%%EOF\n")
      end

      f.close if path.is_a?(String) || path.is_a?(Symbol)

      f.is_a?(StringIO) ? f.string : nil
    end

    def rewrite(path=:string, encoding=nil)

      encoding ||= @encoding

      f =
        case path
          when :string, '-' then StringIO.new
          when String then File.open(path, 'wb')
          else path
        end
      f.set_encoding(encoding)

      v = source.match(/%PDF-\d+\.\d+/)[0]
      f.write(v)
      f.write("\n")

      pointers = {}

      objs.keys.sort.each do |k|
        pointers[k.split(' ').first.to_i] = f.pos
        f.write(objs[k].source.force_encoding(encoding))
        f.write("\n")
      end

      xref = f.pos

      write_xref(f, pointers)

      f.write("trailer\n")
      f.write("<<\n")
      f.write("/Size #{objs.size + 1}\n")
      f.write("/Root #{root} R\n")
      f.write(">>\n")
      f.write("startxref #{xref}\n")
      f.write("%%EOF\n")

      f.close if path.is_a?(String) || path.is_a?(Symbol)

      f.is_a?(StringIO) ? f.string : nil
    end

    protected

    def write_xref(f, pointers)

      f.write("xref\n")
      f.write("0 1\n")
      f.write("0000000000 65535 f \n")

      pointers
        .keys
        .sort
        .inject([ [] ]) { |ps, k|
          ps << [] if ps.last != [] && k > ps.last.last + 1
          ps.last << k
          ps
        }
        .each { |part|
          f.write("#{part.first} #{part.size}\n")
          part.each { |k| f.write(sprintf("%010d 00000 n \n", pointers[k])) }
        }
    end

    def make_stream(&block)

      s = Stream.new
      s.instance_exec(&block) if block

      s
    end

    def extract_ref(s)

      s.gsub(/\s+/, ' ').gsub(/[^0-9 ]+/, '').strip
    end

    def extract_refs(s)

      s.gsub(/\s+/, ' ').scan(/(\d+ \d+) R/).collect(&:first)
    end
  end

  class Obj

    ATTRIBUTES = { type: 'Type', contents: 'Contents', kids: 'Kids' }

    def self.extract(doc)

      sca = doc.scanner

      re = sca.matched[0..-4].strip
      st = sca.pos - sca.matched.length

      i = sca.skip_until(/endobj/); return nil unless i
      en = sca.pos - 1

      Podoff::Obj.new(doc, re, start_index: st, end_index: en)
    end

    attr_reader :document
    attr_reader :ref
    attr_reader :start_index, :end_index
    attr_reader :stream
    attr_reader :attributes

    def initialize(doc, ref, opts={})

      @document = doc
      @ref = ref

      @start_index = opts[:start_index]
      @end_index = opts[:end_index]
      @attributes = nil
      @source = opts[:source]

      @stream = opts[:stream]
      @stream.obj = self if @stream

      recompute_attributes
      #@source.obj = self if @source.is_a?(Podoff::Stream)

      @document.scanner.pos = @end_index if @document.scanner && @end_index
    end

    def dup(new_doc)

      self.class.new(
        new_doc, ref,
        start_index: start_index, end_index: end_index)
    end

    #def self.create(doc, ref, source)
    #  self.new(doc, ref, nil, nil, nil, source)
    #end

    def replicate

      self.class.new(document, ref, source: source.dup)
    end

    def to_a

      [ @ref, @start_index, @end_index, @attributes ]
    end

    def source

      @source || (@start_index && @document.source[@start_index..@end_index])
    end

    def replica?

      @source != nil
    end

    def type

      @attributes && @attributes[:type]
    end

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

    def to_s

      source || stream.to_s
    end

    protected

    def recompute_attributes

      st, en, sca =
        if @start_index
          [ @start_index, @end_index, @document.scanner ]
        elsif @source
          [ 0, @source.length, ::StringScanner.new(@source) ]
        end

      return unless sca

      @attributes =
        ATTRIBUTES.inject({}) do |h, (k, v)|
          sca.pos = st
          i = sca.skip_until(/\/#{v}\b/)
          h[k] = sca.scan(/ *\/?[^\n\r\/>]+/).strip if i && sca.pos < en
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

      pkey = ATTRIBUTES[key]

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

    def initialize(obj=nil)

      @obj = obj
      @font = nil
      @color = nil
      @content = StringIO.new
    end

    def tf(font_name, font_size)

      n = font_name[0] == '/' ? font_name[1..-1] : font_name

      @font = "/#{n} #{font_size} Tf "
    end
    alias :font :tf

    def rg(red, green, blue)

      @color = "#{red} #{green} #{blue} rg "
    end
    alias :color :rg
    alias :rgb :rg

    def bt(x, y, text)

      return unless text

      @content.write "\n" if @content.size > 0
      @content.write "BT "
      @content.write @font if @font
      @content.write @color if @color
      @content.write "#{x} #{y} Td (#{escape(text)}) Tj"
      @content.write " ET"
    end
    alias :text :bt

    def write(text)

      @content.write(text)
    end

    def to_s

      s = @content.string
      f = ''
      if s.length > 98
        f = ' /Filter /FlateDecode'
        s = Zlib::Deflate.deflate(s)
      end

      "#{obj.ref} obj\n" +
      "<</Length #{s.size}#{f}>>\nstream\n#{s}\nendstream\n" +
      "endobj"
    end

    protected

    def escape(s)

      s.gsub(/\(/, '\(').gsub(/\)/, '\)')
    end
  end
end

