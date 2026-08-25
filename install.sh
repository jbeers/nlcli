#!/bin/sh
set -eu

repo=https://github.com/jbeers/nlcli
base=${NLCLI_RELEASE_BASE_URL:-$repo/releases/latest/download}
dest=${NLCLI_INSTALL_DIR:-$HOME/.local/bin}

case "$(uname -s)-$(uname -m)" in
	Linux-x86_64|Linux-amd64) asset=nlcli-linux-x64.tar.gz ;;
	Linux-aarch64|Linux-arm64) asset=nlcli-linux-arm64.tar.gz ;;
	Darwin-x86_64|Darwin-amd64) asset=nlcli-macos-x64.tar.gz ;;
	Darwin-arm64|Darwin-aarch64) asset=nlcli-macos-arm64.tar.gz ;;
	*) echo "nlcli: unsupported platform: $(uname -s)-$(uname -m)" >&2; exit 1 ;;
esac

if command -v curl >/dev/null 2>&1; then
	download() { curl -fsSL "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
	download() { wget -qO "$2" "$1"; }
else
	echo "nlcli: curl or wget is required" >&2
	exit 1
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/nlcli-install.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

if ! download "$base/$asset" "$tmp/$asset"; then
	echo "nlcli: no release available for $asset" >&2
	exit 1
fi
download "$base/checksums.txt" "$tmp/checksums.txt"
expected=$(awk -v file="$asset" '$2 == file || $2 == "*" file { print $1; exit }' "$tmp/checksums.txt")
if [ -z "$expected" ]; then
	echo "nlcli: $asset is missing from checksums.txt" >&2
	exit 1
fi
if command -v sha256sum >/dev/null 2>&1; then
	actual=$(sha256sum "$tmp/$asset" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
	actual=$(shasum -a 256 "$tmp/$asset" | awk '{print $1}')
else
	echo "nlcli: sha256sum or shasum is required" >&2
	exit 1
fi
if [ "$actual" != "$expected" ]; then
	echo "nlcli: checksum verification failed for $asset" >&2
	exit 1
fi

tar -xzf "$tmp/$asset" -C "$tmp"
if [ ! -f "$tmp/nlcli" ]; then
	echo "nlcli: release archive does not contain nlcli" >&2
	exit 1
fi
mkdir -p "$dest"
cp "$tmp/nlcli" "$dest/.nlcli.$$"
chmod 755 "$dest/.nlcli.$$"
mv "$dest/.nlcli.$$" "$dest/nlcli"

echo "Installed $("$dest/nlcli" --version) to $dest/nlcli"
case ":${PATH:-}:" in
	*":$dest:"*) ;;
	*) echo "Add $dest to PATH: export PATH=\"$dest:\$PATH\"" ;;
esac
