PREFIX ?= /usr
DESTDIR ?=
INSTALL ?= install
RM ?= rm -f
CARGO ?= cargo
QML_IMPORT_DIR ?= $(PREFIX)/lib/qt6/qml

BIN_NAME := argvus-i18n
BIN := target/release/$(BIN_NAME)

.DEFAULT_GOAL := help

.PHONY: help build build-bin check lint fmt fmt-check validate validate-pkgbuild install install-core install-locales uninstall reinstall clean

help:
	@echo "Available targets:"
	@echo "  make build"
	@echo "  make build-bin"
	@echo "  make check"
	@echo "  make fmt"
	@echo "  make fmt-check"
	@echo "  make validate"
	@echo "  make validate-pkgbuild"
	@echo "  make install"
	@echo "  make install-core"
	@echo "  make install-locales"
	@echo "  make uninstall"
	@echo "  make reinstall"
	@echo "  make clean"

build:
	@tools/build-local-package.sh

build-bin:
	$(CARGO) build --release --locked

check:
	$(CARGO) clippy --locked --all-targets --all-features -- -D warnings
	$(CARGO) test --locked

lint: check

fmt:
	$(CARGO) fmt

fmt-check:
	$(CARGO) fmt --check

validate: fmt-check check validate-pkgbuild
	ARGVUS_I18N_DIR="$(CURDIR)/locales" $(CARGO) run --release --locked -- validate

validate-pkgbuild:
	@if command -v makepkg >/dev/null 2>&1; then \
		cd packaging/arch && makepkg -p PKGBUILD --printsrcinfo >/dev/null && makepkg -p PKGBUILD.local --printsrcinfo >/dev/null; \
	else \
		echo "makepkg not found; skipping PKGBUILD syntax validation"; \
	fi

install-core: build-bin
	$(INSTALL) -Dm755 "$(BIN)" "$(DESTDIR)$(PREFIX)/bin/$(BIN_NAME)"
	$(INSTALL) -Dm644 src/usr/share/argvus/lib/i18n.sh "$(DESTDIR)$(PREFIX)/share/argvus/lib/i18n.sh"
	$(INSTALL) -Dm644 src/usr/share/argvus/qml/argvus-i18n/I18n.qml "$(DESTDIR)$(QML_IMPORT_DIR)/org/argvus/i18n/I18n.qml"
	$(INSTALL) -Dm644 src/usr/share/argvus/qml/argvus-i18n/qmldir "$(DESTDIR)$(QML_IMPORT_DIR)/org/argvus/i18n/qmldir"
	$(INSTALL) -Dm644 docs/i18n.md "$(DESTDIR)$(PREFIX)/share/doc/argvus-i18n/i18n.md"
	$(INSTALL) -Dm644 LICENSE "$(DESTDIR)$(PREFIX)/share/licenses/argvus-i18n/LICENSE"

install-locales:
	$(INSTALL) -dm755 "$(DESTDIR)$(PREFIX)/share/argvus/i18n"
	cp -R --no-preserve=ownership locales/. "$(DESTDIR)$(PREFIX)/share/argvus/i18n/"

install: install-core install-locales

uninstall:
	$(RM) "$(DESTDIR)$(PREFIX)/bin/$(BIN_NAME)"
	$(RM) "$(DESTDIR)$(PREFIX)/share/argvus/lib/i18n.sh"
	rm -rf "$(DESTDIR)$(QML_IMPORT_DIR)/org/argvus/i18n"
	rm -rf "$(DESTDIR)$(PREFIX)/share/argvus/i18n"
	rm -rf "$(DESTDIR)$(PREFIX)/share/doc/argvus-i18n"
	rm -rf "$(DESTDIR)$(PREFIX)/share/licenses/argvus-i18n"

reinstall: uninstall install

clean:
	$(CARGO) clean
	rm -rf dist
	rm -f packaging/arch/*.zst packaging/arch/*.tar.gz
