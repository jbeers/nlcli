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

out=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"ls","explanation":"list files"}' \
	"$interpret" -n "list files")
check default-cmd test "$out" = "ls"

out=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"ls","explanation":"list files"}' \
	"$interpret" -n -e "list files")
check flag-explain test "${out#*list files}" != "$out"

set +e
out=$(printf '?\nq\n' | INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"true","explanation":"shows truth"}' \
	"$interpret" "noop")
set -e
check prompt-explain test "${out#*shows truth}" != "$out"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
