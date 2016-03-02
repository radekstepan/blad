"use strict";

let _ = require('lodash');

// Creates an array of shuffled values, using a version of Fisher-Yates.
exports.shuffle = _.shuffle;

// Returns an array of all elements predicate returns truthy for.
exports.filter = _.filter;

// Splits string by separator.
exports.split = _.split;

// Creates a slice of array from start up to, but not including, end.
exports.slice = _.slice;

// Creates an array of elements, sorted by running each element through iteratee.
exports.sortBy = _.sortBy;
