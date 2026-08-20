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

out=$(NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"ls","explanation":"list files"}' \
	"$nlcli" -n "list files")
check default-cmd test "$out" = "ls"

out=$(NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"ls","explanation":"list files"}' \
	"$nlcli" -n -e "list files")
check flag-explain test "${out#*list files}" != "$out"

set +e
out=$(printf '?\nq\n' | NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"true","explanation":"shows truth"}' \
	"$nlcli" "noop")
set -e
check prompt-explain test "${out#*shows truth}" != "$out"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
