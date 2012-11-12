marked = require 'marked'

class NewsDocument extends Blað.Type

    render: (done) ->
        @body = marked @body
        done @

Blað.types.NewsDocument = NewsDocument