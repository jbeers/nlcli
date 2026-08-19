# `tool:` hint

**Type:** AFK

## What to build

A `tool:` prefix constrains generation to that CLI:

```bash
interpret -n "git: find commits touching UserService.cfc"
```

Without a prefix, the model may pick any tool.

## Acceptance criteria

- [ ] `git:` / `ffmpeg:` / `kubectl:` prefixes are parsed and passed as a constraint
- [ ] Unprefixed requests still work
- [ ] Garbage prefix does not crash

## Blocked by

- [001-dry-run.md](001-dry-run.md)
