define [
    'views/base/view'
    'templates/notification' # just load, exposed on window.JST
], (View) ->

    class NotificationView extends View

        # Template name on global `JST` object.
        templateName: 'notification'

        container: '#app'

        initialize: ->
            super
            
            @delegate 'click', '.close', @remove