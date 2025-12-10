const STORAGE_KEY = "keyboard-defense:music-stems";

export const MUSIC_LAYERS = ["bed", "pulse", "tension"] as const;
export const MUSIC_PROFILES = ["calm", "rising", "siege", "dire"] as const;

export type MusicStemLayer = (typeof MUSIC_LAYERS)[number];
export type MusicProfile = (typeof MUSIC_PROFILES)[number];
export type MusicStemId = "siege-suite" | "pulse-driver" | "ember-mosaic";

export type MusicStemLayerSpec = {
  baseFreq: number;
  spread: number;
  modFreq?: number;
  noise?: number;
  pulseEvery?: number;
  pulseDecay?: number;
  pulseNoise?: number;
  length?: number;
};

export type MusicStemDefinition = {
  id: MusicStemId;
  name: string;
  accent: string;
  vibe: string;
  summary: string;
  focus: string;
  tags: string[];
  layers: Record<MusicStemLayer, MusicStemLayerSpec>;
  profileGains: Record<MusicProfile, Record<MusicStemLayer, number>>;
  previewProfile: MusicProfile;
};

export type MusicStemState = {
  activeId: MusicStemId;
  auditioned: MusicStemId[];
  dynamicEnabled: boolean;
  updatedAt: string | null;
};

export type MusicStemViewEntry = {
  id: MusicStemId;
  name: string;
  accent: string;
  vibe: string;
  summary: string;
  focus: string;
  tags: string[];
  previewProfile: MusicProfile;
  mixSummary: string;
  active: boolean;
  auditioned: boolean;
};

export type MusicStemViewState = {
  activeId: MusicStemId;
  dynamicEnabled: boolean;
  updatedAt: string | null;
  entries: MusicStemViewEntry[];
};

const DEFAULT_STATE: MusicStemState = {
  activeId: "siege-suite",
  auditioned: [],
  dynamicEnabled: true,
  updatedAt: null
};

const SUITES: MusicStemDefinition[] = [
  {
    id: "siege-suite",
    name: "Siege Suite",
    accent: "#f43f5e",
    vibe: "Cinematic",
    summary: "Layered choirs and low brass pulses that swell as waves intensify.",
    focus: "Keeps tension visible without overpowering typing sounds.",
    tags: ["Orchestral", "Layered", "Drama"],
    previewProfile: "siege",
    layers: {
      bed: { baseFreq: 180, spread: 3.4, modFreq: 0.18, noise: 0.015, length: 6.5 },
      pulse: { baseFreq: 420, spread: 2.2, modFreq: 0.38, pulseEvery: 0.66, pulseDecay: 0.35 },
      tension: { baseFreq: 140, spread: 4.8, modFreq: 0.14, noise: 0.04, length: 5.5 }
    },
    profileGains: {
      calm: { bed: 0.35, pulse: 0.05, tension: 0.08 },
      rising: { bed: 0.55, pulse: 0.24, tension: 0.16 },
      siege: { bed: 0.68, pulse: 0.42, tension: 0.3 },
      dire: { bed: 0.6, pulse: 0.56, tension: 0.48 }
    }
  },
  {
    id: "pulse-driver",
    name: "Pulse Driver",
    accent: "#22c55e",
    vibe: "Modern",
    summary: "Synth plucks, sidechain swells, and clean percussion for focused runs.",
    focus: "Stays light in calm moments and ramps up with clean, bright pulses.",
    tags: ["Electronic", "Tight", "Uplifting"],
    previewProfile: "rising",
    layers: {
      bed: { baseFreq: 260, spread: 2.6, modFreq: 0.24, noise: 0.01, length: 5.2 },
      pulse: {
        baseFreq: 620,
        spread: 1.8,
        modFreq: 0.5,
        pulseEvery: 0.5,
        pulseDecay: 0.28,
        pulseNoise: 0.06
      },
      tension: { baseFreq: 210, spread: 3.2, modFreq: 0.16, noise: 0.05, length: 4.8 }
    },
    profileGains: {
      calm: { bed: 0.32, pulse: 0.12, tension: 0.06 },
      rising: { bed: 0.5, pulse: 0.32, tension: 0.16 },
      siege: { bed: 0.58, pulse: 0.46, tension: 0.26 },
      dire: { bed: 0.48, pulse: 0.54, tension: 0.4 }
    }
  },
  {
    id: "ember-mosaic",
    name: "Ember Mosaic",
    accent: "#fb923c",
    vibe: "Warm",
    summary: "Wooden percussion, ember crackle, and soft strings for comfort nights.",
    focus: "Stays mellow for drills and adds gentle grit when waves heat up.",
    tags: ["Warm", "Gentle", "Comfort"],
    previewProfile: "calm",
    layers: {
      bed: { baseFreq: 200, spread: 2.9, modFreq: 0.2, noise: 0.02, length: 6.2 },
      pulse: {
        baseFreq: 360,
        spread: 1.6,
        modFreq: 0.28,
        pulseEvery: 0.72,
        pulseDecay: 0.32,
        pulseNoise: 0.08
      },
      tension: { baseFreq: 170, spread: 3.8, modFreq: 0.12, noise: 0.06, length: 5.4 }
    },
    profileGains: {
      calm: { bed: 0.4, pulse: 0.08, tension: 0.06 },
      rising: { bed: 0.54, pulse: 0.24, tension: 0.14 },
      siege: { bed: 0.6, pulse: 0.36, tension: 0.22 },
      dire: { bed: 0.54, pulse: 0.44, tension: 0.34 }
    }
  }
];

function normalizeStemId(value: unknown): MusicStemId {
  return SUITES.some((entry) => entry.id === value) ? (value as MusicStemId) : SUITES[0].id;
}

function normalizeProfile(value: unknown): MusicProfile {
  return MUSIC_PROFILES.includes(value as MusicProfile) ? (value as MusicProfile) : "calm";
}

export function getMusicStemDefinition(id: MusicStemId): MusicStemDefinition {
  return SUITES.find((entry) => entry.id === id) ?? SUITES[0];
}

export function resolveMusicProfileGains(
  definition: MusicStemDefinition,
  profile: MusicProfile
): Record<MusicStemLayer, number> {
  const safeProfile = normalizeProfile(profile);
  return definition.profileGains[safeProfile] ?? definition.profileGains.calm;
}

export function readMusicStemState(storage: Storage | null | undefined): MusicStemState {
  if (!storage) return { ...DEFAULT_STATE };
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_STATE };
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return { ...DEFAULT_STATE };
    const activeId = normalizeStemId((parsed as Record<string, unknown>).activeId);
    const dynamicEnabled =
      typeof (parsed as Record<string, unknown>).dynamicEnabled === "boolean"
        ? ((parsed as Record<string, unknown>).dynamicEnabled as boolean)
        : true;
    const auditionedRaw = Array.isArray((parsed as Record<string, unknown>).auditioned)
      ? ((parsed as Record<string, unknown>).auditioned as unknown[])
      : [];
    const auditioned: MusicStemId[] = [];
    for (const id of auditionedRaw) {
      if (SUITES.some((entry) => entry.id === id)) {
        auditioned.push(id as MusicStemId);
      }
    }
    const updatedAt =
      typeof (parsed as Record<string, unknown>).updatedAt === "string"
        ? ((parsed as Record<string, unknown>).updatedAt as string)
        : null;
    return { activeId, auditioned, dynamicEnabled, updatedAt };
  } catch {
    return { ...DEFAULT_STATE };
  }
}

export function writeMusicStemState(
  storage: Storage | null | undefined,
  state: MusicStemState
): void {
  if (!storage) return;
  const payload: MusicStemState = {
    activeId: normalizeStemId(state.activeId),
    auditioned: Array.from(new Set(state.auditioned ?? [])).filter((id) =>
      SUITES.some((entry) => entry.id === id)
    ) as MusicStemId[],
    dynamicEnabled: state.dynamicEnabled !== false,
    updatedAt: state.updatedAt ?? new Date().toISOString()
  };
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch {
    // ignore persistence failures
  }
}

export function setActiveMusicStem(state: MusicStemState, id: MusicStemId): MusicStemState {
  const normalized = normalizeStemId(id);
  const auditioned = Array.from(new Set([...(state.auditioned ?? []), normalized]));
  return {
    activeId: normalized,
    auditioned,
    dynamicEnabled: state.dynamicEnabled !== false,
    updatedAt: new Date().toISOString()
  };
}

export function markMusicStemAudition(state: MusicStemState, id: MusicStemId): MusicStemState {
  const normalized = normalizeStemId(id);
  const auditioned = Array.from(new Set([...(state.auditioned ?? []), normalized]));
  return {
    ...state,
    auditioned,
    updatedAt: new Date().toISOString()
  };
}

export function buildMusicStemView(state: MusicStemState): MusicStemViewState {
  const entries: MusicStemViewEntry[] = SUITES.map((entry) => {
    const gains = resolveMusicProfileGains(entry, entry.previewProfile);
    const mixSummary = `Calm ${Math.round(gains.bed * 100)}% · Pulse ${Math.round(
      gains.pulse * 100
    )}% · Tension ${Math.round(gains.tension * 100)}%`;
    return {
      id: entry.id,
      name: entry.name,
      accent: entry.accent,
      vibe: entry.vibe,
      summary: entry.summary,
      focus: entry.focus,
      tags: entry.tags,
      previewProfile: entry.previewProfile,
      mixSummary,
      active: entry.id === state.activeId,
      auditioned: state.auditioned.includes(entry.id)
    };
  });
  return {
    activeId: state.activeId,
    dynamicEnabled: state.dynamicEnabled !== false,
    updatedAt: state.updatedAt,
    entries
  };
}
