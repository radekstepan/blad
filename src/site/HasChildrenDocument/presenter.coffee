class HasChildrenDocument extends Blað.Type

    render: (done) -> done 'children': @children or {}

Blað.types.HasChildrenDocument = HasChildrenDocument