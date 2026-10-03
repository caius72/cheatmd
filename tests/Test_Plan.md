# cheatmd — Test Plan

Derived from [Requirements_Specification.md](../Requirements_Specification.md). Expected results
come from the requirement, never from the implementation. Layers are defined in
[Test_Infrastructure_Design.md](Test_Infrastructure_Design.md).

The status is the last cell: `planned`; `implemented`, meaning a test carries
`Plan: T-<n>. Covers: <its R-IDs>.`; or `manual`, meaning it is checked by hand from the list
below.

| ID | Test | Covers | Layer | Status |
|---|---|---|---|---|
| T-1 | The sheet path for home `/h` is `/h/.config/cheatmd/cheatmd.md` | R-1.1 | A | implemented |
| T-2 | With no `.config/cheatmd` folder, first load creates the folders and the file from the sample; the sample parses to top-level sections that include `vi` and `tmux` | R-1.2 | B | implemented |
| T-3 | Loading an existing file leaves its bytes and modification date unchanged, even when it differs from the sample | R-1.5 | B | implemented |
| T-4 | The change detector reports an in-place write, a save-by-rename and a delete-then-recreate; it reports nothing when the file is untouched; its poll interval is at most 2 s | R-1.3 | B | planned |
| T-5 | Loading a file that is missing after start-up, has no read permission, or holds invalid UTF-8 yields an error whose message contains the path and the reason; a later successful load yields the sheet again | R-1.4 | B | implemented |
| T-6 | `#`, `##`, `###`, `##` nest as expected; `#` followed directly by `###` nests the `###` under the `#`; a second `#` starts a new top-level section | R-2.1 | A | implemented |
| T-7 | A list item starting with a code span is an entry with those keys and that description; `` `@a` / `@@` replay `` has keys `@a / @@`; an item whose code span is not first is prose; an entry in a nested list is found; `` `x` – delete `` has description `delete`; an item that is only a code span has an empty description | R-2.2 | A | implemented |
| T-8 | Body rows of 2- and 3-column tables are entries (3 columns: description is cells 2 and 3 joined by a space); a row with an empty description cell is an entry with an empty description; the header row is not an entry; an escaped `\|` stays in the cell | R-2.3 | A | implemented |
| T-9 | An entry before the first heading is in the untitled root section; an entry after a subheading belongs to the subsection, not the parent | R-2.4 | A | implemented |
| T-10 | A paragraph, a code block, a block quote, a non-entry list item, a rule and an ordered list item (with its number) are kept in document order and are not entries | R-2.5 | A | implemented |
| T-11 | An empty or whitespace-only query yields every section, entry and prose block in document order | R-3.1 | A | implemented |
| T-12 | Description text keeps its bold, italic, code and link runs | R-3.3 | A | implemented |
| T-13 | Width 1366 at zoom 1.0 gives 3 columns; width 400 gives 1; width 0 gives 1; width 1366 at zoom 2.0 gives 1; cards go to the shortest column, ties to the leftmost | R-3.2 | A | planned |
| T-14 | In a sheet whose shallowest heading is `##`, the `##` sections are the cards | R-3.2 | A | planned |
| T-15 | Zoom in and out moves in 10% steps, stops at 50% and 300%, and resets to 100% | R-3.6 | A | planned |
| T-16 | A printable key appends to the query; Backspace removes the last character; Backspace on an empty query leaves it empty | R-4.1 | A | planned |
| T-17 | `vi ma` matches an entry under `vi → Macros` and none under `tmux`; matching ignores case; `acro` does not match `macro` (not at a word start); `%` matches `C-b %`; an entry matching only some terms does not match | R-4.2 | A | planned |
| T-18 | With a query, only matching entries appear, each with its full heading path; prose, code blocks and sections without a match are absent | R-4.3 | A | planned |
| T-19 | Every word-start occurrence of each term is highlighted in the heading path, keys and description; an occurrence inside a word is not | R-4.4 | A | planned |
| T-20 | A section whose heading path holds 2 terms comes before one holding 1, which comes before one holding 0; ties keep document order; entries keep document order | R-4.5 | A | planned |
| T-21 | A query matching nothing yields no sections and the message `No matches for “<query>”` | R-4.6 | A | planned |
| T-22 | Filtering a generated sheet of 2,000 entries for a 2-term query takes under 50 ms (release build) | R-4.7 | A | planned |
| T-23 | Esc with a non-empty query clears it and has no effect; Esc with an empty query and Return with any query produce `.returnFocus` and leave the query unchanged | R-5.1, R-5.2 | A | planned |
| T-24 | The tracker ignores cheatmd's own activation and returns the last other app; it returns nothing before any app activated or once that app has quit | R-5.2, R-5.3 | A | planned |
| T-25 | Inline styling, monospaced keys and scrolling, checked on the iPad | R-3.3, R-3.4, R-3.5 | D | manual |
| T-26 | Return to the previous app; typing after activation | R-5.2, R-5.4 | D | manual |
| T-27 | Fullscreen at launch and cannot be left | R-6.1, R-6.2 | D | manual |
| T-28 | Move to the iPad; reopens on the last display; falls back to the main display | R-6.3, R-6.6 | D | manual |
| T-29 | Closing quits; a second open activates the running instance | R-6.4, R-6.5 | D | manual |
| T-30 | Live reload while filtering, error and recovery, zoom persistence | R-1.3, R-1.4, R-3.6 | D | manual |
| T-31 | The remembered display is chosen while connected; otherwise, or when none is remembered, the main display | R-6.3 | A | implemented |
| T-32 | The next display after the current one wraps around after the last; with one display it is the current one | R-6.6 | A | implemented |

## Manual checks

These need a real window server, a second display or another app's focus, which no automated
layer reaches. Run them on the iPad (Sidecar) before marking a slice done that delivers them.

- **T-25:**
  - The sample sheet shows bold, italic, code and link text, each styled differently.
  - Keys are monospaced and visibly distinct from descriptions.
  - Two-finger scrolling moves a sheet taller than the screen.
- **T-26:**
  - Switch to cheatmd from Terminal with the hotkey, type `vi ma` without clicking, and press
    Return. Terminal becomes active, and cheatmd still shows `vi ma` with its results.
  - Repeat, pressing Esc twice instead of Return: the first Esc clears the query, and the second
    returns to Terminal.
  - Repeat, activating cheatmd with Cmd-Tab and then with the Dock: typing reaches the query
    without a click each time.
- **T-27:**
  - Launch: the app is fullscreen with no clicks.
  - Each of View → Exit Full Screen, Ctrl-Cmd-F and the green button leaves it fullscreen.
- **T-28:**
  - Press Ctrl-Cmd-→ until the app is on the iPad; it stays fullscreen after each move.
  - Quit and relaunch: it opens fullscreen on the iPad.
  - Disconnect Sidecar and relaunch: it opens fullscreen on the main display.
- **T-29:**
  - Close the window (Cmd-W): the app quits.
  - Run `open -a cheatmd` twice: `pgrep -x cheatmd` lists one process.
- **T-30:**
  - Type `tmux`, then add an entry under `tmux` in vim and `:w`. Within 2 s the new entry appears,
    and the query is still `tmux`.
  - Run `chmod 000` on the file: the app shows a message naming the path. Run `chmod 644`: the
    sheet returns.
  - Zoom to 150%, quit and relaunch: the zoom is still 150%.
