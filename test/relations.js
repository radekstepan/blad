"use strict";

let assert = require('chai').assert;

let rel = require('../lib/relations.js');

let docs = {
  '/': { 'data': '/' },
  '/dogs': { 'data': '/dogs' },
  '/dogs/tim': { 'data': '/dogs/tim' },
  '/cats': { 'data': '/cats' },
  '/cats/tim': { 'data': '/cats/tim' },
  '/cats/liz': { 'data': '/cats/liz' },
  '/pets/pip/8': { 'data': '/pets/pip/8' }
};

module.exports = {
  'relations - menu': (done) => {
    assert.deepEqual(rel.menu(docs), [ '/dogs', '/cats' ]);
    done();
  },

  'relations - children(1)': (done) => {
    assert.deepEqual(rel.children(docs, '/cats', 1), [ '/cats/tim', '/cats/liz' ]);
    done();
  },

  'relations - children(2)': (done) => {
    assert.deepEqual(rel.children(docs, '/pets', 2), [ '/pets/pip/8' ]);
    done();
  }
};
