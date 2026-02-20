$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$solutionPath = Join-Path $repoRoot "apps\\keyboard-defense-monogame\\KeyboardDefense.sln"

if (-not (Test-Path $solutionPath)) {
    throw ("Missing solution: {0}" -f $solutionPath)
}

dotnet test $solutionPath --configuration Release @args
exit $LASTEXITCODE
