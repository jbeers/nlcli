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

ver=$("$interpret" --version)
check version test "${ver#interpret }" != "$ver"

out=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"du -ah . | sort -hr | head -10"}' \
	"$interpret" -n "show me the ten largest files in this directory")
check dry-run-largest test "$out" = "du -ah . | sort -hr | head -10"

out=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"git add -A && git commit -m '\''first commit'\''"}' \
	"$interpret" -n "git commit everything with message \"first commit\"")
check dry-run-commit test "$out" = "git add -A && git commit -m 'first commit'"

set +e
err=$(INTERPRET_STUB_ACTION='{"type":"Fail","message":"cannot do that"}' \
	"$interpret" -n "explode the machine" 2>&1 >/tmp/interpret-001-out)
status=$?
set -e
check fail-exit test "$status" -ne 0
check fail-stderr echo "$err" | grep -q 'cannot do that'
check fail-no-stdout test ! -s /tmp/interpret-001-out

a=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"echo a"}' "$interpret" -n one)
b=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"echo b"}' "$interpret" -n two)
check no-memory test "$a" = "echo a" -a "$b" = "echo b"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
