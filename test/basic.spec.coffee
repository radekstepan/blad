should = require 'should'
request = require 'request'
querystring = require 'querystring'

{ start, blad } = require '../index.js'
config =
    'env':
        'test'
    'middleware':
        []
    'browserid':
        'hashes':
            [ '@dummy' ]
    'mongodb':
        'mongodb://127.0.0.1:27017/test'

# -------------------------------------------------------------------

class BasicDocument extends blad.Type

    # Render as JSON as is.
    render: (done) ->
        done
            'type': @type
            'name': @name
            'url':  @url
        , false

blad.types.BasicDocument = BasicDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1'; app = null

describe "basic document actions", ->

    before (done) ->
        start config, null, (service) ->
            app = service
            service.db (collection) ->
                collection.remove {}, (error, removed) ->
                    collection.find({}).toArray (error, results) ->
                        results.length.should.equal 0
                        # Set the service port on the main url.
                        url = [ url , service.server.address().port ].join(':')
                        # Callback.
                        done()

    after (done) -> app.server.close done

    describe "create document", ->
        it 'should return 201', (done) ->
            for i in [ 0...2 ] then do (i) ->
                request.post
                    'url': "#{url}/api/document"
                    'form':
                        'type':   'BasicDocument'
                        'name':   "document-#{i}"
                        'url':    "/documents/#{i}"
                        'public': true
                    'headers':
                        'x-blad-apikey': '@dummy'
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
                    response.headers['content-type'].should.equal 'application/json'
                    body.should.equal JSON.stringify
                        'type': 'BasicDocument'
                        'name': "document-#{i}"
                        'url':  "/documents/#{i}"
                    
                    if i is 1 then done()

    describe "retrieve all documents", ->
        it 'should get all of them', (done) ->
            request.get
                'url': "#{url}/api/documents"
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200

                # Parse documents.
                documents = JSON.parse body

                documents.length.should.equal 2

                clean = []
                for doc in documents
                    # Do we actually have them?
                    (doc._id?).should.be.true
                    (doc.modified?).should.be.true
                    # Delete them now.
                    delete doc._id
                    delete doc.modified
                    clean.push doc

                clean.should.includeEql
                    "type":   "BasicDocument"
                    "name":   "document-0"
                    "url":    "/documents/0"
                    'public': true
                clean.should.includeEql
                    "type":   "BasicDocument"
                    "name":   "document-1"
                    "url":    "/documents/1"
                    'public': true

                done()