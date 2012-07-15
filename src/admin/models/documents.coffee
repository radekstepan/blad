define [
    'chaplin'
    'models/document'
], (Chaplin, Document) ->

    class Documents extends Chaplin.Collection

        url: '/api/documents'

        # Add custom header with API key.
        sync: (method, model, options) ->
            options = options or {}
            options.headers = 'X-Blad-ApiKey': window.app.apiKey
            Backbone.sync method, @, options

        model: Document