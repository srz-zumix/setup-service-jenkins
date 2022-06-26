build: dist/index.js dist/cleanup.js

dist/index.js: src/index.js Makefile
	ncc build src/index.js

dist/cleanup.js: src/cleanup.js Makefile
	ncc build $< -o tmp
	mv tmp/index.js $@
