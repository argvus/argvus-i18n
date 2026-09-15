#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$ROOT_DIR/packaging/arch/PKGBUILD.local" ]]; then
  PACKAGING_DIR="$ROOT_DIR/packaging/arch"
elif [[ -f "$ROOT_DIR/packaging/PKGBUILD.local" ]]; then
  PACKAGING_DIR="$ROOT_DIR/packaging"
else
  echo "PKGBUILD.local not found under packaging/arch or packaging." >&2
  exit 1
fi

BUILD_SCRIPT="$PACKAGING_DIR/PKGBUILD.local"
TEMP_BUILD_SCRIPT=""
cleanup() {
  [[ -z "$TEMP_BUILD_SCRIPT" ]] || rm -f "$TEMP_BUILD_SCRIPT"
}
trap cleanup EXIT

if [[ -f "$ROOT_DIR/Cargo.toml" ]]; then
  cargo_version="$(awk -F '"' '/^version = / { print $2; exit }' "$ROOT_DIR/Cargo.toml")"
  if [[ -n "$cargo_version" ]]; then
    TEMP_BUILD_SCRIPT="$(mktemp)"
    sed "s/^pkgver=.*/pkgver=${cargo_version}/" "$BUILD_SCRIPT" > "$TEMP_BUILD_SCRIPT"
    BUILD_SCRIPT="$TEMP_BUILD_SCRIPT"
  fi
fi

if [[ -z "$TEMP_BUILD_SCRIPT" ]]; then
  script_version="$(sed -n 's/^VERSION="\(.*\)"/\1/p' "$ROOT_DIR/src/usr/bin/argvus" | head -n1)"
  if [[ -n "$script_version" ]]; then
    TEMP_BUILD_SCRIPT="$(mktemp)"
    sed "s/^pkgver=.*/pkgver=${script_version}/" "$BUILD_SCRIPT" > "$TEMP_BUILD_SCRIPT"
    BUILD_SCRIPT="$TEMP_BUILD_SCRIPT"
  fi
fi

metadata="$({ cd "$PACKAGING_DIR" && bash -c 'source "$1"; printf "%s\n%s\n%s\n" "$pkgbase" "$pkgname" "$pkgver"' bash "$BUILD_SCRIPT"; })"
pkgbase="$(printf '%s\n' "$metadata" | sed -n '1p')"
pkgname="$(printf '%s\n' "$metadata" | sed -n '2p')"
pkgver="$(printf '%s\n' "$metadata" | sed -n '3p')"
base="${pkgbase:-${pkgname}}"
archive="$PACKAGING_DIR/${base}-${pkgver}.tar.gz"

if grep -q "${base}-\${pkgver}.tar.gz\|\${pkgname}-\${pkgver}.tar.gz\|${base}-${pkgver}.tar.gz" "$BUILD_SCRIPT"; then
  echo "Creating local source archive: $archive"
  tar -czf "$archive" \
    --exclude='./.git' \
    --exclude='./.release' \
    --exclude='./packages-repo' \
    --exclude='./dist' \
    --exclude='./tmp' \
    --exclude='./target' \
    --exclude='./pkg' \
    --exclude='./packaging/pkg' \
    --exclude='./packaging/src' \
    --exclude='./packaging/arch/pkg' \
    --exclude='./packaging/arch/src' \
    --exclude='./packaging/*.pkg.tar*' \
    --exclude='./packaging/arch/*.pkg.tar*' \
    --exclude="./${pkgdir:-pkg}" \
    --exclude="./${base}-${pkgver}.tar.gz" \
    --exclude="./packaging/${base}-${pkgver}.tar.gz" \
    --exclude="./packaging/arch/${base}-${pkgver}.tar.gz" \
    --transform "s#^\./#${base}-${pkgver}/#" \
    -C "$ROOT_DIR" .
fi

if [[ -n "${MAKEPKG_FLAGS:-}" ]]; then
  # shellcheck disable=SC2206
  flags=(${MAKEPKG_FLAGS})
elif [[ "$pkgname" == "argvus-waybar" ]]; then
  flags=(--syncdeps --noconfirm --needed --cleanbuild --clean --force)
else
  flags=(--nodeps --noconfirm --needed --cleanbuild --clean --force)
fi

cd "$PACKAGING_DIR"
makepkg -p PKGBUILD.local "${flags[@]}" "$@"

packages="$(find "$PACKAGING_DIR" -maxdepth 1 -type f -name 'argvus-*.pkg.tar.zst' -print | sort)"
if [[ -n "$packages" ]]; then
  printf 'Packages created:\n%s\n' "$packages"

  DIST_DIR="$ROOT_DIR/dist"
  mkdir -p "$DIST_DIR"
  mv -f $packages "$DIST_DIR/"
  printf 'Moved to %s:\n' "$DIST_DIR"
  printf '%s\n' "$packages" | xargs -I{} basename {}
fi
