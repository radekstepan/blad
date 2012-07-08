define [
    'chaplin'
    'models/documents'
    'views/documents_list_view'
], (Chaplin, Documents, DocumentsListView) ->

    class DocumentsController extends Chaplin.Controller

        historyURL: (params) ->
            if params.id then "documents/#{params.id}" else ''

        show: (params) ->
            @collection = new Documents()
            @collection.fetch
                'error': (collection, response) -> throw response
                'success': (collection, response) ->
                    @view = new DocumentsListView 'collection': collection