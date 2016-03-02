#blað

A minimalist flat-file CMS with dynamic content.

[![Build Status](https://img.shields.io/travis/radekstepan/blad/master.svg?style=flat)](https://travis-ci.org/radekstepan/blad)
[![Dependencies](http://img.shields.io/david/radekstepan/blad.svg?style=flat)](https://david-dm.org/radekstepan/blad)
[![License](http://img.shields.io/badge/license-AGPL--3.0-red.svg?style=flat)](LICENSE)

##Features

1. Reads content from Markdown files and YAML front-matter.
1. No database or write access to disk needed.
1. In-memory cache maintains dynamic content defined in helper functions.
1. Powerful [Swig](http://paularmstrong.github.io/swig/) templating.

##Quickstart

```bash
$ npm install blad -g
$ blad --port 8080
# blad/4.0.0-alpha started on port 8080
```

##Configuration

The following command will launch a blad server on port `5050`, sourcing files from the `example/` directory and keep all cached content for a period of `1` day.

```bash
$ ./bin/blad.js --port 5050 --source example/ --cache 1440
```
