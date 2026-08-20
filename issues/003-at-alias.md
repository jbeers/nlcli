# `@` bash alias

**Type:** AFK

## What to build

Interactive entry is `@ <request>`. Implement as a bash function/alias that forwards to `nlcli` (flags included). Standalone `nlcli` stays available without the alias.

Parent-shell mutation (`cd`, `export`) is 013, not this slice.

## Acceptance criteria

- [ ] After enabling the snippet, `@ show me the ten largest files in this directory` matches `nlcli …`
- [ ] `@ -n find every file larger than 1gb` works
- [ ] One documented line/snippet enables it in bash

## Blocked by

- [002-confirm-and-run.md](002-confirm-and-run.md)
