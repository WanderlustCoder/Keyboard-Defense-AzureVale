$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$projectRoot = Resolve-Path (Join-Path $repoRoot "apps\\keyboard-defense-godot")
$logPath = Join-Path $projectRoot "_scenarios_mid.log"
$reportsDir = Join-Path $projectRoot "Logs\\ScenarioReports"
$null = New-Item -ItemType Directory -Force -Path $reportsDir
$summaryPath = Join-Path $reportsDir "last_summary.txt"
$outDirArg = "Logs/ScenarioReports"
$godot = $env:GODOT_PATH
if (-not $godot) {
    $godot = "godot"
}
Push-Location $projectRoot
& $godot --headless --path . --script res://tools/run_scenarios.gd --log-file $logPath --tag p0 --tag balance --tag mid --enforce-targets --out-dir $outDirArg 2>&1 | Tee-Object -FilePath $logPath | Out-Null
if (Test-Path $summaryPath) {
    Get-Content $summaryPath
} else {
    $summaryLines = @()
    if (Test-Path $logPath) {
        $summaryLines = Get-Content $logPath -Tail 200 | Select-String "\[(scenarios|targets)\]" | ForEach-Object { $_.Line }
    }
    if ($summaryLines.Count -gt 0) {
        $summaryLines
    } elseif (Test-Path $logPath) {
        Get-Content $logPath -Tail 5 | ForEach-Object { $_ }
    }
}
Pop-Location
