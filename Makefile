# `make install` puts the script in $(PREFIX)/bin and its read-only data
# (prompts, scheduler templates) in $(PREFIX)/share/sogno, which sogno finds
# relative to itself. Config goes in ~/.config/sogno/sogno.conf.

PREFIX ?= /usr/local
SHARE = $(DESTDIR)$(PREFIX)/share/sogno

install:
	install -d "$(DESTDIR)$(PREFIX)/bin"
	install -m 0755 sogno "$(DESTDIR)$(PREFIX)/bin/sogno"
	install -d "$(SHARE)/prompts" "$(SHARE)/launchd" "$(SHARE)/systemd" "$(SHARE)/windows"
	install -m 0644 prompts/*.md "$(SHARE)/prompts/"
	install -m 0644 launchd/*.tmpl "$(SHARE)/launchd/"
	install -m 0644 systemd/*.tmpl "$(SHARE)/systemd/"
	install -m 0644 windows/*.tmpl "$(SHARE)/windows/"
	install -m 0644 sogno.conf.example "$(SHARE)/"

test:
	bash -n sogno
	bash test/check-helpers.sh
	bash test/check-dream.sh

.PHONY: install test
