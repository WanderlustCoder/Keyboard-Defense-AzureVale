## Asset Integrity Enforcement - 2025-11-08

**Summary**
- `AssetLoader` now parses the manifest `integrity` map, fetches each sprite payload with `cache: "force-cache"`, hashes the bytes via `crypto.subtle.digest("SHA-256")`, and caches the image only when the digest matches the declared `sha256-*` value. Missing entries log warnings so new art drops stay on the checksum plan.
- Integrity failures throw with explicit error messaging, propagate to the loader's aggregate warning, and skip caching so tampered or corrupted assets never render. Environments lacking `fetch`/`SubtleCrypto` emit degradable warnings and fall back to existing behavior.
- Added Vitest coverage that stubs `Image`, `fetch`, and `crypto.subtle` to verify matching/mismatched flows, ensuring we refuse tainted sprites and keep diagnostics noise predictable.
- README, changelog, development docs, backlog status, and season backlog notes now record the checksum policy; backlog item #69 marked Done.
- Shipped `scripts/assetIntegrity.mjs` + `npm run assets:integrity` so sprite drops regenerate manifest hashes automatically, with `--check` mode ready for CI.
- CI build/test job now runs `npm run assets:integrity -- --check` ahead of the build orchestrator so any manifest drift fails the pipeline before other suites run.
- The CLI now emits telemetry (`artifacts/summaries/asset-integrity.(json|md)` by default in CI) capturing checked/missing/failure counts, first failure context, duration, and strict-mode state. Flags/env vars (`--mode`, `ASSET_INTEGRITY_MODE`, `ASSET_INTEGRITY_SUMMARY*`, `ASSET_INTEGRITY_SCENARIO`) let contributors opt into `strict` runs locally so dashboards and CI summaries can ingest the new data.
- Each telemetry payload also appends to `artifacts/history/asset-integrity.log` (newline JSON) so Codex can trend hash coverage over time. Override the destination with `--history <path>` or `ASSET_INTEGRITY_HISTORY`, and note that scenarios now default to `ci-build` in CI and `local` elsewhere so the log always records context.
- Added `scripts/ci/assetIntegritySummary.mjs` (`npm run analytics:asset-integrity`) to aggregate the latest telemetry + history entries into Markdown/JSON for `$GITHUB_STEP_SUMMARY`, making the Codex dashboard tile automatic instead of hand-written notes. CI’s tutorial smoke + full e2e jobs now run the integrity check in strict mode, emit smoke/e2e-specific artifacts, and append the new Markdown tile after their respective runs.
- Diagnostics overlay + HUD debug states now surface the integrity summary (`body.dataset.assetIntegrityStatus`), and tutorial/campaign smoke artifacts embed the telemetry so Codex dashboards show checked/missing/failure counts without digging into raw logs.

**Next Steps**
1. Monitor upcoming art drops to ensure the manifest stays hashed before strict mode is enabled by default.
2. Extend the telemetry to non-visual assets (FX/audio) once their manifests land so the dashboard covers the full asset surface.

## Follow-up
- `docs/codex_pack/tasks/31-asset-integrity-telemetry.md`
