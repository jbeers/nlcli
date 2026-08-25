# source this from Bash after putting nlcli on PATH
_NLCLI="$(command -v nlcli 2>/dev/null || true)"
if [ -z "$_NLCLI" ]; then
	_NLCLI="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/nlcli"
fi
function @ {
	local f st
	f=$(mktemp) || return
	NLCLI_EMIT="$f" "$_NLCLI" "$@"
	st=$?
	if [ "$st" -eq 0 ] && [ -s "$f" ]; then
		# shellcheck disable=SC1090
		. "$f"
		st=$?
	fi
	rm -f "$f"
	return "$st"
}
