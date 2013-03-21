#!/usr/bin/env node
var config = {
    "mongodb": "mongodb://localhost:27017/documents",
    "browserid": {
        "provider": "https://browserid.org/verify",
        "salt":     "Q?RAf!CAkus?ejuCruKu",
        "users": [
            "radek.stepan@gmail.com"
        ]
    },
    "middleware": [
        "baddies"
    ]
};

require('../../build/server/app.js').start(config, __dirname + '/');