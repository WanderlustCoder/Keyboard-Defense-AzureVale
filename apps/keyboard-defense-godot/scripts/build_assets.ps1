# PowerShell script to convert SVG assets to PNG
# Requires: Inkscape installed and in PATH

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$SrcDir = Join-Path $ProjectDir "assets\art\src-svg"
$OutDir = Join-Path $ProjectDir "assets"

Write-Host "Building assets from SVG sources..."
Write-Host "Source: $SrcDir"
Write-Host "Output: $OutDir"

# Check for Inkscape
$inkscape = Get-Command inkscape -ErrorAction SilentlyContinue
if (-not $inkscape) {
    Write-Error "Error: Inkscape not found. Please install Inkscape and add it to PATH."
    exit 1
}

Write-Host "Using Inkscape for conversion"

# Create output directories
New-Item -ItemType Directory -Force -Path "$OutDir\icons" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutDir\tiles" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutDir\sprites" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutDir\ui" | Out-Null

function Convert-Svg {
    param (
        [string]$Source,
        [string]$Destination
    )

    & inkscape --export-filename="$Destination" "$Source" 2>$null
    Write-Host "  Converted: $(Split-Path -Leaf $Destination)"
}

# Convert icons
Write-Host ""
Write-Host "Converting icons..."
Get-ChildItem "$SrcDir\icons\*.svg" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    Convert-Svg -Source $_.FullName -Destination "$OutDir\icons\$name.png"
}

# Convert tiles
Write-Host ""
Write-Host "Converting tiles..."
Get-ChildItem "$SrcDir\tiles\*.svg" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    Convert-Svg -Source $_.FullName -Destination "$OutDir\tiles\$name.png"
}

# Convert sprites
Write-Host ""
Write-Host "Converting sprites..."
Get-ChildItem "$SrcDir\sprites\*.svg" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    Convert-Svg -Source $_.FullName -Destination "$OutDir\sprites\$name.png"
}

# Convert UI elements
Write-Host ""
Write-Host "Converting UI elements..."
Get-ChildItem "$SrcDir\ui\*.svg" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    Convert-Svg -Source $_.FullName -Destination "$OutDir\ui\$name.png"
}

Write-Host ""
Write-Host "Asset build complete!"
Write-Host ""

# Count assets
$iconCount = (Get-ChildItem "$OutDir\icons\*.png" -ErrorAction SilentlyContinue | Measure-Object).Count
$tileCount = (Get-ChildItem "$OutDir\tiles\*.png" -ErrorAction SilentlyContinue | Measure-Object).Count
$spriteCount = (Get-ChildItem "$OutDir\sprites\*.png" -ErrorAction SilentlyContinue | Measure-Object).Count
$uiCount = (Get-ChildItem "$OutDir\ui\*.png" -ErrorAction SilentlyContinue | Measure-Object).Count

Write-Host "Summary:"
Write-Host "  Icons:   $iconCount"
Write-Host "  Tiles:   $tileCount"
Write-Host "  Sprites: $spriteCount"
Write-Host "  UI:      $uiCount"
Write-Host "  Total:   $($iconCount + $tileCount + $spriteCount + $uiCount)"
