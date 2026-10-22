#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/fc-list" <<'SH'
#!/bin/bash
if [[ $1 == "-f" ]]; then
  printf '%s\n' 'Liberation Mono|/usr/share/fonts/TTF/liberation.ttf'
fi
SH

cat >"$mock_bin/pacman" <<'SH'
#!/bin/bash
case $1 in
  -Ql)
    printf '%s\n' 'liberation-font /usr/share/fonts/TTF/liberation.ttf'
    ;;
  -Qi)
    cat <<'INFO'
Name            : liberation-font
Provides        : None
Depends On      : None

INFO
    ;;
esac
SH

cat >"$mock_bin/omarchy-font-current" <<'SH'
#!/bin/bash
echo "Some other font"
SH

chmod +x "$mock_bin/fc-list" "$mock_bin/pacman" "$mock_bin/omarchy-font-current"

for requested in 'Liberation Mono?' 'liberation-font?'; do
  if PATH="$mock_bin:$ROOT/bin:$PATH" bash "$ROOT/bin/omarchy-font-remove" "$requested" >"$test_tmp/output" 2>&1; then
    fail "wildcard characters in an unknown font name are rejected: $requested"
  fi

  grep -q "Font '$requested' was not found" "$test_tmp/output" ||
    fail "unknown font name reports not found: $requested" "$(cat "$test_tmp/output")"
done
pass "unknown family and package globs do not resolve to installed fonts"
