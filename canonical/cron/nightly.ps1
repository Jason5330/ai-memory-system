# nightly.ps1 — OS-level nightly consolidation (Windows), hardened.
#   -DryRun : PLAN ONLY — print what it WOULD do and exit. Launches NO agent, takes NO lock,
#             writes NO audit/memory. (Honest dry-run: it never starts a memory-modifying agent.)
# Hardening (real runs): single memory.lock (prevents concurrent dreams corrupting memory; stale >6h
# auto-clears), a run-id, and a per-phase JSON audit at ~/.ai-memory/cron/audit.jsonl.
# NOTE: the actual memory .md writes happen inside the agent (`claude -p` / `codex exec`), so the lock
# + audit make runs serialized and replayable, but per-file atomicity is the operations' job, not this
# wrapper's. Never auto-approves doctrines or auto-builds skills.
param([switch]$DryRun)
$ErrorActionPreference = 'Continue'
$personal = if ($env:AI_MEMORY_HOME) { $env:AI_MEMORY_HOME -replace '^~', $env:USERPROFILE } else { Join-Path $env:USERPROFILE '.ai-memory' }
$cron = Join-Path $personal 'cron'
New-Item -ItemType Directory -Force $cron | Out-Null
$lock  = Join-Path $cron 'memory.lock'
$audit = Join-Path $cron 'audit.jsonl'
$log   = Join-Path $personal 'nightly-last-run.md'
$runId = (Get-Date -Format 'yyyyMMdd-HHmm') + '-' + ('{0:x4}' -f (Get-Random -Maximum 65535))

function Detect-Cli {
  if (Get-Command claude -ErrorAction SilentlyContinue) { return 'claude' }
  if (Get-Command codex  -ErrorAction SilentlyContinue) { return 'codex' }
  return $null
}
function Get-Scopes {
  $s = @($env:USERPROFILE)
  $pf = Join-Path $personal 'nightly-projects.txt'
  if (Test-Path $pf) {
    foreach ($p in (Get-Content $pf | Where-Object { $_.Trim() -ne '' -and -not $_.StartsWith('#') })) {
      if (Test-Path (Join-Path $p '.claude\memory')) { $s += $p }
    }
  }
  return $s
}

# --- DRY RUN: plan only, no agent, no lock, no audit ---
if ($DryRun) {
  $cli = Detect-Cli; $scopes = Get-Scopes
  $lockState = if (Test-Path $lock) { "HELD (a real run is in progress or stale)" } else { "free" }
  $plan = @"
# Nightly PLAN (dry-run) $runId $(Get-Date -Format 'yyyy-MM-dd HH:mm')
This is a plan only. No agent is launched; nothing is written to memory, audit, or the lock.

CLI detected:      $(if($cli){$cli}else{'NONE (a real run would skip)'})
Lock state:        $lockState
Would consolidate: $($scopes.Count) scope(s)
$([string]::Join("`n", ($scopes | ForEach-Object { "  - $_" })))
Per scope it WOULD run: /ingest-sessions -> /dream (candidates only) -> /harvest scan (no build).
Run without -DryRun to execute.
"@
  Write-Host $plan
  $plan | Out-File $log -Encoding UTF8
  exit 0
}

function Audit($event,$scope,$status,$detail){
  $rec = [ordered]@{ run_id=$runId; ts=(Get-Date).ToString('o'); event=$event; scope=$scope; status=$status; detail="$detail" }
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

"# Nightly $runId $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-File $log -Encoding UTF8
try {
  $cli = Detect-Cli
  if (-not $cli) { Audit 'abort' '-' 'no-cli' 'no claude/codex on PATH'; "No claude/codex CLI found — skipped." | Out-File $log -Append -Encoding UTF8; exit 0 }
  Audit 'start' '-' 'ok' "cli=$cli"

  $prompt = "First run /ingest-sessions to sediment any signals missed from recent Claude/Codex sessions (per-source checkpoint, idempotent). Then run a full /dream memory consolidation now, non-interactively (entity sweep, link repair, dedup, reflection, skill-failure writeback, index sync, doctor). Distill doctrine CANDIDATES only — do NOT approve any doctrine and do NOT build any skill. Then run /harvest in SCAN-ONLY mode: produce the candidate list with evidence/confidence but STOP before building. Summarize what you wrote."

  function Run($workdir,$scope) {
    Audit 'consolidate' $scope 'begin' $workdir
    try {
      # Run the agent with NO new window (so nothing pops up) and a 30-min hard cap (so a stuck
      # headless agent can never leave the task "Running" forever — it gets killed and logged).
      # Prompt is passed as an ARGUMENT (not piped to stdin) — piping can make the CLI wait/hang.
      $exe = (Get-Command $cli -ErrorAction SilentlyContinue).Source
      $cmdArgs = if ($cli -eq 'claude') { @('-p', $prompt) } else { @('exec', $prompt) }
      $o = [System.IO.Path]::GetTempFileName(); $e = "$o.err"
      $p = Start-Process -FilePath $exe -ArgumentList $cmdArgs -WorkingDirectory $workdir -NoNewWindow -PassThru -RedirectStandardOutput $o -RedirectStandardError $e
      if ($p.WaitForExit(1800000)) {   # 30 minutes
        $out = ((Get-Content $o -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content $e -Raw -ErrorAction SilentlyContinue))
        Audit 'consolidate' $scope 'ok' ''
      } else {
        try { $p.Kill() } catch {}
        $out = "TIMEOUT: $cli agent exceeded 30 min and was killed (nothing written this scope). The headless CLI likely isn't running non-interactively — consider running /dream manually instead."
        Audit 'consolidate' $scope 'timeout' '>30m'
      }
      [System.IO.File]::Delete($o); [System.IO.File]::Delete($e)
      "## $scope" | Out-File $log -Append -Encoding UTF8; $out | Out-File $log -Append -Encoding UTF8
    } catch { "## $scope ERROR: $_" | Out-File $log -Append -Encoding UTF8; Audit 'consolidate' $scope 'error' "$_" }
  }

  foreach ($s in (Get-Scopes)) { Run $s ($(if($s -eq $env:USERPROFILE){'personal'}else{"project:$s"})) }
  Audit 'done' '-' 'ok' ''
  "`nDone $runId. Review next session: /review-doctrine and /harvest." | Out-File $log -Append -Encoding UTF8
}
finally {
  [System.IO.File]::Delete($lock)
  Audit 'unlock' '-' 'released' ''
}
