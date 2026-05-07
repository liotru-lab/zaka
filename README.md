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
zaka rm <name>                remove an alias
zaka ls [filter]              list aliases (optionally filtered)
zaka show <name>              show what an alias maps to
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

### List aliases

```sh
$ zaka ls
fc='flutter clean && flutter pub get'
gp='git push origin HEAD'
gs='git status'
k='kubectl'

$ zaka ls git           # filter by substring
gp='git push origin HEAD'
gs='git status'
```

### Remove an alias

```sh
$ zaka rm gp
✓ removed: gp
```

### Inspect what an alias does

```sh
$ zaka show fc
alias fc='flutter clean && flutter pub get'
```

### Edit the file directly

```sh
$ zaka edit
```

Opens `~/.config/zaka/aliases.zsh` in `$EDITOR`. Save and exit — the file is automatically re-sourced.

---

## Why?

You probably already use shell aliases. The friction is everything *around* them: opening `~/.zshrc`, finding the right section, adding the line, saving, sourcing, hoping you didn't break something. For aliases you only realize you want *while you're in the middle of doing something else*, that friction is enough to skip them.

`zaka` removes the friction:

- **Add aliases at the speed of thought.** `zaka add gs "git status"` is one line. No editor, no scroll, no save-and-source.
- **Aliases are data, not config.** They live in their own file (`~/.config/zaka/aliases.zsh`), separate from your shell config. Easy to back up, easy to share, easy to nuke and start over.
- **Standard zsh `alias` underneath.** No custom syntax, no DSL. `zaka` is a thin layer that `alias`-es things and writes the file. If you uninstall `zaka` tomorrow, your aliases still work — just `source` the file directly.
- **Zero dependencies.** A single zsh file, ~100 lines. Install via curl, uninstall by deleting one file and one line in `.zshrc`.

---

## How it works

`zaka` maintains a single file at `~/.config/zaka/aliases.zsh` (overridable via `$ZAKA_FILE`). The file is just a list of `alias` statements:

```
alias gs='git status'
alias gp='git push origin HEAD'
alias k='kubectl'
```

When you start a new shell, `~/.zshrc` sources `zaka.zsh`, which sources the aliases file. When you run `zaka add`, it appends a new line to the file *and* runs `alias` directly so the change is immediate.

That's the whole trick. No daemon, no database, no plugin manager required.

---

## FAQ

**Does this work with bash?** Not currently — it's zsh-specific (uses zsh-style regex matching for input validation). Bash support is an open issue if there's interest.

**Does this work with fish?** No. Fish has its own `abbr` and `funcsave` for this purpose, which are arguably better integrated.

**What if I want to add a function, not an alias?** Use `zaka edit` and add it directly. `zaka` is intentionally scoped to simple aliases — multi-line functions are easier to manage in their own file.

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

The whole project is one ~100-line file. Easy to read, easy to modify, easy to send a fix.

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

