"use strict";

let dir = require('node-dir');
let _ = require('lodash');
let fm = require('front-matter');

// Load all content.
module.exports = (opts, helpers, cb) => {
  let res = {};
  let d = `${opts.source}/content`;
  dir.readFiles(d, {
    'match': /.md$/,
  }, (err, data, name, next) => {
    if (err) return cb(err);
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
    // Save.
    res[name.replace(/^(.*)content\/|\.md$/g, '')] = obj;
    next();
  }, (err, files) => {
    cb(err, res);
  });
};
