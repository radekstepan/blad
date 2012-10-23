marked = require 'marked'
request = require 'request'
kronic = require 'kronic-node'

class HomeDocument extends Blað.Type

    twitter: 'http://api.twitter.com/1/statuses/user_timeline.json?screen_name=intermineorg&count=1'

    render: (done) ->
        # Markdown.
        @welcomeText = marked @welcomeText

        # Children documents.
        @sub = {}
        for page in @children 1 # not direct descendants
            @sub[page.type] ?= []

            # Sub parsing.
            switch page.type
                when 'ProjectDocument', 'GrantDocument'
                    if page.home # should show on homepage?
                        page.summary = marked page.summary
                        @sub[page.type].push page
                else
                    @sub[page.type].push page

        # Check if data in store is old.
        if @store.isOld 'tweet', 1, 'day'
            # Fetch the latest tweet.
            request @twitter, (err, res, body) =>
                if err or res.statusCode isnt 200 then done @
                    
                tweet = JSON.parse(body).pop()

                # Cache the new data.
                @store.save 'tweet', tweet, =>
                    # Get the tweet, add ago time and render.
                    @tweet = @store.get 'tweet'
                    @tweet.ago = kronic.format new Date @tweet.created_at
                    done @
        else
            # Get the tweet, add ago time and render.
            @tweet = @store.get 'tweet'
            @tweet.ago = kronic.format new Date @tweet.created_at
            done @

Blað.types.HomeDocument = HomeDocument