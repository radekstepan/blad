class ImageDocument extends Blað.Type

    # Render the image.
    render: (done) -> done 'image': @image

Blað.types.ImageDocument = ImageDocument