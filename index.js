"use strict";

let args = require('minimist');
let path = require('path');
let _ = require('lodash');
let as = require('async');

let helpers = require('./lib/helpers.js');
let content = require('./lib/content.js');
let server = require('./lib/server.js');

module.exports = (opts) => {
  opts = args(opts, {
    'alias': {
      'p': 'port',
      's': 'source',
      'c': 'cache'
    },
    'default': {
      // Example site.
      's': './example/',
      // Max cache age of 1 day.
      'c': 60 * 24
    }
  });

  opts.source = path.resolve(opts.source);

  as.waterfall([
    _.partial(helpers, opts),
    _.partial(content, opts),
    _.partial(server, opts),
  ], (err) => {
    throw err;
  });
};
