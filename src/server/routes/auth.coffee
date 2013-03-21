#!/usr/bin/env coffee
request = require 'request' # call Persona.org
crypto  = require 'crypto'  # md5 hashing

# BrowserID auth.
module.exports = ({ config, log }) ->
    '/auth':
        post: ->
            # Authenticate.
            request.post
                'url': config.browserid.provider
                'form':
                    'assertion': @req.body.assertion
                    'audience':  "http://#{@req.headers.host}"
            , (error, response, body) =>
                throw error if error

                body = JSON.parse body
                
                if body.status is 'okay'
                    # Authorize.
                    if body.email in config.browserid.users
                        log.info "Identity verified for #{body.email}"
                        # Create API Key from email and salt for the client.
                        @res.writeHead 200, 'application/json'
                        @res.write JSON.stringify
                            'email': body.email
                            'key':   crypto.createHash('md5').update(body.email + config.browserid.salt).digest('hex')
                    else
                        log.warn "#{body.email} tried to access the API"
                        @res.writeHead 403, 'application/json'
                        @res.write JSON.stringify
                            'message': "Your email #{body.email} is not authorized to access the admin backend"
                else
                    # Pass on the authentication error response to the client.
                    log.error body.message
                    @res.writeHead 403, 'application/json'
                    @res.write JSON.stringify body
                
                @res.end()