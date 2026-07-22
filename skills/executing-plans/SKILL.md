---
name: executing-plans
description: "Opt-in only: Use when the user explicitly opts into Superpowers for the current request and wants a written plan executed in a separate session, or explicitly names superpowers:executing-plans. Never auto-invoke from task relevance alone."
---

<OPT-IN-BOUNDARY>
Use this workflow only when the current user request explicitly opts into Superpowers or explicitly names `superpowers:executing-plans`. Task relevance alone is never permission. Ask for permission before invoking another Superpowers workflow unless the user has already explicitly authorized chaining.
</OPT-IN-BOUNDARY>

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (Claude Code, Codex CLI, Codex App, and Copilot CLI all qualify; see the per-platform tool refs in `../using-superpowers/references/`). If subagents are available, use superpowers:subagent-driven-development instead of this skill.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create the task list (below) and proceed

**Task list.** List existing tasks first — on a resumed session the
list may already exist; reconcile against the plan and `git log`
instead of duplicating. Otherwise create one task ("todo") per plan
task: subject `Task N: <short title>` (under ~60 characters — some
harnesses re-inject every subject into context repeatedly), description
a one-line pointer to the plan file and task number, dependencies
mirroring `Depends on:` where the tracker supports them. The plan
remains the source of requirements — never copy task content into the
tracker. The list is a disposable status view: if it is empty or stale
on resume, rebuild it from the plan, marking tasks whose commits
already exist in `git log` as completed.

### Step 2: Execute Tasks

Execute tasks in an order that satisfies each task's `Depends on:` — inline
execution is sequential, so dependencies simply constrain the order. For
each task:
1. Mark as in_progress
2. Implement to the task's Requirements and acceptance tests, honoring its
   Interfaces and contract code exactly (follow superpowers:test-driven-development)
3. Meet the task's "Done when" gates: acceptance tests pass, full suite
   green, lint and typecheck clean
4. Commit and mark as completed

### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Honor each task's contracts and dependency order exactly
- Don't skip the "Done when" gates
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
