marked = require 'marked'

class PeopleHolderDocument extends Blað.Type

    render: (done) ->
        # Sort people Gos first, then by surname.
        @people = @children(0).sort (a, b) ->
            if a.name is 'Gos Micklem' then -1
            else if b.name is 'Gos Micklem' then 1
            else
                if b.name.split(' ').pop() > a.name.split(' ').pop() then -1 else 1

        # Markdown.
        @body = marked @body

        done @

Blað.types.PeopleHolderDocument = PeopleHolderDocument