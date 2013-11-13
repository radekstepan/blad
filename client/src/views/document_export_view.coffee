define [
    'chaplin'
    'views/message_view'
], (Chaplin, MessageView) ->

    # Used for exporting all documents.
    class DocumentExportView extends Chaplin.View

        # Automatically append to the DOM on render.
        container: '#app'

        # Clear existing.
        containerMethod: 'html'

        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: ->

        initialize: (params) ->
            super

            # Any message to display?
            if params?.message? then @message = params.message

        afterRender: ->
            super

            # Show a message?
            if @message? then new MessageView @message

            # FileSaver.js
            if @collection and @collection.length isnt 0
                blob = new Blob [ JSON.stringify(@collection.toJSON()) ], 'type': "application/json;charset=utf-8"
                saveAs blob, "blad-cms-dump-#{(new Date).toISOString()}.json"