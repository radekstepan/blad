#!/usr/bin/env bash
export PATH=$PATH:node_modules/mocha/bin/
mocha --compilers coffee:coffee-script --ui bdd --reporter spec