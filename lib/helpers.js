"use strict";

let dir = require('node-dir');
let _ = require('lodash');
let path = require('path');
let fs = require('fs');

// Make sure we can load CoffeeScript files.
require('coffee-script/register');

// Require helper functions.
module.exports = (opts, cb) => {
  let d = `${opts.source}/helpers`;

  // Has any helpers at all?
  fs.stat(d, (err, stats) => {
    if (err) return cb(null, {});
    let obj = {};

    dir.files(d, (err, files) => {
      console.log(err);
      if (err) return cb(err);

      _.each(files, (file) => {
        obj[file.replace(/^(.*)helpers\//, '')] = require(path.resolve(file));
      });

      cb(null, obj);
    });
  });
};
