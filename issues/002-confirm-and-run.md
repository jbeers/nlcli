# Confirm and run with streamed I/O

**Type:** AFK

## What to build

Without `--dry-run`, show the generated command and wait:

```text
Run? [Enter/e/q]
```

Enter runs it as a child process with live stdout/stderr. `q` cancels. Successful runs add no narration. Interpret's exit code is the child's exit code.

`e` and `?` may be stubbed until 010 and 014.

## Acceptance criteria

- [ ] Default flow is preview → Enter → streamed child output
- [ ] `q` executes nothing
- [ ] Child stdout/stderr stream in real time
- [ ] On run, `interpret` exits with the child's status
- [ ] Success is not wrapped in assistant chatter

## Blocked by

- [001-dry-run.md](001-dry-run.md)
