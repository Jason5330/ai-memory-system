# Signal Layer Routing (shared by /capture and /dream)

> Decide **which layer** each captured signal belongs to. Imported by capture/dream.
> Roots are resolved per `~/.ai-memory/guides/PATHS.md`:
> `PERSONAL = ~/.ai-memory`, `PROJECT = <cwd>/.claude/memory` (if initialized).

| Signal | Goes to | Exact file |
|--------|---------|------------|
| 🎭 AI persona/identity (how the AI itself should sound/address you, its role/boundaries) | **PERSONAL** | `PERSONAL/persona.md` |
| ❤️ User preference (how the user likes a TASK done) | **PERSONAL** | `PERSONAL/feedback_user_style.md` |
| 🧭 Behavior rule / "don't repeat this mistake" (a doctrine) | **PERSONAL** | `PERSONAL/doctrine_candidates.md` → (after review) `PERSONAL/doctrine.md` |
| 🪞 Cross-project reflection (what went right/wrong, how to improve) | **PERSONAL** | `PERSONAL/reflection.md` |
| ⚙️ Tool/behaviour broken in this environment (machine-level) | **PERSONAL** | `PERSONAL/blocked-actions.json` + MEMORY.md top section + hook |
| 📚🧩 Knowledge / entity / decision about **THIS project** | **PROJECT** | `PROJECT/knowledge/<entity>.md` |
| 🐛 Problem+fix tied to this project's code | **PROJECT** | today's `PROJECT/conversations/YYYY-MM-DD.md` |
| 📚🧩 Reusable knowledge NOT tied to any project (a tool gotcha, a concept) | **PERSONAL** | `PERSONAL/knowledge/<entity>.md` |
| 💬 Conversation log of a project session | **PROJECT** | `PROJECT/conversations/YYYY-MM-DD.md` |
| 💬 Conversation log of a non-project / personal chat | **PERSONAL** | `PERSONAL/conversations/YYYY-MM-DD.md` |
| 🔁 Repeated workflow → skill candidate | decided by `/harvest`: project-specific → PROJECT skill; general → PERSONAL skill |

## Decision shortcuts
- **"Is this about the user, or about this project?"** User/behavior/preferences/tool-failures → PERSONAL.
  Project facts/logs → PROJECT.
- **Privacy guard:** PERSONAL never gets written into a project's git-tracked tree. Project knowledge
  may be committed; personal doctrine/preferences must not leak into a shared repo.
- **No project?** If `PROJECT` root doesn't exist, route everything to PERSONAL and continue.
- When unsure → prefer PERSONAL for "about me" signals, PROJECT for "about this code" signals;
  if still unsure, **don't store it** (over-capture dilutes value).
