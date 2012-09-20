marked = require 'marked'
kronic = require 'kronic-node'

class BlogArticleDocument extends Blað.Type

    # Presentation for the document.
    render: (done) ->
        done
            'title':     @title
            'author':    @author
            'article':   marked @article
            'published': kronic.format new Date @published

Blað.types.BlogArticleDocument = BlogArticleDocument