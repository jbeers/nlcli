# nlcli

`nlcli` turns a natural-language request into a shell command, previews it, and asks before running it.

```console
$ nlcli "show the ten largest files here"
  du -ah . | sort -hr | head -10
  Run? [Enter/e/q/t]
```

Risky commands are shown in red, include a warning, and default to **No**. Safe commands are green and default to **Yes**.

## Requirements

- Bash for the optional `@` integration
- [MatchBox](https://github.com/ortus-boxlang/matchbox) built with `bif-cli` and `bif-http`
- An OpenAI-compatible chat-completions endpoint

By default the launcher looks for MatchBox at:

```text
~/dev/ortus-boxlang/matchbox/target/debug/matchbox
~/dev/ortus-boxlang/matchbox/target/release/matchbox
```

Set `MATCHBOX` to use another path.

## Setup

Create a gitignored `nlcli.env` beside the executable:

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

In teach mode, use `Left`/`Right` or `h`/`l` to select command tokens. The normal approval keys remain active.

## Development

Run the shell test suite:

```bash
for test in tests/*.sh; do "$test"; done
```

History is stored in `~/.nlcli/history.jsonl`, or under `NLCLI_HOME` when set.
