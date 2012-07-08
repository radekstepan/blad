define [
    'chaplin'
], (Chaplin) ->

    class Documents extends Chaplin.Collection

        url: '/api/documents'