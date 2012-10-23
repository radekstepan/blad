request = require 'request'
sax = require('sax').parser(true)

class ProjectsHolderDocument extends Blað.Type

    eSearch: 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=Micklem%20G%5bauthor%5d'
    eSummary: 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id='

    render: (done) ->
        
        # Grab hold of publication IDs.
        request @eSearch, (err, res, body) =>
            if err or res.statusCode isnt 200 then done @
            @xmlToIds body, (ids) =>

                # Grab hold of the actual publications.
                request @eSummary + ids.join(','), (err, res, body) =>
                    if err or res.statusCode isnt 200 then done @
                    @xmlToPubs body, (@publications) =>
                        done @

    # Take eSearch XML and call back with ids.
    xmlToIds: (xml, cb) ->
        open = false ; ids = []
        
        sax.onopentag = (node) -> open = node.name is 'Id'
        sax.ontext = (text) -> if open and parseInt text then ids.push text
        sax.onend = -> cb ids
        
        sax.write(xml).close()

    # Take eSummary XML and call back with publications.
    xmlToPubs: (xml, cb) ->
        docs = [] ; doc = {} ; tag = {} ; authors = []

        sax.onattribute = (attr) -> tag[attr.name] = attr.value

        sax.onclosetag = (node) ->
            switch node
                when 'DocSum'
                    doc.Authors = authors
                    docs.push doc
                    doc = {} ; authors = []
                when 'Id'
                    doc.Id = tag.Text
                    tag = {}
                when 'Item'
                    switch tag.Name
                        when 'PubDate', 'FullJournalName', 'Title' then doc[tag.Name] = tag.Text
                        when 'Author' then authors.push tag.Text
                    tag = {}

        sax.ontext = (text) ->
            text = text.replace(/\s+/g, ' ')
            if text isnt ' ' then tag.Text = text

        sax.onend = -> cb docs

        sax.write(xml).close()

Blað.types.ProjectsHolderDocument = ProjectsHolderDocument