# CLAUDE.md — guidance for working ON this framework repo

> This file is for contributors editing the framework itself (it's the project guidance Claude Code
> loads when you open this repo). It is NOT the memory-system entry that gets installed — that lives
> in `canonical/entry/`.

## What this repo is
A dual-platform (Claude Code + Codex), two-layer (personal + per-project), self-evolving memory
system. See [`README.md`](README.md) and [`DUAL-PLATFORM-GUIDE.md`](DUAL-PLATFORM-GUIDE.md).

## Contract-first: edit the canonical source, not the installed copies
Everything is authored ONCE under `canonical/` and **materialized** to each platform by the
installers. When changing behavior, edit the canonical file — never the `~/.claude` / `~/.agents`
copies on a machine.

```
canonical/
├── PATHS.md                      # path & layer resolution (single source of truth)
├── entry/                        # CLAUDE.md / AGENTS.md (personal + project entry templates)
├── operations/                   # capture, dream, harvest, review-doctrine, status,
│   │                             #   schedule-dream, reset, help, ingest-sessions (frontmatter = Codex SKILL.md too)
│   ├── _routing.md               # signal → layer routing (shared by capture/dream)
│   ├── _materialize-skill.md     # dual-platform skill copy helper
│   └── _memory-gate.md           # Memory Decision Gate: confidence tiers + auto-write boundary
├── lib/                          # memory-write.{ps1,sh}  (deterministic safe writer: append + block-tool)
├── hooks/                        # block-failed-actions.{ps1,sh}  (PreToolUse hard-block)
├── cron/                         # nightly.{ps1,sh}
├── lint/                         # memory-lint.{ps1,sh}
├── reset/                        # reset.{ps1,sh}  (deterministic backup→verify→clear→rollback)
└── templates/                    # personal/ + project/ seed files, blocked-actions.json

install-personal.{ps1,sh}         # per-machine: builds ~/.ai-memory, materializes to both platforms
init-project.{ps1,sh}             # per-project: builds <proj>/.claude + .codex + .agents
skills/skill-creator/             # official Anthropic skill-creator (deployed by the installers)
```

## Rules when editing
- One operation file serves BOTH platforms (frontmatter `name` + `description` makes it a Codex
  `SKILL.md`; the body is also the Claude slash-command). Don't fork per-platform copies.
- Adding an operation → also add its name to the op list in all four installers.
- Operation/entry files reference shared guides at their **runtime** path (`~/.ai-memory/guides/...`),
  not `canonical/...`.
- Skill creation goes through `skill-creator`; promoted skills materialize to both platforms via
  `_materialize-skill.md`.
- After changes, verify by running `install-personal` against an isolated `USERPROFILE` and check
  materialization + `memory-lint`. Keep `bash -n` clean on the `.sh` scripts.

## Verify
```powershell
# isolated install smoke test (Windows)
$env:USERPROFILE = "$env:TEMP\mem-test"; .\install-personal.ps1
```
Then confirm `~/.claude/commands/*`, `~/.agents/skills/*/SKILL.md`, the hook registrations, and
`skill-creator` deployment exist; run `~/.ai-memory/memory-lint.ps1` (RESULT fail=0).
