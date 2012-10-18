marked = require 'marked'

class ProjectDocument extends Blað.Type

    render: (done) ->
        # Get other projects
        @siblings (projects) =>
            # Only the current ones.
            @projects = ( (p.summary = marked p.summary ; p) for p in projects when p.current )

            # Markdown.
            @body = marked @body
            
            # We done.
            done @

Blað.types.ProjectDocument = ProjectDocument