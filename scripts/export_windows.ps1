$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $scriptDir "..\\apps\\keyboard-defense-godot\\scripts\\export_windows.ps1"

Write-Output "Delegating to apps/keyboard-defense-godot/scripts/export_windows.ps1"
if (-not (Test-Path $target)) {
    throw ("Missing export script: {0}" -f $target)
}

& $target @args
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    exit $exitCode
}

exit 0
