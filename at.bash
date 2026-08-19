# source this from bash:  . ./at.bash
_INTERPRET="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/interpret"
function @ { "$_INTERPRET" "$@"; }
