# memory-lint.ps1 — the "doctor": deterministic health check for the memory system (Windows)
# Usage: memory-lint.ps1 [-Strict] [root1] [root2] ...
# Default roots: ~/.ai-memory (personal) and ./.claude/memory (project, if present).
# Also runs GLOBAL wiring checks (hook registration, skill twin consistency, skill-creator).
# Reports and exits 0 by default. With -Strict it acts as a CI GATE: exit 1 if fail > 0.

$ErrorActionPreference = 'Continue'
$pass=0; $warn=0; $fail=0
function P($m){ $script:pass++; Write-Host "  PASS  $m" -ForegroundColor Green }
function W($m){ $script:warn++; Write-Host "  WARN  $m" -ForegroundColor Yellow }
function F($m){ $script:fail++; Write-Host "  FAIL  $m" -ForegroundColor Red }

$U = $env:USERPROFILE
$strict = $false
$roots = @()
foreach ($a in $args) {
    if ("$a" -in @('-Strict','--strict','-strict')) { $strict = $true } else { $roots += $a }
}
if ($roots.Count -eq 0) {
    $roots += (Join-Path $U '.ai-memory')
    $proj = Join-Path (Get-Location) '.claude\memory'
    if (Test-Path $proj) { $roots += $proj }
}

foreach ($root in $roots) {
    if (-not (Test-Path $root)) { W "root not found: $root"; continue }
    $isPersonal = ($root -like (Join-Path $U '.ai-memory*'))
    Write-Host "Linting: $root" -ForegroundColor Cyan

    # MEMORY.md present + dead links
    $mem = Join-Path $root 'MEMORY.md'
    if (Test-Path $mem) {
        P "MEMORY.md present"
        $mc = Get-Content $mem -Raw -Encoding UTF8
        foreach ($m in [regex]::Matches($mc, '\]\(([^)#:]+\.md)\)')) {
            $lnk = $m.Groups[1].Value.Trim()
            if (-not (Test-Path (Join-Path $root $lnk))) { W "MEMORY.md dead link: $lnk" }
        }
    } else { F "MEMORY.md missing in $root" }

    if ($isPersonal) {
        if (Test-Path (Join-Path $root 'persona.md')) { P "persona.md present" } else { W "persona.md missing (AI identity bucket)" }
        # blocked-actions.json schema
        $ba = Join-Path $root 'blocked-actions.json'
        if (Test-Path $ba) {
            try {
                $bd = Get-Content $ba -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($null -eq $bd.blocked_tools) { F "blocked-actions.json missing 'blocked_tools' array" }
                else {
                    $bad = $false
                    foreach ($e in $bd.blocked_tools) { if (-not $e.tool -or -not $e.use_instead) { $bad=$true } }
                    if ($bad) { F "blocked-actions.json entry missing tool/use_instead" } else { P "blocked-actions.json valid ($($bd.blocked_tools.Count) entries)" }
                }
            } catch { F "blocked-actions.json INVALID JSON — hard-block net is DOWN until fixed" }
        }
    }

    # knowledge pages
    $kdir = Join-Path $root 'knowledge'
    if (Test-Path $kdir) {
        Get-ChildItem $kdir -Filter '*.md' -File -ErrorAction SilentlyContinue | ForEach-Object {
            $f=$_.Name; $c=Get-Content $_.FullName -Raw -Encoding UTF8
            if ($f -cne $f.ToLower() -or $f -match '[ _]') { W "filename not kebab-lowercase: $f" }
            foreach ($k in @('name','type','kind','layer','first_seen','last_updated')) {
                if ($c -notmatch "(?m)^$k\s*:") { W "$f missing frontmatter '$k'" }
            }
            if ($c -notmatch 'Current State') { W "$f missing '## Current State'" }
            if ($c -notmatch 'Timeline') { W "$f missing '## Timeline'" }
            if ($c -notmatch '(?m)^>\s*Summary') { W "$f missing Why (the '> Summary' line)" }
            if ($c -notmatch 'How to Apply') { W "$f missing '## How to Apply'" }
            if ($c -match '(?m)^- \d{4}-\d\d-\d\d' -and $c -notmatch '\(source:') { W "$f Timeline line missing (source: ...)" }
        }
        P "knowledge/ scanned"
    }

    # doctrine ids unique (personal)
    $doc = Join-Path $root 'doctrine.md'
    if (Test-Path $doc) {
        $ids = [regex]::Matches((Get-Content $doc -Raw -Encoding UTF8), '(?m)^###\s+D-\d+') | ForEach-Object { $_.Value }
        if ($ids.Count -ne ($ids | Select-Object -Unique).Count) { F "duplicate doctrine D-XXX ids" } else { P "doctrine ids unique" }
    }

    # unconsolidated conversation logs older than 7 days
    $cdir = Join-Path $root 'conversations'
    if (Test-Path $cdir) {
        $stale = 0
        Get-ChildItem $cdir -Filter '*.md' -File -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.LastWriteTime -lt (Get-Date).AddDays(-7) -and (Get-Content $_.FullName -Raw -Encoding UTF8) -notmatch 'consolidated') { $stale++ }
        }
        if ($stale -gt 0) { W "$stale conversation log(s) >7 days old not yet consolidated — run /dream" } else { P "conversation logs consolidated/current" }
    }

    # privacy heuristic (project layer should NOT contain personal-layer memory)
    if (-not $isPersonal -and (Test-Path $kdir)) {
        $leak = Get-ChildItem $kdir -Filter '*.md' -File -ErrorAction SilentlyContinue | Where-Object { (Get-Content $_.FullName -Raw -Encoding UTF8) -match 'feedback_user_style|\.ai-memory|persona\.md' }
        if ($leak) { W "PRIVACY: project knowledge references personal-layer memory ($($leak.Count) file(s)) — personal memory must not leak into a shared project" }
    }
}

# ---- GLOBAL wiring checks ----
Write-Host "Wiring (both platforms):" -ForegroundColor Cyan
# Self-test runs the ACTUAL registered command (catches a stale path / wrong command), not just a
# string match. Pipes a non-blocked test payload; the registered command must exit 0.
function Invoke-RegisteredHook($cmd) {
    '{"tool_name":"__doctor_selftest__"}' | cmd /c $cmd 1>$null 2>$null
    return $LASTEXITCODE
}
# Claude: parse the registered command from settings.json and run IT
$cs = Join-Path $U '.claude\settings.json'
if (Test-Path $cs) {
    $reg = $null
    try { $sj = Get-Content $cs -Raw -Encoding UTF8 | ConvertFrom-Json
          foreach ($e in @($sj.hooks.PreToolUse)) { foreach ($h in @($e.hooks)) { if ($h.command -like '*block-failed-actions*') { $reg = $h.command } } } } catch {}
    if (-not $reg) { F "Claude hook NOT registered in settings.json — hard-block net is DOWN" }
    elseif ((Invoke-RegisteredHook $reg) -eq 0) { P "Claude hook registered command runs (self-test exit 0)" }
    else { F "Claude registered hook command FAILED self-test (stale path / broken command?) — net is DOWN" }
} else { W "Claude settings.json not found (run install-personal)" }
# Codex: parse the registered command line from config.toml and run IT
$cfg = Join-Path $U '.codex\config.toml'
if (Test-Path $cfg) {
    $line = Get-Content $cfg -Encoding UTF8 | Where-Object { $_ -match 'block-failed-actions' -and $_ -match 'command' } | Select-Object -First 1
    $reg = $null; if ($line -match "command\s*=\s*'(.+)'") { $reg = $matches[1] } elseif ($line -match 'command\s*=\s*"(.+)"') { $reg = $matches[1] }
    if (-not $reg) { W "Codex hook not registered in config.toml" }
    elseif ((Invoke-RegisteredHook $reg) -eq 0) { P "Codex hook registered command runs (self-test exit 0)" }
    else { F "Codex registered hook command FAILED self-test — Codex hard-block is DOWN" }
} else { W "Codex config.toml not found (Codex hard-block inactive)" }
# skill-creator deployed both platforms
$scC = Join-Path $U '.claude\skills\skill-creator\SKILL.md'
$scA = Join-Path $U '.agents\skills\skill-creator\SKILL.md'
if ((Test-Path $scC) -and (Test-Path $scA)) { P "skill-creator deployed (both platforms)" } else { W "skill-creator missing on a platform (Claude:$([bool](Test-Path $scC)) Codex:$([bool](Test-Path $scA)))" }
# PROMOTED-skill twin consistency: operations live as Claude commands vs Codex skills (expected to
# differ), so exclude them; a /harvest-promoted skill must exist on BOTH sides.
$ops = @('capture','dream','harvest','review-doctrine','status','schedule-dream','reset','help','skill-creator','ingest-sessions')
$claudeSk = Join-Path $U '.claude\skills'; $agentSk = Join-Path $U '.agents\skills'
if ((Test-Path $claudeSk) -and (Test-Path $agentSk)) {
    $cn = @(Get-ChildItem $claudeSk -Directory -ErrorAction SilentlyContinue | Where-Object { $ops -notcontains $_.Name } | Select-Object -Expand Name)
    $an = @(Get-ChildItem $agentSk  -Directory -ErrorAction SilentlyContinue | Where-Object { $ops -notcontains $_.Name } | Select-Object -Expand Name)
    $diff = @(Compare-Object $cn $an)
    if ($diff.Count -eq 0) { P "promoted skills in sync across platforms ($($cn.Count))" } else { W "promoted skills diverge: $((($diff | ForEach-Object { $_.InputObject }) -join ', '))" }
}

Write-Host ""
Write-Host "RESULT: $pass pass, $warn warn, $fail fail" -ForegroundColor Cyan
if ($strict -and $fail -gt 0) { Write-Host "STRICT: $fail failure(s) — exit 1" -ForegroundColor Red; exit 1 }
exit 0
