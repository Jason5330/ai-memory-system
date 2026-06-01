# init-project.ps1 — initialize the current folder as a memory-enabled project (Windows).
# Creates project-layer memory + dual-platform skill folders + entry files. Idempotent.
# Run INSIDE the project folder:  .\init-project.ps1   (or pass a path: .\init-project.ps1 C:\path\to\proj)

$ErrorActionPreference = 'Stop'
$proj = if ($args.Count -ge 1 -and $args[0]) { (Resolve-Path $args[0]).Path } else { (Get-Location).Path }
$name = Split-Path $proj -Leaf
$PT = Join-Path $env:USERPROFILE '.ai-memory\project-templates'
if (-not (Test-Path $PT)) { Write-Host "Run install-personal.ps1 first (missing $PT)." -ForegroundColor Red; exit 1 }

Write-Host "`n=== init-project: $name ===" -ForegroundColor Cyan

# Directories
foreach ($d in @('.claude\memory\knowledge','.claude\memory\knowledge\archive','.claude\memory\conversations','.claude\memory\conversations\archive','.claude\skills','.codex','.agents\skills')) {
    New-Item -ItemType Directory -Force (Join-Path $proj $d) | Out-Null
}

# Project MEMORY.md (copy-if-missing; substitute name)
$mem = Join-Path $proj '.claude\memory\MEMORY.md'
if (-not (Test-Path $mem)) {
    ((Get-Content (Join-Path $PT 'MEMORY.md') -Raw -Encoding UTF8) -replace '\{\{PROJECT_NAME\}\}', $name) | Out-File $mem -Encoding UTF8
}

# Entry files (copy-if-missing; substitute name)
function New-Entry($tpl, $dest) {
    if (Test-Path $dest) { return }
    ((Get-Content (Join-Path $PT $tpl) -Raw -Encoding UTF8) -replace '\{\{PROJECT_NAME\}\}', $name) | Out-File $dest -Encoding UTF8
}
New-Entry 'project-CLAUDE.md' (Join-Path $proj 'CLAUDE.md')
New-Entry 'project-AGENTS.md' (Join-Path $proj 'AGENTS.md')

# Minimal .codex/config.toml placeholder (hooks/skills config; not skills themselves)
$cfg = Join-Path $proj '.codex\config.toml'
if (-not (Test-Path $cfg)) {
@"
# Codex project config for this project. Skills live in ./.agents/skills (not here).
# Add project-scoped PreToolUse hooks or [[skills.config]] entries below if needed.
"@ | Out-File $cfg -Encoding UTF8
}

# .gitignore guard: never let personal memory leak; project knowledge MAY be committed.
$gi = Join-Path $proj '.gitignore'
$guard = "`n# ai-memory: project knowledge is shareable; never commit machine-local noise`n.claude/memory/conversations/`n.codex/`n"
if (Test-Path $gi) {
    if ((Get-Content $gi -Raw -Encoding UTF8) -notmatch 'ai-memory: project knowledge') { Add-Content $gi $guard -Encoding UTF8 }
} else { $guard.TrimStart() | Out-File $gi -Encoding UTF8 }

Write-Host "Created: CLAUDE.md, AGENTS.md, .claude/memory, .claude/skills, .codex/config.toml, .agents/skills" -ForegroundColor Green
Write-Host "Personal layer (~/.ai-memory) is shared and loaded globally; this only adds the project layer." -ForegroundColor Gray
