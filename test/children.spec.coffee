should = require 'should'
request = require 'request'
querystring = require 'querystring'

exported = require('../server.coffee')
app = exported.app
Blað = exported.Blað
config = exported.config

config.BrowserID.hashes = [ '@dummy' ]

# -------------------------------------------------------------------

class HasChildrenDocument extends Blað.Type

    render: (done) ->
        done
            'all': @children() or {}
        , false

Blað.types.HasChildrenDocument = HasChildrenDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1:1118'

describe "document that has children actions", ->

    before (done) ->
        app.start()
        
        setTimeout ( ->
            app.db (collection) ->
                collection.remove {}, (error, removed) ->
                    collection.find({}).toArray (error, results) ->
                        results.length.should.equal 0
                        done()
        ), 100

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
                    delete doc._id ; clean.push doc

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