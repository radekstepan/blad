#!/usr/bin/env coffee

fs  = require 'fs'
cs  = require 'coffee-script'
eco = require 'eco'
Q   = require 'q'
require 'colors'

blad = require('./server.coffee')

task "compile", "compile API server and admin client code", ->
    
    server = ->
        deferred = Q.defer()

        # Core server code.
        codez = [ fs.readFileSync('./server.coffee', "utf-8") ]

        # Custom presenters.
        walk './src/site', (files) ->
            for file in files when file.match /presenter\.coffee/
                console.log file.grey
                codez.push fs.readFileSync(file, "utf-8")

            # Write it all.
            write './server.js', cs.compile codez.join("\n")

            deferred.resolve()
        deferred.promise

    client = (done) ->
        deferred = Q.defer()

        # Client side code.
        walk './src/admin', (files) ->
            for file in files
                console.log file.grey
                if file.match /\.eco/
                    name = file.split('/').pop()
                    js = uglify "JST['#{name}'] = " + eco.precompile fs.readFileSync file, "utf-8"
                    write file.replace('./src/admin', './public/admin/js').replace('.eco', '.js'), js
                else if file.match /\.coffee/
                    js = cs.compile fs.readFileSync(file, "utf-8"), 'bare': 'on'
                    write file.replace('./src/admin', './public/admin/js').replace('.coffee', '.js'), js

            deferred.resolve()
        deferred.promise
    
    forms = (done) ->
        deferred = Q.defer()

        # Custom document forms.
        walk './src/site', (files) ->
            tml = []

            # Inject a BasicDocument form first.
            tml.push uglify "JST['form_BasicDocument.eco'] = #{eco.precompile("")}"

            # Do user's files.
            for file in files when file.match /form\.eco/
                console.log file.grey
                js = eco.precompile fs.readFileSync file, "utf-8"
                p = file.split('/') ; name = p[p.length-2]
                tml.push uglify "JST['form_#{name}.eco'] = #{js}"

            write './public/admin/js/templates/document_forms.js', tml.join("\n")
            deferred.resolve()
        deferred.promise

    Q.all([server(), client(), forms()]).done ->
        console.log 'All is well.'.green
        # Finish.
        process.exit(0)

task "export", "export the database into a JSON file", ->
    blad.app.db (collection) ->
        # Dump the DB.
        collection.find({}, 'sort': 'url').toArray (err, docs) ->
            throw err if err
            
            # Open file for writing.
            fs.open "./dump/data.json", 'w', 0o0666, (err, id) ->
                throw err if err
                
                # Write file.
                fs.write id, JSON.stringify(docs, null, "\t"), null, "utf8"

                console.log "Dumped #{docs.length} documents".yellow

task "import", "clears all! and imports the database from a JSON file", ->
    blad.app.db (collection) ->
        # Clear all
        collection.remove {}, (err) ->
            throw err if err

            # Read file and make into JSON.
            docs = JSON.parse fs.readFileSync "./dump/data.json", "utf-8"

            # Insert all.
            collection.insert docs, { 'safe': true }, (err, docs) ->
                throw err if err

                console.log "Inserted #{docs.length} documents".yellow


# -------------------------------------------------------------------


# Traverse a directory and return a list of files (async, recursive).
walk = (path, cb) ->
    results = []
    # Read directory.
    fs.readdir path, (err, list) ->
        throw err if err
        
        # Get listing length.
        pending = list.length
        
        return cb results unless pending # Done already?
        
        # Traverse.
        list.forEach (file) ->
            # Form path
            file = "#{path}/#{file}"
            fs.stat file, (err, stat) ->
                throw err if err
                # Subdirectory.
                if stat and stat.isDirectory()
                    walk file, (res) ->
                        # Append result from sub.
                        results = results.concat(res)
                        cb results unless --pending # Done yet?
                # A file.
                else
                    results.push file
                    cb results unless --pending # Done yet?

# Compress using `uglify-js`.
uglify = (input) ->
    jsp = require("uglify-js").parser
    pro = require("uglify-js").uglify

    pro.gen_code pro.ast_squeeze pro.ast_mangle jsp.parse input

# Write to file, sync.
write = (path, text, mode = "w") ->
    writeFile = (path) ->
        id = fs.openSync path, mode, 0o0666
        fs.writeSync id, text, null, "utf8"

    # Create the directory if it does not exist first.
    dir = path.split('/').reverse()[1...].reverse().join('/')
    if dir isnt '.'
        console.log "Creating dir #{dir}".yellow
        try
            fs.mkdirSync dir, 0o0777
        catch e
            if e.code isnt 'EEXIST' then throw e
        
        writeFile path
    else
        writeFile path