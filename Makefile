test:
	THEMIS_VIM=nvim THEMIS_ARGS="-e -s --headless" themis

doc:
	gevdoc --externals ./doc/examples.vim

.PHONY: test
.PHONY: doc
