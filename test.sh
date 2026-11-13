#!/usr/bin/env bash
# Self-contained test suite for nim-dotenv. Requires the Nim compiler.
set -uo pipefail
cd "$(dirname "$0")"
export TC="$HOME/.local/toolchains"
export PATH="$TC/nim/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
command -v nim >/dev/null 2>&1 || { echo "FAIL: nim not found"; exit 1; }
./build.sh >/dev/null
BIN="./bin/nim-dotenv"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok(){ pass=$((pass+1)); }
bad(){ fail=$((fail+1)); echo "FAIL: $1"; }
# assert that a command's exit code and stdout match expectations
check(){ # name expected_exit expected_substring actual_exit actual_out
  local name="$1" want_rc="$2" want="$3" rc="$4" out="$5"
  if [ "$rc" != "$want_rc" ]; then bad "$name (exit $rc, want $want_rc)"; return; fi
  if [ -n "$want" ] && ! printf '%s' "$out" | grep -qF -- "$want"; then
    bad "$name (output missing '$want')"; return
  fi
  ok
}

cat > "$TMP/clean.env" <<'EOF'
# a clean file
HOST=localhost
PORT=8080

GREETING="hello world"
NAME='single quoted'
EOF
out=$($BIN "$TMP/clean.env"); rc=$?
check "clean validates" 0 "0 error(s), 0 warning(s)" "$rc" "$out"

cat > "$TMP/dup.env" <<'EOF'
PORT=1
PORT=2
EOF
out=$($BIN "$TMP/dup.env"); rc=$?
check "duplicate key flagged" 1 'duplicate key "PORT"' "$rc" "$out"

cat > "$TMP/nosep.env" <<'EOF'
this line has no separator
EOF
out=$($BIN "$TMP/nosep.env"); rc=$?
check "missing separator flagged" 1 "no '=' separator" "$rc" "$out"

cat > "$TMP/emptykey.env" <<'EOF'
=value
EOF
out=$($BIN "$TMP/emptykey.env"); rc=$?
check "empty key flagged" 1 "empty key" "$rc" "$out"

cat > "$TMP/badkey.env" <<'EOF'
BAD-KEY=1
EOF
out=$($BIN "$TMP/badkey.env"); rc=$?
check "invalid key chars flagged" 1 "invalid key" "$rc" "$out"

cat > "$TMP/badkey2.env" <<'EOF'
1STARTS_WITH_DIGIT=1
EOF
out=$($BIN "$TMP/badkey2.env"); rc=$?
check "key starting with digit flagged" 1 "invalid key" "$rc" "$out"

cat > "$TMP/spaces.env" <<'EOF'
MSG=hello world
EOF
out=$($BIN "$TMP/spaces.env"); rc=$?
check "unquoted spaces warn (exit 0)" 0 "WARN line 1" "$rc" "$out"
printf '%s' "$out" | grep -qF "0 error(s), 1 warning(s)" && ok || bad "warning summary counts"

cat > "$TMP/quoted.env" <<'EOF'
MSG="hello world"
OTHER='a b c'
EOF
out=$($BIN "$TMP/quoted.env"); rc=$?
check "quoted spaces do not warn" 0 "0 error(s), 0 warning(s)" "$rc" "$out"

cat > "$TMP/export.env" <<'EOF'
export API_KEY=abc123
export  SPACED=ok
EOF
out=$($BIN "$TMP/export.env"); rc=$?
check "export prefix stripped" 0 "0 error(s), 0 warning(s)" "$rc" "$out"

cat > "$TMP/comments.env" <<'EOF'
# comment line

   # indented comment
KEY=value
EOF
out=$($BIN "$TMP/comments.env"); rc=$?
check "comments and blanks ignored" 0 "0 error(s), 0 warning(s)" "$rc" "$out"

cat > "$TMP/multi.env" <<'EOF'
A=1
A=2
no separator here
B=two words
EOF
out=$($BIN "$TMP/multi.env"); rc=$?
check "mixed errors and warnings counted" 1 "2 error(s), 1 warning(s)" "$rc" "$out"

out=$($BIN "$TMP/does-not-exist.env" 2>/dev/null); rc=$?
check "missing file exits 2" 2 "" "$rc" "$out"

out=$($BIN 2>/dev/null); rc=$?
check "no args exits 2" 2 "" "$rc" "$out"

out=$(printf 'X=1\nX=2\n' | $BIN -); rc=$?
check "stdin duplicate flagged" 1 'duplicate key "X"' "$rc" "$out"

echo "----------------------------------------"
echo "nim-dotenv: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && echo "ALL CHECKS PASSED" || exit 1