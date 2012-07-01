fs      = require 'fs'
urlib   = require 'url'
http    = require 'http'
util    = require 'util'
eco     = require 'eco'
colors  = require 'colors'
mime    = require 'mime'
less    = require 'less'
mongodb = require 'mongodb'

app = {}

# -------------------------------------------------------------------
# Config.
json = fs.readFileSync './config.json'
try
    CONFIG = JSON.parse json
catch err
    throw err.message.red

# -------------------------------------------------------------------
# Init and start the server.
app.start = (logging=true) ->
    # Shall we log?
    CONFIG.log = logging

    startServer = ->
        server.listen port
        log "Listening on port #{port}".green.bold

    if process.env.PORT? # Heroku
        port = process.env.PORT
        host = CONFIG.production.host
        db = new mongodb.Db(CONFIG.production.mongodb.db,
            new mongodb.Server(CONFIG.production.mongodb.host, CONFIG.production.mongodb.port,
                'auto_reconnect': true
            )
        )
        db.open (err) ->
            throw err.message.red if err
            db.authenticate process.env.MONGOHQ_USER, process.env.MONGOHQ_PASSWORD, (err) ->
                throw err.message.red if err

                startServer()

    else # Local development.
        port = CONFIG.development.port
        host = CONFIG.development.host
        db = new mongodb.Db(CONFIG.development.mongodb.db,
            new mongodb.Server(CONFIG.development.mongodb.host, CONFIG.development.mongodb.port,
                'auto_reconnect': true
            )
        )
        db.open (err, db) ->
            throw err.message.red if err

            startServer()

# Stop server programatically.
app.stop = ->
    server.on "close", -> process.exit()
    server.close()

# -------------------------------------------------------------------
# Routes.
app.router = 'routes': { 'GET': {}, 'POST': {} }
app.router.get = (route, callback) -> app.router.routes.GET[route] = callback
app.router.post = (route, callback) -> app.router.routes.POST[route] = callback

# -------------------------------------------------------------------
# Eco template rendering and helpers.
app.render = (response, filename, data={}) ->
    fs.readFile "#{__dirname}/templates/#{filename}.eco", "utf8", (err, template) ->
        return error err, response if err

        resource = eco.render template, data

        response.writeHead 200,
            'Content-Type':  'text/html'
            'Content-Length': resource.length
        response.write resource
        response.end()

# -------------------------------------------------------------------
# LESS CSS rendering.
css = (response, path) ->
    fs.readFile path, "utf8", (err, f) ->
        return error err, response if err

        less.render f, (err, resource) ->
            return error err, response if err

            # Info header about the source.
            t = resource.split("\n") ; t.splice(0, 0, "/* #{path} */\n") ; resource = t.join("\n")

            response.writeHead 200,
                'Content-Type':  'text/css'
                'Content-Length': resource.length
            response.write resource
            response.end()

# -------------------------------------------------------------------
# Logging and errors.
log = (message) -> if CONFIG.log then console.log message

error = (error, response) ->
    log new String(error.message).red
    response.writeHead 404
    response.end()

# -------------------------------------------------------------------
# Main routing loop.
server = http.createServer (request, response) ->

    url = request.url.toLowerCase()
    route = app.router.routes[request.method][url.split('?')[0]]
    
    # Do we know this route?
    if route
        log "#{request.method} #{url}".bold
        route request, response, urlib.parse(request.url, true).query
    else
        switch request.method
            when 'GET'
                # Public resource?
                log "#{request.method} #{url}".grey

                file = "#{__dirname}#{url}"
                # LESS?
                if file[-9...] is '.less.css'
                    css response, file.replace('.less.css', '.less')
                else
                    fs.stat file, (err, stat) ->
                        if err
                            # 404.
                            log "#{url} not found".red
                            response.writeHead 404
                            response.end()
                        else
                            # Cache control.
                            mtime = stat.mtime
                            etag = stat.size + '-' + Date.parse(mtime)
                            response.setHeader('Last-Modified', mtime);

                            if request.headers['if-none-match'] is etag
                                response.statusCode = 304
                                response.end()
                            else
                                # Stream file.
                                response.writeHead 200,
                                    'Content-Type':   mime.lookup file
                                    'Content-Length': stat.size
                                    'ETag':           etag

                                util.pump fs.createReadStream(file), response, (err) ->
                                    return error err, response if err
            else
                error { 'message': 'No matching route' }, response

# Make the app externally available.
exports.app = app