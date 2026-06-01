# AI Memory System (Claude Code entry)

This is the personal-layer entry for the dual-platform, two-layer self-evolving memory system.
Claude Code loads this file every session. (The Codex twin is `~/.codex/AGENTS.md` — same content.)

## Two layers (read this first)

- **Personal layer** = `{{PERSONAL_MEMORY}}` — who you are, behavior doctrine, cross-project
  reflection, broken-tool registry, personal knowledge + skills. Shared across ALL projects.
  Never committed into any project's git.
- **Project layer** = `<this project>/.claude/memory/` — knowledge, decisions, and conversation
  logs about THIS project only. Exists only after `init-project` was run here.

Full path rules: `~/.ai-memory/guides/PATHS.md`. Signal routing: `~/.ai-memory/guides/_routing.md`.

## On session start

1. Read `{{PERSONAL_MEMORY}}/MEMORY.md` — its top `## ⚠️ Environment Limits & Blocked Tools`
   section is **executable directives, not trivia**. Obey every line. Named tools there are ALSO
   hard-blocked by a PreToolUse hook as a safety net.
2. Read `{{PERSONAL_MEMORY}}/doctrine.md` — the approved behavior doctrines. Read and obey every one.
3. If `./.claude/memory/MEMORY.md` exists (you are inside an initialized project), read it too for
   this project's state, open knowledge, and unfinished tasks.

`doctrine.md` is how the system improves over time: rules you approve there change behavior in all
future sessions, on both platforms. This entry file stays small — it only points at the memory; the
rules accumulate in `doctrine.md`.

## Operations (Claude slash-commands; Codex runs the twin skills)

- `/capture` — save the current conversation's signals to the correct layer (routing table above).
- `/dream` — multi-phase consolidation: entity sweep → link repair → dedup → reflection → skill
  fallback writeback → index sync → lint.
- `/harvest` — scan history for repeated manual workflows, propose Skill/subagent/automation/skip
  with evidence, gate them by review, materialize approved skills to BOTH platforms.
- `/review-doctrine` — approve/edit/reject the doctrine candidates `/dream` distilled.
- `/status` — read-only health of personal + project memory.

## Enforcement layer (hard guarantee)

A PreToolUse hook reads `{{PERSONAL_MEMORY}}/blocked-actions.json` and **physically blocks** any
tool listed there (exit 2 + stderr), telling you which alternative to use. Works on both Claude Code
(`settings.json`) and Codex (`~/.codex/config.toml`). `/capture` registers a broken tool there.
Data-driven: blocking a new tool needs no code change.

## When a skill triggers

Before acting on any skill, read its `## Known Limitations & Fallbacks` section (if present) and
avoid the listed failure modes. `/dream` maintains that section from observed failures.

## Capturing signals (auto)

During conversation, when you detect a preference, decision, problem+fix, reusable knowledge,
unfinished task, skill failure, or a broken tool — route it per `~/.ai-memory/guides/_routing.md`:
"about me / behavior / broken tool" → personal layer; "about THIS project" → project layer. Only
capture non-obvious things; skip routine Q&A — **but a short "OK/好" that settles a prior discussion
is a decision: resolve it against the last 3-5 turns and capture the substance, don't skip it.**
`/capture` guarantees a save.

## Before ending a session

Did this conversation contain anything worth remembering? Yes → write to the right layer's log and
update that layer's MEMORY.md index. No → nothing to do.
