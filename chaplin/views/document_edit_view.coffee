define [
    'chaplin'
    'models/document'
    'views/document_custom_view'
    'templates/document_edit'
], (Chaplin, Document, DocumentCustomView) ->

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
            
            new DocumentCustomView 'model': @model

        saveHandler: =>
            # Get the form fields.
            attr = {}
            for object in $(@el).serializeArray()
                attr[object.name] = object.value
            
            # Save them.
            @model.save attr

        # Call me to reload the View with different type.
        changeTypeHandler: (e) ->
            @model.set 'type', $(e.target).find('option:selected').text()
            @render()