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

export INTERPRET_HOME="$dir"
INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"printf hi"}' \
	"$interpret" -y "say hi" >/dev/null

hist=$(INTERPRET_HOME="$dir" "$interpret" --history)
check has-request test "${hist#*say hi}" != "$hist"
check has-command test "${hist#*printf hi}" != "$hist"
check no-output test "${hist#*hihi}" = "$hist"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
