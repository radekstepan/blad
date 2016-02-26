"use strict";

let as = require('async');
let _ = require('lodash');

module.exports = (files, cache, url, cb) => {
  // Remove leading, trailing slash.
  let path = (url == '/') ? 'index' : url.replace(/^\/|\/$/g, '');

  let obj;
  if (path in files) {
    obj = files[path];
  // Try folder index approach.
  } else if ((path = `${path}/index`) in files) {
    obj = files[path];
  }

  if (!obj) return cb(404);

  // Exec async helpers.
  as.forEachOf(obj.data.helpers, (fn, key, cb) => {
    let done = (err) => {
      obj.data[key] = cache.get(k);
      cb(err);
    };

    // Do we have the data cached?
    let k = `${path}::${key}`;
    if (cache.has(k)) return done(null);

    // Run the helper and cache the data.
    fn.call(null, obj.data, (err, res) => {
      cache.set(k, res);
      done(err);
    });
  }, (err) => {
    // Send for rendering.
    cb(err, obj);
  });
};
