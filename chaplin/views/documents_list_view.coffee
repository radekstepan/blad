define [
    'chaplin'
    'views/document_list_view'
], (Chaplin, DocumentListView) ->

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
            new DocumentListView model: item