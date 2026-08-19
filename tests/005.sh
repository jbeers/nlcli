#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
interpret="$root/interpret"
fail=0
dir=$(mktemp -d)

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

empty=$(mktemp -d)
trap 'rm -rf "$dir" "$empty"' EXIT
ctx=$(cd "$empty" && INTERPRET_DUMP_CONTEXT=1 INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"true"}' \
	"$interpret" -n "x" 2>&1 >/dev/null)
check has-os test "${ctx#*os=}" != "$ctx"
check has-shell test "${ctx#*shell=}" != "$ctx"
check has-user test "${ctx#*user=}" != "$ctx"
check has-cwd test "${ctx#*cwd=}" != "$ctx"
check no-fake-git test "${ctx#*git.repo=yes}" = "$ctx"

git init -q -b testers "$dir"
cd "$dir"
ctx=$(INTERPRET_DUMP_CONTEXT=1 INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"true"}' \
	"$interpret" -n "x" 2>&1 >/dev/null)
check git-repo test "${ctx#*git.repo=yes}" != "$ctx"
check git-branch test "${ctx#*git.branch=testers}" != "$ctx"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
