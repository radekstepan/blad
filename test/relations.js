"use strict";

let assert = require('chai').assert;
let _ = require('lodash');

let rel = require('../lib/relations.js');

let docs = {
  '/': { 'data': '/' },
  '/dogs': { 'data': '/dogs' },
  '/dogs/jim': { 'data': '/dogs/jim' },
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

  'relations - children': (done) => {
    assert.deepEqual(rel.children(docs, '/cats', 1), [ '/cats/tim', '/cats/liz' ]);
    assert.deepEqual(rel.children(docs, '/pets', 2), [ '/pets/pip/8' ]);
    done();
  },

  'relations - siblings': (done) => {
    assert.deepEqual(rel.siblings(docs, '/cats/tim'), [ '/cats/liz' ]);
    done();
  },

  'relations - parent': (done) => {
    assert.deepEqual(rel.parent(docs, '/dogs/jim'), '/dogs');
    assert.deepEqual(rel.parent(docs, '/pets/pip/8'), '/');
    assert.deepEqual(rel.parent(docs, '/'), '/');
    done();
  },

  'relations - isChild': (done) => {
    assert.ok(rel.isChild(null, '/a/b', '/a/b/c'));
    assert.notOk(rel.isChild(null, '/a/b', '/a/ble/c'));
    assert.notOk(rel.isChild(null, '/a/b', '/a/b'));
    done();
  }
};
