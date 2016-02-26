"use strict";

let path = require('path');
let _ = require('lodash');
let as = require('async');

let helpers = require('./lib/helpers.js');
let content = require('./lib/content.js');
let server = require('./lib/server.js');

module.exports = (opts) => {
  opts.PATH = path.resolve(opts.PATH);

  as.waterfall([
    _.partial(helpers, opts),
    _.partial(content, opts),
    _.partial(server, opts),
  ], (err) => {
    throw err;
  });
};
