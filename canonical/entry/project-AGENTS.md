# {{PROJECT_NAME}} — project memory (Codex)

This project is initialized for the dual-platform self-evolving memory system. The personal layer
(`~/.ai-memory`, loaded via `~/.codex/AGENTS.md`) applies everywhere; this file adds THIS project's
layer. The Claude twin is `./CLAUDE.md` (same content).

## On session start (in this project)

1. Read `./.claude/memory/MEMORY.md` — this project's index: current state, open knowledge,
   unfinished tasks. (Personal `~/.ai-memory/MEMORY.md` + `doctrine.md` are already loaded globally.)
2. Continue from this project's "next step" if one is recorded.

## Project-layer routing

- Knowledge / entities / decisions about THIS project → `./.claude/memory/knowledge/<entity>.md`
- Conversation logs for this project → `./.claude/memory/conversations/YYYY-MM-DD.md`
- Project-specific skills → `./.agents/skills/<name>/SKILL.md` (Claude twin: `./.claude/skills/<name>/`)
- Personal-layer signals (preferences, behavior doctrine, broken tools, cross-project reflection)
  still go to `~/.ai-memory` — never write personal memory into this project's tree.

> Note: this project's memory store is shared with the Claude side at `./.claude/memory/` (one store,
> both platforms read it). Codex skills live in `./.agents/skills/` (not `./.codex/skills/`).

## Operations

Same operations as global (capture / dream / harvest / review-doctrine / status, as Codex skills under
`~/.agents/skills/`). They auto-detect this project layer and route signals per
`~/.ai-memory/guides/_routing.md`.

## Sharing this project

If you commit `./.claude/memory/` to git, you share PROJECT knowledge with collaborators. The
personal layer is never here, so your preferences/doctrine don't leak.
