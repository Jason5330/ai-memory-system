# Path & Layer Resolution Convention (canonical)

> This is the single source of truth for **where things live** in the dual-platform,
> two-layer memory framework. Every canonical operation, entry file, and installer
> resolves paths through the rules below. Do not hardcode `~/.claude/memory` anywhere.

## Two layers

| Layer | Lives at | Holds | Shared across projects? | Goes into a project's git? |
|-------|----------|-------|--------------------------|-----------------------------|
| **Personal** | `{{PERSONAL_MEMORY}}` = `~/.ai-memory/` (Win: `%USERPROFILE%\.ai-memory\`) | doctrine, user style, cross-project reflection, blocked-tools registry, personal knowledge, personal skills | ✅ yes | ❌ never |
| **Project** | `<project>/.claude/memory/` | THIS project's knowledge pages, conversation logs, project index | ❌ per-project | ✅ project knowledge may be (personal layer is NOT) |

The personal layer is **platform-neutral** (named `.ai-memory`, not `.claude`) so a Codex-only
user never needs a `~/.claude/` directory.

## Two platforms (one content, materialized twice)

| Thing | Claude Code reads | Codex reads |
|-------|-------------------|-------------|
| Personal entry file | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| Project entry file | `<project>/CLAUDE.md` | `<project>/AGENTS.md` |
| Operations (capture/dream/harvest/review/status) | `~/.claude/commands/<op>.md` (slash) | `~/.agents/skills/<op>/SKILL.md` (skill) |
| Personal skills | `~/.claude/skills/<n>/SKILL.md` | `~/.agents/skills/<n>/SKILL.md` |
| Project skills | `<project>/.claude/skills/<n>/SKILL.md` | `<project>/.agents/skills/<n>/SKILL.md` |
| PreToolUse hook registration | `~/.claude/settings.json` | `~/.codex/config.toml` (`[[hooks.PreToolUse]]`) |
| Hook script (shared) | `{{PERSONAL_MEMORY}}/hooks/block-failed-actions.{ps1,sh}` | same script |
| Blocked-tools registry (shared) | `{{PERSONAL_MEMORY}}/blocked-actions.json` | same file |

> ⚠️ Codex discovers skills at `.agents/skills/` (repo) and `~/.agents/skills/` (user) — **NOT**
> `.codex/skills/`. `.codex/` only holds `config.toml` / `hooks.json`. (Verified 2026-06 against
> developers.openai.com/codex/skills.)

## Memory-root resolution (used by every operation)

```
PERSONAL_ROOT = ~/.ai-memory                  # always
PROJECT_ROOT  = <cwd>/.claude/memory          # if it exists (you are inside an initialized project)
```

An operation decides **which root** a piece of memory goes to via the routing table in
`~/.ai-memory/guides/_routing.md`. Rule of thumb:
- "how I (the user) work / behavior rules / cross-project reflection / broken tools" → **PERSONAL**
- "facts/entities/decisions/logs about THIS project" → **PROJECT**

If `PROJECT_ROOT` does not exist (uninitialized dir or a pure personal chat), everything routes to
**PERSONAL**, and operations still work (degrade gracefully).

## Single-source-of-truth → materialize

Canonical content is authored once under `canonical/` and **materialized** (copied, format-adapted)
to the platform paths above by the installers (`install-personal.*`, `init-project.*`) and, for
promoted skills, by the `/harvest` and `/dream` operations. Because Claude Code and Codex use the
**identical `SKILL.md` shape** (`name` + `description` frontmatter + body), a skill is the same file
written to two locations — no translation needed.
