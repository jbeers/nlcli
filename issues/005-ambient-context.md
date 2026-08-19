# Ambient + git context

**Type:** AFK

## What to build

Every invocation automatically includes: OS, shell, cwd, user, PATH, whether cwd is a git repo, branch, basic repo state.

This is per-call metadata, not conversational memory.

## Acceptance criteria

- [ ] Ambient fields are present on every model call
- [ ] Inside a git repo, branch/state are included
- [ ] Outside a git repo, git fields are absent (not fabricated)
- [ ] Context from invocation N does not leak into N+1

## Blocked by

- [001-dry-run.md](001-dry-run.md)
