"use strict";

let connect = require('connect');
let compression = require('compression');
let http = require('http');
let stat = require('serve-static');

let route = require('./route.js');
let render = require('./render.js');
let pkg = require('../package.json');

// Start the server.
module.exports = (opts, docs, cache, cb) => {
  let app = connect();

  // Compress output.
  app.use(compression());
  // Serve static content.
  app.use('/public', stat(`${opts.source}/public`, { 'index': false, 'fallthrough': false }));
  // Route content.
  app.use((req, res) => {
    route(docs, cache, req.url, (err, obj) => {
      // TODO: handle errors.
      if (err) return res.end(500);
      // No content.
      if (!obj) {
        res.writeHead(204);
        return res.end();
      }
      // Render.
      render(`${opts.source}/layouts/${obj.data.template}`, obj, (err, html) => {
        // TODO: handle errors.
        if (err) return res.end(500);
        // Write head and the html.
        res.writeHead(200, { "Content-Type": "text/html" });
        res.write(html);
        res.end();
      });
    });
  });

  // Start.
  let listener = http.createServer(app).listen(opts.port, (err) => {
    if (!err) console.log(`${pkg.name}/${pkg.version} started on port ${listener.address().port}`);
    cb(err);
  });
};
