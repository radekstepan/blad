#!/usr/bin/env coffee
app = require('./pallur/server.coffee').app

urlib = require 'url'

app.router.get "/api/type", (request, response, params) ->
    response.write 'success'
    response.end()

app.start()

Type = {}

class Type.Plain

    fields:
        'main': # A unique identifier for this field.
            'type': 'textarea' # What content will this hold.
            'description': 'This is the page text.' # Description for the client.

# For testing.
exports.app = app