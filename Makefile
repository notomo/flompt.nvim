test:
	vusted ./test --shuffle -v
.PHONY: test

doc:
	gevdoc --externals ./doc/examples.vim
.PHONY: doc
