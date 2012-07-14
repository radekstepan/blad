should = require 'should'
request = require 'request'
querystring = require 'querystring'

exported = require('../server.coffee')
app = exported.app
Blað = exported.Blað

# -------------------------------------------------------------------

class DummyDocument extends Blað.Type

    # Render as JSON as is.
    render: (done) ->
        done
            'public': @public
            'url':    @url
            '_id':    @_id
        , false

Blað.types.DummyDocument = DummyDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1:1118'

describe "document URL un-/mapping", ->

    before (done) ->
        app.start()
        
        setTimeout ( ->
            app.db (collection) ->
                collection.remove {}, (error, removed) ->
                    collection.find({}).toArray (error, results) ->
                        results.length.should.equal 0
                        done()
        ), 100

    root = undefined

    describe "create root public document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/"
                    'public': true
            , (error, response, body) ->
                response.statusCode.should.equal 201
                root = JSON.parse(body)._id
                done()

        it 'should be able to retrieve the document', (done) ->
            request.get "#{url}/"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200
                response.headers['content-type'].should.equal 'application/json'
                
                done()

    child = undefined

    describe "create child public document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/child"
                    'public': true
            , (error, response, body) ->
                response.statusCode.should.equal 201
                child = JSON.parse(body)._id
                done()

        it 'should be able to retrieve the document', (done) ->
            request.get "#{url}/child"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200
                response.headers['content-type'].should.equal 'application/json'
                
                done()

    describe "update root document to private", ->
        it 'should return 200', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    '_id':    root
                    'type':   'DummyDocument'
                    'url':    "/"
                    'public': false
            , (error, response, body) ->
                response.statusCode.should.equal 200

                body.should.equal JSON.stringify
                    '_id':    root
                    'type':   'DummyDocument'
                    'url':    "/"
                    'public': false

                done()

        it 'should not be able to retrieve the document', (done) ->
            request.get "#{url}/"
            , (error, response, body) ->
                done(error) if error
                
                response.statusCode.should.equal 404
                body.trim().should.equal 'Could not find path: /'

                done()

        it 'should be able to retrieve the child document', (done) ->
            request.get "#{url}/child"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200
                response.headers['content-type'].should.equal 'application/json'
                
                done()

    describe "create child of a child public document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/child/another-child"
                    'public': true
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

        it 'should be able to retrieve the document', (done) ->
            request.get "#{url}/child/another-child"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200
                response.headers['content-type'].should.equal 'application/json'
                
                done()

    describe "update child document to private", ->
        it 'should return 200', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    '_id':    child
                    'type':   'DummyDocument'
                    'url':    "/child"
                    'public': false
            , (error, response, body) ->
                response.statusCode.should.equal 200

                body.should.equal JSON.stringify
                    '_id':    child
                    'type':   'DummyDocument'
                    'url':    "/child"
                    'public': false

                done()

        it 'should not be able to retrieve the document', (done) ->
            request.get "#{url}/child"
            , (error, response, body) ->
                done(error) if error
                
                response.statusCode.should.equal 404
                body.trim().should.equal 'Could not find path: /child'

                done()

        it 'should be able to retrieve the child of a child document', (done) ->
            request.get "#{url}/child/another-child"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200
                response.headers['content-type'].should.equal 'application/json'
                
                done()