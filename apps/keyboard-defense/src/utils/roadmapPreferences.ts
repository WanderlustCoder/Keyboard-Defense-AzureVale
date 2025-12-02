export interface RoadmapFilterPreferences {
  story: boolean;
  systems: boolean;
  challenge: boolean;
  lore: boolean;
  completed: boolean;
}

export interface RoadmapPreferences {
  trackedId: string | null;
  filters: RoadmapFilterPreferences;
}

export const ROADMAP_PREFS_KEY = "keyboard-defense:season-roadmap";

const DEFAULT_FILTERS: RoadmapFilterPreferences = {
  story: true,
  systems: true,
  challenge: true,
  lore: true,
  completed: false
};

export const DEFAULT_ROADMAP_PREFERENCES: RoadmapPreferences = {
  trackedId: null,
  filters: { ...DEFAULT_FILTERS }
};

function normalizeFilters(filters: Partial<RoadmapFilterPreferences> | undefined): RoadmapFilterPreferences {
  return {
    story: filters?.story !== false,
    systems: filters?.systems !== false,
    challenge: filters?.challenge !== false,
    lore: filters?.lore !== false,
    completed: filters?.completed === true
  };
}

export function readRoadmapPreferences(
  storage: Storage | null | undefined
): RoadmapPreferences {
  if (!storage) return { ...DEFAULT_ROADMAP_PREFERENCES, filters: { ...DEFAULT_FILTERS } };
  try {
    const raw = storage.getItem(ROADMAP_PREFS_KEY);
    if (!raw) {
      return { ...DEFAULT_ROADMAP_PREFERENCES, filters: { ...DEFAULT_FILTERS } };
    }
    const parsed = JSON.parse(raw);
    const trackedId =
      typeof parsed?.trackedId === "string" && parsed.trackedId.trim().length > 0
        ? parsed.trackedId
        : null;
    return {
      trackedId,
      filters: normalizeFilters(parsed?.filters)
    };
  } catch {
    return { ...DEFAULT_ROADMAP_PREFERENCES, filters: { ...DEFAULT_FILTERS } };
  }
}

export function writeRoadmapPreferences(
  storage: Storage | null | undefined,
  preferences: RoadmapPreferences
): void {
  if (!storage) return;
  const payload: RoadmapPreferences = {
    trackedId: preferences.trackedId ?? null,
    filters: normalizeFilters(preferences.filters)
  };
  try {
    storage.setItem(ROADMAP_PREFS_KEY, JSON.stringify(payload));
  } catch {
    // Swallow storage failures (e.g. private mode or quota).
  }
}

export function mergeRoadmapPreferences(
  current: RoadmapPreferences,
  patch: Partial<RoadmapPreferences>
): RoadmapPreferences {
  const nextFilters = normalizeFilters(patch.filters ?? current.filters);
  const trackedId =
    patch.trackedId === undefined ? current.trackedId : patch.trackedId ?? null;
  return {
    trackedId,
    filters: nextFilters
  };
}
