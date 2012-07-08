define [
    'chaplin'
    'templates/document_row'
], (Chaplin) ->

    class DocumentListView extends Chaplin.View

        tagName: 'tr'

        # Template name on global `JST` object.
        templateName: 'document_row'
        
        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]