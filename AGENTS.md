# AGENTS.md

## Project Scope

- This repository is a macOS SwiftUI/AppKit text editor distributed as a Swift Package executable and packaged `.app`.
- Preserve the PRD priority: do not corrupt file encoding, line endings, CSV row text, or fixed-width layout safety.
- Keep changes narrow. Avoid unrelated refactors, generated artifact churn, or broad UI rewrites unless the task explicitly asks for them.

## Communication

- Reply in Japanese unless the user asks otherwise.
- Be concise and concrete. State what changed, how it was verified, and any remaining risk.
- If requirements are ambiguous, ask before making product or release decisions.

## Code And UI Work

- Use existing SwiftUI/AppKit patterns in `Sources/SimpleEditorApp`.
- Prefer small view-model or service changes over embedding persistence or parsing logic directly in views.
- For CSV changes, preserve the invariant that unedited rows keep their original text when possible.
- For fixed-width changes, surface warnings clearly before blocking saves.
- Do not add a new runtime dependency without explaining why it is needed and verifying build/package behavior.

## Release And Sparkle

- Use the `$simple-editor-release` skill for release preparation, Sparkle appcast work, or GitHub Pages distribution changes.
- Keep Sparkle private keys out of the repository. The public EdDSA key may be injected through `SPARKLE_PUBLIC_ED_KEY`.
- Do not generate or publish unsigned appcasts for release. `make release-pages` must require a private EdDSA key source.
- Treat `.build/dist/` as generated output. Do not commit built apps, zips, or local signing artifacts.

## Required Verification

- After Swift source changes, run `swift build`.
- After release-script or Sparkle changes, run:
  - `bash -n scripts/build_app_bundle.sh`
  - `bash -n scripts/update_appcast.sh`
  - `SPARKLE_PUBLIC_ED_KEY=dummy make app-bundle`
  - `codesign --verify --deep --strict .build/dist/Simple\ Editor.app`
  - `plutil -lint Distribution/Info.plist`
  - `xmllint --noout docs/appcast.xml`
- When UI behavior changes, launch the app and inspect it with Computer Use or an equivalent GUI check. Verify the app opens without startup alerts and without stale recovery banners caused by tests.

## Git

- Before review or bug-fix work, inspect recent relevant history with `git log --oneline --since='1 week ago' -- <file>`.
- Commit messages must include what changed and why. If a rejected alternative matters, mention why it was not used.
- Do not commit secrets, `.build/`, `.swiftpm/`, generated release zips, or local recovery/test files.
