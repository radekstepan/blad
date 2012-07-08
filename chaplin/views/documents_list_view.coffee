define [
    'chaplin'
    'views/document_view'
], (Chaplin, DocumentView) ->

    class DocumentsListView extends Chaplin.CollectionView

        tagName:   'table'
        id:        'table'

        # Automatically append to the DOM on render
        container: '#app'
        
        # Automatically render after initialization
        autoRender: true

        # The most important method a class inheriting from CollectionView
        # must overwrite.
        getView: (item) ->
            # Instantiate an item view
            new DocumentView model: item