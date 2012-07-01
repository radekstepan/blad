should = require 'should'
request = require 'request'
querystring = require 'querystring'

app = require('../app.coffee').app

describe "basic actions", ->
    
    before -> app.start false

    after -> app.stop()

    describe "create document", ->
        it 'should return 201', (done) ->
            for i in [ 0...2 ] then do (i) ->
                request.post
                    'headers':
                        "content-type": "application/x-www-form-urlencoded"
                    'url': "http://127.0.0.1:1118/api/documents"
                    'body': querystring.stringify
                        'id':  "document-#{i}"
                        'url': "/documents/#{i}"
                , (error, response, body) ->
                    response.statusCode.should.equal 201
                    if i is 1 then done()

        it 'should be able to retrieve the document', (done) ->
            for i in [ 0...2 ] then do (i) ->
                request.get "http://127.0.0.1:1118/documents/#{i}"
                , (error, response, body) ->
                    response.statusCode.should.equal 200
                    body.should.equal "document-#{i}"
                    if i is 1 then done()

    describe "retrieve all documents", ->
        it 'should get all of them', (done) ->
            request.get "http://127.0.0.1:1118/api/documents"
            , (error, response, body) ->
                response.statusCode.should.equal 200

                # Sort the documents for us.
                documents = JSON.parse body

                documents.should.includeEql
                    "id":  "document-0"
                    "url": "/documents/0"
                documents.should.includeEql
                    "id":  "document-1"
                    "url": "/documents/1"

                done()