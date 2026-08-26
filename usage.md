---
title: Usage
order: 3
summary: Learn the request flow, command controls, and safety behavior.
tags: [usage, safety]
---

# Usage

## Options

```text
-n, --dry-run   Print the command without running it
-y, --yes       Run non-risky commands without prompting
-e, --explain   Include the command explanation
    --history   Show local command history
-h, --help      Show help
-v, --version   Show the version
```

The request is the remaining positional text, so these forms are equivalent:

```bash
nlcli "show the ten largest files here"
nlcli show the ten largest files here
```

`--dry-run` prints only the generated command and exits. It never executes the
command or records a history entry.

## Request flow

Each invocation is independent:

1. nlcli extracts an optional tool hint such as `git:`.
2. The model returns a structured action rather than conversational prose.
3. If needed, nlcli asks one focused question or performs an allowlisted local inspection.
4. The resulting command is shown in the terminal.
5. nlcli combines deterministic safety checks with the model's risk metadata.
6. After approval, the command runs through `sh -c` and nlcli returns its exit status.

The model receives per-call ambient context—operating system, shell, user,
working directory, and basic Git repository state. This is context for the
current request, not persistent conversation memory.

## Tool hints

A prefix before a colon constrains generation to one executable:

```bash
nlcli --dry-run "git: find commits touching README.md"
nlcli --dry-run "ffmpeg: convert input.mov to webm"
```

nlcli checks that the hinted command exists before asking the model. A URL such
as `http://example.com` is not treated as a tool hint.

## Approval and safety

A normal command is previewed with this prompt:

```text
Run? [Enter/e/q/t]
```

| Key | Action |
| --- | --- |
| `Enter` | Run a low-risk command; cancel a high-risk command |
| `y` | Explicitly run the command |
| `e` | Open the command in `$VISUAL` or `$EDITOR` |
| `q` / `n` | Cancel |
| `?` | Show the explanation, then return to the prompt |
| `t` | Show the interactive token breakdown |

The `--yes` option skips confirmation only for low-risk commands. High-risk
commands still require `y`.

Risk is calculated from both model metadata and local detection. nlcli marks
commands involving recursive deletion, `git reset --hard`, `git clean`, force
pushes, filesystems, destructive database operations, `dd`, and `sudo` as
high risk. A model risk factor of 7 or more is also high risk. High-risk
commands are shown with a warning and default to No.

Editing replaces the proposed command, then runs the safety checks again. If
the editor exits unsuccessfully, nothing is executed.

## Clarifications and inspection

The model can return a choice question when different answers would change the
command, target, risk, data, or meaning. A choice is not approval: nlcli still
shows the resulting command and asks to run it. Free-text questions and an
`Other…` choice are supported; an empty answer cancels the invocation.

For local facts, the model may request one of these allowlisted inspections:

- platform, shell, or current directory
- whether a command exists
- a command's `--version` or `--help` output
- basic Git context

It cannot use inspection to read arbitrary files, walk the filesystem, make a
network request, or execute arbitrary arguments. Inspection round-trips are
bounded.

## Explain and teach

Use `--explain` for a short explanation in the initial preview:

```bash
nlcli --explain "show the ten largest files here"
```

Press `?` to show the same explanation without enabling it up front. Press `t`
to see a token-by-token breakdown of commands such as pipes, flags, arguments,
and `&&`. Teaching never executes the command; the normal approval keys remain
available while browsing.

## Failed commands and repair

A non-zero command offers one recovery cycle:

```text
[r] Repair  [e] Edit  [q] Quit
```

Repair sends the original intent, command, output, error, exit status, and
ambient context back to the model. The replacement command is previewed and
checked again before it can run. There is no autonomous retry loop.

## History

Successful and failed runs are appended to a local JSON Lines file. View the
newest entries first:

```bash
nlcli --history
```

History includes an id, timestamp, working directory, request, generated
command, and exit status. Command output is not stored and history is never
sent to the model.
