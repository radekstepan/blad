#!/usr/bin/env coffee
fs      = require 'fs'
cs      = require 'coffee-script'
eco     = require 'eco'
uglify  = require 'uglify-js'
wrench  = require 'wrench'
events  = require 'events'
mongodb = require 'mongodb'
Q       = require 'q'

# Use events to capture what has happened.
EE = new events.EventEmitter()

exports.log = (cb) -> EE.on 'log', (msg) -> cb msg

# Compile chaplin admin client code.
exports.compile =
    #Admin client code.
    'admin': ->
        EE.emit 'log', 'Compiling chaplin admin client code'

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
        EE.emit 'log', 'Compiling custom document type forms'

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
    'public': (dir) ->
        EE.emit 'log', 'Copying site\'s public files'

        wrench.copyDirSyncRecursive "#{dir}/src/public", "#{__dirname}/public/site"

exports.include =
    # Get a list of presenter paths to includ in super.
    'presenters': (dir) ->
        EE.emit 'log', 'Returning a list of presenter paths'

        def = Q.defer()
        walk "#{dir}/src/types", (files) ->
            def.resolve ( f for f in files when f.match /presenter\.coffee/ )
        def.promise

exports.db =
    # Export the database into a JSON file.
    'export': (cfg, dir, done) ->
        # Try to create folder if not exists.
        ( do ->
            EE.emit 'log', 'Create directory for dump'
            def = Q.defer()
            fs.mkdir "#{dir}/dump", (err) -> if err and err.code isnt 'EEXIST' then def.reject(err) else def.resolve()
            def.promise
        # Connect to MongoDB.
        ).then( ->
            connect(cfg.mongodb, 'documents')
        # Dump the DB.
        ).then( (collection) ->
            EE.emit 'log', 'Dump the database'
            def = Q.defer()
            collection.find({}, 'sort': 'url').toArray (err, docs) -> if err then def.reject(err) else def.resolve(docs)
            def.promise
        # Open file for writing and write file.
        ).then( (docs) ->
            EE.emit 'log', 'Write file'
            def = Q.defer()
            fs.open "#{dir}/dump/data.json", 'w', 0o0666, (err, id) ->
                if err then def.reject(err)
                else
                    fs.write id, JSON.stringify(docs, null, 4), null, 'utf8', -> def.resolve()
            def.promise
        # Callback or die.
        ).done(
            ->
                if done and typeof(done) is 'function' then done()
                else process.exit()
            , (err) ->
                try
                    err = JSON.parse(err)
                    console.log err.error.message or err.message or err
                catch e
                    console.log err
                process.exit()
        )

    # Clears all! and imports the database from a JSON file.
    'import': (cfg, dir, done) ->
        # Connect to MongoDB.
        connect(cfg.mongodb, 'documents'
        # Read file and make into JSON.
        ).then( (collection) ->
            EE.emit 'log', 'Read dump file'
            [ collection, JSON.parse(fs.readFileSync("#{dir}/dump/data.json", 'utf-8')) ]
        # Clear all.
        ).then( ([ collection, docs ]) ->
            EE.emit 'log', 'Clear database'
            def = Q.defer()
            collection.remove {}, (err) -> if err then def.reject(err) else def.resolve([ collection, docs ])
            def.promise
        # Clean up docs from `_id` keys.
        ).then( ([ collection, docs ]) ->
            EE.emit 'log', 'Cleanup `_id`'
            [ collection, ( ( delete doc._id ; doc ) for doc in docs ) ]
        # Insert all.
        ).then( ([ collection, docs ]) ->
            EE.emit 'log', 'Insert into database'
            def = Q.defer()
            collection.insert docs, { 'safe': true }, (err, docs) -> if err then def.reject(err) else def.resolve()
            def.promise
        # Callback or die.
        ).done(
            ->
                if done and typeof(done) is 'function' then done()
                else process.exit()
            , (err) ->
                try
                    err = JSON.parse(err)
                    console.log err.error.message or err.message or err
                catch e
                    console.log err
                process.exit()
        )


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

# Connect to a MongoDB database.
connect = (uri, collection) ->
    EE.emit 'log', 'Connect to MongoDB'

    def = Q.defer()

    # Connect to MongoDB.
    mongodb.Db.connect uri, (err, connection) ->
        if err then def.reject err
        else    
            # Get the collection.
            connection.collection collection, (err, coll) ->
                if err then def.reject err
                else def.resolve coll

    def.promise