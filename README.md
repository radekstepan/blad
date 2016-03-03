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

###Content

The site pages are maintained as sets of Markdown files with YAML front-matter. The name corresponds to the url of the page so, for example, `/content/people/radek.md` will get mapped to the `/people/radek` URL.

Among the fields one can set in the front-matter, `template` is the most important one. It sets a Swig HTML file that will be used to render the page. Not specifying this property will make the page serve `204 No Content` when accessed.

Fields are represented as key-value pairs of arbitrary depth.

###Layouts

Is a place where [Swig](http://paularmstrong.github.io/swig/) templates live. They can be extended and macros work too.

If a `404.html` template is provided together with a document entitled `404.md`, these will be rendered when a user tries to visit a page that does not exist.

You can access the URL of a page you are on by using the `url` key.

####Relations

You can access content in other documents by using the relations helper object.

To get a list of top-level pages in the CMS use:

```
{% for page in rel.menu() %}
  {{ page.url }}
{% endfor %}
```

To get a list of sibling documents:

```
{% for page in rel.siblings(url) %}
  {{ page.url }}
{% endfor %}
```

You can get a list of children of depth `n`:

```
{% for page in rel.children(url, n) %}
  {{ page.url }}
{% endfor %}
```

Access the first existing parent document:

```
{% set parent = rel.parent(url) %}
```

Check if one document is the same as another or one of its descendants:

```
{% set isFamily = rel.isFamily('/people', '/people') %}
```

Or just check if one document is a child of another:

```
{% set isChild = rel.isChild('/people', '/people/radek') %}
```

###Helpers

Are modules (in JS or CoffeeScript) that can be accessed at page render stage. Typically they will be used to access remote data to then be rendered in a page. In a YAML front-matter we would request a helper like so:

```
---
helpers:
  people: my_helper.js
---
```

The first time a page is rendered, the helper in `my_helper.js` is called. It is expected to be a function with two parameters, `data` and `cb`. The former is a map of key-value fields from the front-matter, the latter a callback for when the helper has done its job. As an example:

```js
module.exports = (data, cb) => {
  // Do some work...

  // Call back.
  cb(null, result);
};
```

You can access 3rd party libraries here by defining them in `package.json` of the site.

The data is then accessible under the key `people` (in the example above) in the page layout and saved for `--cache` amount of time. This is a startup parameter and saves having us make potentially expensive operations every time a page is requested.

###Public

All static content, like CSS and JS files, can be accessed here. Use `/public/path` in layouts when accessing these files.
