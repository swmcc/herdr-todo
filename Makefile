.PHONY: link unlink lint check

# Link this checkout into herdr, so edits take effect next time the popup opens.
link:
	herdr plugin link "$(CURDIR)"

unlink:
	herdr plugin unlink swmcc.todo

lint:
	shellcheck bin/*

check: lint
