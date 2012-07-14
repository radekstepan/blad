#!/usr/bin/env bash
set -e
clear
NODE_ENV=test ./node_modules/mocha/bin/mocha --compilers coffee:coffee-script --ui bdd --reporter spec