import { describe, expect, test } from "vitest";
import path from "node:path";
import {
  applyToggles,
  buildFromCore,
  compileValidator,
  loadSchema,
  summarize,
  validateConfig
} from "../scripts/waves/editConfig.mjs";

const SCHEMA_PATH = path.join(process.cwd(), "schemas", "wave-config.schema.json");

describe("wave config editor helpers", () => {
  test("buildFromCore emits valid structure with feature toggles", async () => {
    const schema = await loadSchema(SCHEMA_PATH);
    const validate = compileValidator(schema);
    const config = await buildFromCore();
    expect(validate(config)).toBe(true);
    expect(config.waves.length).toBeGreaterThan(0);
    expect(config.featureToggles.dynamicSpawns).toBeTypeOf("boolean");
  });

  test("applyToggles updates supported keys", async () => {
    const config = {
      featureToggles: {
        dynamicSpawns: true,
        eliteAffixes: true,
        evacuationEvents: true,
        bossMechanics: true
      },
      waves: []
    };
    applyToggles(config, { dynamicSpawns: false, eliteAffixes: false });
    expect(config.featureToggles.dynamicSpawns).toBe(false);
    expect(config.featureToggles.eliteAffixes).toBe(false);
    expect(config.featureToggles.evacuationEvents).toBe(true);
  });

  test("summarize emits a human-readable overview", () => {
    const config = {
      waves: [
        {
          id: "wave-1",
          spawns: [{ at: 0, lane: 0, tierId: "grunt", count: 1, cadence: 1 }],
          hazards: [{ kind: "fog", lane: 0, time: 10, duration: 5 }],
          dynamicEvents: [{ kind: "skirmish", lane: 1, time: 12 }],
          evacuation: { time: 15, lane: 2, duration: 10 },
          rewardBonus: 0,
          duration: 30
        }
      ]
    };
    const summary = summarize(config);
    expect(summary).toContain("wave-1");
    expect(summary).toContain("hazards=1");
    expect(summary).toContain("evac");
  });

  test("validateConfig rejects bad config", async () => {
    const configPath = path.join(process.cwd(), "temp-wave-invalid.json");
    await fs.writeFile(
      configPath,
      JSON.stringify({
        waves: [{ id: "bad", duration: -1, rewardBonus: 0, spawns: [] }]
      }),
      "utf8"
    );
    await expect(
      validateConfig(configPath, SCHEMA_PATH)
    ).rejects.toThrow(/failed validation/i);
    await fs.unlink(configPath);
  });
});
