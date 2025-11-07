# Analytics Snapshot & Export Schema

This reference captures the structure of the JSON snapshots downloaded from the in-game analytics exporter as well as the CSV emitted by `npm run analytics:aggregate`. Use it to build dashboards or to validate downstream tooling when snapshot formats evolve.

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
| `analytics.waveSummaries` | `WaveSummary[]` | Rolling array of recent wave summaries (latest appended). |
| `analytics.waveHistory` | `WaveSummary[]` | Full session wave history (capped at 100 entries) retained for in-session review. |
| `analytics.wavePerfectWords` | number | Perfect words recorded so far in the active wave. |
| `analytics.waveBonusGold` | number | Bonus gold earned in the active wave prior to finalisation. |
| `telemetry` | object | Telemetry opt-in metadata captured alongside the snapshot (see table below). |

> Need a flattened unlock timeline for dashboards? Run `npm run analytics:passives` (new CLI) to emit the `analytics.castlePassiveUnlocks` array as JSON or CSV.

> The CSV emitted by `analyticsAggregate.mjs` retains these fields as columns: `sessionBreaches`, `sessionBestCombo`, `totalDamageDealt`, `totalTurretDamage`, `totalTypingDamage`, `totalShieldBreaks`, `totalCastleRepairs`, `totalRepairHealth`, `totalRepairGold`, `totalPerfectWords`, `totalBonusGold`, `totalCastleBonusGold`, `totalReactionTime`, `reactionSamples`, `averageTotalDps`, `averageTurretDps`, `averageTypingDps`, along with per-wave `perfectWords`, `averageReaction`, `bonusGold`, `castleBonusGold`, and a serialised `turretStats` column summarising per-slot damage/DPS (`slotId:type Lx dmg=... dps=...`).

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

> Need a quick timeline for dashboards or smoke artifacts? Run `npm run analytics:gold` (see `scripts/goldTimeline.mjs`) to export the last few hundred entries as JSON/CSV with additional metadata (file, mode, capturedAt, time-since). Pass `--merge-passives --passive-window <seconds>` to include the nearest passive unlock (id/level/time/lag) for each event.

## Telemetry Metadata Snapshot

When telemetry is compiled with the export (regardless of opt-in state) the payload includes a `telemetry` object:

| Field | Type | Description |
| --- | --- | --- |
| `available` | boolean | `true` when the telemetry subsystem was enabled for the session. |
| `enabled` | boolean | Player opt-in state at the time of export. |
| `endpoint` | string \| null | Custom endpoint applied through the debug controls (if any). |
| `queueSize` | number | Count of telemetry envelopes currently buffered in the client. |
| `queue` | `TelemetryEnvelope[]` | Shallow copies of the queued envelopes (capped by the client's queue size, default 50). |

Each `TelemetryEnvelope` mirrors the structure emitted by the in-game client: `{ type, capturedAt, payload, metadata }`.

## CSV Column Ordering (Quick Reference)

When you run `npm run analytics:aggregate`, the CSV header is emitted exactly as:

```
file,capturedAt,status,time,telemetryAvailable,telemetryEnabled,telemetryEndpoint,telemetryQueueSize,soundEnabled,soundVolume,timeToFirstTurret,waveIndex,waveTotal,mode,practiceMode,turretStats,summaryWave,duration,accuracy,enemiesDefeated,breaches,perfectWords,averageReaction,dps,turretDps,typingDps,turretDamage,typingDamage,shieldBreaks,repairsUsed,repairHealth,repairGold,bonusGold,castleBonusGold,passiveUnlockCount,lastPassiveUnlock,castlePassiveUnlocks,goldEventsTracked,lastGoldDelta,lastGoldEventTime,goldEarned,maxCombo,sessionBestCombo,sessionBreaches,totalDamageDealt,totalTurretDamage,totalTypingDamage,totalShieldBreaks,totalCastleRepairs,totalRepairHealth,totalRepairGold,totalPerfectWords,totalBonusGold,totalCastleBonusGold,totalReactionTime,reactionSamples,averageTotalDps,averageTurretDps,averageTypingDps,tutorialAttempts,tutorialAssists,tutorialCompletions,tutorialReplays,tutorialSkips
```

This header mirrors the tables above so automated parsers can rely on stable ordering. Any future schema changes should update this document and the README before landing.

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
