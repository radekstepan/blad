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
  app.use('/public', stat(`${opts.source}/public`, { 'index': false }));
  // Route content.
  app.use((req, res) => {
    let error = (code) => {
      res.writeHead(code);
      res.end();
    };

    // 404 on public content.
    if (/^\/public/.test(req.url)) return error(404);

    // Route a page.
    route(docs, cache, req.url, (err, obj) => {
      if (err) return error(err);
      // No content.
      if (!obj) {
        res.writeHead(204);
        return res.end();
      }
      // Render.
      render(`${opts.source}/layouts/${obj.data.template}`, obj, (err, html) => {
        if (err) return error(500);
        // Write head and the html.
        res.writeHead(obj.data.url == '/404' ? 404 : 200, { "Content-Type": "text/html" });
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
