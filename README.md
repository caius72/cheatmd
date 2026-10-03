# cheatmd

An always-fullscreen macOS app that shows your keyboard-shortcut cheat sheet, a plain
hierarchical markdown file at `~/.config/cheatmd/cheatmd.md`, and fuzzy-filters it as you type:
`vi ma` brings up the vi macro shortcuts, highlighted. Built for a 13" iPad used as a Sidecar
display. Bind a global hotkey to `open -a cheatmd` with your tool of choice.

Status: in development; see [TODO.md](TODO.md). Contributors and agents start at
[AGENTS.md](AGENTS.md).

```sh
tools/check.sh      # every gate: traceability, format, lint, tests, coverage, app build
```
