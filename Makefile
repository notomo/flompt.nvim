test:
	vusted --shuffle -v
.PHONY: test

doc:
	nvim --headless -i NONE +"lua dofile('./spec/doc.lua')" +"quitall!"
	cat ./doc/flompt.nvim.txt
.PHONY: doc
