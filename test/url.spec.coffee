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

class URLDocument extends blad.Type

    # Render as JSON as is.
    render: (done) ->
        done
            'type': @type
            'name': @name
            'url':  @url
        , false

blad.types.URLDocument = URLDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1'; app = null

describe "URL parsing vulnerabilities", ->

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

    describe 'create document on /%NETHOOD%/', ->
        it 'should fail mapping', (done) ->
            for i in [ 0...2 ] then do (i) ->
                request.post
                    'url': "#{url}/api/document"
                    'form':
                        'type':   'URLDocument'
                        'name':   'nessus'
                        'url':    '/%NETHOOD%/'
                        'public': true
                    'headers':
                        'x-blad-apikey': '@dummy'
                , (error, response, body) ->
                    done(error) if error

                    response.statusCode.should.equal 400
                    if i is 1 then done()