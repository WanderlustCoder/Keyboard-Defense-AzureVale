$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$projectRoot = Join-Path $repoRoot "apps/keyboard-defense-godot"
$versionPath = Join-Path $projectRoot "VERSION.txt"
$presetPath = Join-Path $projectRoot "export_presets.cfg"
$defaultVersion = "0.0.0"
$incrementModes = @("patch", "minor", "major")

function Fail {
    param([string]$message)
    [Console]::Error.WriteLine($message)
    exit 1
}

function Read-Version {
    if (Test-Path $versionPath) {
        $value = (Get-Content -Path $versionPath -TotalCount 1).Trim()
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }
    return $defaultVersion
}

function Read-Version-Info {
    $info = @{
        value = $defaultVersion
        exists = $false
        valid = $false
    }
    if (Test-Path $versionPath) {
        $value = (Get-Content -Path $versionPath -TotalCount 1).Trim()
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $info.value = $value
            $info.exists = $true
            $info.valid = ($value -match '^\d+\.\d+\.\d+$')
        }
    }
    return $info
}

function Parse-Semver {
    param([string]$version)
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

function Get-Preset-Options {
    param([string[]]$lines)
    $order = New-Object System.Collections.Generic.List[string]
    $data = @{}
    $currentPreset = ""
    $currentSection = ""
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $trimmed = $lines[$i].Trim()
        if ($trimmed -match '^\[preset\.(\d+)\.options\]$') {
            $currentPreset = $matches[1]
            $currentSection = "options"
            if (-not $data.ContainsKey($currentPreset)) {
                $data[$currentPreset] = @{
                    product_index = -1
                    file_index = -1
                    product_value = ""
                    file_value = ""
                }
                $null = $order.Add($currentPreset)
            }
            continue
        }
        if ($trimmed -match '^\[preset\.(\d+)\]$') {
            $currentPreset = $matches[1]
            $currentSection = "preset"
            continue
        }
        if ($currentSection -ne "options" -or $currentPreset -eq "") {
            continue
        }
        if ($trimmed -match '^application/product_version="(.*)"$') {
            $data[$currentPreset].product_index = $i
            $data[$currentPreset].product_value = $matches[1]
            continue
        }
        if ($trimmed -match '^application/file_version="(.*)"$') {
            $data[$currentPreset].file_index = $i
            $data[$currentPreset].file_value = $matches[1]
            continue
        }
    }
    return @{
        order = $order
        data = $data
    }
}

$currentVersion = Read-Version
$currentInfo = Read-Version-Info

if ($args.Count -eq 0) {
    Write-Output ("Current version: {0}" -f $currentVersion)
    Write-Output "Usage:"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 set <version>"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 apply <version>"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 patch"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 minor"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 major"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 apply patch"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 apply minor"
    Write-Output "  powershell -ExecutionPolicy Bypass -File .\\scripts\\bump_version.ps1 apply major"
    exit 0
}

$mode = $args[0]
$targetVersion = ""
$incrementMode = ""
if ($mode -eq "set") {
    if ($args.Count -lt 2) {
        Fail "ERROR: Missing version. Use set <version> or apply <version>."
    }
    $targetVersion = $args[1]
} elseif ($mode -eq "apply") {
    if ($args.Count -lt 2) {
        Fail "ERROR: Missing version. Use set <version> or apply <version>."
    }
    $second = $args[1]
    if ($incrementModes -contains $second) {
        $incrementMode = $second
    } else {
        $targetVersion = $second
    }
} elseif ($incrementModes -contains $mode) {
    $incrementMode = $mode
} else {
    Fail ("ERROR: Unknown mode: {0}" -f $mode)
}

if ($incrementMode -ne "") {
    if (-not $currentInfo.exists -or -not $currentInfo.valid) {
        Fail "ERROR: Current VERSION.txt is missing or invalid; use set <version>."
    }
    $parsed = Parse-Semver -version $currentInfo.value
    if (-not $parsed.ok) {
        Fail "ERROR: Current VERSION.txt is missing or invalid; use set <version>."
    }
    if ($incrementMode -eq "patch") {
        $parsed.patch += 1
    } elseif ($incrementMode -eq "minor") {
        $parsed.minor += 1
        $parsed.patch = 0
    } elseif ($incrementMode -eq "major") {
        $parsed.major += 1
        $parsed.minor = 0
        $parsed.patch = 0
    }
    $targetVersion = "{0}.{1}.{2}" -f $parsed.major, $parsed.minor, $parsed.patch
} else {
    if ($targetVersion -notmatch '^\d+\.\d+\.\d+$') {
        Fail ("ERROR: Invalid version: {0}" -f $targetVersion)
    }
}

if (-not (Test-Path $presetPath)) {
    Fail ("ERROR: Missing export preset: {0}" -f $presetPath)
}

$presetLines = Get-Content $presetPath
$presetInfo = Get-Preset-Options -lines $presetLines
$presetOrder = $presetInfo.order | Sort-Object { [int]$_ }
$presetData = $presetInfo.data
foreach ($presetIndex in $presetOrder) {
    $entry = $presetData[$presetIndex]
    $productIndex = $entry.product_index
    $fileIndex = $entry.file_index
    if ($productIndex -lt 0 -or $fileIndex -lt 0 `
        -or [string]::IsNullOrWhiteSpace($entry.product_value) `
        -or [string]::IsNullOrWhiteSpace($entry.file_value)) {
        Fail ("ERROR: Missing version keys in preset options for preset index {0}" -f $presetIndex)
    }
}

if ($mode -eq "set" -or ($incrementMode -ne "" -and $mode -ne "apply")) {
    Write-Output ("VERSION.txt: {0} -> {1}" -f $currentVersion, $targetVersion)
    Write-Output "export_presets.cfg:"
    foreach ($presetIndex in $presetOrder) {
        $entry = $presetData[$presetIndex]
        Write-Output ("  preset.{0}: product_version {1} -> {2}; file_version {3} -> {2}" -f $presetIndex, $entry.product_value, $targetVersion, $entry.file_value)
    }
    exit 0
}

$updatedLines = $presetLines.Clone()
foreach ($presetIndex in $presetOrder) {
    $entry = $presetData[$presetIndex]
    $updatedLines[$entry.product_index] = [regex]::Replace(
        $presetLines[$entry.product_index],
        '^(\\s*application/product_version=")[^"]*(".*)$',
        ("`$1{0}`$2" -f $targetVersion)
    )
    $updatedLines[$entry.file_index] = [regex]::Replace(
        $presetLines[$entry.file_index],
        '^(\\s*application/file_version=")[^"]*(".*)$',
        ("`$1{0}`$2" -f $targetVersion)
    )
}

$tempVersion = New-TemporaryFile
$tempPreset = New-TemporaryFile
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($tempVersion, $targetVersion + "`n", $utf8NoBom)
[System.IO.File]::WriteAllLines($tempPreset, $updatedLines, $utf8NoBom)
Move-Item -Force $tempVersion $versionPath
Move-Item -Force $tempPreset $presetPath

Write-Output ("Bumped version to {0}" -f $targetVersion)
