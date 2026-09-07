---
name: delegating-to-codex
description: Use when delegating implementation work to the codex CLI (GPT-6 Astra with high reasoning by default) — offloading a coding task, getting a fallback/second implementer, or when the user says "use codex", "ask codex", or "have GPT do it"
---

# Delegating to Codex

## Overview

`codex exec` runs a headless coding agent. Default every implementation, review, fix, and resumed run to **GPT-6 Astra with high reasoning**: `-m gpt-6-astra -c model_reasoning_effort=high`. Keep this pair for both small and complex tasks unless the user explicitly requests a different model or effort.

## Command template

Every delegation call uses this default — fill the workdir and prompt, and change model or effort only for an explicit user override:

```bash
codex exec \
  --cd <workdir> --skip-git-repo-check \
  --sandbox workspace-write \
  --ignore-user-config \
  -m gpt-6-astra \
  -c model_reasoning_effort=high \
  -o /tmp/codex-last.txt \
  "<prompt>" </dev/null
```

- Bash timeout ≥ 600000ms — `high`/`xhigh` runs take minutes; the 120s default kills them. Choose blocking vs background mode (below) before running.
- Never bare `codex "..."` — that opens the interactive TUI and hangs a headless shell.
- `--ignore-user-config` skips the user's `~/.codex/config.toml` (MCP servers, plugin config — most of the default cost). Auth still works. It also resets sandbox to `read-only` and drops the user's `danger-full-access` default — which is why the explicit `--sandbox workspace-write` stays in the template. Omit `--ignore-user-config` only when codex needs the user's MCP servers/plugins.
- `~/.codex/AGENTS.md` is loaded regardless of `--ignore-user-config`. If it installs startup/skill ceremony (e.g. superpowers), codex will read skill files and do TDD ritual even for one-liners. Suppress it in the prompt: open with "You are a subagent dispatched to execute this one fully-specified task; skip startup/plugin skills." Measured: halves wall time and tool calls on a trivial task.
- `-m gpt-6-astra` pins the default model explicitly. `--ignore-user-config` drops the user's `~/.codex/config.toml` model default, so without this flag codex falls back to its own built-in default — always fill the `-m` slot.
- `-o` writes codex's final message to a file; `--json` gives JSONL events; `--output-schema <file>` forces a JSON shape.

## Blocking vs background — choose before running

**Blocking** (foreground Bash call): `low`/`medium` tasks that finish in seconds to ~1 min, when the next step depends on the result.

**Background** (`run_in_background: true` on the Bash call): `high`/`xhigh` runs, or fanning out several codex tasks at once. The harness notifies you when the run exits — do not poll. "One peek after a short wait" is polling: the harness hard-blocks `sleep N && tail ...` chains. A mid-flight glance without the sleep is fine (tail the task's output file directly, then continue your own work); a genuine wait-on-condition belongs in the Monitor tool. Keep `-o <file>` so the final message is trivial to read on completion, and continue your own work meanwhile. For parallel fan-out, give each run its own `--cd` workdir (git worktrees if they share a repo) so they don't clobber each other.

## Model and reasoning default

Use `gpt-6-astra` with `high` for implementers, reviewers, and fixers, including mechanical edits. Do not choose a cheaper model or lower effort based on task size, or raise effort based on task risk. An explicit user request overrides either setting; keep the other at its default unless the user also changes it. Use the same selection on a retry, account switch, or resumed run.

If the requested model or effort is unavailable, report the limitation rather than silently substituting. Check the current CLI help and model metadata before using a user-requested alternative; do not infer CLI effort support from another harness.

For a safeguard refusal on authorized defensive work, clarify the actual authorized scope. If it remains refused, report it; do not switch models or accounts to bypass safeguards.

## Steering the delegated agent

It follows constraints literally, so state them:

- Self-contained prompt: name the files, the exact expected behavior, and an acceptance check it can run ("Run `python3 stats.py`; it must print ok").
- Scope hard or it ceremonializes: "Only modify X. Make the minimal change. Do not add tests or refactor unless asked."
- Missing-target guard: when the task touches anything destructive or the target might not exist, add: "If a named file/path/target doesn't exist, stop and report — do not substitute."
- Iterate instead of restarting: the session id is in the run header — resume it to keep its context (see "Resuming a session"; the flag set differs from fresh runs).

## Resuming a session

`codex exec resume` accepts only a subset of the `codex exec` flags. `--cd`/`-C`, `--sandbox`/`-s`, and `--add-dir` do not exist on it — reusing the fresh-run template after `resume` dies with `unexpected argument '--cd' found`. Follow-up template:

```bash
(cd <workdir> && codex exec resume <session-id> \
  --skip-git-repo-check \
  --ignore-user-config \
  -c sandbox_mode=workspace-write \
  -m gpt-6-astra \
  -c model_reasoning_effort=high \
  -o /tmp/codex-last.txt \
  "<follow-up prompt>") </dev/null
```

- Workdir: no `--cd`, so `cd` first — the subshell keeps it scoped. Being in the right directory also matters for `resume --last`, which picks the newest session recorded for the current cwd.
- Sandbox: no `--sandbox`, so the config override `-c sandbox_mode=workspace-write` does the same job. It is still needed next to `--ignore-user-config`, which resets the sandbox to read-only just like on fresh runs.
- Everything else carries over unchanged: `-c` overrides, `-o`, `-m`, `--json`, `--output-schema`, `--skip-git-repo-check`, `--ignore-user-config`, the ≥600s timeout, and the blocking-vs-background choice.

## Verifying the result

Read the `-o` final message against the actual diff and confirm that the acceptance checks ran and passed from their output. Apply this to every delegated run, including the default Astra/high pair. Check that changes stay within the requested files and behavior before accepting the result.

Keep `--sandbox workspace-write` for implementation and `--sandbox read-only` for reviewers; do not escalate a delegated run to `danger-full-access`.

## Rate limits — two accounts, then the harness

`codex` and `codex-a` are independent installs on separate OpenAI accounts (`codex-a` is a shell wrapper that sets `CODEX_HOME=~/.codex-a`; distinct auth verified). On a rate-limit/usage-cap error, rerun the identical command with `codex-a` — it takes the exact same flag set (verified e2e on 0.144.1). If both accounts are capped, don't wait out the window: fall back to the harness's own agents (Agent tool) for the task.

Caveat: sessions are per-`CODEX_HOME`, so a run started on `codex` cannot be `resume`d on `codex-a` — a mid-conversation account switch means a fresh, self-contained prompt.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Bare `codex` in a shell tool | `codex exec` — the TUI hangs headless shells |
| Missing explicit model/effort flags | `-m gpt-6-astra -c model_reasoning_effort=high` on fresh and resumed runs, unless the user overrides them |
| Changing model or effort based only on task size or risk | Keep Astra/high unless the user explicitly requests a change |
| Letting codex read plugin ceremony | `--ignore-user-config` + subagent-dispatch line in the prompt |
| Default 120s Bash timeout | ≥600s, or background the call |
| `sleep N && tail` to peek at a background run | Harness blocks it. Tail the output file now (no sleep), or wait for the exit notification |
| Taking a delegated run's "done" at face value | Read the actual diff and acceptance-check output |
| Re-prompting from scratch to fix its output | `codex exec resume <session-id> "..."` |
| Fresh-run flags on `resume` (`--cd`, `--sandbox`) | `cd <workdir>` first + `-c sandbox_mode=workspace-write` — see "Resuming a session" |
