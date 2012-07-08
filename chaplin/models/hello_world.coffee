define [
    'chaplin',
    'models/base/model'
], (Chaplin, Model) ->

    class HelloWorld extends Model

        defaults:
            message: 'Hello World from Chaplin.js app!'

        #initialize: (attributes, options) ->
            #super
            #console.debug 'HelloWorld#initialize'