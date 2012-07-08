#!/usr/bin/env coffee

app = require('./pallur/server.coffee').app

# Get all documents.
app.router.get "/api/documents", (request, response, params) ->
    Blað.documents (collection) ->
        collection.find().toArray (err, docs) ->
            response.writeHead 200, "Content-Type": "application/json"
            response.write JSON.stringify docs
            response.end()

# Create the document and map it to a url.
app.router.post "/api/documents", (request, response, params) ->
    Blað.save params, (url) ->
        Blað.map url

        response.writeHead 201
        response.end()

app.start()

# -------------------------------------------------------------------

Blað = {}

# MongoDB collection connection.
Blað.documents = (cb) ->
    app.db.collection process.env.NODE_ENV or 'documents', (err, collection) -> cb collection unless err

# Save/update a document.
Blað.save = (doc, cb) ->
    Blað.documents (collection) ->
        collection.insert doc,
            'safe': true
        , (err, records) ->
            cb records[0].url

# Map a document to a public URL.
Blað.map = (url) -> app.router.get url, Blað.get

# Retrieve publicly mapped document.
Blað.get = (request, response, params) ->
    # Get the doc from the db.
    Blað.documents (collection) ->
        collection.findOne
            'url': request.url.toLowerCase()
        , (err, record) ->
            if record and not err
                # Render.
                response.write (new Blað.types[record.type](record))?.render()
                response.end()
            else
                # 404, should not happen...
                response.writeHead 404
                response.end()

# Document types.
Blað.types = {}

class Blað.Type

    constructor: (params) ->
        for key, value of params
            @[key] = value

# -------------------------------------------------------------------

# Expose.
exports.app = app
exports.Blað = Blað