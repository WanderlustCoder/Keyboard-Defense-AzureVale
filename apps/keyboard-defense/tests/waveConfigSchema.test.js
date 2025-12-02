import { describe, expect, test } from "vitest";
import Ajv from "ajv";
import addFormats from "ajv-formats";
import schema from "../schemas/wave-config.schema.json";

const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);
const validate = ajv.compile(schema);

describe("wave-config.schema.json", () => {
  test("accepts a valid wave config with hazards, dynamic, evacuation, boss flag", () => {
    const sample = {
      featureToggles: {
        dynamicSpawns: true,
        eliteAffixes: true,
        evacuationEvents: true,
        bossMechanics: true
      },
      enemyTiers: ["grunt", "runner", "archivist"],
      turretSlots: [{ id: "slot-1", lane: 0, unlockWave: 0 }],
      waves: [
        {
          id: "wave-1",
          duration: 30,
          rewardBonus: 0,
          spawns: [
            { at: 0, lane: 0, tierId: "grunt", count: 3, cadence: 1.5, affixes: ["shielded"] }
          ],
          hazards: [{ kind: "fog", lane: 0, time: 10, duration: 8, fireRateMultiplier: 0.9 }],
          dynamicEvents: [{ kind: "shield-carrier", lane: 1, time: 12, tierId: "runner", order: 1000 }],
          evacuation: { time: 15, lane: 2, duration: 12, word: "evacuation" }
        },
        {
          id: "wave-2",
          duration: 45,
          rewardBonus: 10,
          spawns: [{ at: 4, lane: 1, tierId: "runner", count: 2, cadence: 2 }],
          boss: true
        }
      ]
    };
    const valid = validate(sample);
    expect(validate.errors ?? []).toEqual([]);
    expect(valid).toBe(true);
  });

  test("rejects invalid wave config missing required fields", () => {
    const bad = {
      waves: [
        {
          id: "",
          duration: -1,
          rewardBonus: 0,
          spawns: []
        }
      ]
    };
    const valid = validate(bad);
    expect(valid).toBe(false);
    expect(validate.errors?.length).toBeGreaterThan(0);
  });
});
