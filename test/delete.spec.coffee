should = require 'should'
request = require 'request'
querystring = require 'querystring'

exported = require('../server.coffee')
app = exported.app
blað = exported.blað
config = exported.config

config.browserid.hashes = [ '@dummy' ]

# -------------------------------------------------------------------

class DeleteDocument extends blað.Type

    # Render as JSON as is.
    render: (done) ->
        done
            'type': @type
            'url':  @url
        , false

blað.types.DeleteDocument = DeleteDocument

# -------------------------------------------------------------------

url = "http://127.0.0.1:#{config.port}"

describe "delete a document action", ->

    before (done) ->
        app.start()
        
        app.db (collection) ->
            collection.remove {}, (error, removed) ->
                collection.find({}).toArray (error, results) ->
                    results.length.should.equal 0
                    done()

    describe "create & delete a document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DeleteDocument'
                    'url':    "/deleteme"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

        it 'should be able to access the document', (done) ->
            request.get "#{url}/deleteme"
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 200
                done()

        it 'should be able to remove the document', (done) ->
            request.del
                'url': "#{url}/api/document?url=/deleteme"
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 200
                done()

        it 'should not be able to access the document now', (done) ->
            request.get "#{url}/deleteme"
            , (error, response, body) ->
                response.statusCode.should.equal 404
                done()

    describe "create & delete a hidden document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DeleteDocument'
                    'url':    "/deleteme"
                    'public': false
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

        it 'should not be able to create the same document', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DeleteDocument'
                    'url':    "/deleteme"
                    'public': false
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 400
                done()

        it 'should be able to remove the document', (done) ->
            request.del
                'url': "#{url}/api/document?url=/deleteme"
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 200
                done()

        it 'now should be able to use the url again', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DeleteDocument'
                    'url':    "/deleteme"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

    describe "do not delete nonexistent document", ->
        it 'delete madeup doc', (done) ->
            request.del
                'url': "#{url}/api/document?url=/nonexistent"
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 404
                done()