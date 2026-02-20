$ErrorActionPreference = "Stop"

Write-Output "Mid scenario tier is not split in MonoGame yet; running full scenario regression set."
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $scriptDir "scenarios.ps1"

if (-not (Test-Path $target)) {
    throw ("Missing script: {0}" -f $target)
}

& $target @args
exit $LASTEXITCODE
