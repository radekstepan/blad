marked = require 'marked'

class BasicDocument extends Blað.Type

    render: (done) ->
        # Markdown?
        @body = marked @body if @body?

        done @

Blað.types.BasicDocument = BasicDocument