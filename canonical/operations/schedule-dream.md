---
name: schedule-dream
description: Create, LIST, or DELETE the nightly memory-consolidation schedule via the OS scheduler (Windows Task Scheduler / cron). Use when the user says "schedule dream", "list my schedules", "delete the schedule", "停用每晚整理", "排程跑很多次". Creating is idempotent (one named task, never duplicates); the user never needs to know the raw scheduler commands — you run them.
---

# schedule-dream — Manage the OS-level nightly job (create / list / delete)

There is **exactly ONE** named schedule: **`ai-memory-nightly`**. Creating again **replaces** it
(never stacks duplicates) — this prevents multiple nightly processes running `/dream` at once and
corrupting memory. The user shouldn't need to know Task Scheduler / cron syntax — **you run the
commands for them** and just report the result.

Nightly script (installed by install-personal):
- Windows: `%USERPROFILE%\.ai-memory\cron\nightly.ps1`
- Mac/Linux: `~/.ai-memory/cron/nightly.sh`

## Route by intent
- "schedule / 每晚自動整理 / set a time" → **Create/Replace**
- "list / 看排程 / 有哪些排程 / 跑幾個" → **List**
- "delete / stop / 停用 / 取消 / 移除排程" → **Delete**

---

## Create / Replace (idempotent — always one task)

1. Ask for a time (suggest 02:00). Validate `HH:MM`.
2. **Run** the register command yourself (it overwrites the same task name, so re-running is safe):

   **Windows (Task Scheduler):** — **resolve the path FIRST** into `$np`, then build the argument with
   double quotes so the task stores the REAL path. ⚠️ Do NOT put a literal `$env:USERPROFILE` inside
   `-File` (single-quoted `-Argument`): `powershell.exe -File` does **not** expand it, so the task
   fails every night with **`-196608`** (script file not found).
   ```powershell
   $np = "$env:USERPROFILE\.ai-memory\cron\nightly.ps1"
   $a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$np`""
   $t = New-ScheduledTaskTrigger -Daily -At <HH:MM>
   Register-ScheduledTask -TaskName 'ai-memory-nightly' -Action $a -Trigger $t -Force `
     -Description 'Nightly memory consolidation (dream + harvest scan)'
   ```
   `-Force` REPLACES any existing `ai-memory-nightly` — that is what keeps it to one schedule (and
   re-running this is the fix for an old task that stored the unexpanded `$env:USERPROFILE`).

   **Mac/Linux (cron) — replace the single tagged line, don't append a new one:**
   ```bash
   ( crontab -l 2>/dev/null | grep -v 'ai-memory-nightly'; \
     echo '0 <H> * * * /bin/bash "$HOME/.ai-memory/cron/nightly.sh" >> "$HOME/.ai-memory/cron/nightly.out" 2>&1  # ai-memory-nightly' ) | crontab -
   ```
   The `grep -v` removes the old tagged line first, so you never end up with duplicate cron entries.

3. (Optional) Projects to consolidate nightly: add absolute paths (one per line) to
   `~/.ai-memory/nightly-projects.txt`. Personal layer is always consolidated.
4. Confirm via **List** below and report the next run time.

---

## List existing schedules

Run and show the result:
- **Windows:** `Get-ScheduledTask -TaskName 'ai-memory-nightly' -ErrorAction SilentlyContinue | Get-ScheduledTaskInfo`
  (or `Get-ScheduledTask | Where-Object TaskName -like '*ai-memory*'` to catch any strays).
- **Mac/Linux:** `crontab -l | grep ai-memory-nightly`

If you find **more than one** ai-memory entry (e.g. from an older version that appended duplicates),
tell the user and offer to **Delete all then Create one** — that's the fix for "排程跑很多次".

**Check `LastTaskResult`.** `0` = last run OK. **`-196608`** (or the task argument shows a literal
`$env:USERPROFILE` in `-File`) = the old bug where the path wasn't expanded, so nightly.ps1 was never
found. **Fix = just re-Create** (above) — it re-registers with the resolved real path.

---

## Delete the schedule

- **Windows:** `Unregister-ScheduledTask -TaskName 'ai-memory-nightly' -Confirm:$false`
- **Mac/Linux:** `crontab -l 2>/dev/null | grep -v 'ai-memory-nightly' | crontab -`

Report: "Nightly schedule removed; `/dream` will only run when you trigger it manually."

---

## Known limitation (why OS scheduler, not Claude's internal cron)
This operation deliberately uses the **OS scheduler**, NOT Claude's internal `CronCreate/CronList/
CronDelete`. Reason: Claude's `CronList` does not reliably display schedules in the Claude Code CLI
(it shows in the VS Code extension), and internal crons are easy to duplicate and hard to audit. The
OS scheduler is always listable/deletable with the commands above, on both platforms.

## Rules
- One schedule only (`ai-memory-nightly`); create = replace, never duplicate.
- Run the scheduler commands for the user; don't make them memorize syntax.
- Deleting needs no backup (it's just a trigger), but confirm before removing.
- The nightly job only produces candidates; approval stays human (/review-doctrine, /harvest).
- Write in the user's language.
