marked = require 'marked'

class PersonDocument extends Blað.Type

    render: (done) ->
        # Get other projects.
        @siblings (people) =>
            # Sort people Gos first, then by surname.
            @people = people.sort (a, b) ->
                if a.name is 'Gos Micklem' then -1
                else if b.name is 'Gos Micklem' then 1
                else
                    if b.name.split(' ').pop() > a.name.split(' ').pop() then -1 else 1

            # Markdown.
            @body = marked @body
            
            # We done.
            done @

Blað.types.PersonDocument = PersonDocument