---
title: Getting started
order: 2
summary: Install nlcli, configure an endpoint, and make your first request.
tags: [setup, installation]
---

# Getting started

## Install a release

The installer downloads the latest release for the current operating system,
verifies its SHA-256 checksum, and places `nlcli` in `~/.local/bin`:

```bash
curl -fsSL https://raw.githubusercontent.com/jbeers/nlcli/main/install.sh | sh
```

Put the destination on `PATH` if it is not there already:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Choose another install directory with `NLCLI_INSTALL_DIR`:

```bash
curl -fsSL https://raw.githubusercontent.com/jbeers/nlcli/main/install.sh \
  | NLCLI_INSTALL_DIR="$HOME/bin" sh
```

The published release currently includes Linux x64 and macOS arm64 binaries.
Other platforms fail with a missing-release message rather than installing an
unverified build. Development builds are available from the
[rolling snapshot](https://github.com/jbeers/nlcli/releases/tag/snapshot).

Verify the installation:

```bash
nlcli --version
```

## Configure the model endpoint

Create a TOML file at the platform-specific path described in
[Configuration](configuration.md):

```toml
api_key = "your-key"
base_url = "https://api.openai.com/v1"
model = "gpt-4o-mini"
```

The config file is optional. Environment variables are useful for temporary
overrides and CI:

```bash
export NLCLI_API_KEY=your-key
export NLCLI_BASE_URL=https://api.openai.com/v1
export NLCLI_MODEL=gpt-4o-mini
```

On Unix, protect the file because it contains a secret:

```bash
chmod 600 "${XDG_CONFIG_HOME:-$HOME/.config}/nlcli/config.toml"
```

## Make a request

```bash
nlcli "list files modified today"
```

nlcli displays the proposed command first. Press **Enter** to run a low-risk
command, or use `y` for an explicit yes. High-risk commands default to No;
they require an explicit `y`.

Use dry-run when you only want the generated command:

```bash
nlcli --dry-run "find every file larger than 1gb"
```

## Enable the `@` Bash integration

The `@` function runs an approved command in the current Bash process. This is
what lets `cd`, `export`, and similar shell changes persist after nlcli exits.

Download the integration:

```bash
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nlcli"
mkdir -p "$config_dir"
curl -fsSL https://raw.githubusercontent.com/jbeers/nlcli/main/at.bash \
  -o "$config_dir/at.bash"
```

Source it from `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
. "${XDG_CONFIG_HOME:-$HOME/.config}/nlcli/at.bash"
```

Reload Bash with `source ~/.bashrc`, then use:

```bash
@ create a temporary workspace, cd into it, and export DEBUG=1
```

The standalone `nlcli` process cannot modify its parent shell. Use `@` only
when that behavior is needed.

## Run from source

A source checkout includes a launcher that looks for MatchBox at
`~/dev/ortus-boxlang/matchbox/target/debug/matchbox` and then the release
location. Set `MATCHBOX` to use another executable:

```bash
MATCHBOX=/path/to/matchbox ./nlcli --dry-run "list files"
```

For local credentials, create the gitignored `nlcli.env` beside the launcher:

```dotenv
NLCLI_API_KEY=your-key
NLCLI_BASE_URL=https://api.openai.com/v1
NLCLI_MODEL=gpt-4o-mini
```

The source launcher accepts `OPENAI_API_KEY`, `OPENAI_BASE_URL`, and
`OPENAI_MODEL` as fallbacks too.
