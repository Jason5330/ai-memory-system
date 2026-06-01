# Skill Materialization (shared helper for /harvest and /dream)

> **Authoring vs materializing:** the SKILL.md content is **authored through the official
> `skill-creator`** (deployed at `~/.claude/skills/skill-creator` + `~/.agents/skills/skill-creator`).
> This helper does NOT author skills — it only handles the **dual-platform copy** of the finished
> SKILL.md afterward.
>
> Single source of truth → two platforms. Claude Code and Codex use the **identical** `SKILL.md`
> shape (`name` + `description` frontmatter + body), so materializing a skill = writing the same
> file to both platforms' discovery paths. No format translation.

## Inputs
- `name` — kebab-lowercase skill id (e.g. `pr-summary`)
- `layer` — `personal` or `project`
- `SKILL.md` content (frontmatter with `name` + `description` that says exactly when to trigger, then
  the workflow body; end with an empty `## Known Limitations & Fallbacks` section)

## Destinations by layer
| layer | Claude path | Codex path |
|-------|-------------|------------|
| personal | `~/.claude/skills/<name>/SKILL.md` | `~/.agents/skills/<name>/SKILL.md` |
| project  | `./.claude/skills/<name>/SKILL.md` | `./.agents/skills/<name>/SKILL.md` |

## Procedure
1. Write the SAME `SKILL.md` content to BOTH destination paths for the chosen layer (create dirs).
2. Add an index line under `## Skills` in that layer's `MEMORY.md`:
   `- [<name>](<claude-path>) — <one-line> (promoted YYYY-MM-DD)`
3. Treat the **Claude path as canonical** for later edits; whenever the canonical SKILL.md changes
   (e.g. `/dream` Phase 3.6 fallback writeback), re-copy it to the Codex twin so they never diverge.
4. `/status` checks the two copies match and flags divergence.

## Notes
- Codex also supports disabling a skill via `~/.codex/config.toml` `[[skills.config]] path=... enabled=false`
  (mirrors a Claude "Tier C / dormant" skill). Use this instead of deleting when retiring a skill.
- Keep `description` sharp — it is what makes the skill auto-trigger at the right time on both platforms.
