# Vertical Slice Balance Baseline

## Scope

This document defines baseline tuning constants for the MonoGame first-playable
single-wave loop (`Start Vertical Slice`).

Primary config source:

- `apps/keyboard-defense-monogame/data/vertical_slice_wave.json`

## Baseline Constants

Current default profile (`vertical_slice_default`) values:

- `spawn_total`: `32`
- `spawn_interval_sec`: `2.5`
- `enemy_step_interval_sec`: `1.4`
- `enemy_step_distance`: `1`
- `enemy_contact_damage`: `1`
- `typed_hit_damage`: `2`
- `typed_miss_damage`: `1`
- `tower_tick_damage`: `1`

Start state defaults:

- `day`: `1`
- `hp`: `20`
- `gold`: `10`
- `threat`: `0`
- `lesson_id`: `full_alpha`
- `practice_mode`: `false`

## Score Formula (Current)

Score is computed in `VerticalSliceWaveSim`:

- Base victory bonus: `+500` (victory only)
- Enemy defeated bonus: `+100` each
- Word completion bonus: `+20` each
- HP remaining bonus: `+10` per HP
- Miss penalty: `-15` each
- Damage taken penalty: `-20` per HP damage
- Floor: minimum `0`

## Runtime Targets

Target playtime band for baseline profile:

- Typical run: `3-5 minutes`
- Fast/high-skill run: `~2-3 minutes`
- Failure run: can end earlier based on miss/contact damage

## Notes

- All values are intentionally data-driven for rapid tuning without code changes.
- Profile loading falls back to safe defaults if the JSON file is missing or invalid.
- Outcome payload keys persisted for summary/profile:
  - `vs_result`
  - `vs_score`
  - `vs_elapsed_seconds`
  - `vs_damage_taken`
  - `vs_miss_count`
  - `vs_summary_payload`
