#!/usr/bin/env coffee

# Sitemap.
module.exports = ({ log, app }) ->
    '/sitemap.xml':
        get: ->
            log.info 'Get sitemap.xml'

            # Give me all public documents.
            app.db (collection) =>
                collection.find('public': true).toArray (err, docs) =>
                    throw err if err

                    xml = [ '<?xml version="1.0" encoding="utf-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' ]
                    for doc in docs
                        xml.push "<url><loc>http://#{@req.headers.host}#{doc.url}</loc><lastmod>#{doc.modified}</lastmod></url>"
                    xml.push '</urlset>'

                    @res.writeHead 200, "content-type": "application/xml"
                    @res.write xml.join "\n"
                    @res.end()