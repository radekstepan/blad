# blað

A forms based [node.js](http://nodejs.org/) CMS ala [SilverStripe](http://www.silverstripe.com/), but smaller.

[ ![Codeship Status for radekstepan/blad](https://www.codeship.io/projects/2629dad0-6f02-0130-c859-22000a1d8b6d/status?branch=master)](https://www.codeship.io/projects/1939)

The idea was to create a RESTful CMS API that would be edited using a client side app. On the backend, we use [flatiron](http://flatironjs.org/) and on the frontend [chaplin](https://github.com/chaplinjs/chaplin) that itself wraps [Backbone.js](http://documentcloud.github.com/backbone/).

![image](https://raw.github.com/radekstepan/blad/master/example.png)

## Getting started

The way to use this CMS is to require it as a package. See [blað example site](https://github.com/radekstepan/blad-example-site) for a guide on how to do so. If you know what you are doing, require and start the service like so:

```coffeescript
fs      = require 'fs'
service = require 'blad'

config = JSON.parse fs.readFileSync './config.json'
service.start config, __dirname
```

## Creating custom document types

Create a new folder with the type name in `./src/site`. Each type consists of three files:

### Admin form

Represented by a `form.eco` file.

Each document form automatically has the `url`, `is public?` and `type` fields. Any extra fields are defined by creating a form field that has a unique `name` attribute.

For example, the Markdown document type has a `<textarea>` defined like so:

```eco
<div class="nine columns">
    <textarea name="markup"><%= @markup %></textarea>
</div>
```

Notice that to display the already saved version of that field, we use eco markup that populates a variable by the `name` of the field.

#### Files

File upload fields are a special case that need to have two fields defined. One for the actual `type="file"` and one for a place where the field will be loaded client side:

```eco
<input type="hidden" name="image" value="<%= @image %>" />
<input type="file" data-custom="file" data-target="image" />
```

The attribute `data-target`, then, specifies which field to populate with base64 encoded version of the file client side.

#### Dates

By the same token, we use [Kronic](https://github.com/xaviershay/kronic) to work with nicely formatted dates. To make use of this library, define the date fields like so:

```eco
<input type="hidden" name="published" value="<%= @published or (new Date()).toJSON() %>" />
<input type="text" data-custom="date" data-target="published" value="<%= if @published then Kronic.format(new Date(@published)) else 'Today' %>" />
```

### Public presenter

Represented by a `presenter.coffee` file.

Each document has a custom class that determines how it is rendered. It has to only have a `render` function defined that takes a callback with contect that is passed to a template. As an example of Markdown rendering that returns the HTML result under the `html` key:

```coffeescript
{ blad } = require 'blad'
marked   = require 'marked'

class exports.MarkdownDocument extends blad.Type

    # Presentation for the document.
    render: (done) -> done 'html': marked @markup
```

Extending the `blad.Type` class gives us the following helpers:

* `@children()` or `@children(n)` that returns public and private documents (optionally of a specific level) that begin with the same URL as the current document... its children.
* `@menu()` that returns public and private top level documents; those documents that have only a leading slash in its URL.

### Public template

Represented by a `template.eco` file.

This file is populated with a context coming from the presenter. In the above Markdown example, we have passed only the `html` key - value forward.

If a `/src/site/layout.eco` file is found, it will be used as a wrapping template around individual templates. The key `page` populated with the individual template is passed to it.

### Additions file

One can save a file in `src/types/additions.coffee` that exports an object. Then, this file can be included from within a Presenter. This way, you can re-use common functionality across types.

## Caching

Sometimes new data may be fetched from within the Presenter and one would like to cache these for say a day. The following shows a workflow from within the Presneter's `render()` function.

1. We check if data under a specific key is old. The second parameter represents a time in milliseconds after which to consider a key value pair to be old. One could also pass a third paramter passing in which unit the previous parameter is.
1. If all data is fresh we get a data saved under a key. We could also pass a context/document as the second parameter. This is useful if we want to retrieve cache for a sibling, child document etc.
1. If data is old, we save the new data returning the result in a callback.

```coffeescript
    # Check if data in store is old.
    if @store.isOld 'data', 300
        # Update with new info and render back.
        @store.save 'data', 'new information', =>
            done
                'data': @store.get('data')
                'was':  'old'
            , false
    else
        # Nope, all fresh.
        done
            'data': @store.get('data')
            'was':  'fresh'
        , false
```

It may be useful to know that cache is per document specific, so one can use the same cache key in different document types.

## Mocha test suite

To run the tests execute the following.

```bash
$ npm install
$ npm test
```

A `test` collection in MongoDB will be created and cleared before each spec run. Make sure the server app is switched off in order to run the tests.

```coffeescript
app.db (collection) ->
    collection.remove {}, (error, removed) ->
        collection.find({}).toArray (error, results) ->
            results.length.should.equal 0
            done()
```

If you want to test the UI through an example app, execute the following:

```bash
$ PORT=5200 npm start
```

Then visit [http://127.0.0.1:5200/admin](http://127.0.0.1:5200/admin).