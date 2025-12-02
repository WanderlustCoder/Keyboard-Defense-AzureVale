import { describe, expect, it } from "vitest";

import {
  allDialogueIds,
  DIALOGUE_LYRA,
  getDialogue,
  listDialogueByStage
} from "../src/data/dialogue.ts";

const ALLOWED_STAGES = new Set([
  "intro",
  "phase-shift",
  "pressure",
  "breach-warning",
  "defeat",
  "victory"
]);

describe("Lyra dialogue catalog", () => {
  it("exposes all entries with required fields", () => {
    expect(DIALOGUE_LYRA.entries.length).toBeGreaterThanOrEqual(5);
    const ids = allDialogueIds();
    const uniqueIds = new Set(ids);
    expect(uniqueIds.size).toBe(ids.length);
    for (const entry of DIALOGUE_LYRA.entries) {
      expect(entry.id).toMatch(/^lyra_/);
      expect(entry.text.length).toBeGreaterThan(12);
      expect(ALLOWED_STAGES.has(entry.stage)).toBe(true);
    }
  });

  it("filters dialogue by stage", () => {
    const intro = listDialogueByStage("intro");
    expect(intro.length).toBeGreaterThanOrEqual(1);
    expect(intro[0].text).toMatch(/Azure Vale|Archivist/i);
  });

  it("returns undefined for unknown ids", () => {
    expect(getDialogue("unknown-id")).toBeUndefined();
  });
});
