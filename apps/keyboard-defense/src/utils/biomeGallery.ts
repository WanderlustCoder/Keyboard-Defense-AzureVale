import { type TypingDrillSummary } from "../core/types.js";

const STORAGE_KEY = "keyboard-defense:biome-gallery";
export const BIOME_GALLERY_VERSION = "v1";

export type BiomeId =
  | "mossy-ruins"
  | "ember-forge"
  | "glacier-ridge"
  | "tidepool-bay"
  | "aurora-steppe";

export type BiomePalette = {
  sky: string;
  mid: string;
  ground: string;
  accent: string;
};

export type BiomeDefinition = {
  id: BiomeId;
  name: string;
  tagline: string;
  focus: string;
  tags: string[];
  palette: BiomePalette;
  difficulty: "calm" | "steady" | "spiky";
};

export type BiomeProgressEntry = {
  runs: number;
  lessons: number;
  drills: number;
  bestWpm: number;
  bestAccuracy: number;
  bestCombo: number;
  lastPlayedAt: string | null;
};

export type BiomeGalleryProgress = {
  version: string;
  activeBiomeId: BiomeId;
  biomes: Record<BiomeId, BiomeProgressEntry>;
  updatedAt: string | null;
};

export type BiomeGalleryCard = {
  id: BiomeId;
  name: string;
  tagline: string;
  focus: string;
  tags: string[];
  palette: BiomePalette;
  difficulty: string;
  isActive: boolean;
  stats: {
    runs: number;
    lessons: number;
    drills: number;
    bestWpm: number;
    bestAccuracy: number;
    bestCombo: number;
    lastPlayedAt: string | null;
    heat: number;
  };
};

export type BiomeGalleryViewState = {
  activeId: BiomeId;
  updatedAt: string | null;
  cards: BiomeGalleryCard[];
};

const BIOME_DEFINITIONS: BiomeDefinition[] = [
  {
    id: "mossy-ruins",
    name: "Mossy Ruins",
    tagline: "Overgrown battlements with calm tempo.",
    focus: "Accuracy first",
    tags: ["rhythm", "steady spawn"],
    palette: { sky: "#1d3557", mid: "#315c6e", ground: "#223944", accent: "#9ef0a0" },
    difficulty: "calm"
  },
  {
    id: "ember-forge",
    name: "Ember Forge",
    tagline: "Volcanic glow and quicker bursts.",
    focus: "Speed spikes",
    tags: ["burst", "tempo shifts"],
    palette: { sky: "#2b1b2f", mid: "#4a243b", ground: "#2f1a24", accent: "#ff7a3d" },
    difficulty: "spiky"
  },
  {
    id: "glacier-ridge",
    name: "Glacier Ridge",
    tagline: "Crystal caverns with high contrast ice.",
    focus: "Precision",
    tags: ["clean lines", "long words"],
    palette: { sky: "#0f2439", mid: "#1c3a52", ground: "#0b1b2c", accent: "#6ee7ff" },
    difficulty: "steady"
  },
  {
    id: "tidepool-bay",
    name: "Tidepool Bay",
    tagline: "Sunset harbor with flowing enemies.",
    focus: "Combo retention",
    tags: ["combo", "sustain"],
    palette: { sky: "#14213d", mid: "#23395b", ground: "#102132", accent: "#fbbf24" },
    difficulty: "steady"
  },
  {
    id: "aurora-steppe",
    name: "Aurora Steppe",
    tagline: "Wide-open skies with drifting auroras.",
    focus: "Endurance",
    tags: ["long runs", "reduced clutter"],
    palette: { sky: "#0b1c2c", mid: "#123049", ground: "#0a1823", accent: "#a78bfa" },
    difficulty: "calm"
  }
];

const DEFAULT_PROGRESS_ENTRY: BiomeProgressEntry = {
  runs: 0,
  lessons: 0,
  drills: 0,
  bestWpm: 0,
  bestAccuracy: 0,
  bestCombo: 0,
  lastPlayedAt: null
};

const DEFAULT_PROGRESS: BiomeGalleryProgress = {
  version: BIOME_GALLERY_VERSION,
  activeBiomeId: BIOME_DEFINITIONS[0].id,
  biomes: BIOME_DEFINITIONS.reduce((map, biome) => {
    map[biome.id] = { ...DEFAULT_PROGRESS_ENTRY };
    return map;
  }, {} as Record<BiomeId, BiomeProgressEntry>),
  updatedAt: null
};

function clampRatio(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

function clampNonNegative(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, value);
}

function normalizeBiomeId(value: unknown): BiomeId {
  if (value === "ember-forge") return "ember-forge";
  if (value === "glacier-ridge") return "glacier-ridge";
  if (value === "tidepool-bay") return "tidepool-bay";
  if (value === "aurora-steppe") return "aurora-steppe";
  return "mossy-ruins";
}

function normalizeEntry(raw: unknown): BiomeProgressEntry {
  if (!raw || typeof raw !== "object") return { ...DEFAULT_PROGRESS_ENTRY };
  const data = raw as Record<string, unknown>;
  const lastPlayedAt =
    typeof data.lastPlayedAt === "string" && data.lastPlayedAt.length > 0
      ? data.lastPlayedAt
      : null;
  return {
    runs: clampNonNegative(data.runs),
    lessons: clampNonNegative(data.lessons),
    drills: clampNonNegative(data.drills),
    bestWpm: clampNonNegative(data.bestWpm),
    bestAccuracy: clampRatio(data.bestAccuracy),
    bestCombo: clampNonNegative(data.bestCombo),
    lastPlayedAt
  };
}

function ensureProgress(base: BiomeGalleryProgress | null | undefined): BiomeGalleryProgress {
  const activeBiomeId = normalizeBiomeId(base?.activeBiomeId);
  const updatedAt =
    typeof base?.updatedAt === "string" && base.updatedAt.length > 0 ? base.updatedAt : null;
  const biomes: Record<BiomeId, BiomeProgressEntry> = { ...DEFAULT_PROGRESS.biomes };
  if (base?.biomes && typeof base.biomes === "object") {
    for (const key of Object.keys(base.biomes)) {
      const id = normalizeBiomeId(key);
      biomes[id] = normalizeEntry((base.biomes as Record<string, unknown>)[key]);
    }
  }
  return {
    version: BIOME_GALLERY_VERSION,
    activeBiomeId,
    biomes,
    updatedAt
  };
}

export function readBiomeGallery(storage: Storage | null | undefined): BiomeGalleryProgress {
  if (!storage) return { ...DEFAULT_PROGRESS, biomes: { ...DEFAULT_PROGRESS.biomes } };
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_PROGRESS, biomes: { ...DEFAULT_PROGRESS.biomes } };
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") {
      return { ...DEFAULT_PROGRESS, biomes: { ...DEFAULT_PROGRESS.biomes } };
    }
    if (parsed.version !== BIOME_GALLERY_VERSION) {
      return { ...DEFAULT_PROGRESS, biomes: { ...DEFAULT_PROGRESS.biomes } };
    }
    return ensureProgress(parsed as BiomeGalleryProgress);
  } catch {
    return { ...DEFAULT_PROGRESS, biomes: { ...DEFAULT_PROGRESS.biomes } };
  }
}

export function writeBiomeGallery(
  storage: Storage | null | undefined,
  progress: BiomeGalleryProgress
): void {
  if (!storage) return;
  const payload = JSON.stringify(progress);
  storage.setItem(STORAGE_KEY, payload);
}

export function setActiveBiome(
  progress: BiomeGalleryProgress | null | undefined,
  biomeId: BiomeId
): BiomeGalleryProgress {
  const base = ensureProgress(progress);
  const nextId = normalizeBiomeId(biomeId);
  if (base.activeBiomeId === nextId) {
    return base;
  }
  return {
    ...base,
    activeBiomeId: nextId,
    updatedAt: new Date().toISOString()
  };
}

export function recordBiomeRun(
  progress: BiomeGalleryProgress | null | undefined,
  summary: TypingDrillSummary,
  delta?: { lessons?: number; drills?: number }
): { progress: BiomeGalleryProgress; activeId: BiomeId } {
  const base = ensureProgress(progress);
  const activeId = base.activeBiomeId ?? DEFAULT_PROGRESS.activeBiomeId;
  const entry = { ...(base.biomes[activeId] ?? DEFAULT_PROGRESS_ENTRY) };
  entry.runs += 1;
  entry.lessons += Math.max(0, delta?.lessons ?? 0);
  entry.drills += Math.max(0, delta?.drills ?? 1);
  entry.bestWpm = Math.max(entry.bestWpm, clampNonNegative(summary?.wpm));
  entry.bestAccuracy = Math.max(entry.bestAccuracy, clampRatio(summary?.accuracy));
  entry.bestCombo = Math.max(entry.bestCombo, clampNonNegative(summary?.bestCombo));
  entry.lastPlayedAt = new Date(summary?.timestamp ?? Date.now()).toISOString();
  const updatedAt = entry.lastPlayedAt;
  return {
    progress: {
      version: BIOME_GALLERY_VERSION,
      activeBiomeId: activeId,
      updatedAt,
      biomes: {
        ...base.biomes,
        [activeId]: entry
      }
    },
    activeId
  };
}

export function buildBiomeGalleryView(progress: BiomeGalleryProgress): BiomeGalleryViewState {
  const safe = ensureProgress(progress);
  const cards: BiomeGalleryCard[] = [];
  for (const def of BIOME_DEFINITIONS) {
    const stats = safe.biomes[def.id] ?? { ...DEFAULT_PROGRESS_ENTRY };
    const totalSessions = stats.runs + stats.lessons + stats.drills;
    const heat = Math.max(0, Math.min(1, totalSessions / 12));
    cards.push({
      id: def.id,
      name: def.name,
      tagline: def.tagline,
      focus: def.focus,
      tags: def.tags,
      palette: def.palette,
      difficulty: def.difficulty,
      isActive: safe.activeBiomeId === def.id,
      stats: {
        ...stats,
        heat
      }
    });
  }
  return {
    activeId: safe.activeBiomeId,
    updatedAt: safe.updatedAt,
    cards
  };
}
