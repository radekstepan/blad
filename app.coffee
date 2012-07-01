#!/usr/bin/env coffee
app = require('./pallur/server.coffee').app

eco = require 'eco'
marked = require 'marked'

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

# For testing.
exports.app = app

# -------------------------------------------------------------------

Blað = {}

# MongoDB collection connection.
Blað.documents = (cb) ->
    app.db.collection process.env.NODE_ENV or 'documents', (err, collection) -> cb collection unless err

# Save/update a document.
Blað.save = (doc, cb) ->
    Blað.documents (collection) ->
        collection.insert doc,
            'safe': false
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
        , (err, document) ->
            if document and not err
                # Instantiate the type.
                switch document.type
                    when 'basic'
                        doc = new BasicDocument document
                    when 'markdown'
                        doc = new MarkdownDocument document

                # Render.
                response.write doc?.render()
                response.end()
            else
                # 404, should not happen...
                response.writeHead 404
                response.end()

# Document types.
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

class MarkdownDocument extends Blað.Type

    # Presentation for the document.
    render: -> marked @content