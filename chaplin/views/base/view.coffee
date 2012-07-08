define [
    'chaplin'
], (Chaplin) ->

    class View extends Chaplin.View

        getTemplateFunction: -> JST[@templateName]