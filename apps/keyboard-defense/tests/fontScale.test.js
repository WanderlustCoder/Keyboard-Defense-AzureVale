import assert from "node:assert/strict";
import { test } from "vitest";

import {
  formatHudFontScale,
  getNextHudFontPreset,
  HUD_FONT_PRESETS
} from "../src/ui/fontScale.ts";

test("formatHudFontScale describes presets and custom values", () => {
  assert.equal(formatHudFontScale(1), "100% (Default)");
  assert.equal(formatHudFontScale(1.3), "130% (Extra Large)");
  assert.equal(formatHudFontScale(1.07), "107% (custom)");
});

test("getNextHudFontPreset cycles through presets with wrapping", () => {
  assert.equal(getNextHudFontPreset(1, 1).value, 1.15);
  assert.equal(getNextHudFontPreset(1.3, 1).value, HUD_FONT_PRESETS[0].value);
  assert.equal(getNextHudFontPreset(1, -1).value, 0.85);
  assert.equal(getNextHudFontPreset(0.9, -1).value, 0.85);
  assert.equal(getNextHudFontPreset(1.12, 1).value, 1.15);
});
