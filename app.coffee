#!/usr/bin/env coffee

app = require('./pallur/server.coffee').app

app.router.get "/", (request, response) ->
    app.render response, 'index', 'message': 'Hello world'

app.start()