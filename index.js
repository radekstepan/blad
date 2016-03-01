"use strict";

let args = require('minimist');
let path = require('path');
let _ = require('lodash');
let as = require('async');

let helpers = require('./lib/helpers.js');
let content = require('./lib/content.js');
let server = require('./lib/server.js');
let build = require('./lib/build.js');

module.exports = (opts, cb) => {
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

  // Callback?
  if (!_.isFunction(cb)) cb = _.identity;

  as.waterfall([
    // Require helper menthods.
    _.partial(helpers, opts),
    // Load all content.
    _.partial(content, opts),
    // Build all pages to check for errors.
    _.partial(build, opts),
    // Start server.
    _.partial(server, opts),
  ], cb);
};
