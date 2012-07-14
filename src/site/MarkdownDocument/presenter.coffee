marked = require 'marked'

class MarkdownDocument extends Blað.Type

    # Presentation for the document.
    render: (done) -> done 'html': marked @markup

Blað.types.MarkdownDocument = MarkdownDocument