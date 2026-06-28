# install-personal.ps1 — Personal-layer installer (Windows) for the dual-platform memory system.
# Sets up ~/.ai-memory (platform-neutral brain) and materializes entry/operations/skills/hook/cron
# to BOTH Claude Code (~/.claude) and Codex (~/.codex + ~/.agents/skills). Idempotent.
# Run from the framework folder:  .\install-personal.ps1

$ErrorActionPreference = 'Stop'
$U = $env:USERPROFILE
$SRC = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'canonical'

# Personal brain root. Default ~/.ai-memory. Set $env:AI_MEMORY_HOME to RELOCATE the brain (e.g. a
# OneDrive/Dropbox folder for cross-machine sharing, or a writable drive). Claude Code + Codex already
# share this one brain; pointing both machines' AI_MEMORY_HOME at the same synced folder = shared memory.
$PERSONAL   = if ($env:AI_MEMORY_HOME) { $env:AI_MEMORY_HOME -replace '^~', $U } else { Join-Path $U '.ai-memory' }
$customHome = ($PERSONAL -ne (Join-Path $U '.ai-memory'))
$PERSONAL_FWD = ($PERSONAL -replace '\\','/')   # forward-slash form for the markdown the AI reads
$GUIDES     = Join-Path $PERSONAL 'guides'
$HOOKS      = Join-Path $PERSONAL 'hooks'
$CRON       = Join-Path $PERSONAL 'cron'
$CLAUDE     = Join-Path $U '.claude'
$CMDS       = Join-Path $CLAUDE 'commands'
$CLAUDE_SK  = Join-Path $CLAUDE 'skills'
$CODEX      = Join-Path $U '.codex'
$AGENTS_SK  = Join-Path $U '.agents\skills'

Write-Host "`n=== AI Memory System — personal install ===" -ForegroundColor Cyan
Write-Host "Personal brain: $PERSONAL" -ForegroundColor Gray
if ($customHome) { Write-Host "  (relocated via AI_MEMORY_HOME — set the SAME value on every machine/shell to share this brain)" -ForegroundColor Yellow }

# 1. Directories
foreach ($d in @($PERSONAL,$GUIDES,$HOOKS,$CRON,(Join-Path $PERSONAL 'knowledge'),(Join-Path $PERSONAL 'conversations'),(Join-Path $PERSONAL 'conversations\archive'),(Join-Path $PERSONAL 'knowledge\archive'),$CMDS,$CLAUDE_SK,$CODEX,$AGENTS_SK)) {
    New-Item -ItemType Directory -Force $d | Out-Null
}
Write-Host "[1] directories ready" -ForegroundColor Green

# 2. Migrate existing ~/.claude/memory/* into ~/.ai-memory (copy-if-missing; never delete original)
$oldMem = Join-Path $CLAUDE 'memory'
if (Test-Path $oldMem) {
    Get-ChildItem $oldMem -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($oldMem.Length).TrimStart('\')
        $dest = Join-Path $PERSONAL $rel
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        if (-not (Test-Path $dest)) { Copy-Item $_.FullName $dest -Force }
    }
    Write-Host "[2] migrated existing ~/.claude/memory (copy-if-missing; original kept)" -ForegroundColor Green
} else { Write-Host "[2] no legacy ~/.claude/memory to migrate" -ForegroundColor Gray }

# 3. Personal templates (copy-if-missing — this is your data)
$tpl = Join-Path $SRC 'templates\personal'
foreach ($f in @('MEMORY.md','doctrine.md','doctrine_candidates.md','feedback_user_style.md','persona.md','reflection.md')) {
    $dest = Join-Path $PERSONAL $f
    if (-not (Test-Path $dest)) { Copy-Item (Join-Path $tpl $f) $dest -Force }
}
$ba = Join-Path $PERSONAL 'blocked-actions.json'
if (-not (Test-Path $ba)) { Copy-Item (Join-Path $SRC 'templates\blocked-actions.json') $ba -Force }
Write-Host "[3] personal templates in place (existing data preserved)" -ForegroundColor Green

# Materialize a framework .md: plain copy by default; when the brain is relocated, rewrite the
# literal ~/.ai-memory runtime references to the real root so the AI reads correct paths.
function Copy-Doc($srcFile, $destFile) {
    if ($customHome) {
        $c = (Get-Content $srcFile -Raw -Encoding UTF8) -replace '~/\.ai-memory', $PERSONAL_FWD
        [System.IO.File]::WriteAllText($destFile, $c, (New-Object System.Text.UTF8Encoding $false))
    } else { Copy-Item $srcFile $destFile -Force }
}

# 4. Framework-owned files (always overwrite): guides, hook, cron, lint
Copy-Doc (Join-Path $SRC 'PATHS.md') (Join-Path $GUIDES 'PATHS.md')
Copy-Doc (Join-Path $SRC 'operations\_routing.md') (Join-Path $GUIDES '_routing.md')
Copy-Doc (Join-Path $SRC 'operations\_materialize-skill.md') (Join-Path $GUIDES '_materialize-skill.md')
Copy-Doc (Join-Path $SRC 'operations\_memory-gate.md') (Join-Path $GUIDES '_memory-gate.md')
Copy-Item (Join-Path $SRC 'hooks\block-failed-actions.ps1') (Join-Path $HOOKS 'block-failed-actions.ps1') -Force
Copy-Item (Join-Path $SRC 'hooks\block-failed-actions.sh')  (Join-Path $HOOKS 'block-failed-actions.sh')  -Force
Copy-Item (Join-Path $SRC 'cron\nightly.ps1') (Join-Path $CRON 'nightly.ps1') -Force
Copy-Item (Join-Path $SRC 'cron\nightly.sh')  (Join-Path $CRON 'nightly.sh')  -Force
Copy-Item (Join-Path $SRC 'lint\memory-lint.ps1') (Join-Path $PERSONAL 'memory-lint.ps1') -Force
Copy-Item (Join-Path $SRC 'lint\memory-lint.sh')  (Join-Path $PERSONAL 'memory-lint.sh')  -Force
$RESET = Join-Path $PERSONAL 'reset'; New-Item -ItemType Directory -Force $RESET | Out-Null
Copy-Item (Join-Path $SRC 'reset\reset.ps1') (Join-Path $RESET 'reset.ps1') -Force
Copy-Item (Join-Path $SRC 'reset\reset.sh')  (Join-Path $RESET 'reset.sh')  -Force
$LIB = Join-Path $PERSONAL 'lib'; New-Item -ItemType Directory -Force $LIB | Out-Null
Copy-Item (Join-Path $SRC 'lib\memory-write.ps1') (Join-Path $LIB 'memory-write.ps1') -Force
Copy-Item (Join-Path $SRC 'lib\memory-write.sh')  (Join-Path $LIB 'memory-write.sh')  -Force
Copy-Item (Join-Path $SRC 'lib\detect-repeats.ps1') (Join-Path $LIB 'detect-repeats.ps1') -Force
Copy-Item (Join-Path $SRC 'lib\detect-repeats.sh')  (Join-Path $LIB 'detect-repeats.sh')  -Force
Copy-Item (Join-Path $SRC 'lib\tool.ps1') (Join-Path $LIB 'tool.ps1') -Force
Copy-Item (Join-Path $SRC 'lib\tool.sh')  (Join-Path $LIB 'tool.sh')  -Force
Copy-Item (Join-Path $SRC 'lib\recall.py') (Join-Path $LIB 'recall.py') -Force
$TOOLS = Join-Path $PERSONAL 'tools'; New-Item -ItemType Directory -Force $TOOLS | Out-Null
if (-not (Test-Path (Join-Path $TOOLS 'tools.json'))) { Copy-Item (Join-Path $SRC 'templates\tools.json') (Join-Path $TOOLS 'tools.json') -Force }
# stage project scaffolding so init-project works from any folder without the framework repo
$PT = Join-Path $PERSONAL 'project-templates'
New-Item -ItemType Directory -Force $PT | Out-Null
Copy-Doc (Join-Path $SRC 'entry\project-CLAUDE.md') (Join-Path $PT 'project-CLAUDE.md')
Copy-Doc (Join-Path $SRC 'entry\project-AGENTS.md') (Join-Path $PT 'project-AGENTS.md')
Copy-Item (Join-Path $SRC 'templates\project\MEMORY.md') (Join-Path $PT 'MEMORY.md') -Force
# Stage init-project into the global brain so a portable 初始化專案.cmd can run from inside ANY
# project folder (no framework repo needed). $REPO = the framework root (parent of canonical/).
$REPO = Split-Path -Parent $SRC
Copy-Item (Join-Path $REPO 'init-project.ps1') (Join-Path $PERSONAL 'init-project.ps1') -Force
if (Test-Path (Join-Path $REPO 'init-project.sh')) { Copy-Item (Join-Path $REPO 'init-project.sh') (Join-Path $PERSONAL 'init-project.sh') -Force }
Write-Host "[4] guides + hook + cron + lint + project-templates + init-project installed" -ForegroundColor Green

# 5. Entry files (render {{PERSONAL_MEMORY}}); marker-guarded append for existing files
# Marker-delimited framework block: REPLACED on every install (so upgrades refresh the entry),
# while any of YOUR own content outside the markers is preserved.
function Install-Entry($srcFile, $destFile) {
    $content = (Get-Content $srcFile -Raw -Encoding UTF8) -replace '\{\{PERSONAL_MEMORY\}\}', ($PERSONAL -replace '\\','\')
    if ($customHome) { $content = $content -replace '~/\.ai-memory', $PERSONAL_FWD }   # relocate runtime refs
    $S = '<!-- AI-MEMORY-START (auto-managed by install-personal; do not edit between markers) -->'
    $E = '<!-- AI-MEMORY-END -->'
    $block = "$S`r`n$content`r`n$E"
    New-Item -ItemType Directory -Force (Split-Path $destFile) | Out-Null
    if (Test-Path $destFile) {
        $existing = Get-Content $destFile -Raw -Encoding UTF8
        $si = $existing.IndexOf('<!-- AI-MEMORY-START'); $ei = $existing.IndexOf($E)
        if ($si -ge 0 -and $ei -ge $si) {                       # has markers → replace just the block
            $new = $existing.Substring(0,$si) + $block + $existing.Substring($ei + $E.Length)
        } elseif ($existing -match '# AI Memory System') {      # legacy framework entry (no markers) → replace whole
            $new = $block
        } else {                                                # user's own file → append our block
            $new = $existing.TrimEnd() + "`r`n`r`n" + $block
        }
        [System.IO.File]::WriteAllText($destFile, $new, (New-Object System.Text.UTF8Encoding $false))
    } else {
        [System.IO.File]::WriteAllText($destFile, $block, (New-Object System.Text.UTF8Encoding $false))
    }
}
Install-Entry (Join-Path $SRC 'entry\CLAUDE.md') (Join-Path $CLAUDE 'CLAUDE.md')
Install-Entry (Join-Path $SRC 'entry\AGENTS.md') (Join-Path $CODEX 'AGENTS.md')
Write-Host "[5] entry files: ~/.claude/CLAUDE.md + ~/.codex/AGENTS.md" -ForegroundColor Green

# 6. Operations → Claude commands + Codex skills + Codex slash-commands (single source, triple materialize)
$ops = @('capture','handoff','recall','dream','harvest','review-doctrine','status','schedule-dream','reset','help','ingest-sessions')
$CODEX_PROMPTS = Join-Path $CODEX 'prompts'; New-Item -ItemType Directory -Force $CODEX_PROMPTS | Out-Null
foreach ($op in $ops) {
    $opSrc = Join-Path $SRC "operations\$op.md"
    Copy-Doc $opSrc (Join-Path $CMDS "$op.md")                              # Claude slash-command
    $skDir = Join-Path $AGENTS_SK $op
    New-Item -ItemType Directory -Force $skDir | Out-Null
    Copy-Doc $opSrc (Join-Path $skDir 'SKILL.md')                           # Codex skill (intent-triggered)
    Copy-Doc $opSrc (Join-Path $CODEX_PROMPTS "$op.md")                     # Codex slash-command (/capture etc.)
}
Write-Host "[6] operations materialized: Claude commands + Codex skills + Codex /slash prompts" -ForegroundColor Green

# 6b. Deploy the official Anthropic skill-creator to BOTH platforms (all skill creation goes through it).
$scSrc = Join-Path (Split-Path -Parent $SRC) 'skills\skill-creator'
if (Test-Path (Join-Path $scSrc 'SKILL.md')) {
    foreach ($scDest in @((Join-Path $CLAUDE_SK 'skill-creator'), (Join-Path $AGENTS_SK 'skill-creator'))) {
        if (-not (Test-Path (Join-Path $scDest 'SKILL.md'))) {
            New-Item -ItemType Directory -Force $scDest | Out-Null
            Copy-Item (Join-Path $scSrc '*') $scDest -Recurse -Force
        }
    }
    Write-Host "[6b] skill-creator deployed to ~/.claude/skills + ~/.agents/skills" -ForegroundColor Green
} else { Write-Host "[6b] skill-creator source not found (skipped)" -ForegroundColor Yellow }

# 7. Hook registration — Claude settings.json (catch-all matcher; script gates via registry)
$SETTINGS = Join-Path $CLAUDE 'settings.json'
$hookPs = (Join-Path $HOOKS 'block-failed-actions.ps1')
$claudeCmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$hookPs`" claude"
# Use $settingsObj for the parsed object — NOT $settings: PowerShell variable names are
# case-INSENSITIVE, so $settings aliases $SETTINGS and would clobber the file path (causing
# WriteAllText to fail with a hashtable-as-path on a fresh machine where the hook isn't registered yet).
# Wrapped so a LOCKED settings.json (Claude Code is open) doesn't abort the install — defer the Claude
# hook with a clear message, same as the Codex config.toml case below.
try {
    if (Test-Path $SETTINGS) { $settingsObj = Get-Content $SETTINGS -Raw -Encoding UTF8 | ConvertFrom-Json } else { $settingsObj = [PSCustomObject]@{} }
    if (-not ($settingsObj.PSObject.Properties.Name -contains 'hooks')) {
        $settingsObj | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([PSCustomObject]@{})
    }
    if (-not ($settingsObj.hooks.PSObject.Properties.Name -contains 'PreToolUse')) {
        $settingsObj.hooks | Add-Member -NotePropertyName 'PreToolUse' -NotePropertyValue @()
    }
    $already = $false
    foreach ($e in @($settingsObj.hooks.PreToolUse)) { foreach ($h in @($e.hooks)) { if ($h.command -like '*block-failed-actions*') { $already = $true } } }
    if (-not $already) {
        $entry = [PSCustomObject]@{ matcher = '*'; hooks = @([PSCustomObject]@{ type='command'; command=$claudeCmd }) }
        $settingsObj.hooks.PreToolUse = @($settingsObj.hooks.PreToolUse) + $entry
        $json = $settingsObj | ConvertTo-Json -Depth 20
        if ($json -is [array]) { $json = $json -join "`r`n" }   # guard: keep it one String for the overload
        $enc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText([string]$SETTINGS, [string]$json, $enc)
        Write-Host "[7a] Claude PreToolUse hook registered (matcher: *)" -ForegroundColor Green
    } else { Write-Host "[7a] Claude hook already registered" -ForegroundColor Gray }
} catch {
    Write-Host "[7a] DEFERRED: ~/.claude/settings.json is locked/unreadable (Claude Code is open)." -ForegroundColor Yellow
    Write-Host "     Everything else is installed; close Claude Code and re-run this installer once to" -ForegroundColor Yellow
    Write-Host "     register the Claude hard-block hook (idempotent)." -ForegroundColor Yellow
}

# 7b. Hook registration — Codex config.toml (append-if-marker-absent)
$CFG = Join-Path $CODEX 'config.toml'
$codexBlock = @"

# --- ai-memory enforcement hook (block-failed-actions) ---
[[hooks.PreToolUse]]
matcher = ".*"

[[hooks.PreToolUse.hooks]]
type = "command"
command = 'powershell -NoProfile -ExecutionPolicy Bypass -File "$hookPs" codex'
statusMessage = "ai-memory: checking blocked tools"
"@
# Wrapped so a LOCKED config.toml (Codex is open) doesn't abort the whole install — the memory system
# is already in place; only the Codex hard-block hook is deferred until Codex is closed and we re-run.
try {
    if (Test-Path $CFG) {
        if ((Get-Content $CFG -Raw -Encoding UTF8) -match 'block-failed-actions') { Write-Host "[7b] Codex hook already present" -ForegroundColor Gray }
        else { Add-Content -Path $CFG -Value $codexBlock -Encoding UTF8; Write-Host "[7b] Codex PreToolUse hook appended to config.toml" -ForegroundColor Green }
    } else {
        Set-Content -Path $CFG -Value $codexBlock.TrimStart() -Encoding UTF8
        Write-Host "[7b] Codex config.toml created with PreToolUse hook" -ForegroundColor Green
    }
} catch {
    Write-Host "[7b] DEFERRED: ~/.codex/config.toml is locked (Codex is open). Everything else is installed;" -ForegroundColor Yellow
    Write-Host "     only the Codex hard-block hook is pending. Fix: close Codex/VS Code, then re-run this" -ForegroundColor Yellow
    Write-Host "     installer once (idempotent). The memory system already works on Codex meanwhile." -ForegroundColor Yellow
}

Write-Host "`n=== Personal install complete ===" -ForegroundColor Cyan
Write-Host "Brain: $PERSONAL   |   Restart Claude Code / Codex to load." -ForegroundColor White
Write-Host "Per-project: run  .\init-project.ps1  inside each project folder." -ForegroundColor White
Write-Host "Nightly: run /schedule-dream (or see canonical/operations/schedule-dream.md)." -ForegroundColor White
