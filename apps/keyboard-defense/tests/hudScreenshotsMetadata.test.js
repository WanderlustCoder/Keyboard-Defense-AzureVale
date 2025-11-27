import { test, expect } from "vitest";
import {
  deriveUiBadges,
  describeUiSnapshot,
  parseHudScreenshotArgs
} from "../scripts/hudScreenshots.mjs";

test("deriveUiBadges emits diagnostics + preference badges + starfield tag", () => {
  const snapshot = {
    compactHeight: true,
    diagnostics: {
      condensed: true,
      sectionsCollapsed: true,
      collapsedSections: {
        "gold-events": true,
        "castle-passives": false
      }
    },
    preferences: {
      diagnosticsSections: {
        "gold-events": true
      }
    }
  };
  const badges = deriveUiBadges(snapshot, { starfieldScene: "warning" });
  expect(badges).toEqual(
    expect.arrayContaining([
      "viewport:compact-height",
      "diagnostics:condensed",
      "diagnostics:sections-collapsed",
      "diagnostics:gold-events:collapsed",
      "diagnostics:castle-passives:expanded",
      "pref:diagnostics:gold-events:collapsed",
      "starfield:warning"
    ])
  );
});

test("describeUiSnapshot lists diagnostics section details", () => {
  const summary = describeUiSnapshot({
    diagnostics: {
      condensed: true,
      sectionsCollapsed: true,
      collapsedSections: {
        "gold-events": true,
        "turret-dps": false
      }
    }
  });
  expect(summary).toContain("Diagnostics condensed");
  expect(summary).toContain(
    "Diagnostics sections — gold-events:collapsed, turret-dps:expanded"
  );
});

test("parseHudScreenshotArgs normalizes starfield scenes", () => {
  const opts = parseHudScreenshotArgs(["--starfield-scene", "tutorial", "--ci"]);
  expect(opts.starfieldScene).toBe("tutorial");
  expect(opts.starfieldPreset).toBe("calm");
  expect(opts.ci).toBe(true);
});

test("parseHudScreenshotArgs rejects unsupported starfield scenes", () => {
  expect(() => parseHudScreenshotArgs(["--starfield-scene", "unknown"])).toThrow(
    /starfield scene/i
  );
});
