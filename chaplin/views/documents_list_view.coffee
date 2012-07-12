define [
    'chaplin'
    'views/document_list_view'
], (Chaplin, DocumentListView) ->

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