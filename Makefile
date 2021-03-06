VERSION = $(shell grep -oE "[0-9]+\.[0-9]+\.[0-9]+" bin/autojump)
TAGNAME = release-v$(VERSION)

.PHONY: clean docs install uninstall pre-commit lint tar test

install:
	./install.py

uninstall:
	./uninstall.py

docs:
	pandoc -s -w man docs/manpage_header.md docs/header.md docs/body.md -o docs/autojump.1
	pandoc -s -w markdown docs/header.md docs/install.md docs/body.md -o README.md

.PHONY: lint
lint: pre-commit
	@tox -e pre-commit -- run --all-files

pre-commit:
	@tox -e pre-commit -- install -f --install-hooks

release: docs
	# Check for tag existence
	# git describe release-$(VERSION) 2>&1 >/dev/null || exit 1

	# Modify autojump with version
	./tools/git-version.sh $(TAGNAME)

	# Commit the version change
	git commit -m "version numbering" ./bin/autojump

	# Create tag
	git tag -a $(TAGNAME)

	# Create tagged archive
	git archive --format=tar --prefix autojump_v$(VERSION)/ $(TAGNAME) | gzip > autojump_v$(VERSION).tar.gz
	sha1sum autojump_v$(VERSION).tar.gz

tar:
	# Create tagged archive
	git archive --format=tar --prefix autojump_v$(VERSION)/ $(TAGNAME) | gzip > autojump_v$(VERSION).tar.gz
	sha1sum autojump_v$(VERSION).tar.gz

test: pre-commit
	@tox

test-xfail: pre-commit
	@tox -- --runxfail

test-fast: pre-commit
	@tox -e py27

clean:
	@find . -type f -iname '*.py[co]' -delete
	@find . -type d -iname '__pycache__' -delete
	@rm -fr .tox
