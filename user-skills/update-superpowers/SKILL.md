---
name: update-superpowers
description: Update and reinstall the Superpowers plugin from the robbedchunk/superpowers GitHub fork in ~/.codex, ~/.codex-a, and Claude Code (~/.claude). Use when the user says "update superpowers", "update the superpowers", "update superpowers plugin", "refresh superpowers", or asks to pull their latest Superpowers changes.
---

# Update Superpowers

Run the bundled updater without asking for confirmation:

```bash
bash scripts/update-superpowers.sh
```

The script refreshes the `superpowers-dev` Git marketplace from
`https://github.com/robbedchunk/superpowers.git`, then removes and reinstalls
`superpowers@superpowers-dev` in both Codex homes and in Claude Code (user
scope). Removal ensures changes are picked up even when the plugin manifest
version was not bumped. It then installs the repository's canonical
`user-skills/delegating-to-codex` and `user-skills/update-superpowers` in all
three homes through `scripts/install-user-skills.sh` from the refreshed
Claude marketplace checkout. These standalone skills remain outside the
Superpowers plugin's opt-in skill directory.

After it finishes:

1. Verify all three homes report the plugin as installed and enabled.
2. Verify the two standalone skills match the canonical repository copies in
   all three homes, and both delegation workflows default to
   `gpt-6-astra` with `model_reasoning_effort=high`.
3. Report the installed version and source repository concisely.
4. Tell the user to start a new task so updated skills are loaded.
