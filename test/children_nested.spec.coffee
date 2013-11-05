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

class HasNestedChildrenDocument extends blad.Type

    render: (done) ->
        done
            'all':  @children()
            'lvl0': @children 0
            'lvl1': @children 1
        , false

blad.types.HasNestedChildrenDocument = HasNestedChildrenDocument

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
                    'type':   'HasNestedChildrenDocument'
                    'name':   "parent"
                    'url':    "/group1"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

    describe "create child level 0", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'HasNestedChildrenDocument'
                    'name':   "child0"
                    'url':    "/group1/child0"
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

    describe "create child level 1", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'HasNestedChildrenDocument'
                    'name':   "child1"
                    'url':    "/group1/rubbish/child1"
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

    describe "retrieve the parent", ->
        it 'should give us all the children nested', (done) ->
            request.get "#{url}/group1"
            , (error, response, body) ->
                response.statusCode.should.equal 200

                # Parse response.
                children = JSON.parse(body)

                children.should.have.property 'all'
                children.should.have.property 'lvl0'
                children.should.have.property 'lvl1'

                clean = []
                for doc in children.lvl0
                    delete doc._id
                    delete doc.modified
                    clean.push doc

                clean.should.includeEql
                    "type": "HasNestedChildrenDocument"
                    "name": "child0"
                    "url":  "/group1/child0"

                clean = []
                for doc in children.lvl1
                    delete doc._id
                    delete doc.modified
                    clean.push doc

                clean.should.includeEql
                    "type": "HasNestedChildrenDocument"
                    "name": "child1"
                    "url":  "/group1/rubbish/child1"

                done()

    describe "create root document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'HasNestedChildrenDocument'
                    'name':   "parent"
                    'url':    "/"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

    describe "retrieve the root", ->
        it 'should give us group1 document only', (done) ->
            request.get "#{url}/"
            , (error, response, body) ->
                response.statusCode.should.equal 200

                # Parse response.
                children = JSON.parse(body)

                children.lvl0.length.should.equal 1

                clean = children.lvl0.pop()
                delete clean._id
                delete clean.modified

                clean.should.eql
                    "type": "HasNestedChildrenDocument"
                    "name": "parent"
                    "url":  "/group1"
                    "public": true

                done()