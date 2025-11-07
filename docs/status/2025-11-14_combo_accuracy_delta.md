## Combo Warning Accuracy Delta - 2025-11-14

**Summary**
- Added an `Accuracy Δ` badge under the combo counter that appears whenever the combo warning timer is active. It compares the current typing accuracy to the last stable (non-warning) value so players immediately see if they are trending up or down before the streak expires.
- Badge text is announced via `aria-live`, adopts success/danger colours for positive/negative deltas, and hides automatically once the warning clears or the combo resets.
- HUD tests now exercise the new element, and the tutorial smoke harness inherits the extra DOM id without additional work.

**Next Steps**
1. Consider logging the accuracy deltas to analytics so automation can correlate combo drops with accuracy swings across runs.
