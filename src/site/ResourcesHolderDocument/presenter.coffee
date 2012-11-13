marked = require 'marked'

class ResourcesHolderDocument extends Blað.Type

    render: (done) ->
        # Get all resources and sort them alphabetically.
        @resources = ( (p.summary = marked p.summary ; p) for p in @children(0) )
        
        # We done.
        done @

Blað.types.ResourcesHolderDocument = ResourcesHolderDocument