define [
    'views/base/view'
    'templates/hello_world' # just load, exposed on window.JST
], (View) ->

    class HelloWorldView extends View

        # Template name on global `JST` object.
        templateName: 'hello_world'

        className: 'hello-world'

        # Automatically append to the DOM on render
        container: '#app'
        
        # Automatically render after initialization
        autoRender: true