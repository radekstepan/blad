marked = require 'marked'

class GrantDocument extends Blað.Type

    render: (done) ->
        # Get other grants.
        @siblings (grants) =>
            @grants = ( (g.summary = marked g.summary ; g) for g in grants )

            # Markdown.
            @body = marked @body
            
            # Provide a nice "table translations".
            @table = []
            for field in [ 'funding', 'pi', 'received', 'coinvestigators' ] when @[field]? and @[field].length isnt 0
                switch field
                    when 'funding' then trans = 'Funding body'
                    when 'pi' then trans = 'Principal Investigator'
                    when 'received' then trans = 'Received by'
                    when 'coinvestigators' then trans = 'Co-investigators'
                @table.push
                    'key': trans
                    'value': @[field]

            # We done.
            done @

Blað.types.GrantDocument = GrantDocument