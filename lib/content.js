"use strict";

let dir = require('node-dir');
let _ = require('lodash');
let fm = require('front-matter');

// Load all content.
module.exports = (opts, helpers, cb) => {
  let docs = {};
  dir.readFiles(`${opts.source}/content`, {
    'match': /.md$/,
  }, (err, data, name, next) => {
    if (err) return cb(err);
    // Get the name.
    name = name.replace(/^(.*)content\/|\/?(index)?\.md$/g, '')
    // Parse content.
    let obj;
    try {
      obj = fm(data);
    } catch(err) {
      return cb(err);
    }
    // Rename.
    obj.data = obj.attributes;
    delete obj.attributes;
    // Supply helpers.
    obj.data.helpers = _.mapValues(obj.data.helpers, (val) => helpers[val]);
    // Get the URL.
    obj.data.url = `/${name}`;
    // Save.
    docs[obj.data.url] = obj;
    next();
  }, (err, files) => {
    cb(err, docs);
  });
};
