# Monte Carlo Simulation Plan (Balance and Skill Sensitivity)

Goal: quantify how typing skill variables (WPM, error rate, assist mode) affect
survival, progression, and pacing. This is a developer tool, not a player
feature.

## LANDMARK: What the simulator must answer
1. Survival probability by day for skill brackets (Beginner/Intermediate/Advanced).
2. Expected resource totals over time (detect snowball or starvation).
3. Expected intervention success rate and its marginal impact.
4. Difficulty spikes: threat cards, biome effects, early upgrades, first tower.

## Inputs
- Seed
- Player WPM distribution (mean and variance) or fixed values
- Error rate distribution (mean and variance) or fixed values
- Assist mode or time multiplier
- Strategy policy (simple heuristic)
  - upgrade priority
  - whether to explore
  - night intervention selection rules

## Outputs
- Run result: defeat day or victory day
- Resource time series
- Upgrades and units time series
- Battles: prompts attempted, success percent, net damage prevented
- Exploration: POIs visited, event outcomes

## Typing model (simple, explainable)
For each prompt:
- Prompt length L chars.
- Expected time (seconds) = (L / (WPM * 5)) * 60
- Add reaction overhead (e.g. 0.25s) and UI overhead (0.15s).
- Success if time <= window AND rand >= error_rate_adjusted
- On success: apply effect * success_bonus
- On fail: apply fail_effects or a penalty

Suggested error function:
- base = error_rate
- +0.02 if punctuation present (tier >= 2)
- +0.01 per 10 chars beyond 20
- clamp 0..0.4

## Strategy policy (baseline)
- Day:
  - keep gold buffer for repairs
  - prioritize core upgrades first
  - explore if no urgent upgrade
- Night:
  - prioritize interventions that prevent castle damage
  - if threat has a counter intervention unlocked, prefer it

## LANDMARK: Acceptance criteria
- Simulator runs 1,000 runs in under 5 seconds for the simplified model.
- Outputs CSV plus summary JSON.
- Produces a markdown report with:
  - survival curve
  - top 10 spike days
  - recommended lever adjustments

## Integration approach
- Implement under `apps/keyboard-defense-godot/scripts/tools/sim/`.
- Reuse the deterministic sim core used by the game.
- Provide a Godot headless entry point, for example:
  - `godot --headless --script res://scripts/tools/sim/balance_sim.gd`
- Use scenarios from `docs/keyboard-defense-plans/extended/tools/sim/scenarios.json`.
