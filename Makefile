REPORTER = spec

# Run an example site.
example: build
	node ./test/example_site/start.js

# Run Mocha test suite.
test: build
	@NODE_ENV=test ./node_modules/.bin/mocha --compilers coffee:coffee-script --reporter $(REPORTER) --bail

# Run Mocha test suite in jscoverage mode.
test-cov: prep-coverage
	@KONTU_COV=1 $(MAKE) test REPORTER=html-cov > coverage.html

# Compile CoffeeScript source and enhance it with jscoverage.
prep-coverage: build node-coverage

# Compile CoffeeScript source.
build:
	@rm -fr build/
	@./node_modules/.bin/coffee -c -o build/server src/server

# Enhance compiled source with jscoverage.
node-coverage:
	rm -fr build-cov/
	@jscoverage build build-cov --encoding=UTF-8

.PHONY: test build