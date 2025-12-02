# Season 2 Backlog - Keyboard Defense (Ages 8-16)

Next-phase backlog for the typing-education castle defense game. Guardrails: audience ages 8-16, runs in Edge and Chrome, free single-player (no monetization), future multiplayer ideas are parked, and art direction is cartoonish pixel art for all sprites and castle pieces.

## Context and Guardrails
1. Narrative overview: castle-defense typing adventure for ages 8-16 (Edge/Chrome).
2. Core loop spec: type words to repel waves; lives/hearts and victory conditions defined.
3. Onboarding flow: first-run tutorial with coach character and simple prompts.
4. Age-tailored UX: large hit targets, minimal text clutter, readable font.
5. Accessibility pass: WCAG AA color/contrast, focus states, screen-reader labels.
6. Pause/resume controls and ESC hotkey behavior.
7. Persistent user profile (local) with multiple learner slots.
8. Privacy notice for minors; no account/no tracking beyond local storage.

## Curriculum and Lesson Design
9. Curriculum map: home row -> top row -> bottom row -> numbers -> punctuation.
10. Lesson objectives per unit (accuracy first, then speed).
11. Key-by-key drills with accuracy gating before speed unlocks.
12. Adaptive difficulty: slow down word spawn if accuracy drops.
13. Adaptive speed-up when accuracy stays high.
14. Per-lesson target WPM and accuracy thresholds.
15. Timed practice mode (1-3 minute runs).
16. Endless defense mode with scaling difficulty.
17. Boss wave design every N lessons using mixed punctuation/longer words.
18. Word list stratification by lesson (only letters introduced so far).
19. Kid-safe dictionary (no inappropriate words).
20. Left-hand/right-hand isolated drills.
21. Shift-key training with on-screen hint.
22. Number row drills with castle-archer theme.
23. Common punctuation drills (.,?!;:'"-).
24. Brackets/braces training for later units.
25. Short-phrase typing (bigrams/trigrams) after single keys.
26. Common English words list for mid-game.
27. Code-like snippets (age-appropriate) for advanced unit.
28. Proper typing posture tips overlay.
29. Finger placement visual (color-coded hands).
30. On-screen keyboard highlight of active keys.

## HUD, Feedback, and Game Feel
31. Live accuracy meter and WPM indicator.
32. Combo meter for streaks (rewards).
33. Miss penalty visualization (projectile hits wall).
34. Health bar for castle; game-over screen with recap.

## Progression, Goals, and Rewards
35. Level select map (chapters/regions of castle).
36. Lesson lock/unlock logic with prerequisites.
37. Star/medal scoring per lesson (accuracy/speed/streak).
38. Daily goal system (minutes practiced or lessons cleared).
39. Streak calendar to encourage return.
40. Rewards store (cosmetic only; free currency).
41. In-game currency earn rates tuned to playtime, not payments.

## Art, Enemies, and Atmosphere
42. Skins for castle walls (pixel art variants).
43. Skins for defenders (archers/mages) in pixel art.
44. Enemy varieties tied to difficulty tiers.
45. Boss sprites (cartoonish pixel art) concept list.
46. Projectile VFX (arrows, bolts) pixel style.
47. Impact/explosion VFX pixel style.
48. Ambient background layers (mountains, clouds) parallax.
49. Weather variants (day/night/rain) purely cosmetic.

## UI and Audio Style
50. UI theme palette tuned for kids and contrast.
51. SFX plan: keypress, hit, miss, wave start/end (volume slider).
52. Music loop selection with mute toggle.

## Performance, Controls, and Accessibility
53. Performance target: smooth at 60 FPS on mid laptops in Edge/Chrome.
54. Low-graphics toggle for weak devices.
55. Latency handling for key input; no dropped strokes.
56. Virtual keyboard (optional) for accessibility.
57. Tutorial voice/text pacing options (slow/normal).
58. Text size preference (small/medium/large).
59. Colorblind-safe palettes for enemies/projectiles.
60. Haptics stub (desktop off by default) for future mobile builds.
61. Input debounce/forgiveness for near-simultaneous keys.
62. Mis-typed key highlight with correct-key hint.

## Coaching, Analytics, and Safety
63. Post-lesson summary: accuracy, WPM, most-missed keys.
64. Suggested remedial drill based on missed keys.
65. Heatmap per finger/row for last session.
66. Progression dashboard with chapter completion.
67. Achievement list (first 10 lessons, first boss, 95 percent accuracy, etc.).
68. Safe-name generator for profiles (no custom text needed).
69. Age-appropriate language throughout UI.
70. Save/export local progress (JSON) and re-import.
71. Offline-capable PWA shell (Edge/Chrome install prompt).
72. Lightweight analytics (local only) for session counts/time.
73. Session timer and break reminders.
74. Parental info screen: what is tracked (local only).

## Layout, Storytelling, and Difficulty
75. Keyboard layout support: start with QWERTY, plan for QWERTZ/AZERTY switch.
76. Regional wordlist toggle (US/UK spelling).
77. Intro cutscene (skippable) establishing castle defense story.
78. In-run voice bubble guidance from mentor character.
79. Difficulty presets (Easy/Normal/Hard) tied to spawn rates.
80. Speed ramp curves configurable per lesson.

## Engine, QA, and Delivery
81. Enemy pathing lanes clear and readable.
82. Collision/castle hitboxes tuning document.
83. Fail-fast debug overlay (FPS, entity counts).
84. QA checklist for typing edge cases (held keys, caps lock).
85. Caps-lock detection warning.
86. Keyboard focus trap to keep inputs in game canvas.
87. Fullscreen toggle.
88. Responsive layout for small/large laptop screens.
89. Content safety check on all text/assets.
90. Asset pipeline plan for pixel art production (sizes, palette).
91. Sprite sheet spec for enemies/defenders/projectiles.
92. Castle tileset spec (walls, gates, damage states).
93. UI icon set spec (pixel-style buttons, toggles).
94. Loading screen with tips and pixel animation.
95. Build-time lint/tests gate expanded to lesson JSON validator.
96. Wordlist/lesson content lints (no forbidden words, length ranges).
97. Automatic playtest script (bot) to simulate key input for perf smoke.
98. Visual regression baselines for core screens.
99. Deployment checklist for browser compatibility (Edge/Chrome).
100. Post-Season roadmap placeholder for multiplayer/co-op ideas (not active now).
