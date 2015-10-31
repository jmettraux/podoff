
# podoff

[![Build Status](https://secure.travis-ci.org/jmettraux/podoff.png)](http://travis-ci.org/jmettraux/podoff)
[![Gem Version](https://badge.fury.io/rb/podoff.png)](http://badge.fury.io/rb/podoff)

A Ruby tool to deface PDF documents.

Uses "incremental updates" to do so.

Podoff is used to write over PDF documents. Those documents should first be uncompressed (and recompressed) (how? see [below](#preparing-documents-for-use-with-podoff))

```ruby
require 'podoff'

d = Podoff.load('d2.pdf')
  # load my d2.pdf

fo = d.add_base_font('Helvetica')
  # make sure the document knows about "Helvetica"
  # (one of the base 13 or 14 fonts PDF readers know about)


pa = d.page(1)
  # grab first page of the document

pa.insert_font('/MyHelvetica', fo)
  # link "MyHelvetica" to the base font above for this page

st =
  d.add_stream {
    tf '/MyHelvetica', 12 # Helvetica size 12
    bt 100, 100, "#{Time.now} stamped via podoff" # text at bottom left
  }

pa.insert_content(st)
  # add content to page

d.write('d3.pdf')
  # write stamped document to d3.pdf
```

For more about the podoff "api", read ["how I use podoff"](#how-i-use-podoff).

If you're looking for serious libraries, look at

* https://github.com/payrollhero/pdf_tempura
* https://github.com/prawnpdf/prawn-templates


## preparing documents for use with podoff

Podoff is naive and can't read xref tables in object streams. You have to work against PDF documents that have vanilla xref tables. [Qpdf](http://qpdf.sourceforge.net/) to the rescue.

Given a doc0.pdf you can produce such a document by doing:
```
qpdf --object-streams=disable doc0.pdf doc1.pdf
```
doc1.pdf is now ready for overwriting with podoff.

qpdf has rewritten the PDF, extracting the xref table but keeping the streams compressed.


## bin/podoff

`bin/podoff` is a command-line tool for to preparing/check PDFs before use.

```
$ ./bin/podoff -h

Usage: ./bin/podoff [option] {fname}

    -o, --objs                       List objs
    -w, --rewrite                    Rewrite
    -s, --stamp                      Apply time stamp at bottom of each page
    -r, --recompress                 Recompress
    --version                        Show version
    -h, --help                       Show this message
```

`--recompress` is mostly an alias for `qpdf --object-streams=disable in.pdf out.pf`

`--stamp` is used to check whether podoff can add a time stamp on each page of an input PDF.


## how I use podoff

In the application which necessitated the creation of podoff, there are two PDF to generate from time to time.

I keep those two PDFs in memory.

```ruby
# lib/myapp/pdf.rb

require 'podoff'

module MyApp::Pdf

  DOC0 = Podoff.load('pdf_templates/d0.pdf')
  DOC1 = Podoff.load('pdf_templates/d1.pdf')

  def generate_doc0(data, path)

    d = DOC0.dup # shallow copy of the document
    d.add_fonts

    pa2 = d.page(2)
    st = d.add_stream # open stream...

    st.font 'MyHelv', 12 # font is an alias to tf
    st.text 100, 100, data['customer_name']
    st.text 100, 80, data['customer_phone']
    st.text 100, 60, data['date'] if data['date']
      # fill in customer info on page 2

    pa2.insert_content(st) ... close stream (yes, you can use a block too)

    pa3 = d.page(3)
    pa3.insert_content(d.add_stream { check 52, 100 }) if data['discount']
      # a single check on page 3 if the customer gets a discount

    d.write(path)
  end

  # ...
end

module Podoff # adding a few helper methods to the podoff classes

  class Document

    # Makes sure Helvetica and ZapfDingbats are available
    # on each page of the document
    #
    def add_fonts

      fo0 = add_base_font('/Helvetica')
      fo1 = add_base_font('/ZapfDingbats')

      pages.each { |pa|
        pa = re_add(pa)
        pa.insert_font('/MyHelv', fo0)
        pa.insert_font('/MyZapf', fo1)
      }
    end
  end

  class Stream

    # Places a check mark ✓ at x, y
    #
    def check(x, y)

      font = @font            # save current font
      self.tf '/MyZapf', 12   # switch to ZapfDingbats size 12
      self.bt x, y, '3'       # check mark
      @font = font            # get back to saved font
    end
  end
end
```

The documents are kept in memory, as generation request comes, the get duplicated, incrementally updated and the filled documents are written to disk. The duplication doesn't copy the whole document file, only the references to the "obj" in the document get copied.


## disclaimer

The author of this tool/library have no link whatsoever with the authors of the sample PDF documents found under `pdfs/`. Those documents have been selected because they are representative of the PDF forms podoff is meant to ~~deface~~fill.


## known bugs

* podoff parsing is naive, documents that contain uncompressed streams with "endobj", "startxref", "/Root" will disorient podoff


## links

* http://qpdf.sourceforge.net/ source: https://github.com/qpdf/qpdf

* http://www.slideshare.net/ange4771/advanced-pdf-tricks


## LICENSE

MIT, see [LICENSE.txt](LICENSE.txt)

