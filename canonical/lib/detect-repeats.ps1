# detect-repeats.ps1 - deterministic repeat-workflow detector (Windows). Scans BOTH layers'
# conversation logs for tagged repeat markers ( "- (loop) repeat:<slug> - <desc>" lines that /capture,
# /dream and /ingest-sessions drop once per occurrence ), tallies how many times each workflow
# recurred, cross-checks existing skills on both platforms, and lists workflows seen >= threshold that
# have NO skill yet - the ones worth proactively offering to turn into a skill via /harvest.
#
# Output is ASCII-only on purpose (PowerShell 5.1 mis-decodes non-ASCII .ps1 literals without a BOM);
# the Traditional-Chinese reminder phrasing lives in the entry files / status.md, not here. The caller
# (the AI) turns this data into the "我發現你做過 X N 次, 要不要生成 skill?" message.
#
# Usage:  detect-repeats.ps1 [-Threshold 2] [-ProjectPath <dir>] [-Json]
# Exit: 0 always (read-only reporter).
param(
  [int]$Threshold = 2,
  [string]$ProjectPath = (Get-Location).Path,
  [switch]$Json
)
$ErrorActionPreference = 'Stop'

$roots = @()
$personal = Join-Path $env:USERPROFILE '.ai-memory'
if (Test-Path $personal) { $roots += $personal }
$projRoot = Join-Path $ProjectPath '.claude\memory'
if (Test-Path $projRoot) { $roots += $projRoot }

# existing skills by dir name (both platforms + project) - never re-offer something already built
$existing = @{}
foreach ($sr in @("$env:USERPROFILE\.claude\skills", "$env:USERPROFILE\.agents\skills",
                  "$ProjectPath\.claude\skills", "$ProjectPath\.agents\skills")) {
  if (Test-Path $sr) { Get-ChildItem $sr -Directory -ErrorAction SilentlyContinue | ForEach-Object { $existing[$_.Name.ToLower()] = $true } }
}

# tally slugs from "repeat:<slug>" tokens (one per occurrence). Key on the ASCII "repeat:" token (not
# the emoji); no end anchor so the greedy slug grabs the whole "md-to-html" without backtracking.
$tally = @{}
foreach ($r in $roots) {
  $cdir = Join-Path $r 'conversations'
  if (-not (Test-Path $cdir)) { continue }
  foreach ($f in Get-ChildItem $cdir -Filter *.md -File -ErrorAction SilentlyContinue) {
    foreach ($line in [System.IO.File]::ReadAllLines($f.FullName)) {
      foreach ($mm in [regex]::Matches($line, 'repeat:([a-z0-9][a-z0-9-]*)')) {
        $slug = $mm.Groups[1].Value.ToLower()
        $tally[$slug] = 1 + $(if ($tally.ContainsKey($slug)) { $tally[$slug] } else { 0 })
      }
    }
  }
}

$cands = @()
foreach ($slug in $tally.Keys) {
  if ($tally[$slug] -ge $Threshold -and -not $existing.ContainsKey($slug)) {
    $cands += [pscustomobject]@{ slug = $slug; count = $tally[$slug] }
  }
}
$cands = @($cands | Sort-Object count -Descending)

if ($Json) { ($cands | ConvertTo-Json -Depth 5 -Compress); exit 0 }
if ($cands.Count -eq 0) { Write-Output "REPEATS: none (no workflow seen >= $Threshold without a skill)"; exit 0 }
Write-Output "REPEATS: $($cands.Count) workflow(s) seen >= $Threshold with no skill yet -"
foreach ($c in $cands) { Write-Output ("  - {0}  (seen {1}x)" -f $c.slug, $c.count) }
Write-Output "-> offer /harvest to turn these into skills"
exit 0
