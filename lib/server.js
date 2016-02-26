"use strict";

let connect = require('connect');
let compression = require('compression');
let http = require('http');
let stat = require('serve-static');

let render = require('./render.js');

// Start the server.
module.exports = (opts, files, cb) => {
  let app = connect();

  // Compress output.
  app.use(compression());
  // Serve static content.
  app.use('/public', stat(`${opts.SITE}public`, { 'index': false, 'fallthrough': false }));
  // Route content.
  app.use((req, res) => {
    render(opts, files, req.url, (err, html) => {
      // TODO: handle errors.
      if (err) return res.end(500);

      res.writeHead(200, { "Content-Type": "text/html" });
      res.write(html);
      res.end();
    });
  });

  // Start.
  // TODO: handle server started callback.
  http.createServer(app).listen(opts.PORT);
};
