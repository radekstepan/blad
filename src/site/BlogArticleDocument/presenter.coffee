class BlogArticleDocument extends Blað.Type

    # Presentation for the document.
    render: (done) -> done
        '_id': @_id
        'url': @url

Blað.types.BlogArticleDocument = BlogArticleDocument