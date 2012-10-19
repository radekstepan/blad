define [
    'chaplin'
    'models/document'
    'views/document_custom_view'
    'views/message_view'
    'templates/document_edit'
    'templates/document_forms'
], (Chaplin, Document, DocumentCustomView, MessageView) ->

    # Used for editing and creating new documents.
    class DocumentEditView extends Chaplin.View

        # Contains links to elements to clear before each model save.
        clearThese: []

        tagName: 'form'

        # Automatically append to the DOM on render.
        container: '#app'

        # Clear existing.
        containerMethod: 'html'

        # Automatically render after initialization
        autoRender: true

        # Template name on global `JST` object.
        templateName: 'document_edit.eco'

        getTemplateFunction: -> JST[@templateName]

        initialize: (params) ->
            @model = params?.model or new Document()

        # Render the custom document template.
        afterRender: ->
            super

            @delegate 'click', '.save', @saveHandler
            @delegate 'click', '.delete', @deleteHandler
            @delegate 'change', '.changeType', @changeTypeHandler
            
            new DocumentCustomView 'model': @model

        saveHandler: =>
            # Get the form fields.
            attr = {}
            for object in $("#{@container} #{@tagName}").serializeArray()
                # Coerce string to boolean when possible.
                switch object.value
                    when 'true' then attr[object.name] = true
                    when 'false' then attr[object.name] = false
                    else attr[object.name] = object.value
            
            # Clear existing error messages if present.
            $(@container).find("#{@tagName} .error").removeClass('error')
            for element in @clearThese
                element.remove()

            # Save them.
            @model.save attr,
                'wait': true
                'success': (model, response) =>
                    # Re-render the view.
                    @render()
                    # Show a success message.
                    new MessageView
                        'type': 'success'
                        'text': "Document #{model.get('url')} saved."
                
                'error': (model, response) =>
                    # Highlight the fields that failed validation.
                    for field, message of JSON.parse response.responseText
                        # Find nearest `<div>`.
                        div = $(@container).find("#{@tagName} [name=#{field}]").closest('div')
                        div.addClass('error')
                        div.append small = $('<small/>', 'text': message)

                        @clearThese.push small

                    new MessageView
                        'type': 'alert'
                        'text': "You no want dis."

        deleteHandler: =>
            if confirm 'Are you sure you want to delete this document?'
                @model.destroy
                    'success': (model, response) ->
                        new MessageView
                            'type': 'success'
                            'text': "Document #{model.get('url')} deleted. Reload the page."
                    
                    'error': (model, response) ->
                        new MessageView
                            'type': 'alert'
                            'text': "You no want dis."

        # Call me to reload the View with different type.
        changeTypeHandler: (e) ->
            @model.set 'type', $(e.target).find('option:selected').text()
            @render()