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

ver=$("$nlcli" --version)
check version test "${ver#nlcli }" != "$ver"
help=$("$nlcli" --help)
check help-usage test "${help#*"nlcli [options] <request>"}" != "$help"
check help-teach test "${help#*"t  teach"}" != "$help"

out=$(NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"du -ah . | sort -hr | head -10"}' \
	"$nlcli" -n "show me the ten largest files in this directory")
check dry-run-largest test "$out" = "du -ah . | sort -hr | head -10"

out=$(NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"git add -A && git commit -m '\''first commit'\''"}' \
	"$nlcli" -n "git commit everything with message \"first commit\"")
check dry-run-commit test "$out" = "git add -A && git commit -m 'first commit'"

set +e
err=$(NLCLI_STUB_ACTION='{"type":"Fail","message":"cannot do that"}' \
	"$nlcli" -n "explode the machine" 2>&1 >/tmp/nlcli-001-out)
status=$?
set -e
check fail-exit test "$status" -ne 0
check fail-stderr echo "$err" | grep -q 'cannot do that'
check fail-no-stdout test ! -s /tmp/nlcli-001-out

a=$(NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"echo a"}' "$nlcli" -n one)
b=$(NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"echo b"}' "$nlcli" -n two)
check no-memory test "$a" = "echo a" -a "$b" = "echo b"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
