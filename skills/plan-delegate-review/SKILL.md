---
name: plan-delegate-review
description: "Opt-in only: Use when the user explicitly opts into Superpowers for a plan-and-implement request, explicitly names superpowers:plan-delegate-review, or matches this skill's declared trigger — entering plan mode for implementation work, asking to plan and build a feature or fix, or saying 'the usual workflow', 'full loop', 'triple review', or 'spawn the codex reviewers' (a standing authorization recorded in this skill). Never auto-invoke outside those triggers. Pipeline: plan → PR-sized slices → codex Sol xhigh implementers → simplify gate → three identically-prompted codex reviewers → coalesced findings → one validating fixer."
---

<OPT-IN-BOUNDARY>
Use this workflow when the current request explicitly opts into Superpowers with a plan-and-implement request, explicitly names `superpowers:plan-delegate-review`, or matches this skill's declared trigger: the user entering plan mode (or asking to plan) for implementation work — a standing authorization recorded per the Declared-trigger clause in `using-superpowers`. Task relevance outside those triggers is never permission. Ask for permission before invoking another Superpowers workflow unless the user has already explicitly authorized chaining. Invoking this skill IS that authorization for `superpowers:writing-plans` in phase 1 — ask before chaining anything else. `delegating-to-codex` is not part of Superpowers; load it freely when available.
</OPT-IN-BOUNDARY>

# Plan → Delegate Slices → Simplify → Triple Review → Fix-Verify

Five phases plus a simplify gate (2.5), in order. You (Claude) are the **dispatcher**: you plan, write every prompt, spawn every agent, coalesce, verify, and push — no one else pushes.

**Announce at start:** "Using plan-delegate-review to run the full delivery pipeline."

## Phase 1 — Plan

The deliverable is a user-approved plan. The route is the user's choice — Claude's plan mode is one valid vehicle, not a requirement:

- **Brainstorm-first:** if the user wants to explore before committing (or explicitly opts into `superpowers:brainstorming`), stay in normal conversation — ask questions, surface trade-offs. Plan mode may never be entered at all; that's fine.
- **Plan-mode:** if the user enters plan mode or asks directly for a plan, research and draft it there.

Either way, research the repo until the plan has no placeholders, then write it per `superpowers:writing-plans`: engineering-brief tasks sized as PR-able vertical slices (2–5 for a medium feature), each with `Depends on:`, `Files:`, Consumes/Produces interfaces, exact-value requirements, described acceptance tests, and a "Done when" gate. Code only where the exact shape IS the requirement. Save to the repo's plan location (`docs/superpowers/plans/YYYY-MM-DD-<feature>.md` unless the repo says otherwise) and get explicit approval before phase 2.

Work happens in a task worktree — primary checkouts stay read-only (`<repo>/.worktrees/<slug>`; follow the repo's worktree doc where one exists). Create it after plan approval, before phase 2.

## Phase 2 — Delegate slices to codex Sol xhigh

Load `delegating-to-codex` (user-level skill) for the command template, flags, and background-run rules. Then, per slice, in dependency order (file-disjoint ready slices may run in parallel, each in its own worktree):

- Model/effort: `-m gpt-5.6-sol -c model_reasoning_effort=xhigh`. This deliberately overrides that skill's Terra-as-workhorse default — do not "correct" it back to Terra.
- Sandbox `workspace-write`, `--cd` the task worktree, background the run, ≥600s timeout.
- The slice prompt is self-contained: the task brief verbatim (the implementer never sees the whole plan), Consumes/Produces contracts, repo conventions, and acceptance checks it must actually run. Open with the subagent-dispatch line ("You are a subagent dispatched to execute this one fully-specified task; skip startup/plugin skills."); add the missing-target guard ("If a named file/path/target doesn't exist, stop and report — do not substitute.") and the YAGNI clause ("Build exactly what the contract and acceptance checks require — no speculative abstractions, config surface, or indirection; three similar lines beat one premature helper.").
- On completion, verify like a dispatcher: read the `-o` final message against the actual diff and confirm the acceptance checks *ran* (output present) — Sol xhigh is exactly the fabricated-completion quadrant.

## Phase 2.5 — Simplify gate

When all slices are in and the branch is coherent — before any review brief is written — spawn ONE harness `code-simplifier` agent (Agent tool) on the task worktree. Deliberately Claude-side, not another codex: Sol judging Sol's abstractions shares the priors that produced them. Its prompt pins:

- **Scope:** only code this branch introduced (`git diff origin/<trunk>...HEAD`) — same scope rule as the reviewers.
- **Frozen:** Consumes/Produces contracts and public API. No behavior change.
- **Bias:** deletion over rewriting — speculative abstractions, unused config surface, and single-caller indirection go first. No-op license: "if nothing warrants removal, say so and change nothing."
- **Proof:** the slices' acceptance checks (list the exact commands) must actually re-run and pass, output shown.
- **Commit:** own commit(s), revertible wholesale. Do NOT push.
- **Output:** a short removed-X-because-Y list.

Verify like a dispatcher (report vs actual diff — same fabricated-completion skepticism as phase 2), then carry the removals list into the phase 3 intent paragraph. Placement is the point: reviewers see the simplified branch, so the triple review verifies the simplification for free.

## Phase 3 — Three reviewers, one identical prompt

When the simplify gate has run (a no-op, revert, or skip counts) and the branch/PR is coherent, write ONE review brief to a scratchpad file (e.g. `$SP/codex-review-prompt.txt`) and give the **exact same prompt** to three reviewers. Independence comes from separate processes, not prompt variation.

Review brief structure:

1. Subagent-dispatch opener ("skip startup/plugin skills").
2. Role + context: independent reviewer, repo one-liner (stack, domain, "financial application" where true), what shipped (PR #s / branch), and that it is **offline — no gh, no network; everything is local**.
3. How to see the change: `git diff origin/<trunk>...HEAD`, plus "read the WHOLE changed files, not just hunks", with the changed files listed.
4. Intent paragraph: what the change does, why, the prod context, what is intentionally untouched, and the phase 2.5 removals list (so reviewers don't burn findings on known-correct code or deliberate removals).
5. Numbered review dimensions (correctness + edge cases incl. how consumers use the change; repo-wide consistency; architecture/boundary rules verbatim from repo docs; unnecessary complexity — abstractions, config surface, or indirection the diff doesn't earn; "anything dangerous once X goes live" where relevant).
6. Scope + format: confine findings to the diff; pre-existing issues listed separately as non-blocking. **Do NOT modify any files.** Output a numbered list — each finding gets file:line, a severity tag (`blocking / should-fix / nit / pre-existing-non-blocking`), and 1–3 lines of rationale. "If you find nothing blocking, say so explicitly."

Spawn all three in the same turn, backgrounded:

```bash
SP=<scratchpad>; codex exec --cd <worktree> --skip-git-repo-check \
  --sandbox read-only --ignore-user-config \
  -m gpt-5.6-sol -c model_reasoning_effort=<high|xhigh> \
  -o "$SP/codex-review-N.txt" "$(cat $SP/codex-review-prompt.txt)" </dev/null
```

- Effort dial: `high` for routine diffs; `xhigh` when the change touches money paths, concurrency, or security.
- Run reviewer 3 as `codex-a exec` (second account) to spread rate limits.
- Wait via task notifications or one Monitor on all three — never `sleep && tail` polling. Work on something else meanwhile (e.g. the PR description — read the owning repo/workspace PR-description rules before drafting; in hawkeye-master that's docs/operating-scope.md "Pull Request Descriptions": "## What this does, in plain English" first, then the collapsed Code mapping details block, then the technical description).

## Phase 4 — Coalesce, then one fixer that validates and fixes

**Coalesce yourself** (plain reading, not another agent): dedupe the three reports into lettered findings A, B, C… with attribution ("reviewers 1 and 3", "reviewer 2 only") and file:line. Attribution matters — a 3/3 finding and a 1/3 finding deserve different skepticism.

Then spawn ONE fixer/verifier codex (Sol, same effort as reviewers, `--sandbox workspace-write`, `--add-dir` for any sibling worktree/`.git` it must reach). Its prompt has three parts:

- **PART 1 — review context**: the reviewer prompt's context verbatim, so the fixer judges findings with the same information.
- **PART 2 — coalesced findings**: the lettered list, attributions included.
- **PART 3 — validate, then fix what survives**: for EACH finding decide (a) is it factually real — name the exact consumer files and repo-doc invariants to check it against; and (b) is it in scope for THIS branch/PR? Verdict per finding: `fix-here / valid-but-out-of-scope (separate PR) / invalid`, with 1–3 lines of justification. For each fix-here: minimal fix in the current worktree following repo conventions (test-first where the repo does TDD) — the smallest diff that resolves the finding; no new abstractions, config surface, or indirection — then named acceptance checks that **must actually run and pass** (list the exact commands), then commit with a conventional message ending in the Claude co-author trailer. If the change spans mirrored branches (e.g. main + staging hotfix pair), cherry-pick the commits to the sibling worktree and re-run the tests there. **Do NOT push.** Missing-target guard. If nothing survives validation, make no commits. Final output: per-finding verdict + justification, commits made (sha + headline) per branch, and the tail of the test output proving the checks ran.

`valid-but-out-of-scope` verdicts don't die — surface them to the user and offer to spawn follow-up tasks.

## Phase 5 — Land

Read the fixer's report against the actual diff (never take "done" at face value), with the simplify lens on: is any fix bigger than its finding warrants? A ballooned fix gets bounced: redo it minimally, or re-run one reviewer on just that diff — never accept-then-refactor, since a fix big enough to need its own simplify pass needed re-review anyway. Then run the repo's targeted validation yourself if anything looks off, push, and report per the repo's done criteria: changed files, tests run, findings table (A/B/C → verdict), and anything deferred out of scope.

## Failure handling

- Simplify gate breaks an acceptance check, or its report doesn't match its diff: revert the simplifier's commit(s) and proceed to review — the gate is optional, the review isn't.
- No `code-simplifier` agent type in this harness: use a general-purpose agent with the same pinned prompt; if no harness agents at all, skip the gate rather than handing it to Sol.
- Sol safeguard false-positive on benign security work: restate defensive intent or retry per `delegating-to-codex`; tell the user it happened.
- Rate-limited account: rerun the identical command on the other account (`codex` ↔ `codex-a`); if both are capped, fall back to harness Agent-tool reviewers with the same prompt rather than stalling.
- A reviewer that returns garbage or dies: rerun it once; proceed with two independent reports only if the user agrees.
- No codex CLI on this machine at all: run the same pipeline with harness subagents (three Agent-tool reviewers with the identical brief, one fixer agent) — the prompts, not the binary, are the workflow.
