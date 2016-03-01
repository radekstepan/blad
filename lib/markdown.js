"use strict";

let _ = require('lodash');
let Remarkable = require('remarkable');

let md = new Remarkable();

// Merge markdown content in.
module.exports = (obj) => {
  if (!(obj.body)) return obj.data;

  return _.extend(obj.data, {
    'contents': md.render(obj.body)
  });
};
