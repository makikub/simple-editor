---
name: simple-editor-release
description: Prepare, verify, and stage Simple Editor macOS releases with Sparkle updates and GitHub Pages appcast distribution. Use when working on release packaging, Sparkle keys, appcast generation, docs/releases staging, release smoke checks, or release-related scripts in this repository.
---

# Simple Editor Release

Use this skill for release packaging and update-feed work in `/Users/masakikubota/src/simple-editor`.

## Sources To Read First

1. Read `AGENTS.md`.
2. Read `README.md` Distribution section.
3. Read `scripts/build_app_bundle.sh` and `scripts/update_appcast.sh` before editing release behavior.
4. Read `Distribution/Info.plist` before changing Sparkle or bundle metadata.

## Release Safety Rules

- Never commit Sparkle private keys, Developer ID certificates, app-specific passwords, notarization credentials, generated `.app` bundles, or release zips.
- Use a real Sparkle EdDSA public key for releasable builds. Use `SPARKLE_PUBLIC_ED_KEY=dummy` only for local packaging smoke checks.
- Do not publish an unsigned appcast. `make release-pages` must receive `SPARKLE_PRIVATE_ED_KEY` or `SPARKLE_PRIVATE_ED_KEY_FILE`.
- Keep GitHub Pages defaults aligned with `https://makikub.github.io/simple-editor/` unless the repository or Pages settings prove otherwise.

## Local Verification

Run these checks after release-related changes:

```bash
swift build
bash -n scripts/build_app_bundle.sh
bash -n scripts/update_appcast.sh
SPARKLE_PUBLIC_ED_KEY=dummy make app-bundle
codesign --verify --deep --strict .build/dist/Simple\ Editor.app
plutil -lint Distribution/Info.plist
xmllint --noout docs/appcast.xml
```

Then launch the packaged app and inspect it with Computer Use:

```bash
open .build/dist/Simple\ Editor.app
```

Confirm:

- No Sparkle update alert appears on startup when the public key is invalid or omitted in local smoke builds.
- No stale crash-recovery banner appears from test data.
- Text mode opens cleanly.
- CSV mode can display a small CSV, filter rows, and keep the grid top-left aligned.

If GUI testing writes a recovery draft, remove only the test-created draft after stopping the app:

```bash
rm -f "$HOME/Library/Application Support/SimpleEditor/recovery.txt"
```

## Staging A Pages Release

Use this shape for a real release:

```bash
VERSION=0.1.0 \
BUILD=1 \
SPARKLE_PUBLIC_ED_KEY="public-key-from-generate-keys" \
SPARKLE_PRIVATE_ED_KEY_FILE="/path/to/private-ed-key" \
make release-pages
```

Expected outputs:

- `.build/dist/Simple Editor.app`
- `.build/dist/SimpleEditor-$VERSION.zip`
- `docs/releases/SimpleEditor-$VERSION.zip`
- `docs/appcast.xml`

Review generated `docs/appcast.xml` before committing release-page changes. Do not commit `.build/dist`.

## Review Checklist

- Sparkle feed URL and download URL prefix point at the same GitHub Pages site.
- `SUPublicEDKey` is present in packaged `Info.plist` only when it is a valid base64 EdDSA public key.
- `SUFeedURL` uses HTTPS.
- Local smoke builds do not start Sparkle with dummy keys.
- README commands match the scripts.
- The release commit contains only source/docs/appcast artifacts intended for GitHub Pages.
