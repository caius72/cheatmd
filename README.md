<img src="docs/icon.svg" width="128" alt="cheatmd icon">

# cheatmd

An always-fullscreen macOS app that shows your keyboard-shortcut cheat sheet, a plain
hierarchical markdown file at `~/.config/cheatmd/cheatmd.md`, and fuzzy-filters it as you type:
`vi ma` brings up the vi macro shortcuts, highlighted. Built for a 13" iPad used as a Sidecar
display. Bind a global hotkey to `open -a cheatmd` with your tool of choice.

![cheatmd fullscreen on a 13" iPad: vi, tmux and macOS cards](docs/screenshot.png)

Typing filters as you go; `vi ma` brings the vi macros and marks to the front:

![cheatmd filtered by "vi ma", matches highlighted](docs/screenshot-filter.png)

## Install

Needs macOS 26 or later on an Apple Silicon Mac. cheatmd is signed with a Developer ID and
notarized by Apple, and installs from the
[caius72/cheatmd Homebrew tap](https://github.com/caius72/homebrew-cheatmd):

```sh
brew install --cask caius72/cheatmd/cheatmd
```

This puts `cheatmd.app` in `/Applications`. The first launch creates
`~/.config/cheatmd/cheatmd.md` from a sample (vi, tmux, macOS); edit it to make the sheet yours.
To put cheatmd on the iPad, press ⌃⌘→ until it is there; it opens on that display from then on.
Bind a global hotkey (Alfred, Raycast, BetterTouchTool, …) to `open -a cheatmd`.

Upgrade and uninstall:

```sh
brew upgrade --cask cheatmd
brew uninstall --cask cheatmd         # removes the app
brew uninstall --cask --zap cheatmd   # also removes its settings (zoom, display)
```

Your sheet in `~/.config/cheatmd/` is never removed; delete it yourself if you want it gone.

## Use

| Key | Does |
|---|---|
| type | filter: every word must start a word in the heading path, keys or description (`vi ma`) |
| Backspace | delete the last character |
| Esc | clear the query; on an empty query, return to the previous app |
| Return | return to the previous app, leaving the results on screen |
| ⌘ + / ⌘ − / ⌘ 0 | zoom in / out / reset |
| ⌃ ⌘ → | move to the next display (put it on the iPad once; it remembers) |

The sheet is plain markdown: headings nest, and a list item that starts with a code span
(`` - `qa` record macro ``) or a row of a two-column table is a shortcut. Edit it in any
editor; the app reloads within a second.

Status: all requirements implemented; manual checks pending, see [TODO.md](TODO.md). Contributors and agents start at
[AGENTS.md](AGENTS.md).

```sh
tools/check.sh      # every gate: traceability, format, lint, tests, coverage, app build
./build.sh          # Developer ID signed Release build, notarized when credentials allow
./release.sh        # from main: notarized build, GitHub release, Homebrew cask update
```
