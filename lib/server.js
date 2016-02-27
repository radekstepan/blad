"use strict";

let connect = require('connect');
let compression = require('compression');
let http = require('http');
let stat = require('serve-static');
let Lru = require('lru-cache');

let route = require('./route.js');
let render = require('./render.js');

// Start the server.
module.exports = (opts, docs, cb) => {
  let app = connect();

  // Cache with time expiry.
  let cache = new Lru({ 'max': +Infinity, 'maxAge': 1e3 * 60 * opts.cache });

  // Compress output.
  app.use(compression());
  // Serve static content.
  app.use('/public', stat(`${opts.source}/public`, { 'index': false, 'fallthrough': false }));
  // Route content.
  app.use((req, res) => {
    route(docs, cache, req.url, (err, obj) => {
      // TODO: handle errors.
      if (err) return res.end(500);
      // Render.
      render(`${opts.source}/layouts/${obj.data.template}`, obj, (err, html) => {
        // TODO: handle errors.
        if (err) return res.end(500);
        // Write head and the html.
        // TOD0: handle 304.
        res.writeHead(200, { "Content-Type": "text/html" });
        res.write(html);
        res.end();
      });
    });
  });

  // Start.
  // TODO: handle server started callback.
  http.createServer(app).listen(opts.port);
};
