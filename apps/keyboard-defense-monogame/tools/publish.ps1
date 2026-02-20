<#
.SYNOPSIS
    Builds release packages for Keyboard Defense (MonoGame) for all platforms.
.DESCRIPTION
    Runs dotnet publish for win-x64, linux-x64, and osx-x64 as self-contained.
    Packages each into a zip (Windows/macOS) or tar.gz (Linux).
    Generates version.txt from git tag or manual version parameter.
.PARAMETER Version
    Version string (e.g. "1.0.0"). If not specified, reads from git describe.
.PARAMETER OutputDir
    Directory for packaged builds. Default: ../../dist
.PARAMETER RuntimeIds
    Comma-separated RIDs to build. Default: win-x64,linux-x64,osx-x64
#>
param(
    [string]$Version = "",
    [string]$OutputDir = "",
    [string]$RuntimeIds = "win-x64,linux-x64,osx-x64"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$monogameRoot = Split-Path -Parent $scriptDir
$gameProj = Join-Path $monogameRoot "src" "KeyboardDefense.Game" "KeyboardDefense.Game.csproj"
$gameName = "KeyboardDefense"

if (-not $OutputDir) {
    $OutputDir = Join-Path $monogameRoot "dist"
}

# Resolve version
if (-not $Version) {
    try {
        $Version = (git -C $monogameRoot describe --tags --always 2>$null).Trim()
    } catch {
        $Version = "dev"
    }
    if (-not $Version) { $Version = "dev" }
}

Write-Host "=== Keyboard Defense Release Builder ===" -ForegroundColor Cyan
Write-Host "Version: $Version"
Write-Host "Output:  $OutputDir"
Write-Host ""

# Clean output
if (Test-Path $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}
New-Item -ItemType Directory -Force $OutputDir | Out-Null

$rids = $RuntimeIds -split ","

foreach ($rid in $rids) {
    $rid = $rid.Trim()
    Write-Host "--- Building $rid ---" -ForegroundColor Yellow

    $publishDir = Join-Path $OutputDir "publish" $rid

    dotnet publish $gameProj `
        -c Release `
        -r $rid `
        --self-contained true `
        -p:PublishTrimmed=false `
        -o $publishDir

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: dotnet publish failed for $rid" -ForegroundColor Red
        exit 1
    }

    # Write version.txt
    Set-Content -Path (Join-Path $publishDir "version.txt") -Value $Version

    # Package
    $archiveName = "$gameName-$Version-$rid"

    if ($rid -like "linux-*") {
        $tarPath = Join-Path $OutputDir "$archiveName.tar.gz"
        Write-Host "Packaging $tarPath"
        Push-Location $publishDir
        tar -czf $tarPath *
        Pop-Location
    } else {
        $zipPath = Join-Path $OutputDir "$archiveName.zip"
        Write-Host "Packaging $zipPath"
        Compress-Archive -Path "$publishDir\*" -DestinationPath $zipPath -Force
    }

    Write-Host "Done: $rid" -ForegroundColor Green
    Write-Host ""
}

# Clean up publish intermediates
$publishRoot = Join-Path $OutputDir "publish"
if (Test-Path $publishRoot) {
    Remove-Item -Recurse -Force $publishRoot
}

Write-Host "=== All platforms built ===" -ForegroundColor Cyan
Write-Host "Archives in: $OutputDir"
Get-ChildItem $OutputDir | ForEach-Object {
    $sizeMB = [math]::Round($_.Length / 1MB, 1)
    Write-Host "  $($_.Name)  ($sizeMB MB)"
}
