"use strict";

let _ = require('lodash');

// Returns top level documents.
let isMenu = (url) => /^\/([^/|\s]*)$/.test(url);

// Relations between documents.
module.exports = (docs, cb) => {
  let menu = [];

  _.each(docs, (doc, key) => {
    if (isMenu(key)) menu.push(doc.data);
    // By ref.
    doc.data.rel = { menu };
  });

  cb(null, docs);
};
