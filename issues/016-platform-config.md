# Platform config for packaged installs

**Type:** AFK

## What to build

Make the standalone `nlcli` binary load persistent configuration from the user's platform config directory instead of relying on an `nlcli.env` file beside the executable or exported secrets in shell startup files.

Use these default locations:

- Unix: `$XDG_CONFIG_HOME/nlcli/config.toml`, falling back to `~/.config/nlcli/config.toml`
- Windows: `%APPDATA%\nlcli\config.toml`

Support `api_key`, `base_url`, and `model` in TOML. `NLCLI_CONFIG` may override the config path. Configuration precedence is:

1. `NLCLI_*` environment variables
2. Config file
3. `OPENAI_*` fallback variables
4. Built-in defaults

Never source or execute the config as shell code. Keep mutable state outside the config directory: use `$XDG_STATE_HOME/nlcli/history.jsonl` (falling back to `~/.local/state/nlcli/history.jsonl`) on Unix and `%LOCALAPPDATA%\nlcli\history.jsonl` on Windows. Preserve access to legacy `~/.nlcli/history.jsonl` when no new history file exists.

## Acceptance criteria

- [x] `nlcli` loads `api_key`, `base_url`, and `model` from the platform `config.toml`
- [x] `NLCLI_CONFIG` selects an alternate config file
- [x] `NLCLI_HOME` overrides the default config location
- [x] `NLCLI_*` values override config values; config values override `OPENAI_*` fallbacks
- [x] Missing config remains valid and existing environment-only configuration still works
- [x] Invalid TOML produces a short actionable error and a non-zero exit
- [x] Config contents are parsed as data and are never sourced or executed
- [x] History uses the platform state directory and falls back to legacy history without data loss
- [x] README documents the paths, precedence, and Unix `chmod 600` recommendation
- [x] Tests isolate config/state under temporary directories and do not read the developer's real home directory

## Out of scope

- Interactive `nlcli configure`
- Multiple named provider profiles
- OS keychain integration
- Modifying `.bashrc` or PowerShell profiles automatically

## Blocked by

None — can start immediately.
