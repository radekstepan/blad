define [
    'chaplin'
    'templates/document'
], (Chaplin) ->

    class DocumentView extends Chaplin.View

        tagName: 'tr'

        # Template name on global `JST` object.
        templateName: 'document'
        
        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]