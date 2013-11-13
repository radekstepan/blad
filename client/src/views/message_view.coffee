class MessageView extends Chaplin.View

    # Automatically prepend before the DOM on render.
    container: '#app'

    containerMethod: 'prepend'

    # Automatically render after initialization
    autoRender: true

    getTemplateFunction: -> require '../templates/message'

    # Not model, but params babe.
    getTemplateData: -> @params

    # Save these.
    initialize: (@params) -> super

    # Events.
    afterRender: ->
        super
        @delegate 'click', @dispose

module.exports = MessageView