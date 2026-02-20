$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$monoRoot = Join-Path $repoRoot "apps\\keyboard-defense-monogame"
$project = Join-Path $monoRoot "src\\KeyboardDefense.Game\\KeyboardDefense.Game.csproj"
$distDir = Join-Path $monoRoot "dist"
$publishDir = Join-Path $distDir "win-x64"
$versionFile = Join-Path $monoRoot "VERSION.txt"

if (-not (Test-Path $project)) {
    throw ("Missing game project: {0}" -f $project)
}

$version = "dev"
if (Test-Path $versionFile) {
    $raw = (Get-Content -Path $versionFile -TotalCount 1).Trim()
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
        $version = $raw
    }
}

if (Test-Path $publishDir) {
    Remove-Item -Recurse -Force $publishDir
}
New-Item -ItemType Directory -Force -Path $publishDir | Out-Null

dotnet publish $project `
    -c Release `
    -r win-x64 `
    --self-contained true `
    -p:PublishTrimmed=false `
    -o $publishDir @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Set-Content -Path (Join-Path $publishDir "version.txt") -Value $version

$zipPath = Join-Path $distDir ("KeyboardDefense-{0}-win-x64.zip" -f $version)
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path "$publishDir\*" -DestinationPath $zipPath -Force

Write-Output ("Created {0}" -f $zipPath)
exit 0
