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

class DummyDocument extends blad.Type

    # Render as JSON as is.
    render: (done) ->
        done
            'public': @public
            'url':    @url
            '_id':    @_id
        , false

blad.types.DummyDocument = DummyDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1'; app = null

describe "document URL un-/mapping", ->

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

    root = undefined

    describe "should not allow mapping to app routes", ->
        it "should return 400 for /auth", (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/auth"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 400
                done()

        it "should return 400 for /admin", (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/admin/whatever"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 400
                done()

        it "should return 400 for /api", (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/api/"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 400
                done()

        it "should return 400 for /sitemap.xml", (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/sitemap.xml"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 400
                done()

    describe "create root public document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
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
                'headers':
                    'x-blad-apikey': '@dummy'
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

        it "should return 400 for existing map", (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/child"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 400
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
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 200

                body = JSON.parse body
                delete body.modified

                body.should.eql
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
                'headers':
                    'x-blad-apikey': '@dummy'
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
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 200

                body = JSON.parse body
                delete body.modified

                body.should.eql
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