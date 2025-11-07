## HUD Castle Panel Condensed Lists - 2025-11-17

**Summary**
- Castle passives and recent gold events inside the HUD now live inside collapsible cards with summary counts so the sidebar stays readable on tablets/phones without sacrificing the details desktop players expect.
- The toggle buttons announce how many passives or events are tracked (e.g., “Show Castle passives (3 passives)”); when collapsed they occupy a single row, and the lists expand inline without reflowing nearby controls.
- Viewports below 768px default to the collapsed state automatically, but players can expand either card at any time—state resets per session so HUD screenshots/tests remain deterministic.
- Gold event summaries surface the latest delta in the collapsed label (e.g., “3 recent events (last +40g)”), giving at-a-glance economy intel even when the list stays hidden.
- The pause/options overlay now mirrors the same condensed treatment for castle passives, complete with summary counts and a responsive toggle so small-screen players don’t scroll past a long passive list mid-battle.
- Player settings now persist each card’s collapsed state (HUD passives, HUD gold events, pause-menu passives), so once a player expands on mobile the preference sticks across reloads without losing the responsive default on fresh sessions.

**Next Steps**
1. Thread the same condensed treatment into the options overlay castle passives block so pause-menu screenshots match the HUD.
2. Persist per-panel collapse preferences in player settings so mobile users who expand once don’t need to repeat the action every wave.
