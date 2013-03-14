should = require 'should'
request = require 'request'
querystring = require 'querystring'

{ start, blað } = require('../blad.coffee')

config = 'env': 'test', 'middleware': [], 'browserid': 'hashes': [ '@dummy' ]

# -------------------------------------------------------------------

class BasicDocument extends blað.Type

    # Render as JSON as is.
    render: (done) ->
        done
            'type': @type
            'name': @name
            'url':  @url
        , false

blað.types.BasicDocument = BasicDocument

# -------------------------------------------------------------------

url = 'http://127.0.0.1'

describe "URL parsing vulnerabilities", ->

    before (done) ->
        start config, null, (service) ->
            service.db (collection) ->
                collection.remove {}, (error, removed) ->
                    collection.find({}).toArray (error, results) ->
                        results.length.should.equal 0
                        # Set the service port on the main url.
                        url = [ url , service.server.address().port ].join(':')
                        # Callback.
                        done()

    describe 'create document on /%NETHOOD%/', ->
        it 'should fail mapping', (done) ->
            for i in [ 0...2 ] then do (i) ->
                request.post
                    'url': "#{url}/api/document"
                    'form':
                        'type':   'BasicDocument'
                        'name':   'nessus'
                        'url':    '/%NETHOOD%/'
                        'public': true
                    'headers':
                        'x-blad-apikey': '@dummy'
                , (error, response, body) ->
                    done(error) if error

                    response.statusCode.should.equal 400
                    if i is 1 then done()