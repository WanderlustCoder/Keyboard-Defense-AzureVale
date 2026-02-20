$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$versionPath = Join-Path $repoRoot "apps\\keyboard-defense-monogame\\VERSION.txt"
$defaultVersion = "0.1.0"

function Fail([string]$message) {
    [Console]::Error.WriteLine($message)
    exit 1
}

function Read-Version {
    if (Test-Path $versionPath) {
        $v = (Get-Content -Path $versionPath -TotalCount 1).Trim()
        if (-not [string]::IsNullOrWhiteSpace($v)) {
            return $v
        }
    }
    return $defaultVersion
}

function Parse-Semver([string]$version) {
    if ($version -match '^(\d+)\.(\d+)\.(\d+)$') {
        return @{
            ok = $true
            major = [int]$matches[1]
            minor = [int]$matches[2]
            patch = [int]$matches[3]
        }
    }
    return @{ ok = $false }
}

$current = Read-Version

if ($args.Count -eq 0) {
    Write-Output ("Current version: {0}" -f $current)
    Write-Output "Usage:"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 set <version>"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 apply <version>"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 patch|minor|major"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 apply patch|minor|major"
    exit 0
}

$mode = $args[0]
$targetVersion = ""
$incrementMode = ""

if ($mode -eq "set") {
    if ($args.Count -lt 2) { Fail "ERROR: Missing version for set." }
    $targetVersion = $args[1]
} elseif ($mode -eq "apply") {
    if ($args.Count -lt 2) { Fail "ERROR: Missing value for apply." }
    if ($args[1] -in @("patch", "minor", "major")) {
        $incrementMode = $args[1]
    } else {
        $targetVersion = $args[1]
    }
} elseif ($mode -in @("patch", "minor", "major")) {
    $incrementMode = $mode
} else {
    Fail ("ERROR: Unknown mode: {0}" -f $mode)
}

if ($incrementMode -ne "") {
    $parsed = Parse-Semver $current
    if (-not $parsed.ok) {
        Fail ("ERROR: Current version is not semver: {0}" -f $current)
    }
    if ($incrementMode -eq "patch") {
        $parsed.patch += 1
    } elseif ($incrementMode -eq "minor") {
        $parsed.minor += 1
        $parsed.patch = 0
    } else {
        $parsed.major += 1
        $parsed.minor = 0
        $parsed.patch = 0
    }
    $targetVersion = "{0}.{1}.{2}" -f $parsed.major, $parsed.minor, $parsed.patch
}

if ($targetVersion -notmatch '^\d+\.\d+\.\d+$') {
    Fail ("ERROR: Invalid semver: {0}" -f $targetVersion)
}

if ($mode -eq "set" -or ($mode -in @("patch", "minor", "major"))) {
    Write-Output ("VERSION.txt: {0} -> {1}" -f $current, $targetVersion)
    Write-Output "Preview only. Use apply to write."
    exit 0
}

$null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $versionPath)
Set-Content -Path $versionPath -Value ($targetVersion + "`n")
Write-Output ("Updated VERSION.txt to {0}" -f $targetVersion)
exit 0
