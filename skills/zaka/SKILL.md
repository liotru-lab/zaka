---
name: zaka
description: Use the zaka command to add, remove, list, and inspect zsh aliases and single-line functions without editing dotfiles. Trigger whenever the user wants to create a shortcut/alias for a command, save a frequently-typed command, remove or rename an existing alias, or list what aliases exist — instead of hand-editing ~/.zshrc.
allowed-tools: Bash(zaka *) Bash(zaka-pick *)
---

# zaka

[zaka](https://zaka.sh) is a single-file zsh alias manager. It writes plain
`alias` lines (and single-line functions) to `~/.config/zaka/aliases.zsh` and
activates them in the current shell — so prefer `zaka` over editing `~/.zshrc`
or sourcing files by hand.

**If `zaka` is missing** (`command -v zaka` fails), it isn't installed — tell the
user it installs with `curl -fsSL zaka.sh/install | sh`, and don't hand-edit
their dotfiles as a substitute.

## Adding an alias

Use `zaka add` for a plain alias (re-adding the same name replaces it):

```sh
zaka add gs "git status"
zaka add gp "git push origin HEAD"
```

Names must match `[a-zA-Z_][a-zA-Z0-9_-]*`. The value is everything after the
name, so quote it.

## Adding a single-line function

When the shortcut needs to take **arguments** (`$1`, `$@`, …), use `zaka fn`, not
`zaka add` — an alias can't take positional args. **Wrap the body in single
quotes** so the args expand at call time, not now:

```sh
zaka fn cdinto 'cd $1 && ls'          # correct — $1 expands when called
zaka fn mkcd 'mkdir -p $1 && cd $1'
```

Double quotes would expand `$1` immediately (to empty) — a common mistake.
Multi-line functions are out of scope; use `zaka edit` for those.

## Removing

```sh
zaka rm gp        # removes an alias or function by name
```

## Listing and inspecting

```sh
zaka ls           # list all aliases and functions
zaka ls git       # list only those matching "git"
zaka show gs      # show what one name maps to
```

## Other commands

```sh
zaka edit         # open the aliases file in $EDITOR, then reload
zaka reload       # re-source the aliases file
zaka file         # print the path to the aliases file
zaka version      # print the version
zaka help         # full usage
```

## Gotchas

- **A literal single quote breaks `zaka add`.** `add` stores the value wrapped in
  single quotes (`alias name='value'`), so a `'` in the command corrupts the
  line. `zaka fn` stores the body *unquoted* (`name() { body; }`), so balanced
  single quotes inside a function body are fine. If a command needs a literal
  `'`, prefer `zaka fn` (or `zaka edit`) over `zaka add`.
- Changes apply to the current shell immediately; other open shells pick them up
  on their next `zaka reload` or new session.
- Storage lives at `~/.config/zaka/aliases.zsh` — it's a normal sourced zsh file
  if you ever need to read it, but write to it through `zaka`, not by hand.
