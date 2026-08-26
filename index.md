---
title: Home
order: 1
summary: Turn plain-language requests into reviewed shell commands.
toc: false
---

# nlcli

`nlcli` turns a natural-language request into a shell command, shows the
command, and asks before running it. It is a thin natural-language layer over
the command line—not a replacement for your shell.

## See it in action

<video controls preload="metadata" style="width: 100%; max-width: 960px;" aria-label="nlcli screencast">
  <source src="assets/Screencast_20260825_113732.webm" type="video/webm">
  <a href="assets/Screencast_20260825_113732.webm">Download the screencast</a>
</video>

```console
$ nlcli "show the ten largest files here"
  du -ah . | sort -hr | head -10
  Run? [Enter/e/q/t]
```

## What it does

- Generates one shell command from each request.
- Shows the command before execution by default.
- Blocks or warns on destructive and privileged commands.
- Asks a focused clarification when the target or meaning is ambiguous.
- Uses limited, allowlisted environment inspection when the model needs local context.
- Explains a command on request, or teaches it token by token with `t`.
- Offers one repair cycle after a failed command.
- Keeps invocation history locally; command output is never saved.

Use the standalone `nlcli` executable for normal command execution, or the
optional Bash `@` integration when commands such as `cd` and `export` must
change the current shell.

## Start here

- [Getting started](getting-started.md) — install nlcli, configure a model, and enable `@`.
- [Usage](usage.md) — options, prompts, tool hints, safety, and failure recovery.
- [Configuration](configuration.md) — config files, environment variables, and state paths.
- [Development](development.md) — run tests, build releases, and work on the project.

## Requirements

Released binaries have no runtime dependencies. nlcli sends requests to an
OpenAI-compatible chat-completions endpoint, so an API key and endpoint are
required unless the endpoint does not need authentication. Running from source
also requires [MatchBox](https://github.com/ortus-boxlang/matchbox) with the
`bif-cli` and `bif-http` features.
