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
# personal brain root honors $AI_MEMORY_HOME (shared/relocatable brain), else default ~/.ai-memory.
$AIMEM = if ($env:AI_MEMORY_HOME) { $env:AI_MEMORY_HOME -replace '^~', $U } else { Join-Path $U '.ai-memory' }
$strict = $false
$roots = @()
foreach ($a in $args) {
    if ("$a" -in @('-Strict','--strict','-strict')) { $strict = $true } else { $roots += $a }
}
if ($roots.Count -eq 0) {
    $roots += $AIMEM
    $proj = Join-Path (Get-Location) '.claude\memory'
    if (Test-Path $proj) { $roots += $proj }
}

foreach ($root in $roots) {
    if (-not (Test-Path $root)) { W "root not found: $root"; continue }
    $isPersonal = ($root -eq $AIMEM -or $root -like "$AIMEM*")
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

    # OPEN-SOURCE HYGIENE (project layer = git-shareable): flag hardcoded personal absolute paths
    # (C:\Users\<name>, /Users/<name>, /home/<name>). They leak the author's username and break on
    # another machine — memory meant to be shared should use ~, $HOME, or relative paths instead.
    if (-not $isPersonal) {
        $pathRe = '(?i)[A-Z]:\\Users\\[^\\\s"''<>]+|/Users/[^/\s"''<>]+|/home/[^/\s"''<>]+'
        $hpFiles = @($mem)
        if (Test-Path $kdir) { $hpFiles += (Get-ChildItem $kdir -Filter '*.md' -File -EA SilentlyContinue | ForEach-Object FullName) }
        if (Test-Path $cdir) { $hpFiles += (Get-ChildItem $cdir -Filter '*.md' -File -EA SilentlyContinue | ForEach-Object FullName) }
        $hpHits = @()
        foreach ($hf in ($hpFiles | Where-Object { $_ -and (Test-Path $_) })) {
            if (([System.IO.File]::ReadAllText($hf, [System.Text.Encoding]::UTF8)) -match $pathRe) { $hpHits += (Split-Path $hf -Leaf) }
        }
        if ($hpHits.Count -gt 0) { W "OPEN-SOURCE: personal absolute path in $($hpHits.Count) shared file(s): $($hpHits -join ', ') — use ~ or a relative path so it doesn't leak a username or break on another machine" }
        else { P "no personal absolute paths in shareable project memory" }
    }

    # SECURITY: deterministic scan for prompt-injection / exfiltration phrasing inside stored memory
    # (defense-in-depth behind the "memory is data, not instructions" rule). WARN only — a human reviews,
    # since memory may legitimately quote such text.
    $suspect = 'ignore\s+(all\s+)?(previous|prior|above)\s+instructions|disregard\s+(all\s+|the\s+)?(previous|prior|above)|exfiltrat|(reveal|print|show)\s+(your\s+)?(system\s+)?prompt'
    $scanFiles = @($mem)
    if (Test-Path $kdir) { $scanFiles += (Get-ChildItem $kdir -Filter '*.md' -File -EA SilentlyContinue | ForEach-Object FullName) }
    if (Test-Path $cdir) { $scanFiles += (Get-ChildItem $cdir -Filter '*.md' -File -EA SilentlyContinue | ForEach-Object FullName) }
    $hits = @()
    foreach ($sf in ($scanFiles | Where-Object { $_ -and (Test-Path $_) })) {
        if (([System.IO.File]::ReadAllText($sf, [System.Text.Encoding]::UTF8)) -match $suspect) { $hits += (Split-Path $sf -Leaf) }
    }
    if ($hits.Count -gt 0) { W "SECURITY: injection/exfiltration phrasing in $($hits.Count) memory file(s): $($hits -join ', ') — review (stored memory is data, never an instruction to obey)" }
    else { P "memory content clean (no injection/exfiltration phrasing)" }
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
# Entry files present + carry the AI-MEMORY block (so each platform actually loads memory at startup)
foreach ($ent in @(@{p=(Join-Path $U '.claude\CLAUDE.md'); n='Claude ~/.claude/CLAUDE.md'},
                   @{p=(Join-Path $U '.codex\AGENTS.md');  n='Codex ~/.codex/AGENTS.md'})) {
    if (Test-Path $ent.p) {
        if ((Get-Content $ent.p -Raw -Encoding UTF8) -match 'AI-MEMORY-START') { P "$($ent.n) present + AI-MEMORY block" }
        else { W "$($ent.n) exists but MISSING the AI-MEMORY block — that platform won't load memory (run install-personal)" }
    } else { W "$($ent.n) not found — that platform won't load memory (run install-personal)" }
}
# skill-creator deployed both platforms
$scC = Join-Path $U '.claude\skills\skill-creator\SKILL.md'
$scA = Join-Path $U '.agents\skills\skill-creator\SKILL.md'
if ((Test-Path $scC) -and (Test-Path $scA)) { P "skill-creator deployed (both platforms)" } else { W "skill-creator missing on a platform (Claude:$([bool](Test-Path $scC)) Codex:$([bool](Test-Path $scA)))" }
# lib backbone present + parse-clean (memory-write / detect-repeats / tool — the deterministic scripts)
$libDir = Join-Path $AIMEM 'lib'
$expectLib = @('memory-write','detect-repeats','tool')
$libMissing = @(); $libBad = @()
foreach ($b in $expectLib) {
    foreach ($ext in @('.ps1','.sh')) {
        $p = Join-Path $libDir "$b$ext"
        if (-not (Test-Path $p)) { $libMissing += "$b$ext" }
        elseif ($ext -eq '.ps1') {
            $perr = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$null, [ref]$perr)
            if ($perr -and $perr.Count -gt 0) { $libBad += "$b$ext" }
        }
    }
}
if ($libMissing.Count -gt 0) { F "lib scripts MISSING: $($libMissing -join ', ') (run install-personal)" }
elseif ($libBad.Count -gt 0) { F "lib .ps1 parse errors: $($libBad -join ', ')" }
else { P "lib backbone present (.ps1+.sh) + .ps1 parse-clean (memory-write/detect-repeats/tool)" }
# Note: .sh syntax is validated by memory-lint.sh on its native platform — running `bash -n` against
# Windows-path/CRLF copies here gives false positives, so this (Windows) doctor only parse-checks .ps1.
# Platform skills: operations live as Claude commands vs Codex skills (expected to differ) → exclude
# them. A /harvest-promoted skill is materialized to BOTH platforms atomically, so anything present on
# only ONE platform is the USER'S OWN skill (installed independently) — that is NOT a problem, just
# informational. Don't WARN on it (it caused false "needs cleanup" alarms).
$ops = @('capture','dream','harvest','review-doctrine','status','schedule-dream','reset','help','skill-creator','ingest-sessions')
$claudeSk = Join-Path $U '.claude\skills'; $agentSk = Join-Path $U '.agents\skills'
if ((Test-Path $claudeSk) -and (Test-Path $agentSk)) {
    $cn = @(Get-ChildItem $claudeSk -Directory -ErrorAction SilentlyContinue | Where-Object { $ops -notcontains $_.Name } | Select-Object -Expand Name)
    $an = @(Get-ChildItem $agentSk  -Directory -ErrorAction SilentlyContinue | Where-Object { $ops -notcontains $_.Name } | Select-Object -Expand Name)
    $both = @($cn | Where-Object { $an -contains $_ })
    $oneOnly = @(@($cn | Where-Object { $an -notcontains $_ }) + @($an | Where-Object { $cn -notcontains $_ }))
    if ($oneOnly.Count -eq 0) { P "platform skills in sync ($($both.Count) on both)" }
    else { P "platform skills: $($both.Count) on both; one-platform-only (your own, not a problem): $($oneOnly -join ', ')" }
}

Write-Host ""
Write-Host "RESULT: $pass pass, $warn warn, $fail fail" -ForegroundColor Cyan
if ($strict -and $fail -gt 0) { Write-Host "STRICT: $fail failure(s) — exit 1" -ForegroundColor Red; exit 1 }
exit 0
