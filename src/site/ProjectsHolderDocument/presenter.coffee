class ProjectsHolderDocument extends Blað.Type

    render: (done) ->
        # Get all current projects underneath.
        @projects = ( (p.summary = marked p.summary ; p) for p in @children(0) when p.current )

        # Markdown.
        @body = marked @body
        
        # We done.
        done @

Blað.types.ProjectsHolderDocument = ProjectsHolderDocument