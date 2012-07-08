define [
    'chaplin'
], (Chaplin) ->

    class Document extends Chaplin.Model

        idAttribute: "_id"

        defaults:
            'type': 'basic'

        url: -> "/api/document?id=#{@id}"