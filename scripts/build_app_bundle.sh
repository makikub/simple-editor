#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.1.0}"
BUILD="${BUILD:-1}"
APP_NAME="${APP_NAME:-Simple Editor}"
APPCAST_URL="${SPARKLE_FEED_URL:-https://makikub.github.io/simple-editor/appcast.xml}"
PUBLIC_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
CONFIGURATION="${CONFIGURATION:-release}"
CODE_SIGN_OPTIONS="${CODE_SIGN_OPTIONS:-}"
NOTARIZE="${NOTARIZE:-0}"
NOTARYTOOL_TIMEOUT="${NOTARYTOOL_TIMEOUT:-30m}"

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
APP_ICON="$ROOT_DIR/Distribution/AppIcon.icns"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$FRAMEWORKS_DIR" "$RESOURCES_DIR"

cp "$BIN_DIR/simple-editor" "$MACOS_DIR/simple-editor"
cp "$APP_ICON" "$RESOURCES_DIR/AppIcon.icns"

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

CODE_SIGN_ARGS=(--force --deep)
if [[ -n "$CODE_SIGN_OPTIONS" ]]; then
  # Split intentional option strings such as "--options runtime".
  # shellcheck disable=SC2206
  EXTRA_CODE_SIGN_ARGS=($CODE_SIGN_OPTIONS)
  CODE_SIGN_ARGS+=("${EXTRA_CODE_SIGN_ARGS[@]}")
fi
CODE_SIGN_ARGS+=(--sign "${CODE_SIGN_IDENTITY:--}" "$APP_DIR")

codesign "${CODE_SIGN_ARGS[@]}"

if [[ "$NOTARIZE" == "1" ]]; then
  if [[ "${CODE_SIGN_IDENTITY:--}" == "-" ]]; then
    echo "NOTARIZE=1 requires a Developer ID CODE_SIGN_IDENTITY." >&2
    exit 2
  fi

  NOTARYTOOL_ARGS=()
  if [[ -n "${NOTARYTOOL_KEYCHAIN_PROFILE:-}" ]]; then
    NOTARYTOOL_ARGS+=(--keychain-profile "$NOTARYTOOL_KEYCHAIN_PROFILE")
  elif [[ -n "${NOTARYTOOL_KEY:-}" && -n "${NOTARYTOOL_KEY_ID:-}" ]]; then
    NOTARYTOOL_ARGS+=(--key "$NOTARYTOOL_KEY" --key-id "$NOTARYTOOL_KEY_ID")
    if [[ -n "${NOTARYTOOL_ISSUER:-}" ]]; then
      NOTARYTOOL_ARGS+=(--issuer "$NOTARYTOOL_ISSUER")
    fi
  elif [[ -n "${NOTARYTOOL_APPLE_ID:-}" && -n "${NOTARYTOOL_PASSWORD:-}" && -n "${NOTARYTOOL_TEAM_ID:-}" ]]; then
    NOTARYTOOL_ARGS+=(--apple-id "$NOTARYTOOL_APPLE_ID" --password "$NOTARYTOOL_PASSWORD" --team-id "$NOTARYTOOL_TEAM_ID")
  else
    echo "NOTARIZE=1 requires NOTARYTOOL_KEYCHAIN_PROFILE, App Store Connect API key variables, or Apple ID variables." >&2
    exit 2
  fi

  NOTARY_ZIP="$ROOT_DIR/.build/dist/SimpleEditor-$VERSION-notary-upload.zip"
  ditto -c -k --keepParent "$APP_DIR" "$NOTARY_ZIP"
  xcrun notarytool submit "$NOTARY_ZIP" --wait --timeout "$NOTARYTOOL_TIMEOUT" "${NOTARYTOOL_ARGS[@]}"
  xcrun stapler staple "$APP_DIR"
  xcrun stapler validate "$APP_DIR"
  rm -f "$NOTARY_ZIP"
fi

ditto -c -k --keepParent "$APP_DIR" "$ROOT_DIR/.build/dist/SimpleEditor-$VERSION.zip"

echo "$APP_DIR"
echo "$ROOT_DIR/.build/dist/SimpleEditor-$VERSION.zip"
