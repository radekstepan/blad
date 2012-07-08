#!/usr/bin/env bash
node_modules/.bin/coffee --bare --output public/js/ chaplin/
cp chaplin/templates/*.eco public/js/templates
(cd public/js/templates ; find . -type f \( -iname '*.eco' \) -exec ../../../node_modules/.bin/eco {} -o . -i "JST" \; -exec rm -rf {} \;)