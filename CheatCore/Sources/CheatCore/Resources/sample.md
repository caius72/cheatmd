# vi

## Movement
- `h` `j` `k` `l` left, down, up, right
- `w` / `b` next / previous word start
- `e` end of word
- `0` / `^` / `$` line start / first non-blank / line end
- `gg` / `G` first / last line
- `{` / `}` previous / next paragraph
- `%` jump to matching bracket
- `C-d` / `C-u` half page down / up

## Editing
- `i` / `a` insert before / after cursor
- `o` / `O` open line below / above
- `x` delete character
- `dd` delete line
- `cw` change word
- `ciw` change inner word
- `yy` yank line
- `p` / `P` put after / before
- `u` / `C-r` undo / redo
- `.` repeat last change
- `>>` / `<<` indent / outdent line

## Macros
- `qa` record a macro into register `a`
- `q` stop recording
- `@a` replay macro `a`
- `@@` replay the last macro
- `5@a` replay macro `a` five times
- `:reg a` show the contents of register `a`

## Marks
- `ma` set mark `a`
- `` `a `` jump to mark `a`
- ``` `` ``` jump back to the previous position

## Search and replace
- `/text` search forward
- `?text` search backward
- `n` / `N` next / previous match
- `*` search for the word under the cursor
- `:%s/old/new/g` replace in the whole file
- `:%s/old/new/gc` replace, confirming each match

## Windows
- `:sp` / `:vsp` split horizontally / vertically
- `C-w w` cycle windows
- `C-w h` `C-w l` move to the left / right window
- `C-w =` equalize window sizes
- `C-w q` close window

# tmux

Prefix is `C-b`.

## Sessions

| keys | action |
|---|---|
| `tmux new -s name` | new named session |
| `tmux a -t name` | attach to a session |
| `C-b d` | detach |
| `C-b s` | list and switch sessions |
| `C-b $` | rename session |

## Windows

| keys | action |
|---|---|
| `C-b c` | new window |
| `C-b ,` | rename window |
| `C-b n` / `C-b p` | next / previous window |
| `C-b 0`…`9` | go to window by number |
| `C-b w` | choose window from a list |
| `C-b &` | kill window |

## Panes

| keys | action |
|---|---|
| `C-b %` | split left / right |
| `C-b "` | split top / bottom |
| `C-b o` | next pane |
| `C-b ←↑→↓` | move to the pane in that direction |
| `C-b z` | zoom pane (toggle) |
| `C-b x` | kill pane |
| `C-b {` / `C-b }` | swap pane with previous / next |
| `C-b Space` | cycle layouts |

## Copy mode

| keys | action |
|---|---|
| `C-b [` | enter copy mode |
| `Space` | start selection |
| `Enter` | copy selection |
| `C-b ]` | paste |
| `q` | leave copy mode |

# macOS

- `⌘ Space` Spotlight
- `⌘ Tab` switch apps
- `` ⌘ ` `` switch windows of the current app
- `⌃ ⌘ F` toggle full screen
- `⌘ ⇧ 4` screenshot of a selection
- `⌘ ⇧ 5` screenshot and recording options
- `⌃ ⌘ Q` lock screen
