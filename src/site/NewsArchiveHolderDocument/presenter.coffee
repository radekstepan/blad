marked = require 'marked'
kronic = require 'kronic-node'

class NewsArchiveHolderDocument extends Blað.Type

    render: (done) ->
        @parent (parent) =>
            # Get how many 'latest' means
            latest = parent.latest

            @siblings (articles) =>
                # Hold the archived articles.
                @articles = []

                # Do we actually have any articles?
                if articles? and articles instanceof Array
                    format = (article) ->
                        # Markdown.
                        article.body = marked article.body if article.body?
                        # Kronic date.
                        article.published = kronic.format(new Date(article.published)) if article.published?

                        article

                    # Sort articles by date and add them to list.
                    @articles = ( format article for article in ( articles.sort (a, b) ->
                        new Date(b.published).getTime() - new Date(a.published).getTime()
                    )[latest...] )
                
                done @

Blað.types.NewsArchiveHolderDocument = NewsArchiveHolderDocument