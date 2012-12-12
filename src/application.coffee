define [
    'chaplin'
    'views/layout'
    'routes'
], (Chaplin, Layout, routes) ->

    # The application object
    # Choose a meaningful name for your application
    class Application extends Chaplin.Application

        # Set your application name here so the document title is set to
        # “Controller title – Site title” (see Layout#adjustTitle)
        title: 'blað CMS'

        # Store the X-Blad-ApiKey here. Application is global.
        apiKey: undefined

        # Authenticate and authorize the client.
        auth: (signedIn) ->
            # Check for saved cookie.
            for cookie in document.cookie.split ';'
                [k, v] = cookie.split '='
                if k is 'X-Blad-ApiKey' then return signedIn true, v

            # Show a message during sign-in.
            $('#app').append $ '<div/>',
                'class': 'alert-box'
                'text':  'Signing-in to Persona.org (Mozilla), make sure pop-ups are allowed'

            # Need to auth with the server.
            navigator.id.get (assertion) ->
                if assertion
                    $.ajax
                        url:      '/auth'
                        type:     'POST'
                        dataType: 'json'
                        data:
                            'assertion': assertion
                        
                        success: (data) ->
                            # Save cookie for 24h.
                            d = new Date() ; d.setDate d.getDate() + 1 ; d = d.toUTCString()
                            document.cookie = "X-Blad-ApiKey=#{data.key};expires=#{d}"
                            
                            signedIn true, data.key
                        
                        error: (data) -> signedIn false, data
                else
                    signedIn false, 'message': 'Cancelled sign-in'

        initialize: ->
            super
            #console.debug 'HelloWorldApplication#initialize'

            # Initialize core components
            @initDispatcher()
            @initLayout()
            @initTemplates()
            @initMediator()

            # Authenticate and authorize the user.
            @auth (isSignedIn, res) =>
                if isSignedIn
                    # Save the response API key.
                    @apiKey = res

                    # Register all routes and start routing
                    @initRouter routes

                    # Freeze the application instance to prevent further changes
                    Object.freeze? this
                else
                    # Let us know...
                    $('#app').append $ '<div/>',
                        'class': 'alert-box alert'
                        'text':  JSON.parse(res.responseText).message

        # Override standard layout initializer
        # ------------------------------------
        initLayout: ->
            # Use an application-specific Layout class. Currently this adds
            # no features to the standard Chaplin Layout, it’s an empty placeholder.
            @layout = new Layout {@title}

        # Create a namespace for templates.
        # ---------------------------------            
        initTemplates: ->
            window.JST = {}

        # Create additional mediator properties
        # -------------------------------------
        initMediator: ->
            # Create a user property
            Chaplin.mediator.user = null
            # Add additional application-specific properties and methods
            # Seal the mediator
            Chaplin.mediator.seal()