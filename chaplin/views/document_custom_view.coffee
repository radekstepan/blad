define [
    'chaplin'
    'templates/type_BasicDocument'
    'templates/type_MarkdownDocument'
], (Chaplin) ->

    # A view for the custom document fields
    class DocumentCustomView extends Chaplin.View

        # Automatically append to the DOM on render.
        container: '#custom'

        # Clear existing.
        containerMethod: 'html'

        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST['type_' + @model.get('type')]

        initialize: (params) -> @model = params.model