"use strict";

let dir = require('node-dir');
let _ = require('lodash');
let fm = require('front-matter');
let clrs = require('colors/safe');

let rel = require('./relations.js');

// Load all content.
module.exports = (opts, helpers, cb) => {
  let docs = {};
  dir.readFiles(`${opts.source}/content`, {
    'match': /.md$/,
  }, (err, data, name, next) => {
    if (err) throw err;
    // Get the name.
    name = name.replace(/^(.*)content\/|\/?(index)?\.md$/g, '')
    // Parse content (throws).
    let obj;
    try {
      obj = fm(data);
    } catch(err) {
      console.log(clrs.red(`Route '/${name}' error:`))
      throw err;
    }
    // Rename.
    obj.data = obj.attributes;
    delete obj.attributes;
    // Supply helpers.
    obj.data.helpers = _.mapValues(obj.data.helpers, (val) => helpers[val]);
    // Get the URL.
    obj.data.url = `/${name}`;
    // Add the relations.
    obj.data.rel = _.mapValues(rel, (fn) => _.partial(fn, docs));

    // Save.
    docs[obj.data.url] = obj;
    next();
  }, (err, files) => {
    cb(err, docs);
  });
};
