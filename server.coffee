#!/usr/bin/env coffee

flatiron = require 'flatiron'
connect  = require 'connect'
mongodb  = require 'mongodb'
urlib    = require 'url'
eco      = require 'eco'
fs       = require 'fs'

app = flatiron.app
app.use flatiron.plugins.http,
    'before': [
        connect.favicon()
        connect.static './public'
    ]

app.start 1118, (err) ->
    throw err if err
    app.log.info "Listening on port #{app.server.address().port}"

# -------------------------------------------------------------------
# Plugins.
app.use
    name: "eco-templating"
    attach: (options) ->
        app.eco = (filename, data, cb) ->
            fs.readFile "./templates/#{filename}.eco", "utf8", (err, template) ->
                throw err if err

                cb eco.render template, data

# Start.
mongodb.Db.connect "mongodb://localhost:27017/documents", (err, db) ->
    throw err if err
    app.log.info "Fired up MongoDB"

    app.use
        name: "mongodb"
        attach: (options) ->
            app.db = (cb) ->
                db.collection 'documents', (err, collection) ->
                    throw err if err
                    cb collection

# -------------------------------------------------------------------
# Bootstrap the CMS frontend.
app.router.path "/", ->
    @get ->
        app.log.info "Bootstrapping app"

        app.eco 'index', {}, (html) =>
            @res.writeHead 200,
                'content-type':  'text/html'
                'content-length': html.length
            @res.write html
            @res.end()

# Get all documents.
app.router.path "/api/documents", ->
    @get ->
        app.log.info "Get all documents"

        app.db (collection) =>
            collection.find().toArray (err, docs) =>
                throw err if err
                @res.writeHead 200, "content-type": "application/json"
                @res.write JSON.stringify docs
                @res.end()

# Get/update/create a document.
app.router.path "/api/document", ->
    @get ->
        app.log.info "Get a document"

        app.db (collection) =>
            params = urlib.parse(@req.url, true).query
            collection.findOne '_id': params._id, (err, doc) =>
                @res.writeHead 200, "content-type": "application/json"
                @res.write JSON.stringify doc
                @res.end()

    editSave = ->
        app.log.info "Edit/create a document"
        
        Blað.save @req.body, (url) =>
            Blað.map url

            @res.writeHead 201
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
        collection.insert doc,
            'safe': false
        , (err, records) ->
            throw err if err
            cb records[0].url

# Map a document to a public URL.
Blað.map = (url) => app.router.path url, Blað.get

# Retrieve publicly mapped document.
Blað.get = ->
    @get ->
        # Get the doc from the db.
        app.db (collection) =>
            collection.findOne
                'url': @req.url.toLowerCase()
            , (err, record) ->
                throw err if err
                response.write (new Blað.types[record.type](record))?.render()
                response.end()

# Document types.
Blað.types = {}

class Blað.Type

    constructor: (params) ->
        for key, value of params
            @[key] = value

# Expose.
exports.app = app
exports.Blað = Blað