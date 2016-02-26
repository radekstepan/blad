"use strict";

let as = require('async');
let _ = require('lodash');

module.exports = (docs, cache, url, cb) => {
  // Remove trailing slash.
  let path = url.replace(/^(.+)\/$/g, '$1');

  if (!(path in docs)) return cb(404);
  let obj = docs[path];

  // Exec async helpers.
  as.forEachOf(obj.data.helpers, (fn, key, cb) => {
    let k = `${path}::${key}`;

    // Copy cache data to the response.
    let done = (err) => {
      obj.data[key] = cache.get(k);
      cb(err);
    };

    // Do we have the data cached?
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
