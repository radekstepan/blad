define [
    'chaplin'
], (Chaplin) ->

    class Document extends Chaplin.Model

        idAttribute: "_id"

        defaults:
            'type':   'BasicDocument' # always present, coming from the `server.coffee`
            'public': true

        url: ->
            if @get('_id')?
                '/api/document?_id=' + @get '_id'
            else
                '/api/document'

        # Add custom header with API key.
        sync: (method, model, options) ->
            options = options or {}
            options.headers = 'X-Blad-ApiKey': window.app.apiKey
            Backbone.sync method, @, options

        # Modify the attributes of a document on presenter code.
        getAttributes: ->
            _.extend
                '_description': @attrDescription()
                '_types':       @attrTypes()
            , @attributes

        # Format labels in a description, accessed with `_description`.
        attrDescription: ->
            return {} unless @get('description')?
            @get('description').replace /label:(\S*)/g, '<span class="radius label">$1</span>'

        # Determine available doc types based on JST forms.
        attrTypes: ->
            ( key[5...key.length - 4] for key, value of window.JST when key.indexOf('form_') is 0 ).sort()