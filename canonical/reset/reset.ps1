# reset.ps1 — deterministic memory reset (Windows). The /reset operation gathers the user's choices
# interactively, then calls THIS script so the destructive part is a real, auditable tool.
#
# Usage:
#   reset.ps1 -Layer personal|project|both -Categories conversations,reflection,knowledge,doctrine,preferences[,blocked-actions]
#             [-ProjectPath <dir>] [-DryRun] [-Yes "yes reset"]
#
# Safety: backs up everything to be cleared FIRST, VERIFIES the backup (count match), only then clears;
# if any clear step throws, ROLLS BACK from the backup. Refuses to clear without -Yes "yes reset".
# Exit: 0 ok / 0 dry-run / 2 refused (no confirm) / 3 backup-verify failed / 4 rolled back after error.
param(
  [ValidateSet('personal','project','both')][string]$Layer = 'personal',
  [string[]]$Categories = @('conversations','reflection'),   # accepts "a,b" OR a,b OR a b
  [string]$ProjectPath = (Get-Location).Path,
  [switch]$DryRun,
  [string]$Yes = ''
)
$ErrorActionPreference = 'Stop'
$runId = (Get-Date -Format 'yyyyMMdd-HHmmss')
# flatten whether passed as one comma-string, a PowerShell array, or space-separated
$cats  = @($Categories | ForEach-Object { $_ -split '[, ]' } | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })
$reseed = @{
  'reflection.md'          = "# Reflection Log (personal, append-only)`r`n`r`n_(empty until first /dream)_`r`n"
  'doctrine.md'            = "# Doctrine — Approved Behavior Rules`r`n`r`n_(none yet)_`r`n"
  'doctrine_candidates.md' = "# Doctrine Candidates — Pending Review`r`n`r`n_(none yet)_`r`n"
  'feedback_user_style.md' = "# User Style & Preferences`r`n`r`n_(none yet)_`r`n"
  'persona.md'             = "# Agent Persona`r`n`r`n_(none yet)_`r`n"
  'blocked-actions.json'   = "{`r`n  `"blocked_tools`": []`r`n}`r`n"
}
# After clearing, prune MEMORY.md so its index reflects reality: drop any line whose linked .md file
# no longer exists (e.g. the conversation logs / knowledge pages we just cleared). Non-link lines
# (headers, the Environment-Limits section) and links to surviving files are kept. This is what makes
# the *visible* memory actually reset — clearing the content files alone leaves a stale index.
function Prune-Index($root) {
  $mem = Join-Path $root 'MEMORY.md'
  if (-not (Test-Path $mem)) { return }
  $kept = @()
  foreach ($ln in [System.IO.File]::ReadAllLines($mem, [System.Text.Encoding]::UTF8)) {
    $mt = [regex]::Match($ln, '\]\(([^)#:]+\.md)\)')
    if ($mt.Success -and -not (Test-Path (Join-Path $root $mt.Groups[1].Value.Trim()))) { continue }  # dead link → drop
    $kept += $ln
  }
  [System.IO.File]::WriteAllText($mem, (($kept -join "`r`n") + "`r`n"), (New-Object System.Text.UTF8Encoding $false))
}

# category -> items for a layer. dir items are cleared (files moved to backup); file items are reseeded.
function Items($root, $cat, $isPersonal) {
  switch ($cat) {
    'conversations' { @{ dirs=@("$root\conversations"); files=@() } }
    'knowledge'     { @{ dirs=@("$root\knowledge");     files=@() } }
    'reflection'    { if ($isPersonal) { @{ dirs=@(); files=@("$root\reflection.md") } } else { @{dirs=@();files=@()} } }
    'doctrine'      { if ($isPersonal) { @{ dirs=@(); files=@("$root\doctrine.md","$root\doctrine_candidates.md") } } else { @{dirs=@();files=@()} } }
    'preferences'   { if ($isPersonal) { @{ dirs=@(); files=@("$root\feedback_user_style.md","$root\persona.md") } } else { @{dirs=@();files=@()} } }
    'blocked-actions' { if ($isPersonal) { @{ dirs=@(); files=@("$root\blocked-actions.json") } } else { @{dirs=@();files=@()} } }
    default { @{dirs=@();files=@()} }
  }
}

$layers = @()
$aimem = if ($env:AI_MEMORY_HOME) { $env:AI_MEMORY_HOME -replace '^~', $env:USERPROFILE } else { Join-Path $env:USERPROFILE '.ai-memory' }
if ($Layer -in @('personal','both')) { $layers += @{ root=$aimem; personal=$true;  name='personal' } }
if ($Layer -in @('project','both'))  { $layers += @{ root=(Join-Path (Resolve-Path $ProjectPath) '.claude\memory'); personal=$false; name="project:$ProjectPath" } }

# ---- build plan ----
$plan = @()  # each: @{ root; backup; type='dir'|'file'; src }
foreach ($L in $layers) {
  if (-not (Test-Path $L.root)) { Write-Host "skip (no memory): $($L.name)" -ForegroundColor Yellow; continue }
  $backup = Join-Path $L.root ("archive\reset-$runId")
  foreach ($c in $cats) {
    $it = Items $L.root $c $L.personal
    foreach ($d in $it.dirs) { if (Test-Path $d) { Get-ChildItem $d -Filter *.md -File -ErrorAction SilentlyContinue | ForEach-Object { $plan += @{ root=$L.root; backup=$backup; type='dir'; src=$_.FullName } } } }
    foreach ($f in $it.files) { if (Test-Path $f) { $plan += @{ root=$L.root; backup=$backup; type='file'; src=$f } } }
  }
}

Write-Host "reset $runId — layer=$Layer categories=$($cats -join ',')" -ForegroundColor Cyan
Write-Host "Would affect $($plan.Count) file(s):"
$plan | ForEach-Object { Write-Host "  - $($_.src)" }

if ($DryRun) { Write-Host "`nDRY RUN — nothing written." -ForegroundColor Green; exit 0 }
if ($Yes -ne 'yes reset') { Write-Host "`nREFUSED: pass  -Yes ""yes reset""  to actually clear (nothing changed)." -ForegroundColor Red; exit 2 }
if ($plan.Count -eq 0) { Write-Host "Nothing to clear." -ForegroundColor Green; exit 0 }

# ---- backup ----
$done = @()  # pairs we cleared, for rollback
try {
  foreach ($p in $plan) {
    $rel = $p.src.Substring($p.root.Length).TrimStart('\')
    $dst = Join-Path $p.backup $rel
    New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
    Copy-Item $p.src $dst -Force
  }
  # ---- verify backup (count match) ----
  $backups = @($plan | ForEach-Object { $_.backup } | Select-Object -Unique)
  $backedCount = 0; foreach ($b in $backups) { $backedCount += @(Get-ChildItem $b -Recurse -File -ErrorAction SilentlyContinue).Count }
  if ($backedCount -ne $plan.Count) { Write-Host "BACKUP VERIFY FAILED ($backedCount/$($plan.Count)) — aborting, nothing cleared." -ForegroundColor Red; exit 3 }
  Write-Host "backup verified: $backedCount file(s) → $($backups -join ', ')" -ForegroundColor Green

  # ---- clear (with rollback on error) ----
  foreach ($p in $plan) {
    if ($p.type -eq 'dir') { [System.IO.File]::Delete($p.src) }                       # data is in backup
    else { $name=Split-Path $p.src -Leaf; $seed = if ($reseed.ContainsKey($name)) { $reseed[$name] } else { '' }
           [System.IO.File]::WriteAllText($p.src, $seed, (New-Object System.Text.UTF8Encoding $false)) }
    $done += $p
  }
}
catch {
  Write-Host "ERROR during clear: $_  — ROLLING BACK from backup..." -ForegroundColor Red
  foreach ($p in $done) {
    $rel = $p.src.Substring($p.root.Length).TrimStart('\'); $bak = Join-Path $p.backup $rel
    if (Test-Path $bak) { Copy-Item $bak $p.src -Force }
  }
  Write-Host "Rolled back $($done.Count) file(s)." -ForegroundColor Yellow
  exit 4
}

# clear succeeded → prune each affected layer's MEMORY.md so the loaded index no longer lists cleared content
foreach ($r in @($plan | ForEach-Object { $_.root } | Select-Object -Unique)) { Prune-Index $r }

Write-Host "`n✅ reset complete — cleared $($plan.Count) file(s) + pruned MEMORY.md index. Backup: $(($plan | ForEach-Object { $_.backup } | Select-Object -Unique) -join ', ')" -ForegroundColor Green
Write-Host "Restore = copy files back from the backup. Run /dream to fully rebuild the index if needed." -ForegroundColor Gray
exit 0
