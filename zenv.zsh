#!/usr/bin/env zsh
# ============================================================================
#  zenv — manage environment variables without editing dotfiles
#
#  Project:  https://zaka.sh
#  Source:   https://github.com/liotru-lab/zaka
#  License:  MIT
#  Version:  0.1.0
#
#  Sibling to zaka. Where zaka manages aliases for interactive shells, zenv
#  manages `export` environment variables. It is sourced from ~/.zshenv, so the
#  variables reach every shell — interactive AND non-interactive — and are
#  inherited by child processes (scripts in any language: zsh, bash, python…).
#
#  Usage:
#    zenv set <NAME> <value>    Set or replace an environment variable
#    zenv unset <NAME>          Remove an environment variable
#    zenv ls  [filter]          List variables (optionally filtered)
#    zenv get <NAME>            Show what a variable is set to
#    zenv edit                  Open the env file in $EDITOR
#    zenv reload                Re-source the env file
#    zenv file                  Print the path to the env file
#    zenv version               Print the version
#    zenv help                  Show this help
#
#  Install:
#    1. Save this file to ~/.local/share/zenv/zenv.zsh
#    2. Add to your ~/.zshenv:
#         source ~/.local/share/zenv/zenv.zsh
#    3. Reload your shell: exec zsh
#
#  Or via the install script:
#    curl -fsSL zaka.sh/install | sh
# ============================================================================

ZENV_VERSION="0.1.0"
ZENV_DIR="${ZENV_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zenv}"
ZENV_FILE="${ZENV_FILE:-$ZENV_DIR/env.zsh}"

# Ensure storage exists and source variables on shell startup
[ -d "$ZENV_DIR" ] || mkdir -p "$ZENV_DIR"
[ -f "$ZENV_FILE" ] || touch "$ZENV_FILE"
source "$ZENV_FILE"

zenv() {
  local cmd="$1"; shift 2>/dev/null

  case "$cmd" in
    set)
      # Usage: zenv set <NAME> <value...>
      local name="$1"; shift 2>/dev/null
      local value="$*"
      if [ -z "$name" ] || [ -z "$value" ]; then
        echo "usage: zenv set <NAME> <value>" >&2
        return 1
      fi
      # Environment variable names: letters, digits, underscore; no hyphens
      if ! [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "✗ invalid variable name: '$name' (use letters, digits, _)" >&2
        return 1
      fi
      # Remove any existing entry for the same name
      sed -i.bak -E "/^export ${name}=/d" "$ZENV_FILE" && rm -f "${ZENV_FILE}.bak"
      # Append the new export
      printf "export %s='%s'\n" "$name" "$value" >> "$ZENV_FILE"
      # Activate immediately in the current shell
      export "${name}=${value}"
      echo "✓ set: ${name}=${value}"
      ;;

    unset|rm|remove|del|delete)
      # Usage: zenv unset <NAME>
      local name="$1"
      if [ -z "$name" ]; then
        echo "usage: zenv unset <NAME>" >&2
        return 1
      fi
      if grep -qE "^export ${name}=" "$ZENV_FILE"; then
        sed -i.bak -E "/^export ${name}=/d" "$ZENV_FILE" && rm -f "${ZENV_FILE}.bak"
        unset "$name" 2>/dev/null
        echo "✓ unset: ${name}"
      else
        echo "✗ no variable named '${name}' in ${ZENV_FILE}" >&2
        return 1
      fi
      ;;

    ls|list)
      # Usage: zenv ls [filter]
      local count
      count=$(grep -cE "^export " "$ZENV_FILE" 2>/dev/null || echo 0)
      if [ "$count" -eq 0 ]; then
        echo "no variables yet — try: zenv set EDITOR vim"
        return 0
      fi
      if [ -n "$1" ]; then
        grep -E "^export " "$ZENV_FILE" \
          | grep "${1}" \
          | sed 's/^export //'
      else
        grep -E "^export " "$ZENV_FILE" \
          | sed 's/^export //' \
          | sort
      fi
      ;;

    get|show|cat)
      # Usage: zenv get <NAME>
      local name="$1"
      if [ -z "$name" ]; then
        echo "usage: zenv get <NAME>" >&2
        return 1
      fi
      grep -E "^export ${name}=" "$ZENV_FILE" | sed 's/^export //' || {
        echo "✗ no variable named '${name}'" >&2
        return 1
      }
      ;;

    edit)
      # Usage: zenv edit
      "${EDITOR:-vi}" "$ZENV_FILE"
      source "$ZENV_FILE"
      echo "✓ reloaded"
      ;;

    reload)
      # Usage: zenv reload
      source "$ZENV_FILE"
      local n
      n=$(grep -cE "^export " "$ZENV_FILE")
      echo "✓ reloaded ${n} variable$([ "$n" = "1" ] || echo 's')"
      ;;

    file|path)
      # Usage: zenv file
      echo "$ZENV_FILE"
      ;;

    version|--version|-v)
      echo "zenv ${ZENV_VERSION}"
      ;;

    ""|help|--help|-h)
      cat <<EOF
zenv ${ZENV_VERSION} — manage environment variables without editing dotfiles

usage:
  zenv set <NAME> <value>    set or replace an environment variable
  zenv unset <NAME>          remove an environment variable
  zenv ls [filter]           list variables (optionally filtered)
  zenv get <NAME>            show what a variable is set to
  zenv edit                  open the env file in \$EDITOR
  zenv reload                re-source the env file
  zenv file                  print the path to the env file
  zenv version               print the version

examples:
  zenv set EDITOR vim
  zenv set GOPATH "\$HOME/go"
  zenv set JAVA_OPTS "-Xmx2g -Dfile.encoding=UTF-8"
  zenv ls JAVA
  zenv unset GOPATH

note:
  zenv is sourced from ~/.zshenv, so variables reach interactive shells, scripts,
  and child processes (bash, python, …) — not just zsh. Values are stored
  single-quote-wrapped, so a literal single quote in a value needs 'zenv edit'.

storage: ${ZENV_FILE}
docs:    https://zaka.sh
EOF
      ;;

    *)
      echo "✗ unknown command: '${cmd}'. try: zenv help" >&2
      return 1
      ;;
  esac
}
