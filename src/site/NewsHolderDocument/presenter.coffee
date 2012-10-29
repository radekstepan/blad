marked = require 'marked'
kronic = require 'kronic-node'

class NewsHolderDocument extends Blað.Type

    render: (done) ->
        # Do we have any more articles?
        @archive = false

        # Hold the latest articles.
        @articles = []

        # Get direct children.
        articles = @children(0)
        # Do we actually have any articles?
        if articles? and articles instanceof Array
            # Sort articles by date.
            all = ( articles.sort (a, b) ->
                new Date(b.published).getTime() - new Date(a.published).getTime()
            )

            # Only take in NewsDocuments (not Archive for example).
            all = ( article for article in all when article.type is 'NewsDocument' )

            # Do we have more articles in the archive?
            if all.length > @latest then @archive = true            
            
            # Format the latest ones.
            format = (article) ->
                # Markdown.
                article.body = marked article.body if article.body?
                # Kronic date.
                article.published = kronic.format(new Date(article.published)) if article.published?

                article
            
            @articles = ( format article for article in all[0...@latest] )
        
        done @

Blað.types.NewsHolderDocument = NewsHolderDocument