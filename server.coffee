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

salt = 'Q?RAf!CAkus?ejuCruKu'
email = 'radek.stepan@gmail.com'

app = flatiron.app
app.use flatiron.plugins.http,
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
                    if crypto.createHash('md5').update(email + salt).digest('hex') is req.headers['x-blad-apikey']                   
                        next()
                    else
                        res.writeHead 403
                        res.write 'Invalid `X-Blad-ApiKey` authorization'
                        res.end()
            else
                next()
    ]

app.start 1118, (err) ->
    throw err if err
    app.log.info "Listening on port #{app.server.address().port}".green if process.env.NODE_ENV isnt 'test'

# -------------------------------------------------------------------
# Eco templating.
app.use
    name: "eco-templating"
    attach: (options) ->
        app.eco = (path, data, cb) ->
            fs.readFile "./src/site/#{path}.eco", "utf8", (err, template) ->
                if err then cb err, {} else cb undefined, eco.render template, data

# Start MongoDB.
mongodb.Db.connect "mongodb://localhost:27017/documents", (err, db) ->
    throw err if err
    app.log.info "Fired up MongoDB".green if process.env.NODE_ENV isnt 'test'

    # Add a collection plugin.
    app.use
        name: "mongodb"
        attach: (options) ->
            app.db = (cb) ->
                db.collection process.env.NODE_ENV or 'documents', (err, collection) ->
                    throw err if err
                    cb collection

    # Map all existing public documents.
    app.db (collection) ->
        collection.find('public': true).toArray (err, docs) ->
            throw err if err
            for doc in docs
                app.log.info "Mapping url " + doc.url.blue if process.env.NODE_ENV isnt 'test'
                app.router.path doc.url, Blað.get

# -------------------------------------------------------------------
# BrowserID auth.
app.router.path "/auth", ->
    @post ->
        # Authenticate.
        request.post
            'url': "https://browserid.org/verify"
            'form':
                'assertion': @req.body.assertion
                'audience':  "http://127.0.0.1:1118"
        , (error, response, body) =>
            throw error if error

            body = JSON.parse(body)
            
            if body.status is 'okay'
                # Authorize.
                if body.email is email
                    app.log.info "#{body.email} identity verified".green if process.env.NODE_ENV isnt 'test'
                    # Create API Key from email and salt for the client.
                    @res.writeHead 200, 'application/json'
                    @res.write JSON.stringify
                        'email': body.email
                        'key':   crypto.createHash('md5').update(body.email + salt).digest('hex')
                else
                    app.log.info "#{body.email} tried to access the API".red if process.env.NODE_ENV isnt 'test'
                    @res.writeHead 403, 'application/json'
                    @res.write JSON.stringify
                        'message': "Your email #{body.email} is not authorized to access the app"
            else
                # Pass on the authentication error response to the client.
                app.log.info body.message.red if process.env.NODE_ENV isnt 'test'
                @res.writeHead 403, 'application/json'
                @res.write JSON.stringify body
            
            @res.end()

# -------------------------------------------------------------------
# Get all documents.
app.router.path "/api/documents", ->
    @get ->
        app.log.info "Get all documents" if process.env.NODE_ENV isnt 'test'

        app.db (collection) =>
            collection.find({}, 'sort': 'url').toArray (err, docs) =>
                throw err if err
                @res.writeHead 200, "content-type": "application/json"
                @res.write JSON.stringify docs
                @res.end()

# Get/update/create a document.
app.router.path "/api/document", ->
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
                value = mongodb.ObjectID.createFromHexString params._id
                query = '_id': value
            else
                value = decodeURIComponent params.url
                query = 'url': value

            app.log.info "Get document " + new String(value).blue if process.env.NODE_ENV isnt 'test'

            # Actual grab.
            app.db (collection) =>
                collection.findOne query, (err, doc) =>
                    throw err if err
                    
                    @res.writeHead 200, "content-type": "application/json"
                    @res.write JSON.stringify doc
                    @res.end()

    editSave = ->
        doc = @req.body

        if doc._id?
            # Editing existing.
            app.log.info "Edit document " + doc._id.blue if process.env.NODE_ENV isnt 'test'
            # Convert _id to object.
            doc._id = mongodb.ObjectID.createFromHexString doc._id
            cb = => @res.writeHead 200, "content-type": "application/json"
        else
            # Creating a new one.
            app.log.info "Create new document" if process.env.NODE_ENV isnt 'test'
            cb = => @res.writeHead 201, "content-type": "application/json"

        # One command to save/update and optionaly unmap.
        Blað.save doc, (err, reply) =>
            if err
                app.log.info "I am different...".red if process.env.NODE_ENV isnt 'test'

                @res.writeHead 400, "content-type": "application/json"
                @res.write JSON.stringify reply
                @res.end()
            
            else
                if doc.public
                    # Map a document to a public URL.
                    app.log.info "Mapping url " + reply.blue if process.env.NODE_ENV isnt 'test'
                    app.router.path reply, Blað.get

                # Stringify the new document so Backbone can see what has changed.
                app.db (collection) =>
                    collection.findOne 'url': reply, (err, doc) =>
                        throw err if err
                        
                        cb()
                        @res.write JSON.stringify doc
                        @res.end()

    @post editSave
    @put editSave

app.router.path "/admin/reset", ->
    @get ->
        app.db (collection) =>
            collection.remove {}, (err, removed) =>
                throw err if err
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
    if doc.url.match(new RegExp("^/admin|^/api|^/auth", 'i'))?
        cb true, 'url': 'Is in use by core application'
    else
        # Is the URL mappable?
        m = doc.url.match(new RegExp(/^\/(\S*)$/))
        if !m then cb true, 'url': 'Does that look valid to you?'
        else
            app.db (collection) ->
                # Do we have the `public` attr?
                if doc.public?
                    # Coerce boolean.
                    switch doc.public
                        when 'true'  then doc.public = true
                        when 'false' then doc.public = false

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

                            # Update the collection.
                            collection.update '_id': doc._id
                                , doc
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

# Retrieve publicly mapped document.
Blað.get = ->
    @get ->
        # Get the doc(s) from the db. We want to get the whole 'group'.
        app.db (collection) =>
            collection.find({'url': new RegExp('^' + @req.url.toLowerCase())}, {'sort': 'url'}).toArray (err, docs) =>
                throw err if err

                record = docs[0]
                
                # Any children?
                if docs.length > 1 then record._children = (d for d in docs[1...docs.length])

                app.log.info 'Serving document ' + new String(record._id).blue if process.env.NODE_ENV isnt 'test'

                # Do we have this type?
                if Blað.types[record.type]?
                    presenter = new Blað.types[record.type](record)
                    # Give us the data.
                    presenter.render (context, template=true) =>
                        if template
                            # Render as HTML using template.
                            app.eco "#{record.type}/template", context, (err, html) =>
                                if err
                                    @res.writeHead 500
                                    @res.write err.message
                                else
                                    @res.writeHead 200, "content-type": "text/html"
                                    @res.write html
                                
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
    app.log.info "Delete url " + url.yellow if process.env.NODE_ENV isnt 'test'

    # A bit of hairy tweaking.
    if url is '/' then delete app.router.routes.get
    else
        # Multiple levels deep?
        r = app.router.routes
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
        app.db (collection) =>
            collection.find({'url': new RegExp("^\/([^/|\s]*)$")}, {'sort': 'url'}).toArray (err, docs) =>
                throw err if err
                cb docs

    # Provides children for a certain depth.
    children: (n) ->
        return {} unless @_children
        if n?
            ( child for child in @_children when child.url.replace(@url, '').split('/').length is n + 2 )
        else
            @_children

    # Needs to be overriden.
    render: (done) -> done {}

    # Expand model on us.
    constructor: (params) ->
        for key, value of params
            @[key] = value

# Expose.
exports.app = app
exports.Blað = Blað