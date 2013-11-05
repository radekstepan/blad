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

class ParentDocument extends blad.Type

    # Render as JSON as is.
    render: (done) ->
        @parent (doc) ->
            done doc, false

blad.types.ParentDocument = ParentDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1'; app = null

describe "parent document", ->

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
                    'type':   'ParentDocument'
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
                    'type':   'ParentDocument'
                    'name':   "article-1"
                    'url':    "/blog/article-1"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

    describe "create lvl0 document again", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'ParentDocument'
                    'name':   "emicko"
                    'url':    "/emicko"
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
                    'type':   'ParentDocument'
                    'name':   "article-2"
                    'url':    "/blog/article-2"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

    describe "retrieve one of the blog articles", ->
        it 'should get back the blog root', (done) ->
            request.get "#{url}/blog/article-2"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200

                # Parse document.
                document = JSON.parse body

                document.should.have.property 'type', 'ParentDocument'
                document.should.have.property 'url', '/blog'

                done()

    describe "retrieve the blog root", ->
        it 'should get back nothing', (done) ->
            request.get "#{url}/blog"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200

                # Parse document.
                document = JSON.parse body

                document.should.eql {}

                done()