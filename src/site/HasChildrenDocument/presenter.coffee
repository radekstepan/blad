class HasChildrenDocument extends Blað.Type

    render: -> JSON.stringify @children or {}

Blað.types.HasChildrenDocument = HasChildrenDocument