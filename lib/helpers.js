"use strict";

let dir = require('node-dir');
let _ = require('lodash');
let path = require('path');

// Make sure we can load CoffeeScript files.
require('coffee-script/register');

// Require helper functions.
module.exports = (opts, cb) => {
  let obj = {};

  dir.files(`${opts.source}/helpers`, (err, files) => {
    if (err) return cb(err);

    _.each(files, (file) => {
      obj[file.replace(/^(.*)helpers\//, '')] = require(path.resolve(file));
    });

    cb(null, obj);
  });
};
