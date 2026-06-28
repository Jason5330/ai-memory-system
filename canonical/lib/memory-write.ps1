# memory-write.ps1 — deterministic safe writer (Windows). Hermes-style write shell for the two
# safety-critical memory writes: append-to-file and add-to-block-registry. Does empty-check, dedup,
# file-lock, read-latest-from-disk, atomic temp+rename, and a drift backup. NOT a universal writer —
# knowledge pages (semantic merge) stay AI-edited. Called by the Memory Decision Gate (_memory-gate.md).
#
# Usage:
#   memory-write.ps1 -Mode append     -File <path> -Content "<text block>"
#   memory-write.ps1 -Mode block-tool  -Tool <Name> -Reason "..." -UseInstead "<Alt>" [-Platform both] [-File <registry.json>]
#
# Exit: 0 written · 0 (prints SKIP) duplicate/no-op · 2 empty content refused · 3 lock busy · 4 write error
#       · 5 registry corrupt (block-tool refused — original preserved, fix by hand).
param(
  [ValidateSet('append','block-tool')][string]$Mode = 'append',
  [string]$File,
  [string]$Content = '',
  [string]$Tool,
  [string]$Reason = '',
  [string]$UseInstead = '',
  [ValidateSet('claude','codex','both')][string]$Platform = 'both'
)
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding $false   # UTF-8 NO BOM (PS 5.1 safe)

function Acquire-Lock($target) {
  $lock = "$target.lock"
  for ($i = 0; $i -lt 30; $i++) {
    try { $fs = [System.IO.File]::Open($lock, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write); $fs.Close(); return $lock }
    catch { Start-Sleep -Milliseconds 100 }
  }
  return $null
}
function Release-Lock($lock) { if ($lock -and (Test-Path $lock)) { [System.IO.File]::Delete($lock) } }

# atomic write: tmp in same dir → backup current (drift snapshot) → replace
function Atomic-Write($target, $text) {
  $dir = Split-Path $target -Parent
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  $tmp = "$target.tmp"
  [System.IO.File]::WriteAllText($tmp, $text, $enc)
  if (Test-Path $target) {
    [System.IO.File]::Replace($tmp, $target, "$target.bak")   # .bak = pre-write drift snapshot
  } else {
    [System.IO.File]::Move($tmp, $target)
  }
}

if ($Mode -eq 'append') {
  if (-not $File) { Write-Host "ERROR: -File required for append." -ForegroundColor Red; exit 4 }
  if ([string]::IsNullOrWhiteSpace($Content)) { Write-Host "REFUSED: empty content (nothing written)." -ForegroundColor Yellow; exit 2 }
  $lock = Acquire-Lock $File
  if (-not $lock) { Write-Host "LOCK BUSY: $File.lock held — try again." -ForegroundColor Red; exit 3 }
  try {
    $cur = if (Test-Path $File) { [System.IO.File]::ReadAllText($File) } else { '' }   # read LATEST from disk
    if ($cur.Replace("`r","").Contains($Content.Trim().Replace("`r",""))) {
      Write-Host "SKIP: identical content already present in $File (no change)." -ForegroundColor Gray; exit 0
    }
    $sep = if ($cur.Length -gt 0 -and -not $cur.EndsWith("`n")) { "`r`n" } else { '' }
    Atomic-Write $File ($cur + $sep + $Content.TrimEnd() + "`r`n")
    Write-Host "✅ appended to $File" -ForegroundColor Green; exit 0
  }
  catch { Write-Host "WRITE ERROR: $_" -ForegroundColor Red; exit 4 }
  finally { Release-Lock $lock }
}

if ($Mode -eq 'block-tool') {
  if (-not $Tool) { Write-Host "ERROR: -Tool required for block-tool." -ForegroundColor Red; exit 4 }
  if (-not $File) {
    $aimem = if ($env:AI_MEMORY_HOME) { $env:AI_MEMORY_HOME -replace '^~', $env:USERPROFILE } else { Join-Path $env:USERPROFILE '.ai-memory' }
    $File = Join-Path $aimem 'blocked-actions.json'
  }
  $lock = Acquire-Lock $File
  if (-not $lock) { Write-Host "LOCK BUSY: $File.lock held — try again." -ForegroundColor Red; exit 3 }
  try {
    # If the registry EXISTS but is corrupt, REFUSE — never overwrite it with a fresh empty object
    # (that would silently drop every existing blocked tool, disarming the hard-block net). Preserve
    # the original and tell the user to fix it. Only seed an empty registry when the file truly absent.
    if (Test-Path $File) {
      try { $data = [System.IO.File]::ReadAllText($File, [System.Text.Encoding]::UTF8) | ConvertFrom-Json }
      catch { Write-Host "REFUSED: $File exists but is not valid JSON — NOT overwriting (would lose existing blocked tools). Fix it by hand, then retry." -ForegroundColor Red; exit 5 }
      if ($null -eq $data.blocked_tools) { Write-Host "REFUSED: $File has no 'blocked_tools' array — NOT overwriting. Fix it by hand." -ForegroundColor Red; exit 5 }
    } else { $data = [pscustomobject]@{ blocked_tools = @() } }
    $list = @($data.blocked_tools)
    foreach ($e in $list) {
      if ($e.tool -eq $Tool -and ($e.platform -eq $Platform -or $e.platform -eq 'both' -or $Platform -eq 'both')) {
        Write-Host "SKIP: '$Tool' already in registry (no change)." -ForegroundColor Gray; exit 0
      }
    }
    $entry = [pscustomobject]@{ tool=$Tool; reason=$Reason; use_instead=$UseInstead; platform=$Platform; added=(Get-Date -Format 'yyyy-MM-dd') }
    $data.blocked_tools = @($list + $entry)
    Atomic-Write $File (($data | ConvertTo-Json -Depth 10))
    Write-Host "✅ blocked '$Tool' (platform=$Platform) → $File. Restart Claude/Codex to load." -ForegroundColor Green; exit 0
  }
  catch { Write-Host "WRITE ERROR: $_" -ForegroundColor Red; exit 4 }
  finally { Release-Lock $lock }
}
