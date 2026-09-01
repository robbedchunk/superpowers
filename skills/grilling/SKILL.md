---
name: grilling
description: "Opt-in only: Use when the user explicitly opts into Superpowers for the current request, explicitly names superpowers:grilling, or matches this skill's declared trigger — asking to be grilled ('grill me', 'grill this', 'grill the plan', 'grill me on X'). Never auto-invoke from task relevance alone. Interviews the user in rounds across a design tree while sharpening the project's domain language, writing resolved terms into CONTEXT.md and hard decisions into docs/superpowers/adr/ as they crystallise."
---

<OPT-IN-BOUNDARY>
Use this workflow when the current request explicitly opts into Superpowers, explicitly names `superpowers:grilling`, or matches this skill's declared trigger: the user asking to be grilled — "grill me", "grill this", "grill the plan", "grill me on X" — a standing authorization recorded per the Declared-trigger clause in `using-superpowers`. Task relevance outside those triggers is never permission: a user thinking out loud about a half-formed plan has not asked to be grilled. Ask for permission before invoking another Superpowers workflow unless the user has already explicitly authorized chaining.
</OPT-IN-BOUNDARY>

# Grilling

**Announce at start:** "Using grilling to stress-test this."

Two halves run at once: the **interview**, which drives to a shared understanding, and the **domain model**, which writes down the vocabulary and the hard decisions the interview settles. Both are this skill. There is no interview-only mode to fall back to — if nothing qualifies to be written, nothing gets written, and that is a normal session, not a degraded one.

## The interview

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.

## Sharpening the domain model

Run these throughout the interview — they generate frontier questions, they don't wait until the end.

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account': do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible. Which is right?"

## Writing it down

### Where to write

Decisions go to the repo's ADR location (`docs/superpowers/adr/NNNN-<slug>.md` unless the repo says otherwise) — a sibling of `docs/superpowers/plans/` and `docs/superpowers/specs/`, so everything this suite writes lives under one root.

The glossary is the deliberate exception: `CONTEXT.md` goes at the **repo root**, or in the relevant context's directory if a `CONTEXT-MAP.md` at the root marks the repo as multi-context. It is vocabulary every reader and every agent should hit without being told where to look — burying it under a tool's directory defeats what it is for.

Create files lazily: only when you have something to write. Nothing exists until the first term or decision crystallises, so there is nothing to scaffold up front.

<TARGET-GATE>
Before the first file lands, confirm the subject of the grilling is the domain of the repo you are in. Grilling about a business decision, a strategy call, or another system entirely — while the working directory happens to be a code repo — writes nothing into that repo. Ask where it should go, or keep the session in conversation. Never write into a repo the interview is not about.
</TARGET-GATE>

### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Don't batch these up: capture them as they happen. Use the format in [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md).

`CONTEXT.md` should be totally devoid of implementation details. Do not treat `CONTEXT.md` as a spec, a scratch pad, or a repository for implementation decisions. It is a glossary and nothing else.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse**: the cost of changing your mind later is meaningful
2. **Surprising without context**: a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off**: there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. Use the format in [ADR-FORMAT.md](ADR-FORMAT.md).

## What the session does NOT capture

The glossary is not a spec, and most settled answers earn neither a term nor an ADR — they exist only in this conversation. That is the known gap in this workflow, and it is where precise answers get lost: ordering guarantees, negative requirements, numeric defaults, and exact thresholds soften into vague prose if anything downstream re-derives them from memory instead of from the transcript.

Commit the glossary and ADR changes as they land — they are the record of intent, the same way a plan is. Everything else rides on the transcript until a plan absorbs it, which is why the session must never end on a vague note.

## The understanding gate

When the frontier empties, put it to the user as three explicit options — never a bare "does that make sense?":

- **Confirm the understanding** — proceed to `superpowers:writing-plans` to commit the settled tree to a plan, or `superpowers:plan-delegate-review` to plan and build it. Ask first unless the user already authorized chaining for this request. Carry the exact values from the answers into the plan, then re-read the plan against what the user actually said rather than assuming it captured them.
- **Hold** — stop; the committed glossary and ADRs are the deliverable, and a later "go" (this session or a fresh one) resumes without re-interviewing.
- **Produce a handoff** — write the handoff below, then stop as with hold.

**Handoff** (also the right move whenever the session must stop mid-interview — usage limits, end of day): one file at `docs/superpowers/plans/YYYY-MM-DD-<topic>-GRILL-HANDOFF.md`, left uncommitted — it may name credentials, hosts, or session facts that don't belong in history.

Where `plan-delegate-review`'s handoff points and never restates, this one **restates** — deliberately. That handoff sits beside a committed plan holding every decision; here no such artifact exists, and the transcript is the only copy of the settled answers. A grilling handoff that merely points would hand the next session an empty room. Contents, in order: the one-line resume instruction ("resume this grilling; the settled answers below are approved, do not re-ask them"); every settled decision with its **exact values verbatim** — thresholds, ordering guarantees, negative requirements, numeric defaults — never paraphrased; the unexplored frontier, as the questions that would have been the next round; pointers (path + sha) to the terms and ADRs already written, which are the one part that does not need restating; and any open user-owned prerequisite the interview was blocked on.

---

Adapted from the `grilling`, `grill-with-docs`, and `domain-modeling` skills in [mattpocock/skills](https://github.com/mattpocock/skills) (MIT © 2026 Matt Pocock). Upstream splits these three ways — a one-line `grill-with-docs` delegating to the other two — whose most-reported failure is partial loading: the interview runs, the writing half never loads, and the session leaves no paper trail. Folding them into one skill removes that failure mode.
