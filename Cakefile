#!/usr/bin/env coffee

fs  = require 'fs'
cs  = require 'coffee-script'
eco = require 'eco'

task "compile", "compile server and client code with custom document types", ->
    server = (done) ->
        # Core server code.
        codez = [ fs.readFileSync('./server.coffee', "utf-8") ]

        # Custom presenters.
        walk './custom', (files) ->
            for file in files when file.match /presenter\.coffee/
                console.log file
                codez.push fs.readFileSync(file, "utf-8")

            # Write it all.
            write './server.js', cs.compile codez.join("\n")

            done()

    client = (done) ->
        # Client side code.
        walk './chaplin', (files) ->
            for file in files
                console.log file
                if file.match /\.eco/
                    name = file.split('/').pop()
                    js = uglify "JST['#{name}'] = " + eco.precompile fs.readFileSync file, "utf-8"
                    write file.replace('./chaplin', './public/js').replace('.eco', '.js'), js
                else if file.match /\.coffee/
                    js = cs.compile fs.readFileSync(file, "utf-8"), 'bare': 'on'
                    write file.replace('./chaplin', './public/js').replace('.coffee', '.js'), js

            done()
    
    forms = (done) ->
        # Custom document forms.
        walk './custom', (files) ->
            tml = []
            for file in files when file.match /form\.eco/
                js = eco.precompile fs.readFileSync file, "utf-8"
                p = file.split('/') ; name = p[p.length-2]
                tml.push uglify "JST['form_#{name}.eco'] = #{js}"
            write './public/js/templates/document_forms.js', tml.join("\n")
            done()

    queue [ server, client, forms ], (out) ->
        console.log 'All is done.'

# -------------------------------------------------------------------


# A serial queue that waits until all resources have returned and then calls back.
queue = (calls, cb) ->
    make = (index) ->
      ->
        counter--
        all[index] = arguments
        cb(all) unless counter

    # How many do we have?
    counter = calls.length
    # Store results here.
    all = []

    i = 0
    for call in calls
        call make i++

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

# Write to file.
write = (path, text, mode = "w") ->
    fs.open path, mode, 0o0666, (err, id) ->
        throw err if err
        fs.write id, text, null, "utf8"