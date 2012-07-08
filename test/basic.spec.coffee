should = require 'should'
request = require 'request'
querystring = require 'querystring'

exported = require('../server.coffee')
app = exported.app
Blað = exported.Blað

url = 'http://127.0.0.1:1118'

# -------------------------------------------------------------------

eco = require 'eco'

class BasicDocument extends Blað.Type

    # Eco template.
    template: '<%= @_id %>'

    # Presentation for the document.
    render: ->
        eco.render @template,
            '_id': @_id
            'url': @url

Blað.types.BasicDocument = BasicDocument

# -------------------------------------------------------------------

describe "basic document actions", ->

    before (done) ->
        app.start()
        
        setTimeout ( ->
            app.db.collection 'test', (error, collection) ->
                done(error) if error
                collection.remove {}, (error, removed) ->
                    collection.find({}).toArray (error, results) ->
                        results.length.should.equal 0
                        done()
        ), 100

    describe "create document", ->
        it 'should return 201', (done) ->
            for i in [ 0...2 ] then do (i) ->
                request.post
                    'headers':
                        "content-type": "application/x-www-form-urlencoded"
                    'url': "#{url}/api/documents"
                    'body': querystring.stringify
                        'type': 'BasicDocument'
                        '_id':   "document-#{i}"
                        'url':  "/documents/#{i}"
                , (error, response, body) ->
                    done(error) if error

                    response.statusCode.should.equal 201
                    if i is 1 then done()

        it 'should be able to retrieve the document', (done) ->
            for i in [ 0...2 ] then do (i) ->
                request.get "#{url}/documents/#{i}"
                , (error, response, body) ->
                    done(error) if error

                    response.statusCode.should.equal 200
                    body.should.equal "document-#{i}"
                    if i is 1 then done()

    describe "retrieve all documents", ->
        it 'should get all of them', (done) ->
            request.get "#{url}/api/documents"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200

                # Parse documents.
                documents = JSON.parse body

                documents.length.should.equal 2

                documents.should.includeEql
                    "type": "BasicDocument"
                    "_id":   "document-0"
                    "url":  "/documents/0"
                documents.should.includeEql
                    "type": "BasicDocument"
                    "_id":  "document-1"
                    "url": "/documents/1"

                done()