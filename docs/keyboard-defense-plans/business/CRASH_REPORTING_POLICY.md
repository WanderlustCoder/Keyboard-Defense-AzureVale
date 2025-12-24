# Crash Reporting Policy

## Default Stance
- Prefer **local-first** crash logs.
- If remote crash reporting is used, make it **opt-in**.

## Minimum Requirements
- Crash log includes:
  - version
  - platform
  - stack trace
  - last 50 log lines
- Crash log must not include sensitive user data.

## Player UX
- On crash:
  - show a friendly dialog on next launch
  - offer "copy report to clipboard"
  - offer "open logs folder"
  - optional "send report" only if opt-in and network is available



