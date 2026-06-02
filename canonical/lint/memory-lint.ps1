# memory-lint.ps1 — the "doctor": deterministic health check for the memory system (Windows)
# Usage: memory-lint.ps1 [root1] [root2] ...
# Default roots: ~/.ai-memory (personal) and ./.claude/memory (project, if present).
# Also runs GLOBAL wiring checks (hook registration, skill twin consistency, skill-creator).
# Exit 0 always; prints a final "RESULT: X pass, Y warn, Z fail" line. fail>0 = something to fix.

$ErrorActionPreference = 'Continue'
$pass=0; $warn=0; $fail=0
function P($m){ $script:pass++; Write-Host "  PASS  $m" -ForegroundColor Green }
function W($m){ $script:warn++; Write-Host "  WARN  $m" -ForegroundColor Yellow }
function F($m){ $script:fail++; Write-Host "  FAIL  $m" -ForegroundColor Red }

$U = $env:USERPROFILE
$roots = @()
if ($args.Count -gt 0) { $roots = $args }
else {
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
# Claude hook registered
$cs = Join-Path $U '.claude\settings.json'
if (Test-Path $cs) {
    if ((Get-Content $cs -Raw -Encoding UTF8) -match 'block-failed-actions') { P "Claude PreToolUse hook registered" }
    else { F "Claude hook NOT registered in settings.json — hard-block net is DOWN" }
} else { W "Claude settings.json not found (run install-personal)" }
# Codex hook registered
$cfg = Join-Path $U '.codex\config.toml'
if (Test-Path $cfg) {
    if ((Get-Content $cfg -Raw -Encoding UTF8) -match 'block-failed-actions') { P "Codex PreToolUse hook registered" }
    else { W "Codex hook not registered in config.toml" }
} else { W "Codex config.toml not found (Codex hard-block inactive)" }
# hook script exists + runnable (self-test: a non-blocked tool must exit 0)
$hook = Join-Path $U '.ai-memory\hooks\block-failed-actions.ps1'
if (Test-Path $hook) {
    '{"tool_name":"__doctor_selftest__"}' | & powershell -NoProfile -ExecutionPolicy Bypass -File $hook claude *> $null
    if ($LASTEXITCODE -eq 0) { P "hook script runs (self-test exit 0 on non-blocked tool)" } else { F "hook self-test returned $LASTEXITCODE (expected 0) — hook is broken" }
} else { F "hook script missing: $hook" }
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
