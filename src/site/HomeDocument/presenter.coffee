marked = require 'marked'

class HomeDocument extends Blað.Type

    render: (done) ->
        # Markdown.
        @welcomeText = marked @welcomeText

        # Children documents.
        @sub = {}
        for article in @children 0
            @sub[article.type] ?= []

            # Sub parsing.
            switch article.type
                when 'ProjectDocument' then article.summary = marked article.summary

            @sub[article.type].push article

        done @

Blað.types.HomeDocument = HomeDocument