---
name: harvest
description: Review the user's conversation history to find repeatable manual workflows worth encapsulating, then propose Skill / subagent / automation / skip — each with evidence, frequency, and confidence. Presents a candidate list for review BEFORE building anything, then materializes only high-confidence, missing assets to BOTH platforms. Use when the user says "harvest", "harvest workflows", "find repeatable work", "what should I turn into a skill", or after /dream flags repeat candidates.
---

# harvest — Encapsulate Repeated Workflows (evidence-gated, dual-platform)

This is the workflow-discovery loop. It does NOT auto-create anything until you approve a candidate.
Roots: `PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if present).
Skill materialization: `~/.ai-memory/guides/_materialize-skill.md`.

## Core task
Review conversation history and identify the repetitive manual workflows worth encapsulating.

## Step 1: Gather evidence (in this priority order)
1. **Recent sessions + task summaries** — read `conversations/*.md` in BOTH layers (project + recent
   personal). Note dates.
2. **Memory + reflection** — `reflection.md`, `MEMORY.md`, `## 🔁 Repeat candidates` lines, recurring
   `## 🐛 Problems Solved` / `## 💡 Decisions` patterns across days.
3. **(If available) external repetitive work** — any Chronicle-style activity logs are LEADS ONLY;
   verify the actual details in the source system before trusting them.
4. **Existing assets — reuse, don't rebuild** — list current skills/subagents/automations:
   `~/.claude/skills`, `~/.agents/skills`, `./.claude/skills`, `./.agents/skills`, any cron scripts.
   A candidate that an existing asset already covers → propose **extend**, not create.

## Step 2: Scope of work to scan
Look broadly — not just coding: research, writing, planning, communication, ops, analysis, personal
admin. Focus on tasks that are high-frequency, time-consuming, error-prone, context-heavy, or that
badly need a standard procedure.

## Step 3: Action criteria (only act if ALL hold)
- the task occurred **at least twice**, OR has a clear recurring tendency with high repeat cost;
- it has **stable inputs, reproducible steps, and a clear output / stop condition**;
- encapsulating it would clearly improve speed, quality, consistency, or reliability;
- existing tools/skills don't already cover it.

## Step 4: Pick the smallest suitable form
- **Skill** — a reusable workflow / playbook the agent follows.
- **Custom subagent** — a delegable, well-scoped expert role or investigation.
- **Automation** — a scheduled/periodic check, report, reminder, or monitor (→ an OS-cron script;
  see `~/.ai-memory/cron/`).
- **Skip** — too random, ill-defined, sensitive, or evidence-thin to encapsulate.

## Step 5: Present the candidate list (DO NOT build yet)
Output a concise table, one row per repeatable workflow:
```
# Harvest candidates
| # | Workflow | Evidence (dates) | Frequency | Confidence | Proposed form | Layer | Why / why not |
|---|----------|------------------|-----------|------------|---------------|-------|----------------|
| 1 | PR summary writeup | 2026-05-12, 05-19, 05-27 | 3× / 3 wk | high | Skill | personal | stable steps, clear output, not covered |
| 2 | Weekly metrics pull | 05-13, 05-20 | 2× weekly | med | Automation | project | reproducible; needs a stable data source |
| 3 | "explain this error" | scattered | low | low | Skip | — | too varied, no stable steps |
```
Confidence = how sure you are it's a real, stable, worth-encapsulating workflow (high/med/low).

## Step 6: Review gate (reuse /review-doctrine UX)
Present candidates **one at a time**; for each: ✅ Create · ✏️ Create with edits · 🔁 Extend existing
· ❌ Skip · ⏭️ Decide later. Wait for the user between candidates. **Only build high-confidence,
genuinely-missing items.** Never create speculative, redundant, or over-broad assets.

## Step 7: Build approved items (smallest viable)
- **Skill → create it THROUGH the official skill-creator (required).** Do NOT hand-write the
  `SKILL.md` ad hoc. Invoke the **`skill-creator`** skill (Claude: the `Skill` tool / `~/.claude/skills/
  skill-creator/SKILL.md`; Codex: `~/.agents/skills/skill-creator/SKILL.md`) and follow its "Creating a
  skill" flow — capture intent (pull the workflow from the conversation/logs), write the SKILL.md with a
  sharp `description`, end with an empty `## Known Limitations & Fallbacks`. Full eval/benchmark loop is
  optional (use it if the user wants rigor; otherwise the lightweight authoring path is fine). Then
  **materialize the result to BOTH platforms** via `~/.ai-memory/guides/_materialize-skill.md` at the
  chosen layer.
- **Extend** → have skill-creator edit the existing canonical SKILL.md, then re-materialize to its twin.
- **Automation** → add an OS-cron script under the cron folder + show the user the scheduler-register
  command (Windows Task Scheduler / cron). Do not silently install schedules.
- **Subagent** → write the agent definition in each platform's expected location.
- Keep everything tight, sourced, and easy to verify.

## Step 8: Final report (required)
```
🔁 Harvest complete
Created / extended:
  - <name> (Skill, personal) → .claude/skills + .agents/skills
Skipped (with reason):
  - <name> — too varied, no stable steps
Need more evidence before encapsulating:
  - <name> — seen once; revisit after it recurs
```

## Rules
- Candidate list FIRST, build SECOND — evidence before assets.
- Reuse/extend over rebuild; one source of truth, materialized to both platforms.
- Be concrete, practical, source-anchored, verifiable. No speculative or duplicate assets.
- Sensitive or ambiguous workflows → Skip.
- Write in the user's language.
