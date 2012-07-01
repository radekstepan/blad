should = require 'should'
request = require 'request'

app = require('../app.coffee').app

url = 'http://127.0.0.1:1118'

describe "page types", ->
    
    before -> app.start false

    after -> app.stop()

    describe "this case #1", ->
        it 'should be successful #1', (done) ->
            request.get "#{url}/api/type?type=Plain", (error, response, body) ->
                body.should.equal 'success'
                done()