define [
    'chaplin'
    'models/document'
    'templates/type_BasicDocument'
], (Chaplin, Document) ->

    # Used for editing and creating new documents
    class DocumentEditView extends Chaplin.View

        tagName: 'form'

        # Automatically append to the DOM on render
        container: '#app'

        # Clear existing.
        containerMethod: 'html'

        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST['type_' + @model.get('type')]

        initialize: (params) ->
            @model = params?.model or new Document()
            @delegate 'click', '.save', @saveHandler

        saveHandler: =>
            # Get the form fields.
            attributes = {}
            for field in $(@el).serialize().split('&') then do (field) ->
                [key, value] = field.split('=')
                attributes[key] = decodeURIComponent value
            
            # Save them.
            @model.save attributes