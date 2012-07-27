should = require 'should'
request = require 'request'
querystring = require 'querystring'

exported = require('../server.coffee')
app = exported.app
Blað = exported.Blað
config = exported.config

config.BrowserID.hashes = [ '@dummy' ]

# -------------------------------------------------------------------

class SitemapDocument extends Blað.Type

Blað.types.SitemapDocument = SitemapDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1:1118'

describe "sitemap.xml", ->

    before (done) ->
        app.start()
        
        setTimeout ( ->
            app.db (collection) ->
                collection.remove {}, (error, removed) ->
                    collection.find({}).toArray (error, results) ->
                        results.length.should.equal 0
                        done()
        ), 100

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

                matches.should.includeEql '<url><loc>http://127.0.0.1:1118/one</loc></url>'
                matches.should.includeEql '<url><loc>http://127.0.0.1:1118/two</loc></url>'
                matches.should.not.includeEql '<url><loc>http://127.0.0.1:1118/three</loc></url>'

                done()