## Asset Integrity Enforcement - 2025-11-08

**Summary**
- `AssetLoader` now parses the manifest `integrity` map, fetches each sprite payload with `cache: "force-cache"`, hashes the bytes via `crypto.subtle.digest("SHA-256")`, and caches the image only when the digest matches the declared `sha256-*` value. Missing entries log warnings so new art drops stay on the checksum plan.
- Integrity failures throw with explicit error messaging, propagate to the loader's aggregate warning, and skip caching so tampered or corrupted assets never render. Environments lacking `fetch`/`SubtleCrypto` emit degradable warnings and fall back to existing behavior.
- Added Vitest coverage that stubs `Image`, `fetch`, and `crypto.subtle` to verify matching/mismatched flows, ensuring we refuse tainted sprites and keep diagnostics noise predictable.
- README, changelog, development docs, backlog status, and season backlog notes now record the checksum policy; backlog item #69 marked Done.
- Shipped `scripts/assetIntegrity.mjs` + `npm run assets:integrity` so sprite drops regenerate manifest hashes automatically, with `--check` mode ready for CI.
- CI build/test job now runs `npm run assets:integrity -- --check` ahead of the build orchestrator so any manifest drift fails the pipeline before other suites run.

**Next Steps**
1. Surface integrity verification metrics in diagnostics/telemetry so CI artifacts can flag unexpected asset failures.
2. Consider optional `integrity=strict` flag to fail fast (abort load) when any manifest entry lacks a checksum once the pipeline is fully hashed.
