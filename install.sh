#!/bin/sh
# ============================================================================
#  zaka install script
#  Usage:   curl -fsSL zaka.sh/install | sh
#  Source:  https://github.com/liotru-lab/zaka
# ============================================================================

set -eu

# ---- Configuration ---------------------------------------------------------

ZAKA_REPO="${ZAKA_REPO:-liotru-lab/zaka}"
ZAKA_REF="${ZAKA_REF:-main}"
ZAKA_URL="${ZAKA_URL:-https://raw.githubusercontent.com/${ZAKA_REPO}/${ZAKA_REF}/zaka.zsh}"
ZAKA_INSTALL_DIR="${ZAKA_INSTALL_DIR:-$HOME/.local/share/zaka}"
ZAKA_INSTALL_FILE="${ZAKA_INSTALL_DIR}/zaka.zsh"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

# zenv — sibling tool for environment variables. Sourced from .zshenv so the
# vars reach interactive shells, scripts, and child processes.
ZENV_URL="${ZENV_URL:-https://raw.githubusercontent.com/${ZAKA_REPO}/${ZAKA_REF}/zenv.zsh}"
ZENV_INSTALL_DIR="${ZENV_INSTALL_DIR:-$HOME/.local/share/zenv}"
ZENV_INSTALL_FILE="${ZENV_INSTALL_DIR}/zenv.zsh"
ZSHENV="${ZDOTDIR:-$HOME}/.zshenv"

# Claude Code skills (optional). Installed when Claude Code is detected, unless
# ZAKA_NO_SKILL=1. Set ZAKA_SKILL=1 to force. One skill per tool (zaka, zenv).
ZAKA_SKILLS_BASE="${ZAKA_SKILLS_BASE:-https://raw.githubusercontent.com/${ZAKA_REPO}/${ZAKA_REF}/skills}"
ZAKA_SKILLS_DIR="${ZAKA_SKILLS_DIR:-$HOME/.claude/skills}"

# ---- Output helpers --------------------------------------------------------

# ANSI colors only if stdout is a TTY
if [ -t 1 ]; then
  R='\033[0;31m'   # red
  G='\033[0;32m'   # green
  Y='\033[0;33m'   # yellow
  D='\033[2m'      # dim
  N='\033[0m'      # reset
else
  R=''; G=''; Y=''; D=''; N=''
fi

ok()    { printf '%b✓%b %s\n'  "$G" "$N" "$1"; }
info()  { printf '%b›%b %s\n'  "$D" "$N" "$1"; }
warn()  { printf '%b!%b %s\n'  "$Y" "$N" "$1"; }
fail()  { printf '%b✗%b %s\n'  "$R" "$N" "$1" >&2; exit 1; }

# ---- Pre-flight checks -----------------------------------------------------

# zsh required (the tool itself is zsh-specific)
if ! command -v zsh >/dev/null 2>&1; then
  fail "zsh is not installed. zaka is a zsh tool — install zsh first, then re-run this script."
fi

# Need curl OR wget for the download
if command -v curl >/dev/null 2>&1; then
  DOWNLOAD="curl -fsSL"
elif command -v wget >/dev/null 2>&1; then
  DOWNLOAD="wget -qO-"
else
  fail "need either curl or wget to download zaka."
fi

# ---- Banner ----------------------------------------------------------------

printf '\n'
printf '  %bzaka%b + %bzenv%b — manage aliases & env vars without editing dotfiles\n' "$G" "$N" "$G" "$N"
printf '  %bhttps://zaka.sh%b\n' "$D" "$N"
printf '\n'

# ---- Install ---------------------------------------------------------------

# 1. Make the install directory
info "Creating ${ZAKA_INSTALL_DIR}"
mkdir -p "$ZAKA_INSTALL_DIR"

# 2. Download zaka.zsh
info "Downloading zaka.zsh"
if ! $DOWNLOAD "$ZAKA_URL" > "$ZAKA_INSTALL_FILE.tmp"; then
  rm -f "$ZAKA_INSTALL_FILE.tmp"
  fail "Download failed from $ZAKA_URL"
fi

# Sanity-check the file (must contain the function definition)
if ! grep -q '^zaka()' "$ZAKA_INSTALL_FILE.tmp"; then
  rm -f "$ZAKA_INSTALL_FILE.tmp"
  fail "Downloaded file does not look like zaka. Aborting."
fi

mv "$ZAKA_INSTALL_FILE.tmp" "$ZAKA_INSTALL_FILE"
chmod +x "$ZAKA_INSTALL_FILE"
ok "Installed to ${ZAKA_INSTALL_FILE}"

# 3. Add source line to .zshrc (idempotent — only adds if missing)
SOURCE_LINE="source \"${ZAKA_INSTALL_FILE}\""

if [ ! -f "$ZSHRC" ]; then
  info "Creating $ZSHRC"
  touch "$ZSHRC"
fi

if grep -Fq "zaka/zaka.zsh" "$ZSHRC" 2>/dev/null; then
  ok "Source line already present in $ZSHRC"
else
  {
    printf '\n# zaka — https://zaka.sh\n'
    printf '%s\n' "$SOURCE_LINE"
  } >> "$ZSHRC"
  ok "Added source line to $ZSHRC"
fi

# 4. Download zenv.zsh (sibling tool — environment variables)
info "Downloading zenv.zsh"
mkdir -p "$ZENV_INSTALL_DIR"
if ! $DOWNLOAD "$ZENV_URL" > "$ZENV_INSTALL_FILE.tmp"; then
  rm -f "$ZENV_INSTALL_FILE.tmp"
  fail "Download failed from $ZENV_URL"
fi

# Sanity-check the file (must contain the function definition)
if ! grep -q '^zenv()' "$ZENV_INSTALL_FILE.tmp"; then
  rm -f "$ZENV_INSTALL_FILE.tmp"
  fail "Downloaded file does not look like zenv. Aborting."
fi

mv "$ZENV_INSTALL_FILE.tmp" "$ZENV_INSTALL_FILE"
chmod +x "$ZENV_INSTALL_FILE"
ok "Installed to ${ZENV_INSTALL_FILE}"

# 5. Add source line to .zshenv (idempotent — env vars must load for all shells)
ZENV_SOURCE_LINE="source \"${ZENV_INSTALL_FILE}\""

if [ ! -f "$ZSHENV" ]; then
  info "Creating $ZSHENV"
  touch "$ZSHENV"
fi

if grep -Fq "zenv/zenv.zsh" "$ZSHENV" 2>/dev/null; then
  ok "Source line already present in $ZSHENV"
else
  {
    printf '\n# zenv — https://zaka.sh\n'
    printf '%s\n' "$ZENV_SOURCE_LINE"
  } >> "$ZSHENV"
  ok "Added source line to $ZSHENV"
fi

# 6. Install the Claude Code skills (optional, opt-out) — one per tool.
#    Lets Claude reach for `zaka`/`zenv` instead of hand-editing dotfiles.
#    Skipped silently when Claude Code isn't detected; never aborts the install.
if [ "${ZAKA_NO_SKILL:-0}" = "1" ]; then
  info "Skipping Claude Code skills (ZAKA_NO_SKILL=1)"
elif [ "${ZAKA_SKILL:-0}" = "1" ] || command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
  for skill in zaka zenv; do
    skill_dir="${ZAKA_SKILLS_DIR}/${skill}"
    info "Installing Claude Code skill: ${skill}"
    mkdir -p "$skill_dir"
    if $DOWNLOAD "${ZAKA_SKILLS_BASE}/${skill}/SKILL.md" > "$skill_dir/SKILL.md.tmp" 2>/dev/null \
       && grep -q "^name: ${skill}" "$skill_dir/SKILL.md.tmp"; then
      mv "$skill_dir/SKILL.md.tmp" "$skill_dir/SKILL.md"
      ok "Installed skill to ${skill_dir}/SKILL.md"
    else
      rm -f "$skill_dir/SKILL.md.tmp"
      warn "Could not install the ${skill} skill — skipped (the tool itself is fine)"
    fi
  done
else
  info "Claude Code not detected — skipping skills (set ZAKA_SKILL=1 to force)"
fi

# ---- Done ------------------------------------------------------------------

printf '\n'
ok "Installation complete."
printf '\n'
printf '  Next steps:\n'
printf '    %bexec zsh%b              %b# reload your shell%b\n' "$G" "$N" "$D" "$N"
printf '    %bzaka help%b             %b# see what zaka can do%b\n' "$G" "$N" "$D" "$N"
printf '    %bzaka add gs "git status"%b   %b# add your first alias%b\n' "$G" "$N" "$D" "$N"
  printf '    %bzenv set EDITOR vim%b        %b# set an env var (reaches scripts too)%b\n' "$G" "$N" "$D" "$N"
printf '\n'
