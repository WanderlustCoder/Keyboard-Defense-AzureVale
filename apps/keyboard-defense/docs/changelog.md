## Weekly Parent Summary Overlay

- Pause/options menu now includes a "Weekly Parent Summary" button that opens a printable overlay with time practiced, average accuracy/WPM, combo peak, perfect words, breaches, drills completed, repairs used, and a coaching note.
- Overlay is fully accessible (aria labels, focus trap, keyboard-close), supports print-to-PDF, and offers both header/inline close buttons so parents can dismiss without touching gameplay controls.
- HUD refreshes the summary live from session analytics so parents see up-to-date metrics even mid-run; tests cover the overlay toggle and metric rendering.

## Collectible Lore Scrolls

- Lesson completions now unlock a Lore Scrolls overlay with short, kid-friendly reading snippets; progress persists locally via the new lesson progress storage.
- HUD sidebar adds a Lore Scrolls card showing lessons completed, scroll unlock count, and the next requirement, with buttons in the HUD/options menu to open the overlay.
- Typing drill completions log scroll unlocks, and new helpers/tests cover lesson progress normalization and scroll unlock summaries.

## Castle Skin Themes

- Pause/options overlay now includes a Castle Skin selector (Classic, Dusk, Aurora, Ember) that applies instantly to the HUD castle panel and health bar.
- Castle passives, gold events, benefits, and the castle card/background now pull from skin-specific CSS variables set on root/body/HUD via `data-castle-skin`.
- Skin choice persists through the new `castleSkin` player setting (with normalization tests) and restores on load before syncing the pause menu.

## Companion Pet Sprites

- HUD sidebar now features a companion pet sprite that reacts to performance (calm/happy/cheer/sad) using live session accuracy, combo peaks, and castle health.
- Companion mood is announced via aria-label/text so assistive tech can read changes; reduced-motion settings dampen animations automatically.
- Added CSS pixel styling and tests covering mood transitions.

## Sticker Book Achievements

- Added a pixel-art Sticker Book overlay to the pause/options menu with a dedicated button, showing a grid of collectible achievement stickers with progress bars and status pills.
- HUD derives sticker progress from session stats (combos, breaches, shields broken, gold held, accuracy, drills) and auto-updates the summary/unlocked counts as runs progress.
- Overlay includes keyboard focus traps and accessible labels, plus tests to verify rendering, toggling, and summary counts.

## Contrast Audit Overlay

- Added a Contrast Audit overlay in the pause/options menu that scans key UI regions and highlights any text/background pairs below WCAG targets with inline markers and a summary list.
- The overlay is launched via a dedicated button (non-persistent), plays nicely with Reduced Motion and existing accessibility toggles, and reuses HUD layout data to position warning boxes.
- HUD tests cover the new control and overlay rendering; the audit is advisory and does not change player settings.

## Accessibility Self-Test Mode

- Pause/options overlay now includes an Accessibility Self-Test card that plays a short chime, flash, and motion cue with per-channel confirmations so players can verify comfort before enabling effects; motion checks auto-disable when Reduced Motion is on and sound checks skip when audio is muted.
- Self-test results (last run timestamp + confirmation flags) persist via player settings schema version 27 (`accessibilitySelfTest`) and ride alongside the screen-shake preview controls.
- HUD wiring animates the inline indicators and disables confirmations when unavailable, with tests covering UI state and persistence.

## Screen Shake Preview

- Pause/options overlay now includes a Screen Shake toggle with an intensity slider (0-120%) plus an inline preview tile so players can test comfort before enabling; controls respect Reduced Motion and default to off.
- Impact effects trigger a mild canvas shake when enabled (hits, breaches, muzzle flashes), reusing the preview path; preferences persist via player settings v27 alongside new HUD wiring and tests.

## Defeat Animation Sprite Pipeline

- AssetLoader now parses optional defeat animation definitions from the manifest and exposes `getDefeatAnimation`/`hasDefeatAnimation` so the renderer can stream sprite frames when defeat art drops into `public/assets/defeat/`.
- CanvasRenderer/GameEngine share a new `DefeatAnimationMode` preference (`auto`, `sprite`, `procedural`) so analytics match the rendered burst type, and diagnostics/CI summaries continue reporting sprite vs procedural usage via the upgraded analytics state.
- The pause/options overlay gained a “Defeat Animations” select that persists in player settings (`version 15`), letting comfort testers force procedural effects, require sprites, or keep the default auto mode; HUD/tests cover the new control.

## Castle Passive Iconography

- Added dedicated SVG iconography for regen, armor, and bonus-gold passives (served from `public/assets/icons/passives/`) so players can parse buffs at a glance without reading every row.
- HUD + pause/options passive lists now render the icons with accessible labels/tooltips, including condensed layouts, keeping the responsive cards legible while meeting the design request from backlog #30/#19.
- HUD tests cover the new semantics and fallback styling ensures generic passives (future content) still render a badge even if a specific icon is missing.

## Tutorial Passive Messaging

- Inserted a new tutorial beat after the castle upgrade that spotlights the freshly unlocked passive, highlights its HUD entry, and ensures condensed cards auto-expand so the badge is visible on tablets/phones.
- The tutorial now emits `tutorial.passiveAnnounced` telemetry with passive id/totals, letting smoke fixtures and dashboards confirm onboarding awareness; the message auto-advances after a short timer to keep the flow brisk.

## Passive Analytics Summaries

- `scripts/analyticsAggregate.mjs` gained `--passive-summary`, `--passive-summary-csv`, and `--passive-summary-md` flags so automation can emit passive unlock JSON/CSV/Markdown artifacts while still printing the core CSV to stdout.
- CI now writes `artifacts/summaries/passive-analytics.(json|csv|md)` alongside the existing passive gold dashboard outputs, and docs/guides describe the new workflow.
- Vitest coverage exercises the new flags to guard against regressions when the aggregation script evolves.

## HUD Castle Panel Condensed Lists

- Castle passives and recent gold events in the HUD now render inside collapsible summary cards with explicit counts, keeping the sidebar compact on tablets/phones while preserving one-click access to the full lists.
- Cards default to a collapsed state on screens ≤768px (desktop retains the previous always-expanded view), and the toggle buttons announce both the entry count and the latest gold delta so you can read economy drift without expanding.
- Passives/gold event lists no longer pop in/out abruptly—they hide behind the cards, which stabilizes layout shifts and makes HUD screenshots/tests deterministic again on narrow viewports.
- The pause/options overlay mirrors the same condensed card for castle passives, with summary counts plus a toggle so touch players can collapse the passive stack without losing at-a-glance context.

## Player Settings Collapse Preferences

- Player settings schema bumped to `version 12` so we can persist each condensed card’s collapse state (HUD passives, HUD gold events, and the pause-menu passive card) across sessions.
- When a player expands/collapses any of those cards, the preference now survives reloads on both desktop and touch layouts, while first-time sessions still respect the responsive default (collapsed on ≤768px).

## Responsive HUD Layout

- HUD + canvas layout now reflows on viewports below 1024px: the canvas stacks above a grid-based HUD that auto-fits two columns on tablets and collapses to a single column on phones, preventing the sidebar from squishing or overflowing.
- Options, wave scorecard, and main-menu overlays adopt reduced padding with scrollable cards on small screens so modals remain usable on touch devices.
- Debug analytics tables gain horizontal scrolling guards when space is tight, and coarse-pointer media queries bump buttons, selects, and primary inputs (typing field, telemetry endpoint) to the 44px accessibility target.

## Audio Intensity Slider

- Added an Audio Intensity slider to the pause/options overlay so players can scale SFX energy between 50% and 150% without muting the game; the slider disables automatically when master audio is off and mirrors the live percent label.
- Intensities persist via the upgraded player settings schema (`version 12`), propagate through `HudView.syncOptionsOverlayState`, and drive a new `SoundManager.setIntensity` multiplier so every procedural cue respects the preference.
- Vitest HUD harness now covers the slider state/emit path, ensuring automation keeps watch over the comfort control and backlog #54 stays Done.

## Canvas DPR Telemetry & Diagnostics

- GameController now propagates the canvas resize cause from the renderer into diagnostics (`Last canvas resize: …`), `document.body.dataset.canvasResizeCause`, and analytics snapshots so responsive regressions are traceable across HUD, telemetry, and dashboards.
- `analyticsAggregate` emits the new responsive columns (`uiHudLayout`, `uiResolution*`, `uiResolutionLastCause`, `uiPrefDevicePixelRatio`, `uiPrefHudLayout`) and the Codex dashboard docs describe how to pipe them into CI summaries.
- `npm run debug:dpr-transition` gained a `--markdown <path>` flag for drop-in PR/dashboards summaries, and the status note highlights the automation hook for quicker debugging.

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
