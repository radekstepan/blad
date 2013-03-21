{ blad } = require '../../../../../build/server/app.js'

marked = require 'marked'

class exports.BasicDocument extends blad.Type

    render: (done) ->
        # Markdown?
        @body = marked @body if @body?

        done @