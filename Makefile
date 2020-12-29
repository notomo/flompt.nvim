test:
	vusted ./test --shuffle -v
.PHONY: test

doc:
	nvim --headless -i NONE +"lua dofile('./test/doc.lua')" +"quitall!"
	cat ./doc/flompt.nvim.txt
.PHONY: doc
