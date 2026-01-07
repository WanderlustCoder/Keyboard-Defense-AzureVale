# Release Strategy

## Release Objectives
- Deliver stable builds for:
  - internal playtests (weekly)
  - public demo (optional)
  - Early Access (optional)
  - v1.0 launch

## Versioning
Use Semantic Versioning:
- `0.x.y` for pre-release
- `1.0.0` for launch

Recommended build metadata:
- `0.2.0-alpha+<buildNumber>` for CI builds.

## Branching Model (lightweight)
- `main`: always releasable (or at least buildable)
- feature branches: `feat/<topic>`, `fix/<topic>`
- optional `release/<version>` branches for store submissions

## Build Matrix
Target a small set of platforms first:
- Windows (itch.io/Steam) - widest reach
- Optional later: macOS/Linux

## Packaging Principles
- Deterministic content builds: generated art/audio atlases committed or built in CI.
- Reproducible builds: lock dependencies, avoid "download at build time" steps.

## Release Artifacts
Minimum per build:
- Game build bundle (zip)
- Changelog snippet
- Version + commit hash
- (Optional) symbolicated crash logs

## Documentation Requirements Per Public Release
- Known issues list
- Accessibility options summary
- Privacy stance (telemetry opt-in/offline friendly)
- Input/controls summary (typing-first)

## Verification Points
Platform requirements change. Before submitting:
- Re-check Steamworks and itch.io docs for current packaging and store page requirements.
- Validate controller/input remapping requirements if you support gamepads.



