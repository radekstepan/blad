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

        initialize: (params) ->
            @model = params.model
            @subviews ?= []

        afterRender: ->
            super

            # Attach handlers...
            @delegate 'change', '[data-custom="file"]', @loadFileHandler
            @delegate 'change', '[data-custom="date"]', @niceDateHandler

        # Onchange form file input fields.
        loadFileHandler: (e) ->
            file = new FileReader()
            file.readAsDataURL $(e.target)[0].files[0]
            file.onload = (event) =>
                # Set base64 encoded string into target hidden input field.
                target = $(e.target).attr('data-target')
                $(@el).find("[name=#{target}]").val(event.target.result)

        # Convert nice date into a Date form.
        niceDateHandler: (e) ->
            # The input field with the nice date.
            target = $(e.target)
            
            # Clear existing error message if present.
            target.closest('div').removeClass('error')
            @error?.remove()

            d = Kronic.parse target.val()
            unless d?
                # Show an error message.
                # Find nearest `<div>`.
                div = target.closest('div')
                div.addClass('error')
                div.append @error = $('<small/>', 'text': 'Do not understand this date')
            else
                # Set the serialized date.
                j = new Date(d).toJSON()
                t = target.attr('data-target')
                $(@el).find("[name=#{t}]").val(j)