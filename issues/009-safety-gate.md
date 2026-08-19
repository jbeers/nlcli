# Safety gate and `--yes`

**Type:** AFK

## What to build

Every generated command gets risk tags (`READ`, `WRITE`, `DESTRUCTIVE`, `PRIVILEGED`, `NETWORK`; several may apply).

The client also deterministically flags: `rm -rf`, `git reset --hard`, `git clean`, `git push --force`, `mkfs`, `dd`, `sudo`, recursive delete, filesystem format, destructive DB ops.

Normal confirm is Enter to run. High-risk confirm defaults to No:

```text
⚠ …

Run? [y/N/e/?]
```

`-y`/`--yes` skips the normal confirm. High-risk still requires an explicit yes.

## Acceptance criteria

- [ ] `@ delete all untracked git files` warns and defaults to N
- [ ] Detector flags `rm -rf` even if the model tags `READ`
- [ ] `--yes` auto-runs a read/low-risk command
- [ ] `--yes` does not auto-run `git clean -fd` / `rm -rf`
- [ ] Multiple risk tags can apply

## Blocked by

- [002-confirm-and-run.md](002-confirm-and-run.md)
