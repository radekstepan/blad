define [
    'chaplin'
    'templates/document_row'
], (Chaplin) ->

    class DocumentListView extends Chaplin.View

        tagName: 'li'

        # Template name on global `JST` object.
        templateName: 'document_row'

        getTemplateFunction: -> JST[@templateName]