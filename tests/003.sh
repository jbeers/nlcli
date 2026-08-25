#!/bin/bash
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PATH="$root:$PATH"
# shellcheck disable=SC1091
. "$root/at.bash"
test "$_NLCLI" = "$root/nlcli"
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

out=$(NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"du -h"}' @ -n "show sizes")
check at-alias test "$out" = "du -h"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
