"use strict";

let _ = require('lodash');

// Returns top level documents.
exports.menu = (docs) => {
  return exports.children(docs, '/', 1);
};

// Returns children of a certain depth.
exports.children = (docs, url, depth) => {
  depth = Math.max(1, parseInt(depth, 10)) + (url == '/' ? 0 : url.match(/\//g).length);

  url = new RegExp(`^${url}.+`);

  return _(docs)
  .filter((doc, key) => {
    return url.test(key) && key.match(/\//g).length == depth;
  })
  .map('data')
  .value();
};
