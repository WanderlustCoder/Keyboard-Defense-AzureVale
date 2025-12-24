$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
$logPath = Join-Path $projectRoot "_test.log"
$summaryPath = Join-Path $projectRoot "_test_summary.log"
$userSummaryPath = Join-Path $env:APPDATA "Godot\\app_userdata\\Keyboard Defense\\_test_summary.log"
$godot = $env:GODOT_PATH
if (-not $godot) {
    $godot = "godot"
}

Push-Location $projectRoot
& $godot --headless --path . --script res://tests/run_tests.gd --log-file $logPath 2>&1 | Tee-Object -FilePath $logPath | Out-Null
$summaryLines = @()
if (Test-Path $logPath) {
    $summaryLines = Get-Content $logPath -Tail 200 | Select-String "\[tests\]" | ForEach-Object { $_.Line }
}
if ($summaryLines.Count -gt 0) {
    $summaryLines
} elseif (Test-Path $summaryPath) {
    Get-Content $summaryPath | ForEach-Object { $_ }
} elseif (Test-Path $userSummaryPath) {
    Get-Content $userSummaryPath | ForEach-Object { $_ }
}
Pop-Location
