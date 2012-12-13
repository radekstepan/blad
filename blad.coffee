#!/usr/bin/env coffee
flatiron = require 'flatiron'
union    = require 'union'
connect  = require 'connect'
mongodb  = require 'mongodb'
request  = require 'request'
crypto   = require 'crypto'
urlib    = require 'url'
fs       = require 'fs'
eco      = require 'eco'
Q        = require 'q'
domain   = require 'domain' # experimental!
winston  = require 'winston'

# Our utilities.
utils = require './utils.coffee'
# Export the database in/out scripts.
exports.db = utils.db

# The config once set.
CONFIG = {}
# The MongoDB connection once set.
DB = null
# Path to the site source code will be here.
SITE_PATH = null
# This is where logger will be.
LOG = null
# blað in da house.
blað = 'types': {}

setup = (SERVICE) ->
    # HTTP plugins.
    SERVICE.use flatiron.plugins.http,
        'before': [
            # Have a nice favicon.
            connect.favicon()
            # Static file serving.
            connect.static __dirname + '/public'
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
                        if req.headers['x-blad-apikey'] in CONFIG.browserid.hashes
                            next()
                        else
                            res.writeHead 403
                            res.write 'Invalid `X-Blad-ApiKey` authorization'
                            res.end()
                else
                    next()
        ]
        'onError': (err, req, res) ->
            LOG.error err.message
            # Trying to reach a 'page' on admin?
            if err.status is 404 and req.url.match(new RegExp("^/admin", 'i'))?
                res.redirect '/admin', 301
            else
                # Go Union!
                union.errorHandler err, req, res

    # Eco templating plugin.
    SERVICE.use
        name: 'eco-templating'
        attach: (options) ->
            SERVICE.eco = (path, data, cb) ->
                fs.readFile "#{SITE_PATH}/src/types/#{path}.eco", "utf8", (err, template) ->
                    if err then cb err, null
                    else
                        try
                            cb null, eco.render template, data
                        catch e
                            cb e, null

    # MongoDB collection plugin.
    SERVICE.use
        name: 'mongodb'
        attach: (options) ->
            SERVICE.db = (done) ->
                collection = (done) ->
                    DB.collection CONFIG.env, (err, coll) ->
                        throw err if err
                        done coll

                unless DB?
                    LOG.debug 'Connect to MongoDB'

                    mongodb.Db.connect CONFIG.mongodb, (err, connection) ->
                        throw err if err
                        mcfg = connection.serverConfig
                        LOG.info 'Connected to ' + "mongodb://#{mcfg.host}:#{mcfg.port}/#{mcfg.dbInstance.databaseName}".bold
                        DB = connection
                        collection done
                else
                    collection done

    # -------------------------------------------------------------------

    # BrowserID auth.
    SERVICE.router.path "/auth", ->
        @post ->
            # Authenticate.
            request.post
                'url': CONFIG.browserid.provider
                'form':
                    'assertion': @req.body.assertion
                    'audience':  "http://#{@req.headers.host}"
            , (error, response, body) =>
                throw error if error

                body = JSON.parse(body)
                
                if body.status is 'okay'
                    # Authorize.
                    if body.email in CONFIG.browserid.users
                        LOG.info "Identity verified for #{body.email}"
                        # Create API Key from email and salt for the client.
                        @res.writeHead 200, 'application/json'
                        @res.write JSON.stringify
                            'email': body.email
                            'key':   crypto.createHash('md5').update(body.email + CONFIG.browserid.salt).digest('hex')
                    else
                        LOG.warn "#{body.email} tried to access the API"
                        @res.writeHead 403, 'application/json'
                        @res.write JSON.stringify
                            'message': "Your email #{body.email} is not authorized to access the admin backend"
                else
                    # Pass on the authentication error response to the client.
                    LOG.error body.message
                    @res.writeHead 403, 'application/json'
                    @res.write JSON.stringify body
                
                @res.end()

    # -------------------------------------------------------------------

    # Sitemap.xml
    SERVICE.router.path "/sitemap.xml", ->
        @get ->
            LOG.info 'Get sitemap.xml'

            # Give me all public documents.
            SERVICE.db (collection) =>
                collection.find('public': true).toArray (err, docs) =>
                    throw err if err

                    xml = [ '<?xml version="1.0" encoding="utf-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' ]
                    for doc in docs
                        xml.push "<url><loc>http://#{@req.headers.host}#{doc.url}</loc><lastmod>#{doc.modified}</lastmod></url>"
                    xml.push '</urlset>'

                    @res.writeHead 200, "content-type": "application/xml"
                    @res.write xml.join "\n"
                    @res.end()

    # -------------------------------------------------------------------

    # Get all documents.
    SERVICE.router.path "/api/documents", ->
        @get ->
            LOG.info 'Get all documents'

            SERVICE.db (collection) =>
                collection.find({}, 'sort': 'url').toArray (err, docs) =>
                    throw err if err
                    @res.writeHead 200, "content-type": "application/json"
                    @res.write JSON.stringify docs
                    @res.end()

    # -------------------------------------------------------------------

    # Get/update/create a document.
    SERVICE.router.path "/api/document", ->
        @get ->
            params = urlib.parse(@req.url, true).query

            # We can request a document using '_id' or 'url'.
            if !params._id? and !params.url?
                @res.writeHead 404, "content-type": "application/json"
                @res.write JSON.stringify 'message': 'Use `_id` or `url` to fetch the document'
                @res.end()
            else
                # Which one are we using then?
                if params._id?
                    try
                        value = mongodb.ObjectID.createFromHexString params._id
                    catch e
                        @res.writeHead 404, "content-type": "application/json"
                        @res.write JSON.stringify 'message': 'The `_id` parameter is not a valid MongoDB id'
                        @res.end()
                        return

                    query = '_id': value
                else
                    value = decodeURIComponent params.url
                    query = 'url': value

                LOG.info "Get document #{value}"

                # Actual grab.
                SERVICE.db (collection) =>
                    collection.findOne query, (err, doc) =>
                        throw err if err

                        @res.writeHead 200, "content-type": "application/json"
                        @res.write JSON.stringify doc
                        @res.end()

        editSave = ->
            doc = @req.body

            if doc._id?
                # Editing existing.
                LOG.info "Edit document #{doc._id}"
                # Convert _id to object.
                doc._id = mongodb.ObjectID.createFromHexString doc._id
                cb = => @res.writeHead 200, "content-type": "application/json"
            else
                # Creating a new one.
                LOG.info 'Create new document'
                cb = => @res.writeHead 201, "content-type": "application/json"

            # One command to save/update and optionaly unmap.
            blað.save doc, (err, reply) =>
                if err
                    LOG.error 'I am different...'

                    @res.writeHead 400, "content-type": "application/json"
                    @res.write JSON.stringify reply
                    @res.end()
                
                else
                    if doc.public
                        # Map a document to a public URL.
                        LOG.info 'Mapping url ' + reply.underline
                        SERVICE.router.path reply, blað.get

                    # Stringify the new document so Backbone can see what has changed.
                    SERVICE.db (collection) =>
                        collection.findOne 'url': reply, (err, doc) =>
                            throw err if err
                            
                            cb()
                            @res.write JSON.stringify doc
                            @res.end()

        @post editSave
        @put editSave

        # Remove a document.
        @delete ->
            params = urlib.parse(@req.url, true).query

            # We can request a document using '_id' or 'url'.
            if !params._id? and !params.url?
                @res.writeHead 404, "content-type": "application/json"
                @res.write JSON.stringify 'message': 'Use `_id` or `url` to specify the document'
                @res.end()
            else
                # Which one are we using then?
                if params._id?
                    try
                        value = mongodb.ObjectID.createFromHexString params._id
                    catch e
                        @res.writeHead 404, "content-type": "application/json"
                        @res.write JSON.stringify 'message': 'The `_id` parameter is not a valid MongoDB id'
                        @res.end()
                        return
                    
                    query = '_id': value
                else
                    value = decodeURIComponent params.url
                    query = 'url': value

                LOG.info "Delete document #{value}"

                # Find and delete.
                SERVICE.db (collection) =>
                    # Do we have the document?
                    collection.findAndModify query, [], {}, 'remove': true, (err, doc) =>
                        throw err if err

                        # Did this doc actually exist?
                        if doc
                            # Unmap the url.
                            blað.unmap doc.url

                            # Respond in kind.
                            @res.writeHead 200, "content-type": "application/json"
                            @res.end()
                        else
                            @res.writeHead 404, "content-type": "application/json"
                            @res.end()

    # -------------------------------------------------------------------

    # Save/update a document.
    blað.save = (doc, cb) ->
        # Prefix URL with a forward slash if not present.
        if doc.url[0] isnt '/' then doc.url = '/' + doc.url
        # Remove trailing slash if present.
        if doc.url.length > 1 and doc.url[-1...] is '/' then doc.url = doc.url[...-1]
        # Are we trying to map to core URLs?
        if doc.url.match(new RegExp("^/admin|^/api|^/auth|^/sitemap.xml", 'i'))?
            cb true, 'url': 'Is in use by core application'
        else
            # Is the URL mSERVICEable?
            m = doc.url.match(new RegExp(/^\/(\S*)$/))
            if !m then cb true, 'url': 'Does that look valid to you?'
            else
                SERVICE.db (collection) ->
                    # Do we have the `public` attr?
                    if doc.public?
                        # Coerce boolean.
                        switch doc.public
                            when 'true'  then doc.public = true
                            when 'false' then doc.public = false

                    # Update the document timestamp in ISO 8601.
                    doc.modified = (new Date()).toJSON()

                    # Check that the URL is unique and has not been elsewhere besides us.
                    if doc._id?
                        # Update.
                        collection.find(
                            '$or': [
                                { 'url': doc.url },
                                { '_id': doc._id }
                            ]
                        ).toArray (err, docs) =>
                            throw err if err

                            if docs.length isnt 1 then cb true, 'url': 'Is in use already'
                            else
                                # Unmap the original URL if it was public.
                                old = docs.pop()
                                if old.public then blað.unmap old.url

                                # Get the id and remove the key as we cannot modify that one.
                                _id = doc._id
                                delete doc._id

                                # Update the collection.
                                collection.update '_id': _id
                                    , { '$set': doc } # run an update only to not remove cache etc.
                                    , 'safe': true
                                    , (err) ->
                                        throw err if err
                                        cb false, doc.url
                    else
                        # Insert.
                        collection.find('url': doc.url).toArray (err, docs) =>
                            throw err if err

                            if docs.length isnt 0 then cb true, 'url': 'Is in use already'
                            else
                                collection.insert doc,
                                    'safe': true
                                , (err, records) ->
                                    throw err if err
                                    cb false, records[0].url

    # Retrieve publicly mSERVICEed document.
    blað.get = ->
        @get ->
            # Get the doc(s) from the db. We want to get the whole 'group'.
            SERVICE.db (collection) =>
                collection.find({'url': new RegExp('^' + @req.url.toLowerCase())}, {'sort': 'url'}).toArray (err, docs) =>
                    throw err if err

                    record = docs[0]

                    # Any children?
                    if docs.length > 1 then record._children = (d for d in docs[1...docs.length])

                    LOG.debug 'Render url ' + (record.url or record._id).underline

                    # Do we have this type?
                    if blað.types[record.type]
                        # Create a new domain for the 'untrusted' presenter.
                        doom = domain.create()

                        # Handle this doom like this.
                        doom.on 'error', (err) =>
                            # Can we grace?
                            try
                                LOG.error t = "Error occurred, sorry: #{err}"
                                @res.writeHead 500
                                @res.end t
                                @res.on 'close', ->
                                    # Forcibly shut down any other things added to this domain.
                                    doom.dispose()

                            catch err
                                # Tried our best. Clean up anything remaining.
                                doom.dispose()

                        # Finally execute the presenter in the domain context.
                        doom.run =>
                            # Init new type passing the data and "this" SERVICE.
                            presenter = new blað.types[record.type](record, SERVICE)

                            # Give us the data.
                            presenter.render (context, template=true) =>
                                if template
                                    # Render as HTML using template.
                                    SERVICE.eco "#{record.type}/template", context, (err, html) =>
                                        if err
                                            @res.writeHead 500
                                            @res.write err.message
                                            @res.end()
                                        else
                                            # Do we have a layout template to render to?
                                            SERVICE.eco 'layout', 'page': html, (err, layout) =>
                                                @res.writeHead 200, 'content-type': 'text/html'
                                                @res.write if err then html else layout
                                                @res.end()
                                else
                                    # Render as is, JSON.
                                    @res.writeHead 200, 'content-type': 'application/json'
                                    @res.write JSON.stringify context
                                    @res.end()
                    else
                        LOG.warn t = "Document type #{record.type} not one of #{Object.keys(blað.types).join(', ')}"
                        @res.writeHead 500
                        @res.write t
                        @res.end()

    # Unmap document from router.
    blað.unmap = (url) ->
        LOG.info 'Delete url ' + url.underline

        # A bit of hairy tweaking.
        if url is '/' then delete SERVICE.router.routes.get
        else
            # Multiple levels deep?
            r = SERVICE.router.routes
            parts = url.split '/'
            for i in [1...parts.length]
                if i + 1 is parts.length
                    r[parts.pop()].get = undefined
                else
                    r = r[parts[i]]

# This gets used circullarly, you DO NOT have access to anything beyond this class.
class blað.Type

    # Returns top level documents.
    menu: (cb) ->
        @service.db (collection) =>
            collection.find({'url': new RegExp("^\/([^/|\s]*)$")}, {'sort': 'url'}).toArray (err, docs) =>
                throw err if err
                cb docs

    # Provides children for a certain depth.
    children: (n) ->
        return {} unless @_children
        if n?
            ( child for child in @_children when ( if @url is '/' then child.url else child.url.replace(@url, '') ).split('/').length is n + 2 )
        else
            @_children

    # Grab siblings of this article, for example all blog articles when viewing one article (based on URL).
    siblings: (cb) ->
        # Split to parts.
        parts = @url.split('/')
        # Join.
        url = parts[0...-1].join('/')
        end = parts[-1...]

        # Query.
        @service.db (collection) =>
            # Find us documents that are not us, but have all but last part of the url like us and have the same depth.
            collection.find({'url': new RegExp('^' + url.toLowerCase() + "\/(?!\/|#{end}).*")}, {'sort': 'url'}).toArray (err, docs) =>
                throw err if err

                cb(docs or [])

    # Grab a parent article of this one, if present (based on URL).
    parent: (cb) ->
        # Split to parts.
        parts = @url.split('/')
        # No way parent?
        return cb({}) unless parts.length > 2
        # Join.
        url = parts[0...-1].join('/')
        # Query.
        @service.db (collection) =>
            collection.find({'url': new RegExp('^' + url.toLowerCase())}, {'sort': 'url'}).toArray (err, docs) =>
                throw err if err

                # No parent.
                return cb({}) unless docs.length > 0

                # Return 
                return cb docs[0]

    # Needs to be overriden.
    render: (done) -> done {}

    # Link to "this" SERVICE.
    constructor: (params, @service) ->
        # Expand model on us but maintain a blacklist.
        for key, value of params
            @[key] = value unless key in [ 'store', 'menu', 'children', 'siblings', 'parent', 'render', 'constructor', 'service' ]

        # Store of objects under `cache` key so we get context of this object.
        @store =
            # Get a key optionally on an object.
            get: (key, obj) =>
                if obj? then obj.cache[key]?.value
                else @cache?[key]?.value

            # Save key value pair to the cache.
            save: (key, value, done) =>
                # Need to init?
                @cache ?= {}
                # Locally update the object.
                @cache[key] =
                    'value': value
                    'modified': (new Date()).toJSON()
                
                # Update the object in the db.
                @service.db (collection) =>
                    # Update the collection.
                    collection.update '_id': @_id # what if someone changes this in the Presenter?
                        , { '$set': { 'cache': @cache } }
                        , 'safe': true
                        , (err) ->
                            throw err if err
                            done()

            # Check if cache is too old given the time interval passed.
            isOld: (key, ms, interval='ms') =>
                # Adjust the interval.
                switch interval
                    when 's', 'second', 'seconds' then ms = 1e3 * ms
                    when 'm', 'minute', 'minutes' then ms = 6e4 * ms
                    when 'h', 'hour', 'hours' then ms = 3.6e6 * ms
                    when 'd', 'day', 'days' then ms = 28.64e7 * ms
                    when 'w', 'week', 'weeks' then ms = 6.048e8 * ms
                    when 'm', 'month', 'months' then ms = 1.8144e10 * ms

                # Is the key even present?
                if @cache? and @cache[key]?
                    return new Date().getTime() - ms > new Date(@cache[key].modified).getTime()
                else
                    true

# A type that is always present, the default.
class blað.types.BasicDocument extends blað.Type

    # Presentation for the document.
    render: (done) -> done @, false

# -------------------------------------------------------------------

# Export in order to define custom document types.
exports.blað = blað

# Exposed firestarter that builds the site and starts the SERVICE.
exports.start = (cfg, dir, done) ->
    # Welcome.
    welcome = ->
        def = Q.defer()

        LOG.info "Welcome to #{'blað'.grey}"

        fs.readFile "#{__dirname}/logo.txt", (err, data) ->
            if err then def.reject err
            
            ( LOG.help line.cyan.bold for line in data.toString('utf-8').split('\n') )

            LOG.help ''
            LOG.help 'A forms based Node.js CMS'
            LOG.help ''

            def.resolve()

        def.promise

    # Deep copy of config (and check dict passed in).
    config = ->
        LOG.debug 'Duplicate config'
        
        CONFIG = JSON.parse JSON.stringify cfg
    
    # Go env or config? And validate.
    validate = ->
        LOG.debug 'Validate config'

        # Resolve config coming from environment and the `cfg` dict.
        CONFIG.mongodb        = process.env.DATABASE_URL or CONFIG.mongodb    # MongoDB database
        CONFIG.port           = process.env.PORT or CONFIG.port               # port number
        CONFIG.env            = process.env.NODE_ENV or 'documents'           # environment/collection to use
        CONFIG.browserid     ?= {}
        CONFIG.browserid.salt = process.env.API_SALT or CONFIG.browserid.salt # API key salt

        # Validate file.
        if not CONFIG.browserid? or
          not CONFIG.browserid.provider? or
            not CONFIG.browserid.salt? or
              not CONFIG.browserid.users? or
                not CONFIG.browserid.users instanceof Array
                    throw 'You need to create a valid `browserid` section'
        if not CONFIG.mongodb?
            throw 'You need to specify the `mongodb` uri'

        # Create create hashes of salt + user emails.
        CONFIG.browserid.hashes = []
        for email in CONFIG.browserid.users
            CONFIG.browserid.hashes.push crypto.createHash('md5').update(email + CONFIG.browserid.salt).digest('hex')

    # Code compilation.
    compile = ->
        LOG.debug 'Compile code, copy public site files'

        # Attach my logger.
        utils.log (message) -> LOG.debug message

        # Compile our and their code.
        Q.all [
            utils.compile.admin(),
            utils.compile.forms(SITE_PATH),
            utils.copy.public(SITE_PATH),
            utils.include.presenters(SITE_PATH)
        ]

    # Include site's presenters on us.
    include = ([ undefineds..., presenters ]) ->
        LOG.debug 'Including custom presenters'

        # Traverse all plain functions.
        for f in presenters
            # Require the file.
            req = require f
            # Get the first key - a document that will be exposed, hopefully.
            key = Object.keys(req)[0]
            # Extend the function on us.
            blað.types[key] = req[key]

    # Start flatiron service on a port.
    startup = ->
        LOG.debug 'Setup & start ' + 'flatiron'.grey

        def = Q.defer()
        service = flatiron.app
        setup service
        service.start CONFIG.port, (err) ->
            if err then def.reject err
            else def.resolve service
        def.promise

    # Map all existing public documents.
    map = (service) ->
        LOG.debug 'Map existing documents'

        def = Q.defer()
        service.db (collection) ->
            collection.find('public': true).toArray (err, docs) ->
                if err then def.reject err
                for doc in docs
                    LOG.info 'Mapping url ' + doc.url.underline
                    service.router.path doc.url, blað.get
                def.resolve service
        def.promise

    # OK or bust?
    ya = (service) ->
        LOG.debug 'Done'

        LOG.info 'Listening on port ' + service.server.address().port.toString().bold
        LOG.info 'blað'.grey + ' started ' +  'ok'.green.bold
        # Callback?
        if done and typeof done is 'function' then done service
    
    na = (err) ->
        try
            err = JSON.parse(err)
            LOG.error err.error.message or err.message or err
        catch e
            LOG.error err

    # What is the environment?
    if process.env.NODE_ENV isnt 'test'
        # CLI output.
        winston.cli()
        LOG = winston

        # Set site path on us.
        SITE_PATH = dir

        # Actual sequence goes here.
        Q.fcall(welcome).then(config).then(validate).then(compile).then(include).then(startup).then(map).done(ya, na)
    else
        # Go silent.
        winston.loggers.add 'dummy', 'console': 'silent': true
        LOG = winston.loggers.get 'dummy'

        # Under test condition.
        Q.fcall(config).then(startup).done(ya, na)