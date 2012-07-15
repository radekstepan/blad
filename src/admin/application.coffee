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
        title: 'Blað CMS'

        # Store the X-Blad-ApiKey here. Application is global.
        apiKey: undefined

        # Authenticate and authorize the client.
        auth: (signedIn) ->
            # Check for saved cookie.
            for cookie in document.cookie.split ';'
                [k, v] = cookie.split '='
                if k is 'X-Blad-ApiKey' then return signedIn true, v

            # Need to auth with the server.
            navigator.id.get (assertion) ->
                if assertion
                    $.ajax
                        url: "/auth"
                        type: "POST"
                        data:
                            'assertion': assertion
                        
                        success: (data) ->
                            key = JSON.parse(data).key
                            
                            # Save cookie for 24h.
                            d = new Date() ; d.setDate d.getDate() + 1 ; d = d.toUTCString()
                            document.cookie = "X-Blad-ApiKey=#{key};expires=#{d}"
                            
                            signedIn true, key
                        
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
            @auth (isSignedIn, @apiKey) =>
                if isSignedIn
                    # Register all routes and start routing
                    @initRouter routes, 'pushState': no

                    # Freeze the application instance to prevent further changes
                    Object.freeze? this
                else
                    console.log res

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