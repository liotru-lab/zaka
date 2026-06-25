---
name: zenv
description: Use the zenv command to set, remove, list, and inspect environment variables without editing dotfiles. Trigger whenever the user wants to set an env var (e.g. EDITOR, GOPATH, JAVA_OPTS), make a value available to their shell and scripts, remove or change an existing variable, or list what's set — instead of hand-editing ~/.zshenv.
allowed-tools: Bash(zenv *)
---

# zenv

[zenv](https://zaka.sh) is a single-file zsh tool — zaka's sibling — that manages
`export` environment variables. It writes `export NAME='value'` lines to
`~/.config/zenv/env.zsh` and activates them in the current shell. Because it's
sourced from `~/.zshenv`, the variables reach interactive shells, scripts, and
child processes in any language (bash, python, …) — so prefer `zenv` over editing
`~/.zshenv` by hand.

**Why you're reading this / what to do:** you have this skill because the user
manages their environment variables with `zenv`. When they describe a variable to
set, a value to make available, or a variable to change or remove, respond with
the exact `zenv` command — run it if you can execute shell commands (e.g. in
Claude Code), otherwise give them the command to paste. Produce the command;
don't ask what to do with the skill, and don't fall back to editing `~/.zshenv`
by hand.

**If `zenv` is missing** (`command -v zenv` fails), it isn't installed — tell the
user it installs with `curl -fsSL zaka.sh/install | sh` (the same installer ships
zaka and zenv).

**Assume zsh on macOS** (BSD userland, not Linux/GNU), same as zaka.

## Setting a variable

```sh
zenv set EDITOR vim
zenv set GOPATH "$HOME/go"
zenv set JAVA_OPTS "-Xmx2g -Dfile.encoding=UTF-8"
```

Re-setting the same name replaces it. Names must match `[A-Za-z_][A-Za-z0-9_]*` —
letters, digits, underscore; **no hyphens** (env-var rules).

## Removing

```sh
zenv unset GOPATH
```

## Listing and inspecting

```sh
zenv ls            # list all variables
zenv ls JAVA       # list only those matching "JAVA"
zenv get EDITOR    # show what one variable is set to
```

## Other commands

```sh
zenv edit          # open the env file in $EDITOR, then reload
zenv reload        # re-source the env file
zenv file          # print the path to the env file
zenv version       # print the version
zenv help          # full usage
```

## Gotchas

- **A literal single quote breaks `zenv set`.** Values are stored
  single-quote-wrapped (`export NAME='value'`), so a `'` in the value corrupts the
  line — use `zenv edit` for those.
- **Variables reach child processes** — a `zenv set` value is inherited by every
  script/program launched from a shell, so set deliberately.
- Storage lives at `~/.config/zenv/env.zsh` — a normal sourced zsh file, but write
  to it through `zenv`, not by hand.
- For **aliases and single-line functions** (not env vars), use the sibling tool
  `zaka`.
