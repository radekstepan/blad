marked = require 'marked'

class ResourcesHolderDocument extends Blað.Type

    render: (done) ->
        # Get all resources and sort them alphabetically apart from InterMine.
        @resources = ( (p.summary = marked p.summary ; p) for p in @children(0) ).sort (a, b) ->
            if a.title is 'InterMine' then -1
            else if b.title is 'InterMine' then 1
            else
                if b.title.toLowerCase() > a.title.toLowerCase() then -1 else 1
        
        # We done.
        done @

Blað.types.ResourcesHolderDocument = ResourcesHolderDocument