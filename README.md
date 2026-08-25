# nlcli

[![Build, test, and release](https://github.com/jbeers/nlcli/actions/workflows/delivery.yml/badge.svg)](https://github.com/jbeers/nlcli/actions/workflows/delivery.yml)

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

## Install a release

Download the archive for your platform from [GitHub Releases](https://github.com/jbeers/nlcli/releases). For Linux x64:

```bash
curl -LO https://github.com/jbeers/nlcli/releases/latest/download/nlcli-linux-x64.tar.gz
tar -xzf nlcli-linux-x64.tar.gz
install -m 755 nlcli ~/.local/bin/nlcli
```

Until platform config support lands, provide settings through environment variables:

```bash
export NLCLI_API_KEY=your-key
export NLCLI_BASE_URL=https://api.openai.com/v1
export NLCLI_MODEL=gpt-4o-mini
```

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

For the shorter Bash interface:

```bash
. ./at.bash
@ list files modified today
```

The `@` function executes approved commands in the current shell, allowing changes such as `cd` and `export` to persist. Direct `nlcli` execution cannot modify its parent shell.

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

Run the shell test suite:

```bash
for test in tests/*.sh; do "$test"; done
```

CI builds and tests standalone Linux and macOS binaries. Every push to `dev` replaces the rolling `snapshot` prerelease. Every push to `main` publishes the version declared in `nlcli.bxs`; merging without bumping `VERSION` fails if that release already exists.

History is stored in `~/.nlcli/history.jsonl`, or under `NLCLI_HOME` when set.
