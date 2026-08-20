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

export NLCLI_HOME="$dir"
NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"printf hi"}' \
	"$nlcli" -y "say hi" >/dev/null

hist=$(NLCLI_HOME="$dir" "$nlcli" --history)
check has-request test "${hist#*say hi}" != "$hist"
check has-command test "${hist#*printf hi}" != "$hist"
check no-output test "${hist#*hihi}" = "$hist"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
