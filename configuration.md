---
title: Configuration
order: 4
summary: Configure the endpoint and locate nlcli's persistent files.
tags: [configuration, reference]
---

# Configuration

nlcli reads three settings:

| TOML key | Environment override | Purpose |
| --- | --- | --- |
| `api_key` | `NLCLI_API_KEY` or `OPENAI_API_KEY` | Endpoint authentication |
| `base_url` | `NLCLI_BASE_URL` or `OPENAI_BASE_URL` | OpenAI-compatible API base URL |
| `model` | `NLCLI_MODEL` or `OPENAI_MODEL` | Model name; defaults to `gpt-4o-mini` |

A base URL such as `https://api.openai.com/v1` is normalized to the
`/chat/completions` endpoint. Use the base URL expected by your
OpenAI-compatible provider.

## Config file

The default config file is:

| Platform | Default path |
| --- | --- |
| Unix | `${XDG_CONFIG_HOME}/nlcli/config.toml`, or `~/.config/nlcli/config.toml` when `XDG_CONFIG_HOME` is empty |
| Windows | `%APPDATA%\nlcli\config.toml` |

Example:

```toml
api_key = "your-key"
base_url = "https://api.openai.com/v1"
model = "gpt-4o-mini"
```

Set `NLCLI_CONFIG` to select a specific TOML file. Set `NLCLI_HOME` to use a
single directory for both config and state; it uses `config.toml` and
`history.jsonl` directly inside that directory.

The file is parsed as TOML data and is never sourced as shell code. Invalid
TOML or non-string values for the three supported keys fail with an actionable
error before a model request is made.

## Precedence

For each setting, the first non-empty value wins:

1. The matching `NLCLI_*` environment variable.
2. The value in `config.toml`.
3. The matching `OPENAI_*` environment variable.
4. The built-in default.

This makes a persistent config convenient while keeping temporary overrides
simple:

```bash
NLCLI_MODEL=gpt-4o-mini nlcli --dry-run "list files"
```

## Protect credentials

On Unix, restrict the config file to the current user:

```bash
chmod 600 "${XDG_CONFIG_HOME:-$HOME/.config}/nlcli/config.toml"
```

Avoid putting API keys in a checked-in file. The source-only `nlcli.env` file
is gitignored for local development; packaged installs use the platform config
path instead.

## History and state

History is deliberately stored outside the config directory:

| Platform | Default path |
| --- | --- |
| Unix | `${XDG_STATE_HOME}/nlcli/history.jsonl`, or `~/.local/state/nlcli/history.jsonl` when `XDG_STATE_HOME` is empty |
| Windows | `%LOCALAPPDATA%\nlcli\history.jsonl` |

`NLCLI_HOME` overrides these defaults and places `history.jsonl` beside
`config.toml`. If an existing Unix installation has
`~/.nlcli/history.jsonl`, nlcli copies it to the new state path on first use
without deleting the original.
