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

out=$(NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"git log -- README.md"}' \
	"$nlcli" -n "git: find commits touching README.md")
check tool-prefix test "$out" = "git log -- README.md"

out=$(NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"ls"}' \
	"$nlcli" -n "show files")
check unprefixed test "$out" = "ls"

out=$(NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"curl http://example.com"}' \
	"$nlcli" -n "http://example.com is up")
check url-not-prefix test "$out" = "curl http://example.com"

set +e
err=$( "$nlcli" -n "fooctl: read a file" 2>&1 >/dev/null)
status=$?
set -e
check missing-tool-exit test "$status" -ne 0
check missing-tool-msg test "${err#*fooctl}" != "$err"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
