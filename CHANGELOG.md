
# CHANGELOG.md


## podoff 1.4.0  not yet released


## podoff 1.3.0  released 2020-03-30

* Introduce Podoff::Stream#line
* Introduce Podoff::Stream#rectangle


## podoff 1.2.4  released 2019-03-12

* Let Stream#bt/#text accept a nil string


## podoff 1.2.3  released 2019-03-12

* Introduce Stream#rg(red, green, blue)
* Silence 2 Ruby warnings


## podoff 1.2.2  released 2017-02-13

* Use rb: + enc instead of just r: + enc, should fix issues on Windows


## podoff 1.2.1  released 2017-02-01

* Fail with ArgumentError when pdf not "unpacked"


## podoff 1.2.0  released 2015-11-11

* require encoding upon loading and parsing, introduce Document#encoding
* drop Podoff::Obj#page_number
* use /Kids in /Pages to determine pages and page order


## podoff 1.1.1  released 2015-10-26

* reworked xref table output
* FlateDecode stream if length > 98


## podoff 1.1.0  released 2015-10-25

* more tolerant at parsing (StringScanner)
* bin/podoff
* Document#rewrite(path)


## podoff 1.0.0  released 2015-10-23

* leverage incremental updates


## podoff 0.9.1  not released

* ensure Obj#contents accepts arrays


## podoff 0.9.0  released 2015-10-21

* beta release


## podoff 0.0.1  released 2015-10-20

* initial, empty, release

