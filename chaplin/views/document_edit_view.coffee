define [
    'chaplin'
    'models/document'
    'views/document_custom_view'
    'views/message_view'
    'templates/document_edit'
], (Chaplin, Document, DocumentCustomView, MessageView) ->

    # Used for editing and creating new documents.
    class DocumentEditView extends Chaplin.View

        tagName: 'form'

        # Automatically append to the DOM on render.
        container: '#app'

        # Clear existing.
        containerMethod: 'html'

        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST['document_edit']

        initialize: (params) ->
            @model = params?.model or new Document()

        # Render the custom document template.
        afterRender: ->
            super

            @delegate 'click', '.save', @saveHandler
            @delegate 'change', '.changeType', @changeTypeHandler
            
            @model.bind 'sync', @successHandler
            
            new DocumentCustomView 'model': @model

        saveHandler: =>
            # Get the form fields.
            attr = {}
            for object in $(@el).serializeArray()
                console.log object
                attr[object.name] = object.value
            
            # Save them.
            @model.save attr

        # Call me to reload the View with different type.
        changeTypeHandler: (e) ->
            @model.set 'type', $(e.target).find('option:selected').text()
            @render()

        # If model was synced OK.
        successHandler: (model) ->
            new MessageView
                'type': 'success'
                'text': "Document #{model.get('name')} saved."