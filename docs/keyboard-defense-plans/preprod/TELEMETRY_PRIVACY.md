# Telemetry and Privacy Spec (Optional, Local-First)

This game can improve dramatically with player feedback on typing difficulty,
but telemetry must be handled carefully.

---
## Landmark: Default stance
- Telemetry OFF by default.
- Provide a clear settings toggle: "Share anonymous gameplay analytics".
- If OFF, all metrics remain local and are used only for adaptivity.

---
## Landmark: Data minimization rules
Collect only what is needed:
- run outcomes (win/loss, day reached)
- aggregate typing performance (WPM, accuracy)
- pack progression (which pack used, mastery status)
- difficulty settings (time multiplier, assist toggles)
- performance counters (fps bucket, load time bucket)

Never collect:
- raw typed text content
- freeform command history
- any personally identifying information

---
## Landmark: Event model
Use a small set of events:
- `session_start`
- `run_start`
- `run_end`
- `wave_start`
- `wave_end`
- `pack_used`
- `settings_changed`

Each event should include:
- timestamp (coarse; minute precision is enough)
- app_version and content_version
- anonymous device class bucket (desktop) if needed

---
## Landmark: Privacy UX requirements
- Explain what is collected in plain language.
- Provide Export Telemetry Data (JSON) for transparency.
- Provide Delete Local Data (resets telemetry and optionally profile with confirmation).

---
## Landmark: Implementation options
### Local-only (MVP-safe)
- Write event logs to `user://telemetry.jsonl`.
- No network calls.

### Opt-in upload (post-MVP)
- Upload only on explicit consent.
- Use HTTPS; rotate anonymous IDs.

---
## Landmark: Testing
- Verify no PII fields exist in event payload schema.
- Settings toggle must immediately stop logging.

Schema reference:
- `docs/keyboard-defense-plans/preprod/schemas/telemetry.schema.json`
