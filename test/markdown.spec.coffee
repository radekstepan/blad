should = require 'should'
request = require 'request'
querystring = require 'querystring'

exported = require('../server.coffee')
app = exported.app
Blað = exported.Blað

url = 'http://127.0.0.1:1118'

# -------------------------------------------------------------------

marked = require 'marked'

class MarkdownDocument extends Blað.Type

    # Presentation for the document.
    render: -> marked @content

Blað.types.MarkdownDocument = MarkdownDocument

# -------------------------------------------------------------------

describe "markdown document actions", ->

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
            request.post
                'headers':
                    "content-type": "application/x-www-form-urlencoded"
                'url': "#{url}/api/documents"
                'body': querystring.stringify
                    'type':    'MarkdownDocument'
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

                documents.length.should.equal 1

                documents.should.includeEql
                    'type':    'MarkdownDocument'
                    "_id":      "markdown"
                    "url":     "/documents/markdown"
                    "content": "__hello__"

                done()