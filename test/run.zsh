#!/usr/bin/env zsh
# ============================================================================
#  test/run.zsh — zero-dependency test suite for zaka and zenv.
#
#  Exercises both tools and the installer against throwaway temp dirs and
#  asserts on their behavior + file state. No framework, no docker, no network
#  — just zsh. It tests the platform you run it on, so run it on macOS before a
#  release to catch BSD-vs-GNU issues (`sed -i.bak`, etc.).
#
#    zsh test/run.zsh        # exits 0 if all pass, 1 otherwise
# ============================================================================

REPO="${0:A:h:h}"
PASS=0 FAIL=0

_ok()  { print -r -- "  ✓ $1"; (( PASS++ )) }
_bad() { print -r -- "  ✗ $1"; (( FAIL++ )) }

assert_eq()      { if [[ "$2" == "$3" ]]; then _ok "$1"; else _bad "$1"; print -r -- "      expected [$2]  got [$3]"; fi }
assert_contains(){ if [[ "$3" == *"$2"* ]]; then _ok "$1"; else _bad "$1"; print -r -- "      [$3] lacks [$2]"; fi }
assert_rc()      { if [[ "$2" == "$3" ]]; then _ok "$1"; else _bad "$1 (rc want $2 got $3)"; fi }
assert_grep()    { if grep -qE -- "$2" "$3" 2>/dev/null; then _ok "$1"; else _bad "$1 (/$2/ not in $3)"; fi }
assert_no_grep() { if grep -qE -- "$2" "$3" 2>/dev/null; then _bad "$1 (/$2/ still in $3)"; else _ok "$1"; fi }
assert_fgrep()   { if grep -qF -- "$2" "$3" 2>/dev/null; then _ok "$1"; else _bad "$1 ('$2' not in $3)"; fi }
assert_nofgrep() { if grep -qF -- "$2" "$3" 2>/dev/null; then _bad "$1 ('$2' still in $3)"; else _ok "$1"; fi }
assert_isfile()  { if [[ -f "$2" ]]; then _ok "$1"; else _bad "$1 ($2 missing)"; fi }
section()        { print -r -- ""; print -r -- "== $1 ==" }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---- lint ------------------------------------------------------------------
section "lint"
if zsh -n "$REPO/zaka.zsh"   2>/dev/null; then _ok "zaka.zsh parses";   else _bad "zaka.zsh syntax"; fi
if zsh -n "$REPO/zenv.zsh"   2>/dev/null; then _ok "zenv.zsh parses";   else _bad "zenv.zsh syntax"; fi
if sh  -n "$REPO/install.sh" 2>/dev/null; then _ok "install.sh parses (POSIX)"; else _bad "install.sh syntax"; fi

# ---- zaka ------------------------------------------------------------------
section "zaka — aliases & functions"
export ZAKA_DIR="$TMP/zaka"
source "$REPO/zaka.zsh"
ZF="$ZAKA_DIR/aliases.zsh"

zaka add gs "git status" > "$TMP/out" 2>&1   # run in THIS shell so activation persists
assert_contains "add: confirms"            "gs" "$(<$TMP/out)"
assert_grep     "add: writes alias line"   "^alias gs='git status'$" "$ZF"
assert_contains "add: activates in shell"  "gs='git status'" "$(alias gs 2>&1)"

zaka add gs "git status -s" >/dev/null
assert_eq    "add: replaces (one line)"    "1" "$(grep -c '^alias gs=' "$ZF")"
assert_grep  "add: value updated"          "git status -s" "$ZF"

zaka fn cdls 'cd $1 && ls' >/dev/null
assert_grep  "fn: writes function line"    "^cdls\(\) \{" "$ZF"

zaka add cdls "echo hi" >/dev/null
assert_grep    "fn→add: alias replaces fn" "^alias cdls=" "$ZF"
assert_nofgrep "fn→add: old fn line gone"  "cdls() {" "$ZF"

assert_rc      "rm: existing returns 0"    0 "$(zaka rm gs >/dev/null 2>&1; echo $?)"
assert_no_grep "rm: line removed"          "^alias gs=" "$ZF"
assert_rc      "rm: missing returns 1"     1 "$(zaka rm nope >/dev/null 2>&1; echo $?)"

assert_rc       "add: bad name rejected"   1 "$(zaka add 'bad name' x >/dev/null 2>&1; echo $?)"
assert_contains "ls: lists entries"        "cdls" "$(zaka ls 2>&1)"
assert_contains "show: prints definition"  "cdls" "$(zaka show cdls 2>&1)"
assert_eq       "file: prints path"        "$ZF" "$(zaka file)"
assert_contains "version: prints version"  "zaka" "$(zaka version)"
assert_rc       "unknown cmd returns 1"    1 "$(zaka bogus >/dev/null 2>&1; echo $?)"

# ---- zenv ------------------------------------------------------------------
section "zenv — environment variables"
export ZENV_DIR="$TMP/zenv"
source "$REPO/zenv.zsh"
EF="$ZENV_DIR/env.zsh"

zenv set EDITOR vim >/dev/null
assert_fgrep "set: writes export line"     "export EDITOR='vim'" "$EF"
assert_eq    "set: activates (exported)"   "vim" "$EDITOR"

zenv set EDITOR nvim >/dev/null
assert_eq    "set: replaces (one line)"    "1" "$(grep -c '^export EDITOR=' "$EF")"

zenv set MSG "a b c" >/dev/null
assert_eq    "set: value with spaces"      "a b c" "$MSG"
assert_fgrep "set: spaces stored quoted"   "export MSG='a b c'" "$EF"

assert_rc      "set: hyphen name rejected" 1 "$(zenv set BAD-NAME x >/dev/null 2>&1; echo $?)"
assert_rc      "unset: existing returns 0" 0 "$(zenv unset EDITOR >/dev/null 2>&1; echo $?)"
assert_no_grep "unset: line removed"       "^export EDITOR=" "$EF"
assert_rc      "unset: missing returns 1"  1 "$(zenv unset NOPE >/dev/null 2>&1; echo $?)"

assert_contains "ls: filter"               "MSG" "$(zenv ls MSG 2>&1)"
assert_contains "get: prints value line"   "MSG" "$(zenv get MSG 2>&1)"
assert_eq       "file: prints path"        "$EF" "$(zenv file)"
assert_contains "version: prints version"  "zenv" "$(zenv version)"
assert_rc       "unknown cmd returns 1"    1 "$(zenv bogus >/dev/null 2>&1; echo $?)"

# ---- cross-shell reach (env vars reach child processes) --------------------
section "cross-shell reach"
RT="$TMP/reach"; mkdir -p "$RT/cfg"
ZENV_DIR="$RT/cfg" zsh -c "source '$REPO/zenv.zsh'; zenv set ZREACH OK >/dev/null"
print -r -- "export ZENV_DIR=$RT/cfg" >  "$RT/.zshenv"
print -r -- "source $REPO/zenv.zsh"   >> "$RT/.zshenv"
assert_eq "zsh child inherits var"  "OK" "$(ZDOTDIR=$RT zsh -c 'zsh -c "echo \$ZREACH"')"
assert_eq "bash child inherits var" "OK" "$(ZDOTDIR=$RT zsh -c 'bash -c "echo \$ZREACH"')"

# ---- installer (sandboxed, local file:// sources) --------------------------
section "installer"
IT="$TMP/install"; mkdir -p "$IT"
install_args=(
  ZDOTDIR="$IT"
  ZAKA_INSTALL_DIR="$IT/share/zaka" ZAKA_URL="file://$REPO/zaka.zsh"
  ZENV_INSTALL_DIR="$IT/share/zenv" ZENV_URL="file://$REPO/zenv.zsh"
  ZAKA_SKILL=1 ZAKA_SKILLS_BASE="file://$REPO/skills" ZAKA_SKILLS_DIR="$IT/skills"
)
assert_rc      "install: exit 0"                0 "$(env $install_args sh "$REPO/install.sh" >/dev/null 2>&1; echo $?)"
assert_isfile  "install: zaka.zsh placed"       "$IT/share/zaka/zaka.zsh"
assert_isfile  "install: zenv.zsh placed"       "$IT/share/zenv/zenv.zsh"
assert_fgrep   "install: zaka wired to .zshrc"  "zaka/zaka.zsh"  "$IT/.zshrc"
assert_fgrep   "install: zenv wired to .zshenv" "zenv/zenv.zsh"  "$IT/.zshenv"
assert_isfile  "install: zaka skill placed"     "$IT/skills/zaka/SKILL.md"
assert_isfile  "install: zenv skill placed"     "$IT/skills/zenv/SKILL.md"
env $install_args sh "$REPO/install.sh" >/dev/null 2>&1   # re-run
assert_eq "install: idempotent (.zshrc)"  "1" "$(grep -c 'zaka/zaka.zsh' "$IT/.zshrc")"
assert_eq "install: idempotent (.zshenv)" "1" "$(grep -c 'zenv/zenv.zsh' "$IT/.zshenv")"

# ---- summary ---------------------------------------------------------------
print -r -- ""
print -r -- "── ${PASS} passed, ${FAIL} failed ──"
[[ $FAIL -eq 0 ]]
