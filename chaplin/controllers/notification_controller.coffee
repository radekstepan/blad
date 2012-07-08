define [
    'chaplin'
    'views/notification_view'
], (Chaplin, NotificationView) ->

    class NotificationController extends Chaplin.Controller

        title: 'Notification'

        notify: (params) ->
            #console.debug 'NotificationController#notify'
            @view = new NotificationView()
            @view.render()