---
name: grilling
description: "Opt-in only: Use when the user explicitly opts into Superpowers for the current request, explicitly names superpowers:grilling, or matches this skill's declared trigger — asking to be grilled ('grill me', 'grill this', 'grill the plan', 'grill me on X'). Never auto-invoke from task relevance alone. Interviews the user in rounds across a design tree, numbering each question and carrying a recommended answer, until nothing is silently assumed."
---

<OPT-IN-BOUNDARY>
Use this workflow when the current request explicitly opts into Superpowers, explicitly names `superpowers:grilling`, or matches this skill's declared trigger: the user asking to be grilled — "grill me", "grill this", "grill the plan", "grill me on X" — a standing authorization recorded per the Declared-trigger clause in `using-superpowers`. Task relevance outside those triggers is never permission: a user thinking out loud about a half-formed plan has not asked to be grilled. Ask for permission before invoking another Superpowers workflow unless the user has already explicitly authorized chaining.
</OPT-IN-BOUNDARY>

# Grilling

**Announce at start:** "Using grilling to stress-test this."

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

## Handing Off

Grilling produces a shared understanding, not an artifact. Once the user confirms it, ask before chaining — `superpowers:writing-plans` to commit the settled tree to a plan, or `superpowers:plan-delegate-review` to plan and build it — unless the user already authorized chaining for this request.

---

Adapted from the `grilling` skill in [mattpocock/skills](https://github.com/mattpocock/skills) (MIT © 2026 Matt Pocock). The `grill-me` alias is folded into this skill's declared trigger rather than shipped separately.
