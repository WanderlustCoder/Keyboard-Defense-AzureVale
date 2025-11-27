## Ambient Starfield Layer - 2025-11-07

**Summary**
- Starfield rendering now routes through `StarfieldParallaxController` / `utils/starfield.ts`, deriving drift/tint from wave progress and castle HP; diagnostics overlay surfaces the live state (`drift`, `depth`, `tint`, wave %, castle %) so CI artifacts prove the effect is responding.
- CanvasRenderer consumes the shared starfield state so reduced-motion and checkered background flags remain deterministic, and the new config (`config/starfield.ts`) documents all tunables.
- `scripts/hudScreenshots.mjs` gained `--starfield-scene tutorial|warning|breach`, forcing the chosen preset before every capture and stamping the scene into each `.meta.json` + `screenshots-summary.(json|ci.json)` entry (badges now include `starfield:<scene>`). The CLI help/docs were refreshed so contributors know how to pin a tint for tutorials/breach callouts.
- CI summaries now list `Screenshots | starfieldScene | <scene>` via `scripts/ci/emit-summary.mjs` so reviewers see which parallax preset the gallery used without inspecting artifacts; docs (Guide, Playbooks, dashboard/task status) point at the new flag/test coverage.
- `scripts/docs/renderHudGallery.mjs` now reads the starfield scene from each `.meta.json`, exposes it in the Markdown table + gallery JSON, and notes `_auto_` entries so dashboards immediately reflect which preset was forced without scraping badges.
- Fresh HUD screenshots were captured for tutorial, warning, and breach presets, and `docs/codex_dashboard.md` now displays the starfield scene for each gallery shot via the snapshot JSON so reviewers can see the active tint directly.
- Gold summary/report artifacts now emit `starfieldDepth|Drift|WaveProgress|CastleRatio|Tint`, and the gold analytics board surfaces both aggregated averages and a per-scenario `Starfield` column, letting reviewers correlate castle tint severity with net delta without leaving the board/portal.
- Gold analytics board + portal now tag starfield entries with severity badges (`CALM/WARN/BREACH`) based on castle ratio thresholds (default warn < 65%, breach < 50%), keeping castle damage drift visible inline with gold deltas; thresholds are overridable via `--castle-warn/--castle-breach` or env `GOLD_STARFIELD_WARN/BREACH` for new economy cutlines.
- Diagnostics overlay now shows starfield severity (%), reduced-motion flag, and per-layer velocities (first 3 layers) so parallax tuning and accessibility clamps are visible in CI artifacts without opening raw JSON.

**Next**
1. Keep the new Codex portal starfield tile refreshed with real artifacts (ensure nightly `npm run analytics:gold:board && npm run codex:dashboard` runs) so severity drift stays visible without manual refreshes.

## Follow-up
- `docs/codex_pack/tasks/35-starfield-parallax-effects.md`

