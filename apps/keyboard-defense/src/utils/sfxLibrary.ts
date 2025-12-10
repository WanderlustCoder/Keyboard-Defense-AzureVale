const STORAGE_KEY = "keyboard-defense:sfx-library";

export const SFX_SAMPLE_KEYS = [
  "projectile-arrow",
  "projectile-arcane",
  "projectile-flame",
  "impact-hit",
  "impact-breach",
  "upgrade"
] as const;

export type SfxSampleKey = (typeof SFX_SAMPLE_KEYS)[number];

export type SfxLibraryId = "classic" | "arcade" | "ember" | "crystal" | "paper";

export type SfxPatch = {
  wave: "tone" | "noise" | "hybrid";
  duration: number;
  frequency?: number;
  rising?: boolean;
  falloff?: number;
  mix?: number;
  volume: number;
};

export type SfxLibraryDefinition = {
  id: SfxLibraryId;
  name: string;
  accent: string;
  vibe: string;
  summary: string;
  tags: string[];
  focus: string;
  preview: SfxSampleKey[];
  stingers: { victory: number; defeat: number };
  patches: Record<SfxSampleKey, SfxPatch>;
};

export type SfxLibraryState = {
  activeId: SfxLibraryId;
  auditioned: SfxLibraryId[];
  updatedAt: string | null;
};

export type SfxLibraryViewEntry = {
  id: SfxLibraryId;
  name: string;
  accent: string;
  vibe: string;
  summary: string;
  tags: string[];
  focus: string;
  preview: SfxSampleKey[];
  active: boolean;
  auditioned: boolean;
};

export type SfxLibraryViewState = {
  activeId: SfxLibraryId;
  updatedAt: string | null;
  entries: SfxLibraryViewEntry[];
};

const DEFAULT_STATE: SfxLibraryState = {
  activeId: "classic",
  auditioned: [],
  updatedAt: null
};

const LIBRARY: SfxLibraryDefinition[] = [
  {
    id: "classic",
    name: "Classic Mix",
    accent: "#22c55e",
    vibe: "Balanced",
    summary: "Bright bows, crisp hits, and the default castle upgrade chime.",
    tags: ["Balanced", "Readable", "Default"],
    focus: "Keeps the original Keyboard Defense palette intact.",
    preview: ["projectile-arrow", "impact-hit", "upgrade"],
    stingers: { victory: 440, defeat: 196 },
    patches: {
      "projectile-arrow": { wave: "tone", duration: 0.18, frequency: 880, volume: 0.6 },
      "projectile-arcane": { wave: "tone", duration: 0.22, frequency: 1320, volume: 0.55 },
      "projectile-flame": { wave: "noise", duration: 0.25, falloff: 0.05, volume: 0.7 },
      "impact-hit": { wave: "tone", duration: 0.15, frequency: 520, volume: 0.8 },
      "impact-breach": { wave: "noise", duration: 0.3, falloff: 0.12, volume: 1 },
      upgrade: { wave: "tone", duration: 0.35, frequency: 960, rising: true, volume: 0.8 }
    }
  },
  {
    id: "arcade",
    name: "Arcade Spark",
    accent: "#fb7185",
    vibe: "Snappy",
    summary: "Tighter envelopes, higher pitches, and a punchy breach burst.",
    tags: ["Bright", "Snappy", "Short tail"],
    focus: "Good for noisy rooms or when you want quick readbacks.",
    preview: ["projectile-arcane", "impact-breach", "upgrade"],
    stingers: { victory: 520, defeat: 240 },
    patches: {
      "projectile-arrow": { wave: "tone", duration: 0.14, frequency: 1050, volume: 0.72 },
      "projectile-arcane": {
        wave: "tone",
        duration: 0.17,
        frequency: 1500,
        rising: true,
        volume: 0.65
      },
      "projectile-flame": { wave: "noise", duration: 0.18, falloff: 0.08, volume: 0.75 },
      "impact-hit": {
        wave: "hybrid",
        duration: 0.14,
        frequency: 680,
        mix: 0.35,
        volume: 0.85
      },
      "impact-breach": { wave: "noise", duration: 0.24, falloff: 0.16, volume: 1 },
      upgrade: {
        wave: "hybrid",
        duration: 0.28,
        frequency: 1240,
        rising: true,
        mix: 0.2,
        volume: 0.9
      }
    }
  },
  {
    id: "ember",
    name: "Ember Forge",
    accent: "#f97316",
    vibe: "Warm",
    summary: "Heavier wooden thunks with ember crackle for flame shots.",
    tags: ["Warm", "Chunky", "Mid focus"],
    focus: "Great for comfort play or when you want weight behind impacts.",
    preview: ["impact-hit", "projectile-flame", "projectile-arrow"],
    stingers: { victory: 392, defeat: 175 },
    patches: {
      "projectile-arrow": { wave: "tone", duration: 0.2, frequency: 640, volume: 0.7 },
      "projectile-arcane": {
        wave: "hybrid",
        duration: 0.24,
        frequency: 880,
        mix: 0.25,
        rising: true,
        volume: 0.65
      },
      "projectile-flame": {
        wave: "hybrid",
        duration: 0.3,
        frequency: 520,
        mix: 0.5,
        falloff: 0.12,
        volume: 0.9
      },
      "impact-hit": { wave: "tone", duration: 0.17, frequency: 420, volume: 0.95 },
      "impact-breach": { wave: "noise", duration: 0.32, falloff: 0.1, volume: 1 },
      upgrade: { wave: "tone", duration: 0.38, frequency: 720, rising: true, volume: 0.85 }
    }
  },
  {
    id: "crystal",
    name: "Crystal Bloom",
    accent: "#38bdf8",
    vibe: "Glass",
    summary: "Airy chimes with subtle shimmer and softer breach noise.",
    tags: ["Airy", "Glassy", "Soft edges"],
    focus: "Pairs well with night palettes or calmer runs.",
    preview: ["projectile-arrow", "impact-hit", "upgrade"],
    stingers: { victory: 660, defeat: 260 },
    patches: {
      "projectile-arrow": {
        wave: "tone",
        duration: 0.16,
        frequency: 960,
        rising: true,
        volume: 0.58
      },
      "projectile-arcane": {
        wave: "hybrid",
        duration: 0.24,
        frequency: 1400,
        mix: 0.18,
        rising: true,
        volume: 0.65
      },
      "projectile-flame": { wave: "noise", duration: 0.26, falloff: 0.05, volume: 0.68 },
      "impact-hit": { wave: "tone", duration: 0.16, frequency: 640, volume: 0.78 },
      "impact-breach": {
        wave: "hybrid",
        duration: 0.28,
        frequency: 520,
        mix: 0.4,
        volume: 0.92
      },
      upgrade: { wave: "tone", duration: 0.33, frequency: 1280, rising: true, volume: 0.82 }
    }
  },
  {
    id: "paper",
    name: "Paper Quiet",
    accent: "#a8a29e",
    vibe: "Soft",
    summary: "Muffled envelopes with lower peaks and shorter tails.",
    tags: ["Quiet", "Comfort", "Low fatigue"],
    focus: "Fallback when you need the lightest touch during focus drills.",
    preview: ["projectile-flame", "impact-hit", "upgrade"],
    stingers: { victory: 360, defeat: 150 },
    patches: {
      "projectile-arrow": { wave: "tone", duration: 0.16, frequency: 520, volume: 0.45 },
      "projectile-arcane": {
        wave: "hybrid",
        duration: 0.2,
        frequency: 780,
        mix: 0.15,
        volume: 0.5
      },
      "projectile-flame": { wave: "noise", duration: 0.22, falloff: 0.07, volume: 0.55 },
      "impact-hit": {
        wave: "tone",
        duration: 0.13,
        frequency: 360,
        volume: 0.6
      },
      "impact-breach": { wave: "noise", duration: 0.22, falloff: 0.12, volume: 0.72 },
      upgrade: {
        wave: "tone",
        duration: 0.24,
        frequency: 620,
        rising: true,
        volume: 0.65
      }
    }
  }
];

function normalizeLibraryId(value: unknown): SfxLibraryId {
  return LIBRARY.some((entry) => entry.id === value) ? (value as SfxLibraryId) : "classic";
}

export function getSfxLibraryDefinition(id: SfxLibraryId): SfxLibraryDefinition {
  return LIBRARY.find((entry) => entry.id === id) ?? LIBRARY[0];
}

export function readSfxLibraryState(storage: Storage | null | undefined): SfxLibraryState {
  if (!storage) return { ...DEFAULT_STATE };
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_STATE };
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return { ...DEFAULT_STATE };
    const activeId = normalizeLibraryId((parsed as Record<string, unknown>).activeId);
    const rawAuditioned = Array.isArray((parsed as Record<string, unknown>).auditioned)
      ? ((parsed as Record<string, unknown>).auditioned as unknown[])
      : [];
    const auditioned: SfxLibraryId[] = [];
    for (const id of rawAuditioned) {
      if (LIBRARY.some((entry) => entry.id === id)) {
        auditioned.push(id as SfxLibraryId);
      }
    }
    const updatedAt =
      typeof (parsed as Record<string, unknown>).updatedAt === "string"
        ? ((parsed as Record<string, unknown>).updatedAt as string)
        : null;
    return { activeId, auditioned, updatedAt };
  } catch {
    return { ...DEFAULT_STATE };
  }
}

export function writeSfxLibraryState(
  storage: Storage | null | undefined,
  state: SfxLibraryState
): void {
  if (!storage) return;
  storage.setItem(
    STORAGE_KEY,
    JSON.stringify({
      activeId: normalizeLibraryId(state?.activeId),
      auditioned: Array.isArray(state?.auditioned)
        ? state.auditioned.filter((id) => LIBRARY.some((entry) => entry.id === id))
        : [],
      updatedAt: state?.updatedAt ?? new Date().toISOString()
    })
  );
}

export function setActiveSfxLibrary(
  state: SfxLibraryState,
  libraryId: SfxLibraryId
): SfxLibraryState {
  const nextId = normalizeLibraryId(libraryId);
  return {
    activeId: nextId,
    auditioned: state.auditioned ?? [],
    updatedAt: new Date().toISOString()
  };
}

export function markSfxLibraryAudition(
  state: SfxLibraryState,
  libraryId: SfxLibraryId
): SfxLibraryState {
  const nextId = normalizeLibraryId(libraryId);
  const nextAuditioned = new Set(state?.auditioned ?? []);
  nextAuditioned.add(nextId);
  return {
    activeId: state?.activeId ?? "classic",
    auditioned: Array.from(nextAuditioned),
    updatedAt: new Date().toISOString()
  };
}

export function buildSfxLibraryView(state: SfxLibraryState): SfxLibraryViewState {
  const activeId = normalizeLibraryId(state?.activeId);
  const auditioned = new Set(state?.auditioned ?? []);
  return {
    activeId,
    updatedAt: state?.updatedAt ?? null,
    entries: LIBRARY.map((entry) => ({
      id: entry.id,
      name: entry.name,
      accent: entry.accent,
      vibe: entry.vibe,
      summary: entry.summary,
      tags: entry.tags,
      focus: entry.focus,
      preview: entry.preview,
      active: entry.id === activeId,
      auditioned: auditioned.has(entry.id)
    }))
  };
}

export { LIBRARY as SFX_LIBRARY };
