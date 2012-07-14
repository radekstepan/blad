define [
    'chaplin'
    'templates/document_forms' # Will be generated server side. Do not attempt custom.
], (Chaplin) ->

    # A view for the custom document fields
    class DocumentCustomView extends Chaplin.View

        # Automatically append to the DOM on render.
        container: '#custom'

        # Clear existing.
        containerMethod: 'html'

        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST["form_#{@model.get('type')}.eco"]

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
                $(@el).find("[name=#{target}]").val(event.target.result)