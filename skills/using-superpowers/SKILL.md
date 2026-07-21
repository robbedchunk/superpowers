---
name: using-superpowers
description: "Opt-in only: Use when the user explicitly asks to use Superpowers for the current request, asks how Superpowers works, or explicitly names superpowers:using-superpowers. Never auto-invoke at conversation start or from task relevance alone."
---

<OPT-IN-BOUNDARY>
Superpowers is explicitly opt-in. Installing the plugin, starting a conversation, or noticing that a workflow might be relevant is never permission to invoke it.

- **Suite-wide opt-in:** If the current user request clearly asks to use Superpowers, select and invoke the relevant Superpowers workflows for that request.
- **Single-workflow opt-in:** If the user names only one `superpowers:<workflow>`, invoke only that workflow. Do not chain into other Superpowers workflows unless the user separately names them or expands the request to Superpowers generally.
- **No opt-in:** If the current user request does not explicitly ask for Superpowers or name a Superpowers workflow, do not invoke any Superpowers skill.

Opt-in applies to the current request. Do not silently turn it into a default for later requests.
</OPT-IN-BOUNDARY>

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill unless the dispatch prompt explicitly opts into Superpowers.
</SUBAGENT-STOP>

## When Activated

After explicit opt-in, announce "Using [skill] to [purpose]" and follow the selected workflow exactly. If it has a checklist, create a todo per item.

When the user opts into the suite generally and multiple workflows apply, process skills come first because they set the approach, followed by implementation skills.

Examples:

- "Use Superpowers to build X" permits `superpowers:brainstorming` and later relevant workflows for that request.
- "Use superpowers:systematic-debugging for this bug" permits only `superpowers:systematic-debugging` until the user opts into another workflow.
- "Fix this bug" does not opt into Superpowers. Handle it without Superpowers workflows.

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills. Superpowers workflows apply only within the explicit opt-in boundary above.
