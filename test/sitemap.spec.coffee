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

class SitemapDocument extends blad.Type

blad.types.SitemapDocument = SitemapDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1'; app = null

describe "sitemap.xml", ->

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

    describe "create a public document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/one"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

    describe "create another public document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/two"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

    describe "create a private document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'DummyDocument'
                    'url':    "/three"
                    'public': false
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                response.statusCode.should.equal 201
                done()

    describe "get the sitemap", ->
        it 'should list only the two public documents', (done) ->
            request.get "#{url}/sitemap.xml"
            , (error, response, body) ->
                response.statusCode.should.equal 200

                matches = ( match.replace(/<lastmod>.+?<\/lastmod>/, '') for match in body.match /<url>(.+?)<\/url>/g )

                matches.should.includeEql "<url><loc>#{url}/one</loc></url>"
                matches.should.includeEql "<url><loc>#{url}/two</loc></url>"
                matches.should.not.includeEql "<url><loc>#{url}/three</loc></url>"

                done()