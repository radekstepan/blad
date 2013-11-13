class DocumentListView extends Chaplin.View

    tagName: 'li'

    getTemplateFunction: -> require '../templates/document_row'

module.exports = DocumentListView