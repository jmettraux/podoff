
# podoff

[![Build Status](https://secure.travis-ci.org/jmettraux/podoff.png)](http://travis-ci.org/jmettraux/podoff)
[![Gem Version](https://badge.fury.io/rb/podoff.png)](http://badge.fury.io/rb/podoff)

A Ruby tool to deface PDF documents.

Podoff is used to write over PDF documents. Those documents should first be uncompressed (and recompressed) (how? see [below](#preparing-documents-for-use-with-podoff))

```
# TODO
```

If you're looking for serious libraries, look at

* https://github.com/payrollhero/pdf_tempura
* https://github.com/prawnpdf/prawn-templates


## preparing documents for use with podoff

Podoff is naive and can't read xref tables in object streams. You have to work against PDF documents that have vanilla xref tables. [Qpdf](http://qpdf.sourceforge.net/) to the rescue.

Given a doc0.pdf you can produce such a document by doing:
```
qpdf --qdf --object-streams=disable doc0.pdf doc1.pdf
```
doc1.pdf is now ready for overwriting with podoff.

I use podoff to stamp or fill forms inside (well over) the PDF document, and I have to keep the resulting PDF around. It's better to work with compressed PDFs. Our doc0.pdf has its streams uncompressed.

To recompress the streams but keep the vanilla xref table:
```
qpdf doc1.pdf doc2.pdf
```

doc2.pdf will be smaller and still usable with podoff.


## bin/podoff

TODO


## disclaimer

The author of this tool/library have no link whatsoever with the authors of the sample PDF documents found under `pdfs/`. Those documents have been selected because they are representative of the PDF forms podoff is meant to ~~deface~~fill.


## known bugs

* podoff parsing is naive, documents that contain uncompressed streams with "endobj", "startxref", "/Root" will disorient podoff


## links

* http://qpdf.sourceforge.net/
* https://github.com/qpdf/qpdf

* http://www.slideshare.net/ange4771/advanced-pdf-tricks


## LICENSE

MIT, see [LICENSE.txt](LICENSE.txt)

