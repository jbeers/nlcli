#!/bin/sh
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

set +e
out=$(printf 't\nq\n' | INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"git add -A && git commit -m first"}' \
	"$interpret" "commit everything")
status=$?
set -e
check teach-git test "${out#*git}" != "$out"
check teach-and test "${out#*&&}" != "$out"
check teach-exit test "$status" -ne 0

parts='[{"token":"ls","meaning":"list directory"},{"token":"-l","meaning":"long format"}]'
set +e
out=$(printf 't\nq\n' | INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"ls -l"}' \
	INTERPRET_STUB_TEACH="$parts" \
	"$interpret" "list")
set -e
check model-parts test "${out#*long format}" != "$out"

marker="$dir/x"
echo stay > "$marker"
set +e
printf 't\n\n' | INTERPRET_STUB_ACTION="{\"type\":\"ExecuteCommand\",\"command\":\"rm -r -- $marker\"}" \
	"$interpret" "remove it" >/dev/null
status=$?
set -e
check still-default-n test -f "$marker"
check still-no test "$status" -ne 0

dry=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"ls -l"}' \
	"$interpret" -n "list")
check default-preview test "$dry" = "ls -l"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
