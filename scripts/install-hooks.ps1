$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")

Push-Location $repoRoot
try {
    git config core.hooksPath .githooks
    Write-Host "Configured git hooks path: .githooks"
}
finally {
    Pop-Location
}
