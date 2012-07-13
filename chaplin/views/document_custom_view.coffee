define [
    'chaplin'
    'templates/type_BasicDocument'
    'templates/type_ImageDocument'
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

        afterRender: ->
            super

            # Do we have any file uploads? Attach handlers...
            @delegate 'change', '[type="file"]', @loadFileHandler

        # Onchange form file input fields.
        loadFileHandler: (e) ->
            file = new FileReader()
            file.readAsDataURL $(e.target)[0].files[0]
            file.onload = (event) =>
                # Set base64 encoded string into target hidden input field.
                target = $(e.target).attr('data-target')
                $(@el).find("input[name=#{target}]").val(event.target.result)