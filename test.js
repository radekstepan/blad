"use strict";

let _ = require('lodash');

let object = {};

_.set(object, '[0].children[0]', { 'url': '/A' });
_.set(object, '[0].children[1]', { 'url': '/B' });

console.log(JSON.stringify(object, null, 2));
