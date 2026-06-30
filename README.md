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

Known MVP limitations:

- CSV edited rows are reserialized on save; unedited rows keep their original row text when possible.
- Fixed-width mode is a safety-oriented preview/check view, not a table editor.
- This is a Swift Package executable app, not a signed `.app` distribution bundle yet.
