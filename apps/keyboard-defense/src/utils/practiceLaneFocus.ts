export const PRACTICE_LANE_FOCUS_STORAGE_KEY = "keyboard-defense:practice-lane-focus";

function normalizeLane(value: unknown): number | null {
  if (value === null || value === undefined) return null;
  if (typeof value !== "number" || !Number.isFinite(value) || !Number.isInteger(value) || value < 0) {
    return null;
  }
  return value;
}

export function readPracticeLaneFocus(storage: Storage | null | undefined): number | null {
  if (!storage) return null;
  const raw = storage.getItem(PRACTICE_LANE_FOCUS_STORAGE_KEY);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    if (typeof parsed === "number") {
      return normalizeLane(parsed);
    }
    if (parsed && typeof parsed === "object") {
      return normalizeLane((parsed as Record<string, unknown>).lane);
    }
    return null;
  } catch {
    if (raw === "all") return null;
    const asNumber = Number.parseInt(raw, 10);
    if (Number.isFinite(asNumber)) {
      return normalizeLane(asNumber);
    }
    return null;
  }
}

export function writePracticeLaneFocus(
  storage: Storage | null | undefined,
  lane: number | null
): number | null {
  const normalized = normalizeLane(lane);
  if (!storage) return normalized;
  storage.setItem(PRACTICE_LANE_FOCUS_STORAGE_KEY, JSON.stringify({ lane: normalized }));
  return normalized;
}
