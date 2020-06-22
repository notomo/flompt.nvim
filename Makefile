test:
	vusted ./test --shuffle -v

doc:
	gevdoc --externals ./doc/examples.vim

.PHONY: test
.PHONY: doc
