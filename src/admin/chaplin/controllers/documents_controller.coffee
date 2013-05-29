define [
    'chaplin'
    'models/document'
    'models/documents'
    'views/documents_list_view'
    'views/document_edit_view'
    'views/document_export_view'
], (Chaplin, Document, Documents, DocumentsListView, DocumentEditView, DocumentExportView) ->

    class DocumentsController extends Chaplin.Controller

        historyURL: (params) -> ''

        # List all documents.
        index: (params={}) ->
            @collection = new Documents()
            @collection.fetch
                'error': (collection, response) -> throw response
                'success': (collection, response) ->
                    @view = new DocumentsListView 'collection': collection, 'message': params?.message

        # Edit a document.
        edit: (params={}) ->
            @model = new Document '_id': params._id
            @model.fetch
                'success': (model) ->
                    @view = new DocumentEditView 'model': model, 'message': params?.message

        # Create a new document.
        new: ->
            @view = new DocumentEditView()

        # Export all documents in JSON.
        export: ->
            @collection = new Documents()
            @collection.fetch
                'error': (collection, response) ->
                    @view = new DocumentExportView 'message':
                        'type': 'alert', 'text': 'There was a problem getting your documents. Server offline?'
                
                'success': (collection, response) ->
                    if (count = collection.length) > 0
                        message = 'type': 'success', 'text': "#{count} document#{if count isnt 1 then 's' else ''} exported."
                    else
                        message = 'type': 'notify', 'text': 'Nothing to export.'
                    
                    @view = new DocumentExportView 'collection': collection, 'message': message