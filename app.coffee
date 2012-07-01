#!/usr/bin/env coffee
app = require('./pallur/server.coffee').app

eco = require 'eco'
marked = require 'marked'

# Get all documents.
app.router.get "/api/documents", (request, response, params) ->
    response.writeHead 200,
        "Content-Type": "application/json"
    response.write JSON.stringify Blað.storage
    response.end()

# Create the document and map it to a url.
app.router.post "/api/documents", (request, response, params) ->
    switch params.type
        when 'basic'
            Blað.save new BasicDocument params
            response.writeHead 201
        when 'markdown'
            Blað.save new MarkdownDocument params
            response.writeHead 201
        else
            response.writeHead 404

    response.end()

app.start()

# For testing.
exports.app = app

# -------------------------------------------------------------------

Blað = {}
Blað.storage = []

# Save new document.
Blað.save = (doc) ->
    Blað.storage.push doc

    # Map the document to a URL.
    app.router.get doc.url, (request, response, params) ->
        response.write doc.render()
        response.end()

# Document types.
class Blað.Type

    constructor: (params) ->
        for key, value of params
            @[key] = value

class BasicDocument extends Blað.Type

    # Eco template.
    template: '<%= @id %>'

    # Presentation for the document.
    render: ->
        eco.render @template,
            'id':  @id
            'url': @url

class MarkdownDocument extends Blað.Type

    # Presentation for the document.
    render: -> marked @content