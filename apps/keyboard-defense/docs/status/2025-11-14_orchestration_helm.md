## Orchestration Helm - 2025-11-14

**Summary**
- Added `scripts/helm.mjs`, a tiny task runner that proxies the most common npm workflows (start/build/test/smoke/gold-check) so local devs and automation can issue `node scripts/helm.mjs smoke` instead of memorizing multiple commands.
- `helm` delegates to the existing npm scripts (ensuring we reuse lint/test tooling) and provides a single entry point for future workflow glue.

**Next Steps**
1. Expanding helm with `--ci` presets could simplify our smoke/e2e invocations even further.
