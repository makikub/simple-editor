# Simple Editor

Personal macOS text editor MVP based on `PRD.md`.

## Debug

```sh
make debug
```

Equivalent command:

```sh
swift run
```

The window title and status bar show `DEBUG`, and the header uses a light debug-colored background.

## Release

```sh
make release
```

Equivalent command:

```sh
swift run -c release
```

The window title and status bar show `RELEASE`.

## Build Only

```sh
make build-debug
make build-release
```

## Distribution

Sparkle is wired for app updates when the executable is packaged as a `.app`.
The bundled app icon is generated from `scripts/generate_app_icon.swift` and
stored as `Distribution/AppIcon.icns`.

1. Generate a Sparkle EdDSA key pair with Sparkle's `generate_keys` tool.
2. Keep the private key outside the repository.
3. Regenerate the icon if the source script changed:

```sh
swift scripts/generate_app_icon.swift
```

4. Build the app bundle:

```sh
SPARKLE_PUBLIC_ED_KEY='public-key-from-generate-keys' make app-bundle
```

For Developer ID signing, pass the signing identity and hardened runtime option:

```sh
CODE_SIGN_IDENTITY='Developer ID Application: Example (TEAMID)' \
CODE_SIGN_OPTIONS='--options runtime' \
SPARKLE_PUBLIC_ED_KEY='public-key-from-generate-keys' \
make app-bundle
```

The default appcast URL is `https://makikub.github.io/simple-editor/appcast.xml`.
Override it with `SPARKLE_FEED_URL` if GitHub Pages uses another URL.
The generated app and zip are written to `.build/dist/`.

To stage a GitHub Pages update feed under `docs/`:

```sh
SPARKLE_PUBLIC_ED_KEY='public-key-from-generate-keys' \
SPARKLE_PRIVATE_ED_KEY_FILE='/path/to/ed25519_private_key' \
make release-pages
```

This copies the release zip into `docs/releases/` and regenerates
`docs/appcast.xml` with Sparkle's `generate_appcast` tool.

## MVP Scope

Implemented:

- macOS SwiftUI/AppKit app
- `NSTextView`-based text editor with line numbers
- Open, drag-and-drop open, save, save as
- UTF-8, UTF-8 BOM, CP932/Shift_JIS decode and encode
- Line ending detection and save-time preservation
- Save-time encoding validation
- Atomic save with optional `.bak`
- CSV/TSV display and cell editing
- Quoted CSV parsing, including commas, quotes, and cell newlines
- CSV all-cell and column-limited search
- Fixed-width ruler, guide display, byte/character length warning
- Plain and regex search, plain replace in text mode
- Status bar and crash-recovery draft
- Sparkle update check hook for packaged app distribution

Known MVP limitations:

- CSV edited rows are reserialized on save; unedited rows keep their original row text when possible.
- Fixed-width mode is a safety-oriented preview/check view, not a table editor.
- Public distribution still needs notarization after Developer ID signing.
