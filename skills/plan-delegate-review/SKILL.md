---
name: plan-delegate-review
description: "Opt-in only: Use when the user explicitly opts into Superpowers for a plan-and-implement request, explicitly names superpowers:plan-delegate-review, or matches this skill's declared trigger — entering plan mode for implementation work, asking to plan and build a feature or fix, or saying 'the usual workflow', 'full loop', 'triple review', or 'spawn the codex reviewers' (a standing authorization recorded in this skill). Never auto-invoke outside those triggers. Pipeline: plan with slices mapped to PRs → codex Sol xhigh implementers → per PR: simplify gate → three identically-prompted codex reviewers → coalesced findings → one validating fixer → land in dependency order."
---

<OPT-IN-BOUNDARY>
Use this workflow when the current request explicitly opts into Superpowers with a plan-and-implement request, explicitly names `superpowers:plan-delegate-review`, or matches this skill's declared trigger: the user entering plan mode (or asking to plan) for implementation work — a standing authorization recorded per the Declared-trigger clause in `using-superpowers`. Task relevance outside those triggers is never permission. Ask for permission before invoking another Superpowers workflow unless the user has already explicitly authorized chaining. Invoking this skill IS that authorization for `superpowers:writing-plans` in phase 1 — ask before chaining anything else. `delegating-to-codex` is not part of Superpowers; load it freely when available.
</OPT-IN-BOUNDARY>

# Plan → Delegate Slices → Simplify → Triple Review → Fix-Verify

Five phases plus a simplify gate (2.5), in order; phases 2.5–5 run at least one full cycle per PR the plan declares (usually one PR) — re-entry rules repeat a cycle, never skip one. You (Claude) are the **dispatcher**: you plan, write every prompt, spawn every agent, coalesce, verify, and push — no one else pushes.

**Announce at start:** "Using plan-delegate-review to run the full delivery pipeline."

## Phase 1 — Plan

The deliverable is a user-approved plan. The route is the user's choice — Claude's plan mode is one valid vehicle, not a requirement:

- **Brainstorm-first:** if the user wants to explore before committing (or explicitly opts into `superpowers:brainstorming`), stay in normal conversation — ask questions, surface trade-offs. Plan mode may never be entered at all; that's fine.
- **Plan-mode:** if the user enters plan mode or asks directly for a plan, research and draft it there.

Either way, research the repo until the plan has no placeholders, then write it per `superpowers:writing-plans`: engineering-brief tasks sized as PR-able vertical slices (2–5 for a medium feature), each with `Depends on:`, `Files:`, Consumes/Produces interfaces, exact-value requirements, described acceptance tests, a "Done when" gate, and `Lands in: PR-<n>` naming the PR the slice ships in. The plan header declares each PR's base branch — the trunk, or the prior PR's branch when stacked — and may declare one optional stack-wide integration audit (run in phase 5). A plan that doesn't map every slice to a PR is incomplete; a single-PR plan (the common case) may declare the mapping once in the header — all slices land in PR-1, base the trunk — and phases 2.5–5 then run exactly once. Code only where the exact shape IS the requirement. Save to the repo's plan location (`docs/superpowers/plans/YYYY-MM-DD-<feature>.md` unless the repo says otherwise). Then put the **plan gate** to the user as three explicit options — never a bare "proceed?":

- **Approve the plan** — enter phase 2.
- **Hold the plan** — stop; the committed plan is the deliverable, and a later "go" (this session or a fresh one) re-enters at phase 2 with no re-planning.
- **Produce a handoff** — write the handoff below, then stop as with hold.

**Handoff** (also the right move whenever the session must stop mid-pipeline — usage limits, end of day): one lean file beside the plan, `<plan-basename>-HANDOFF.md`, left uncommitted — it may name credentials, hosts, or session facts that don't belong in history. It points, never restates: the committed plan (path + sha) stays the single source of truth. Contents, in order: the one-line resume instruction ("execute this plan; design approved, no re-planning"); a portability note — this pipeline was authored for a specific harness, and its mechanics (codex delegation, agent counts, this skill itself) are optional: any executor may use its own tools so long as each PR is reviewed before it is pushed; environment facts an executor can't derive from the repo (deploy quirks, sandbox caveats, services that must be running, secrets to mint); open user-owned prerequisites; and, when stopping mid-pipeline, one status line per declared PR (branch, phase reached, pushed or not). Nothing else — a handoff that restates the plan will drift from it.

Work happens in task worktrees — primary checkouts stay read-only (`<repo>/.worktrees/<slug>`; follow the repo's worktree doc where one exists). Create one per declared PR, on that PR's declared branch, after plan approval and before phase 2.

## Phase 2 — Delegate slices to codex Sol xhigh

Load `delegating-to-codex` (user-level skill) for the command template, flags, and background-run rules. Then, per slice, in dependency order (file-disjoint ready slices may run in parallel, each in its own worktree):

- Model/effort: `-m gpt-5.6-sol -c model_reasoning_effort=xhigh`. This deliberately overrides that skill's Terra-as-workhorse default — do not "correct" it back to Terra.
- Sandbox `workspace-write`, `--cd` the worktree of the PR named by the slice's `Lands in:`, background the run, ≥600s timeout.
- The slice prompt is self-contained: the task brief verbatim (the implementer never sees the whole plan), Consumes/Produces contracts, repo conventions, and acceptance checks it must actually run. Open with the subagent-dispatch line ("You are a subagent dispatched to execute this one fully-specified task; skip startup/plugin skills."); add the missing-target guard ("If a named file/path/target doesn't exist, stop and report — do not substitute.") and the YAGNI clause ("Build exactly what the contract and acceptance checks require — no speculative abstractions, config surface, or indirection; three similar lines beat one premature helper.").
- On completion, verify like a dispatcher: read the `-o` final message against the actual diff and confirm the acceptance checks *ran* (output present) — Sol xhigh is exactly the fabricated-completion quadrant.

## Phase 2.5 — Simplify gate

Phases 2.5–5 run as a full cycle per PR the plan declares, in dependency order; phase 5 hands off to the next PR. Each declared PR has one branch and one worktree; a slice implemented in a parallel worktree lands back on its PR's branch (merge or fast-forward) before that PR enters phase 2.5. Entering phase 2.5 requires, in order: rebase the PR's branch onto the current tip of its declared base (a no-op when already current); pin the base — `BASE=$(git rev-parse <base-branch>)` — and use `$BASE`, never a branch name, in every command of this cycle; run the union of the PR's slices' acceptance checks on the assembled head, output in hand. The simplify gate, the review brief, and the fixer all operate on the same diff: `git diff $BASE...HEAD`. If the base branch moves after pinning — fixer commits landing on the base PR, or the base PR merging — rebase onto the new tip (onto the trunk once the base PR has merged), re-pin, and recompute the diff: the review stands only when it is byte-identical to the diff the reviewers received AND the PR's acceptance checks pass on the rebased head; anything else re-enters phase 2.5. (Documented tradeoff: an unchanged patch over a moved base can still change behavior in ways the checks don't cover — accepted so stacking stays affordable.)

Two invariants and one license govern the cycles. No PR's branch is pushed before phases 2.5–4 have run on it; the only commits allowed after its reviewers run are fixer commits, which phase 5 validates (a ballooned fix goes back to review per phase 5). No review's diff spans more than one PR's changes — the sole exception is the plan-declared stack audit (phase 5), which supplements per-PR cycles, never replaces them. While one PR is in phases 3–5, implementing a later PR's slices in its own worktree is allowed.

With the entry conditions met — before any review brief is written — spawn ONE harness `code-simplifier` agent (Agent tool) on the PR's worktree. Deliberately Claude-side, not another codex: Sol judging Sol's abstractions shares the priors that produced them. Its prompt pins:

- **Scope:** only code this PR introduced (`git diff <base>...HEAD`) — same scope rule as the reviewers.
- **Frozen:** Consumes/Produces contracts and public API. No behavior change.
- **Bias:** deletion over rewriting — speculative abstractions, unused config surface, and single-caller indirection go first. No-op license: "if nothing warrants removal, say so and change nothing."
- **Proof:** the slices' acceptance checks (list the exact commands) must actually re-run and pass, output shown.
- **Commit:** own commit(s), revertible wholesale. Do NOT push.
- **Output:** a short removed-X-because-Y list.

Verify like a dispatcher (report vs actual diff — same fabricated-completion skepticism as phase 2), then carry the removals list into the phase 3 intent paragraph. Placement is the point: reviewers see the simplified branch, so the triple review verifies the simplification for free.

## Phase 3 — Three reviewers, one identical prompt

When the simplify gate has run (a no-op, a revert, or a failure-handling skip counts), write ONE review brief to a scratchpad file (e.g. `$SP/codex-review-prompt.txt`) and give the **exact same prompt** to three reviewers. Independence comes from separate processes, not prompt variation.

Review brief structure:

1. Subagent-dispatch opener ("skip startup/plugin skills").
2. Role + context: independent reviewer, repo one-liner (stack, domain, "financial application" where true), what shipped (the PR under review — its plan id, branch, and base), and that it is **offline — no gh, no network; everything is local**.
3. How to see the change: `git diff <base>...HEAD` (the PR's declared base), plus "read the WHOLE changed files, not just hunks", with the changed files listed.
4. Intent paragraph: what the change does, why, the prod context, what is intentionally untouched, and the phase 2.5 removals list (so reviewers don't burn findings on known-correct code or deliberate removals). Attach the PR's task briefs from the plan — Interfaces and Requirements verbatim — so reviewers judge against the approved contracts, not just prose intent.
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
- **PART 3 — validate, then fix what survives**: for EACH finding decide (a) is it factually real — name the exact consumer files and repo-doc invariants to check it against; and (b) is it in scope for THIS branch/PR? Verdict per finding: `fix-here / valid-but-out-of-scope (separate PR) / invalid`, with 1–3 lines of justification. For each fix-here: minimal fix in the current worktree following repo conventions (test-first where the repo does TDD) — the smallest diff that resolves the finding; no new abstractions, config surface, or indirection — then named acceptance checks that **must actually run and pass** (list the exact commands), then commit with a conventional message ending in the Claude co-author trailer. A mirrored deployment branch (e.g. a main + staging hotfix pair) is a landing target for already-reviewed commits, not a second review branch: cherry-pick the reviewed commits to the sibling worktree and re-run the tests there — same reviewed diff, so no separate cycle. **Do NOT push.** Missing-target guard. If nothing survives validation, make no commits. Final output: per-finding verdict + justification, commits made (sha + headline) per branch, and the tail of the test output proving the checks ran.

`valid-but-out-of-scope` verdicts don't die — surface them to the user and offer to spawn follow-up tasks.

## Phase 5 — Land

Read the fixer's report against the actual diff (never take "done" at face value), with the simplify lens on: is any fix bigger than its finding warrants? A ballooned fix gets bounced: redo it minimally, then re-run one reviewer on just the redone diff — never accept-then-refactor, since a fix big enough to need its own simplify pass needed re-review anyway. Then confirm the PR's acceptance checks passed on its final head — rerun them yourself when the fixer's output doesn't show them — push, and report per the repo's done criteria: changed files, tests run, findings table (A/B/C → verdict), and anything deferred out of scope.

Landing a PR does not end the pipeline: if the plan declares more PRs, the next one in dependency order enters phase 2.5 (after any rebase the base-move rule requires). If the plan declared a stack audit, run it before the final PR's push: pin the trunk (`TRUNK=$(git rev-parse <trunk>)`) and run one phase-3 review pass whose diff is the whole stack (`git diff $TRUNK...HEAD` on the final PR's branch), findings coalesced and fixed per phase 4 — fixes belonging to the final unpushed PR land there. A blocking audit finding against an already-landed PR halts the pipeline: hold the final PR's push and stop for the user's disposition (fix-forward PR now, accept and push, or hold); non-blocking findings are surfaced as follow-up work, never silently dropped. The pipeline ends when every declared PR has landed and the report covers them all.

## Failure handling

- A finding invalidates an approved plan decision (a Consumes/Produces contract, a Global Constraint, an exact requirement, contract code, or the PR topology itself): stop the cycle, surface it to the user, amend the plan only with their approval, then re-enter every affected PR at phase 2 — slices already implemented against the old contract get re-verified against the amended one.
- Simplify gate breaks an acceptance check, or its report doesn't match its diff: revert the simplifier's commit(s) and proceed to review — the gate is optional, the review isn't.
- No `code-simplifier` agent type in this harness: use a general-purpose agent with the same pinned prompt; if no harness agents at all, skip the gate rather than handing it to Sol.
- Sol safeguard false-positive on benign security work: restate defensive intent or retry per `delegating-to-codex`; tell the user it happened.
- Rate-limited account: rerun the identical command on the other account (`codex` ↔ `codex-a`); if both are capped, fall back to harness Agent-tool reviewers with the same prompt rather than stalling.
- A reviewer that returns garbage or dies: rerun it once; proceed with two independent reports only if the user agrees.
- No codex CLI on this machine at all: run the same pipeline with harness subagents (three Agent-tool reviewers with the identical brief, one fixer agent) — the prompts, not the binary, are the workflow.
