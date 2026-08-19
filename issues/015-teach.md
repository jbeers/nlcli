# Teach command parts (`t`)

**Type:** AFK

## What to build

At the confirm prompt, `t` prints an ASCII diagram that labels each part of the proposed command (binary, flags, arguments, pipes, `&&`), then returns to `Run?`.

This is teaching, not a prose essay. Prefer a labeled breakdown over a paragraph.

```text
git add -A && git commit -m 'first'

  git          version-control CLI
  add          stage paths
  -A           all changes (tracked + untracked)
  &&           run next only if add succeeds
  git commit   record a snapshot
  -m 'first'   commit message

Run? [Enter/e/q/t]
```

The model may supply the breakdown as structured data; the client renders the diagram. `t` does not execute the command.

## Acceptance criteria

- [ ] `t` at confirm shows a labeled ASCII breakdown of the proposed command
- [ ] After `t`, the user is back at `Run?` (nothing executed)
- [ ] Default preview is still just the command
- [ ] High-risk confirm still defaults to No after `t`

## Blocked by

- [002-confirm-and-run.md](002-confirm-and-run.md)
