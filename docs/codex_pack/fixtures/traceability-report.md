## Traceability Report

Generated at: 2025-11-13T20:14:08.571Z
Filters: #71, #94

| Backlog | Title | Tasks | Tests | Status |
| --- | --- | --- | --- | --- |
| #71 | Script tutorial auto-run CLI verifying onboarding path nightly. *(Codex: `scenario-matrix`)* | `scenario-matrix` (done)<br>`ci-traceability-report` (done) | Tutorial smoke CLI fixtures – `apps/keyboard-defense/tests/tutorialSmoke.test.js` (pass)<br>Castle breach nightly summary – `apps/keyboard-defense/tests/castleBreachSummary.test.js` (pass)<br>Traceability CLI behavior – `apps/keyboard-defense/tests/traceabilityReport.test.js` (pass) | covered |
| #94 | Implement visual regression harness for HUD layout snapshots. *(Codex: `visual-diffs`)* | `visual-diffs` (done)<br>`starfield-parallax-effects` (todo) | HUD gallery rendering + metadata – `apps/keyboard-defense/tests/renderHudGallery.test.js` (fail)<br>HUD screenshot metadata validation – `apps/keyboard-defense/tests/hudScreenshotsMetadata.test.js` (unknown) | failing |

### Unmapped Tests
- `apps/keyboard-defense/tests/diagnostics.test.js` (pass)