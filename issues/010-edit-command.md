# Edit command before run

**Type:** AFK

## What to build

At confirm, `e` opens the proposed command in `$EDITOR` or `$VISUAL`. The saved buffer replaces the command and returns to confirm. Re-run deterministic safety on the edited text.

## Acceptance criteria

- [ ] `e` opens the editor with the proposed command
- [ ] Save returns to confirm with the edited command
- [ ] Aborting the editor does not execute
- [ ] Edited command goes through the safety gate again

## Blocked by

- [009-safety-gate.md](009-safety-gate.md)
