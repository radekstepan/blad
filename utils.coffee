#!/usr/bin/env coffee
fs     = require 'fs'
cs     = require 'coffee-script'
eco    = require 'eco'
uglify = require 'uglify-js'
wrench = require 'wrench'
Q      = require 'q'

# Compile API server and admin client code.
exports.compile =
    #Admin client code.
    'admin': ->
        def = Q.defer()

        walk "#{__dirname}/src", (files) ->
            for file in files
                if file.match /\.eco/
                    name = file.split('/').pop()
                    js = eco.precompile fs.readFileSync file, "utf-8"
                    js = (uglify.minify("JST['#{name}'] = #{js}", 'fromString': true)).code
                    write file.replace('/src/', '/public/admin/js/').replace('.eco', '.js'), js # what if we have /src/ in deeper?
                else if file.match /\.coffee/
                    js = cs.compile fs.readFileSync(file, "utf-8"), 'bare': 'on'
                    write file.replace('/src/', '/public/admin/js/').replace('.coffee', '.js'), js # what if we have /src/ in deeper?

            def.resolve()

        def.promise

    # Site's custom document type forms.
    'forms': (dir) ->
        def = Q.defer()

        walk "#{dir}/src/types", (files) ->
            tml = []

            # Inject a BasicDocument form first.
            tml.push (uglify.minify("JST['form_BasicDocument.eco'] = #{eco.precompile("")}", 'fromString': true)).code

            # Do user's files.
            for file in files when file.match /form\.eco/
                js = eco.precompile fs.readFileSync file, "utf-8"
                p = file.split('/') ; name = p[p.length-2]
                tml.push (uglify.minify("JST['form_#{name}.eco'] = #{js}", 'fromString': true)).code

            write "#{__dirname}/public/admin/js/templates/document_forms.js", tml.join("\n")

            def.resolve()

        def.promise

exports.copy =
    # Copy over site's public files.
    'public': (dir) -> wrench.copyDirSyncRecursive "#{dir}/src/public", "#{__dirname}/public/site"

exports.include =
    # Get a list of presenter paths to includ in super.
    'presenters': (dir) ->
        def = Q.defer()
        walk "#{dir}/src/types", (files) ->
            def.resolve ( f for f in files when f.match /presenter\.coffee/ )
        def.promise

exports.db =
    # Export the database into a JSON file.
    'export': ->
        blad.app.db (collection) ->
            # Dump the DB.
            collection.find({}, 'sort': 'url').toArray (err, docs) ->
                throw err if err

                # Open file for writing.
                fs.open "./dump/data.json", 'w', 0o0666, (err, id) ->
                    throw err if err
                    
                    # Write file.
                    fs.write id, JSON.stringify(docs, null, "\t"), null, "utf8"
    # Clears all! and imports the database from a JSON file.
    'import': ->
        blad.app.db (collection) ->
            # Clear all
            collection.remove {}, (err) ->
                throw err if err

                # Read file and make into JSON.
                docs = JSON.parse fs.readFileSync "./dump/data.json", "utf-8"

                # Clean up docs from `_id` keys.
                docs = ( ( delete doc._id ; doc ) for doc in docs )

                # Insert all.
                collection.insert docs, { 'safe': true }, (err, docs) ->
                    throw err if err

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

# Write to file, sync.
write = (path, text, mode = "w") ->
    writeFile = (path) ->
        id = fs.openSync path, mode, 0o0666
        fs.writeSync id, text, null, "utf8"

    # Create the directory if it does not exist first.
    dir = path.split('/').reverse()[1...].reverse().join('/')
    if dir isnt '.'
        try
            fs.mkdirSync dir, 0o0777
        catch e
            if e.code isnt 'EEXIST' then throw e
        
        writeFile path
    else
        writeFile path