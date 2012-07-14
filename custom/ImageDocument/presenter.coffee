class ImageDocument extends Blað.Type

    # Render the image.
    render: -> "<img src='#{@image}' />"

Blað.types.ImageDocument = ImageDocument