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
    'admin': (whateva..., cb) ->
        EE.emit 'log', 'Compiling Chaplin.js admin client app code'

        # Make a dir for us.
        async.waterfall [ (_cb) ->
            try
                wrench.mkdirSyncRecursive "#{__dirname}/../public/admin", 0o0777
                _cb null
            catch err
                _cb err

        # CSS & vendor JS.
        , async.apply(wrench.copyDirRecursive,
            "#{__dirname}/../../src/admin/assets", "#{__dirname}/../public/admin"
            , { 'forceDelete': yes }
        )
        
        # CoffeeScript & Eco.
        , (_cb) ->
            # Where from/to?
            root = "#{__dirname}/../../src/admin/chaplin"
            target = path.resolve "#{__dirname}/../../build/public/admin/js"

            apply = (file, __cb) ->
                # Eco templates.
                if file.match /\.eco/
                    name = file.split('/').pop()
                    # Read.
                    fs.readFile path.resolve(root + '/' + file), 'utf8', (err, data) ->
                        if err then return __cb err
                        # Eco precompile.
                        js = eco.precompile data
                        # Minify.
                        js = (uglify.minify("JST['#{name}'] = #{js}", 'fromString': true)).code
                        # Write.
                        write (target + '/' + file).replace('.eco', '.js'), js, __cb
                
                # CoffeeScript files.
                else if file.match /\.coffee/
                    # Read.
                    fs.readFile path.resolve(root + '/' + file), 'utf8', (err, data) ->
                        if err then return __cb err
                        # CoffeeScript compile.
                        js = cs.compile data, 'bare': 'on'
                        # Write.
                        write (target + '/' + file).replace('.coffee', '.js'), js, __cb

                # Useless.
                else __cb null

            asyncWalk root, apply, _cb

        ], cb

    # Site's custom document type forms.
    'forms': ({ site_src }) ->
        (whateva..., cb) ->
            EE.emit 'log', 'Compiling custom document type forms'

            # Where from?
            root = path.join site_src, '/src/types'
            # All them templates.
            tml = []
            # Inject a BasicDocument form first.
            tml.push (uglify.minify("JST['form_BasicDocument.eco'] = #{eco.precompile("")}", 'fromString': true)).code

            apply = (file, _cb) ->
                # A form Eco file?
                if file.match /form\.eco/
                    fs.readFile path.resolve(root + '/' + file), 'utf8', (err, data) ->
                        # Get the name of the document form.
                        p = file.split('/') ; name = p[p.length-2]
                        # Eco precompile.
                        js = eco.precompile data
                        # Push on templates stack.
                        tml.push (uglify.minify("JST['form_#{name}.eco'] = #{js}", 'fromString': true)).code
                        _cb null

                else _cb null

            asyncWalk root, apply, (err) ->
                if err then return cb err
                write "#{__dirname}/../public/admin/js/templates/document_forms.js", tml.join("\n"), cb

exports.copy =
    # Copy over site's public files.
    'public': ({ site_src }) ->
        (whateva..., cb) ->
            EE.emit 'log', "Copying site's public files"
            wrench.copyDirRecursive path.join(site_src, '/src/public'), "#{__dirname}/../public/site"
            , { 'forceDelete': yes }, (err) ->
                cb err

    # Copy presenter additions?
    'additions': ({ site_src }) ->
        (whateva..., cb) ->
            source = path.join site_src, '/src/types/additions.coffee'
            target = path.resolve "#{__dirname}/../../build/server/additions.js"

            fs.stat source, (err, stats) ->
                # No additions.
                return cb null if err
                # Not a file.
                return cb null if do stats.isDirectory

                EE.emit 'log', 'Including additions file'

                # Load it.
                fs.readFile source, 'utf-8', (err, data) ->
                    # Ah well.
                    return cb null if err
                    # Compile.
                    try js = cs.compile data, 'bare': 'on'
                    # Write?
                    return cb null unless js
                    fs.writeFile target, js, (err) ->
                        # Silence.
                        cb null

exports.include =
    # Get a list of presenter paths to include in super.
    'presenters': ({ site_src }) ->
        (whateva..., cb) ->
            EE.emit 'log', 'Returning a list of presenter paths'

            # Where from?
            root = path.join site_src, '/src/types'

            # All paths.
            paths = []

            apply = (file, _cb) ->
                if file.match /presenter\.coffee/ then paths.push root + '/' + file
                _cb null

            asyncWalk root, apply, (err) ->
                if err then return cb err
                cb null, paths

exports.db =
    # Export the database into a JSON file.
    'export': (cfg, dir, done) ->
        
        # Try to create folder if not exists.
        async.waterfall [ (cb) ->
            EE.emit 'log', 'Create directory for dump'
            fs.mkdir "#{dir}/dump", (err) -> if err and err.code isnt 'EEXIST' then cb(err) else cb(null)
        
        # Connect to MongoDB.
        , (cb) ->
            connect cfg.mongodb, 'documents', cb

        # Dump the DB.
        , (collection, cb) ->
            EE.emit 'log', 'Dump the database'
            collection.find({}, 'sort': 'url').toArray (err, docs) -> if err then cb(err) else cb(null, docs)
        
        # Open file for writing and write file.
        , (docs, cb) ->
            EE.emit 'log', 'Write file'
            write "#{dir}/dump/data.json", JSON.stringify(docs, null, 4), cb

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
        async.waterfall [ (cb) ->
            connect cfg.mongodb, 'documents', cb

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
                catch e
                    console.log err
                process.exit()
            else
                if done and typeof(done) is 'function' then done()
                else process.exit()

# A recursive directory walk using async applying a fn on each.
asyncWalk = (path, apply, cb) ->
    # If there are no more jobs then continue.
    jobs = 0 ; canExit = false
    exit = -> if jobs is 0 and canExit then cb null

    # Wrench to the rescue.
    wrench.readdirRecursive path, (err, files) ->
        # Crap?
        if err then return cb err
        
        # Are we done?
        unless files
            canExit = true
            exit()
        else
            # Moar jobs.
            jobs++ ; fns = []
            # Do something.
            for file in files then do (file) ->
                fns.push (_cb) -> apply file, _cb

            # Run all of them in parallel.
            async.parallel fns, (err) ->
                if err then cb err
                else
                    # One more thing done.
                    jobs--
                    # Exit?
                    exit()

# Write to file, async.
write = (path, text, cb) ->
    # Grab the directory path.
    dir = path.split('/').reverse()[1...].reverse().join('/')

    # Create the directory if it does not exist yet.
    wrench.mkdirSyncRecursive dir, 0o0777

    # Write the file.
    fs.open path, 'w', 0o0666, (err, id) ->
        if err then cb err
        else fs.write id, text, null, 'utf8', cb

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