---
name: writing-plans
description: "Opt-in only: Use when the user explicitly opts into Superpowers for the current request and wants a detailed implementation plan, or explicitly names superpowers:writing-plans. Never auto-invoke from task relevance alone."
---

<OPT-IN-BOUNDARY>
Use this workflow only when the current user request explicitly opts into Superpowers or explicitly names `superpowers:writing-plans`. Task relevance alone is never permission. Ask for permission before invoking another Superpowers workflow unless the user has already explicitly authorized chaining.
</OPT-IN-BOUNDARY>

# Writing Plans

## Overview

Write implementation plans that carry the decisions an implementer cannot cheaply rediscover: intent, interface contracts, binding constraints, and acceptance criteria. The implementer is a capable engineer with full access to the repo and its tools — linters, typecheckers, test runners. Implementation code gets written in the repo, where those tools can judge it; the plan records what must be true when the work is done, not how every line looks. DRY. YAGNI. TDD. Frequent commits.

Assume the implementer knows the language and stack well, but knows nothing about our problem domain, our spec, or the decisions made during brainstorming — the plan is where those decisions live. Each task's implementer sees only their own task, never the whole plan.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is a coherent vertical slice — the smallest unit that deserves its
own merge-gate review, sized like a reviewable PR. Fold setup,
configuration, scaffolding, and documentation into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

A medium feature is typically 2-5 tasks, not 10-15. Do not script the
implementer's moment-to-moment work — no "write the test, run it, watch it
fail, implement, commit" step lists. superpowers:test-driven-development
already governs how implementers work; the plan defines what must be true
when they finish.

Granularity is a dial, not a rule. When a slice is genuinely risky — subtle
concurrency, a security-sensitive surface, a migration that must not lose
data — split it finer so the review gate lands more often, and say in the
task why it is cut fine.

## Dependencies

Tasks form a dependency graph, and the executor schedules directly from it:
any task whose dependencies are complete and whose files don't overlap
in-flight work can run in parallel with its neighbors. You control that
scheduling with two declarations per task:

- **Depends on:** the tasks whose outputs this task consumes — or `none`.
  Declare true dependencies only. "Feels related" is not a dependency, and
  an inflated list serializes work that could have run concurrently.
- **Files:** the exact files the task creates, modifies, or tests. Two
  tasks with no dependency path between them must not share a file — if
  they do, add the real dependency or move the file to one owner.

Declare the real graph and let the executor schedule it. Don't design the
plan around parallelism or against it — a linear chain, a wide fan-out, and
a contract-defining task that unblocks three others are all fine shapes
when the dependencies are real.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Tasks declare `Depends on:` — execute in an order that satisfies dependencies.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Depends on:** Task 1, Task 2 — or `none`

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from its dependencies — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

**Requirements:**
- [What this task must do, as observable behavior. Copy exact values from
  the spec verbatim: limits, formats, defaults, error codes, user-facing
  copy.]
- [Name edge cases and error behavior specifically — "amounts above
  MAX_TRADE are rejected with error E402", never "handle invalid input".]

**Contract code** — only where the exact shape IS the requirement (public
API signature, wire format, schema/migration DDL, spec-pinned algorithm,
exact user-facing copy). Omit this section if the task has none:

```python
@app.post("/trades")
def create_trade(req: TradeRequest) -> TradeResponse: ...
```

**Acceptance tests** — described precisely enough to write without
guessing, not written as code:
- `test_rejects_oversize_trade`: amount above MAX_TRADE → E402, nothing persisted
- `test_happy_path_persists`: valid trade → row in `trades`, `TradeCreated` event emitted

**Done when:** acceptance tests pass; full suite green; lint and typecheck
clean; work committed.
````

## Requirements Are Exact; Code Is Contract-Only

Two rules, opposite directions.

**Requirements: no placeholders.** Every requirement must be specific enough to test. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases" (name the cases and the required behavior)
- "Similar to Task N" (repeat the exact values — the implementer sees only their own task)
- References to types, functions, or methods that no task Produces and the codebase doesn't already contain
- Acceptance criteria that cannot fail ("works correctly", "is robust")

**Code: contracts only.** A code block earns its place in a plan only when its exact shape is itself a requirement: a public API signature, a wire format, schema or migration DDL, exact user-facing copy, an algorithm the spec pinned down. If you catch yourself writing a function body, stop — turn it into requirements and acceptance tests. Code written in a plan is authored where no linter, typechecker, or test can judge it, then treated as authoritative by implementers even after the repo has drifted from its assumptions. Behavior belongs in the plan; implementation belongs in the repo.

## Remember
- Exact file paths always
- Exact values from the spec verbatim — numbers, formats, copy, signatures
- Acceptance tests an implementer can write without guessing
- True dependencies declared per task; concurrent tasks never share files
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for the red-flag patterns above. Fix them.

**3. Interface consistency:** Does every task's Consumes trace to another task's Produces or to existing code, with matching names and types? A function Produced as `clearLayers()` in Task 3 but Consumed as `clearFullLayers()` in Task 7 is a bug.

**4. Graph sanity:** No dependency cycles. No missing `Depends on:` — a task that Consumes what another Produces depends on it. No two tasks without a dependency path between them sharing a file.

**5. Contract-only scan:** Any code block that isn't a contract? Convert it to requirements plus acceptance tests, and delete it.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch fresh implementer subagents per task, scheduled from the dependency graph — independent tasks run in parallel — with a merge-gate review per task

**2. Inline Execution** - Execute tasks in this session using executing-plans, sequentially in dependency order

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
