# block-failed-actions.ps1 — PreToolUse enforcement layer (Windows; Claude Code + Codex)
#
# Reads ~/.ai-memory/blocked-actions.json. If the tool about to run is on the
# blocklist (and applies to this platform), exits 2 with a reason on stderr.
# BOTH Claude Code and Codex honor "exit 2 + stderr" to deny a PreToolUse call.
#
# Usage in registration:
#   Claude (settings.json):  powershell ... -File block-failed-actions.ps1 claude
#   Codex  (config.toml):    powershell ... -File block-failed-actions.ps1 codex
# Platform arg is optional (defaults to "claude"). An entry blocks when its
# "platform" field is absent, "both", or equals this platform.
#
# Generic + data-driven: knows no specific tool; only reads the registry.

$ErrorActionPreference = 'Stop'
$platform = if ($args.Count -ge 1 -and $args[0]) { "$($args[0])".ToLower() } else { 'claude' }

# 1. Read hook payload (JSON on stdin → tool_name)
try {
    $raw = [Console]::In.ReadToEnd()
    $payload = $raw | ConvertFrom-Json
} catch { exit 0 }   # fail-open

$tool = $payload.tool_name
if ([string]::IsNullOrEmpty($tool)) { exit 0 }

# 2. Read registry
$registry = Join-Path $env:USERPROFILE '.ai-memory\blocked-actions.json'
if (-not (Test-Path $registry)) { exit 0 }
try {
    $data = Get-Content $registry -Raw -Encoding UTF8 | ConvertFrom-Json
} catch { exit 0 }

# 3. Match (tool name + platform applicability) → hard block
foreach ($b in $data.blocked_tools) {
    if ($b.tool -ne $tool) { continue }
    $p = if ($b.PSObject.Properties['platform']) { "$($b.platform)".ToLower() } else { 'both' }
    if ($p -ne 'both' -and $p -ne $platform) { continue }
    [Console]::Error.WriteLine("[memory enforcement] $tool is known-broken in this environment: $($b.reason). Use $($b.use_instead) instead; do not call $tool.")
    exit 2
}

exit 0
