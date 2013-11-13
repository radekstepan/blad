#!/usr/bin/env coffee
urlib   = require 'url'
mongodb = require 'mongodb'
domain  = require 'domain'
{ _ }   = require 'underscore'

module.exports = ({ app, log, blad }) ->
    editSave = ->
        doc = @req.body

        if doc._id?
            # Editing existing.
            log.info "Edit document #{doc._id}"
            # Convert _id to object.
            doc._id = mongodb.ObjectID.createFromHexString doc._id
            cb = => @res.writeHead 200, "content-type": "application/json"
        else
            # Creating a new one.
            log.info 'Create new document'
            cb = => @res.writeHead 201, "content-type": "application/json"

        # One command to save/update and optionaly unmap.
        blad.save doc, (err, reply) =>
            if err
                log.error 'I am different...'

                @res.writeHead 400, "content-type": "application/json"
                @res.write JSON.stringify reply
                @res.end()
            
            else
                if doc.public
                    # Map a document to a public URL.
                    log.info 'Mapping url ' + reply.underline
                    app.router.path reply, blad.get

                # Stringify the new document so Backbone can see what has changed.
                app.db (collection) =>
                    collection.findOne 'url': reply, (err, doc) =>
                        throw err if err
                        
                        cb()
                        @res.write JSON.stringify doc
                        @res.end()

    # Save/update a document.
    blad.save = (doc, cb) ->
        # Prefix URL with a forward slash if not present.
        if doc.url[0] isnt '/' then doc.url = '/' + doc.url
        # Remove trailing slash if present.
        if doc.url.length > 1 and doc.url[-1...] is '/' then doc.url = doc.url[...-1]
        # Are we trying to map to core URLs?
        if doc.url.match(new RegExp("^/admin|^/api|^/auth|^/sitemap.xml", 'i'))?
            cb true, 'url': 'Is in use by core application'
        else
            # Is the URL mappable?
            try
                decodeURIComponent(doc.url) # issue #85
                m = doc.url.match(new RegExp(/^\/(\S*)$/))
            catch e
                # Silence!
            if !m then cb true, 'url': 'Does that look valid to you?'
            else
                app.db (collection) ->
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
                                if old.public then blad.unmap old.url

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

    # Retrieve publicly mapped document.
    blad.get = ->
        @get ->
            # Get the doc(s) from the db. We want to get the whole 'group'.
            app.db (collection) =>
                # A URL might have parameters, only keep the pathname; #80
                url = urlib.parse(@req.url, true).pathname.toLowerCase()

                collection.find({'url': new RegExp('^' + url)}, {'sort': 'url'}).toArray (err, docs) =>
                    throw err if err

                    # Did we actually get anything?
                    unless record = docs[0] then throw 'Bad request URL, need to get a pathname only'

                    # Any children?
                    if docs.length > 1 then record._children = (d for d in docs[1...docs.length])

                    log.debug 'Render url ' + (record.url or record._id).underline

                    # Do we have this type?
                    if blad.types[record.type]
                        # Create a new domain for the 'untrusted' presenter.
                        doom = domain.create()

                        # Handle this doom like this.
                        doom.on 'error', (err) =>
                            # Can we grace?
                            try
                                log.error t = "Error occurred, sorry: #{err}"
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
                            # Init new type passing the data and "this" app.
                            presenter = new blad.types[record.type](record, app)

                            # Give us the data.
                            presenter.render (context, template=true) =>
                                # http://www.w3.org/Protocols/HTTP/HTRQ_Headers.html#z3
                                accept = @req?.headers?.accept
                                if accept
                                    for part in accept.split(';')
                                        if part.indexOf('application/json') isnt -1
                                            template = false

                                if template
                                    # Render as HTML using template.
                                    app.eco "#{record.type}/template", context, (err, html) =>
                                        if err
                                            @res.writeHead 500
                                            @res.write err.message
                                            @res.end()
                                        else
                                            # Create a new context boosted with the page html.
                                            context = _.extend 'page': html, context
                                            # Do we have a layout template to render to?
                                            app.eco 'layout', context, (err, layout) =>
                                                @res.writeHead 200, 'content-type': 'text/html'
                                                @res.write if err then html else layout
                                                @res.end()
                                else
                                    # Remove functions from context.
                                    for key, value of context
                                        try
                                            JSON.stringify value
                                        catch err
                                            delete context[key]

                                    # Render as is, JSON.
                                    @res.writeHead 200, 'content-type': 'application/json'
                                    @res.write JSON.stringify context
                                    @res.end()
                    else
                        log.warn t = "Document type #{record.type} not one of #{Object.keys(blad.types).join(', ')}"
                        @res.writeHead 500
                        @res.write t
                        @res.end()

    # Unmap document from router.
    blad.unmap = (url) ->
        log.info 'Delete url ' + url.underline

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

    # Get/update/create a document.
    '/api/document':
        get: ->
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

                log.info "Get document #{value}"

                # Actual grab.
                app.db (collection) =>
                    collection.findOne query, (err, doc) =>
                        throw err if err

                        @res.writeHead 200, "content-type": "application/json"
                        @res.write JSON.stringify doc
                        @res.end()
        
        post: editSave
        put: editSave

        # Remove a document.
        delete: ->
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

                log.info "Delete document #{value}"

                # Find and delete.
                app.db (collection) =>
                    # Do we have the document?
                    collection.findAndModify query, [], {}, 'remove': true, (err, doc) =>
                        throw err if err

                        # Did this doc actually exist?
                        if doc
                            # Unmap the url.
                            blad.unmap doc.url

                            # Respond in kind.
                            @res.writeHead 200, "content-type": "application/json"
                            @res.end()
                        else
                            @res.writeHead 404, "content-type": "application/json"
                            @res.end()