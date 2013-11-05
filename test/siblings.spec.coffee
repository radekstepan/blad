should = require 'should'
request = require 'request'
querystring = require 'querystring'

{ start, blad } = require '../index.js'
config =
    'env':
        'test'
    'middleware':
        []
    'browserid':
        'hashes':
            [ '@dummy' ]
    'mongodb':
        'mongodb://127.0.0.1:27017/test'

# -------------------------------------------------------------------

class SiblingsDocument extends blad.Type

    # Render as JSON as is.
    render: (done) ->
        @siblings (docs) ->
            done docs, false

blad.types.SiblingsDocument = SiblingsDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1'; app = null

describe "siblings of a document", ->

    before (done) ->
        start config, null, (service) ->
            app = service
            service.db (collection) ->
                collection.remove {}, (error, removed) ->
                    collection.find({}).toArray (error, results) ->
                        results.length.should.equal 0
                        # Set the service port on the main url.
                        url = [ url , service.server.address().port ].join(':')
                        # Callback.
                        done()

    after (done) -> app.server.close done

    describe "create lvl0 document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'SiblingsDocument'
                    'name':   "root"
                    'url':    "/blog"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

    describe "create lvl1 document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'SiblingsDocument'
                    'name':   "article-1"
                    'url':    "/blog/article-1"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

    describe "create lvl2 document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'SiblingsDocument'
                    'name':   "article-1 child"
                    'url':    "/blog/article-1/some-shiz"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

    describe "create another lvl1 document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'SiblingsDocument'
                    'name':   "article-2"
                    'url':    "/blog/article-2"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

    describe "retrieve one of the siblings", ->
        it 'should get only the same level documents and not us back', (done) ->
            request.get "#{url}/blog/article-1"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200

                # Parse documents.
                documents = JSON.parse body

                documents.length.should.equal 1

                clean = []
                for doc in documents
                    delete doc._id
                    delete doc.modified
                    clean.push doc

                clean.should.includeEql
                    "type":   "SiblingsDocument"
                    "name":   "article-2"
                    "url":    "/blog/article-2"
                    'public': true

                done()