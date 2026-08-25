#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
mkdir -p "$dir/release" "$dir/package" "$dir/bin"

cat > "$dir/package/nlcli" <<'EOF'
#!/bin/sh
echo 'nlcli 9.9.9'
EOF
chmod +x "$dir/package/nlcli"
tar -czf "$dir/release/nlcli-linux-x64.tar.gz" -C "$dir/package" nlcli
(
	cd "$dir/release"
	sha256sum nlcli-linux-x64.tar.gz > checksums.txt
)

out=$(NLCLI_RELEASE_BASE_URL="file://$dir/release" NLCLI_INSTALL_DIR="$dir/bin" "$root/install.sh")
test -x "$dir/bin/nlcli"
test "$($dir/bin/nlcli --version)" = 'nlcli 9.9.9'
test "${out#*Installed nlcli 9.9.9}" != "$out"

echo corrupt >> "$dir/release/nlcli-linux-x64.tar.gz"
set +e
NLCLI_RELEASE_BASE_URL="file://$dir/release" NLCLI_INSTALL_DIR="$dir/bad" \
	"$root/install.sh" >/dev/null 2>&1
status=$?
set -e
test "$status" -ne 0
test ! -e "$dir/bad/nlcli"

echo 'all passed'
