# Season 1 Backlog – Siege of the Azure Vale

Structured backlog derived from the inspiration brief, architecture notes, and tutorial spec. Items are grouped by theme with numbered references for planning.

## Tutorial & Onboarding
1. Introduce tutorial pause/resume hooks and ensure intro overlay gates gameplay.
2. Highlight turret slot and enforce guided placement with gold auto-top-up.
3. Gate upgrade step with forced slot selection and auto-replenished gold.
4. Script deterministic castle breach demonstration with guided messaging.
5. Present wrap-up summary modal (accuracy/combo/breaches/gold) with replay/continue.
6. Persist tutorial completion in localStorage; expose debug replay/skip.
7. Add assist tip when typing errors exceed threshold during tutorial.
8. Record tutorial telemetry events (start/step-complete/fail/skip/complete).
9. Provide tutorial skip option from main menu once completed.
10. Surface tutorial firmware versioning to invalidate old completions if flow changes.

## Combat Systems & Typing
11. Scale word difficulty dynamically using rolling accuracy window.
12. Diversify lane word banks to reduce repetition and teach pacing.
13. Add per-letter feedback colors for active enemy word progress.
14. Implement combo decay timer with HUD warning state.
15. Provide manual buffer purge hotkey with minor combo penalty.
16. Track wave-side bonus objectives (e.g., perfect words) for rewards.
17. Introduce shielded enemies requiring turret damage before typing is effective.
18. Add turret/enemy affinity bonuses to encourage mixed defenses.
19. Offer low-intensity endless practice mode for casual warm-up.
20. Log typing reaction time metrics for balancing.

## Castle & Turrets
21. Display upcoming castle upgrade benefits in upgrade panel tooltip.
22. Add castle repair ability with cooldown/resource cost.
23. Persist turret loadout presets per slot for experimentation.
24. Introduce "Crystal Pulse" turret archetype behind feature toggle.
25. Allow turret targeting priority selection (first/strongest/weakest).
26. Animate turret firing states with sprite overlays.
27. Log per-wave turret DPS in diagnostics overlay.
28. Provide turret range visualization on hover/focus.
29. Allow downgrade/refund via debug toggle for testing.
30. Unlock castle passive buffs (regen/armor/gold) at higher levels.

## Enemy & Wave Design
31. Create elite enemy affixes (slow aura, shielded, armored) under toggles.
32. Script Episode 1 boss wave with bespoke mechanics and intro message.
33. Display enemy taunt text when special units spawn.
34. Render spawn preview icons using sprite thumbnails.
35. Add dynamic spawn scheduler for surprise mini-events.
36. Implement evacuation event requiring long-form typing to rescue civilians.
37. Introduce lane hazards (fog/storms) affecting visibility/accuracy.
38. Provide JSON schema/editor for designer-authored wave configs.
39. Calculate difficulty ratings per wave and surface in analytics overlay.
40. Spawn practice dummy enemy for turret DPS tuning in debug mode.

## Analytics & Telemetry
41. Expand analytics export to include tutorial metrics and summary history.
42. Persist per-wave analytics snapshot history for in-session review.
43. Build in-game analytics table accessible from debug panel.
44. Separate turret vs typing DPS metrics in analytics payload.
45. Add CLI script to aggregate analytics logs into summary CSV.
46. Guard analytics reset mid-wave with dedicated tests.
47. Export leaderboard-ready CSV covering key stats.
48. Capture time-to-first-turret placement and include in analytics.
49. Emit tutorial replay/skip counts for onboarding analysis.
50. Wire optional telemetry endpoint for backend ingestion (future-ready).

## UI/UX & Accessibility
51. Offer colorblind-friendly palette toggle across sprites/HUD.
52. Support adjustable HUD font size with persistence.
53. Reflow layout for narrow screens / touch devices.
54. Add audio intensity slider alongside mute toggle.
55. Provide dyslexia-friendly font option for key UI elements.
56. Highlight wave preview during tutorial to emphasize planning.
57. Surface keyboard shortcut reference overlay.
58. Add pause/options overlay while maintaining deterministic state.
59. Present wave-end scorecard summarizing accuracy, breaches, rewards.
60. Implement reduced-motion mode (disable shake/particle effects).
61. Persist player settings (audio, diagnostics, toggles) across sessions.

## Asset Pipeline & Visuals
62. Replace inline SVG helpers with hashed asset pipeline utilities.
63. Generate sprite atlas to minimize draw calls.
64. Defer high-res asset loading until post-ready signal.
65. Introduce projectile particle systems via offscreen canvas.
66. Add enemy defeat animation frames with easing.
67. Morph castle visuals across upgrade levels.
68. Overlay ambient starfield/parallax background effects.
69. Validate asset integrity via manifest checksum at startup.
70. Automate asset manifest generation from source sprites.

## Automation, Monitoring, Tooling
71. Script tutorial auto-run CLI verifying onboarding path nightly.
72. Capture automated HUD screenshots for docs/regression.
73. Integrate ESLint/Prettier into build pipeline.
74. Add performance benchmark harness for engine throughput.
75. Create deterministic wave simulation CLI for balance sweeps.
76. Validate config files against schema in pre-commit hook.
77. Watch docs/ for changes and rebuild summaries automatically.
78. Scaffold Playwright smoke tests for tutorial/campaign start.
79. Aggregate runtime logs into breach/accuracy summary post-run.
80. Provide git hook automation to run tests/lint locally.
81. Implement dev-server monitor (logs + health probes) for unattended runs.
82. Add tutorial smoke workflow leveraging diagnostics tolerance.

## Narrative & Content
83. Script Archivist Lyra dialogue blocks for Episode 1 beats.
84. Author lore codex entries unlocked by completing waves.
85. Enrich turret tooltips with flavor text.
86. Surface interactive season roadmap overlay within HUD.
87. Add enemy biography cards accessible from wave preview panel.
88. Curate ambient music tracks escalating across waves.
89. Expand word banks with themed lists per wave.
90. Compose short victory/defeat stingers.

## QA & Testing
91. Expand tutorial state tests to cover assist cues and replay/skip flows.
92. Add asset loader fallback tests (network failure/cache reuse).
93. Write analytics export/reset integration tests for debug panel flows.
94. Implement visual regression harness for HUD layout snapshots.
95. Include dev-server monitor smoke test in CI.
96. Fuzz test typing input buffer for invalid characters/timing.
97. Automate tutorial summary modal snapshot tests.
98. Add soak test that alternates tutorial replay/skip, verifying persistence.
99. Create CLI to replay deterministic castle breach scenario for regression.
100. Track tutorials completed per session in QA dashboard.

## Economy & Telemetry
101. Add percentile stats (median/p90) to the gold summary CLI output so dashboards can monitor economy drift.
102. Add percentile flag to the gold summary CLI so dashboards can request alternate gain/spend cutlines.
103. Ensure CI smoke workflows emit gold summary artifacts with the standardized percentile list.
104. Include the percentile list inside every gold summary artifact so downstream tooling can verify cutlines.
105. Validate gold summary percentile metadata during CI smoke runs.
