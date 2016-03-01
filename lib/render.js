"use strict";

let cons = require('consolidate');
let swig = require('swig');
let Remarkable = require('remarkable');
let _ = require('lodash');

let filters = require('./filters.js');
let markdown = require('./markdown.js');

// Expose all filters.
_.each(filters, (v, k) => swig.setFilter(k, v));
cons.requires.swig = swig;

let md = new Remarkable();

// Render the template with the data.
module.exports = (template, obj, cb) => {
  cons.swig(template, markdown(obj), cb);
};
