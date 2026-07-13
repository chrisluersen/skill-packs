# Zellij Keybinding Reference — Custom Config (clear-defaults=true)

user's zellij config at `~/AppData/Local/hermes\AppData\Roaming\Zellij\config\config.kdl` uses `keybinds clear-defaults=true` — ALL keybindings are custom. This file is the distilled reference from the actual config, verified 2026-06-19.

## Mode Diagram

```
Normal                 (default mode, waiting for mode switch)
  │
  ├─ Ctrl+p  ───▶  Pane mode     (split, close, focus, fullscreen)
  ├─ Ctrl+t  ───▶  Tab mode      (new/close/switch tabs)
  ├─ Ctrl+s  ───▶  Scroll mode   (scroll pane history, search)
  ├─ Ctrl+o  ───▶  Session mode  (session manager, layout, settings)
  ├─ Ctrl+n  ───▶  Resize mode   (resize panes)
  ├─ Ctrl+h  ───▶  Move mode     (move panes around)
  ├─ Ctrl+b  ───▶  Tmux mode     (tmux-compatible bindings)
  └─ Ctrl+g  ───▶  Locked mode   (keyboard passthrough)
```

Once in a mode, press the mode trigger again or `esc`/`enter` to return to Normal.

## Alt Shortcuts — Available From ALL Unlocked Modes

These work in Normal, Pane, Tab, Scroll, Resize, Move, Session, and Tmux modes:

| Shortcut | Action |
|----------|--------|
| `Alt + h/l` | Move focus left/right (wraps tabs at edges) |
| `Alt + j/k` | Move focus down/up |
| `Alt + [+]` | Resize increase |
| `Alt + [-]` | Resize decrease |
| `Alt + [=]` | Resize increase |
| `Alt + [` | Previous swap layout |
| `Alt + ]` | Next swap layout |
| `Alt + f` | Toggle floating panes |
| `Alt + n` | New pane |
| `Alt + i` | Move tab left |
| `Alt + o` | Move tab right |
| `Alt + p` | Toggle pane in group |
| `Alt + Shift + p` | Toggle group marking |
| `Ctrl + q` | Quit zellij |

## Pane Mode (Ctrl+p)

| Key | Action |
|-----|--------|
| `h/j/k/l` or arrows | Move focus |
| `r` | Split pane right |
| `d` | Split pane down |
| `n` | New pane (default direction) |
| `s` | Stacked pane (overlapping) |
| `x` | Close focus |
| `f` | Toggle fullscreen |
| `p` | Switch focus (cycle) |
| `c` | Rename pane |
| `e` | Toggle pane embed/floating |
| `i` | Toggle pane pin |
| `w` | Toggle floating panes |
| `z` | Toggle pane frames |
| `Ctrl + p` | Return to normal |

## Tab Mode (Ctrl+t)

| Key | Action |
|-----|--------|
| `h/j/k/l` or arrows | Switch tabs |
| `n` | New tab |
| `x` | Close tab |
| `1`–`9` | Go to tab by number |
| `r` | Rename tab |
| `b` | Break pane into its own tab |
| `[` / `]` | Break pane left / right |
| `s` | Toggle sync (all panes same input) |
| `tab` | Toggle current/last tab |
| `Ctrl + t` | Return to normal |

## Scroll Mode (Ctrl+s)

| Key | Action |
|-----|--------|
| `j/k` or arrows | Scroll up/down by line |
| `u/d` | Half page up/down |
| `Ctrl + b/f` | Page up/down |
| `s` | Enter search mode |
| `e` | Edit scrollback in $EDITOR |
| `Ctrl + s` or `esc` | Return to normal |

### Search (from scroll mode, press `s`)

| Key | Action |
|-----|--------|
| `n` | Next match |
| `p` | Previous match |
| `c` | Toggle case sensitivity |
| `w` | Toggle wrap |
| `o` | Toggle whole word |
| `enter` | Confirm search |
| `esc` | Back to scroll |
| `Ctrl + c` | Back to scroll |

## Session Mode (Ctrl+o)

| Key | Action |
|-----|--------|
| `s` | Launch session manager |
| `w` | Launch session manager plugin |
| `l` | Launch layout manager |
| `c` | Launch configuration editor |
| `p` | Launch plugin manager |
| `a` | Launch about dialog |
| `d` | Detach |
| `Ctrl + o` | Return to normal |

## Resize Mode (Ctrl+n)

| Key | Action |
|-----|--------|
| `h/j/k/l` or arrows | Resize in that direction |
| `+` / `=` | Increase size |
| `-` | Decrease size |
| `H/J/K/L` (shift) | DECREASE in that direction |
| `Ctrl + n` | Return to normal |

## Move Mode (Ctrl+h)

| Key | Action |
|-----|--------|
| `h/j/k/l` or arrows | Move pane in that direction |
| `n` | Move pane to next position |
| `p` | Move pane backwards |
| `tab` | Move pane to next position |
| `Ctrl + h` | Return to normal |

## Tmux Mode (Ctrl+b)

Tmux-compatible keybindings for users switching from tmux:

| Key | Action |
|-----|--------|
| `"` | New pane down (split horizontal in tmux terms) |
| `%` | New pane right (split vertical in tmux terms) |
| `h/j/k/l` | Move focus |
| `n` | Next tab |
| `p` | Previous tab |
| `,` | Rename tab |
| `[` | Enter scroll mode |
| `c` | New tab |
| `o` | Focus next pane |
| `z` | Toggle fullscreen |
| `space` | Next swap layout |
| `Ctrl + b` | Send Ctrl+b to pane |
| `d` | Detach |

## Locked Mode (Ctrl+g)

Everything passes through to the focused pane. Press `Ctrl + g` to return to normal.

## Shared Mappings

These work in the listed modes:

| Shortcut | Modes | Action |
|----------|-------|--------|
| `Ctrl + g` | Shared except locked | Lock |
| `Ctrl + o` | Shared except locked, session | Session mode |
| `Ctrl + b` | Shared except locked, scroll, search, tmux | Tmux mode |
| `Ctrl + s` | Shared except locked, scroll, search | Scroll mode |
| `Ctrl + t` | Shared except locked, tab | Tab mode |
| `Ctrl + p` | Shared except locked, pane | Pane mode |
| `Ctrl + n` | Shared except locked, resize | Resize mode |
| `Ctrl + h` | Shared except locked, move | Move mode |
| `enter` | Shared except normal, locked, entersearch | Return to normal |
| `esc` | Shared except normal, locked, entersearch, renametab, renamepane | Return to normal |
| `x` | Pane, tmux | Close focus |
| `d` | Session, tmux | Detach |
| `PageDown/PageUp` | Scroll, search | Page scroll down/up |
| `left/down/up/right` | Scroll, search | Scroll/page direction |

## Config Source

File: `~/AppData/Local/hermes\AppData\Roaming\Zellij\config\config.kdl`
