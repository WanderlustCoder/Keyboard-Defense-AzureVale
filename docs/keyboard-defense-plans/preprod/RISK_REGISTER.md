# Risk Register (Pre-Production)

This is not exhaustive; it is the top risks that cause rework.

| Risk | Likelihood | Impact | Trigger | Mitigation |
|---|---:|---:|---|---|
| Typing-first controls feel slow or frustrating | Med | High | Playtesters hesitate or fail early | Add assist modes, autocomplete, command aliases, calm mode |
| Adaptive difficulty overreacts (yo-yo) | Med | High | Difficulty spikes after one bad prompt | Use smoothing windows, cap deltas, add floor/ceiling |
| Battle UI becomes unreadable | Med | High | Too many simultaneous prompts/entities | Threat cards, queue limits, telegraphing, slow-mo option |
| Content authoring becomes a bottleneck | High | Med | Adding packs requires code edits | Data-driven pipeline plus schemas and validator tool |
| Determinism breaks due to hidden randomness | Med | Med | Mismatched replay or inconsistent saves | Central PRNG, ban DateTime randomness, add deterministic tests |
| Procedural asset pipeline complexity | Med | Med | Generator brittle or hard to tweak art | Keep generator simple, runtime fallback, small style guide |
| Audio fatigue (repetitive cues) | High | Low/Med | Testers mute quickly | Subtle pitch/amp variation, rate limiting, toggles |
| Scope creep | High | High | More enemies/biomes before core loop solid | Enforce VS criteria, gate features behind milestones |
| Accessibility debt | Med | High | Late requests require UI refactor | Bake in settings early, centralized UI strings |
