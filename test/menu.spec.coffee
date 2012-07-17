should = require 'should'
request = require 'request'
querystring = require 'querystring'

exported = require('../server.coffee')
app = exported.app
Blað = exported.Blað

# -------------------------------------------------------------------

class MenuDocument extends Blað.Type

    # Render as JSON as is.
    render: (done) ->
        @menu (docs) ->
            done docs, false

Blað.types.MenuDocument = MenuDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1:1118'

describe "menu document actions", ->

    before (done) ->
        app.start()
        
        setTimeout ( ->
            app.db (collection) ->
                collection.remove {}, (error, removed) ->
                    collection.find({}).toArray (error, results) ->
                        results.length.should.equal 0
                        done()
        ), 100

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
                    'x-blad-apikey': '836f05bcb41b62ee335fc8b06dc8e629'
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
                    'x-blad-apikey': '836f05bcb41b62ee335fc8b06dc8e629'
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
                    'x-blad-apikey': '836f05bcb41b62ee335fc8b06dc8e629'
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
                    delete doc._id ; clean.push doc

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