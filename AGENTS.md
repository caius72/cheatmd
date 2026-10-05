# cheatmd — agent guide

Always-fullscreen macOS app that shows a markdown cheat sheet of keyboard shortcuts and
fuzzy-filters it as you type. Built for a 13" iPad used as a Sidecar display.

## Documents (read in this order)

1. [Requirements_Specification.md](Requirements_Specification.md) — what, with `R-` IDs
2. [Implementation_Design.md](Implementation_Design.md) — architecture, decisions, slice plan
3. [tests/Test_Plan.md](tests/Test_Plan.md) — `T-` rows, each citing the R-IDs it covers
4. [tests/Test_Infrastructure_Design.md](tests/Test_Infrastructure_Design.md) — layers, CI, commands
5. [TODO.md](TODO.md), [tests/TODO.md](tests/TODO.md) — open work, quirks, bugs

## Layout

- `CheatCore/` — Swift package, Foundation only: all logic and its tests (`swift test`).
- `cheatmd/` — the app target (AppKit window + SwiftUI views); thin shell over CheatCore.
- `build.sh`, `release.sh`, `VERSION` — signed and notarized release builds; `release.sh` publishes a
  GitHub release and updates the cask in `~/repos/homebrew-cheatmd`. Bump `VERSION` by PR first.
- `tools/` — `check.sh` (every gate), `lint.sh`, `coverage.sh`, `check_traceability.py`, `icon.sh`
  (renders `docs/icon.svg`, the icon's source, into the app icon set).

## Rules

- Run `tools/check.sh` before every push; CI runs the same script.
- Tests are requirements-based: expected values come from the spec, not the code. Tag each test
  `Plan: T-<n>. Covers: <exactly the row's R-IDs>.` and flip the row to `implemented` in the same
  commit. Never renumber R-/T-IDs; retire them.
- Update the documents in the same commit as the behavior they describe.
- Use the Xcode MCP tools for project settings and builds; do not hand-edit `project.pbxproj`
  when a tool covers the change.
- Coverage floor (`tools/coverage.sh`) only goes up.
- `main` is protected: work on a branch, open a PR, merge when CI is green.
