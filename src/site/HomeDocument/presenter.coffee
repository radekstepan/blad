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
        for page in @children 0
            @sub[page.type] ?= []

            # Sub parsing.
            switch page.type
                when 'ProjectDocument', 'GrantDocument'
                    if page.home # should show on homepage?
                        page.summary = marked page.summary
                        @sub[page.type].push page
                else
                    @sub[page.type].push page

        # Fetch the latest tweet.
        request @twitter, (err, res, body) =>
            if !err and res.statusCode is 200
                tweets = JSON.parse body
                if tweets.length is 1
                    tweet = tweets.pop()
                    @tweet =
                        'text': tweet.text
                        'date': kronic.format new Date(tweet.created_at)
                        'id':   tweet.id_str

            done @

Blað.types.HomeDocument = HomeDocument