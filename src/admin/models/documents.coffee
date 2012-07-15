define [
    'chaplin'
    'models/document'
], (Chaplin, Document) ->

    class Documents extends Chaplin.Collection

        url: '/api/documents'

        # Add custom header with API key.
        sync: (method, model, options) ->
            options = options or {}
            options.headers = 'X-Blad-ApiKey': '836f05bcb41b62ee335fc8b06dc8e629'
            Backbone.sync method, @, options

        model: Document