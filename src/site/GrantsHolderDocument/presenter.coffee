class GrantsHolderDocument extends Blað.Type

    render: (done) ->
        # Get all current grants underneath.
        @grants = ( (g.summary = marked g.summary ; g) for g in @children(0) when g.current )

        # Markdown.
        @body = marked @body
        
        # We done.
        done @

Blað.types.GrantsHolderDocument = GrantsHolderDocument