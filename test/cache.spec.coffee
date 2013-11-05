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

class CacheDocument extends blad.Type

    render: (done) ->
        # Do we have cache already?
        if @cache?
            # Check if data in store is old.
            if @store.isOld 'data', 300
                # Update with new info and render back.
                @store.save 'data', 'new information', =>
                    done
                        'data': @store.get('data')
                        'was':  'old'
                    , false
            else
                # Nope, all fresh.
                done
                    'data': @store.get('data')
                    'was':  'fresh'
                , false
        else
            # Initial info.
            @store.save 'data', 'old information', =>
                done
                    'data': @store.get('data')
                    'was':  'new'
                , false

blad.types.CacheDocument = CacheDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1'; app = null

describe "cache document", ->

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

    describe "create old document", ->
        it 'should return 201', (done) ->
            request.post
                'url': "#{url}/api/document"
                'form':
                    'type':   'CacheDocument'
                    'url':    "/cache"
                    'public': true
                'headers':
                    'x-blad-apikey': '@dummy'
            , (error, response, body) ->
                done(error) if error
                response.statusCode.should.equal 201                
                done()

        it 'should be able to retrieve the original document', (done) ->
            request.get "#{url}/cache"
            , (error, response, body) ->
                done(error) if error

                response.statusCode.should.equal 200
                response.headers['content-type'].should.equal 'application/json'
                body.should.equal JSON.stringify
                    'data': 'old information'
                    'was':  'new'

                done()

        it 'should be able to retrieve the document with new information now', (done) ->
            # Put some delay here so we expire the cache.
            setTimeout ->
                request.get "#{url}/cache"
                , (error, response, body) ->
                    done(error) if error

                    response.statusCode.should.equal 200
                    response.headers['content-type'].should.equal 'application/json'
                    body.should.equal JSON.stringify
                        'data': 'new information'
                        'was':  'old'
                    
                    done()
            , 500