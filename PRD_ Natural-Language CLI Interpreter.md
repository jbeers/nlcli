# PRD: Natural-Language CLI Interpreter

## 1. Overview

### Working Name

**Interpret**

The final product name is not decided. The implementation should use a conventional executable name such as `interpret`, while the primary interactive shell interface should be a short punctuation alias, preferably:

```bash
@ <natural language request>
```

Example:

```bash
@ git commit everything with message "this is my first commit"
```

Interpret resolves the request into:

```bash
git add -A && git commit -m 'this is my first commit'
```

The user sees the proposed command, approves it, and Interpret executes it.

### Product Concept

Interpret is a thin natural-language layer over the existing command line.

Its core mental model is:

> **Use normal shell commands when you remember how to do something. Use `@` when you remember what you want to accomplish but not the exact command.**

Interpret is not intended to replace the shell, become a general-purpose AI assistant, or create a persistent conversational environment.

It exists specifically to bridge the gap between **intent** and **CLI syntax**.

---

# 2. Problem

Modern command-line environments contain hundreds of useful programs, each with its own command syntax, flags, conventions, and edge cases.

Users frequently know:

- what tool they want to use;
- what operation they want to perform;
- roughly what should happen;

but cannot remember the exact syntax.

Examples:

```bash
@ git show me commits that changed UserService.cfc
```

```bash
@ ffmpeg convert this mov to a reasonably compressed 1080p mp4
```

```bash
@ kubectl restart the api deployment in staging
```

```bash
@ show me the ten largest directories here
```

Today the user must typically:

1. search the web;
2. read `--help`;
3. ask an AI in another application;
4. copy the command;
5. return to the terminal;
6. execute it.

Interpret collapses this workflow into a native shell interaction.

---

# 3. Product Principles

## 3.1 The Shell Remains Primary

Interpret augments the command line rather than replacing it.

The desired interaction is:

```bash
git status

@ squash my last three commits into one

docker ps

@ show only containers using more than 500mb
```

Natural language and conventional commands should coexist fluidly.

---

## 3.2 Commands, Not Conversation

The primary output of Interpret is executable shell code.

Avoid responses such as:

> Sure! You can accomplish this by using the following Git command...

Prefer:

```text
git reset --soft HEAD~3 && git commit
```

The default UI should be terse and command-oriented.

---

## 3.3 One-Shot by Default

Normal invocations should be independent.

This:

```bash
@ deploy this branch to staging
```

should behave consistently regardless of what the user asked Interpret five minutes earlier.

Persistent conversational memory must not silently change the meaning of future commands.

---

## 3.4 Ask Rather Than Guess When the Difference Matters

Interpret should normally make sensible assumptions.

It should ask for clarification only when ambiguity materially changes:

- the target;
- the resulting command;
- the risk;
- the data affected;
- or the meaning of the operation.

For example:

```bash
@ compress foo.txt
```

should probably resolve directly to something reasonable such as:

```bash
gzip foo.txt
```

It should not interrogate the user about compression algorithms.

However:

```bash
@ reset my git changes
```

has materially different interpretations and should trigger clarification.

---

## 3.5 Make Dangerous Operations Obvious

Interpret must display commands before executing them by default.

Destructive, privileged, or otherwise dangerous operations should receive additional warnings and stronger confirmation requirements.

---

# 4. Primary Interface

## 4.1 Named Executable

The project should ship a conventional executable:

```bash
interpret
```

Examples:

```bash
interpret --version
interpret --history
interpret --config
```

This provides a stable executable for:

- package managers;
- documentation;
- shell integration;
- debugging;
- scripting;
- configuration.

---

## 4.2 Short Interactive Alias

The preferred interactive interface is:

```bash
@
```

Example:

```bash
@ git commit everything with message "initial implementation"
```

The implementation may use whatever alias/function mechanism is appropriate for Bash, Zsh, Fish, etc., but the intended user-facing syntax is `@`.

Shell-specific compatibility should be validated during implementation.

---

# 5. Basic Command Flow

Example:

```text
$ @ git commit everything with message "this is my first commit"

  git add -A && git commit -m 'this is my first commit'

Run? [Enter/e/q]
```

Controls:

```text
Enter   Execute
e       Edit command
q       Cancel
?       Show explanation/details
```

After execution, stdout/stderr should stream normally:

```text
[main 73a12cd] this is my first commit
 13 files changed, 482 insertions(+)
```

Interpret should avoid adding unnecessary narration around successful commands.

---

# 6. Tool Hint Syntax

Users should be able to constrain which CLI tool Interpret uses.

Syntax:

```bash
@ git: find commits touching UserService.cfc
```

```bash
@ ffmpeg: turn video.mov into a gif 800 pixels wide
```

```bash
@ kubectl: show pods with more than three restarts
```

The `tool:` prefix communicates:

> Solve this request using this tool.

Without a prefix:

```bash
@ find when UserService.cfc was last changed
```

Interpret is free to choose the appropriate command-line utility.

This creates three useful levels of expertise:

```text
git log -- UserService.cfc
```

The user knows the command.

```text
@ git: find commits touching UserService.cfc
```

The user knows the tool.

```text
@ find when UserService.cfc changed
```

The user only knows the desired result.

Interpret should support all three workflows naturally.

---

# 7. Clarification / Question TUI

The model must have the ability to request clarification.

Clarification should be implemented as a structured action rather than arbitrary conversational text.

Example:

```bash
$ @ undo my last git commit
```

Interpret may render:

```text
How should the changes be handled?

  > Keep the changes staged
    Keep the changes unstaged
    Discard the changes
    Cancel
```

After selection:

```text
git reset --soft HEAD~1

Run? [Enter/e/q]
```

---

# 8. Question Types

The initial question system should support four interaction types.

### Single Choice

```text
Which environment?

  > staging
    production
    development
```

### Multiple Choice

```text
What should be cleaned?

  [x] node_modules/
  [x] dist/
  [ ] .env
  [x] *.log
```

### Free Text

Used when structured choices cannot represent the answer.

Example:

```text
Which host should be used?

> dev-server.example.com
```

### Other

Single-choice menus may optionally expose:

```text
Other…
```

Selecting it opens free-text input.

---

# 9. Clarification Policy

The system prompt should explicitly instruct the model:

> Prefer a reasonable, reversible assumption over asking a question. Ask only when missing information materially changes the command, result, target, or risk.

Interpret should therefore avoid unnecessary questions.

Bad:

```text
$ @ compress foo.txt

What compression format would you like?
```

Better:

```text
gzip foo.txt
```

But this:

```bash
@ delete the old docker stuff
```

should trigger something like:

```text
What should be removed?

  > Stopped containers
    Unused images
    Unused volumes
    Everything unused
    Cancel
```

---

# 10. Clarification and Confirmation Are Different

These concepts must remain separate.

## Clarification

Determines **what command should be generated**.

Example:

```text
What do you mean by reset?

  Working-tree changes
  Staged changes
  Last commit
  Branch to remote state
```

## Confirmation

Determines **whether an already-generated command should execute**.

Example:

```text
git clean -fd

⚠ Deletes untracked files and directories.

Run? [y/N]
```

The model should not use clarification questions as a substitute for execution confirmation.

---

# 11. Model Interaction Protocol

Interpret should not treat the LLM response as simply:

```text
Natural language -> shell string
```

Instead, the model should return a structured **next action**.

Initial action types should include:

```text
ExecuteCommand
AskQuestion
InspectEnvironment
Fail
```

Conceptually:

```text
ExecuteCommand {
    command
    explanation
    risk
}
```

```text
AskQuestion {
    question
    type
    choices
    allow_other
}
```

```text
InspectEnvironment {
    operation
    arguments
}
```

The application, not the model, is responsible for rendering the TUI.

This keeps UI behavior deterministic and consistent.

---

# 12. Context Model

Interpret should distinguish three forms of context.

## 12.1 Ambient Context

Ambient context is automatically supplied for every invocation.

Examples:

```text
Operating system
Shell
Current working directory
Current user
Available PATH
Whether cwd is inside a Git repository
Current Git branch
Basic repository state
```

Example request:

```bash
@ open port 8080 in the firewall
```

The correct command depends heavily on the operating system.

Ambient context allows the model to make that decision without asking the user.

Ambient context is **not conversational memory**.

---

## 12.2 Invocation Context

Context may persist during a single operation.

For example:

```bash
@ rsync this folder to my server
```

If execution fails:

```text
rsync: unknown option --foo
```

Interpret may offer:

```text
Command failed.

[r] Repair
[e] Edit
[q] Quit
```

Selecting `Repair` should send the model:

- original intent;
- generated command;
- stdout;
- stderr;
- exit status;
- relevant environment information.

The model may then produce a corrected command.

This temporary context ends when the operation is completed or abandoned.

---

## 12.3 Explicit Conversational Context

Longer conversational context should not be implicit.

A future version may support:

```bash
@ -c now only show the ones belonging to this project
```

where `-c` explicitly means:

> Continue from my previous Interpret request.

Named sessions may eventually be supported:

```bash
@ -s migration find pending migrations
@ -s migration run only safe ones
```

Named sessions are **not part of the initial MVP**.

---

# 13. Environment Inspection

One of Interpret's most important capabilities should be inspecting the CLI tools actually installed on the user's machine.

The model should have access to a small collection of safe inspection operations.

Initial examples:

```text
get_platform()
get_shell()
get_cwd()
command_exists(name)
command_version(name)
command_help(name)
git_context()
```

A request like:

```bash
@ fooctl: create a deployment using config.json
```

may result internally in:

```text
command_exists("fooctl")
command_version("fooctl")
command_help("fooctl")
command_help("fooctl create")
```

The resulting command can therefore target the user's **actual installed version** rather than relying entirely on the model's training data.

This is a major product feature.

---

# 14. Inspection Safety

Environment inspection should initially be conservative.

Safe inspection includes:

- executable existence;
- `--help`;
- `--version`;
- current directory;
- OS/platform;
- Git metadata.

The MVP should avoid giving the model unrestricted:

- file reads;
- recursive filesystem access;
- network requests;
- arbitrary command execution.

Additional inspection capabilities may be introduced later with explicit security boundaries.

---

# 15. Shell Integration

A standalone child process cannot modify the state of the parent shell.

For example:

```bash
@ go to the parent directory
```

cannot simply execute:

```bash
cd ..
```

inside the `interpret` process because the directory change disappears when the process exits.

The same issue applies to:

```bash
@ activate the python environment
```

```bash
@ set JAVA_HOME to Java 21
```

```bash
@ add this directory to PATH
```

Therefore the short `@` interface should ultimately be implemented as shell integration capable of executing approved shell code **inside the current shell**.

Conceptually:

```text
Shell
  ↓
Interpret receives intent
  ↓
Model produces shell code
  ↓
Interpret renders preview
  ↓
User approves
  ↓
Shell integration executes code in current shell
```

The conventional `interpret` executable should remain usable without shell integration, although parent-shell mutations will naturally be unavailable in that mode.

---

# 16. Command Editing

When a command is proposed:

```text
git add -A && git commit -m 'first commit'

Run? [Enter/e/q]
```

pressing:

```text
e
```

should open the command for editing.

For the MVP this may use:

- `$EDITOR`;
- `$VISUAL`;
- or a lightweight inline editor.

The user should always retain the ability to manually correct AI-generated shell code before execution.

---

# 17. Execution Modes

Initial command-line flags should remain deliberately small.

Recommended:

```text
-n / --dry-run
```

Generate the command but never execute it.

Example:

```bash
@ -n find every file larger than 1gb
```

Output:

```bash
find . -type f -size +1G
```

---

```text
-y / --yes
```

Execute automatically without normal confirmation.

Safety policy may still override `--yes` for particularly dangerous operations.

---

```text
-e / --explain
```

Show an explanation of the generated command.

This should not be the default behavior.

---

Future:

```text
-c / --continue
```

Explicitly continue from the previous interaction.

Named sessions should be deferred.

---

# 18. Safety Model

Every generated command should receive a risk classification.

Suggested categories:

```text
READ
WRITE
DESTRUCTIVE
PRIVILEGED
NETWORK
```

Multiple categories may apply.

Example:

```text
git status
```

is approximately:

```text
READ
```

while:

```text
sudo rm -rf /some/path
```

is:

```text
WRITE
DESTRUCTIVE
PRIVILEGED
```

---

# 19. Deterministic Safety Rules

Risk classification should not rely entirely on the LLM.

Interpret should include deterministic detection for common dangerous constructs such as:

```text
rm -rf
git reset --hard
git clean
git push --force
mkfs
dd
sudo
filesystem formatting
recursive deletion
database destructive operations
```

The exact rule engine may evolve, but obvious danger should be independently detected by the client.

---

# 20. High-Risk Confirmation

Example:

```bash
$ @ remove all untracked git files
```

Result:

```text
git clean -fd

⚠ Deletes untracked files and directories.

Run? [y/N/e/?]
```

Risky commands should default to **No**.

Certain commands may require confirmation even when the user supplies:

```text
--yes
```

A future advanced configuration may allow experienced users to relax these rules.

---

# 21. History

History is considered more important than persistent conversational sessions.

Interpret should record local invocation history containing at least:

```text
Timestamp
Working directory
Original natural-language request
Generated command
Exit status
```

Potential additional metadata:

```text
Model/provider
Tool hint
Risk classification
Execution duration
```

Sensitive command output should not automatically be persisted.

---

# 22. History Interface

Example:

```bash
interpret --history
```

Possible output:

```text
32  git commit everything with message "first commit"
    git add -A && git commit -m 'first commit'

31  find largest directories
    du -h --max-depth=1 | sort -hr
```

Future capabilities may include:

```bash
interpret --rerun 32
```

and using an earlier request as explicit context.

---

# 23. Pipeline Support

Pipeline support is desirable but not required for the first MVP.

Future examples:

```bash
docker ps | @ show only containers that have been running more than a day
```

or:

```bash
cat users.json | @ jq: get the email address of every active user
```

Interpret should preferably generate a conventional CLI transformation:

```bash
jq -r '.users[] | select(.active) | .email'
```

rather than sending the entire dataset to the LLM for processing.

This preserves the product philosophy:

> AI determines how ordinary command-line tools should perform the work.

---

# 24. Privacy Principle

Whenever possible, Interpret should send **intent and metadata** to the model rather than user data.

For example:

```bash
cat customers.json | @ find all active customers
```

should ideally result in the model generating an appropriate `jq` command without sending `customers.json` itself to the model.

This distinction should remain a major design principle.

---

# 25. Error Repair

When a generated command exits unsuccessfully, Interpret should optionally offer one repair cycle.

Example:

```text
Command exited with status 1.

[r] Repair
[e] Edit
[q] Quit
```

Repair should provide the model with:

- original request;
- original generated command;
- stdout;
- stderr;
- exit code;
- relevant environmental metadata.

The repaired command must still go through normal preview and safety evaluation.

Interpret must not enter an uncontrolled autonomous retry loop.

---

# 26. Non-Goals

The initial product is intentionally **not**:

- a general-purpose chatbot;
- a replacement shell;
- a long-running agent;
- an autonomous sysadmin;
- a full terminal emulator;
- a persistent AI REPL;
- a programming assistant;
- an environment with hidden conversational memory;
- an unrestricted filesystem agent;
- a mechanism that blindly executes generated commands.

Keeping these boundaries is important to the identity of the product.

---

# 27. MVP Scope — v0.1

The first functional version should implement:

1. A conventional `interpret` executable.
2. A shell-facing `@` shortcut.
3. Natural-language intent input.
4. Ambient OS/shell/cwd context.
5. Basic Git context when inside a repository.
6. Optional `tool:` hints.
7. Structured model responses.
8. `ExecuteCommand` actions.
9. `AskQuestion` actions.
10. Single-choice clarification TUI.
11. Free-text clarification fallback.
12. Command preview.
13. Execute/edit/cancel controls.
14. `--dry-run`.
15. `--yes`.
16. Risk classification.
17. Deterministic checks for obvious dangerous commands.
18. Strong confirmation for destructive operations.
19. Safe inspection of command existence, version, and help.
20. Execution with stdout/stderr streaming.
21. Exit-code capture.
22. One repair attempt after command failure.
23. Local history.

Multi-select questions are desirable in v0.1 but may be pushed to v0.2 if they materially complicate the TUI framework.

---

# 28. Explicitly Deferred

Do not allow the MVP to expand into the following features unless they prove necessary for the core experience:

- named sessions;
- long-lived conversational history;
- semantic search over documentation;
- web search;
- unrestricted filesystem reads;
- autonomous multi-step agents;
- arbitrary model-triggered command execution;
- remote machine management;
- plugin ecosystems;
- complex configuration systems;
- cloud account synchronization;
- graphical desktop UI.

---

# 29. Suggested Internal Architecture

A useful conceptual architecture is:

```text
Shell Integration
       │
       ▼
Intent Parser
       │
       ▼
Context Collector
       │
       ▼
Model Orchestrator
       │
       ├──── Inspect Environment
       │
       ├──── Ask Question
       │
       └──── Produce Command
                 │
                 ▼
          Safety Evaluator
                 │
                 ▼
          Command Preview
                 │
                 ▼
          User Confirmation
                 │
                 ▼
              Execute
                 │
        ┌────────┴────────┐
        ▼                 ▼
     Success            Failure
                          │
                          ▼
                     Repair?
```

The orchestration may be agent-like internally, but the external interface should continue to feel like a simple shell utility.

---

# 30. Model Responsibilities

The model should be responsible for:

- interpreting natural-language intent;
- choosing appropriate CLI tools when unspecified;
- translating intent into shell commands;
- identifying genuine ambiguity;
- generating structured clarification questions;
- requesting safe environment inspection;
- using returned `--help` or version information;
- explaining commands when requested;
- repairing commands based on execution errors.

The model should **not** control the TUI directly.

---

# 31. Client Responsibilities

The Interpret client should be responsible for:

- shell integration;
- collecting ambient context;
- enforcing inspection boundaries;
- rendering questions;
- collecting answers;
- validating model response schemas;
- displaying generated commands;
- deterministic safety checks;
- confirmations;
- command execution;
- history;
- stdout/stderr;
- repair-loop limits.

The client must remain the authority over whether commands execute.

---

# 32. Example Complete Flow

User:

```bash
@ reset my git changes
```

Model cannot determine the intended Git operation.

It emits an `AskQuestion` action.

Interpret renders:

```text
What should be reset?

  > Working-tree modifications
    Staged changes
    Last commit
    Branch to remote state
    Cancel
```

User chooses:

```text
Last commit
```

Interpret may ask a second material clarification:

```text
What should happen to the commit's changes?

  > Keep staged
    Keep unstaged
    Discard
```

User chooses:

```text
Keep staged
```

The model produces:

```bash
git reset --soft HEAD~1
```

Interpret classifies it as a write operation and renders:

```text
git reset --soft HEAD~1

Run? [Enter/e/q]
```

The user presses Enter.

The command runs.

No additional conversation is displayed unless needed.

---

# 33. UX Quality Bar

The product should feel closer to:

```bash
!
```

or shell completion than to opening ChatGPT.

A successful common interaction should require approximately:

```text
intent
↓
command preview
↓
Enter
```

Clarification menus are there when needed, but their existence should not encourage the model to ask questions unnecessarily.

The ideal reaction should be:

> "I know this is possible from the command line; I just don't remember how. I'll use `@`."

---

# 34. Acceptance Criteria for Initial Prototype

The first prototype is successful if a user can perform workflows such as:

```bash
@ git commit everything with message "first commit"
```

```bash
@ show me the ten largest files in this directory
```

```bash
@ git: show commits that modified README.md
```

```bash
@ ffmpeg: convert recording.mov to a 1080p mp4
```

and receive a sensible executable command with one confirmation step.

It must also correctly recognize ambiguity in requests such as:

```bash
@ reset my git changes
```

and use a structured question TUI rather than guessing.

Finally, dangerous requests such as:

```bash
@ delete all untracked git files
```

must receive visibly stronger confirmation before execution.

---

# 35. Implementation Priority

When making implementation tradeoffs, prioritize in this order:

1. **Fast, low-friction shell UX**
2. **Correct command generation**
3. **User control before execution**
4. **Useful environment awareness**
5. **Good ambiguity handling**
6. **Safety**
7. **Error repair**
8. **History**
9. **Extended conversational features**

Do not sacrifice the simplicity of the core interaction in order to make Interpret behave like a more general AI agent.

---

# 36. Product Thesis

Interpret should not try to teach the user every CLI syntax or replace the command line with natural language.

It should make forgotten syntax almost irrelevant.

The shell remains the interface.

CLI programs remain the tools.

The AI simply fills in the missing command.

> **Interpret is the part of the shell you use when you remember the outcome but forget the incantation.**