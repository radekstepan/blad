"use strict";

let connect = require('connect');
let compression = require('compression');
let http = require('http');
let stat = require('serve-static');
let cons = require('consolidate');
let fs = require('fs');
let _ = require('lodash');
let fm = require('front-matter');
let Remarkable = require('remarkable');
let glob = require('glob');
let dir = require('node-dir');
let as = require('async');
let Lru = require('lru-cache');

let md = new Remarkable();

// 10s cache.
let cache = new Lru({ 'max': +Infinity, 'maxAge': 1e3 * 10 });

// Require helper functions.
let helpers = {};
for (let fn of glob.sync("site/helpers/**/*.js")) {
  helpers[fn.replace('site/helpers/', '')] = require('./' + fn);
}

// Load all content.
let content = {};
dir.readFiles('site/content', {
  'match': /.md$/,
}, (err, data, name, next) => {
  if (err) throw err;
  // Parse content.
  let obj = fm(data);
  // Rename.
  obj.data = obj.attributes;
  delete obj.attributes;
  // Supply helpers.
  obj.data.helpers = _.mapValues(obj.data.helpers, (val) => helpers[val]);
  // Save.
  content[name.replace(/^site\/content\/|\.md$/g, '')] = obj;

  next();
}, (err, files) => {
  if (err) throw err;
});

var app = connect();

app.use(compression());
app.use('/public', stat('public', { 'index': false, 'fallthrough': false }));

app.use((req, res) => {
  // Remove leading, trailing slash.
  let path = req.url.replace(/^\/|\/$/g, '');

  let obj;
  if (path in content) {
    obj = content[path];
  // Try folder index approach.
  } else if ((path = `${path}/index`) in content) {
    obj = content[path];
  }

  // TODO: 404.
  if (!obj) return res.end();

  // Run through async helpers.
  as.forEachOf(obj.data.helpers, (fn, key, cb) => {
    let done = (err) => {
      obj.data[key] = cache.get(k);
      cb(err);
    };

    // Do we have the data cached?
    let k = `${path}::${key}`;
    if (cache.has(k)) return done(null);

    // Run the helper and cache the data.
    fn.call(null, obj.data, (err, res) => {
      cache.set(k, res);
      cb(err);
    });
  }, (err) => {
    // TODO: 500.

    // Render the template with the data.
    cons.swig(`site/layouts/${obj.data.template}`, _.extend(obj.data, {
      'contents': md.render(obj.body)
    }), (err, html) => {
      res.writeHead(200, { "Content-Type": "text/html" });
      res.write(html);
      res.end();
    });
  });
});

http.createServer(app).listen(process.env.PORT);
