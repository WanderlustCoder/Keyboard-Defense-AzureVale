## Defeat Sprite Seed - 2025-11-22

**Summary**
- Seeded `public/assets/manifest.json` with a minimal defeat atlas plus integrity hashes so sprite-mode bursts work out of the box. Manifest includes default + brute frame entries and SHA-256 digests consumed by `npm run assets:integrity`.
- Added placeholder PNGs and `defeat/atlas.json` so `npm run defeat:preview` can target the default manifest without flags; the preview now exercises both fallback and match-specific frame sets.

**Notes**
- The sample atlas uses 1x1 placeholder frames; drop real art into `public/assets/defeat/` and rerun `npm run assets:integrity` to refresh digests.
- Sprite selection follows the existing player setting (`Defeat Animations`: auto/sprite/procedural) and continues to honor reduced-motion.

## Follow-up
- Replace placeholders with production defeat sprites per backlog #66 / Codex task `docs/codex_pack/tasks/24-enemy-defeat-spriteframes.md`, then regenerate integrity and preview outputs for CI.
