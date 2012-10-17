marked = require 'marked'
kronic = require 'kronic-node'

class HomeDocument extends Blað.Type

    # Presentation for the document.
    render: (done) ->
        # Markdowny Kronyism :)
        articles = []
        for article in @children() when article.type is 'BlogArticleDocument'
            article.article = marked article.article
            article.published = kronic.format new Date article.published
            articles.push article
        
        done
            'articles': articles

Blað.types.HomeDocument = HomeDocument
