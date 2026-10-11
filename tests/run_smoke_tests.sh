#!/usr/bin/env bash
# Usage: ./tests/run_smoke_tests.sh [--static] [--dist DIR]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT_DIR/dist"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --static)
      DIST="$ROOT_DIR/dist-static"
      shift
      ;;
    --dist)
      DIST="$(cd "$2" && pwd)"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

BIN="$DIST/bin/vim"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { echo "ok: $*"; }
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

version="$("$BIN" --version | sed -n 1p)"
echo "$version" | grep -q '^VIM - Vi IMproved' || fail "vim --version: $version"
pass "$version"

# the runtime files are found through $VIM, as the archive is not at the compiled-in prefix
export VIM="$DIST/share/vim"
unset VIMRUNTIME
out="$(printf 'pmg' | "$DIST/bin/xxd" -p)"
[ "$out" = 706d67 ] || fail "xxd output: $out"
out="$(printf '706d67' | "$DIST/bin/xxd" -r -p)"
[ "$out" = pmg ] || fail "xxd -r output: $out"
pass "xxd dumps and reverses"

# edits a file in Ex mode on a terminal without terminfo
printf 'hello\n' >"$TMP/in.txt"
TERM=xterm-256color TERMINFO=/nonexistent TERMINFO_DIRS=/nonexistent \
  "$BIN" -u NONE -es "$TMP/in.txt" <<'EOF' >/dev/null
%s/hello/hello pmg/
wq
EOF
[ "$(cat "$TMP/in.txt")" = "hello pmg" ] || fail "ex mode edit: $(cat "$TMP/in.txt")"
pass "edits in Ex mode"

"$BIN" -u NONE -es -c "redir! > $TMP/rt.txt | echo \$VIMRUNTIME | redir END | qa!" </dev/null
grep -q 'share/vim/vim' "$TMP/rt.txt" || fail "runtime path: $(cat "$TMP/rt.txt")"
test -f "$(tr -d '[:space:]' <"$TMP/rt.txt")/syntax/syntax.vim" || fail "no syntax files in the runtime"
pass "finds the runtime files"

if [ "$(uname -s)" = Linux ] && ! LC_ALL=C grep -a -q 'ld-musl' "$BIN"; then
  max="$(LC_ALL=C grep -aoh 'GLIBC_2\.[0-9]*' "$BIN" | sort -uV | tail -n 1)" || true
  if [ -n "$max" ]; then
    [ "$(printf '%s\n' "$max" GLIBC_2.17 | sort -V | tail -n 1)" = GLIBC_2.17 ] \
      || fail "needs $max, newer than GLIBC_2.17"
    pass "glibc floor ($max)"
  fi
fi

echo "all smoke tests passed"
