# Pre-Production Checklist (Before Codex Implementation)

Use this to decide if you are "ready to code" or likely to churn.

## Landmark: Hard requirements to lock
- [ ] Platform target (Windows desktop first) and minimum hardware support
- [ ] Tech stack locked (Godot 4 + GDScript + JSON data)
- [ ] Core loop acceptance criteria (Vertical Slice + MVP) agreed
- [ ] Wordpack format and progression model agreed
- [ ] Determinism strategy (seeded RNG) agreed
- [ ] Accessibility baseline agreed (time multiplier, contrast, motion)

## Landmark: Strong recommendations
- [ ] Save schema and migration plan agreed
- [ ] Content validation tooling planned
- [ ] Asset pipeline approach chosen (SVG pipeline vs runtime)
- [ ] Performance budgets documented
- [ ] Playtest plan and success metrics documented
- [ ] CI workflow planned

## Landmark: Optional (post-VS)
- [ ] Telemetry plan (opt-in, privacy-safe)
- [ ] Localization plan beyond `en-US`
- [ ] Modding or content pack import UI
