# Schema validation wrapper script (PowerShell)
# Usage: .\scripts\validate.ps1 [options] [files...]
#
# Options:
#   --quick    Only validate files with schemas (faster)
#
# Examples:
#   .\scripts\validate.ps1              # Validate all data files
#   .\scripts\validate.ps1 --quick      # Only schema-validated files
#   .\scripts\validate.ps1 lessons map  # Validate specific files

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Push-Location $ProjectDir
try {
    python scripts/validate_schemas.py @args
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

exit $exitCode
