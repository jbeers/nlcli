# Local history

**Type:** AFK

## What to build

Record local invocations: timestamp, cwd, original request, generated command, exit status. Optional extras (model, tool hint, risk, duration) if cheap.

`interpret --history` lists newest first. Do not persist command output.

`--rerun` and using history as `-c` context are out of scope.

## Acceptance criteria

- [ ] A run appends a record (success and failure)
- [ ] `interpret --history` shows an id, the NL request, and the generated command
- [ ] Child stdout/stderr is not stored
- [ ] History is local-only (no network)

## Blocked by

- [002-confirm-and-run.md](002-confirm-and-run.md)
