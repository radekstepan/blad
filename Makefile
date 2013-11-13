REPORTER = spec

# Run Mocha test suite.
test:
	./node_modules/.bin/mocha --compilers coffee:coffee-script --reporter $(REPORTER) --bail

.PHONY: test