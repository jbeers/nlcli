# nlcli

[![Build, test, and release](https://github.com/jbeers/nlcli/actions/workflows/delivery.yml/badge.svg)](https://github.com/jbeers/nlcli/actions/workflows/delivery.yml)

[Documentation](https://jbeers.github.io/nlcli/)

`nlcli` turns a natural-language request into a shell command, previews it, and asks before running it.

```console
$ nlcli "show the ten largest files here"
  du -ah . | sort -hr | head -10
  Run? [Enter/e/q/t]
```

Risky commands are shown in red, include a warning, and default to **No**. Safe commands are green and default to **Yes**.

## Requirements

The standalone release binary has no runtime dependencies. Running from source requires [MatchBox](https://github.com/ortus-boxlang/matchbox) built with `bif-cli` and `bif-http`. Bash is required only for the optional `@` integration.

Both forms require an OpenAI-compatible chat-completions endpoint.

## Quick install

Install the latest release for your OS and architecture:

```bash
curl -fsSL https://raw.githubusercontent.com/jbeers/nlcli/main/install.sh | sh
```

The installer verifies the release checksum and writes `nlcli` to `~/.local/bin` by default. Set another destination when needed:

```bash
curl -fsSL https://raw.githubusercontent.com/jbeers/nlcli/main/install.sh \
  | NLCLI_INSTALL_DIR="$HOME/bin" sh
```

Published builds currently cover Linux x64 and macOS arm64. Other detected platforms fail with a clear missing-release error. Development builds are available from the rolling [snapshot prerelease](https://github.com/jbeers/nlcli/releases/tag/snapshot).

## Configuration

On Unix, create `${XDG_CONFIG_HOME:-$HOME/.config}/nlcli/config.toml`:

```toml
api_key = "your-key"
base_url = "https://api.openai.com/v1"
model = "gpt-4o-mini"
```

Protect API keys from other local users:

```bash
chmod 600 "${XDG_CONFIG_HOME:-$HOME/.config}/nlcli/config.toml"
```

Windows uses `%APPDATA%\nlcli\config.toml`. Set `NLCLI_CONFIG` to use a specific file, or `NLCLI_HOME` to place `config.toml` and `history.jsonl` in a specific directory.

Values are resolved in this order:

1. `NLCLI_API_KEY`, `NLCLI_BASE_URL`, and `NLCLI_MODEL`
2. `api_key`, `base_url`, and `model` from `config.toml`
3. `OPENAI_API_KEY`, `OPENAI_BASE_URL`, and `OPENAI_MODEL`
4. Built-in defaults

The config file is optional. Environment variables remain useful for CI and temporary overrides.

## Enable `@` after installation

Download the Bash integration to your user config directory:

```bash
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nlcli"
mkdir -p "$config_dir"
curl -fsSL https://raw.githubusercontent.com/jbeers/nlcli/main/at.bash \
  -o "$config_dir/at.bash"
```

Then add the installed binary and integration to `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
. "${XDG_CONFIG_HOME:-$HOME/.config}/nlcli/at.bash"
```

Reload Bash with `source ~/.bashrc`. You can now use:

```bash
@ show the ten largest files here
```

The `@` function sources approved commands into the current shell, allowing changes such as `cd` and `export` to persist. Direct `nlcli` execution cannot modify its parent shell.

## Run from source

The source launcher looks for MatchBox at `~/dev/ortus-boxlang/matchbox/target/debug/matchbox` and `target/release/matchbox`. Set `MATCHBOX` to use another path.

Create a gitignored `nlcli.env` beside the source launcher:

```dotenv
NLCLI_API_KEY=your-key
NLCLI_BASE_URL=https://api.openai.com/v1
NLCLI_MODEL=gpt-4o-mini
```

`OPENAI_API_KEY`, `OPENAI_BASE_URL`, and `OPENAI_MODEL` are accepted as fallbacks.

Run directly:

```bash
./nlcli "list files modified today"
```

For the shorter Bash interface from a source checkout:

```bash
. ./at.bash
@ list files modified today
```

## Five things worth trying

Generated commands vary with your machine, but these are representative.

### Find the change, not just the file

```console
$ @ git: find the commit that removed UserService
  git log -S'UserService' --all --oneline
```

### Diagnose the dev server you forgot about

```console
$ @ show me what is listening on port 3000
  lsof -nP -iTCP:3000 -sTCP:LISTEN
```

### Turn an API response into something readable

```console
$ @ fetch localhost:8080/api/users and show id, email, and role as a table
  curl -sS http://localhost:8080/api/users | jq -r '.[] | [.id, .email, .role] | @tsv' | column -t
```

### Find repository bloat without searching ignored files

```console
$ @ show the ten largest files known to git
  git ls-files -z | xargs -0 du -h | sort -hr | head -10
```

### Change the current shell without remembering the syntax

```console
$ @ create a temporary workspace, cd into it, and export DEBUG=1
  work=$(mktemp -d) && cd "$work" && export DEBUG=1
```

Because this last command runs through `@`, the new directory and environment variable remain active afterward.

## Options

```text
-n, --dry-run   Print the command without running it
-y, --yes       Run non-risky commands without prompting
-e, --explain   Include the command explanation
    --history   Show local command history
-h, --help      Show help
-v, --version   Show the version
```

Tool prefixes constrain command generation:

```bash
@ git: show commits that changed README.md
@ ffmpeg: convert input.mov to webm
```

## Approval

| Key | Action |
| --- | --- |
| `Enter` | Run safe commands; cancel risky commands by default |
| `y` | Explicitly run, including risky commands |
| `e` | Edit before running |
| `q` / `n` | Cancel |
| `?` | Show the explanation |
| `t` | Open the interactive token breakdown |

## Teach mode

Press `t` at any approval prompt to replace the preview with a token-by-token explanation:

```text
ls -l --block-size=M
│  │  └─ display sizes in mebibytes
│  └─ use long listing format
└─ list directory contents

Lists the current directory in long format with sizes measured in MiB.
```

The initial view is a normal readable breakdown. Use `Left`/`Right` or `h`/`l` to move through the command. The selected token gets a background highlight, its connector and explanation are emphasized, and unrelated token details are dimmed.

Teach mode never executes anything by itself. The approval keys remain active while browsing: `Enter` accepts the default, `y` runs explicitly, `e` edits, and `q`/`n` cancels. Risky commands still default to No.

## Development

Run the isolated shell test suite:

```bash
tests/run
```

CI builds and tests standalone Linux and macOS binaries. Every push to `dev` replaces the rolling `snapshot` prerelease. Every push to `main` publishes the version declared in `nlcli.bxs`; merging without bumping `VERSION` fails if that release already exists.

History is stored separately from configuration: `${XDG_STATE_HOME:-$HOME/.local/state}/nlcli/history.jsonl` on Unix and `%LOCALAPPDATA%\nlcli\history.jsonl` on Windows. Existing `~/.nlcli/history.jsonl` data is copied to the new Unix location on first use. `NLCLI_HOME` overrides both locations.
