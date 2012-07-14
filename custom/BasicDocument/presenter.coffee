class BasicDocument extends Blað.Type

    # Eco template.
    template: '<%= @_id %>'

    # Presentation for the document.
    render: ->
        eco.render @template,
            '_id': @_id
            'url': @url

Blað.types.BasicDocument = BasicDocument