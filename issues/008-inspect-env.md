# Safe environment inspect

**Type:** AFK

## What to build

The model may return `InspectEnvironment`. The client runs an allowlisted operation, returns the result, then the model continues (command or question).

Allowlist: `get_platform`, `get_shell`, `get_cwd`, `command_exists`, `command_version`, `command_help`, `git_context`.

No file reads, recursive walks, network, or arbitrary exec.

# ponytail: hard-cap inspect round-trips (e.g. 4); raise only if real tools need more help pages

## Acceptance criteria

- [ ] Each allowlisted op works
- [ ] `command_help` is `--help` only, not arbitrary argv
- [ ] Missing tools return a result, not a crash
- [ ] Non-allowlisted inspect is rejected
- [ ] Inspect loop is bounded; then `Fail` or proceed

## Blocked by

- [001-dry-run.md](001-dry-run.md)
