import { describe, expect, test } from "vitest";
import { selectAmbientProfile } from "../src/audio/ambientProfiles.ts";

describe("selectAmbientProfile", () => {
  test("starts calm and ramps to rising then siege", () => {
    expect(selectAmbientProfile(0, 4, 1)).toBe("calm");
    expect(selectAmbientProfile(1, 4, 1)).toBe("rising");
    expect(selectAmbientProfile(3, 4, 1)).toBe("siege");
  });

  test("forces dire when health is low regardless of wave", () => {
    expect(selectAmbientProfile(0, 4, 0.3)).toBe("dire");
    expect(selectAmbientProfile(2, 4, 0.2)).toBe("dire");
  });

  test("handles missing values safely", () => {
    expect(selectAmbientProfile(null, null, null)).toBe("calm");
    expect(selectAmbientProfile(undefined, 0, 0.9)).toBe("calm");
  });
});
