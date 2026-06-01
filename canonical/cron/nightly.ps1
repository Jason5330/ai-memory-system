# nightly.ps1 — OS-level nightly consolidation (Windows; platform-neutral)
#
# Replaces Claude's internal CronCreate. Register this with Windows Task Scheduler
# (install-personal prints the exact command). Runs headless:
#   1) /dream  — consolidate + reflect → doctrine CANDIDATES (human reviews later)
#   2) /harvest (scan only) — produce a candidate list (does NOT build; human gates)
# It NEVER auto-approves doctrines or auto-builds skills — those keep their human gate.
#
# CLI auto-detect: prefers `claude` (print mode), falls back to `codex exec`.
# Projects to consolidate: one absolute path per line in ~/.ai-memory/nightly-projects.txt
# (plus the personal layer is always consolidated).

$ErrorActionPreference = 'Continue'
$personal = Join-Path $env:USERPROFILE '.ai-memory'
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$log = Join-Path $personal 'nightly-last-run.md'
"# Nightly run $stamp" | Out-File -FilePath $log -Encoding UTF8

# Detect CLI
$cli = $null
if (Get-Command claude -ErrorAction SilentlyContinue) { $cli = 'claude' }
elseif (Get-Command codex -ErrorAction SilentlyContinue) { $cli = 'codex' }
if (-not $cli) { "No claude/codex CLI found on PATH — skipped." | Out-File $log -Append -Encoding UTF8; exit 0 }
"CLI: $cli" | Out-File $log -Append -Encoding UTF8

function Invoke-Headless($promptText, $workdir) {
    Push-Location $workdir
    try {
        if ($cli -eq 'claude') { $promptText | claude -p 2>&1 | Out-String }
        else { codex exec "$promptText" 2>&1 | Out-String }
    } catch { "ERROR: $_" } finally { Pop-Location }
}

$dreamPrompt = 'Run a full /dream memory consolidation now, non-interactively. Follow the dream operation (entity sweep, link repair, dedup, reflection, skill-failure writeback, index sync, lint). Distill doctrine CANDIDATES only — do NOT approve any doctrine and do NOT build any skill (those need human review). Then run /harvest in SCAN-ONLY mode: produce the candidate list of repeatable workflows with evidence/confidence, but STOP before Step 6 (do not build anything). Summarize what you wrote.'

# Personal layer (run from home)
"## Personal layer" | Out-File $log -Append -Encoding UTF8
(Invoke-Headless $dreamPrompt $env:USERPROFILE) | Out-File $log -Append -Encoding UTF8

# Project layers
$projFile = Join-Path $personal 'nightly-projects.txt'
if (Test-Path $projFile) {
    foreach ($p in (Get-Content $projFile | Where-Object { $_.Trim() -ne '' -and -not $_.StartsWith('#') })) {
        if (Test-Path (Join-Path $p '.claude\memory')) {
            "## Project: $p" | Out-File $log -Append -Encoding UTF8
            (Invoke-Headless $dreamPrompt $p) | Out-File $log -Append -Encoding UTF8
        }
    }
}

"`nDone $((Get-Date -Format 'yyyy-MM-dd HH:mm')). Review next session: /review-doctrine and /harvest." | Out-File $log -Append -Encoding UTF8
