#!/usr/bin/env coffee
fs      = require 'fs'
path    = require 'path'
cs      = require 'coffee-script'
eco     = require 'eco'
uglify  = require 'uglify-js'
wrench  = require 'wrench'
events  = require 'events'
mongodb = require 'mongodb'
async   = require 'async'

# Use events to capture what has happened.
EE = new events.EventEmitter()

exports.log = (cb) -> EE.on 'log', (msg) -> cb msg

# Compile chaplin admin client code.
exports.compile =
    # Admin client code.
    'admin': (cb) ->
        EE.emit 'log', 'Compiling Chaplin.js admin client app code'

        # Make a dir for us.
        async.waterfall [ (_cb) ->
            try
                wrench.mkdirSyncRecursive "#{__dirname}/../public/admin", 0o0777
                _cb null
            catch err
                _cb err

        # CSS & vendor JS.
        , async.apply wrench.copyDirRecursive, "#{__dirname}/../../src/admin/assets", "#{__dirname}/../public/admin"
        
        # CoffeeScript & Eco.
        , (_cb) ->
            # If there are no more jobs then continue.
            jobs = 0 ; canExit = false
            exit = -> if jobs is 0 and canExit then _cb null

            # Where from/to?
            root = "#{__dirname}/../../src/admin"
            target = path.resolve "#{__dirname}/../../build/public/admin/js"

            wrench.readdirRecursive root, (err, files) ->
                # Crap?
                if err then return _cb err
                
                # Are we done?
                unless files
                    canExit = true
                    exit()
                else
                    # Moar jobs.
                    jobs++ ; fns = []
                    # Compilez mich.
                    for file in files then do (file) ->
                        # Make into full path.
                        file = root + '/' + file

                        console.log file

                        # Assume we are a file if we have a good extension.
                        if file.match /\.eco/
                            fns.push (__cb) ->
                                name = file.split('/').pop()
                                js = eco.precompile fs.readFileSync file, "utf8"
                                js = (uglify.minify("JST['#{name}'] = #{js}", 'fromString': true)).code
                                write (target + '/' + file).replace('.eco', '.js'), js
                                __cb null
                        
                        else if file.match /\.coffee/
                            fns.push (__cb) ->
                                js = cs.compile fs.readFileSync(file, "utf8"), 'bare': 'on'
                                write (target + '/' + file).replace('.coffee', '.js'), js
                                __cb null

                    # Run all of them in parallel.
                    async.parallel fns, (err) ->
                        if err then _cb err
                        else
                            # One more thing done.
                            jobs--
                            # Exit?
                            exit()

        ], cb

    # Site's custom document type forms.
    'forms': ({ site_src }) ->
        (cb) ->
            EE.emit 'log', 'Compiling custom document type forms'

            walk path.join(site_src, '/src/types'), (files) ->
                tml = []

                # Inject a BasicDocument form first.
                tml.push (uglify.minify("JST['form_BasicDocument.eco'] = #{eco.precompile("")}", 'fromString': true)).code

                # Do site files.
                for file in files when file.match /form\.eco/
                    js = eco.precompile fs.readFileSync file, "utf-8"
                    p = file.split('/') ; name = p[p.length-2]
                    tml.push (uglify.minify("JST['form_#{name}.eco'] = #{js}", 'fromString': true)).code

                write "#{__dirname}/../public/admin/js/templates/document_forms.js", tml.join("\n")

                cb null

exports.copy =
    # Copy over site's public files.
    'public': ({ site_src }) ->
        (cb) ->
            EE.emit 'log', "Copying site's public files"
            wrench.copyDirSyncRecursive path.join(site_src, '/src/public'), "#{__dirname}/../public/site"
            cb null

exports.include =
    # Get a list of presenter paths to include in super.
    'presenters': ({ site_src }) ->
        (cb) ->
            EE.emit 'log', 'Returning a list of presenter paths'
            walk path.join(site_src, '/src/types'), (files) ->
                files = ( f for f in files when f.match /presenter\.coffee/ )
                cb null, files

exports.db =
    # Export the database into a JSON file.
    'export': (cfg, dir, done) ->
        
        # Try to create folder if not exists.
        async.waterfall [ (cb) ->
            EE.emit 'log', 'Create directory for dump'
            fs.mkdir "#{dir}/dump", (err) -> if err and err.code isnt 'EEXIST' then cb(err) else cb(null)
        
        # Connect to MongoDB.
        , (cb) -> connect cfg.mongodb, 'documents', cb

        # Dump the DB.
        , (collection, cb) ->
            EE.emit 'log', 'Dump the database'
            collection.find({}, 'sort': 'url').toArray (err, docs) -> if err then cb(err) else cb(docs)
        
        # Open file for writing and write file.
        , (docs, cb) ->
            EE.emit 'log', 'Write file'
            fs.open "#{dir}/dump/data.json", 'w', 0o0666, (err, id) ->
                if err then cb err
                else fs.write id, JSON.stringify(docs, null, 4), null, 'utf8', -> cb null

        # Callback or die.
        ], (err) ->
            if err
                try
                    err = JSON.parse(err)
                    console.log err.error.message or err.message or err
                catch e
                    console.log err
                process.exit()
            else
                if done and typeof(done) is 'function' then done()
                else process.exit()

    # Clears all! and imports the database from a JSON file.
    'import': (cfg, dir, done) ->

        # Connect to MongoDB.        
        async.waterfall [ (cb) -> connect cfg.mongodb, 'documents', cb

        # Read file and make into JSON.
        , (collection, cb) ->
            EE.emit 'log', 'Read dump file'
            cb null, collection, JSON.parse(fs.readFileSync("#{dir}/dump/data.json", 'utf-8'))
        
        # Clear all.
        , (collection, docs, cb) ->
            EE.emit 'log', 'Clear database'
            collection.remove {}, (err) -> if err then cb(err) else cb null, collection, docs
        
        # Clean up docs from `_id` keys.
        , (collection, docs, cb) ->
            EE.emit 'log', 'Cleanup `_id`'
            cb null, collection, ( ( delete doc._id ; doc ) for doc in docs )
        
        # Insert all.
        , (collection, docs, cb) ->
            EE.emit 'log', 'Insert into database'
            collection.insert docs, { 'safe': true }, (err, docs) -> if err then cb(err) else cb(null)

        # Callback or die.
        ], (err) ->
            if err
                try
                    err = JSON.parse(err)
                    console.log err.error.message or err.message or err
                catch err
                    console.log err
                process.exit()
            else
                if done and typeof(done) is 'function' then done()
                else process.exit()

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
    # Grab the directory path.
    dir = path.split('/').reverse()[1...].reverse().join('/')

    # Create the directory if it does not exist yet.
    wrench.mkdirSyncRecursive dir, 0o0777
    
    # Write the file.
    id = fs.openSync path, mode, 0o0666
    fs.writeSync id, text, null, "utf8"

# Connect to a MongoDB database.
connect = (uri, collection, cb) ->
    EE.emit 'log', 'Connect to MongoDB'

    # Connect to MongoDB.
    mongodb.Db.connect uri, (err, connection) ->
        if err then cb err
        else    
            # Get the collection.
            connection.collection collection, (err, coll) ->
                if err then cb err
                else cb null, coll