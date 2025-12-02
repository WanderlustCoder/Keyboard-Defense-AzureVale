# QA Checklist - Enemy Behaviors and Traps

Covers Season 3 enemy/mechanic additions: shielded, splitting, stealth, frost, trap tiles, environmental variants, status effects. Target platform Edge/Chrome, ages 8-16, single-player.

## Setup
- Use dev server (`npm run start -- --no-build`) and enable diagnostics overlay.
- Enable reduced motion toggle to verify fallback visuals for effects.
- Use debug spawn tools or wave editor to force enemy types and traps per lane.

## Shielded Enemies
- Initial shield value matches design; first hits subtract shield before health.
- Visual cue for shield present/absent; removal timing is frame-accurate with first successful hit.
- Typing completion with shield active does not count as kill; requires guard-break key if applicable.
- Analytics: shield break count increments; damage split (typing vs turret) logged correctly.

## Splitting Enemies
- On defeat, exactly two child enemies spawn with expected shorter words; no duplicate credit on parent death.
- Spawn timing staggered slightly (no overlapping spawn positions); children inherit lane and respect pathing.
- Score/gold counted per child; parent reward not duplicated.
- Diagnostics shows expected enemy count increase after split.

## Stealth/Reveal Enemies
- Letters reveal at intended pace under fire; unreadable portions never count as errors.
- Targetable state matches visibility: turrets do not fire until reveal rule satisfied (or specific affix allows).
- Typing buffer ignores hidden letters; error feedback limited to revealed portion.
- Reduced-motion mode still shows clear reveal steps without flicker.

## Frost / Slow Effects
- On hit, affected turrets/enemies show clear slow icon/tint; duration matches spec and decays smoothly.
- Fire rate/speed multipliers apply once (no stacking beyond cap); timer resets on reapply within grace.
- Diagnostics/telemetry capture slow events and current multipliers.

## Trap Tiles
- Activation prompt appears when expected (e.g., after a wave threshold or lane hazard trigger).
- Typing prompt consumes input and triggers trap once; subsequent attempts respect cooldown.
- Slow/stop effect applies only to enemies on trap tile; clears after duration.
- No soft-lock: trap prompt does not block normal enemy targeting.

## Environmental Variants (fog/gloom/wind)
- Overlay readability: text remains legible; background brightness slider helps mitigate.
- Effects respect reduced-motion; heavy particles disabled when toggle is on.
- Turret projectile behavior matches variant (e.g., wind drift) and reverts after event ends.

## Status Effects (burn/slow/shock)
- Icons/tooltips display per enemy; stacking rules follow spec (e.g., burn refresh vs stack).
- Damage-over-time ticks at defined rate; stops when enemy dies or timer expires.
- Combo/accuracy not penalized by ticking damage; rewards granted once per enemy.

## Regression & Edge
- Pause/resume does not duplicate effects or drop timers.
- Wave rewind/replay (if enabled) resets status and trap state.
- Low graphics mode + reduced motion still shows essential cues (icons, tints).
- Asset preloading: new sprites/effects appear without hitching on first use.
