# Performance Budget and Profiling Plan

---
## Landmark: Targets (MVP)
- 60 FPS at 1080p on a typical desktop.
- 30 FPS minimum on low-end hardware (graceful degradation).
- Input latency: under 50ms perceived for typing feedback.

---
## Landmark: Budgets
### CPU (frame time)
- Total frame budget at 60 FPS: 16.7ms
  - Simulation: <= 4ms
  - Rendering: <= 8ms
  - UI/layout: <= 2ms
  - Misc headroom: <= 2ms

### Memory
- Keep peak memory under 1 GB for desktop builds.
- Avoid per-frame allocations during battles.
- Prefer object pools for particles, enemies, and projectiles.

### Assets
- Total shipped assets (MVP): target < 200 MB installed.
- Use texture groups and compression where appropriate.

---
## Landmark: Hotspot risks in this genre
- Battle wave: too many entities and collision checks
- Text rendering: frequent re-layout
- Audio: too many overlapping SFX

Mitigations:
- Fixed-step sim with interpolation for rendering.
- Batch draw calls via atlases or texture groups.
- Audio rate limiting and voice caps per sound group.

---
## Landmark: Profiling workflow
1. Run a stress scene (spawn max enemies and prompts).
2. Use the Godot profiler:
   - identify top scripts by time
   - capture frame time breakdown
3. Add instrumentation counters:
   - entity count
   - active prompts
   - average sim tick time

---
## Landmark: Acceptance tests
- Stress scene runs for 60 seconds without degrading below 50 FPS on a typical dev machine.
- No memory growth > 50 MB over 5 minutes in a static scene.
