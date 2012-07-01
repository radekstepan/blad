#!/usr/bin/env coffee
app = require('./pallur/server.coffee').app

urlib = require 'url'

app.router.get "/api/type", (request, response, params) ->
    response.write 'success'
    response.end()

app.router.post "/api/document", (request, response, params) ->
    response.write 'success'
    response.end()    

app.start()

# For testing.
exports.app = app

# -------------------------------------------------------------------

Blað = {}

Blað.storage = {}

class Blað.Type

class Basic extends Blað.Type
    
    id:  null
    url: null