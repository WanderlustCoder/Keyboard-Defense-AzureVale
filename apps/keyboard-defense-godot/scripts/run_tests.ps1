param(
  [string]$GodotPath = $env:GODOT_PATH
)

if (-not $GodotPath) {
  $cmd = Get-Command godot -ErrorAction SilentlyContinue
  if ($cmd) {
    $GodotPath = $cmd.Path
  }
}

if (-not $GodotPath) {
  $cmd = Get-Command godot4 -ErrorAction SilentlyContinue
  if ($cmd) {
    $GodotPath = $cmd.Path
  }
}

if (-not $GodotPath) {
  Write-Error "Godot 4 not found. Set GODOT_PATH or add godot to PATH."
  exit 1
}

$projectRoot = Split-Path -Parent $PSScriptRoot
& $GodotPath --headless --path $projectRoot --script res://scripts/tests/run_tests.gd
exit $LASTEXITCODE
