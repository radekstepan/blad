should = require 'should'
request = require 'request'
querystring = require 'querystring'

app = require('../app.coffee').app

url = 'http://127.0.0.1:1118'

describe "markdown document actions", ->

    beforeEach (done) ->
        app.start()
        
        do check = ->
            if !app.ready? then setTimeout(check, 0)
            else
                app.db.collection 'test', (error, collection) ->
                    done(error) if error
                    collection.remove {}, (error, removed) ->
                        collection.find({}).toArray (error, results) ->
                            console.log results
                            throw "Fuck sake this should be empty" if results.length isnt 0
                            done()

    #after (done) -> app.stop -> done()

    describe "create document", ->
        it 'should return 201', (done) ->
            request.post
                'headers':
                    "content-type": "application/x-www-form-urlencoded"
                'url': "#{url}/api/documents"
                'body': querystring.stringify
                    'type':    'markdown'
                    '_id':      "markdown"
                    'url':     "/documents/markdown"
                    'content': "__hello__"
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

        it 'should be able to retrieve the document', (done) ->
            request.get "#{url}/documents/markdown"
            , (error, response, body) ->
                response.statusCode.should.equal 200
                body.trim().should.equal '<p><strong>hello</strong></p>'
                done()

    describe "retrieve all documents", ->
        it 'should get all of them', (done) ->
            request.get "#{url}/api/documents"
            , (error, response, body) ->
                response.statusCode.should.equal 200

                # Parse documents.
                documents = JSON.parse body

                documents.should.includeEql
                    'type':    'markdown'
                    "_id":      "markdown"
                    "url":     "/documents/markdown"
                    "content": "__hello__"

                done()