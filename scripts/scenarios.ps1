$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$testProject = Join-Path $repoRoot "apps\\keyboard-defense-monogame\\src\\KeyboardDefense.Tests\\KeyboardDefense.Tests.csproj"

if (-not (Test-Path $testProject)) {
    throw ("Missing test project: {0}" -f $testProject)
}

Write-Output "Running MonoGame scenario regression set (xUnit E2E namespace filter)."
dotnet test $testProject --configuration Release --filter "FullyQualifiedName~E2E" @args
exit $LASTEXITCODE
