# nightly.ps1 — OS-level nightly consolidation (Windows), hardened.
#   -DryRun : report what WOULD happen, write nothing.
# Hardening: single memory.lock (prevents concurrent dreams corrupting memory; stale >6h auto-clears),
# a run-id, and a per-phase JSON audit at ~/.ai-memory/cron/audit.jsonl.
# NOTE: the actual memory .md writes happen inside `claude -p` / `codex exec` (the agent), so the lock
# + audit make runs serialized and replayable, but per-file atomicity is the operations' job, not this
# wrapper's. Never auto-approves doctrines or auto-builds skills.
param([switch]$DryRun)
$ErrorActionPreference = 'Continue'
$personal = Join-Path $env:USERPROFILE '.ai-memory'
$cron = Join-Path $personal 'cron'
New-Item -ItemType Directory -Force $cron | Out-Null
$lock  = Join-Path $cron 'memory.lock'
$audit = Join-Path $cron 'audit.jsonl'
$log   = Join-Path $personal 'nightly-last-run.md'
$runId = (Get-Date -Format 'yyyyMMdd-HHmm') + '-' + ('{0:x4}' -f (Get-Random -Maximum 65535))

function Audit($event,$scope,$status,$detail){
  $rec = [ordered]@{ run_id=$runId; ts=(Get-Date).ToString('o'); event=$event; scope=$scope; status=$status; detail="$detail"; dry_run=[bool]$DryRun }
  Add-Content -Path $audit -Value ($rec | ConvertTo-Json -Compress) -Encoding UTF8
}

# --- single-instance lock (stale >6h auto-clears) ---
if (Test-Path $lock) {
  $age = (Get-Date) - (Get-Item $lock).LastWriteTime
  if ($age.TotalHours -lt 6) {
    Audit 'skipped' '-' 'locked' "another run holds the lock ($([int]$age.TotalMinutes)m old)"
    "# Nightly $runId — SKIPPED (locked)" | Out-File $log -Encoding UTF8
    exit 0
  } else { Audit 'lock' '-' 'stale-cleared' "$([int]$age.TotalHours)h old"; [System.IO.File]::Delete($lock) }
}
"$runId pid=$PID $(Get-Date -Format o)" | Out-File $lock -Encoding UTF8
Audit 'lock' '-' 'acquired' ''

"# Nightly $runId $(Get-Date -Format 'yyyy-MM-dd HH:mm')$(if($DryRun){' (DRY RUN)'})" | Out-File $log -Encoding UTF8
try {
  $cli = $null
  if (Get-Command claude -ErrorAction SilentlyContinue) { $cli='claude' }
  elseif (Get-Command codex -ErrorAction SilentlyContinue) { $cli='codex' }
  if (-not $cli) { Audit 'abort' '-' 'no-cli' 'no claude/codex on PATH'; "No claude/codex CLI found — skipped." | Out-File $log -Append -Encoding UTF8; exit 0 }
  Audit 'start' '-' 'ok' "cli=$cli"

  $dryNote = if ($DryRun) { ' THIS IS A DRY RUN: do NOT write or modify ANY file; instead report what you WOULD consolidate/harvest and stop.' } else { '' }
  $prompt = "First run /ingest-sessions to sediment any signals missed from recent Claude/Codex sessions (watermarked, idempotent). Then run a full /dream memory consolidation now, non-interactively (entity sweep, link repair, dedup, reflection, skill-failure writeback, index sync, lint). Distill doctrine CANDIDATES only — do NOT approve any doctrine and do NOT build any skill. Then run /harvest in SCAN-ONLY mode: produce the candidate list with evidence/confidence but STOP before building. Summarize what you wrote.$dryNote"

  function Run($workdir,$scope) {
    Audit 'consolidate' $scope 'begin' $workdir
    Push-Location $workdir
    try {
      $out = if ($cli -eq 'claude') { $prompt | claude -p 2>&1 | Out-String } else { codex exec "$prompt" 2>&1 | Out-String }
      "## $scope" | Out-File $log -Append -Encoding UTF8; $out | Out-File $log -Append -Encoding UTF8
      Audit 'consolidate' $scope 'ok' ''
    } catch { "## $scope ERROR: $_" | Out-File $log -Append -Encoding UTF8; Audit 'consolidate' $scope 'error' "$_" }
    finally { Pop-Location }
  }

  Run $env:USERPROFILE 'personal'
  $projFile = Join-Path $personal 'nightly-projects.txt'
  if (Test-Path $projFile) {
    foreach ($p in (Get-Content $projFile | Where-Object { $_.Trim() -ne '' -and -not $_.StartsWith('#') })) {
      if (Test-Path (Join-Path $p '.claude\memory')) { Run $p "project:$p" }
    }
  }
  Audit 'done' '-' 'ok' ''
  "`nDone $runId. Review next session: /review-doctrine and /harvest." | Out-File $log -Append -Encoding UTF8
}
finally {
  [System.IO.File]::Delete($lock)
  Audit 'unlock' '-' 'released' ''
}
