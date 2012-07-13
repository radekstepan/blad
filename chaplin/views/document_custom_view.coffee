define [
    'chaplin'
    'templates/type_BasicDocument'
    'templates/type_ImageDocument'
    'templates/type_MarkdownDocument'
], (Chaplin) ->

    # A view for the custom document fields
    class DocumentCustomView extends Chaplin.View

        # Automatically append to the DOM on render.
        container: '#custom'

        # Clear existing.
        containerMethod: 'html'

        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST['type_' + @model.get('type')]

        initialize: (params) -> @model = params.model

        afterRender: ->
            super
            # Any image uploads?
            if @model.get('type') is 'ImageDocument'
                @delegate 'change', '.image', @loadImageHandler

        loadImageHandler: (e) ->
            target = $(e.target)[0]

            return if target.files.length is 0

            oFile = target.files[0]

            rFilter = /^(?:image\/bmp|image\/cis\-cod|image\/gif|image\/ief|image\/jpeg|image\/jpeg|image\/jpeg|image\/pipeg|image\/png|image\/svg\+xml|image\/tiff|image\/x\-cmu\-raster|image\/x\-cmx|image\/x\-icon|image\/x\-portable\-anymap|image\/x\-portable\-bitmap|image\/x\-portable\-graymap|image\/x\-portable\-pixmap|image\/x\-rgb|image\/x\-xbitmap|image\/x\-xpixmap|image\/x\-xwindowdump)$/i

            unless rFilter.test(oFile.type)
                return console.log "You must select a valid image file!"
            
            oFReader = new FileReader()

            oFReader.readAsDataURL oFile

            oFReader.onload = (oFREvent) => $(@el).find('.preview').attr('src', oFREvent.target.result).show()