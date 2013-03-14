should = require 'should'
request = require 'request'
querystring = require 'querystring'

{ start, blað } = require('../blad.coffee')

config = 'env': 'test', 'middleware': [], 'browserid': 'hashes': [ '@dummy' ]

# -------------------------------------------------------------------

class MenuDocument extends blað.Type

    # Render as JSON as is.
    render: (done) ->
        @menu (docs) ->
            done docs, false

blað.types.MenuDocument = MenuDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1'

describe "menu document actions", ->

    before (done) ->
        start config, null, (service) ->
            service.db (collection) ->
                collection.remove {}, (error, removed) ->
                    collection.find({}).toArray (error, results) ->
                        results.length.should.equal 0
                        # Set the service port on the main url.
                        url = [ url , service.server.address().port ].join(':')
                        # Callback.
                        done()

    describe "create root document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'MenuDocument'
                    'name':   "root"
                    'url':    "/"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

    describe "create another root document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'MenuDocument'
                    'name':   "another-root"
                    'url':    "/yup/"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

    describe "create child document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'MenuDocument'
                    'name':   "child"
                    'url':    "/whatever/dude"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201
                done()

    describe "retrieve the root", ->
        it 'should get only menu docs back', (done) ->
            request.get "#{url}/"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200

                # Parse documents.
                documents = JSON.parse body

                documents.length.should.equal 2

                clean = []
                for doc in documents
                    delete doc._id
                    delete doc.modified
                    clean.push doc

                clean.should.includeEql
                    "type":   "MenuDocument"
                    "name":   "root"
                    "url":    "/"
                    'public': true
                clean.should.includeEql
                    "type":   "MenuDocument"
                    "name":   "another-root"
                    "url":    "/yup"
                    'public': true

                done()