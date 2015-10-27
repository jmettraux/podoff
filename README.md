
# podoff

[![Build Status](https://secure.travis-ci.org/jmettraux/podoff.png)](http://travis-ci.org/jmettraux/podoff)
[![Gem Version](https://badge.fury.io/rb/podoff.png)](http://badge.fury.io/rb/podoff)

A Ruby tool to deface PDF documents.

Podoff is used to write over PDF documents. Those documents should first be uncompressed (and recompressed).

```
# TODO
```

If you're looking for serious libraries, look at

* https://github.com/payrollhero/pdf_tempura
* https://github.com/prawnpdf/prawn-templates


## preparing documents for use with podoff

TODO


## bin/podoff

TODO


## disclaimer

The author of this tool/library have no link whatsoever with the authors of the sample PDF documents found under `pdfs/`. Those documents have been selected because they are representative of the PDF forms podoff is meant to ~~deface~~fill.


## known bugs

* podoff parsing is naive, documents that contain uncompressed streams with "endobj", "startxref", "/Root" will disorient podoff


## links

* http://www.slideshare.net/ange4771/advanced-pdf-tricks


## LICENSE

MIT, see [LICENSE.txt](LICENSE.txt)

