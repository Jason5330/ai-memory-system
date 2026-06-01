# memory-lint.ps1 — deterministic health check for memory layers (Windows)
# Usage: memory-lint.ps1 [root1] [root2] ...
# Default roots: ~/.ai-memory (personal) and ./.claude/memory (project, if present).
# Exit 0 always; prints a final "RESULT: X pass, Y warn, Z fail" line.

$ErrorActionPreference = 'Continue'
$pass = 0; $warn = 0; $fail = 0
function Pass($m){ $script:pass++; Write-Host "  PASS  $m" -ForegroundColor Green }
function Warn($m){ $script:warn++; Write-Host "  WARN  $m" -ForegroundColor Yellow }
function Fail($m){ $script:fail++; Write-Host "  FAIL  $m" -ForegroundColor Red }

$roots = @()
if ($args.Count -gt 0) { $roots = $args }
else {
    $roots += (Join-Path $env:USERPROFILE '.ai-memory')
    $proj = Join-Path (Get-Location) '.claude\memory'
    if (Test-Path $proj) { $roots += $proj }
}

foreach ($root in $roots) {
    if (-not (Test-Path $root)) { Warn "root not found: $root"; continue }
    Write-Host "Linting: $root" -ForegroundColor Cyan

    if (Test-Path (Join-Path $root 'MEMORY.md')) { Pass "MEMORY.md present" } else { Fail "MEMORY.md missing in $root" }

    $ba = Join-Path $root 'blocked-actions.json'
    if (Test-Path $ba) {
        try { Get-Content $ba -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null; Pass "blocked-actions.json valid JSON" }
        catch { Fail "blocked-actions.json invalid JSON" }
    }

    $kdir = Join-Path $root 'knowledge'
    if (Test-Path $kdir) {
        Get-ChildItem $kdir -Filter '*.md' -File -ErrorAction SilentlyContinue | ForEach-Object {
            $f = $_.Name; $c = Get-Content $_.FullName -Raw -Encoding UTF8
            if ($f -cne $f.ToLower() -or $f -match '[ _]') { Warn "filename not kebab-lowercase: $f" }
            foreach ($k in @('name','type','kind','first_seen','last_updated')) {
                if ($c -notmatch "(?m)^$k\s*:") { Warn "$f missing frontmatter '$k'" }
            }
            if ($c -notmatch 'Current State') { Warn "$f missing '## Current State'" }
            if ($c -notmatch 'Timeline') { Warn "$f missing '## Timeline'" }
        }
        Pass "knowledge/ scanned"
    }

    $doc = Join-Path $root 'doctrine.md'
    if (Test-Path $doc) {
        $dc = Get-Content $doc -Raw -Encoding UTF8
        $ids = [regex]::Matches($dc, '(?m)^###\s+D-\d+') | ForEach-Object { $_.Value }
        if ($ids.Count -ne ($ids | Select-Object -Unique).Count) { Fail "duplicate doctrine D-XXX ids" } else { Pass "doctrine ids unique" }
    }
}

Write-Host ""
Write-Host "RESULT: $pass pass, $warn warn, $fail fail" -ForegroundColor Cyan
