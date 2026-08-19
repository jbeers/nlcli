# Execute approved code in the parent shell

**Type:** AFK

## What to build

`@` must run the approved script in the current shell so `cd`, `export`, `source`, PATH changes persist. `interpret` as a child process still cannot mutate the parent; that limitation stays documented.

Bash only. Preview and safety still wrap execution.

## Acceptance criteria

- [ ] `@ go to the parent directory` after approve changes the user's cwd
- [ ] `@ set JAVA_HOME to Java 21` after approve persists in that shell (or a documented equivalent env assignment)
- [ ] Bare `interpret …` still cannot change the caller's cwd
- [ ] Command still previews and passes the safety gate

## Blocked by

- [003-at-alias.md](003-at-alias.md)
- [009-safety-gate.md](009-safety-gate.md)
