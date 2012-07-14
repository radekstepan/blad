#!/usr/bin/env bash
set -e
clear
./node_modules/.bin/cake compile
node server.js