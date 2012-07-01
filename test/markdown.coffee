should = require 'should'
request = require 'request'
querystring = require 'querystring'

app = require('../app.coffee').app

describe "markdown document actions", ->
    
    before -> app.start false

    # after -> app.stop()

    describe "create document", ->
        it 'should return 201', (done) ->
            request.post
                'headers':
                    "content-type": "application/x-www-form-urlencoded"
                'url': "http://127.0.0.1:1118/api/documents"
                'body': querystring.stringify
                    'type':    'markdown'
                    'id':      "markdown"
                    'url':     "/documents/markdown"
                    'content': "__hello__"
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

        it 'should be able to retrieve the document', (done) ->
            request.get "http://127.0.0.1:1118/documents/markdown"
            , (error, response, body) ->
                response.statusCode.should.equal 200
                body.trim().should.equal '<p><strong>hello</strong></p>'
                done()

    describe "retrieve all documents", ->
        it 'should get all of them', (done) ->
            request.get "http://127.0.0.1:1118/api/documents"
            , (error, response, body) ->
                response.statusCode.should.equal 200

                # Sort the documents for us.
                documents = JSON.parse body

                documents.should.includeEql
                    'type':    'markdown'
                    "id":      "markdown"
                    "url":     "/documents/markdown"
                    "content": "__hello__"

                done()