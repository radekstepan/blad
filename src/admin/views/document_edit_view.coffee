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
            @subviews ?= []

            @model = params?.model or new Document()

            # Any message to display?
            if params?.message? then @message = params.message

        # Render the custom document template.
        afterRender: ->
            super

            @undelegate()

            @delegate 'click', '.save', @saveHandler
            @delegate 'click', '.delete', @deleteHandler
            @delegate 'change', '.changeType', @changeTypeHandler
            
            @subviews.push new DocumentCustomView 'model': @model

            # Show a message?
            if @message? then @subviews.push new MessageView @message

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
                    # Pass an extra message to display.
                    Chaplin.mediator.publish '!startupController', 'documents', 'edit',
                        '_id': response._id
                        'message':
                            'type': 'success'
                            'text': "Document #{model.get('url')} saved."
                    # Change the URL too so we can click on 'New Document' button again.
                    Chaplin.mediator.publish '!router:changeURL', "admin/edit/#{response._id}"
                
                'error': (model, response) =>
                    # Highlight the fields that failed validation.
                    for field, message of JSON.parse response.responseText
                        # Find nearest `<div>`.
                        div = $(@container).find("#{@tagName} [name=#{field}]").closest('div')
                        div.addClass('error')
                        div.append small = $('<small/>', 'text': message)

                        @clearThese.push small

                    @subviews.push new MessageView
                        'type': 'alert'
                        'text': "You no want dis."

        deleteHandler: =>
            if confirm 'Are you sure you want to delete this document?'
                @model.destroy
                    'success': (model, response) ->
                        # Go back to index.
                        Chaplin.mediator.publish '!startupController', 'documents', 'index',
                            'message':
                                'type': 'success'
                                'text': "Document #{model.get('url')} deleted."
                        # Change the URL too.
                        Chaplin.mediator.publish '!router:changeURL', "admin/"
                    
                    'error': (model, response) ->
                        @subviews.push new MessageView
                            'type': 'alert'
                            'text': "You no want dis."

        # Call me to reload the View with different type.
        changeTypeHandler: (e) ->
            @model.set 'type', $(e.target).find('option:selected').text()
            @render()