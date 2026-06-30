#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.1.0}"
PAGES_DIR="$ROOT_DIR/docs"
RELEASES_DIR="$PAGES_DIR/releases"
ZIP_PATH="$ROOT_DIR/.build/dist/SimpleEditor-$VERSION.zip"
DOWNLOAD_PREFIX="${SPARKLE_DOWNLOAD_URL_PREFIX:-https://makikub.github.io/simple-editor/releases/}"
RELEASE_NOTES_PREFIX="${SPARKLE_RELEASE_NOTES_URL_PREFIX:-https://makikub.github.io/simple-editor/releases/}"
PRODUCT_LINK="${SPARKLE_PRODUCT_LINK:-https://makikub.github.io/simple-editor/}"
GENERATE_APPCAST="$ROOT_DIR/.build/artifacts/sparkle/Sparkle/bin/generate_appcast"

if [[ ! -x "$GENERATE_APPCAST" ]]; then
  swift build -c release
fi

if [[ -z "${SPARKLE_PRIVATE_ED_KEY:-}" && -z "${SPARKLE_PRIVATE_ED_KEY_FILE:-}" ]]; then
  echo "SPARKLE_PRIVATE_ED_KEY or SPARKLE_PRIVATE_ED_KEY_FILE is required to sign the appcast." >&2
  exit 2
fi

"$ROOT_DIR/scripts/build_app_bundle.sh"

mkdir -p "$RELEASES_DIR"
cp "$ZIP_PATH" "$RELEASES_DIR/"

if [[ -n "${SPARKLE_RELEASE_NOTES_FILE:-}" ]]; then
  cp "$SPARKLE_RELEASE_NOTES_FILE" "$RELEASES_DIR/SimpleEditor-$VERSION.md"
fi

if [[ -n "${SPARKLE_PRIVATE_ED_KEY:-}" ]]; then
  printf "%s" "$SPARKLE_PRIVATE_ED_KEY" | "$GENERATE_APPCAST" \
    --ed-key-file - \
    --download-url-prefix "$DOWNLOAD_PREFIX" \
    --release-notes-url-prefix "$RELEASE_NOTES_PREFIX" \
    --link "$PRODUCT_LINK" \
    -o "$PAGES_DIR/appcast.xml" \
    "$RELEASES_DIR"
elif [[ -n "${SPARKLE_PRIVATE_ED_KEY_FILE:-}" ]]; then
  "$GENERATE_APPCAST" \
    --ed-key-file "$SPARKLE_PRIVATE_ED_KEY_FILE" \
    --download-url-prefix "$DOWNLOAD_PREFIX" \
    --release-notes-url-prefix "$RELEASE_NOTES_PREFIX" \
    --link "$PRODUCT_LINK" \
    -o "$PAGES_DIR/appcast.xml" \
    "$RELEASES_DIR"
fi

echo "$PAGES_DIR/appcast.xml"
