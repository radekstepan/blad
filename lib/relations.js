"use strict";

let _ = require('lodash');

// One level up.
let up = (path) => le(path) == 1 ? '/' : path.replace(/\/[^\/]+$/, '');
// Depth.
let le = (path) => path == '/' ? 0 : path.match(/\//g).length;
// Begins with.
let be = (path) => new RegExp(`^${path}.+`);

// Returns top level documents.
exports.menu = (docs) => {
  return exports.children(docs, '/', 1);
};

// Returns sibling documents.
exports.siblings = (docs, url) => {
  return exports.children(docs, up(url), 1, url);
};

// Returns children of a certain depth.
exports.children = (docs, url, depth, ignore) => {
  depth = Math.max(1, parseInt(depth, 10)) + le(url);

  url = be(url);

  return _(docs)
  .filter((doc, key) => {
    return key != ignore && url.test(key) && le(key) == depth;
  })
  .map('data')
  .value();
};

// Returns the (first existing) parent document.
exports.parent = (docs, url) => {
  do {
    url = up(url);
    if (url in docs) return url;
  } while (le(url) != 0);
}
