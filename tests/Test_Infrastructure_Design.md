# cheatmd — Test Infrastructure Design

Derived from [Implementation_Design.md](../Implementation_Design.md) and
[Test_Plan.md](Test_Plan.md).

## Layers

| Layer | Touches | Runs in CI | Command |
|---|---|---|---|
| A | CheatCore pure logic: parser, matcher, reducer, layout, zoom, tracker | yes | `swift test --package-path CheatCore` |
| B | CheatCore with the real filesystem, in a fresh temp folder per test | yes | same as A |
| C | App target compiles and links against CheatCore. No behavior is asserted | yes | `xcodebuild -project cheatmd.xcodeproj -scheme cheatmd build` |
| D | Window server, Sidecar display, other apps' focus | no | manual checklist in [Test_Plan.md](Test_Plan.md#manual-checks) |

All gates run with **one local command:** `tools/check.sh`. CI runs the same script.

## Fixtures and harnesses

- Tests use Swift Testing (`import Testing`) in `CheatCore/Tests/CheatCoreTests/`, one file per
  component. Each test's doc comment carries `Plan: T-<n>. Covers: <R-IDs>.`
- **Markdown fixtures** are inline string literals next to the test that uses them, so each
  test reads on its own.
- **`TempDir`** (in `Support.swift`) creates a unique folder under `FileManager.temporaryDirectory`
  and removes it in `deinit`. Layer B tests pass it to `SheetSource(home:)` as the home folder,
  so the tests never touch the real `~/.config`.
- **`FakeApp`** implements the tracker's `ActivatableApp` protocol, with settable `isTerminated`.
- **T-22** generates its 2,000-entry sheet in code. It runs under
  `swift test -c release -Xswiftc -enable-testing` (release builds need `-enable-testing` for
  `@testable import`), where timing is meaningful; in debug builds a condition trait skips it.

## CI

`.github/workflows/ci.yml`, triggered on every push and pull request.

| Job | Runner | Gates (all fail the job) |
|---|---|---|
| `check` | `xcode-27` | `tools/check.sh`, which runs, in order: the traceability check, `swift format lint --strict`, SwiftLint, `swift test` with coverage, the coverage floor, the release-build performance test (T-22), and the app build |
| `secrets` | `ubuntu-latest` | gitleaks, version pinned, over the full history |

- **Lint:** SwiftLint, pinned in `tools/lint.sh` (it downloads the portable binary into
  `.tools/`, the same way locally and in CI). The rules are listed explicitly in `.swiftlint.yml`
  (`only_rules`), so a new SwiftLint release cannot add rules silently.
- **Format:** the `swift-format` bundled with the selected Xcode, with `.swift-format` checked
  in. Locally and in CI this is Xcode 27.
- **Coverage:** `swift test --enable-code-coverage`, then `tools/coverage.sh`, which reads
  `llvm-cov report` for `CheatCore/Sources` and fails below `COVERAGE_FLOOR` (region coverage,
  set in the script). Swift does not emit branch coverage, so regions are the closest measure.
  The floor only ever rises.
- **Secrets:** gitleaks in CI, plus GitHub secret scanning with push protection on the
  repository.
- **Merge protection:** `main` requires a pull request with `check` and `secrets` green, and
  applies to admins too.
