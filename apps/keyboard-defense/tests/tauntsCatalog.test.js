import { describe, it, expect } from "vitest";

import { TAUNT_CATALOG, getTauntEntry, getTauntText } from "../src/data/taunts.js";
import {
  loadCatalog,
  validateCatalogEntries
} from "../scripts/taunts/validateCatalog.mjs";

describe("taunt catalog", () => {
  it("exposes catalog entries with text", () => {
    expect(TAUNT_CATALOG.length).toBeGreaterThanOrEqual(5);
    const entry = getTauntEntry("boss_archivist_intro");
    expect(entry?.text).toMatch(/Archivist/i);
    expect(getTauntText("boss_archivist_phase2")).toMatch(/Lyra/i);
    expect(getTauntText("unknown-taunt")).toBe("[[unknown-taunt]]");
  });

  it("validateCatalogEntries catches duplicate ids", async () => {
    const entries = await loadCatalog("docs/taunts/catalog.json");
    const { errors } = validateCatalogEntries(entries);
    expect(errors).toHaveLength(0);
    const broken = [...entries, { ...entries[0] }];
    const duplicate = validateCatalogEntries(broken);
    expect(duplicate.errors.some((error) => error.includes("Duplicate taunt id"))).toBe(true);
  });
});
