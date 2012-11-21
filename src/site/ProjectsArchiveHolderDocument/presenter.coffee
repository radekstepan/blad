marked = require 'marked'

class ProjectsArchiveHolderDocument extends Blað.Type

    render: (done) ->
        # Get all not current projects at our level.
        @siblings (projects) =>
            @current = false
            @projects = []
            for p in projects
                if !p.current and p.type is 'ProjectDocument'
                    if p.summary then p.summary = marked p.summary
                    @projects.push p
                else
                    @current = true
            
            # We done.
            done @

Blað.types.ProjectsArchiveHolderDocument = ProjectsArchiveHolderDocument