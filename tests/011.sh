#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
interpret="$root/interpret"
fail=0

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

out=$(printf '\nr\n\n' | INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"sh -c \"echo fail; exit 7\""}' \
	INTERPRET_STUB_REPAIR='{"type":"ExecuteCommand","command":"printf repaired"}' \
	"$interpret" "do the thing")
check repaired test "${out%repaired}" != "$out"

set +e
printf '\nr\n\n' | INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"sh -c \"exit 7\""}' \
	INTERPRET_STUB_REPAIR='{"type":"ExecuteCommand","command":"sh -c \"exit 8\""}' \
	"$interpret" "fail twice" >/dev/null
status=$?
set -e
check one-repair test "$status" -eq 8

set +e
printf '\nq\n' | INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"sh -c \"exit 7\""}' \
	"$interpret" "quit repair" >/dev/null
status=$?
set -e
check quit-keeps-status test "$status" -eq 7

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
