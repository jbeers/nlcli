# source this from bash:  . ./at.bash
_INTERPRET="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/interpret"
function @ {
	local f st
	f=$(mktemp) || return
	INTERPRET_EMIT="$f" "$_INTERPRET" "$@"
	st=$?
	if [ "$st" -eq 0 ] && [ -s "$f" ]; then
		# shellcheck disable=SC1090
		. "$f"
		st=$?
	fi
	rm -f "$f"
	return "$st"
}
