marked = require 'marked'

class GrantDocument extends Blað.Type

    render: (done) ->
        # Get other grants.
        @siblings (grants) =>
            @grants = ( (g.summary = marked g.summary ; g) for g in grants )

            # Markdown.
            @body = marked @body
            
            # We done.
            done @

Blað.types.GrantDocument = GrantDocument