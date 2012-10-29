marked = require 'marked'

class ContactsDocument extends Blað.Type

    render: (done) ->
        # Markdown?
        @body = marked @body if @body?

        # ROT13 the email address.
        @email = @email.replace(/[a-zA-Z]/g, (c) ->
            String.fromCharCode (if ((if c <= "Z" then 90 else 122)) >= (c = c.charCodeAt(0) + 13) then c else c - 26)
        ) if @email?

        done @

Blað.types.ContactsDocument = ContactsDocument