#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.1.0}"
BUILD="${BUILD:-1}"
APP_NAME="${APP_NAME:-Simple Editor}"
APPCAST_URL="${SPARKLE_FEED_URL:-https://makikub.github.io/simple-editor/appcast.xml}"
PUBLIC_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
CONFIGURATION="${CONFIGURATION:-release}"

if [[ -z "$PUBLIC_KEY" ]]; then
  echo "SPARKLE_PUBLIC_ED_KEY is required. Generate it with Sparkle's generate_keys tool." >&2
  exit 2
fi

swift build -c "$CONFIGURATION"

BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
APP_DIR="$ROOT_DIR/.build/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$FRAMEWORKS_DIR" "$RESOURCES_DIR"

cp "$BIN_DIR/simple-editor" "$MACOS_DIR/simple-editor"

INFO_PLIST="$CONTENTS_DIR/Info.plist"
sed \
  -e "s#__VERSION__#$VERSION#g" \
  -e "s#__BUILD__#$BUILD#g" \
  -e "s#__SPARKLE_FEED_URL__#$APPCAST_URL#g" \
  -e "s#__SPARKLE_PUBLIC_ED_KEY__#$PUBLIC_KEY#g" \
  "$ROOT_DIR/Distribution/Info.plist" > "$INFO_PLIST"

if [[ -d "$BIN_DIR/Sparkle.framework" ]]; then
  cp -R "$BIN_DIR/Sparkle.framework" "$FRAMEWORKS_DIR/"
elif [[ -d "$ROOT_DIR/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework" ]]; then
  cp -R "$ROOT_DIR/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework" "$FRAMEWORKS_DIR/"
fi

codesign --force --deep --sign "${CODE_SIGN_IDENTITY:--}" "$APP_DIR"

ditto -c -k --keepParent "$APP_DIR" "$ROOT_DIR/.build/dist/SimpleEditor-$VERSION.zip"

echo "$APP_DIR"
echo "$ROOT_DIR/.build/dist/SimpleEditor-$VERSION.zip"
