module.exports = (grunt) ->
    grunt.initConfig
        pkg: grunt.file.readJSON("package.json")
        
        apps_c:
            commonjs:
                src: [ 'client/src/**/*.{coffee,js,eco}' ]
                dest: 'build/app.js'
                options:
                    main: 'client/src/app.coffee'
                    name: 'blad'

        stylus:
            compile:
                options:
                    paths: [ 'client/src/app.styl' ]
                files:
                    'build/app.css': 'client/src/app.styl'
        
        concat:
            scripts:
                src: [
                    # Our app with CommonJS requirerer (needed by Chaplin).
                    'client/build/app.js'
                    # Vendor dependencies.
                    'client/vendor/jquery/jquery.js'
                    'client/vendor/underscore/underscore.js'
                    'client/vendor/backbone/backbone.js'
                    'client/vendor/chaplin/chaplin.js'

                    'client/vendor/FileSaver/FileSaver.js'
                    'client/vendor/browserid/index.js'
                    'client/vendor/kronic/index.js'
                ]
                dest: 'build/app.bundle.js'
                options:
                    separator: ';' # we will minify...

            styles:
                src: [
                    # Vendor dependencies.
                    'client/vendor/foundation3/index.css'
                    # Our style.
                    'build/app.css'
                ]
                dest: 'build/app.bundle.css'

    grunt.loadNpmTasks('grunt-apps-c')
    grunt.loadNpmTasks('grunt-contrib-stylus')
    grunt.loadNpmTasks('grunt-contrib-concat')

    grunt.registerTask('default', [
        'apps_c'
        'stylus'
        'concat'
    ])