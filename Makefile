REPORTER = spec

# Run Mocha test suite.
test: cs-compile
	@NODE_ENV=test ./node_modules/.bin/mocha --compilers coffee:coffee-script --reporter $(REPORTER) --bail

# Run Mocha test suite in jscoverage mode.
test-cov: prep-coverage
	@KONTU_COV=1 $(MAKE) test REPORTER=html-cov > coverage.html

# Compile CoffeeScript source and enhance it with jscoverage.
prep-coverage: cs-compile node-coverage

# Compile CoffeeScript source.
cs-compile:
	@./node_modules/.bin/coffee -c -o lib/ src/

# Enhance compiled source with jscoverage.
node-coverage:
	rm -fr lib-cov/
	@jscoverage lib lib-cov

.PHONY: test