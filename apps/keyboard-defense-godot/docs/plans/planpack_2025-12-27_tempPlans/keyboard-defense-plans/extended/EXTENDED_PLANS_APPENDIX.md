# Extended Plans Appendix - Recommended Implementation Order

If you are using the earlier packs (core plans + assets + preprod), the
recommended order is:
1. Preprod foundations
   - settings and save scaffolding
   - content validator framework
   - acceptance test harness scene
2. Core loop (map to battle to rewards)
3. Extended systems from this pack
   - EXT-01 deterministic event engine
   - EXT-02 content validation integration
   - EXT-03 POI spawn and explore sim actions
   - EXT-04 UI for events with typing choice modes
   - EXT-05 safe content pack loader
   - EXT-06 balance simulation tooling

## LANDMARK: Why this order
- Content validation early prevents bad data from breaking runs.
- Event engine in the sim layer preserves determinism.
- UI arrives after the sim layer is stable.
- Modding comes last so schemas and loaders are mature.
