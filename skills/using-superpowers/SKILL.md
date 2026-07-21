---
name: using-superpowers
description: "Opt-in only: Use when the user explicitly asks to use Superpowers for the current request, asks how Superpowers works, or explicitly names superpowers:using-superpowers. Never auto-invoke at conversation start or from task relevance alone."
---

<OPT-IN-BOUNDARY>
Superpowers is explicitly opt-in. Installing the plugin, starting a conversation, or noticing that a workflow might be relevant is never permission to invoke it.

- **Suite-wide opt-in:** If the current user request clearly asks to use Superpowers, select and invoke the initial relevant Superpowers workflow for that request.
- **Single-workflow opt-in:** If the user names one `superpowers:<workflow>`, invoke that workflow.
- **Chaining permission:** Ask for permission before invoking another Superpowers workflow unless the user has already explicitly authorized chaining. Requests such as "chaining is fine," "run the full Superpowers workflow," or an equivalent instruction provide that authorization for the current request.
- **No opt-in:** If the current user request does not explicitly ask for Superpowers or name a Superpowers workflow, do not invoke any Superpowers skill.

Opt-in applies to the current request. Do not silently turn it into a default for later requests.
</OPT-IN-BOUNDARY>

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill unless the dispatch prompt explicitly opts into Superpowers.
</SUBAGENT-STOP>

## When Activated

After explicit opt-in, announce "Using [skill] to [purpose]" and follow the selected workflow exactly. If it has a checklist, create a todo per item.

When multiple workflows may apply, choose the initial workflow using process-first priority. Before transitioning to another workflow, apply the chaining permission rule above.

Examples:

- "Use Superpowers to build X" permits the initial `superpowers:brainstorming` workflow; ask before transitioning to another workflow.
- "Use Superpowers to build X; chaining is fine" permits relevant workflow transitions without additional confirmation for that request.
- "Use superpowers:systematic-debugging for this bug" permits `superpowers:systematic-debugging`; ask before transitioning to another workflow.
- "Fix this bug" does not opt into Superpowers. Handle it without Superpowers workflows.

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills. Superpowers workflows apply only within the explicit opt-in boundary above.
