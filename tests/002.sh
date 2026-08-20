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

out=$(printf '\n' | INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"printf ran"}' \
	"$interpret" "print ran")
check preview test "${out#*printf ran}" != "$out"
check ran test "${out#*ran}" != "$out"
check run-spacing test "${out#*"

ran"}" != "$out"
check no-chatter test "${out#*Sure}" = "$out"

set +e
printf '\n' | INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"exit 7"}' \
	"$interpret" "fail please" >/dev/null
status=$?
set -e
check child-status test "$status" -eq 7

marker="$dir/created"
set +e
printf 'q\n' | INTERPRET_STUB_ACTION="{\"type\":\"ExecuteCommand\",\"command\":\"touch $marker\"}" \
	"$interpret" "make a file" >/dev/null
status=$?
set -e
check cancel-status test "$status" -ne 0
check cancel-no-exec test ! -e "$marker"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
