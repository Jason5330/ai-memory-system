# tool.ps1 - saved-tools runner (Windows). A "saved tool" is a working script the AI wrote once and
# KEPT, so the SAME request next time just RUNS it instead of re-writing code. Distinct from a skill
# (a playbook the AI follows): a tool is a single executable, run verbatim. ASCII-only output
# (PowerShell 5.1 mis-decodes non-ASCII .ps1 literals without a BOM).
#
# Registry: ~/.ai-memory/tools/tools.json  ;  scripts live next to it as <slug>.ps1 / <slug>.sh
# Usage:
#   tool.ps1 list
#   tool.ps1 run <slug> [args...]    (forwards POSITIONAL args to the saved script; design saved tools
#                                     to take positional args or env vars, not -Named flags — a -Named
#                                     flag gets intercepted by this wrapper's own parameter binding)
#   tool.ps1 add <slug> -Desc "..." -Triggers "a;b;c" -Script <path-to-working-script>
#   tool.ps1 path <slug>
# Exit: 0 ok / 2 not found / 3 bad usage / 4 run error.
param(
  [Parameter(Position=0)][string]$Cmd = 'list',
  [Parameter(Position=1)][string]$Slug,
  [Parameter(ValueFromRemainingArguments=$true)][string[]]$Rest,
  [string]$Desc = '',
  [string]$Triggers = '',
  [string]$Script = ''
)
$ErrorActionPreference = 'Stop'
$enc  = New-Object System.Text.UTF8Encoding $false
$dir  = Join-Path $env:USERPROFILE '.ai-memory\tools'
$reg  = Join-Path $dir 'tools.json'
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
# read with explicit UTF-8 (PS 5.1 Get-Content mis-decodes UTF-8-no-BOM JSON containing non-ASCII triggers)
function Load { if (Test-Path $reg) { try { return ([System.IO.File]::ReadAllText($reg, [System.Text.Encoding]::UTF8) | ConvertFrom-Json) } catch { } } ; return [pscustomobject]@{ tools = @() } }
function Save($data) { $tmp = "$reg.tmp"; [System.IO.File]::WriteAllText($tmp, ($data | ConvertTo-Json -Depth 12), $enc); if (Test-Path $reg) { [System.IO.File]::Replace($tmp,$reg,"$reg.bak") } else { [System.IO.File]::Move($tmp,$reg) } }

switch ($Cmd) {
  'list' {
    $d = Load; $t = @($d.tools)
    if ($t.Count -eq 0) { Write-Output "TOOLS: none saved yet."; exit 0 }
    Write-Output "TOOLS: $($t.Count) saved -"
    foreach ($x in $t) { Write-Output ("  - {0}  : {1}   [triggers: {2}]" -f $x.slug, $x.desc, ((@($x.triggers)) -join ', ')) }
    exit 0
  }
  'path' {
    if (-not $Slug) { Write-Output "usage: tool.ps1 path <slug>"; exit 3 }
    $p = Join-Path $dir "$Slug.ps1"
    if (Test-Path $p) { Write-Output $p; exit 0 } else { Write-Output "NOT FOUND: $Slug.ps1"; exit 2 }
  }
  'run' {
    if (-not $Slug) { Write-Output "usage: tool.ps1 run <slug> [args...]"; exit 3 }
    $p = Join-Path $dir "$Slug.ps1"
    if (-not (Test-Path $p)) { Write-Output "NOT FOUND: no saved tool '$Slug' for this platform ($Slug.ps1)"; exit 2 }
    try { & $p @Rest; exit 0 } catch { Write-Output "RUN ERROR: $_"; exit 4 }
  }
  'add' {
    if (-not $Slug -or -not $Script) { Write-Output "usage: tool.ps1 add <slug> -Desc '...' -Triggers 'a;b' -Script <path>"; exit 3 }
    if (-not (Test-Path $Script)) { Write-Output "NOT FOUND: script '$Script'"; exit 2 }
    # copy the working script in under <slug> with the same extension
    $ext = [System.IO.Path]::GetExtension($Script); if (-not $ext) { $ext = '.ps1' }
    Copy-Item $Script (Join-Path $dir ("$Slug$ext")) -Force
    $d = Load; $list = @($d.tools | Where-Object { $_.slug -ne $Slug })   # replace if same slug
    $trg = @($Triggers -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $entry = [pscustomobject]@{ slug=$Slug; desc=$Desc; triggers=$trg; added=(Get-Date -Format 'yyyy-MM-dd') }
    $d.tools = @($list + $entry)
    Save $d
    Write-Output "SAVED tool '$Slug' ($ext). Next time a matching request comes, run: tool.ps1 run $Slug"
    exit 0
  }
  default { Write-Output "usage: tool.ps1 list | run <slug> [args] | add <slug> -Desc -Triggers -Script | path <slug>"; exit 3 }
}
