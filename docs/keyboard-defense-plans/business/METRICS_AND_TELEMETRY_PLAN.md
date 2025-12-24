# Metrics and Telemetry Plan (Opt-In, Local-First)

## Philosophy
- The game must work fully offline.
- Metrics are primarily for **player feedback** and **balance tuning**.
- Telemetry is optional and must be explicitly enabled.

## Local Metrics (always allowed)
Store locally:
- per-run summary (day reached, loss cause)
- per-prompt stats (duration, errors, difficulty tag)
- settings snapshots

## Optional Telemetry (opt-in)
If enabled, upload **aggregates only**:
- histograms of WPM/accuracy buckets
- wave reached distribution
- command usage frequency (no raw text)
- failure reasons

## Data Minimization
Do not transmit:
- full prompt strings
- user-entered free text
- unique identifiers unless necessary (use random install id and allow reset)

## Schema Discipline
- All metrics must match a documented schema and be validated before save/upload.
- Any new field requires updating the data dictionary.

## Player Controls
- Toggle telemetry on/off at any time
- "Delete local data" option
- If uploads exist, provide "request deletion" mechanism



