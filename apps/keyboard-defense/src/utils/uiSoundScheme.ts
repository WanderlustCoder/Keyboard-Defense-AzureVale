const STORAGE_KEY = "keyboard-defense:ui-sound-scheme";

export const UI_SAMPLE_KEYS = ["ui-open", "ui-select", "ui-back", "ui-alert"] as const;

export type UiSampleKey = (typeof UI_SAMPLE_KEYS)[number];
export type UiSchemeId = "clarity" | "pop" | "minimal";

export type UiPatch = {
  wave: "tone" | "noise" | "hybrid";
  duration: number;
  frequency?: number;
  rising?: boolean;
  falloff?: number;
  mix?: number;
  volume: number;
};

export type UiSchemeDefinition = {
  id: UiSchemeId;
  name: string;
  accent: string;
  vibe: string;
  summary: string;
  tags: string[];
  patches: Record<UiSampleKey, UiPatch>;
  preview: UiSampleKey[];
};

export type UiSchemeState = {
  activeId: UiSchemeId;
  auditioned: UiSchemeId[];
  updatedAt: string | null;
};

export type UiSchemeViewEntry = {
  id: UiSchemeId;
  name: string;
  accent: string;
  vibe: string;
  summary: string;
  tags: string[];
  preview: UiSampleKey[];
  active: boolean;
  auditioned: boolean;
};

export type UiSchemeViewState = {
  activeId: UiSchemeId;
  updatedAt: string | null;
  entries: UiSchemeViewEntry[];
};

const DEFAULT_STATE: UiSchemeState = {
  activeId: "clarity",
  auditioned: [],
  updatedAt: null
};

const SCHEMES: UiSchemeDefinition[] = [
  {
    id: "clarity",
    name: "Clarity",
    accent: "#38bdf8",
    vibe: "Clean",
    summary: "Airy clicks and subtle confirmations for modal actions.",
    tags: ["Clean", "Light", "Modal"],
    preview: ["ui-open", "ui-select", "ui-alert"],
    patches: {
      "ui-open": { wave: "tone", duration: 0.14, frequency: 1120, rising: true, volume: 0.5 },
      "ui-select": { wave: "tone", duration: 0.12, frequency: 920, volume: 0.55 },
      "ui-back": { wave: "tone", duration: 0.1, frequency: 520, volume: 0.45 },
      "ui-alert": { wave: "hybrid", duration: 0.22, frequency: 640, mix: 0.25, volume: 0.65 }
    }
  },
  {
    id: "pop",
    name: "Pop",
    accent: "#fb7185",
    vibe: "Lively",
    summary: "Bouncy pops with a hint of noise for button-heavy flows.",
    tags: ["Punchy", "Buttons", "Warm"],
    preview: ["ui-select", "ui-open", "ui-alert"],
    patches: {
      "ui-open": { wave: "hybrid", duration: 0.16, frequency: 820, mix: 0.18, volume: 0.6 },
      "ui-select": { wave: "tone", duration: 0.12, frequency: 980, rising: true, volume: 0.65 },
      "ui-back": { wave: "hybrid", duration: 0.14, frequency: 480, mix: 0.3, volume: 0.5 },
      "ui-alert": { wave: "noise", duration: 0.22, falloff: 0.16, volume: 0.75 }
    }
  },
  {
    id: "minimal",
    name: "Minimal",
    accent: "#a3a3a3",
    vibe: "Soft",
    summary: "Quiet ticks for late-night or low-distraction play.",
    tags: ["Quiet", "Low fatigue", "Late night"],
    preview: ["ui-open", "ui-select", "ui-back"],
    patches: {
      "ui-open": { wave: "tone", duration: 0.1, frequency: 720, volume: 0.35 },
      "ui-select": { wave: "tone", duration: 0.1, frequency: 860, rising: true, volume: 0.4 },
      "ui-back": { wave: "tone", duration: 0.1, frequency: 420, volume: 0.32 },
      "ui-alert": { wave: "hybrid", duration: 0.18, frequency: 520, mix: 0.2, volume: 0.48 }
    }
  }
];

function normalizeSchemeId(value: unknown): UiSchemeId {
  return SCHEMES.some((entry) => entry.id === value) ? (value as UiSchemeId) : "clarity";
}

export function getUiSchemeDefinition(id: UiSchemeId): UiSchemeDefinition {
  return SCHEMES.find((entry) => entry.id === id) ?? SCHEMES[0];
}

export function readUiSchemeState(storage: Storage | null | undefined): UiSchemeState {
  if (!storage) return { ...DEFAULT_STATE };
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_STATE };
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return { ...DEFAULT_STATE };
    const activeId = normalizeSchemeId((parsed as Record<string, unknown>).activeId);
    const auditionedRaw = Array.isArray((parsed as Record<string, unknown>).auditioned)
      ? ((parsed as Record<string, unknown>).auditioned as unknown[])
      : [];
    const auditioned: UiSchemeId[] = [];
    for (const id of auditionedRaw) {
      if (SCHEMES.some((entry) => entry.id === id)) {
        auditioned.push(id as UiSchemeId);
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

export function writeUiSchemeState(
  storage: Storage | null | undefined,
  state: UiSchemeState
): void {
  if (!storage) return;
  const payload: UiSchemeState = {
    activeId: normalizeSchemeId(state.activeId),
    auditioned: Array.from(new Set(state.auditioned ?? [])).filter((id) =>
      SCHEMES.some((entry) => entry.id === id)
    ) as UiSchemeId[],
    updatedAt: state.updatedAt ?? new Date().toISOString()
  };
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch {
    // ignore persistence failures
  }
}

export function setActiveUiScheme(state: UiSchemeState, id: UiSchemeId): UiSchemeState {
  const normalized = normalizeSchemeId(id);
  const auditioned = Array.from(new Set([...(state.auditioned ?? []), normalized]));
  return {
    activeId: normalized,
    auditioned,
    updatedAt: new Date().toISOString()
  };
}

export function markUiSchemeAudition(state: UiSchemeState, id: UiSchemeId): UiSchemeState {
  const normalized = normalizeSchemeId(id);
  const auditioned = Array.from(new Set([...(state.auditioned ?? []), normalized]));
  return {
    ...state,
    auditioned,
    updatedAt: new Date().toISOString()
  };
}

export function buildUiSchemeView(state: UiSchemeState): UiSchemeViewState {
  const entries: UiSchemeViewEntry[] = SCHEMES.map((entry) => ({
    id: entry.id,
    name: entry.name,
    accent: entry.accent,
    vibe: entry.vibe,
    summary: entry.summary,
    tags: entry.tags,
    preview: entry.preview,
    active: entry.id === state.activeId,
    auditioned: state.auditioned.includes(entry.id)
  }));
  return {
    activeId: state.activeId,
    updatedAt: state.updatedAt,
    entries
  };
}
