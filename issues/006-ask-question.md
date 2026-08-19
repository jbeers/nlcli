# Single-choice clarification

**Type:** AFK

## What to build

The model may return `AskQuestion` (single choice). The client renders the menu, sends the answer back, then continues to command preview.

Clarification picks the command. Confirmation (002/009) still decides whether it runs. The model must not use questions as a stand-in for `Run?`.

System prompt: prefer a reasonable reversible assumption; ask only when ambiguity changes target, command, risk, data, or meaning.

## Acceptance criteria

- [ ] `@ reset my git changes` can show a choice list instead of guessing a destructive git command
- [ ] Cancel aborts with nothing executed
- [ ] After a choice, the user still gets command preview (002)
- [ ] A question cannot replace execution confirmation
- [ ] `compress foo.txt` does not interrogate compression formats (prompt policy)

## Blocked by

- [002-confirm-and-run.md](002-confirm-and-run.md)
