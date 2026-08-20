#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
nlcli="$root/nlcli"
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

actions='[{"type":"AskQuestion","question":"What should be reset?","choices":["Working-tree","Last commit"]},{"type":"ExecuteCommand","command":"git reset --soft HEAD~1"}]'

out=$(NLCLI_STUB_ACTIONS="$actions" NLCLI_STUB_ANSWER="Last commit" \
	"$nlcli" -n "reset my git changes")
check after-choice test "$out" = "git reset --soft HEAD~1"

set +e
err=$(NLCLI_STUB_ACTIONS="$actions" NLCLI_STUB_ANSWER="Cancel" \
	"$nlcli" -n "reset my git changes" 2>&1 >/tmp/nlcli-006-out)
status=$?
set -e
check cancel-exit test "$status" -ne 0
check cancel-msg test "${err#*cancelled}" != "$err"
check cancel-no-cmd test ! -s /tmp/nlcli-006-out

marker="$dir/nope"
run="[{\"type\":\"AskQuestion\",\"question\":\"What?\",\"choices\":[\"A\"]},{\"type\":\"ExecuteCommand\",\"command\":\"touch $marker\"}]"
set +e
printf 'q\n' | NLCLI_STUB_ACTIONS="$run" NLCLI_STUB_ANSWER="A" \
	"$nlcli" "reset my git changes" >/dev/null
status=$?
set -e
check still-confirms test "$status" -ne 0
check did-not-run test ! -e "$marker"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
