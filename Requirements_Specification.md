# cheatmd — Requirements Specification

## 1. Objectives

The owner's statement, confirmed 2026-10-03:

> A fullscreen app that renders a markdown document with keyboard short cut. I want this
> always to run in fullscreen mode. I will create a global keyboard short cut to open and
> switch to it. The markdown will be a normal hierarchal markdown document. It will have
> sections for vi, tmux, and what ever other keyboard short cuts I can't remember. If the
> app is in focus typing will be fuzzy finding. For example "vi ma" should bring up and
> highlight the keyboard shortcuts for vi macros. The hierarchical markdown source file will
> allow me to easily organize my short cuts.
>
> My intended target screen is 13" ipad, that I use as an external display.

Agreed during grilling:

- **Success:** hotkey → type `vi ma` → the vi macro shortcuts are on screen and highlighted,
  with no perceptible lag per keystroke.
- **Target screen:** a 13" iPad as a Sidecar display, about 1366×1024 points, landscape, driven
  by the Mac's keyboard.
- **Constraints:** macOS 26 or later, Apple Silicon, built from source for the owner's own use.
- **Out of scope:** see §4.

## 2. Definitions

| Term | Meaning |
|---|---|
| Sheet | The markdown document the app displays. |
| Section | The content under a heading, up to the next heading of the same or a lower level. |
| Heading path | The titles of a section and all its enclosing sections, outermost first. |
| Entry | One keyboard shortcut: its *keys* and its *description* (R-2.2, R-2.3). |
| Card | The on-screen box that holds one top-level section. |
| Query | The text typed while the app has focus. |
| Term | A whitespace-separated part of the query. |
| Word start | The start of a text, or a letter or digit that follows a character that is not a letter or digit. |
| Previous app | The app that was frontmost immediately before cheatmd became active. |

## 3. Requirements

### R-1 Sheet source

R-1.1 The app MUST read the sheet from `~/.config/cheatmd/cheatmd.md`.

R-1.2 If that file does not exist at launch, the app MUST create it, and any missing parent
folders, from a bundled sample containing at least a `vi` and a `tmux` section, then display it.

R-1.3 When the file changes on disk, including an editor's save-by-rename, the app MUST display
the new content within 2 seconds, without a restart and without clearing the query.

R-1.4 If the file cannot be read or is not valid UTF-8, the app MUST show a message naming the
path and the reason in place of the sheet, and MUST show the sheet again once the file is
readable (per R-1.3).

R-1.5 The app MUST NOT write to the sheet file once it exists.

### R-2 Sheet structure

R-2.1 Headings (`#` to `######`) MUST define the section hierarchy: a section nests inside the
nearest preceding section whose heading level is lower.

R-2.2 A list item whose text starts with a code span MUST be an entry. Its keys are the leading
code spans together with the whitespace and punctuation between them; its description is the
rest of the item's first paragraph, trimmed of whitespace and of one leading `-`, `–`, `—` or
`:`. Example: `` - `@a` / `@@` replay macro `` has keys `@a / @@` and description
`replay macro`; `` - `x` – delete char `` has description `delete char`.

R-2.3 A body row of a table with two or more columns MUST be an entry. Its keys are the first
cell; its description is the remaining cells joined by a space. The header row is not an entry.

R-2.4 An entry MUST belong to the innermost section that contains it. Content before the first
heading belongs to an untitled root section.

R-2.5 All other markdown blocks (paragraphs, list items that are not entries, code blocks,
block quotes) MUST be displayed in document order, and MUST NOT be entries.

### R-3 Display

R-3.1 With an empty query, the app MUST display the whole sheet in document order.

R-3.2 Each top-level section (one not nested in another section) MUST be displayed as a card;
content before the first heading forms an untitled first card. Cards MUST flow into columns: at the default zoom, a window 1366 points wide MUST show 3
columns. Narrower windows MUST show fewer columns, but never fewer than 1.

R-3.3 Bold, italic, code spans and link text MUST be displayed with distinct styling.

R-3.4 An entry's keys MUST be displayed in a monospaced font, visually distinct from its
description.

R-3.5 Content taller than the screen MUST scroll with the trackpad, mouse wheel or a two-finger
gesture on the iPad.

R-3.6 The app SHOULD zoom the whole sheet with Cmd-+ and Cmd-−, in 10% steps between 50% and
300%. Cmd-0 SHOULD reset to 100%. The zoom level SHOULD persist across launches.

### R-4 Fuzzy find

R-4.1 While the app is active, typing a printable character MUST append it to the query, with
no field to click first. The query MUST be visible on screen. Backspace MUST delete the last
character.

R-4.2 An entry MUST match the query if and only if every term occurs, ignoring case, at a word
start in at least one of: the entry's heading path, its keys, or its description. A term that
starts with a character that is not a letter or digit may occur anywhere. Example: `vi ma`
matches the entry `` `qa` record macro `` under `# vi` → `## Macros`, and does not match any
entry under `# tmux`.

R-4.3 With a non-empty query, the app MUST display only matching entries, each under its full
heading path. Sections without matching entries, and all non-entry content, MUST be hidden.

R-4.4 Every occurrence of a term that satisfies R-4.2 MUST be highlighted, in headings, keys and
descriptions.

R-4.5 Sections MUST be ordered by how many terms occur in their heading path, most first. Ties
MUST keep document order, and entries within a section MUST keep document order.

R-4.6 If no entry matches, the app MUST say that nothing matches the query.

R-4.7 Filtering a sheet of 2,000 entries MUST take less than 50 ms per query on an Apple Silicon
Mac.

### R-5 Keys and focus

R-5.1 Esc with a non-empty query MUST clear the query.

R-5.2 Return, or Esc with an empty query, MUST make the previous app active again. cheatmd's
window MUST stay visible and the query MUST stay unchanged.

R-5.3 If there is no previous app, or it has quit, Return and Esc with an empty query MUST do
nothing.

R-5.4 Whenever cheatmd becomes active (hotkey, Dock, Cmd-Tab), keystrokes MUST reach the query
without a click.

### R-6 Window

R-6.1 The app MUST enter native fullscreen at launch, without user action.

R-6.2 Nothing MUST take the app out of fullscreen: the View menu toggle, Ctrl-Cmd-F and the
window's green button MUST leave it fullscreen.

R-6.3 The app MUST open on the display it was last fullscreen on, if that display is connected,
and otherwise on the main display.

R-6.4 Closing the window MUST quit the app.

R-6.5 Opening the app while it runs MUST activate the running instance, not start a second one.

R-6.6 Ctrl-Cmd-→ SHOULD move the window to the next connected display, wrapping around after the
last, and the window is fullscreen again afterwards. With one display it MUST do nothing. A fullscreen window cannot be dragged, so this
is how the window first reaches the iPad.

R-6.7 Cmd-Q and the app menu's Quit item MUST quit the app.

## 4. Non-goals

- **The global hotkey.** The owner binds it with an external tool, for example
  `open -a cheatmd`.
- **Editing in the app.** The sheet is edited in the owner's editor; R-1.3 picks up changes.
- **Multiple sheets or a file chooser.** One fixed path keeps launch instant and the code small.
- **Tap or Pencil interaction on the iPad.** Sidecar is driven by the Mac keyboard; scrolling is
  enough.
- **A windowed mode.**
- **Acting on entries:** selecting, copying or executing a shortcut.
- **Images and raw HTML** in the sheet.
- **Distribution:** notarization, App Store, Intel Macs, macOS before 26, sync.

## 5. Open questions

None.
