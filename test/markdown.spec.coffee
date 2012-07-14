should = require 'should'
request = require 'request'
querystring = require 'querystring'

exported = require('../server.coffee')
app = exported.app
Blað = exported.Blað

# -------------------------------------------------------------------

marked = require 'marked'

class MarkdownDocument extends Blað.Type

    render: (done) ->
        done
            'html': marked @markup
        , false

Blað.types.MarkdownDocument = MarkdownDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1:1118'

describe "markdown document actions", ->

    before (done) ->
        app.start()
        
        setTimeout ( ->
            app.db (collection) ->
                collection.remove {}, (error, removed) ->
                    collection.find({}).toArray (error, results) ->
                        results.length.should.equal 0
                        done()
        ), 100

    describe "create document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'MarkdownDocument'
                    'name':   "markdown"
                    'url':    "/documents/markdown"
                    'markup': "__hello__"
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

        it 'should be able to retrieve the document', (done) ->
            request.get "#{url}/documents/markdown"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200
                response.headers['content-type'].should.equal 'application/json'
                body.should.equal JSON.stringify
                    'html': "<p><strong>hello</strong></p>\n"
                
                done()

    describe "retrieve all documents", ->
        it 'should get all of them', (done) ->
            request.get "#{url}/api/documents"
            , (error, response, body) ->
                response.statusCode.should.equal 200

                # Parse documents.
                documents = JSON.parse body

                documents.length.should.equal 1

                delete documents[0]._id

                documents.should.includeEql
                    'type':   'MarkdownDocument'
                    "name":   "markdown"
                    "url":    "/documents/markdown"
                    "markup": "__hello__"

                done()