$ErrorActionPreference = "Stop"
Write-Output "Delegating to scripts/scenarios_early.ps1"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..\\..\\..")
$target = Join-Path $repoRoot "scripts\\scenarios_early.ps1"
Push-Location $repoRoot
& $target @args
$exitCode = $LASTEXITCODE
Pop-Location
if ($exitCode -ne 0) {
    exit $exitCode
}
exit 0
