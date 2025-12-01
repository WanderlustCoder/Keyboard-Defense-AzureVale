# Analytics Snapshot & Export Schema

This reference captures the structure of the JSON snapshots downloaded from the in-game analytics exporter as well as the CSV emitted by `npm run analytics:aggregate`. Use it to build dashboards or to validate downstream tooling when snapshot formats evolve. The canonical JSON Schema lives at `apps/keyboard-defense/schemas/analytics.schema.json`; validate snapshots locally or in CI via `npm run analytics:validate-schema` (which runs `node scripts/analytics/validate-schema.mjs <files>` under the hood).

## Root Snapshot Fields

| Field | Type | Description |
| --- | --- | --- |
| `capturedAt` | string (ISO date) | Timestamp when the snapshot was generated. |
| `exportVersion` | number | Schema version for the analytics export payload (currently `2`). |
| `time` | number | Elapsed game time in seconds when captured. |
| `status` | `"preparing" \| "running" \| "victory" \| "defeat"` | Current game loop status. |
| `wave.index` | number | Zero-based wave index active when captured. |
| `wave.total` | number | Total wave count in the episode. |
| `settings.soundEnabled` | boolean | Whether the master audio channel was enabled when the snapshot was captured. |
| `settings.soundVolume` | number (0-1) | Master audio volume slider position (0 = muted, 1 = full). |
| `settings.soundIntensity` | number (0.5-1.5) | Audio intensity multiplier applied to individual cues (0.5 = minimum energy, 1.5 = maximum). |
| `typing.accuracy` | number (0-1) | Session accuracy up to the snapshot time. |
| `resources.gold` | number | Current gold balance. |
| `timeToFirstTurret` | number or null | Seconds elapsed before the first turret was placed (null if no turret yet). |
| `turretStats` | `TurretRuntimeStat[]` | Array summarising per-slot turret damage/DPS at capture time (may be empty when no turrets). |
| `analytics.sessionBreaches` | number | Total breaches sustained for the run. |
| `analytics.sessionBestCombo` | number | Highest combo reached in-session. |
| `analytics.totalDamageDealt` | number | Sum of turret + typing damage across the session. |
| `analytics.totalTurretDamage` | number | Damage dealt by turrets across the session. |
| `analytics.totalTypingDamage` | number | Damage dealt by typing across the session. |
| `analytics.totalShieldBreaks` | number | Total shield break events this session. |
| `analytics.totalCastleRepairs` | number | Count of castle repairs triggered this session. |
| `analytics.totalRepairHealth` | number | Hit points restored across all repairs. |
| `analytics.totalRepairGold` | number | Gold spent on castle repairs. |
| `analytics.totalPerfectWords` | number | Count of enemies defeated without typing mistakes across the session. |
| `analytics.totalBonusGold` | number | Bonus gold awarded from wave objectives so far. |
| `analytics.totalCastleBonusGold` | number | Additional gold earned from castle passive bonuses across the session. |
| `analytics.totalReactionTime` | number | Sum of reaction times (seconds) captured for first-hit typing samples. |
| `analytics.reactionSamples` | number | Count of reaction-time samples contributing to the totals. |
| `analytics.averageTotalDps` | number | Session-long average combined DPS (turrets + typing). |
| `analytics.averageTurretDps` | number | Session-long average turret DPS. |
| `analytics.averageTypingDps` | number | Session-long average typing DPS. |
| `analytics.castlePassiveUnlocks` | array | Chronological list of passive buffs unlocked `{ id, total, delta, level, time }`. |
| `analytics.goldEvents` | array | Chronological gold events `{ gold, delta, timestamp }` (capped at 200 entries). |
| `analytics.taunt` | object | Snapshot of the most recent taunt plus aggregate metadata (see **Taunt Metadata** below). |
| `analytics.waveSummaries` | `WaveSummary[]` | Rolling array of recent wave summaries (latest appended). |
| `analytics.waveHistory` | `WaveSummary[]` | Full session wave history (capped at 100 entries) retained for in-session review. |
| `analytics.comboWarning` | object | Combo warning accuracy delta analytics (see **Combo Warning Analytics** below). |
| `analytics.audioIntensityHistory` | array | Chronological list of audio intensity adjustments `{ timestampMs, gameTime, waveIndex, combo, accuracy, from, to, source }` for telemetry/correlation. |
| `analytics.typingDrills` | array | Recorded typing drill summaries from the drills overlay (see **Typing Drill Analytics** below). |
| `analytics.wavePerfectWords` | number | Perfect words recorded so far in the active wave. |
| `analytics.waveBonusGold` | number | Bonus gold earned in the active wave prior to finalisation. |
| `telemetry` | object | Telemetry opt-in metadata captured alongside the snapshot (see table below). |

> Need a flattened unlock timeline for dashboards? Run `npm run analytics:passives` (new CLI) to emit the `analytics.castlePassiveUnlocks` array as JSON or CSV. For CI/automation that already runs `analyticsAggregate`, pass `--passive-summary <json> [--passive-summary-csv <csv>] [--passive-summary-md <md>]` so the aggregation step also writes passive unlock artifacts alongside the main CSV.

> The CSV emitted by `analyticsAggregate.mjs` retains these fields as columns: `sessionBreaches`, `sessionBestCombo`, `totalDamageDealt`, `totalTurretDamage`, `totalTypingDamage`, `totalShieldBreaks`, `totalCastleRepairs`, `totalRepairHealth`, `totalRepairGold`, `totalPerfectWords`, `totalBonusGold`, `totalCastleBonusGold`, `totalReactionTime`, `reactionSamples`, `averageTotalDps`, `averageTurretDps`, `averageTypingDps`, per-wave `perfectWords`, `averageReaction`, `bonusGold`, `castleBonusGold`, the serialized `turretStats` column, plus the combo warning analytics (`comboWarningCount`, `comboWarningDeltaLast`, `comboWarningDeltaAvg`, `comboWarningDeltaMin`, `comboWarningDeltaMax`, `comboWarningHistory`) and audio telemetry columns (`audioIntensitySamples`, `audioIntensityAvg`, `audioIntensityDelta`, `audioIntensityComboCorrelation`, `audioIntensityAccuracyCorrelation`).
> Typing drills are exported too: `typingDrillCount`, `typingDrillLastMode`, `typingDrillLastSource`, `typingDrillLastAccuracyPct`, `typingDrillLastWpm`, `typingDrillLastBestCombo`, `typingDrillLastWords`, `typingDrillLastErrors`, `typingDrillLastTimestamp`, and a compact `typingDrillHistory` string.

### Combo Warning Analytics

| Field | Type | Description |
| --- | --- | --- |
| `comboWarning.count` | number | Total number of combo warnings recorded this session. |
| `comboWarning.lastDelta` | number | Most recent accuracy delta (percent) captured when a warning triggered. |
| `comboWarning.deltaMin` | number | Worst (lowest) delta percent recorded this session. |
| `comboWarning.deltaMax` | number | Highest delta percent recorded (closest to zero or positive) this session. |
| `comboWarning.deltaSum` | number | Sum of all delta percents; divide by `count` for the average value used by dashboards/CI. |
| `comboWarning.baselineAccuracy` | number | Current 0-1 baseline accuracy used to compute the next warning delta. |
| `comboWarning.history` | array | Rolling buffer of warning entries `{ timestamp, waveIndex, comboBefore, comboAfter, accuracy, baselineAccuracy, deltaPercent, durationMs }` (capped so snapshots remain small). |

Each warning also emits a telemetry envelope named `combat.comboWarningDelta` containing `{ comboBefore, comboAfter, deltaPercent, durationMs, timeSinceLastWarningMs }` so CI and dashboards can flag accuracy swings without parsing the raw snapshots.

### Typing Drill Analytics

When players run the typing drills overlay, each finished drill is appended to `analytics.typingDrills`.

| Field | Type | Description |
| --- | --- | --- |
| `typingDrills[].mode` | `"burst" \| "endurance" \| "precision"` | Drill variant that ran. |
| `typingDrills[].source` | string | Where the drill launched from (`menu`, `options`, `cta`, `practice`, `debug`, or custom). |
| `typingDrills[].elapsedMs` | number | Duration of the drill in milliseconds. |
| `typingDrills[].accuracy` | number (0-1) | Accuracy achieved during the drill. |
| `typingDrills[].bestCombo` | number | Highest combo reached during the drill. |
| `typingDrills[].words` | number | Words cleared during the drill. |
| `typingDrills[].errors` | number | Total errors recorded during the drill. |
| `typingDrills[].wpm` | number | Gross WPM approximation (based on correct characters / 5 per minute). |
| `typingDrills[].timestamp` | number | Epoch milliseconds when the drill finished. |

CSV columns flatten the latest drill and a compact history: `typingDrillCount`, `typingDrillLastMode`, `typingDrillLastSource`, `typingDrillLastAccuracyPct`, `typingDrillLastWpm`, `typingDrillLastBestCombo`, `typingDrillLastWords`, `typingDrillLastErrors`, `typingDrillLastTimestamp`, `typingDrillHistory`.

### Typing Drill Telemetry

- `typing-drill.started`: `{ mode, source, timestamp, telemetryEnabled, menu, optionsOverlay, waveScorecard }`
- `typing-drill.completed`: `{ mode, source, elapsedMs, accuracy, bestCombo, words, errors, wpm, timestamp, telemetryEnabled }`
- `ui.typingDrill.menuQuickstart`: `{ mode, hadRecommendation, reason, timestamp }` (fires from the main-menu quickstart CTA and falls back to Burst Warmup when no recommendation is available)

## Taunt Metadata

When enemies spawn with scripted taunts the analytics payload captures the most recent line plus lightweight aggregates so dashboards/snapshots can highlight the context without replaying the session.

| Field | Type | Description |
| --- | --- | --- |
| `analytics.taunt.active` | boolean | `true` immediately after a taunt fires; `false` after the first snapshot when no taunts have triggered yet. |
| `analytics.taunt.text` | string \| null | Text of the latest taunt (localised string once localization lands). |
| `analytics.taunt.enemyType` | string \| null | Enemy tier id that triggered the taunt (e.g., `brute`, `witch`, boss ids). |
| `analytics.taunt.waveIndex` | number \| null | Wave index associated with the taunt event. |
| `analytics.taunt.lane` | number \| null | Lane where the taunting enemy spawned (0-indexed). |
| `analytics.taunt.timestampMs` | number \| null | Session time in seconds when the taunt triggered. |
| `analytics.taunt.id` | string \| null | Stable identifier for the taunt (falls back to the enemy id or text when no catalog id exists). |
| `analytics.taunt.countPerWave` | object | Map of `waveIndex -> count` showing how many taunts fired per wave in the session. |
| `analytics.taunt.uniqueLines` | string[] | Ordered list of unique taunt strings encountered this session. |
| `analytics.taunt.history` | `TauntAnalyticsEntry[]` | Rolling list (last 25) of taunt events `{ id, text, enemyType, lane, waveIndex, timestamp }`. |

The CSV emitted by `analyticsAggregate.mjs` adds the following columns to surface the same info without parsing nested JSON: `tauntActive`, `tauntText`, `tauntEnemyType`, `tauntWaveIndex`, `tauntLane`, `tauntTimestamp`, `tauntId`, `tauntCountPerWave`, `tauntUniqueLines`.

## Defeat Burst Metrics

Defeat bursts capture the defeat-animation activity per session so diagnostics, smoke artifacts, and CI summaries can ensure the effects keep firing (and track sprite vs procedural usage).

| Field | Type | Description |
| --- | --- | --- |
| `analytics.defeatBurst.total` | number | Total bursts fired this session. |
| `analytics.defeatBurst.sprite` | number | Count of bursts rendered via sprite atlases. |
| `analytics.defeatBurst.procedural` | number | Count of procedural fallback bursts. |
| `analytics.defeatBurst.lastEnemyType` | string \| null | Tier id of the last enemy that triggered a burst. |
| `analytics.defeatBurst.lastLane` | number \| null | Lane index of the last burst. |
| `analytics.defeatBurst.lastTimestamp` | number \| null | Session time (seconds) when the last burst started. |
| `analytics.defeatBurst.lastMode` | `"sprite"` \| `"procedural"` \| null | Rendering mode used for the last burst. |
| `analytics.defeatBurst.history` | array | Rolling list of events `{ enemyType, lane, timestamp, mode }` used by dashboards and diagnostics. |
| `analytics.starfield` | object \| null | Snapshot of the current starfield parallax state (depth, drift, tint, wave progress, castle health ratio, severity, reduced-motion flag, and layer velocities/depths). |
| `analytics.starfield.depth` | number | Depth multiplier applied to the starfield layers. |
| `analytics.starfield.driftMultiplier` | number | Current multiplier applied to per-layer velocities. |
| `analytics.starfield.tint` | string | Hex color tint currently applied based on castle damage. |
| `analytics.starfield.waveProgress` | number | Normalized wave progress (0-1) used by the parallax controller. |
| `analytics.starfield.castleHealthRatio` | number | Current castle health ratio (0-1). |
| `analytics.starfield.severity` | number | Normalized (0-1) castle damage severity derived from health ratio. |
| `analytics.starfield.reducedMotionApplied` | boolean | Whether parallax was frozen/clamped due to reduced-motion settings. |
| `analytics.starfield.layers` | array | Layer diagnostics `{ id, velocity, direction, depth, baseDepth, depthOffset }`. |

CSV columns: `defeatBurstCount`, `defeatBurstSpriteCount`, `defeatBurstProceduralCount`, `defeatBurstPerMinute`, `defeatBurstSpritePct`, `defeatBurstLastEnemyType`, `defeatBurstLastLane`, `defeatBurstLastMode`, `defeatBurstLastTimestamp`, `defeatBurstHistory`, `starfieldDepth`, `starfieldDrift`, `starfieldTint`, `starfieldWaveProgress`, `starfieldCastleRatio`, `starfieldSeverity`, `starfieldReducedMotionApplied`, `starfieldLayers`.

## UI Snapshot Fields

The `ui` object travels alongside each analytics export to describe how the HUD rendered when the snapshot was taken. This keeps automation artifacts honest without scraping DOM state.

| Field | Type | Description |
| --- | --- | --- |
| `ui.compactHeight` | boolean \| null | Mirrors `document.body.dataset.compactHeight` to indicate the tutorial banner compact-height heuristic triggered. |
| `ui.tutorialBanner.condensed` | boolean | Whether the tutorial banner is currently in condensed mode (viewport <540px tall). |
| `ui.tutorialBanner.expanded` | boolean | Whether the condensed tutorial banner is expanded (player toggled it open). |
| `ui.hud.passivesCollapsed` | boolean \| null | Current collapse state of the HUD castle passives card (`null` when unavailable). |
| `ui.hud.goldEventsCollapsed` | boolean \| null | Current collapse state of the HUD recent gold events card. |
| `ui.hud.prefersCondensedLists` | boolean \| null | Result of the viewport heuristic that drives the default collapse state (true on mobile viewports). |
| `ui.hud.layout` | `"stacked"` \| `"condensed"` \| null | Resolved HUD layout badge (mirrors the heuristic controlled collapse state). |
| `ui.options.passivesCollapsed` | boolean \| null | Collapse state of the pause/options overlay passives section. |
| `ui.diagnostics.condensed` | boolean \| null | Whether the diagnostics overlay flipped into its condensed mode (short viewports). |
| `ui.diagnostics.sectionsCollapsed` | boolean \| null | Whether the condensed diagnostics overlay has its verbose sections collapsed behind the toggle button. |
| `ui.diagnostics.collapsedSections` | object \| null | Per-section collapsed state (e.g., `{ "gold-events": true }`), allowing dashboards to render badges for individual cards. |
| `ui.diagnostics.lastUpdatedAt` | string \| null | ISO timestamp when diagnostics section preferences last changed (mirrors player settings metadata). |
| `ui.preferences.hudPassivesCollapsed` | boolean \| null | Player preference for the HUD passives card collapse state (persisted in player settings). |
| `ui.preferences.hudGoldEventsCollapsed` | boolean \| null | Player preference for the HUD gold events card collapse state. |
| `ui.preferences.optionsPassivesCollapsed` | boolean \| null | Player preference for the options overlay passives card. |
| `ui.preferences.diagnosticsSections` | object \| null | Persisted diagnostics section collapse map (matches `ui.diagnostics.collapsedSections`). |
| `ui.preferences.diagnosticsSectionsUpdatedAt` | string \| null | ISO timestamp when diagnostics section preferences were last persisted. |
| `ui.preferences.devicePixelRatio` | number \| null | Persisted devicePixelRatio sample (rounded to two decimals) from player settings. |
| `ui.preferences.hudLayout` | `"stacked"` \| `"condensed"` \| null | Persisted HUD layout preference captured from the last known responsive state. |
| `ui.resolution.cssWidth` | number \| null | Latest CSS width applied to the canvas (null until the canvas is measured). |
| `ui.resolution.cssHeight` | number \| null | CSS height computed from the base aspect ratio. |
| `ui.resolution.renderWidth` | number \| null | Internal renderer width after DPR scaling. |
| `ui.resolution.renderHeight` | number \| null | Internal renderer height after DPR scaling. |
| `ui.resolution.devicePixelRatio` | number \| null | Most recent DPR sample (rounded to two decimals). |
| `ui.resolution.hudLayout` | `"stacked"` \| `"condensed"` \| null | HUD layout sampled at the time the resolution snapshot was captured. |
| `ui.resolution.lastResizeCause` | string \| null | Last recorded resize cause from the renderer (`viewport`, `device-pixel-ratio`, etc.). |
| `ui.resolutionChanges[]` | object[] | Rolling list (max 10) describing each resolution transition captured during the session. |
| `ui.resolutionChanges[].capturedAt` | string | ISO timestamp recorded when the transition completed. |
| `ui.resolutionChanges[].cause` | string \| null | Source of the transition (`initial`, `resize-observer`, `viewport`, `device-pixel-ratio`, etc.). |
| `ui.resolutionChanges[].fromDpr` / `toDpr` | number \| null | DPR values before/after the transition (identical when only the viewport width changed). |
| `ui.resolutionChanges[].cssWidth` / `cssHeight` | number | CSS dimensions applied after the transition. |
| `ui.resolutionChanges[].renderWidth` / `renderHeight` | number | Renderer dimensions applied after the transition. |
| `ui.resolutionChanges[].transitionMs` | number \| null | Duration of the fade/hold animation applied to mask the resize. |
| `ui.resolutionChanges[].prefersCondensedHud` | boolean \| null | HUD condensed preference sampled at the time of the transition. |
| `ui.resolutionChanges[].hudLayout` | `"stacked"` \| `"condensed"` \| null | Derived HUD layout badge used by dashboards and telemetry. |

> Use `npm run debug:dpr-transition -- --steps 1:960:init,1.5:840:pinch,2:720:zoom --json` to regenerate the DPR transition payloads without relying on browser zooming; the CLI emits the same entries recorded under `ui.resolutionChanges[]`.

## Wave Summary Fields

Each entry in `waveSummaries`/`waveHistory` (and the per-row CSV output) exposes:

| Field | Type | Description |
| --- | --- | --- |
| `index` | number | Zero-based wave index summarised. |
| `duration` | number | Seconds the wave lasted. |
| `accuracy` | number (0-1) | Accuracy recorded during the wave. |
| `enemiesDefeated` | number | Count of enemies defeated in the wave. |
| `breaches` | number | Breaches during the wave. |
| `perfectWords` | number | Perfect-typed enemies (no errors) during the wave. |
| `averageReaction` | number | Average time (seconds) between enemy spawn and the first correct key press. |
| `dps` | number | Combined damage-per-second (typing + turrets). |
| `turretDps` | number | Turret damage-per-second. |
| `typingDps` | number | Typing damage-per-second. |
| `turretDamage` | number | Total turret damage in the wave. |
| `typingDamage` | number | Total typing damage in the wave. |
| `shieldBreaks` | number | Shield break events in the wave. |
| `repairsUsed` | number | Castle repairs triggered during the wave. |
| `repairHealth` | number | Hit points restored by repairs during the wave. |
| `repairGold` | number | Gold spent on repairs during the wave. |
| `bonusGold` | number | Bonus gold granted by wave objectives (e.g., perfect word streaks). |
| `castleBonusGold` | number | Additional gold granted by the castle's passive gold bonus during the wave. |
| `goldEarned` | number | Net gold earned during the wave. |
| `maxCombo` | number | Highest combo achieved during the wave. |
| `sessionBestCombo` | number | Session best when the wave concluded (for reference). |

## Tutorial Analytics (when present)

Tutorial runs populate `analytics.tutorial`:

| Field | Type | Description |
| --- | --- | --- |
| `events` | array | Step-by-step telemetry events `{ stepId, event, atTime, timeInStep }`. |
| `attemptedRuns` | number | Count of tutorial starts recorded in the session. |
| `assistsShown` | number | Assist tip count shown to the player. |
| `completedRuns` | number | Tutorial completions recorded in the session. |
| `replayedRuns` | number | Optional replays triggered by the player. |
| `skippedRuns` | number | Tutorial skips detected. |
| `lastSummary` | object \| null | Final tutorial stats (accuracy, combo, breaches, gold, replayed). |

## Gold Event Fields

Each entry in `analytics.goldEvents` captures a single gold balance update:

| Field | Type | Description |
| --- | --- | --- |
| `gold` | number | Player gold total immediately after the event. |
| `delta` | number | Net gold change applied by the event (negative for spend). |
| `timestamp` | number | Game time in seconds when the event occurred. |

> Need a quick timeline for dashboards or smoke artifacts? Run `npm run analytics:gold` (see `scripts/goldTimeline.mjs`) to export the last few hundred entries as JSON/CSV with additional metadata (file, mode, capturedAt, time-since). Pass `--merge-passives --passive-window <seconds>` to include the nearest passive unlock (id/level/time/lag) for each event. For high-level summaries (net delta, max gain/spend, configurable gain/spend percentiles, passive linkage counts) use `npm run analytics:gold:summary` (add `--percentiles 25,50,90` to control which percentile cutlines appear; defaults to `50,90`). The summary output always appends `gainP<percent>` / `spendP<percent>` columns (e.g., `gainP50`, `spendP90`) along with the legacy `medianGain`/`p90Gain` aliases for backward compatibility, and CI smoke/report workflows pass `--percentiles 25,50,90` by default so artifacts line up with dashboards. JSON output includes a wrapper `{ percentiles: number[], rows: SummaryRow[] }` and CSV output includes a trailing `summaryPercentiles` column containing the pipe-delimited percentile list so downstream tools can assert the cutlines that generated the artifact. Want to gate ingestion? Run `npm run analytics:gold:check <path>` to validate that an artifact’s metadata matches the expected percentile list.\n\n> Starfield telemetry now flows through the gold summary pipeline: each summary row includes starfieldDepth, starfieldDrift, starfieldWaveProgress, starfieldCastleRatio, and starfieldTint. The CI dashboard step (scripts/ci/goldSummaryReport.mjs) aggregates those into metrics.starfield with average depth/drift/percentages plus the last recorded tint so reviewers can correlate castle damage tinting with economy swings directly from Markdown/JSON.

## Telemetry Metadata Snapshot

When telemetry is compiled with the export (regardless of opt-in state) the payload includes a `telemetry` object:

| Field | Type | Description |
| --- | --- | --- |
| `available` | boolean | `true` when the telemetry subsystem was enabled for the session. |
| `enabled` | boolean | Player opt-in state at the time of export. |
| `endpoint` | string \| null | Custom endpoint applied through the debug controls (if any). |
| `queueSize` | number | Count of telemetry envelopes currently buffered in the client. |
| `soundIntensity` | number | Latest audio intensity multiplier applied when the export was generated. |
| `queue` | `TelemetryEnvelope[]` | Shallow copies of the queued envelopes (capped by the client's queue size, default 50). |

Each `TelemetryEnvelope` mirrors the structure emitted by the in-game client: `{ type, capturedAt, payload, metadata }`.

## CSV Column Ordering (Quick Reference)

When you run `npm run analytics:aggregate`, the CSV header is emitted exactly as:

```
file,capturedAt,status,time,telemetryAvailable,telemetryEnabled,telemetryEndpoint,telemetryQueueSize,soundEnabled,soundVolume,soundIntensity,timeToFirstTurret,waveIndex,waveTotal,mode,practiceMode,turretStats,summaryWave,duration,accuracy,enemiesDefeated,breaches,perfectWords,averageReaction,dps,turretDps,typingDps,turretDamage,typingDamage,shieldBreaks,repairsUsed,repairHealth,repairGold,bonusGold,castleBonusGold,passiveUnlockCount,lastPassiveUnlock,castlePassiveUnlocks,goldEventsTracked,lastGoldDelta,lastGoldEventTime,tauntActive,tauntText,tauntEnemyType,tauntWaveIndex,tauntLane,tauntTimestamp,tauntId,tauntCountPerWave,tauntUniqueLines,goldEarned,maxCombo,sessionBestCombo,sessionBreaches,totalDamageDealt,totalTurretDamage,totalTypingDamage,totalShieldBreaks,totalCastleRepairs,totalRepairHealth,totalRepairGold,totalPerfectWords,totalBonusGold,totalCastleBonusGold,totalReactionTime,reactionSamples,averageTotalDps,averageTurretDps,averageTypingDps,tutorialAttempts,tutorialAssists,tutorialCompletions,tutorialReplays,tutorialSkips,audioIntensitySamples,audioIntensityAvg,audioIntensityDelta,audioIntensityComboCorrelation,audioIntensityAccuracyCorrelation
```

This header mirrors the tables above so automated parsers can rely on stable ordering. Any future schema changes should update this document and the README before landing.

## Validation CLI

- JSON Schema: `apps/keyboard-defense/schemas/analytics.schema.json`
- Command: `npm run analytics:validate-schema -- <files|directories>` (wrap extra targets after `--` to forward them through npm) or call `node scripts/analytics/validate-schema.mjs <targets>` directly.
- Flags:
  - `--mode warn` (or `info`) keeps the exit code at 0 even when failures occur; default `fail` blocks CI/commits.
  - `--report <path>` overrides the JSON artifact (`artifacts/summaries/analytics-validate.ci.json` by default).
  - `--report-md <path>` writes/overrides the Markdown summary (`artifacts/summaries/analytics-validate.ci.md` by default).
  - `--no-report` / `--no-md-report` skip writing the respective artifacts entirely.
- Outputs: both JSON + Markdown reports list per-file status, error counts, `gitSha`, schema path, and the invocation mode so CI dashboards can surface the triage data without inspecting logs.
- Dry-runs: point the CLI at `docs/codex_pack/fixtures/analytics` (valid + invalid fixtures) and at `artifacts/analytics/*.json` before shipping schema changes, e.g.
  ```
  node scripts/analytics/validate-schema.mjs docs/codex_pack/fixtures/analytics artifacts/analytics \
    --mode warn \
    --report temp/analytics-validate.local.json \
    --report-md temp/analytics-validate.local.md
  ```

## Leaderboard Export

`npm run analytics:leaderboard` consumes one or more snapshot files/directories and emits a leaderboard-ranked CSV (or `--json`) sorted by `sessionBestCombo`, `accuracy`, and `averageTotalDps`. Columns are:

```
rank,file,mode,status,timeSeconds,waveCount,accuracyPercent,sessionBestCombo,totalPerfectWords,totalBonusGold,totalCastleBonusGold,totalDamageDealt,averageTotalDps,averageTurretDps,averageTypingDps,averageReactionMs,sessionBreaches,totalCastleRepairs
```

The script accepts optional `--limit N` and `--json` flags. Only snapshots with parseable analytics payloads contribute to the ranking; rows are numbered after sorting so downstream tooling can display the top performers directly.
## Turret Runtime Stat Fields

Each entry in `turretStats` (and the serialised CSV column) contains:

| Field | Type | Description |
| --- | --- | --- |
| `slotId` | string | Turret slot identifier (`slot-1`, `slot-2`, ...). |
| `turretType` | string \\ null | Turret archetype occupying the slot (null if empty). |
| `level` | number \\ null | Current level of the turret (null if empty). |
| `damage` | number | Total damage dealt by the slot during the active wave. |
| `dps` | number | Per-second damage for the slot during the active wave (uses wave duration). |

