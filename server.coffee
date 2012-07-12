#!/usr/bin/env coffee

flatiron = require 'flatiron'
union    = require 'union'
connect  = require 'connect'
mongodb  = require 'mongodb'
urlib    = require 'url'
fs       = require 'fs'
eco      = require 'eco'
marked   = require 'marked'

app = flatiron.app
app.use flatiron.plugins.http,
    'before': [
        connect.favicon()
        connect.static './public'
    ]

app.start 1118, (err) ->
    throw err if err
    app.log.info "Listening on port #{app.server.address().port}".green if process.env.NODE_ENV isnt 'test'

# -------------------------------------------------------------------
# Eco templating.
app.use
    name: "eco-templating"
    attach: (options) ->
        app.eco = (filename, data, cb) ->
            fs.readFile "./templates/#{filename}.eco", "utf8", (err, template) ->
                throw err if err

                cb eco.render template, data

# Start MongoDB.
mongodb.Db.connect "mongodb://localhost:27017/documents", (err, db) ->
    throw err if err
    app.log.info "Fired up MongoDB".green if process.env.NODE_ENV isnt 'test'

    # Add a collection plugin.
    app.use
        name: "mongodb"
        attach: (options) ->
            app.db = (cb) ->
                db.collection process.env.NODE_ENV or 'documents', (err, collection) ->
                    throw err if err
                    cb collection

    # Map all existing documents.
    app.db (collection) ->
        collection.find().toArray (err, docs) ->
            throw err if err
            for doc in docs
                app.router.path doc.url, Blað.get


# -------------------------------------------------------------------
# Get all documents.
app.router.path "/api/documents", ->
    @get ->
        app.log.info "Get all documents" if process.env.NODE_ENV isnt 'test'

        app.db (collection) =>
            collection.find().toArray (err, docs) =>
                throw err if err
                @res.writeHead 200, "content-type": "application/json"
                @res.write JSON.stringify docs
                @res.end()

# Get/update/create a document.
app.router.path "/api/document", ->
    @get ->
        params = urlib.parse(@req.url, true).query

        app.log.info "Get document " + params._id.blue if process.env.NODE_ENV isnt 'test'

        app.db (collection) =>
            collection.findOne '_id': mongodb.ObjectID.createFromHexString(params._id), (err, doc) =>
                @res.writeHead 200, "content-type": "application/json"
                @res.write JSON.stringify doc
                @res.end()

    editSave = ->
        doc = @req.body

        if doc._id?
            # Editing existing.
            app.log.info "Edit document " + doc._id.blue if process.env.NODE_ENV isnt 'test'
            # Convert _id to object.
            doc._id = mongodb.ObjectID.createFromHexString doc._id
            cb = => @res.writeHead 200
        else
            # Creating a new one.
            app.log.info "Create new document" if process.env.NODE_ENV isnt 'test'
            cb = => @res.writeHead 201

        # One command to save.
        Blað.save doc, (url) =>
            app.log.info "Mapping url " + url.blue if process.env.NODE_ENV isnt 'test'

            # Map a document to a public URL.
            app.router.path url, Blað.get

            cb()
            @res.end()

    @post editSave
    @put editSave

app.router.path "/reset", ->
    @get ->
        app.db (collection) =>
            collection.remove {}, (err, removed) =>
                throw err if err
                @res.end()

# -------------------------------------------------------------------
# Blað.
Blað = {}

# Save/update a document.
Blað.save = (doc, cb) ->
    app.db (collection) ->
        if doc._id?
            # Update.
            collection.update '_id': doc._id
            , doc
            , 'safe': true
            , (err) ->
                throw err if err
                cb doc.url
        else
            # Insert.
            collection.insert doc,
                'safe': true
            , (err, records) ->
                throw err if err
                cb records[0].url

# Retrieve publicly mapped document.
Blað.get = ->
    @get ->
        # Get the doc from the db.
        app.db (collection) =>
            collection.findOne
                'url': @req.url.toLowerCase()
            , (err, record) =>
                throw err if err

                app.log.info 'Serving document ' + new String(record._id).blue if process.env.NODE_ENV isnt 'test'

                @res.writeHead 200, "content-type": "text/html"
                @res.write (new Blað.types[record.type]?(record))?.render()
                @res.end()

# Document types.
Blað.types = {}

class Blað.Type

    constructor: (params) ->
        for key, value of params
            @[key] = value


class BasicDocument extends Blað.Type

    # Eco template.
    template: '<%= @_id %>'

    # Presentation for the document.
    render: ->
        eco.render @template,
            '_id': @_id
            'url': @url

Blað.types.BasicDocument = BasicDocument

class MarkdownDocument extends Blað.Type

    # Presentation for the document.
    render: -> marked @markup

Blað.types.MarkdownDocument = MarkdownDocument

# Expose.
exports.app = app
exports.Blað = Blað