const STORAGE_KEY = "keyboard-defense:challenge-modifiers";
export const CHALLENGE_MODIFIERS_VERSION = "v1";

export type ChallengeModifierId = "fog" | "fast-spawns" | "limited-mistakes";

export type ChallengeModifiersSelection = {
  enabled: boolean;
  fog: boolean;
  fastSpawns: boolean;
  limitedMistakes: boolean;
  mistakeBudget: number;
};

export type ChallengeModifiersState = {
  version: string;
  selection: ChallengeModifiersSelection;
  updatedAt: string;
};

export type ChallengeModifierDescriptor = {
  id: ChallengeModifierId;
  label: string;
  description: string;
  scoreMultiplier: number;
};

export type ChallengeModifiersViewState = {
  enabled: boolean;
  active: ChallengeModifierDescriptor[];
  scoreMultiplier: number;
  summary: string;
  mistakeBudget: number;
};

const CATALOG: Record<ChallengeModifierId, ChallengeModifierDescriptor> = {
  fog: {
    id: "fog",
    label: "Fog of War",
    description: "Hide upcoming spawn intel and chill turret targeting with fog.",
    scoreMultiplier: 1.15
  },
  "fast-spawns": {
    id: "fast-spawns",
    label: "Fast Spawns",
    description: "Enemies arrive sooner and waves move faster.",
    scoreMultiplier: 1.25
  },
  "limited-mistakes": {
    id: "limited-mistakes",
    label: "Limited Mistakes",
    description: "Reach the mistake limit and the wave ends immediately.",
    scoreMultiplier: 1.2
  }
};

function clampInteger(value: unknown, min: number, max: number): number {
  const parsed = typeof value === "number" ? value : Number.parseInt(String(value ?? ""), 10);
  if (!Number.isFinite(parsed)) return min;
  const rounded = Math.floor(parsed);
  return Math.max(min, Math.min(max, rounded));
}

export function getChallengeModifierCatalog(): ChallengeModifierDescriptor[] {
  return [CATALOG.fog, CATALOG["fast-spawns"], CATALOG["limited-mistakes"]];
}

export function getDefaultChallengeModifiersSelection(): ChallengeModifiersSelection {
  return {
    enabled: false,
    fog: false,
    fastSpawns: false,
    limitedMistakes: false,
    mistakeBudget: 10
  };
}

export function normalizeChallengeModifiersSelection(
  input: unknown
): ChallengeModifiersSelection {
  const defaults = getDefaultChallengeModifiersSelection();
  if (!input || typeof input !== "object") {
    return defaults;
  }
  const data = input as Record<string, unknown>;
  const enabled = Boolean(data.enabled);
  const fog = Boolean(data.fog);
  const fastSpawns = Boolean(data.fastSpawns);
  const limitedMistakes = Boolean(data.limitedMistakes);
  const mistakeBudget = clampInteger(data.mistakeBudget, 3, 50);
  return { enabled, fog, fastSpawns, limitedMistakes, mistakeBudget };
}

function normalizeState(raw: unknown): ChallengeModifiersState {
  if (!raw || typeof raw !== "object") {
    return {
      version: CHALLENGE_MODIFIERS_VERSION,
      selection: getDefaultChallengeModifiersSelection(),
      updatedAt: new Date().toISOString()
    };
  }
  const data = raw as Record<string, unknown>;
  if (data.version !== CHALLENGE_MODIFIERS_VERSION) {
    return {
      version: CHALLENGE_MODIFIERS_VERSION,
      selection: getDefaultChallengeModifiersSelection(),
      updatedAt: new Date().toISOString()
    };
  }
  const selection = normalizeChallengeModifiersSelection(data.selection ?? data);
  const updatedAt =
    typeof data.updatedAt === "string" && data.updatedAt.length > 0
      ? data.updatedAt
      : new Date().toISOString();
  return {
    version: CHALLENGE_MODIFIERS_VERSION,
    selection,
    updatedAt
  };
}

export function readChallengeModifiers(
  storage: Storage | null | undefined
): ChallengeModifiersState {
  if (!storage) {
    return normalizeState(null);
  }
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return normalizeState(null);
    return normalizeState(JSON.parse(raw));
  } catch {
    return normalizeState(null);
  }
}

export function writeChallengeModifiers(
  storage: Storage | null | undefined,
  state: ChallengeModifiersState
): ChallengeModifiersState {
  const normalized = normalizeState(state);
  if (!storage) return normalized;
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(normalized));
  } catch {
    // ignore persistence failures
  }
  return normalized;
}

export function listActiveChallengeModifiers(
  selection: ChallengeModifiersSelection
): ChallengeModifierDescriptor[] {
  if (!selection.enabled) return [];
  const active: ChallengeModifierDescriptor[] = [];
  if (selection.fog) active.push(CATALOG.fog);
  if (selection.fastSpawns) active.push(CATALOG["fast-spawns"]);
  if (selection.limitedMistakes) active.push(CATALOG["limited-mistakes"]);
  return active;
}

export function computeChallengeScoreMultiplier(selection: ChallengeModifiersSelection): number {
  const active = listActiveChallengeModifiers(selection);
  if (active.length === 0) return 1;
  const multiplier = active.reduce((product, entry) => product * entry.scoreMultiplier, 1);
  return Number.isFinite(multiplier) ? Math.max(1, Number(multiplier.toFixed(3))) : 1;
}

export function buildChallengeModifiersViewState(
  state: ChallengeModifiersState
): ChallengeModifiersViewState {
  const selection = normalizeChallengeModifiersSelection(state?.selection);
  const active = listActiveChallengeModifiers(selection);
  const scoreMultiplier = computeChallengeScoreMultiplier(selection);
  const summary =
    active.length === 0
      ? "No challenge modifiers active."
      : `${active.map((entry) => entry.label).join(" + ")} (Score x${scoreMultiplier.toFixed(2)})`;
  return {
    enabled: selection.enabled,
    active,
    scoreMultiplier,
    summary,
    mistakeBudget: selection.mistakeBudget
  };
}

