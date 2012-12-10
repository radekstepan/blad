#!/usr/bin/env coffee
flatiron = require 'flatiron'
union    = require 'union'
connect  = require 'connect'
mongodb  = require 'mongodb'
request  = require 'request'
crypto   = require 'crypto'
urlib    = require 'url'
fs       = require 'fs'
cs       = require 'coffee-script'
eco      = require 'eco'
Q        = require 'q'
domain   = require 'domain' # experimental!
winston  = require 'winston'

# Internal flatiron app.
service = flatiron.app

# The config once set.
config = {}

service.use flatiron.plugins.http,
    'before': [
        # Have a nice favicon.
        connect.favicon()
        # Static file serving.
        connect.static './public'
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
                next()
    ]
    'onError': (err, req, res) ->
        # Trying to reach a 'page' on admin
        if err.status is 404 and req.url.match(new RegExp("^/admin", 'i'))?
            res.redirect '/admin', 301
        else
            # Go Union!
            union.errorHandler err, req, res

# -------------------------------------------------------------------
# Eco templating.
service.use
    name: "eco-templating"
    attach: (options) ->
        service.eco = (path, data, cb) ->
            fs.readFile "./src/site/#{path}.eco", "utf8", (err, template) ->
                if err then cb err, null
                else
                    try
                        cb null, eco.render template, data
                    catch e
                        cb e, null

# Start MongoDB.
db = null
# Add a collection plugin.
service.use
    name: "mongodb"
    attach: (options) ->
        service.db = (done) ->
            collection = (done) ->
                db.collection config.env, (err, coll) ->
                    throw err if err
                    done coll

            unless db?
                mongodb.Db.connect config.mongodb, (err, connection) ->
                    winston.info "Connected to #{config.mongodb}"
                    db = connection
                    throw err if err
                    collection done
            else
                collection done

# Map all existing public documents.
service.db (collection) ->
    collection.find('public': true).toArray (err, docs) ->
        throw err if err
        for doc in docs
            winston.info "Mapping url " + doc.url
            service.router.path doc.url, Blað.get

# -------------------------------------------------------------------
# BrowserID auth.
service.router.path "/auth", ->
    @post ->
        # Authenticate.
        request.post
            'url': config.browserid.provider
            'form':
                'assertion': @req.body.assertion
                'audience':  "http://#{@req.headers.host}"
        , (error, response, body) =>
            throw error if error

            body = JSON.parse(body)
            
            if body.status is 'okay'
                # Authorize.
                if body.email in config.browserid.users
                    winston.info "Identity verified for #{body.email}"
                    # Create API Key from email and salt for the client.
                    @res.writeHead 200, 'application/json'
                    @res.write JSON.stringify
                        'email': body.email
                        'key':   crypto.createHash('md5').update(body.email + config.browserid.salt).digest('hex')
                else
                    winston.warning "#{body.email} tried to access the API"
                    @res.writeHead 403, 'application/json'
                    @res.write JSON.stringify
                        'message': "Your email #{body.email} is not authorized to access the service"
            else
                # Pass on the authentication error response to the client.
                service.log.info body.message.red if config.env isnt 'test'
                @res.writeHead 403, 'application/json'
                @res.write JSON.stringify body
            
            @res.end()

# -------------------------------------------------------------------
# Sitemap.xml
service.router.path "/sitemap.xml", ->
    @get ->
        service.log.info "Get sitemap.xml" if config.env isnt 'test'

        # Give me all public documents.
        service.db (collection) =>
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
service.router.path "/api/documents", ->
    @get ->
        winston.info 'Get all documents'

        service.db (collection) =>
            collection.find({}, 'sort': 'url').toArray (err, docs) =>
                throw err if err
                @res.writeHead 200, "content-type": "application/json"
                @res.write JSON.stringify docs
                @res.end()

# Get/update/create a document.
service.router.path "/api/document", ->
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

            winston.info "Get document #{value}"

            # Actual grab.
            service.db (collection) =>
                collection.findOne query, (err, doc) =>
                    throw err if err

                    @res.writeHead 200, "content-type": "application/json"
                    @res.write JSON.stringify doc
                    @res.end()

    editSave = ->
        doc = @req.body

        if doc._id?
            # Editing existing.
            winston.info "Edit document #{doc._id}"
            # Convert _id to object.
            doc._id = mongodb.ObjectID.createFromHexString doc._id
            cb = => @res.writeHead 200, "content-type": "application/json"
        else
            # Creating a new one.
            winston.info 'Create new document'
            cb = => @res.writeHead 201, "content-type": "application/json"

        # One command to save/update and optionaly unmap.
        Blað.save doc, (err, reply) =>
            if err
                winston.error 'I am different...'

                @res.writeHead 400, "content-type": "application/json"
                @res.write JSON.stringify reply
                @res.end()
            
            else
                if doc.public
                    # Map a document to a public URL.
                    winston.info "Mapping url #{reply}"
                    service.router.path reply, Blað.get

                # Stringify the new document so Backbone can see what has changed.
                service.db (collection) =>
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

            winston.info "Delete document #{value}"

            # Find and delete.
            service.db (collection) =>
                # Do we have the document?
                collection.findAndModify query, [], {}, 'remove': true, (err, doc) =>
                    throw err if err

                    # Did this doc actually exist?
                    if doc
                        # Unmap the url.
                        Blað.unmap doc.url

                        # Respond in kind.
                        @res.writeHead 200, "content-type": "application/json"
                        @res.end()
                    else
                        @res.writeHead 404, "content-type": "application/json"
                        @res.end()

# -------------------------------------------------------------------
# Blað.
Blað = {}

# Save/update a document.
Blað.save = (doc, cb) ->
    # Prefix URL with a forward slash if not present.
    if doc.url[0] isnt '/' then doc.url = '/' + doc.url
    # Remove trailing slash if present.
    if doc.url.length > 1 and doc.url[-1...] is '/' then doc.url = doc.url[...-1]
    # Are we trying to map to core URLs?
    if doc.url.match(new RegExp("^/admin|^/api|^/auth|^/sitemap.xml", 'i'))?
        cb true, 'url': 'Is in use by core application'
    else
        # Is the URL mserviceable?
        m = doc.url.match(new RegExp(/^\/(\S*)$/))
        if !m then cb true, 'url': 'Does that look valid to you?'
        else
            service.db (collection) ->
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
                            if old.public then Blað.unmap old.url

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

# Retrieve publicly mserviceed document.
Blað.get = ->
    @get ->
        # Get the doc(s) from the db. We want to get the whole 'group'.
        service.db (collection) =>
            collection.find({'url': new RegExp('^' + @req.url.toLowerCase())}, {'sort': 'url'}).toArray (err, docs) =>
                throw err if err

                record = docs[0]

                # Any children?
                if docs.length > 1 then record._children = (d for d in docs[1...docs.length])

                winston.info "Serving document #{record._id}"

                # Do we have this type?
                if Blað.types[record.type]?                    
                    # Create a new domain for the 'untrusted' presenter.
                    doom = domain.create()

                    # Handle this doom like this.
                    doom.on 'error', (err) =>
                        # Say what?
                        winston.error err.message
                        
                        # Can we grace?
                        try
                            @res.writeHead 500
                            @res.end 'Error occurred, sorry.'
                            @res.on 'close', ->
                                # Forcibly shut down any other things added to this domain.
                                doom.dispose()

                        catch err                            
                            # Tried our best. Clean up anything remaining.
                            doom.dispose()

                    # Finally execute the presenter in the domain context.
                    doom.run =>
                        # Init new type.
                        presenter = new Blað.types[record.type](record)

                        # Give us the data.
                        presenter.render (context, template=true) =>
                            if template
                                # Render as HTML using template.
                                service.eco "#{record.type}/template", context, (err, html) =>
                                    if err
                                        @res.writeHead 500
                                        @res.write err.message
                                    else
                                        # Do we have a layout template to render to?
                                        service.eco 'layout', 'page': html, (err, layout) =>
                                            @res.writeHead 200, "content-type": "text/html"
                                            @res.write if err then html else layout
                                            @res.end()
                            else
                                # Render as is, JSON.
                                @res.writeHead 200, "content-type": "application/json"
                                @res.write JSON.stringify context
                                @res.end()
                else
                    @res.writeHead 500
                    @res.write 'Non existent document type'
                    @res.end()

# Unmap document from router.
Blað.unmap = (url) ->
    winston.info "Delete url #{url}"

    # A bit of hairy tweaking.
    if url is '/' then delete service.router.routes.get
    else
        # Multiple levels deep?
        r = service.router.routes
        parts = url.split '/'
        for i in [1...parts.length]
            if i + 1 is parts.length
                r[parts.pop()].get = undefined
            else
                r = r[parts[i]]

# Document types.
Blað.types = {}

class Blað.Type

    # Returns top level documents.
    menu: (cb) ->
        service.db (collection) =>
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
        service.db (collection) =>
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
        service.db (collection) =>
            collection.find({'url': new RegExp('^' + url.toLowerCase())}, {'sort': 'url'}).toArray (err, docs) =>
                throw err if err

                # No parent.
                return cb({}) unless docs.length > 0

                # Return 
                return cb docs[0]

    # Needs to be overriden.
    render: (done) -> done {}

    constructor: (params) ->
        # Expand model on us but servicely a blacklist.
        for key, value of params
            @[key] = value unless key in [ 'store', 'menu', 'children', 'siblings', 'parent', 'render', 'constructor' ]

        # Store of objects under `cache` key so we get context of this object.
        @store =
            # Get a key optionally on an object.
            get: (key, obj) =>
                winston.info "Cache used for #{key}"

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
                service.db (collection) =>
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
class BasicDocument extends Blað.Type

    # Presentation for the document.
    render: (done) -> done @, false

Blað.types.BasicDocument = BasicDocument

# -------------------------------------------------------------------

# So we can inject our own types.
exports.Blað = Blað

# Exposed firestarter that builds the site and starts the service.
exports.start = (cfg, dir, done) ->
    # Deep copy of config (and check dict passed in).
    Q.fcall( ->
        config = JSON.parse JSON.stringify cfg
    
    # Go env or config? And validate.
    ).then( ->
        # Resolve config coming from environment and the `cfg` dict.
        config.mongodb        = process.env.DATABASE_URL or config.mongodb    # MongoDB database
        config.port           = process.env.PORT or config.port               # port number
        config.env            = process.env.NODE_ENV or 'documents'           # environment/collection to use
        config.browserid     ?= {}
        config.browserid.salt = process.env.API_SALT or config.browserid.salt # API key salt

        # CLI output on the default output?
        winston.cli()

        # Validate file.
        if not config.browserid? or
          not config.browserid.provider? or
            not config.browserid.salt? or
              not config.browserid.users? or
                not config.browserid.users instanceof Array
                    throw 'You need to create a valid `browserid` section'
        if not config.mongodb?
            throw 'You need to specify the `mongodb` uri'

        # Create create hashes of salt + user emails.
        config.browserid.hashes = []
        for email in config.browserid.users
            config.browserid.hashes.push crypto.createHash('md5').update(email + config.browserid.salt).digest('hex')

    ).then( ->
        utils = require './utils.coffee'

        # Compile admin coffee files.

        # Compile in the site's type forms.

        # Include all the site's type presenters.

    # Start flatiron service on a port.
    ).then( ->
        def = Q.defer()
        service.start config.port, (err) ->
            if err then def.reject err
            else def.resolve()
        def.promise
    
    # OK or bust.
    ).done(
        ->
            winston.info "Listening on port #{service.server.address().port} " + 'ok'.green.bold
            # Callback?
            if done and typeof done is 'function' then done()
        , (err) ->
            try
                err = JSON.parse(err)
                winston.error(err.error.message or err.message or err)
            catch e
                winston.error(err) if config.env isnt 'test'
    )