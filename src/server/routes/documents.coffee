#!/usr/bin/env coffee

# Get all documents.
module.exports = ({ app, log }) ->
    '/api/documents':
        get: ->
            log.info 'Get all documents'

            app.db (collection) =>
                collection.find({}, 'sort': 'url').toArray (err, docs) =>
                    throw err if err
                    @res.writeHead 200, 'content-type': 'application/json'
                    @res.write JSON.stringify docs
                    @res.end()