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

class HasChildrenDocument extends blad.Type

    render: (done) ->
        done
            'all': @children() or {}
        , false

blad.types.HasChildrenDocument = HasChildrenDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1'; app = null

describe "document that has children actions", ->

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

    describe "create parent document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'HasChildrenDocument'
                    'name':   "parent"
                    'url':    "/group1"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

    describe "create children", ->
        it 'should return 201', (done) ->
            for i in [ 1...4 ] then do (i) ->
                request.post
                    'url': "#{url}/api/document"
                    'form':
                        'type':   'HasChildrenDocument'
                        'name':   "child#{i}"
                        'url':    "/group1/child#{i}"
                    'headers':
                        'x-blad-apikey': '@dummy'
                , (error, response, body) ->
                    response.statusCode.should.equal 201
                    if i is 3 then done()

    describe "retrieve the parent", ->
        it 'should give us all the children', (done) ->
            request.get "#{url}/group1"
            , (error, response, body) ->
                response.statusCode.should.equal 200

                # Parse response.
                children = JSON.parse(body)

                clean = []
                for doc in children.all
                    delete doc._id
                    delete doc.modified
                    clean.push doc

                clean.should.includeEql
                    "type": "HasChildrenDocument"
                    "name": "child1"
                    "url":  "/group1/child1"
                clean.should.includeEql
                    "type": "HasChildrenDocument"
                    "name": "child2"
                    "url":  "/group1/child2"
                clean.should.includeEql
                    "type": "HasChildrenDocument"
                    "name": "child3"
                    "url":  "/group1/child3"

                done()