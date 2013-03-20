#!/usr/bin/env node
switch (process.env.NODE_ENV) {
    case 'test':
        module.exports = (process.env.KONTU_COV) ? require('./lib-cov/blad.js') : require('./lib/blad.js');
        break;
    default:
        module.exports = require('../lib/blad.js');
}