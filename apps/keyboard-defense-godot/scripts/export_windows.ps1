$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
$presetName = "Windows Desktop"
$outputRelative = "build/windows/KeyboardDefense.exe"
$outputPath = Join-Path $projectRoot $outputRelative
$outputDirRelative = Split-Path -Parent $outputRelative
$outputDirPath = Join-Path $projectRoot $outputDirRelative
$zipRelative = "build/windows/KeyboardDefense-win64.zip"
$presetConfig = Join-Path $projectRoot "export_presets.cfg"
$versionFilePath = Join-Path $projectRoot "VERSION.txt"

$defaultProductName = "Keyboard Defense"
$defaultProductVersion = "0.0.0"
$productName = $defaultProductName
$productVersion = $defaultProductVersion
$productFileVersion = $defaultProductVersion
$embedPck = $false
$matchedPreset = ""
$presetLines = @()
if (Test-Path $presetConfig) {
    $presetLines = Get-Content $presetConfig
    $currentPreset = ""
    foreach ($line in $presetLines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^\[preset\.(\d+)\]$') {
            $currentPreset = $matches[1]
            continue
        }
        if ($currentPreset -ne "" -and $trimmed -match '^name="(.+)"$') {
            if ($matches[1] -eq $presetName) {
                $matchedPreset = $currentPreset
            }
        }
    }

    if ($matchedPreset -ne "") {
        $currentPreset = ""
        $currentSection = ""
        $foundEmbed = $false
        $foundName = $false
        $foundVersion = $false
        $foundFileVersion = $false
        foreach ($line in $presetLines) {
            $trimmed = $line.Trim()
            if ($trimmed -match '^\[preset\.(\d+)\]$') {
                $currentPreset = $matches[1]
                $currentSection = "preset"
                continue
            }
            if ($trimmed -match '^\[preset\.(\d+)\.options\]$') {
                $currentPreset = $matches[1]
                $currentSection = "options"
                continue
            }
            if ($currentSection -ne "options" -or $currentPreset -ne $matchedPreset) {
                continue
            }
            if ($trimmed -match '^binary_format/embed_pck=(true|false)$') {
                $embedPck = [System.Boolean]::Parse($matches[1])
                $foundEmbed = $true
                continue
            }
            if ($trimmed -match '^application/product_name="(.*)"$') {
                if ($matches[1] -ne "") {
                    $productName = $matches[1]
                    $foundName = $true
                }
                continue
            }
            if ($trimmed -match '^application/product_version="(.*)"$') {       
                if ($matches[1] -ne "") {
                    $productVersion = $matches[1]
                    $foundVersion = $true
                }
                continue
            }
            if ($trimmed -match '^application/file_version="(.*)"$') {
                if ($matches[1] -ne "") {
                    $productFileVersion = $matches[1]
                    $foundFileVersion = $true
                }
                continue
            }
            if ($foundEmbed -and $foundName -and $foundVersion -and $foundFileVersion) {
                break
            }
        }
    }
}

if ([string]::IsNullOrWhiteSpace($productName)) {
    $productName = $defaultProductName
}
if ([string]::IsNullOrWhiteSpace($productVersion)) {
    $productVersion = $defaultProductVersion
}
if ([string]::IsNullOrWhiteSpace($productFileVersion)) {
    $productFileVersion = $defaultProductVersion
}

$versionFileValue = $defaultProductVersion
if (Test-Path $versionFilePath) {
    $versionFileValue = (Get-Content -Path $versionFilePath -TotalCount 1).Trim()
}
if ([string]::IsNullOrWhiteSpace($versionFileValue)) {
    $versionFileValue = $defaultProductVersion
}

$zipVersionedRelative = ("build/windows/KeyboardDefense-{0}-win64.zip" -f $productVersion)
$manifestRelative = "build/windows/export_manifest.json"
$manifestPath = Join-Path $projectRoot $manifestRelative

$pckRelative = "none"
$pckPath = ""
if (-not $embedPck) {
    $pckRelative = [System.IO.Path]::ChangeExtension($outputRelative, ".pck")
    $pckPath = Join-Path $projectRoot $pckRelative
}

$godot = $env:GODOT_BIN
$godotSource = "GODOT_BIN"
if (-not $godot) {
    $godot = "godot"
    $godotSource = "PATH"
}

$godotResolved = $godot
$godotFound = $true
try {
    if ($godotSource -eq "PATH") {
        $command = Get-Command $godot -ErrorAction Stop
        $godotResolved = $command.Source
    } else {
        if (-not (Test-Path $godot)) {
            $godotFound = $false
        }
    }
} catch {
    $godotFound = $false
}

$apply = $args -contains "apply"
$package = $args -contains "package"
$versioned = $args -contains "versioned"
$mode = "dry-run"
if ($apply -and $package) {
    $mode = "apply+package"
} elseif ($apply) {
    $mode = "apply"
} elseif ($package) {
    $mode = "package"
}

$zipSelectedRelative = $zipRelative
if ($versioned) {
    $zipSelectedRelative = $zipVersionedRelative
}
$zipSelectedPath = Join-Path $projectRoot $zipSelectedRelative

$godotLabel = $godotResolved
if (-not $godotFound) {
    $godotLabel = "%s (not found)" -f $godotResolved
}

$commandLine = "`"$godotResolved`" --headless --path `"$projectRoot`" --export-release `"$presetName`" `"$outputRelative`""
$outputName = [System.IO.Path]::GetFileName($outputRelative)
$pckName = ""
if (-not $embedPck) {
    $pckName = [System.IO.Path]::GetFileName($pckRelative)
}
$manifestName = [System.IO.Path]::GetFileName($manifestRelative)
$zipFileName = [System.IO.Path]::GetFileName($zipSelectedRelative)
$zipInputsRoot = @($outputName)
if (-not $embedPck) {
    $zipInputsRoot += $pckName
}
$zipInputsRoot += $manifestName
$zipCommand = "Compress-Archive -Force -Path {0} -DestinationPath `"{1}`"" -f ((($zipInputsRoot | ForEach-Object { "`"$_`"" }) -join ", "), $zipFileName)
$fileVersionMismatch = $productFileVersion -ne $productVersion
$versionFileMismatch = $versionFileValue -ne $productFileVersion
$versionMismatch = $versionFileValue -ne $productVersion

function Escape-JsonString {
    param([string]$value)
    return ($value -replace '\\', '\\\\' -replace '"', '\\"')
}

function New-ExportManifestJson {
    param(
        [string]$preset,
        [string]$productNameValue,
        [string]$productVersionValue,
        [bool]$embedValue,
        [string[]]$outputs
    )
    $escapedPreset = Escape-JsonString $preset
    $escapedName = Escape-JsonString $productNameValue
    $escapedVersion = Escape-JsonString $productVersionValue
    $lines = @(
        "{",
        "  ""schema"": ""typing-defense.export-manifest"",",
        "  ""schema_version"": 1,",
        ("  ""preset"": ""{0}""," -f $escapedPreset),
        ("  ""product_name"": ""{0}""," -f $escapedName),
        ("  ""product_version"": ""{0}""," -f $escapedVersion),
        ("  ""embed_pck"": {0}," -f $embedValue.ToString().ToLower()),
        "  ""outputs"": ["
    )
    for ($i = 0; $i -lt $outputs.Count; $i++) {
        $suffix = ""
        if ($i -lt ($outputs.Count - 1)) {
            $suffix = ","
        }
        $lines += ("    ""{0}""{1}" -f (Escape-JsonString $outputs[$i]), $suffix)
    }
    $lines += "  ]"
    $lines += "}"
    return ($lines -join "`n") + "`n"
}

Write-Output ("Mode: {0}" -f $mode)
Write-Output ("Godot: {0} ({1})" -f $godotLabel, $godotSource)
Write-Output ("Project: {0}" -f $projectRoot)
Write-Output ("Preset: {0}" -f $presetName)
Write-Output ("Product: {0} {1}" -f $productName, $productVersion)
Write-Output ("Version file: {0}" -f $versionFileValue)
Write-Output ("Preset version: {0}" -f $productVersion)
Write-Output ("Preset file_version: {0}" -f $productFileVersion)
Write-Output ("Output: {0}" -f $outputRelative)
Write-Output ("Embed PCK: {0}" -f $embedPck.ToString().ToLower())
Write-Output ("PCK Output: {0}" -f $pckRelative)
Write-Output ("Zip: {0}" -f $zipRelative)
Write-Output ("Zip (versioned): {0}" -f $zipVersionedRelative)
Write-Output ("Manifest: {0}" -f $manifestRelative)
Write-Output ("Zip Command: {0}" -f $zipCommand)
Write-Output ("Command: {0}" -f $commandLine)

$hasMismatch = $false
if ($fileVersionMismatch) {
    if ($mode -eq "dry-run") {
        Write-Output ("WARNING: preset file_version ({0}) != preset product_version ({1})" -f $productFileVersion, $productVersion)
    } else {
        [Console]::Error.WriteLine(("ERROR: preset file_version ({0}) != preset product_version ({1})" -f $productFileVersion, $productVersion))
        $hasMismatch = $true
    }
}
if ($versionFileMismatch) {
    if ($mode -eq "dry-run") {
        Write-Output ("WARNING: VERSION.txt ({0}) != preset file_version ({1})" -f $versionFileValue, $productFileVersion)
    } else {
        [Console]::Error.WriteLine(("ERROR: VERSION.txt ({0}) != preset file_version ({1})" -f $versionFileValue, $productFileVersion))
        $hasMismatch = $true
    }
}
if ($versionMismatch) {
    if ($mode -eq "dry-run") {
        Write-Output ("WARNING: VERSION.txt ({0}) != preset product_version ({1})" -f $versionFileValue, $productVersion)
    } else {
        [Console]::Error.WriteLine(("ERROR: VERSION.txt ({0}) != preset product_version ({1})" -f $versionFileValue, $productVersion))
        $hasMismatch = $true
    }
}
if ($hasMismatch -and $mode -ne "dry-run") {
    exit 1
}

if ($mode -eq "dry-run") {
    exit 0
}

if ($apply) {
    if (-not $godotFound) {
        throw ("Godot not found: {0}" -f $godotResolved)
    }

    if ($outputDirPath) {
        $null = New-Item -ItemType Directory -Force -Path $outputDirPath
    }

    & $godotResolved --headless --path $projectRoot --export-release $presetName $outputRelative
    if ($LASTEXITCODE -ne 0) {
        throw ("Godot export failed with exit code {0}" -f $LASTEXITCODE)
    }

    if (-not (Test-Path $outputPath)) {
        throw ("Export output missing: {0}" -f $outputRelative)
    }
    if (-not $embedPck -and -not (Test-Path $pckPath)) {
        throw ("Export output missing: {0}" -f $pckRelative)
    }

    Write-Output ("Exported: {0}" -f $outputRelative)
}

if ($package) {
    if (-not (Test-Path $outputPath)) {
        throw ("Export output missing: {0}" -f $outputRelative)
    }
    if (-not $embedPck -and -not (Test-Path $pckPath)) {
        throw ("Export output missing: {0}" -f $pckRelative)
    }

    $manifestOutputs = @($outputName)
    if (-not $embedPck -and $pckName) {
        $manifestOutputs += $pckName
    }
    $manifestOutputs = $manifestOutputs | Sort-Object
    $manifestJson = New-ExportManifestJson -preset $presetName -productNameValue $productName -productVersionValue $productVersion -embedValue $embedPck -outputs $manifestOutputs
    $manifestDir = Split-Path -Parent $manifestPath
    if ($manifestDir) {
        $null = New-Item -ItemType Directory -Force -Path $manifestDir
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($manifestPath, $manifestJson, $utf8NoBom)

    $zipDir = Split-Path -Parent $zipSelectedPath
    if ($zipDir) {
        $null = New-Item -ItemType Directory -Force -Path $zipDir
    }
    Push-Location $outputDirPath
    try {
        if (Test-Path $zipFileName) {
            Remove-Item -Force $zipFileName
        }
        Compress-Archive -Force -Path $zipInputsRoot -DestinationPath $zipFileName
    } finally {
        Pop-Location
    }

    Write-Output ("Packaged: {0}" -f $zipSelectedRelative)
}
