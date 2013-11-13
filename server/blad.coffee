#!/usr/bin/env coffee

module.exports = blad = 'types': {}

class blad.Type

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
class blad.types.BasicDocument extends blad.Type

    # Presentation for the document.
    render: (done) -> done @, false