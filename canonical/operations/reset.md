---
name: reset
description: Reset (clear) memory and start fresh, interactively. Use when the user says "reset memory", "重置記憶", "wipe my memory", "清空記憶重來", or has over-captured unwanted memories. The user only ever CLICKS choices (layer, categories, final confirm) — never types a token. Gathers the choices, then runs the DETERMINISTIC reset script (backup-first, verify, rollback) to do the actual clearing.
---

# reset — Click-only front-end to the deterministic reset script

The user makes **simple selections only — never types any token**. You gather the choices, show the
dry-run plan, get a one-click confirm, then call the **script** (`~/.ai-memory/reset/reset.{ps1,sh}`)
which does the destructive work (backup → verify → clear → rollback-on-error). Never delete files
yourself. Roots: `PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if present).

> **The `yes reset` token is an internal AI→script safety handshake, NOT something the user types.**
> After the user *clicks* the final confirm, YOU pass `-Yes "yes reset"` to the script. The user
> never sees or types that token.

## Step 1: Show what exists (read-only)
Report counts per layer (conversations / reflection / knowledge / doctrine / preferences) so the user
sees what they're about to clear.

## Step 2: Ask the choices as CLICKABLE options (no typing)
Use a selection prompt (**AskUserQuestion** on Claude; on Codex present numbered options to pick).
**The selection UI allows at most 4 options per question — use single-select PRESET BUNDLES, not a
5-way multi-select.** The platform auto-adds an "Other" choice, so the user can still name a custom
combination by clicking Other (no required typing for the common cases).

- **Which layer** (only ask this question if a project exists here):
  - **No project memory** (`./.claude/memory` absent) → don't ask; it's `personal` (state it in the
    confirm).
  - **Project memory exists** → options: `只這個專案` → `project` · `只個人記憶` → `personal` ·
    `兩個都清` → `both`.
- **Which categories** — offer single-click preset bundles (recommended first):
  - `只清雜訊：對話＋反思（推薦）` → `conversations,reflection` (keeps knowledge/doctrine/preferences)
  - `對話＋反思＋知識` → `conversations,reflection,knowledge`
  - `全部清空` → `conversations,reflection,knowledge,doctrine,preferences`
  - (auto "Other" = a custom combination if they really need it)
  - Project layer only has `conversations` + `knowledge` (reflection/doctrine/preferences are
    personal-only — the script ignores them for a project). `blocked-actions` stays preserved unless
    explicitly named.

You may ask layer + categories together in ONE AskUserQuestion call (each ≤4 options).

## Step 3: DRY-RUN the script and show the plan (read-only)
Run the script with `-DryRun` using the picked layer/categories, and show the user the exact list of
files it WOULD clear + where the backup goes:
```
& "$env:USERPROFILE\.ai-memory\reset\reset.ps1" -Layer <L> -Categories <C> -DryRun      # Windows
bash ~/.ai-memory/reset/reset.sh --layer <L> --categories <C> --dry-run                 # Mac/Linux
```

## Step 4: One-click confirm → run for real (you supply the token)
Present a simple confirm **selection** (AskUserQuestion / numbered choice), e.g.:
`確認重置（已備份可復原）` · `取消`.
- If they pick **取消** → stop, change nothing.
- If they pick **確認重置** → run the script, **you** pass the handshake token (the user typed nothing):
```
& "$env:USERPROFILE\.ai-memory\reset\reset.ps1" -Layer <L> -Categories <C> -Yes "yes reset"   # Windows
bash ~/.ai-memory/reset/reset.sh --layer <L> --categories <C> --yes "yes reset"               # Mac/Linux
```
The script backs up to `<layer>/archive/reset-<timestamp>/`, **verifies the backup count**, only then
clears, and **rolls back** if any step fails. Relay its output (cleared N, backup path).

## Step 5: After
Tell the user the backup path (restore = copy files back) and suggest `/dream` or `/status` to refresh
the index. Restart Claude Code / Codex if doctrine/preferences/persona were cleared.

## Rules
- **User only clicks** — never make them type `yes reset` or any other token. The token is an
  internal AI→script handshake you supply *after* the click.
- The destructive step is ALWAYS the script (deterministic; backup+verify+rollback) — never hand-delete.
- Always DRY-RUN and show the plan before the confirm click.
- Honor the layer rule in Step 2 (no project → personal only; project present → let them pick).
- `blocked-actions.json` preserved unless explicitly selected.
- Reply in the user's language.
