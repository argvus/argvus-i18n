PREFIX ?= /usr
DESTDIR ?=
CARGO ?= cargo

.PHONY: build test validate install-core install-locales install

build:
	$(CARGO) build --release --locked

test:
	$(CARGO) test --locked

validate:
	ARGVUS_I18N_DIR="$(CURDIR)/locales" $(CARGO) run --release --locked -- validate

install-core: build
	install -Dm755 target/release/argvus-i18n "$(DESTDIR)$(PREFIX)/bin/argvus-i18n"
	install -Dm644 src/usr/share/argvus/lib/i18n.sh "$(DESTDIR)$(PREFIX)/share/argvus/lib/i18n.sh"
	install -Dm644 src/usr/share/argvus/qml/argvus-i18n/I18n.qml "$(DESTDIR)$(PREFIX)/share/argvus/qml/argvus-i18n/I18n.qml"
	install -Dm644 src/usr/share/argvus/qml/argvus-i18n/qmldir "$(DESTDIR)$(PREFIX)/share/argvus/qml/argvus-i18n/qmldir"
	install -Dm644 docs/i18n.md "$(DESTDIR)$(PREFIX)/share/doc/argvus-i18n/i18n.md"
	install -Dm644 LICENSE "$(DESTDIR)$(PREFIX)/share/licenses/argvus-i18n/LICENSE"

install-locales:
	install -dm755 "$(DESTDIR)$(PREFIX)/share/argvus/i18n"
	cp -R --no-preserve=ownership locales/. "$(DESTDIR)$(PREFIX)/share/argvus/i18n/"

install: install-core install-locales
