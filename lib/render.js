"use strict";

let cons = require('consolidate');
let Remarkable = require('remarkable');
let _ = require('lodash');

let md = new Remarkable();

// Render the template with the data.
module.exports = (template, obj, cb) => {
  cons.swig(template, _.extend(obj.data, {
    'contents': md.render(obj.body)
  }), cb);
};
