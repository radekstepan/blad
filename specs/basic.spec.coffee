should = require 'should'
request = require 'request'
querystring = require 'querystring'

app = require('../app.coffee').app

url = 'http://127.0.0.1:1118'

describe "basic document actions", ->

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
            for i in [ 0...2 ] then do (i) ->
                request.post
                    'headers':
                        "content-type": "application/x-www-form-urlencoded"
                    'url': "#{url}/api/documents"
                    'body': querystring.stringify
                        'type': 'basic'
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

                documents.should.includeEql
                    "type": "basic"
                    "_id":   "document-0"
                    "url":  "/documents/0"
                documents.should.includeEql
                    "type": "basic"
                    "_id":  "document-1"
                    "url": "/documents/1"

                done()