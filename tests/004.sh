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

out=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"git log -- README.md"}' \
	"$interpret" -n "git: find commits touching README.md")
check tool-prefix test "$out" = "git log -- README.md"

out=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"ls"}' \
	"$interpret" -n "show files")
check unprefixed test "$out" = "ls"

out=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"curl http://example.com"}' \
	"$interpret" -n "http://example.com is up")
check url-not-prefix test "$out" = "curl http://example.com"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
