# Blað
A forms based [node.js](http://nodejs.org/) CMS ala [SilverStripe](http://www.silverstripe.com/), but smaller.

The idea was to create a RESTful CMS API that would be edited using a client side app. On the backend, we use [flatiron](http://flatironjs.org/) and on the frontend [chaplin](https://github.com/chaplinjs/chaplin) that itself wraps [Backbone.js](http://documentcloud.github.com/backbone/).

## Start the service and admin app

We wrap the compilation of user code and core code using `cake` but first, dependencies need to be met.

```bash
$ npm install -d
$ ./server.sh
```

Visit [http://127.0.0.1:1118/admin](http://127.0.0.1:1118/admin).

## Mocha test suite

To run the tests execute the following.

```bash
$ ./test.sh
```

A `test` collection in MongoDB will be created and cleared before each spec run.