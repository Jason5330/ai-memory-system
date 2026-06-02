---
name: reset
description: Reset (clear) memory and start fresh, interactively. Use when the user says "reset memory", "重置記憶", "wipe my memory", "清空記憶重來", or has over-captured unwanted memories. Gathers the user's choices (layer + categories), then runs the DETERMINISTIC reset script (backup-first, verify, rollback) to do the actual clearing. Never clears without an explicit "yes reset".
---

# reset — Interactive front-end to the deterministic reset script

You gather the choices; the **script** (`~/.ai-memory/reset/reset.{ps1,sh}`) does the destructive work
(backup → verify → clear → rollback-on-error). Do NOT delete files yourself — always call the script.
Roots: `PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if present).

## Step 1: Show what exists (read-only)
Report counts per layer (conversations / reflection / knowledge / doctrine / preferences) so the user
knows what they're about to clear.

## Step 2: Ask WHICH LAYER (exactly per these rules)
- **No project memory here** (`./.claude/memory` absent) → only ask: *"Reset your personal memory? (y/n)"*
  → `-Layer personal`.
- **Project memory exists** → you MUST let the user choose:
  ```
  Reset which?
   1. This project only   → -Layer project
   2. Personal only        → -Layer personal
   3. Both                 → -Layer both
  ```

## Step 3: Ask WHICH CATEGORIES
```
Clear what?  (comma-separated; passed to the script as -Categories)
  conversations · reflection · knowledge · doctrine · preferences
  default = conversations,reflection   (the noisy logs; keeps doctrine/preferences/knowledge)
```
Note: project layer only has `conversations` + `knowledge` (reflection/doctrine/preferences are
personal-only — the script ignores them for a project). `blocked-actions` is preserved unless the user
explicitly adds it.

## Step 4: DRY-RUN first (show the exact plan)
Run the script with `-DryRun` and show the user the list of files it WOULD clear + where the backup
goes. **Windows:**
```
& "$env:USERPROFILE\.ai-memory\reset\reset.ps1" -Layer <L> -Categories <C> -DryRun
```
**Mac/Linux:**
```
bash ~/.ai-memory/reset/reset.sh --layer <L> --categories <C> --dry-run
```

## Step 5: Confirm → run for real
Require the user to type **`yes reset`**. Then run the script with the confirmation token:
```
& "$env:USERPROFILE\.ai-memory\reset\reset.ps1" -Layer <L> -Categories <C> -Yes "yes reset"
bash ~/.ai-memory/reset/reset.sh --layer <L> --categories <C> --yes "yes reset"
```
The script backs up to `<layer>/archive/reset-<timestamp>/`, **verifies the backup count**, only then
clears, and **rolls back** if any step fails. Relay its output (cleared N, backup path).

## Step 6: After
Tell the user the backup path (restore = copy files back) and suggest `/dream` or `/status` to refresh
the index. Restart Claude Code / Codex if doctrine/preferences/persona were cleared.

## Rules
- The destructive step is ALWAYS the script (deterministic; backup+verify+rollback) — never hand-delete.
- Interactive every time; honor the layer rules in Step 2 exactly.
- Dry-run before the real run; require the literal `yes reset`.
- `blocked-actions.json` preserved unless explicitly requested.
- Reply in the user's language.
