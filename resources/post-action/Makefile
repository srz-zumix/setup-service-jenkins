build: dist/main/index.js dist/post/index.js

dist/main/index.js: src/index.js Makefile package-lock.json
	npx ncc build $< -o dist/main

dist/post/index.js: src/cleanup.js Makefile package-lock.json
	npx ncc build $< -o dist/post

package-lock.json: package.json
	npm install
