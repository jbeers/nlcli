#!/bin/bash
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
interpret="$root/interpret"
fail=0
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

check() {
	name=$1
	shift
	if "$@"; then
		echo "ok $name"
	else
		echo "FAIL $name"
		fail=$((fail + 1))
	fi
}

emit="$dir/cmd"
here=$(pwd)
printf '\n' | INTERPRET_EMIT="$emit" INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"cd /tmp"}' \
	"$interpret" "go to tmp" >/dev/null
check emit-written test -s "$emit"
check emit-cd grep -q 'cd /tmp' "$emit"
check child-cwd test "$(pwd)" = "$here"

# shellcheck disable=SC1091
. "$root/at.bash"
out=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"pwd"}' @ -n "where")
check at-dry-run test "$out" = "pwd"

start=$(pwd)
INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"cd /tmp"}' @ -y "go to tmp" >/dev/null
check at-cd test "$(pwd)" = "/tmp"
cd "$start"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
