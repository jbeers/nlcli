#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
mb=${MATCHBOX:-$HOME/dev/ortus-boxlang/matchbox/target/debug/matchbox}
binary=${NLCLI_BINARY:-}
dir=$(mktemp -d)
SERVER_PID=
cleanup() {
	[ -z "$SERVER_PID" ] || kill "$SERVER_PID" 2>/dev/null || true
	rm -rf "$dir"
}
trap cleanup EXIT HUP INT TERM

export HOME="$dir/home"
export XDG_CONFIG_HOME="$dir/config"
export XDG_STATE_HOME="$dir/state"
unset NLCLI_CONFIG NLCLI_HOME NLCLI_API_KEY NLCLI_BASE_URL NLCLI_MODEL
unset OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
mkdir -p "$HOME" "$XDG_CONFIG_HOME/nlcli"

run() {
	if [ -n "$binary" ]; then
		"$binary" "$@"
	else
		"$mb" "$root/nlcli.bxs" -- "$@"
	fi
}

start_server() {
	capture=$1
	port_file="$dir/port"
	rm -f "$port_file"
	python3 - "$capture" "$port_file" <<'PY' &
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

capture, port_file = sys.argv[1:]
class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", "0")))
        request = json.loads(body)
        with open(capture, "w", encoding="utf-8") as output:
            json.dump({"path": self.path, "auth": self.headers.get("Authorization"), "model": request["model"]}, output)
        response = json.dumps({"choices": [{"message": {"content": '{"type":"ExecuteCommand","command":"true"}'}}]}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response)))
        self.end_headers()
        self.wfile.write(response)
    def log_message(self, *_):
        pass

server = HTTPServer(("127.0.0.1", 0), Handler)
with open(port_file, "w", encoding="utf-8") as output:
    output.write(str(server.server_port))
server.handle_request()
PY
	SERVER_PID=$!
	while [ ! -s "$port_file" ]; do sleep 0.01; done
	SERVER_PORT=$(cat "$port_file")
}

finish_server() {
	wait "$SERVER_PID"
	SERVER_PID=
}

check_capture() {
	capture=$1 key=$2 model=$3
	grep -Fq '"path": "/v1/chat/completions"' "$capture"
	grep -Fq "\"auth\": \"Bearer $key\"" "$capture"
	grep -Fq "\"model\": \"$model\"" "$capture"
}

# Platform config overrides OPENAI_* fallbacks.
start_server "$dir/default.json"
cat > "$XDG_CONFIG_HOME/nlcli/config.toml" <<EOF
api_key = "config-key"
base_url = "http://127.0.0.1:$SERVER_PORT/v1"
model = "config-model"
EOF
export OPENAI_API_KEY=fallback-key OPENAI_BASE_URL=http://127.0.0.1:1 OPENAI_MODEL=fallback-model
run -n test >/dev/null 2>&1
finish_server
check_capture "$dir/default.json" config-key config-model

# NLCLI_CONFIG selects data-only TOML and never executes its contents.
start_server "$dir/alternate.json"
marker="$dir/executed"
cat > "$dir/alternate.toml" <<EOF
api_key = '\$(touch $marker)'
base_url = "http://127.0.0.1:$SERVER_PORT/v1"
model = "alternate-model"
EOF
export NLCLI_CONFIG="$dir/alternate.toml"
run -n test >/dev/null 2>&1
finish_server
test ! -e "$marker"
grep -Fq '"model": "alternate-model"' "$dir/alternate.json"

# NLCLI_* values override the selected config.
start_server "$dir/environment.json"
export NLCLI_API_KEY=environment-key NLCLI_BASE_URL="http://127.0.0.1:$SERVER_PORT/v1" NLCLI_MODEL=environment-model
run -n test >/dev/null 2>&1
finish_server
check_capture "$dir/environment.json" environment-key environment-model
unset NLCLI_CONFIG NLCLI_API_KEY NLCLI_BASE_URL NLCLI_MODEL

# NLCLI_HOME overrides the default config location.
start_server "$dir/home.json"
export NLCLI_HOME="$dir/nlcli-home"
mkdir -p "$NLCLI_HOME"
cat > "$NLCLI_HOME/config.toml" <<EOF
api_key = "home-key"
base_url = "http://127.0.0.1:$SERVER_PORT/v1"
model = "home-model"
EOF
run -n test >/dev/null 2>&1
finish_server
check_capture "$dir/home.json" home-key home-model
unset NLCLI_HOME

# Missing config preserves OPENAI_* environment-only configuration.
rm -f "$XDG_CONFIG_HOME/nlcli/config.toml"
start_server "$dir/fallback.json"
export OPENAI_API_KEY=fallback-key OPENAI_BASE_URL="http://127.0.0.1:$SERVER_PORT/v1" OPENAI_MODEL=fallback-model
run -n test >/dev/null 2>&1
finish_server
check_capture "$dir/fallback.json" fallback-key fallback-model

# Empty XDG_CONFIG_HOME falls back under the isolated HOME.
export XDG_CONFIG_HOME=
start_server "$dir/home-fallback.json"
mkdir -p "$HOME/.config/nlcli"
cat > "$HOME/.config/nlcli/config.toml" <<EOF
api_key = "home-fallback-key"
base_url = "http://127.0.0.1:$SERVER_PORT/v1"
model = "home-fallback-model"
EOF
run -n test >/dev/null 2>&1
finish_server
check_capture "$dir/home-fallback.json" home-fallback-key home-fallback-model
rm -f "$HOME/.config/nlcli/config.toml"
export XDG_CONFIG_HOME="$dir/config"

# Invalid TOML fails before any model call.
printf '%s\n' 'api_key = [' > "$XDG_CONFIG_HOME/nlcli/config.toml"
set +e
error=$(run -n test 2>&1 >/dev/null)
status=$?
set -e
test "$status" -ne 0
test "${error#*invalid TOML}" != "$error"
rm -f "$XDG_CONFIG_HOME/nlcli/config.toml"

# History writes to state and migrates legacy history without deleting it.
NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"true"}' run -y state-test >/dev/null
state_history="$XDG_STATE_HOME/nlcli/history.jsonl"
test -s "$state_history"
test "$(grep -c state-test "$state_history")" -eq 1

export XDG_STATE_HOME=
NLCLI_STUB_ACTION='{"type":"ExecuteCommand","command":"true"}' run -y home-state-test >/dev/null
test -s "$HOME/.local/state/nlcli/history.jsonl"
rm -rf "$HOME/.local/state"
export XDG_STATE_HOME="$dir/state"
rm -rf "$XDG_STATE_HOME"
mkdir -p "$HOME/.nlcli"
printf '%s\n' '{"id":42,"request":"legacy-test","command":"true","exit":0}' > "$HOME/.nlcli/history.jsonl"
history=$(run --history)
test "${history#*legacy-test}" != "$history"
cmp "$HOME/.nlcli/history.jsonl" "$XDG_STATE_HOME/nlcli/history.jsonl"

echo 'all passed'
