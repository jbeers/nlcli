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

victim="$dir/victim"
echo stay > "$victim"

set +e
printf '\n' | NLCLI_STUB_ACTION="{\"type\":\"ExecuteCommand\",\"command\":\"rm -rf $victim\",\"risk\":[\"READ\"]}" \
	"$nlcli" "delete it" >/dev/null
status=$?
set -e
check detector-overrides-read test -f "$victim"
check enter-is-no test "$status" -ne 0

set +e
printf '\n' | NLCLI_STUB_ACTION="{\"type\":\"ExecuteCommand\",\"command\":\"git clean -fd\"}" \
	"$nlcli" "delete all untracked git files" >/dev/null
status=$?
set -e
check git-clean-default-n test "$status" -ne 0

out=$(NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"printf ran"}' \
	"$nlcli" -y "print ran")
check yes-low-risk test "${out#*ran}" != "$out"

set +e
printf '\n' | NLCLI_STUB_ACTION="{\"type\":\"ExecuteCommand\",\"command\":\"rm -rf $victim\"}" \
	"$nlcli" -y "delete it" >/dev/null
status=$?
set -e
check yes-skips-high-risk test -f "$victim"
check yes-high-still-asks test "$status" -ne 0

set +e
warn=$(printf '\n' | NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"git clean -fd"}' \
	"$nlcli" "delete untracked")
set -e
check red-or-warn test "${warn#*Deletes}" != "$warn"

set +e
printf '\n' | NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"rm -r -- x"}' \
	"$nlcli" "recursively remove x" >/dev/null
status=$?
set -e
check rm-r-is-risky test "$status" -ne 0

marker2="$dir/from-factor"
set +e
printf '\n' | NLCLI_STUB_ACTION="{\"type\":\"ExecuteCommand\",\"command\":\"touch $marker2\",\"riskFactor\":8}" \
	"$nlcli" "make a file" >/dev/null
status=$?
set -e
check factor-over-threshold test ! -e "$marker2"
check factor-blocks test "$status" -ne 0

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
