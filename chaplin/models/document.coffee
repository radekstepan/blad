define [
    'chaplin'
], (Chaplin) ->

    class Document extends Chaplin.Model

        idAttribute: "_id"

        defaults:
            'type': 'BasicDocument'

        url: -> '/api/document?_id=' + @get '_id'