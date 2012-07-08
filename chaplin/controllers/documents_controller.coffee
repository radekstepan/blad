define [
    'chaplin'
    'models/document'
    'models/documents'
    'views/documents_list_view'
    'views/document_edit_view'
], (Chaplin, Document, Documents, DocumentsListView, DocumentEditView) ->

    class DocumentsController extends Chaplin.Controller

        historyURL: (params) ->
            if params.id then "edit/#{params.id}" else ''

        index: (params) ->
            @collection = new Documents()
            @collection.fetch
                'error': (collection, response) -> throw response
                'success': (collection, response) ->
                    @view = new DocumentsListView 'collection': collection

        edit: (params) ->
            @model = new Document 'id': params.document
            @model.fetch
                'success': (model) ->
                    @view = new DocumentEditView 'model': model

        new: (params) ->
            @view = new DocumentEditView()