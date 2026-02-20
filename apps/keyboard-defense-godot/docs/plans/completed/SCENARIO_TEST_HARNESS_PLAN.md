# Scenario Test Harness Plan

Supports: P0-BAL-001, P1-QA-001

## Goal
Create a fixed-seed scenario suite to validate balance and determinism without manual play.

## Proposed scenario format
- JSON or GDScript data file containing:
  - seed string
  - starting day/resources
  - action list (commands or intents)
  - expected outputs (resource ranges, hp ranges, wave size)
  - tolerance rules for metrics

## Example scenarios
- Day 1 baseline: gather -> build -> end -> wait until dawn.
- Day 3 ramp: explore twice, build tower, survive night with minimal misses.
- Night sample: known seed spawns a fixed enemy sequence; tower damage reduces hp.

## Headless execution
- Run via `res://tests/run_tests.gd` or a dedicated scenario runner script.
- Record outputs to a log file for diffing between milestones.

## Metrics to track
- Base hp remaining
- Night wave size and enemies defeated
- Resource totals after dawn
- Typing metrics (hits/misses, accuracy)

## Acceptance criteria
- Scenarios produce the same outputs for the same seed/actions.
- Failures surface clear diffs in test output.
- Harness runs headless without UI dependencies.
