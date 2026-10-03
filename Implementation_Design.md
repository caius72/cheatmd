# cheatmd — Implementation Design & Plan

Derived from [Requirements_Specification.md](Requirements_Specification.md).

## Architecture

```text
~/.config/cheatmd/cheatmd.md
        │ read, polled for changes
        ▼
┌──────────────────── CheatCore (Swift package, Foundation only) ─────────────────────┐
│ SheetSource ──► SheetParser ──► Section tree ──► Matcher ──► [ResultSection]          │
│ ChangeDetector    (Foundation markdown)            ▲   (highlights as an attribute)   │
│                                                    │                                  │
│ KeyReducer: (query, Key) → (query, Effect?)   Zoom   CardLayout   PreviousAppTracker   │
└──────────────────────────────────────────────────────────────────────────────────────┘
        ▲ pure values, unit-tested with `swift test`
┌──────────────────── cheatmd app target (AppKit + SwiftUI) ──────────────────────────┐
│ AppDelegate: owns the one FullscreenWindow, the key monitor, the poll timer          │
│ FullscreenWindow: NSWindow subclass that only ever enters fullscreen                  │
│ SheetModel (@Observable): query, sheet or load error, zoom                            │
│ SwiftUI views: QueryBar, CardGrid, CardView, EntryRow                                 │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

**CheatCore** (`CheatCore/`) holds every decision that can be made without a screen. It
imports only Foundation, so `swift test` covers it in seconds.

| Component | Responsibility | Requirements |
|---|---|---|
| `SheetSource` | Resolve the path from a home folder, create the file from the sample, read it as UTF-8, describe failures | R-1.1, R-1.2, R-1.4, R-1.5 |
| `ChangeDetector` | Fingerprint the file (inode, size, modification date); report changes | R-1.3 |
| `SheetParser` | Markdown → `SheetSection` tree of entries, prose and code blocks | R-2.* |
| `Matcher` | Query → ordered `ResultSection`s with highlighted text | R-3.1, R-4.2–R-4.6 |
| `KeyReducer` | Key press → new query and an optional `.returnFocus` effect | R-4.1, R-5.1, R-5.2 |
| `PreviousAppTracker` | Remember the last other app to activate; forget it once it quits | R-5.2, R-5.3 |
| `CardLayout` | Cards for the results, column count for a width and zoom, cards into the shortest column | R-3.2 |
| `Zoom` | 10% steps clamped to 50–300%, reset | R-3.6 |
| `DisplayChoice` | Remembered display while connected, else the main one; the next display for a move | R-6.3, R-6.6 |

**The app target** (`cheatmd/`) is a thin shell that wires AppKit events to CheatCore and draws
the result.

- `cheatmdApp` declares only a `Settings` scene. `AppDelegate`
  (`NSApplicationDelegateAdaptor`) creates the single window itself, because a SwiftUI
  `WindowGroup` can neither veto leaving fullscreen nor guarantee a single window.
- `FullscreenWindow` overrides `toggleFullScreen(_:)` to ignore the call when already
  fullscreen. It also re-enters fullscreen in `windowDidExitFullScreen`, a backstop for any path
  that bypasses the override. It opens on the last
  display. A fullscreen window cannot be dragged between displays, so the app remembers the
  display's name (`NSScreen.localizedName`, which is stable for a Sidecar iPad) whenever the window
  changes screen, and places the window on that screen before entering fullscreen (R-6.3).
  Move to Next Display leaves fullscreen through a path that bypasses the override, moves the
  window, and re-enters fullscreen from `windowDidExitFullScreen` (R-6.6).
- Link text is styled but not clickable: the sheet is display-only, and a clickable link could
  open any URL scheme.
- A local `keyDown` monitor maps events to `KeyReducer.Key`. Cmd-+, Cmd-− and Cmd-0 go to `Zoom`;
  other Cmd chords pass through to the menu (Cmd-Q).
- `NSWorkspace.didActivateApplicationNotification` feeds `PreviousAppTracker`; the
  `.returnFocus` effect calls `activate()` on the tracked app.
- A 1-second timer asks `ChangeDetector` whether to reload.

## Decisions

| Decision | Rationale | Alternatives rejected |
|---|---|---|
| Parse with Foundation `AttributedString(markdown:, interpretedSyntax: .full)` | Ships with the OS. Its presentation intents expose headings, list items, tables, code blocks and inline styles, and descriptions arrive already styled for SwiftUI `Text` | swift-markdown (a dependency for the same information); a hand-written parser |
| Core logic in a local Swift package | `swift test` with coverage; no app launch during tests | Unit-test target hosted in the app, which would launch fullscreen during every test run |
| AppKit owns the window | Required to veto leaving fullscreen and to keep one window | SwiftUI `WindowGroup` |
| Poll the file once a second | One `stat` a second costs nothing. It handles in-place writes, save-by-rename and delete-then-recreate alike. 1 s is within the 2 s of R-1.3 | `DispatchSource` on the file (loses the file on rename) plus the folder (misses in-place writes) |
| Highlights as a custom `AttributedString` attribute | The core marks the matched runs; the view maps them to a background colour, so the core stays free of SwiftUI | Returning index ranges that the view must re-map onto styled text |
| Masonry by shortest column | Cards differ a lot in height; filling the shortest column keeps columns even without measuring views | `LazyVGrid` (rows align to the tallest card) |
| Card width ≥ 420 pt × zoom | 1366 pt ÷ 420 = 3 columns at 100% (R-3.2) | — |
| No sandbox | The sandbox redirects `~` to its container, so it could not read `~/.config/cheatmd`. Not distributed (§4 of the spec) | Security-scoped bookmark plus a file chooser |
| CI on the `xcode-27` runner | The project file is Xcode 27 format (objectVersion 110), and the local toolchain is Xcode 27; one toolchain for build, `swift-format` and tests | `macos-26` with Xcode 26.6, which cannot open the project |

## Plan

| Slice | Delivers | Depends on | Status |
|---|---|---|---|
| 0 Gates | CI pipeline, traceability check, lint, format, coverage floor, secret scan; package and app build | — | done |
| 1 Show the sheet | R-1.1, R-1.2, R-1.5, R-2.1–R-2.5, R-3.1, R-3.3, R-3.4, R-3.5 | 0 | done (T-25 manual check pending on the iPad) |
| 2 Always fullscreen | R-6.1–R-6.6 | 1 | done (manual T-27–T-29 pending) |
| 3 Fuzzy find | R-4.1–R-4.7, R-5.1, R-5.4 | 1 | done (manual T-26 pending) |
| 4 Return focus | R-5.2, R-5.3 | 3 | done (manual T-26 pending) |
| 5 Cards and zoom | R-3.2, R-3.6 | 1 | done (manual T-30 zoom persistence pending) |
| 6 Live reload and errors | R-1.3, R-1.4 | 1 | done (manual T-30 pending) |
