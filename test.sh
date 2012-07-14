#!/usr/bin/env bash
clear
NODE_ENV=test ./node_modules/mocha/bin/mocha --compilers coffee:coffee-script --ui bdd --reporter spec