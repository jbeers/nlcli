#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
interpret="$root/interpret"
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

set +e
out=$(printf 't\nq\n' | INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"git add -A && git commit -m first"}' \
	"$interpret" "commit everything")
status=$?
set -e
check teach-git test "${out#*git}" != "$out"
check teach-and test "${out#*&&}" != "$out"
check teach-exit test "$status" -ne 0

parts='[{"token":"ls","meaning":"list directory"},{"token":"-l","meaning":"long format"}]'
set +e
out=$(printf 't\nq\n' | INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"ls -l"}' \
	INTERPRET_STUB_TEACH="$parts" \
	"$interpret" "list")
set -e
check model-parts test "${out#*long format}" != "$out"

set +e
out=$(printf 't\nq\n' | COLUMNS=45 \
	INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"ls -l --block-size=M"}' \
	INTERPRET_STUB_TEACH='{"summary":"Long listing with sizes in mebibytes and 1,048,576-byte units.","parts":[{"token":"ls","meaning":"list directory entries"},{"token":"-l","meaning":"long format: mode, owner, size, mtime"},{"token":"--block-size=M","meaning":"sizes in 1048576-byte units, not SI MB"}]}' \
	"$interpret" "sizes")
set -e
check summary test "${out#*mebibytes}" != "$out"
check wrapped-indent test "${out#*"
  1,048,576-byte units."}" != "$out"
check block-size test "${out#*1048576}" != "$out"

esc=$(printf '\033')
set +e
out=$(printf 't\n\033[C\033[Cq' | \
	INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"ls -l"}' \
	INTERPRET_STUB_TEACH='{"summary":"Lists files.","parts":[{"token":"ls","meaning":"list entries"},{"token":"-l","meaning":"long format"}]}' \
	script -qefc "$interpret sizes" /dev/null)
status=$?
set -e
check interactive-exit test "$status" -ne 0
check interactive-focus test "${out#*"$esc[1;36m"}" != "$out"
check interactive-background test "${out#*"$esc[30;46m-l"}" != "$out"
check interactive-dim test "${out#*"$esc[2m"}" != "$out"
check interactive-pointer-owner test "${out#*"$esc[2m│$esc[0m  $esc[1;36m└─ long format"}" != "$out"
check interactive-redraw test "${out#*"$esc[u$esc[J"}" != "$out"

marker="$dir/x"
echo stay > "$marker"
set +e
printf 't\n\n' | INTERPRET_STUB_ACTION="{\"type\":\"ExecuteCommand\",\"command\":\"rm -r -- $marker\"}" \
	"$interpret" "remove it" >/dev/null
status=$?
set -e
check still-default-n test -f "$marker"
check still-no test "$status" -ne 0

dry=$(INTERPRET_STUB_ACTION='{"type":"ExecuteCommand","command":"ls -l"}' \
	"$interpret" -n "list")
check default-preview test "$dry" = "ls -l"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
