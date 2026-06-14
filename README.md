# zaka

> Manage your shell aliases without editing dotfiles.

`zaka` is a single-file zsh tool for adding, removing, and listing shell aliases from the command line. No more opening `~/.zshrc` to add a one-line shortcut, no more wondering whether you remembered to `source` it.

```
$ zaka add gs "git status"
✓ added: gs → git status

$ gs
On branch main
nothing to commit, working tree clean
```

That's it. The alias is live in your current shell and persisted across new ones.

---

## Install

```sh
curl -fsSL zaka.sh/install | sh
```

The installer drops `zaka.zsh` into `~/.local/share/zaka/` and adds a single `source` line to your `~/.zshrc`. Reload your shell (`exec zsh`) and run `zaka help`.

If [Claude Code](https://claude.com/claude-code) is detected, the installer also drops in a small [skill](#claude-code-skill) so Claude reaches for `zaka` instead of editing your dotfiles. Set `ZAKA_NO_SKILL=1` to skip it.

**Manual install** if you'd rather not pipe `curl` to `sh`:

```sh
mkdir -p ~/.local/share/zaka
curl -fsSL https://zaka.sh/zaka.zsh -o ~/.local/share/zaka/zaka.zsh
echo 'source ~/.local/share/zaka/zaka.zsh' >> ~/.zshrc
exec zsh
```

**Homebrew** is on the roadmap. For now use the install script or manual method.

---

## Usage

```
zaka add <name> <command>     add or replace an alias
zaka fn  <name> <command>     add or replace a single-line function
zaka rm <name>                remove an alias or function
zaka ls [filter]              list aliases and functions (optionally filtered)
zaka show <name>              show what an alias or function maps to
zaka edit                     open the aliases file in $EDITOR
zaka reload                   re-source the aliases file
zaka file                     print the path to the aliases file
zaka version                  print the version
zaka help                     show help
```

### Add an alias

```sh
zaka add gs "git status"
zaka add gp "git push origin HEAD"
zaka add k kubectl
zaka add fc "flutter clean && flutter pub get"
```

The alias activates immediately in your current shell — no `source` step, no new terminal window.

### Add a function

For commands that need to accept arguments, use `zaka fn`:

```sh
zaka fn mycommand 'command -switch1 -switch2 $1'
zaka fn deploy 'rsync -av $1 user@host:$2'
zaka fn cdls 'cd $1 && ls'
```

Use single quotes to prevent the shell from expanding `$1`, `$2`, `$@` before zaka stores them:

```sh
zaka fn greet 'echo "hello, $1"'   # correct: $1 expands at call time
zaka fn greet "echo 'hello, $1'"   # wrong: $1 expands now (probably empty)
```

Call the function like any shell command:

```sh
mycommand /some/dir
deploy ./build /var/www
cdls ~/projects
```

For multi-line functions, use `zaka edit` and write them directly into the aliases file.

### List aliases and functions

```sh
$ zaka ls
cdls() { cd $1 && ls; }
fc='flutter clean && flutter pub get'
gp='git push origin HEAD'
gs='git status'
k='kubectl'

$ zaka ls git           # filter by substring
gp='git push origin HEAD'
gs='git status'
```

### Remove an alias or function

```sh
$ zaka rm gp
✓ removed: gp
```

Works for both aliases and functions.

### Inspect what an alias or function does

```sh
$ zaka show mycommand
mycommand() { command -switch1 -switch2 $1; }
```

### Edit the file directly

```sh
$ zaka edit
```

Opens `~/.config/zaka/aliases.zsh` in `$EDITOR`. Save and exit — the file is automatically re-sourced.

---

## Claude Code skill

zaka ships with a [Claude Code](https://claude.com/claude-code) skill so that when you ask Claude to "make a `gs` alias for `git status`", it runs `zaka add gs "git status"` instead of hand-editing your `~/.zshrc`. The skill is plain Markdown (`skills/zaka/SKILL.md`) — usable by any assistant that reads skill files, and harmless if you don't use one.

You get it three ways:

- **With the install script** — auto-installed to `~/.claude/skills/zaka/` when Claude Code is detected. Disable with `ZAKA_NO_SKILL=1`; force with `ZAKA_SKILL=1`.
- **As a plugin** — from the `liotru-lab` Claude Code marketplace:

  ```
  /plugin marketplace add liotru-lab/plugins
  /plugin install zaka@liotru-lab
  ```

- **Manually** — copy `skills/zaka/SKILL.md` from this repo to `~/.claude/skills/zaka/SKILL.md`.

The skill only *uses* zaka; it doesn't replace it. Install the CLI (above) too.

---

## Why?

You probably already use shell aliases. The friction is everything *around* them: opening `~/.zshrc`, finding the right section, adding the line, saving, sourcing, hoping you didn't break something. For aliases you only realize you want *while you're in the middle of doing something else*, that friction is enough to skip them.

`zaka` removes the friction:

- **Add aliases at the speed of thought.** `zaka add gs "git status"` is one line. No editor, no scroll, no save-and-source.
- **Functions too, for when you need arguments.** `zaka fn deploy 'rsync -av $1 user@host:$2'` — same workflow, for the cases where a plain alias isn't enough.
- **Aliases are data, not config.** They live in their own file (`~/.config/zaka/aliases.zsh`), separate from your shell config. Easy to back up, easy to share, easy to nuke and start over.
- **Standard zsh `alias` and functions underneath.** No custom syntax, no DSL. `zaka` writes a plain zsh file. If you uninstall `zaka` tomorrow, your aliases and functions still work — just `source` the file directly.
- **Zero dependencies.** A single zsh file, ~150 lines. Install via curl, uninstall by deleting one file and one line in `.zshrc`.

---

## How it works

`zaka` maintains a single file at `~/.config/zaka/aliases.zsh` (overridable via `$ZAKA_FILE`). The file is plain zsh — `alias` statements and single-line functions:

```
alias gs='git status'
alias gp='git push origin HEAD'
alias k='kubectl'
mycommand() { command -switch1 -switch2 $1; }
```

When you start a new shell, `~/.zshrc` sources `zaka.zsh`, which sources the aliases file. When you run `zaka add` or `zaka fn`, it appends a new line to the file *and* defines it directly in the current shell so the change is immediate.

That's the whole trick. No daemon, no database, no plugin manager required.

---

## FAQ

**Does this work with bash?** Not currently — it's zsh-specific (uses zsh-style regex matching for input validation). Bash support is an open issue if there's interest.

**Does this work with fish?** No. Fish has its own `abbr` and `funcsave` for this purpose, which are arguably better integrated.

**What if I want to add a multi-line function?** Use `zaka edit` and add it directly. `zaka fn` is intentionally scoped to single-line functions — anything more complex is easier to manage in an editor.

**Does this conflict with Oh My Zsh's git aliases / similar plugins?** No. Plugin-defined aliases are loaded into your shell from the plugin file; `zaka`'s aliases are loaded from `~/.config/zaka/aliases.zsh`. They coexist. If you `zaka add gs "..."` and you also have OMZ's `gs` alias, the last-loaded one wins (typically yours).

**How do I migrate my existing aliases from `.zshrc`?** Move them to `~/.config/zaka/aliases.zsh`:

```sh
zaka file   # prints the path
zaka edit   # paste your aliases here
```

Then delete them from `.zshrc`. They'll behave identically.

---

## Configuration

Override defaults via environment variables in `~/.zshrc` *before* the `source` line:

```sh
export ZAKA_DIR="$HOME/.dotfiles/zaka"      # custom storage directory
export ZAKA_FILE="$HOME/aliases-work.zsh"   # custom file (overrides ZAKA_DIR)
source ~/.local/share/zaka/zaka.zsh
```

Useful for syncing aliases across machines via your dotfiles repo, or keeping per-context alias sets (`~/.zshrc-work`, `~/.zshrc-personal`).

---

## Uninstall

```sh
rm -rf ~/.local/share/zaka
rm -rf ~/.config/zaka              # only if you want to delete your aliases too
sed -i.bak '/zaka\/zaka.zsh/d' ~/.zshrc
exec zsh
```

---

## Contributing

Issues and PRs welcome at <https://github.com/liotru-lab/zaka>.

The whole project is one ~150-line file. Easy to read, easy to modify, easy to send a fix.

---

## License

MIT. See [LICENSE](LICENSE).

---

## Acknowledgments

The code, install script, and this README were drafted with assistance from [Claude](https://claude.ai), then reviewed, edited, and shipped by a human. Direction, naming, and design decisions are mine.

---

<p align="center">
  <sub>Built by <a href="https://github.com/liotru-lab">@liotru-lab</a> · <a href="https://zaka.sh">zaka.sh</a> · co-written with <a href="https://claude.ai">Claude</a></sub>
</p>
