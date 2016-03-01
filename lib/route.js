"use strict";

let as = require('async');
let _ = require('lodash');

let rel = require('./relations.js');

module.exports = (docs, cache, url, cb) => {
  // Remove trailing slash.
  let path = url.replace(/^(.+)\/$/g, '$1');

  if (!(path in docs)) return cb(404);
  let obj = docs[path];

  // No content when the document doesn't have a template.
  if (!obj.data.template) return cb();

  // The helpers context.
  let ctx = {
    // Partially apply all docs for relations.
    'rel': _.mapValues(rel, (fn) => _.partial(fn, docs))
  };

  // Exec async helpers.
  as.forEachOf(obj.data.helpers, (fn, key, cb) => {
    // Actually a function?
    if (!_.isFunction(fn)) return cb(`${key} is not a helper function`);

    let k = `${path}::${key}`;

    // Copy cache data to the response.
    let done = (err) => {
      obj.data[key] = cache.get(k);
      cb(err);
    };

    // Do we have the data cached?
    if (cache.has(k)) return done(null);

    // Run the helper in relations context and cache the result.
    fn.call(ctx, obj.data, (err, res) => {
      cache.set(k, res);
      done(err);
    });
  }, (err) => {
    // Send for rendering.
    cb(err, obj);
  });
};
