define [
    'chaplin'
    'models/document'
], (Chaplin, Document) ->

    class Documents extends Chaplin.Collection

        url: '/api/documents'

        model: Document