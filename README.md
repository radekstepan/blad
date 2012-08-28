# Blað
A forms based [node.js](http://nodejs.org/) CMS ala [SilverStripe](http://www.silverstripe.com/), but smaller.

The idea was to create a RESTful CMS API that would be edited using a client side app. On the backend, we use [flatiron](http://flatironjs.org/) and on the frontend [chaplin](https://github.com/chaplinjs/chaplin) that itself wraps [Backbone.js](http://documentcloud.github.com/backbone/).

![image](https://raw.github.com/radekstepan/blad/master/example.png)

## Start the service and admin app

Configure the `salt` and emails of `users` that are allowed access to the admin area and `port` number for the server and uri for `mongodb` in `config.json`.

Install [MongoDB](http://www.mongodb.org/display/DOCS/Quickstart) and start the service.

```bash
$ sudo mongod
```

We wrap the compilation of user code and core code using `cake` but first, dependencies need to be met.

```bash
$ npm install -d
$ npm start
```

Visit [http://127.0.0.1:1118/admin](http://127.0.0.1:1118/admin) and modify port number as appropriate.

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

File upload fields are a special case that need to have two fields defined. One for the actual `type="file"` and one for a place where the field will be loaded client side:

```eco
<input type="hidden" name="image" value="<%= @image %>" />
<input type="file" data-target="image" />
```

The attribute `data-target`, then, specifies which field to populate with base64 encoded version of the file client side.

### Public presenter

Represented by a `presenter.coffee` file.

Each document has a custom class that determines how it is rendered. It has to only have a `render` function defined that takes a callback with contect that is passed to a template. As an example of Markdown rendering that returns the HTML result under the `html` key:

```coffeescript
marked = require 'marked'

class MarkdownDocument extends Blað.Type

    # Presentation for the document.
    render: (done) -> done 'html': marked @markup

Blað.types.MarkdownDocument = MarkdownDocument
```

Extending the `Blað.Type` class gives us the following helpers:

* `@children()` or `@children(n)` that returns public and private documents (optionally of a specific level) that begin with the same URL as the current document... its children.
* `@menu()` that returns public and private top level documents; those documents that have only a leading slash in its URL.

### Public template

Represented by a `template.eco` file.

This file is populated with a context coming from the presenter. In the above Markdown example, we have passed only the `html` key - value forward.

## Mocha test suite

To run the tests execute the following.

```bash
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