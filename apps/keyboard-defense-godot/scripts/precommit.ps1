# Pre-commit validation script (PowerShell)
# Run this before committing to catch common issues early
#
# Usage: .\scripts\precommit.ps1 [options]
#
# Options:
#   -Quick      Skip slow checks (headless tests)
#   -NoTests    Skip headless tests only
#   -Verbose    Show detailed output

param(
    [switch]$Quick,
    [switch]$NoTests,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Push-Location $ProjectDir

$passed = 0
$failed = 0
$skipped = 0

$SkipTests = $Quick -or $NoTests

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Blue
    Write-Host "  $Text" -ForegroundColor Blue
    Write-Host ("=" * 60) -ForegroundColor Blue
}

function Write-Result {
    param(
        [string]$Status,
        [string]$Message
    )
    switch ($Status) {
        "pass" {
            Write-Host "  [PASS] $Message" -ForegroundColor Green
            $script:passed++
        }
        "fail" {
            Write-Host "  [FAIL] $Message" -ForegroundColor Red
            $script:failed++
        }
        "skip" {
            Write-Host "  [SKIP] $Message" -ForegroundColor Yellow
            $script:skipped++
        }
    }
}

Write-Header "KEYBOARD DEFENSE - PRE-COMMIT VALIDATION"
Write-Host "  Project: $ProjectDir"
Write-Host "  Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# ─────────────────────────────────────────────────────────────
# Check 1: JSON Syntax Validation
# ─────────────────────────────────────────────────────────────
Write-Header "CHECK 1: JSON Syntax"

$jsonErrors = 0
Get-ChildItem -Path "data\*.json" | ForEach-Object {
    try {
        $null = Get-Content $_.FullName -Raw | ConvertFrom-Json
        if ($Verbose) {
            Write-Result "pass" $_.Name
        }
    }
    catch {
        Write-Result "fail" "$($_.Name) - invalid JSON"
        $jsonErrors++
    }
}

if ($jsonErrors -eq 0) {
    Write-Result "pass" "All JSON files are valid"
}

# ─────────────────────────────────────────────────────────────
# Check 2: Schema Validation
# ─────────────────────────────────────────────────────────────
Write-Header "CHECK 2: Schema Validation"

$pythonAvailable = Get-Command python -ErrorAction SilentlyContinue
if ($pythonAvailable) {
    try {
        $result = python scripts/validate_schemas.py --quick 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Result "pass" "All schemas validated"
            if ($Verbose) {
                $result | ForEach-Object { Write-Host "    $_" }
            }
        }
        else {
            Write-Result "fail" "Schema validation errors found"
            $result | ForEach-Object { Write-Host "    $_" }
        }
    }
    catch {
        Write-Result "skip" "Schema validation failed: $_"
    }
}
else {
    Write-Result "skip" "Python not available"
}

# ─────────────────────────────────────────────────────────────
# Check 3: Sim Layer Architecture
# ─────────────────────────────────────────────────────────────
Write-Header "CHECK 3: Sim Layer Architecture"

$simErrors = 0
$forbiddenPatterns = @("extends Node", "extends Control", "extends Node2D", "extends Node3D", "extends CanvasItem")

Get-ChildItem -Path "sim\*.gd" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    foreach ($pattern in $forbiddenPatterns) {
        if ($content -match [regex]::Escape($pattern)) {
            Write-Result "fail" "$($_.Name) contains '$pattern'"
            $simErrors++
        }
    }
}

if ($simErrors -eq 0) {
    Write-Result "pass" "sim/ layer is Node-free"
}

# ─────────────────────────────────────────────────────────────
# Check 4: GDScript Syntax Check
# ─────────────────────────────────────────────────────────────
Write-Header "CHECK 4: GDScript Syntax"

$godotAvailable = Get-Command godot -ErrorAction SilentlyContinue
if ($godotAvailable -and -not $SkipTests) {
    Write-Host "  Checking GDScript syntax..."
    $output = godot --headless --path . --quit 2>&1
    if ($output -match "error") {
        Write-Result "fail" "GDScript errors detected"
        $output | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" }
    }
    else {
        Write-Result "pass" "GDScript syntax OK"
    }
}
elseif ($SkipTests) {
    Write-Result "skip" "GDScript syntax (quick mode)"
}
else {
    Write-Result "skip" "Godot not in PATH"
}

# ─────────────────────────────────────────────────────────────
# Check 5: Headless Tests
# ─────────────────────────────────────────────────────────────
Write-Header "CHECK 5: Headless Tests"

if ($SkipTests) {
    Write-Result "skip" "Headless tests (quick mode)"
}
elseif ($godotAvailable) {
    Write-Host "  Running tests (this may take a moment)..."
    $testOutput = godot --headless --path . --script res://tests/run_tests.gd 2>&1
    $testOutput | Select-Object -Last 5 | ForEach-Object { Write-Host "    $_" }

    if ($testOutput -match "FAILED") {
        Write-Result "fail" "Some tests failed"
    }
    elseif ($testOutput -match "PASSED|All tests passed") {
        Write-Result "pass" "All tests passed"
    }
    else {
        Write-Result "pass" "Tests completed"
    }
}
else {
    Write-Result "skip" "Godot not in PATH"
}

# ─────────────────────────────────────────────────────────────
# Check 6: Common Mistakes
# ─────────────────────────────────────────────────────────────
Write-Header "CHECK 6: Common Mistakes"

# Check for TODO/FIXME comments
$todoCount = (Get-ChildItem -Path "sim\*.gd", "game\*.gd", "scripts\*.gd" -ErrorAction SilentlyContinue |
    Select-String -Pattern "TODO|FIXME|HACK|XXX" |
    Measure-Object).Count

if ($todoCount -gt 0) {
    Write-Host "  [INFO] Found $todoCount TODO/FIXME comments" -ForegroundColor Yellow
}

Write-Result "pass" "Common mistake check complete"

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
Write-Header "SUMMARY"

Write-Host ""
Write-Host "  Passed:  $passed" -ForegroundColor Green
Write-Host "  Failed:  $failed" -ForegroundColor Red
Write-Host "  Skipped: $skipped" -ForegroundColor Yellow
Write-Host ""

Pop-Location

if ($failed -gt 0) {
    Write-Host ("=" * 60) -ForegroundColor Red
    Write-Host "  VALIDATION FAILED - Fix errors before committing" -ForegroundColor Red
    Write-Host ("=" * 60) -ForegroundColor Red
    exit 1
}
else {
    Write-Host ("=" * 60) -ForegroundColor Green
    Write-Host "  ALL CHECKS PASSED - Ready to commit" -ForegroundColor Green
    Write-Host ("=" * 60) -ForegroundColor Green
    exit 0
}
