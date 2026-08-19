# One repair after failure

**Type:** AFK

## What to build

If the command exits non-zero, offer one repair cycle:

```text
[r] Repair
[e] Edit
[q] Quit
```

Repair sends original intent, generated command, stdout, stderr, exit status, and ambient metadata. The new command still goes through preview and safety. No autonomous retry loop. Invocation context dies when the user finishes or quits.

## Acceptance criteria

- [ ] Non-zero exit offers r/e/q
- [ ] Repair does not auto-execute
- [ ] After one repair, a second failure does not repair again
- [ ] Quitting drops the temporary context

## Blocked by

- [009-safety-gate.md](009-safety-gate.md)
