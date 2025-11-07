## HUD Castle Panel Condensed Lists

- Castle passives and recent gold events in the HUD now render inside collapsible summary cards with explicit counts, keeping the sidebar compact on tablets/phones while preserving one-click access to the full lists.
- Cards default to a collapsed state on screens ≤768px (desktop retains the previous always-expanded view), and the toggle buttons announce both the entry count and the latest gold delta so you can read economy drift without expanding.
- Passives/gold event lists no longer pop in/out abruptly—they hide behind the cards, which stabilizes layout shifts and makes HUD screenshots/tests deterministic again on narrow viewports.
- The pause/options overlay mirrors the same condensed card for castle passives, with summary counts plus a toggle so touch players can collapse the passive stack without losing at-a-glance context.

## Responsive HUD Layout

- HUD + canvas layout now reflows on viewports below 1024px: the canvas stacks above a grid-based HUD that auto-fits two columns on tablets and collapses to a single column on phones, preventing the sidebar from squishing or overflowing.
- Options, wave scorecard, and main-menu overlays adopt reduced padding with scrollable cards on small screens so modals remain usable on touch devices.
- Debug analytics tables gain horizontal scrolling guards when space is tight, and coarse-pointer media queries bump buttons, selects, and primary inputs (typing field, telemetry endpoint) to the 44px accessibility target.

## Audio Intensity Slider

- Added an Audio Intensity slider to the pause/options overlay so players can scale SFX energy between 50% and 150% without muting the game; the slider disables automatically when master audio is off and mirrors the live percent label.
- Intensities persist via the upgraded player settings schema (`version 11`), propagate through `HudView.syncOptionsOverlayState`, and drive a new `SoundManager.setIntensity` multiplier so every procedural cue respects the preference.
- Vitest HUD harness now covers the slider state/emit path, ensuring automation keeps watch over the comfort control and backlog #54 stays Done.

## Tooling Baseline Refresh

- Added `.eslintrc.cjs` so `npm run lint` once again has a project-level configuration (TypeScript files use the typed ruleset, automation scripts/tests stay on the lighter JS profile).
- Introduced `tsconfig.json` with `rootDirs` pointing at the shipped declaration files under `public/dist/src`, allowing `npm run build` / `tsc -p tsconfig.json` to pass without rehydrating the legacy source tree while still surfacing type errors inside the authored TypeScript.
- Dropped unused `simulateTyping` helper from the tutorial smoke orchestrator and normalized the `goldReport` path assertions so Windows/CI absolute paths no longer fail the test matrix.
- Prettier now requires an explicit `@format` pragma (`.prettierrc.json`) which keeps the historical code style intact while still letting contributors opt-in per file; `npm run format:check` now succeeds inside CI once the new config is present.

## Gold Summary CI Percentiles

- Tutorial smoke automation now calls `goldSummary.mjs --percentiles 25,50,90` so CI artifacts match the dashboard cutlines without any manual flags.
- `goldReport.mjs` forwards `--percentiles` (defaulting to `25,50,90`) to the summary CLI, keeping local investigations aligned with the automation defaults while still letting engineers override the list when necessary.

## Gold Summary Percentile Metadata

- `goldSummary.mjs` now embeds the percentile list used for each run: JSON output wraps the result in `{ percentiles, rows }`, and CSV output gains a trailing `summaryPercentiles` column so downstream tooling can validate cutlines without inspecting command logs.
- Vitest coverage verifies the envelope/column across default and custom percentile runs.
- Smoke summary JSON captures the verified percentile list (`goldSummaryPercentiles`) so dashboards/alerts can read the cutlines directly from the automation artifact.
- Added `goldSummaryCheck.mjs` (`npm run analytics:gold:check`) to validate one or more gold summary artifacts (JSON or CSV), ensuring they embed the expected percentile metadata before dashboards ingest them.
- CI tutorial smoke now runs `npm run analytics:gold:check artifacts/smoke/gold-summary.ci.json` so uploaded artifacts fail fast if percentiles drift.
- Smoke automation now parses the JSON summary immediately after generation and raises a warning if the metadata deviates from the canonical `25,50,90` list, preventing mismatched artifacts from entering CI.

## Gold Summary Custom Cutlines

- Added `--percentiles <comma-list>` to `goldSummary.mjs`, enabling dashboards to request arbitrary gain/spend percentile columns alongside the existing stats; defaults remain `50,90` for median/p90 parity.
- The CLI now emits `gainP<percent>` / `spendP<percent>` columns (e.g., `gainP25`, `spendP95`) immediately after `uniquePassiveIds`, plus the legacy `medianGain`/`p90Gain` aliases so earlier tooling keeps working.
- Parser validation, per-file aggregation, global rows, and CSV header generation gained coverage for custom percentiles (including decimal cut lines).

## Gold Summary Percentiles

- `goldSummary.mjs` now tracks every gain/spend delta per file to compute the median and 90th-percentile amounts; the JSON/CSV output adds `medianGain`, `p90Gain`, `medianSpend`, and `p90Spend` columns so dashboards can distinguish routine economy flow from rare spikes.
- The optional global row reprocesses raw timeline entries (instead of aggregating existing summaries) to keep percentile math and passive unlock stats accurate across mixed run lengths.
- Vitest coverage exercises empty timelines, per-file stats, CSV headers, and the new percentile calculation path to guard against regressions.

## Asset Integrity Guard

- `AssetLoader` now parses the optional `integrity` map in `public/assets/manifest.json`, downloads each sprite through `fetch`, hashes the bytes with `crypto.subtle.digest`, and refuses to cache any image whose digest does not match the declared `sha256-*` value.
- Missing integrity entries for manifest sprites raise warnings so future assets are brought under the checksum policy.
- When SubtleCrypto/fetch are unavailable (older browsers or offline scripts) the loader logs a degradable warning and continues so deterministic smoke tests keep running.
- Vitest coverage exercises matching/mismatched cases to ensure errors propagate and cached sprites stay untouched on failure.

## Asset Integrity Automation

- Added `node scripts/assetIntegrity.mjs` (available via `npm run assets:integrity`) to compute SHA-256 digests for every manifest-listed sprite and rewrite the manifest's `integrity` block automatically.
- `--check` mode lets CI and local hooks verify hashes without mutating the manifest, giving us a quick health check before commit/push.
- New Vitest coverage targets the hashing helper and orchestration path so future pipeline tweaks surface regressions immediately.

## Gold Timeline CLI

- Added `node scripts/goldTimeline.mjs` (`npm run analytics:gold`) to emit JSON/CSV timelines of gold events from analytics snapshots or smoke artifacts, capturing delta, resulting total, timestamps, and time-since values for dashboards.
- Script mirrors the passive timeline interface (directory recursion, stdout by default, `--out` and `--csv` flags) so automation can publish artifacts without bespoke code.
- Vitest coverage ensures argument parsing, entry shaping, and CSV output stay stable as analytics schemas evolve.

## Gold Summary Aggregator

- Added `node scripts/goldSummary.mjs` (`npm run analytics:gold:summary`) to crunch one or more timelines/snapshots into per-file economy stats (event counts, net delta, max gain/spend, passive linkage counts/lag).
- CLI accepts both raw timeline files and original snapshots; when snapshots are provided it auto-merges passive unlock data via the shared timeline helper.
- Vitest coverage ensures the new aggregation logic and CSV export remain stable.
- New `--global` flag appends an aggregate row so dashboards can track overall economy totals in a single run.

## Diagnostics & Passive Telemetry Refresh

- Diagnostics overlay now displays current gold with the latest delta/timestamp plus a running passive unlock summary so automation logs the same economy signals surfaced to players.
- Added a "Recent gold events" block to diagnostics, showing the last three deltas (amount, resulting total, timestamp, and time since) so smoke logs and HUD captures immediately reveal economy swings.
- HUD castle upgrade panel mirrors the same condensed history, listing the latest three gold deltas right next to passive summaries for quick at-a-glance economy context even when diagnostics are hidden.
- Runtime metrics track `goldEvents` and `castlePassiveUnlocks`, enabling the analytics export pipeline to expose unlock counts, last unlock details, and gold event timelines.
- `npm run analytics:aggregate` CSV gains `passiveUnlockCount`, `lastPassiveUnlock`, `castlePassiveUnlocks`, `goldEventsTracked`, `lastGoldDelta`, and `lastGoldEventTime` columns; docs updated accordingly.
- Tutorial smoke and castle breach artifacts now attach passive unlock counts, summaries, and active castle passives for downstream dashboards.

## Tutorial Wave Preview Highlight

- Combo, placement, and upgrade tutorial steps now surface an on-HUD hint for the upcoming enemies panel, reinforcing how to plan defenses.
- Wave preview adds an accessible tooltip with aria-live messaging so screen readers and automation pick up the guidance whenever the panel is highlighted.
- Pause/options overlay now lists the castle's current gold bonus alongside the exact benefits granted by the next upgrade (HP, regen, armor, slots, and bonus gold).

## Castle Gold Bonus Tracking

- Castle gold bonus now shows up in wave analytics, HUD scorecards, and CSV exports alongside existing objective bonuses.
- Analytics exports/leaderboards gained `castleBonusGold` and `totalCastleBonusGold` columns, keeping downstream tooling in sync with the new passive economy stat.

## Shield Telemetry Enhancements

- Wave HUD now marks shielded enemies with HP badges, lane highlights, and castle warnings.
- Diagnostics overlay surfaces live shield forecasts and damage splits.
- Analytics CSV export adds turret/typing damage, DPS, and shield-break columns.

## Crystal Pulse Turret Toggle

- Crystal Pulse turret archetype added behind a feature toggle with shield-burst damage and renderer assets.
- Pause/options menu, main menu, and debug panel can enable/disable the turret; player settings persist the choice.
- HUD highlights disabled turrets in slots/presets and lists shield bonuses in summaries.
- Projectile system now applies shield bonus damage prior to base damage with analytics coverage.

## Turret Downgrade Debug Mode

- Debug panel adds a turret downgrade toggle that exposes downgrade/refund controls on each turret slot.
- Downgrading refunds the appropriate gold, removes projectiles when clearing a slot, and has automated coverage for removal and level reduction.

## Turret Firing Animations

- Canvas renderer now adds coloured muzzle flashes per archetype whenever a turret fires.
- Animations respect reduced-motion settings and surface alongside impact effects for visual clarity.

## Analytics Leaderboard Export

- Added `analyticsLeaderboard.mjs` CLI plus `npm run analytics:leaderboard` to sort snapshot runs by combo, accuracy, and DPS.
- Outputs CSV or JSON with ranks and core performance stats for fast leaderboard generation.

## Castle Passive Buffs

- Castle upgrades now surface passive buffs (regen, armor, gold bonus) in the HUD and pause/options overlay.
- `castle:passive-unlocked` events drive automation logs/messages so tutorials and diagnostics can react.
- Options overlay lists active passives with totals and deltas, clarifying upgrade impact at a glance.

## Combo Warning Accuracy Delta

- HUD combo panel now surfaces an `Accuracy Δ` badge whenever the combo timer enters the warning window, referencing the last stable accuracy so players (and automation) see if they're trending up or down before the streak drops.
- Badge text/colour responds to positive/negative deltas and hides automatically when the warning clears or the combo resets.
