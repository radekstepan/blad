"use strict";

let _ = require('lodash');
let as = require('async');
let Lru = require('lru-cache');
let clrs = require('colors/safe');

let route = require('./route.js');
let render = require('./render.js');

let log = console.log;

// Build all content to check for errors.
module.exports = (opts, docs, cb) => {
  // Cache with time expiry.
  let cache = new Lru({ 'max': +Infinity, 'maxAge': 1e3 * 60 * opts.cache });

  as.forEachOf(docs, (val, url, cb) => {
    let done = (err) => {
      if (err) {
        log(clrs.red(`Route '${url}' error:`), err);
      }
      cb(err);
    };

    route(docs, cache, url, (err, obj) => {
      // Error or empty documents.
      if (err || !obj) return done(err);
      // Render.
      render(`${opts.source}/layouts/${obj.data.template}`, obj, done);
    });
  }, (err) => {
    return (err) ? null : cb(null, docs, cache);
  });
};
