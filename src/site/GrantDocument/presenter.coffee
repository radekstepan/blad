marked = require 'marked'

class GrantDocument extends Blað.Type

    render: (done) ->
        # Get other grnats.
        @siblings (grants) =>
            @grants = ( (p.summary = marked p.summary ; p) for p in grants )

            # Markdown.
            @body = marked @body
            
            # We done.
            done @

Blað.types.GrantDocument = GrantDocument