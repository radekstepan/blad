#!/usr/bin/env node
switch (process.env.NODE_ENV) {
    case 'test':
        module.exports = (process.env.KONTU_COV) ? require('./build-cov/server/app.js') : require('./build/server/app.js');
        break;
    default:
        module.exports = require('./build/server/app.js');
}