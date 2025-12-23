---
id: asset-integrity-telemetry
title: "Expose asset integrity telemetry + strict mode"
priority: P2
effort: M
depends_on: []
produces:
  - diagnostics/asset-integrity.json
  - strict integrity configuration flag
status_note: docs/status/2025-11-08_asset_integrity.md
backlog_refs:
  - "#69"
  - "#41"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
Asset checksum enforcement now guards sprite corruption, but failures stay local to
the CLI/loader logs. Diagnostics overlays, CI summaries, and dashboards cannot see
integrity outcomes, and missing manifest hashes silently warn. We need telemetry +
an opt-in strict mode so Codex can detect drift automatically.

## Steps

1. **Telemetry emitter**
   - Extend `AssetLoader` (and `scripts/assetIntegrity.mjs`) to emit structured events:
     - totals (checked, skipped, missing hash, failed)
     - first failure digest + asset path
     - strict-mode flag state
   - Write the telemetry to `artifacts/asset-integrity.ci.json` when running in CI.
   - Append each run to a newline-delimited log (`artifacts/history/asset-integrity.log`) so dashboards can track drift over time; offer `--history` / `ASSET_INTEGRITY_HISTORY` overrides.
2. **Diagnostics + dashboard**
   - Surface the latest stats inside the diagnostics overlay (or developer HUD panel) so manual runs highlight tampered sprites.
   - Add a Codex dashboard tile that ingests the CI JSON/history log and lists the count of verified/missing hashes (use `scripts/ci/assetIntegritySummary.mjs` to emit Markdown/JSON for `$GITHUB_STEP_SUMMARY`).
3. **Strict mode**
   - Implement `integrity=strict` (env var or CLI flag) to fail immediately when manifest entries are missing checksums (once the manifest is fully hashed).
   - Document migration guidance so contributors can enable strict mode locally before CI does.
4. **Docs/playbooks**
   - Update `README.md`, `CODEX_GUIDE.md`, and `docs/status/2025-11-08_asset_integrity.md` once telemetry + strict mode land.

## Implementation Notes

- **Telemetry schema**
  - Emit JSON payloads shaped as:
    ```json
    {
      "scenario": "tutorial-smoke",
      "checked": 420,
      "skipped": 12,
      "missingHash": 3,
      "failed": 0,
      "firstFailure": { "path": "sprites/turret.png", "expected": "abcd", "actual": "efgh" },
      "strictMode": false,
      "durationMs": 312,
      "timestamp": "2025-11-08T12:34:56.000Z"
    }
    ```
  - Store the latest payload at `artifacts/summaries/asset-integrity.ci.json` and append to a rolling history under `artifacts/history/asset-integrity.log`.
  - Teach `analyticsAggregate` to ingest this JSON so dashboards can trend failure counts over time.
- **Diagnostics integration**
  - Add a compact card to the diagnostics overlay (and HUD debug panel) showing pass/fail status, counts, and a CTA to open full logs.
  - Surface `body.dataset.assetIntegrityStatus` so HUD screenshots + `uiSnapshot` metadata can display the result.
- **Strict mode behavior**
  - Environment controls: `ASSET_INTEGRITY_MODE=soft|strict|off` plus CLI flag `--integrity-mode`.
  - In strict mode:
    - Missing hashes or skipped files become fatal (non-zero exit).
    - Loader paths throw during dev-server boot, prompting contributors to regenerate manifests.
  - Provide `npm run assets:integrity -- --fix-missing-hashes` helper that hashes untracked assets and updates the manifest.
- **CI wiring**
  - Add a dedicated step (tutorial smoke + nightly) that runs the loader in `--integrity-mode strict`, uploads the telemetry JSON, and publishes a Markdown summary to `$GITHUB_STEP_SUMMARY`.
  - Thresholds: fail if `failed > 0`, warn if `missingHash > 0` when in soft mode.
- **Docs & onboarding**
  - Update `apps/keyboard-defense/docs/DEVELOPMENT.md` with strict-mode instructions.
  - Add a checklist to `CODEX_PLAYBOOKS.md` (Automation section) reminding contributors to regenerate manifests, run `assets:integrity`, and review telemetry.
  - Expand the status note with follow-up closure details once telemetry + dashboards land.

## Deliverables & Artifacts

- Telemetry writer inside `scripts/assetIntegrity.mjs` + `AssetLoader`.
- `artifacts/summaries/asset-integrity*.json|md` produced during CI.
- Diagnostics overlay UI + CSS updates reflecting integrity status.
- Strict-mode configuration (env vars, CLI flags, docs).
- Tests covering telemetry schema + strict-mode error paths.

## Acceptance criteria

- CI uploads telemetry JSON and Codex dashboard references it.
- Diagnostics overlay shows current integrity status without opening logs.
- Strict mode blocks missing-hash runs when enabled; soft mode still warns.

## Verification

- npm run assets:integrity -- --check
- npm run test -- assetIntegrity
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status






