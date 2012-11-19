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
            
            # Our publications in chronological order.
            pubs = []
            for i in [0...10]
                if @["pubTitle#{i}"]
                    pubs.push
                        'link':      @["pubURL#{i}"] or ''
                        'title':     @["pubTitle#{i}"] or ''
                        'journal':   @["pubJournal#{i}"] or ''
                        'authors':   @["pubAuthors#{i}"] or ''
                        'published': @["pubDate#{i}"] or 0

            @publications = pubs.sort (a, b) ->
                parseDate = (date) ->
                    return 0 if date is 0
                    [ year, month, day] = date.split(' ')
                    month = month or 'Jan' ; day = day or 1
                    p = kronic.parse([ day, month, year ].join(' '))
                    if p then p.getTime() else 0

                if parseDate(b.published) > parseDate(a.published) then 1
                else -1
            
            # We done.
            done @

Blað.types.PersonDocument = PersonDocument