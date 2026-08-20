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

ed="$dir/ed"
cat > "$ed" << 'EOF'
#!/bin/sh
echo 'printf edited' > "$1"
EOF
chmod +x "$ed"

out=$(printf 'e\n\n' | EDITOR="$ed" VISUAL="" \
	NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"printf original"}' \
	"$nlcli" "print something")
check edited-ran test "${out%edited}" != "$out"

abort="$dir/abort"
cat > "$abort" << 'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$abort"
marker="$dir/nope"
set +e
printf 'e\nq\n' | EDITOR="$abort" VISUAL="" \
	NLCLI_STUB_ACTION="{\"type\":\"ExecuteCommand\",\"command\":\"touch $marker\"}" \
	"$nlcli" "make a file" >/dev/null
status=$?
set -e
check abort-status test "$status" -ne 0
check abort-no-exec test ! -e "$marker"

if [ "$fail" -ne 0 ]; then
	echo "$fail failed"
	exit 1
fi
echo "all passed"
