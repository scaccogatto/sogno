# `make install` puts the script in $(PREFIX)/bin and its read-only data
# (prompts, scheduler templates) in $(PREFIX)/share/sogno, which sogno finds
# relative to itself. Config goes in ~/.config/sogno/sogno.conf.

PREFIX ?= /usr/local

install:
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 0755 sogno $(DESTDIR)$(PREFIX)/bin/sogno
	install -d $(DESTDIR)$(PREFIX)/share/sogno/prompts $(DESTDIR)$(PREFIX)/share/sogno/launchd \
	           $(DESTDIR)$(PREFIX)/share/sogno/systemd $(DESTDIR)$(PREFIX)/share/sogno/windows
	install -m 0644 prompts/*.md $(DESTDIR)$(PREFIX)/share/sogno/prompts/
	install -m 0644 launchd/*.tmpl $(DESTDIR)$(PREFIX)/share/sogno/launchd/
	install -m 0644 systemd/*.tmpl $(DESTDIR)$(PREFIX)/share/sogno/systemd/
	install -m 0644 windows/*.tmpl $(DESTDIR)$(PREFIX)/share/sogno/windows/
	install -m 0644 sogno.conf.example $(DESTDIR)$(PREFIX)/share/sogno/

test:
	bash -n sogno
	bash test/check-helpers.sh
	bash test/check-dream.sh

.PHONY: install test
