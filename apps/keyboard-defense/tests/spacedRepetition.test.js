import { describe, expect, test } from "vitest";

import {
  computeSpacedRepetitionGrade,
  createDefaultSpacedRepetitionState,
  listDueSpacedRepetitionPatterns,
  recordSpacedRepetitionObservedStats,
  recordSpacedRepetitionReview
} from "../src/utils/spacedRepetition.ts";

describe("spacedRepetition", () => {
  test("computeSpacedRepetitionGrade maps accuracy into grades", () => {
    expect(computeSpacedRepetitionGrade({ attempts: 10, errors: 0 })).toBe(5);
    expect(computeSpacedRepetitionGrade({ attempts: 100, errors: 2 })).toBe(4);
    expect(computeSpacedRepetitionGrade({ attempts: 10, errors: 1 })).toBe(3);
    expect(computeSpacedRepetitionGrade({ attempts: 10, errors: 2 })).toBe(2);
    expect(computeSpacedRepetitionGrade({ attempts: 10, errors: 3 })).toBe(1);
    expect(computeSpacedRepetitionGrade({ attempts: 10, errors: 4 })).toBe(1);
    expect(computeSpacedRepetitionGrade({ attempts: 10, errors: 5 })).toBe(1);
    expect(computeSpacedRepetitionGrade({ attempts: 0, errors: 0 })).toBeNull();
  });

  test("recordSpacedRepetitionReview schedules a due time in the future", () => {
    const base = createDefaultSpacedRepetitionState();
    const next = recordSpacedRepetitionReview(base, {
      kind: "key",
      pattern: "a",
      grade: 1,
      nowMs: 1_000_000
    });
    const item = next.items["key:a"];
    expect(item).toBeTruthy();
    expect(item.pattern).toBe("a");
    expect(item.dueAtMs).toBeGreaterThan(1_000_000);
    const due = listDueSpacedRepetitionPatterns(next, { nowMs: item.dueAtMs + 1, limit: 5 });
    expect(due).toContain("a");
  });

  test("recordSpacedRepetitionObservedStats only creates new items when errors occur", () => {
    const base = createDefaultSpacedRepetitionState();
    const noError = recordSpacedRepetitionObservedStats(base, {
      keys: { a: { attempts: 6, errors: 0 } }
    }, { nowMs: 1000 });
    expect(Object.keys(noError.items).length).toBe(0);

    const withError = recordSpacedRepetitionObservedStats(base, {
      keys: { a: { attempts: 6, errors: 2 } },
      digraphs: { th: { attempts: 4, errors: 1 } }
    }, { nowMs: 1000 });
    expect(withError.items["key:a"]).toBeTruthy();
    expect(withError.items["digraph:th"]).toBeTruthy();
  });
});
