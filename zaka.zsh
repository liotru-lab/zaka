#!/usr/bin/env zsh
# ============================================================================
#  zaka — manage your shell aliases without editing dotfiles
#
#  Project:  https://zaka.sh
#  Source:   https://github.com/liotru-lab/zaka
#  License:  MIT
#  Version:  0.1.0
#
#  Usage:
#    zaka add <name> <command>   Add or replace an alias
#    zaka rm  <name>             Remove an alias
#    zaka ls  [filter]           List aliases (optionally filtered)
#    zaka show <name>            Show what an alias maps to
#    zaka edit                   Open the aliases file in $EDITOR
#    zaka reload                 Re-source the aliases file
#    zaka file                   Print the path to the aliases file
#    zaka version                Print the version
#    zaka help                   Show this help
#
#  Install:
#    1. Save this file to ~/.local/share/zaka/zaka.zsh
#    2. Add to your ~/.zshrc:
#         source ~/.local/share/zaka/zaka.zsh
#    3. Reload your shell: exec zsh
#
#  Or via the install script:
#    curl -fsSL zaka.sh/install | sh
# ============================================================================

ZAKA_VERSION="0.1.0"
ZAKA_DIR="${ZAKA_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zaka}"
ZAKA_FILE="${ZAKA_FILE:-$ZAKA_DIR/aliases.zsh}"

# Ensure storage exists and source aliases on shell startup
[ -d "$ZAKA_DIR" ] || mkdir -p "$ZAKA_DIR"
[ -f "$ZAKA_FILE" ] || touch "$ZAKA_FILE"
source "$ZAKA_FILE"

zaka() {
  local cmd="$1"; shift 2>/dev/null

  case "$cmd" in
    add)
      # Usage: zaka add <name> <command...>
      local name="$1"; shift 2>/dev/null
      local value="$*"
      if [ -z "$name" ] || [ -z "$value" ]; then
        echo "usage: zaka add <name> <command>" >&2
        return 1
      fi
      # Validate alias name (alphanumeric, dash, underscore only)
      if ! [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
        echo "✗ invalid alias name: '$name' (use letters, digits, _, -)" >&2
        return 1
      fi
      # Remove any existing entry for the same name
      sed -i.bak "/^alias ${name}=/d" "$ZAKA_FILE" && rm -f "${ZAKA_FILE}.bak"
      # Append the new alias
      printf "alias %s='%s'\n" "$name" "$value" >> "$ZAKA_FILE"
      # Activate immediately in the current shell
      alias "${name}=${value}"
      echo "✓ added: ${name} → ${value}"
      ;;

    rm|remove|del|delete)
      # Usage: zaka rm <name>
      local name="$1"
      if [ -z "$name" ]; then
        echo "usage: zaka rm <name>" >&2
        return 1
      fi
      if grep -q "^alias ${name}=" "$ZAKA_FILE"; then
        sed -i.bak "/^alias ${name}=/d" "$ZAKA_FILE" && rm -f "${ZAKA_FILE}.bak"
        unalias "$name" 2>/dev/null
        echo "✓ removed: ${name}"
      else
        echo "✗ no alias named '${name}' in ${ZAKA_FILE}" >&2
        return 1
      fi
      ;;

    ls|list)
      # Usage: zaka ls [filter]
      local count
      count=$(grep -c '^alias ' "$ZAKA_FILE" 2>/dev/null || echo 0)
      if [ "$count" -eq 0 ]; then
        echo "no aliases yet — try: zaka add gs \"git status\""
        return 0
      fi
      if [ -n "$1" ]; then
        grep "^alias .*${1}" "$ZAKA_FILE" | sed 's/^alias //'
      else
        sed -n 's/^alias //p' "$ZAKA_FILE" | sort
      fi
      ;;

    show|cat)
      # Usage: zaka show <name>
      local name="$1"
      if [ -z "$name" ]; then
        echo "usage: zaka show <name>" >&2
        return 1
      fi
      grep "^alias ${name}=" "$ZAKA_FILE" || {
        echo "✗ no alias named '${name}'" >&2
        return 1
      }
      ;;

    edit)
      # Usage: zaka edit
      "${EDITOR:-vi}" "$ZAKA_FILE"
      source "$ZAKA_FILE"
      echo "✓ reloaded"
      ;;

    reload)
      # Usage: zaka reload
      source "$ZAKA_FILE"
      local n
      n=$(grep -c '^alias ' "$ZAKA_FILE")
      echo "✓ reloaded ${n} alias$([ "$n" = "1" ] || echo 'es')"
      ;;

    file|path)
      # Usage: zaka file
      echo "$ZAKA_FILE"
      ;;

    version|--version|-v)
      echo "zaka ${ZAKA_VERSION}"
      ;;

    ""|help|--help|-h)
      cat <<EOF
zaka ${ZAKA_VERSION} — manage your shell aliases without editing dotfiles

usage:
  zaka add <name> <command>   add or replace an alias
  zaka rm <name>              remove an alias
  zaka ls [filter]            list aliases (optionally filtered)
  zaka show <name>            show what an alias maps to
  zaka edit                   open the aliases file in \$EDITOR
  zaka reload                 re-source the aliases file
  zaka file                   print the path to the aliases file
  zaka version                print the version

examples:
  zaka add gs "git status"
  zaka add gp "git push origin HEAD"
  zaka add k kubectl
  zaka ls git
  zaka rm gp

storage: ${ZAKA_FILE}
docs:    https://zaka.sh
EOF
      ;;

    *)
      echo "✗ unknown command: '${cmd}'. try: zaka help" >&2
      return 1
      ;;
  esac
}

# Optional: fzf-powered interactive remove (only defined if fzf is present)
if command -v fzf >/dev/null 2>&1; then
  zaka-pick() {
    local choice
    choice=$(sed -n 's/^alias //p' "$ZAKA_FILE" | fzf --prompt="zaka › " --height=40% --reverse) || return
    [ -n "$choice" ] && echo "$choice"
  }
fi
