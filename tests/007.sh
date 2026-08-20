#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
nlcli="$root/nlcli"
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

actions='[{"type":"AskQuestion","question":"Which host?","questionType":"freetext"},{"type":"ExecuteCommand","command":"echo dev.example"}]'
out=$(NLCLI_STUB_ACTIONS="$actions" NLCLI_STUB_ANSWER="dev.example" \
	"$nlcli" -n "rsync this folder")
check freetext test "$out" = "echo dev.example"

set +e
err=$(printf '\n' | NLCLI_STUB_ACTIONS='[{"type":"AskQuestion","question":"Which host?","questionType":"freetext"}]' \
	"$nlcli" -n "rsync this" 2>&1 >/dev/null)
status=$?
set -e
check empty-cancels test "$status" -ne 0
check empty-msg test "${err#*cancel}" != "$err"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
