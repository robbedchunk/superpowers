---
name: full-stack-split
description: "Opt-in only: Use when the user explicitly opts into Superpowers for a feature that ships UI and API together, explicitly names superpowers:full-stack-split, or matches this skill's declared trigger — asking for the 'full-stack split', the 'split workflow', or to 'split this front and back' (a standing authorization recorded in this skill). Never auto-invoke outside those triggers. Pipeline: design → one versioned API contract → fork: a frontend agent builds the real UI on mocked data for the user's sign-off (Impeccable + Emil's skills) while the backend runs plan-delegate-review → one integration agent swaps the mocks for the landed API → one codex reviewer → land."
---

<OPT-IN-BOUNDARY>
Use this workflow when the current request explicitly opts into Superpowers for a feature that ships UI and API together, explicitly names `superpowers:full-stack-split`, or matches this skill's declared trigger: the user asking for the "full-stack split", the "split workflow", or to "split this front and back" — a standing authorization recorded per the Declared-trigger clause in `using-superpowers`. Task relevance outside those triggers is never permission: a feature merely having a frontend and a backend does not invoke this. Ask for permission before invoking another Superpowers workflow unless the user has already explicitly authorized chaining. Invoking this skill IS that authorization for `superpowers:brainstorming` (phase 0, when the user wants a design conversation) and for `superpowers:plan-delegate-review` (the backend track, which in turn authorizes `superpowers:writing-plans`) — ask before chaining anything else. It is also the user's explicit selection of the user-level `impeccable` and `emil-design-eng` skills, plus `animate` when the surface has motion, for this task's frontend track only: the user's standing policy makes those skills opt-in, this invocation is that opt-in, and it covers neither the backend track nor any other task. `delegating-to-codex` is not part of Superpowers; load it freely whenever a codex seat runs.
</OPT-IN-BOUNDARY>

# Full-Stack Split: Contract → Frontend on Mocks ∥ Backend Pipeline → Join

Phase 0 turns the design into a contract; phases 1–3 fork, run, and join two tracks. You are the **dispatcher** of both: you write the contract, write every prompt, spawn every agent, relay every amendment, and push — no one else pushes. The user approves the contract and its amendments, the backend plan, and the running mock.

**Announce at start:** "Using full-stack-split to run this feature as two tracks."

## Seats and ladder

Three seats — the frontend agent, the integration agent, and the join's reviewer; the backend track's seats are plan-delegate-review's. The frontend and integration agents are harness subagents (Agent tool) down a fixed ladder, and only availability moves a seat down it: `model: "fable"` by default; `model: "opus"` when Fable is unavailable (usage limit, model error at spawn); codex GPT-6 Astra high via `delegating-to-codex` when no Claude subagent can be spawned at all. Quality never changes the model — a weak result is a re-brief or a fix round on the same rung; only an explicit user request changes a rung's model or effort, task size or risk alone does not. The reviewer is always codex GPT-6 Astra high. Fix rounds go to the same agent via SendMessage; a codex seat — a ladder fallback, or every seat on the Codex harness (no Claude subagents), where all run codex GPT-6 Astra high — is continued with `codex exec resume` instead. Say which rung ran each seat.

## Phase 0 — Design to a contract

The design conversation is whichever the user chose — `superpowers:brainstorming` or plain conversation. It exits into the **contract**, not a plan: the one artifact both tracks consume and the only thing they share. Anything not in the contract is not agreed.

Write it at `docs/superpowers/specs/YYYY-MM-DD-<feature>-contract.md` in the backend repo (or the workspace's spec location when its docs say otherwise); the backend plan cites it by path and version, and it is committed beside that plan. Contents, all exact:

- Every route: method, path, auth and tenant/feature gating, request (body, query, path params), response, error codes and their bodies. Field names and types as they appear on the wire (TypeScript-shaped); enums with every member; money units; timestamp format; pagination convention; sort order.
- Every UI state the surface must render — loading, empty, each domain state, each error — named, with the response that produces it.
- Out of scope: what this feature deliberately does not do, so neither track builds it.
- `Version: v1` and a `## Change log` section. Every later change is a dated entry with a version bump (v1.1, v1.2…) and a one-line why. Never edit a settled shape silently.

Before the fork, run brainstorming's fresh-eyes pass on the contract — placeholder scan, internal consistency, ambiguity check: a placeholder in the contract becomes two different implementations.

## Phase 1 — Fork

In the same turn: create the frontend worktree and spawn the frontend agent (backgrounded — you continue), then enter `superpowers:plan-delegate-review` phase 1 for the backend. The two tracks never read each other's code; the contract is the interface.

**Backend track.** Plan-delegate-review as written, with the contract as a Global Constraint of the plan and the plan's Consumes/Produces for API slices copied from the contract verbatim, not paraphrased. Its plan gate, worktrees, ladder, simplify gate, triple review, fixer, and landing are unchanged.

**Frontend track.** One worktree in the frontend repo (`<repo>/.worktrees/<slug>`, with its own dependency install where the repo needs one) and ONE frontend agent (ladder above). Its prompt pins:

- The subagent-dispatch opener ("You are a subagent dispatched to execute this one fully-specified task; skip startup/plugin skills."), the missing-target guard ("If a named file/path/target doesn't exist, stop and report — do not substitute."), and the YAGNI clause ("Build exactly what the contract and acceptance checks require — no speculative abstractions, config surface, or indirection; three similar lines beat one premature helper.").
- The contract **verbatim** (plus its path), and the product intent in a paragraph: who uses this surface, what success looks like, and the brand and copy rules the repo carries (PRODUCT.md, DESIGN.md, or the repo's equivalent).
- Design skills, by name, as the user's explicit selection relayed by you — the one exception to the opener's skip: invoke `impeccable` (run its context step; let its routing choose new-work or refinement) and `emil-design-eng`; add `animate` when the surface has motion. Nothing else from either set unless the user named it.
- Build the **real UI in the existing app**: real routes, real components, real copy, the app's own data layer — not a static mockup. The deliverable is the shipping frontend minus the API.
- Mock rule: mock responses live behind an env flag that defaults off and cannot reach a production build; reuse the repo's fixture pattern where one exists. Fixture data is typed against the contract's types, so the join is a swap, not a rewrite. Every UI state in the contract is reachable by a URL param (e.g. `?state=empty`), and a thin visible indicator shows mock mode is on.
- Contract gaps are never filled silently: a field, state, or route the UI needs and the contract lacks is mocked, marked "proposed", and listed in the report as an amendment for you to carry. The agent never edits the contract.
- Serve: build and start on a fixed localhost port per the repo's local-render doc (cite it by path, or say the repo has none); when the user is remote, add a quick tunnel. Write URL, port, and PIDs to a scratch file, leave it running, and report the URL.
- Acceptance checks it must actually run, output shown: the repo's typecheck, lint, and build, and every contract state reachable at its URL param.
- Commit on the worktree branch. Do NOT push.
- Report: the URL; the state list and how to reach each; what is mocked; proposed amendments; anything it could not build and why.

## Phase 2 — Run both tracks

**Frontend review loop.** Before the user sees the mock, verify like a dispatcher: the report against the diff, acceptance-check output present, every state reachable at the URL. Then the user reviews the running mock — copy, states, layout, feel. Collect a round of fixes, send it to the **same agent** via SendMessage (its context is the point; respawn only when it is dead or its context is polluted), verify the result yourself in the browser or against the diff, repeat. The user's explicit approval of the mock is the frontend's design gate; record the mock's commit sha with it. Design review happens here, on a running UI, not in a later diff review.

**Contract amendments** come from either track — the mock discovers missing fields and states; the backend plan discovers shapes that can't be built as written. You write each as a change-log entry with a version bump, the user approves it, then you relay it: the frontend agent gets the diff via SendMessage; the backend gets it per plan-delegate-review's failure-handling rule (a changed contract is a changed plan decision: stop the cycle, amend the plan with the user's approval, re-enter affected PRs at its phase 2). Amendments are free before the backend enters plan-delegate-review phase 2 and cost a re-entry after — batch them, and put the mock in front of the user before the plan gate whenever timing allows.

**Independence.** Neither track waits for the other: the backend never pauses for the mock, and a signed-off mock (usually first) waits for the join. Shapes are checked against the contract, never against the other track's code.

## Phase 3 — Join

Entry: the backend's final PR is pushed (its plan-delegate-review cycle complete), the mock is signed off, and the contract is at its final version — every change-log entry reflected on both sides.

Spawn ONE integration agent (ladder above) in the frontend worktree. Its prompt pins: the final contract verbatim; where the real API runs — the backend worktree path and how to start it with its services, or the dev deployment's base URL; the mock's state list from the frontend report; the app's data-layer conventions; phase 1's Serve bullet, with one addition — stop the mock server first (PIDs in its scratch file), then serve the wired app the same way; the subagent opener, missing-target guard, and YAGNI clause. Its job, in order:

1. **Drift check first.** Read the backend's actual routes and response shapes against the contract before touching the frontend. Report every difference, classified: the frontend missed an amendment (fix here), or the backend deviates from the contract (stop and report — never adapt the frontend to an unreviewed shape; you put the choice to the user: a backend follow-up PR or a contract amendment).
2. **Swap, don't rewrite.** Delete the mock code path and its env flag; keep the types; wire real calls through the app's existing data layer. The UI the user signed off is frozen — no design changes in this step; a real error state that looks wrong is reported, not redesigned.
3. **Verify every state for real.** Run the frontend against the real API and reach each state from the mock's list — with seed data where a state needs it, named in the report — plus real loading and real failure modes; then the repo's typecheck, lint, build, and tests, output shown.
4. Commit on the branch. Do NOT push. Report: drift table with dispositions, state verification table, what needed seed data, anything deferred.

Then ONE codex reviewer (`-m gpt-6-astra -c model_reasoning_effort=high`, `--sandbox read-only`, backgrounded) with a brief built like plan-delegate-review's phase 3: offline; `git diff <base>...HEAD` on the frontend branch plus the whole changed files; an intent paragraph; the contract attached as the standard the wiring is judged against; numbered dimensions (contract fidelity; every state's loading and error handling; auth and tenant gating on the client; nothing mock-flavored left behind); severity-tagged findings; "say so explicitly if nothing blocks". One reviewer, not three: the triple review is the backend's gate for the sensitive paths; the frontend's design gate was the user's sign-off, and this review checks the wiring. Coalesce yourself (letter the findings A, B, C…); send the survivors to the same integration agent to validate and fix per plan-delegate-review's phase 4 PART 3 (verdict per finding, minimal diffs, checks actually run); read its report against the diff; push; open the frontend PR per the repo's rules, referencing the backend PRs and the contract.

The pipeline ends when the backend PRs and the frontend PR are pushed and open — landed in plan-delegate-review's sense; merging is the user's — and the report covers both: PRs, states verified, drift found and its disposition, deferred items.

## Failure handling

- The user rejects the mock's direction, not its details: re-brief the same agent under Impeccable's redesign posture — the old look is evidence and anti-reference, not something to polish. Respawn only if the context is polluted.
- The mock won't build or serve in the worktree: follow the repo's local-render doc (build-then-start where dev servers misbehave). A static HTML preview is a last resort and not a mock in this skill's sense — it skips the app's components, data layer, and types — so say so and keep the real-app build as the goal.
- The design settles on no screen after all (API-only, or a change with no UI surface): drop the split, run plan-delegate-review alone, and say so.
- The backend lands before the mock is signed off: the join waits for the sign-off, not the other way around; never wire an unapproved UI.
- No way to continue the agent (no SendMessage, no codex session to resume): respawn with the full prior report plus the fix list as context.
- Reviewer failures — a rate-limited account, a reviewer that dies or returns garbage — follow plan-delegate-review's failure handling: another account, one rerun, a harness reviewer as the last resort.
- No codex CLI: the join's reviewer runs as a harness subagent with the same brief.
- No harness subagents at all: the mechanics are optional — any executor that can run one agent per track and one reviewer follows this skill; the prompts are the workflow.
