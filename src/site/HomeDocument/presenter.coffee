marked = require 'marked'
request = require 'request'
kronic = require 'kronic-node'

class HomeDocument extends Blað.Type

    twitter: 'http://api.twitter.com/1/statuses/user_timeline.json?screen_name=intermineorg&count=1'

    render: (done) ->
        # Markdown.
        @welcomeText = marked @welcomeText

        # Our publications in chronological order.
        pubs = []
        for i in [0...10]
            if @["pubTitle#{i}"]
                pubs.push
                    'link':      @["pubURL#{i}"] or ''
                    'title':     @["pubTitle#{i}"] or ''
                    'journal':   @["pubJournal#{i}"] or ''
                    'authors':   @["pubAuthors#{i}"] or ''
                    'published': @["pubDate#{i}"] or 0

        @publications = pubs.sort (a, b) ->
            parseDate = (date) ->
                return 0 if date is 0
                [ year, month, day] = date.split(' ')
                month = month or 'Jan' ; day = day or 1
                p = kronic.parse([ day, month, year ].join(' '))
                if p then p.getTime() else 0

            if parseDate(b.published) > parseDate(a.published) then 1
            else -1

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

        # Randomize projects and funding.
        @sub.ProjectDocument = randomArray @sub.ProjectDocument
        @sub.GrantDocument = randomArray @sub.GrantDocument

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

# Seed array randomly.
randomArray = (arr) ->
    i = arr.length
    return [] if i is 0
    while --i
        j = Math.floor(Math.random() * (i + 1))
        tempi = arr[i]
        tempj = arr[j]
        arr[i] = tempj
        arr[j] = tempi
    arr