should = require 'should'
request = require 'request'

app = require('../app.coffee').app

url = 'http://127.0.0.1:1118'

describe "some test", ->
    
    beforeEach -> app.start false

    afterEach -> app.stop()

    describe "this case", ->
        it 'should be successful', (done) ->
            request.get "#{url}/api/type?type=Plain", (error, response, body) ->
                body.should.equal 'success'
                done()