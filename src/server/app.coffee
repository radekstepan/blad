#!/usr/bin/env coffee
flatiron = require 'flatiron' # web app framework
union    = require 'union'    # error handler middleware
director = require 'director' # routing
winston  = require 'winston'  # logging

connect  = require 'connect'  # static fileserving middleware
mongodb  = require 'mongodb'  # databasing
eco      = require 'eco'      # templating
async    = require 'async'    # asynchronous utilities

crypto   = require 'crypto'   # md5 hashing
fs       = require 'fs'
path     = require 'path'

# log, compile, copy, db io utilities.
utils = require './utils.js'

# Export the database io scripts.
exports.db = utils.db

# Blad object for Presenter declarations.
exports.blad = exports.blað = blad = require './blad.js'

# Configure the Flatiron app.
configureApp = ({ config, log }) ->
    app = flatiron.app

    # HTTP plugin.
    app.use flatiron.plugins.http,
        'before': config.middleware.concat [
            # Have a nice favicon.
            connect.favicon()

            # Static file serving.
            connect.static __dirname + '/../public'
            
            # Authorize all calls to the API.
            (req, res, next) ->
                if req.url.match(new RegExp("^/api", 'i'))
                    # Is key provided?
                    if !req.headers['x-blad-apikey']?
                        res.writeHead 403
                        res.write '`X-Blad-ApiKey` needs to be provided in headers of all API requests'
                        res.end()
                    else
                        # Is the key valid?
                        if req.headers['x-blad-apikey'] in config.browserid.hashes
                            next()
                        else
                            res.writeHead 403
                            res.write 'Invalid `X-Blad-ApiKey` authorization'
                            res.end()
                else
                    # Go on then...
                    next()
        ]
        'onError': (err, req, res) ->
            log.error err.message
            # Trying to reach a 'page' on admin?
            if err.status is 404 and req.url.match(new RegExp("^/admin", 'i'))?
                # Redirect to the admin route so we can take it from there.
                res.redirect '/admin', 301
            else
                # Go Union!
                union.errorHandler err, req, res

    # Eco templating plugin.
    app.use
        name: 'eco-templating'
        attach: (options) ->
            app.eco = (file, data, cb) ->
                fs.readFile path.join(config.site_src, "/src/types/#{file}.eco"), 'utf8', (err, template) ->
                    if err then cb err
                    else
                        try
                            cb null, eco.render template, data
                        catch err
                            cb err

    # MongoDB collection plugin.
    db = null # connection once set
    app.use
        name: 'mongodb'
        attach: (options) ->
            app.db = (done) ->
                collection = (done) ->
                    db.collection config.env, (err, coll) ->
                        throw err if err
                        done coll

                unless db?
                    log.debug 'Connect to MongoDB'

                    mongodb.Db.connect config.mongodb, (err, connection) ->
                        throw err if err
                        mcfg = connection.serverConfig
                        log.info 'Connected to ' + "mongodb://#{mcfg.host}:#{mcfg.port}/#{mcfg.db.databaseName}".bold
                        db = connection
                        collection done
                else
                    collection done

    # Expose the following in reqs.
    expose =
        'config': config
        'log':    log
        'blad':   blad
        'app':    app

    # Require API routes automatically.
    routes = {} ; p = "#{__dirname}/routes"
    ( ( routes[url] = obj for url, obj of require("#{p}/#{file}")(expose) ) for file in fs.readdirSync p )

    # A new Director router.
    app.router = new director.http.Router routes

    app

# Exposed firestarter that builds the site and starts the service.
exports.start = (cfg, site_src, done) ->
    # Config and logger once set so we do not have to pass them around the fns.
    config = {} ; log = null

    # Where is the site source? Only used in production btw.
    config.site_src = site_src

    # Deep copy of config (and check dict passed in).
    readConfig = (cb) ->
        log.debug 'Duplicate config'

        try
            # Extend the object.
            ( config[key] = value for key, value of JSON.parse JSON.stringify cfg )
            cb null
        catch err
            cb err

    # Start flatiron app on a port.
    startApp = (cb) ->
        log.debug 'Setup & start ' + 'flatiron'.grey

        # Configure the app, adding routes etc.
        app = configureApp({ 'config': config, 'log': log })
        
        # Start and cb with the finished product.
        app.start config.port, (err) ->
            if err then cb err
            else cb null, app

    # Welcome.
    welcome = (cb) ->
        async.parallel [ (_cb) ->
            try
                _cb null, require "#{__dirname}/../../package.json"
            catch err
                _cb err
        ,
            async.apply(fs.readFile, "#{__dirname}/../../logo.txt", 'utf8')
        
        ], (err, [ pkg, logo ]) ->
            if err then cb err
            else
                if typeof pkg isnt 'object' then [ logo, pkg ] = [ pkg, logo ]

                log.info 'Welcome to ' + "blad #{pkg.version}".grey

                ( log.help line.cyan.bold for line in logo.split('\n') )
                
                log.help ''
                log.help 'A forms based Node.js CMS'
                log.help ''
                
                cb null
    
    # Go env or config? And validate.
    validateConfig = (cb) ->
        log.debug 'Validate config'

        # Resolve config coming from environment and the `cfg` dict.
        config.mongodb        = process.env.MONGO_URL or process.env.DATABASE_URL or config.mongodb # MongoDB database
        config.port           = process.env.PORT or config.port                                     # port number
        config.env            = process.env.NODE_ENV or 'documents'                                 # environment/collection to use
        config.browserid     ?= {}
        config.browserid.salt = process.env.API_SALT or config.browserid.salt                       # API key salt
        config.middleware    ?= []

        # Validate file.
        if not config.browserid? or
          not config.browserid.provider? or
            not config.browserid.salt? or
              not config.browserid.users? or
                not config.browserid.users instanceof Array
                    return cb 'You need to create a valid `browserid` section'
        if not config.mongodb?
            return cb 'You need to specify the `mongodb` uri'

        # Create create hashes of salt + user emails.
        config.browserid.hashes = []
        for email in config.browserid.users
            config.browserid.hashes.push crypto.createHash('md5').update(email + config.browserid.salt).digest('hex')

        # Using middleware?
        use = (pkg) ->            
            switch pkg
                when 'connect-baddies'
                    return do require pkg
                else
                    throw new Error "Unknown middleware `#{pkg}`"
        
        try
            config.middleware = ( use('connect-' + suffix) for suffix in config.middleware)
            cb null
        catch err
            cb err

    # Code compilation.
    compile = (cb) ->
        log.debug 'Build site code'

        # Attach our logger.
        utils.log (message) -> log.data message

        # Compile our and their code.
        async.waterfall [
            utils.compile.admin,
            utils.compile.forms(config),
            utils.copy.public(config),
            utils.copy.additions(config),
            utils.include.presenters(config)
        ], (err, presenters) ->
            if err then cb err
            else cb null, presenters

    # Include site's presenters on us.
    include = (presenters, cb) ->
        log.debug 'Including custom presenters: ' + ( ( p = f.split('/'); p[p.length - 2] ) for f in presenters ).join(', ')

        # Traverse all plain functions.
        for f in presenters
            # Require the file.
            req = require f
            # Get the first key - a document that will be exposed, hopefully.
            key = Object.keys(req)[0]
            # Extend the function on us.
            blad.types[key] = req[key]

        cb null

    # Map all existing public documents, no checking whether they are OK...
    map = (app, cb) ->
        log.debug 'Map existing documents'

        app.db (collection) ->
            collection.find('public': true).toArray (err, docs) ->
                if err then cb err
                else
                    for doc in docs
                        log.info 'Mapping url ' + doc.url.underline
                        app.router.path doc.url, blad.get
                    cb null, app

    # OK or bust?
    fin = (err, app) ->
        if err
            try
                err = JSON.parse(err)
                log.error err.error.message or err.message or err
            catch e
                log.error err
        else
            log.debug 'Done'

            log.info 'Listening on port ' + app.server.address().port.toString().bold
            log.info 'blad'.grey + ' started ' +  'ok'.green.bold
            
            # Callback?
            if done and typeof done is 'function' then done app

    # What is the environment?
    if process.env.NODE_ENV isnt 'test'
        # CLI output.
        winston.cli()
        # File output.
        winston.add winston.transports.File, 'filename': "#{__dirname}/../../blad.log"
        # Expose.
        log = winston

        # Actual sequence goes here.
        async.waterfall [ welcome, readConfig, validateConfig, compile, include, startApp, map ], fin
    else
        # Go silent.
        winston.loggers.add 'dummy', 'console': 'silent': true
        log = winston.loggers.get 'dummy'

        # Under test condition.
        async.waterfall [ readConfig, startApp ], fin