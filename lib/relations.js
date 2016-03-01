"use strict";

let _ = require('lodash');

let markdown = require('./markdown.js')

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
exports.siblings = (docs, url, ignore) => {
  return exports.children(docs, up(url), 1, [ url, ignore ]);
};

// Returns children of a certain depth.
exports.children = (docs, url, depth, ignore) => {
  depth = Math.max(1, parseInt(depth || 1, 10)) + le(url);

  url = be(url);

  // Make sure ignore list is a list.
  if (ignore) {
    if (_.isString(ignore)) {
      ignore = [ ignore ];
    } else {
      // Make sure it doesn't have any falsey values.
      ignore = _.compact(ignore);
    }
  } else {
    ignore = [];
  }

  return _(docs)
  .filter((doc, key) => {
    return _.indexOf(ignore, key) == -1 && url.test(key) && le(key) == depth;
  })
  .map(markdown)
  .value();
};

// Returns the (first existing) parent document.
exports.parent = (docs, url) => {
  do {
    url = up(url);
    if (url in docs) return markdown(docs[url]);
  } while (le(url) != 0);
};

// Is `b` the same as `a` or one of its descendants?
exports.isFamily = (docs, a, b) => {
  return a == b || exports.isChild(docs, a, b);
};

// Is `b` one of the descendants of `a`.
exports.isChild = (docs, a, b) => {
  return new RegExp(`^${a}\/`).test(b);
};
