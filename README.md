# argvus-i18n

Shared internationalization infrastructure for the ARGVUS desktop.

The repository contains the Rust catalog library and CLI, Shell and QML
integration files, locale catalogs, and Arch Linux packaging for the core
runtime plus the English and Brazilian Portuguese language packs.

## Build from source

```sh
make build
make install
```

`make build` runs the workspace checks and creates local packages in
`build/dist/`. The package installs the CLI as `/usr/bin/argvus-i18n`,
catalogs under `/usr/share/argvus/i18n/`, and the Shell/QML integrations.

## Workspace

```text
crates/
  core/       locale detection, catalog loading, and translation APIs
  main/       argvus-i18n CLI
locales/      en-US canonical catalogs and pt-BR translations
packaging/
  arch/
    local/    package built from the current working tree
    ci/       package built from a version tag
tools/sh/     local source archive and makepkg driver
```

See [docs/i18n.md](docs/i18n.md) for the API and catalog contract.

## License

SPDX: `GPL-3.0-only`. See [LICENSE](LICENSE).
