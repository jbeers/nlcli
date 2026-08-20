# Dry-run: NL → printed command

**Type:** AFK

## What to build

`nlcli` takes a natural-language request and `-n`/`--dry-run` prints the generated shell command to stdout, then exits without running it.

The model returns a structured action (`ExecuteCommand` or `Fail`), not chatbot prose. Invocations are one-shot: no hidden conversational memory.

LLM: OpenAI-compatible HTTP via env (`NLCLI_API_KEY`, optional base URL/model). Tests may stub the HTTP.

## Acceptance criteria

- [ ] `nlcli --version` prints a version
- [ ] `nlcli -n "show me the ten largest files in this directory"` prints a command only (e.g. `find`/`du`), no preamble
- [ ] `nlcli -n "git commit everything with message \"first commit\""` prints a command and does not execute it
- [ ] `Fail` prints a short error, non-zero exit, no command
- [ ] Two sequential invocations do not share conversational memory

## Blocked by

None — can start immediately.
