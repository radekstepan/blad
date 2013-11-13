define [
    'chaplin'
    'views/document_list_view'
    'views/message_view'
], (Chaplin, DocumentListView, MessageView) ->

    class DocumentsListView extends Chaplin.CollectionView

        tagName: 'ul'

        className: 'list'

        # Automatically append to the DOM on render
        container: '#app'
        
        # Clear existing.
        containerMethod: 'html'

        # Automatically render after initialization
        autoRender: true

        # The most important method a class inheriting from CollectionView
        getView: (item) ->
            # Instantiate an item view
            new DocumentListView 'model': item

        initialize: (params) ->
            super
            
            # Any message to display?
            if params?.message? then @message = params.message

        afterRender: ->
            super

            # Show a message?
            if @message? then new MessageView @message