# NOTE: installed sogno expects prompts/ and launchd/ next to the binary or run from a repo checkout; share/ layout support is a TODO

PREFIX ?= /usr/local

install:
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 0755 sogno $(DESTDIR)$(PREFIX)/bin/sogno
	install -d $(DESTDIR)$(PREFIX)/share/sogno/prompts $(DESTDIR)$(PREFIX)/share/sogno/launchd
	install -m 0644 prompts/*.md $(DESTDIR)$(PREFIX)/share/sogno/prompts/
	install -m 0644 launchd/*.tmpl $(DESTDIR)$(PREFIX)/share/sogno/launchd/

test:
	bash -n sogno
	sh test/check-advise.sh

.PHONY: install test
