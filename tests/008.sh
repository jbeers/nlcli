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

actions='[{"type":"InspectEnvironment","operation":"get_cwd"},{"type":"ExecuteCommand","command":"printf inspected"}]'
out=$(INTERPRET_STUB_ACTIONS="$actions" "$interpret" -n "where am i")
check inspect-then-cmd test "$out" = "printf inspected"

actions='[{"type":"InspectEnvironment","operation":"command_exists","arguments":"sh"},{"type":"ExecuteCommand","command":"true"}]'
out=$(INTERPRET_STUB_ACTIONS="$actions" "$interpret" -n "have sh")
check exists-ok test "$out" = "true"

actions='[{"type":"InspectEnvironment","operation":"command_help","arguments":"ls; rm -rf /"},{"type":"ExecuteCommand","command":"true"}]'
out=$(INTERPRET_STUB_ACTIONS="$actions" "$interpret" -n "bad help")
check help-rejects-argv test "$out" = "true"

actions='[{"type":"InspectEnvironment","operation":"read_file","arguments":"/etc/passwd"},{"type":"ExecuteCommand","command":"true"}]'
out=$(INTERPRET_STUB_ACTIONS="$actions" "$interpret" -n "no files")
check reject-unknown test "$out" = "true"

actions='[{"type":"InspectEnvironment","operation":"get_cwd"},{"type":"InspectEnvironment","operation":"get_cwd"},{"type":"InspectEnvironment","operation":"get_cwd"},{"type":"InspectEnvironment","operation":"get_cwd"},{"type":"InspectEnvironment","operation":"get_cwd"}]'
set +e
err=$(INTERPRET_STUB_ACTIONS="$actions" "$interpret" -n "loop" 2>&1 >/dev/null)
status=$?
set -e
check inspect-cap test "$status" -ne 0
check inspect-cap-msg test "${err#*inspect}" != "$err"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
