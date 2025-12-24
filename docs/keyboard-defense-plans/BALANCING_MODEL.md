# Balancing model (prototype) - combat pacing and typing linkage

## Principles
- Typing performance should matter, but never hard-gate progress.
- Reward accuracy first; speed second.
- Keep buffs short and readable to avoid overwhelm.

## Baseline combat values (current)
- Base threat rate: 8.0
- Threat relief per correct word: 12.0
- Mistake penalty: 18.0
- Castle health: 3 (plus upgrades)

## Buffs (current)
- Focus Surge: +25% typing power for 8s (word streak trigger).
- Ward of Calm: 0.75x threat rate for 8s (input streak trigger).

## Rewards (current)
- Practice gold: 3 per battle.
- First-clear reward: node reward_gold.
- Performance tiers:
  - S: accuracy >= 96% and WPM >= 32 (bonus 6g)
  - A: accuracy >= 93% and WPM >= 26 (bonus 4g)
  - B: accuracy >= 88% and WPM >= 18 (bonus 2g)
  - C: fallback tier (bonus 0g)

## Tuning levers
If battles feel too punishing:
- Lower base threat rate.
- Raise threat relief.
- Increase castle health bonus on early upgrades.

If battles feel trivial:
- Raise threat rate slightly.
- Increase intermission duration to reduce free relief.
- Tighten performance tier thresholds.

If typing feels irrelevant:
- Increase bonus gold slightly.
- Add optional drills that grant focused rewards.

If typing feels mandatory:
- Ensure base rewards still progress the map.
- Cap bonus gold and buffs to avoid runaway advantages.
