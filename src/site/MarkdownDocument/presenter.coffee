marked = require 'marked'

class MarkdownDocument extends Blað.Type

    # Presentation for the document.
    render: -> marked @markup

Blað.types.MarkdownDocument = MarkdownDocument