import type { TypingDrillMode } from "../core/types.js";

export const FINGER_MASTERY_STORAGE_KEY = "keyboard-defense:finger-mastery";
export const FINGER_MASTERY_VERSION = "v1";

export type FingerId =
  | "left-pinky"
  | "left-ring"
  | "left-middle"
  | "left-index"
  | "right-index"
  | "right-middle"
  | "right-ring"
  | "right-pinky";

export type FingerMasteryEntry = {
  attempts: number;
  errors: number;
  timingSamples: number;
  timingTotalMs: number;
};

export type FingerMasteryState = {
  version: string;
  updatedAt: string;
  fingers: Record<FingerId, FingerMasteryEntry>;
};

export type FingerMasteryTarget = {
  accuracy: number;
  timingMs: number;
  minAttempts: number;
  minTimingSamples: number;
};

export type FingerMasteryProgress = {
  attempts: number;
  errors: number;
  timingSamples: number;
  accuracy: number;
  avgTimingMs: number | null;
  progress: number;
  mastered: boolean;
};

export type FingerMasteryDelta = Partial<Record<FingerId, Partial<FingerMasteryEntry>>>;

export const FINGER_IDS: FingerId[] = [
  "left-pinky",
  "left-ring",
  "left-middle",
  "left-index",
  "right-index",
  "right-middle",
  "right-ring",
  "right-pinky"
];

export const FINGER_MASTERY_TARGET: FingerMasteryTarget = {
  accuracy: 0.9,
  timingMs: 380,
  minAttempts: 12,
  minTimingSamples: 8
};

export const FINGER_MASTERY_UNLOCKS: Array<{
  mode: TypingDrillMode;
  requires: FingerId[];
}> = [
  { mode: "reaction", requires: ["left-index", "right-index"] },
  { mode: "rhythm", requires: ["left-middle", "right-middle"] },
  { mode: "combo", requires: ["left-ring", "right-ring"] },
  { mode: "symbols", requires: ["left-pinky", "right-pinky"] },
  {
    mode: "precision",
    requires: [
      "left-pinky",
      "left-ring",
      "left-middle",
      "left-index",
      "right-index",
      "right-middle",
      "right-ring",
      "right-pinky"
    ]
  }
];

const EPOCH = "1970-01-01T00:00:00.000Z";

const EMPTY_ENTRY: FingerMasteryEntry = {
  attempts: 0,
  errors: 0,
  timingSamples: 0,
  timingTotalMs: 0
};

function clampCount(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.floor(value));
}

function clampTotal(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, value);
}

function normalizeEntry(value: unknown): FingerMasteryEntry {
  const entry = value && typeof value === "object" ? (value as Partial<FingerMasteryEntry>) : null;
  return {
    attempts: clampCount(entry?.attempts),
    errors: clampCount(entry?.errors),
    timingSamples: clampCount(entry?.timingSamples),
    timingTotalMs: clampTotal(entry?.timingTotalMs)
  };
}

function createFingerMap(value?: Record<string, FingerMasteryEntry> | null): Record<FingerId, FingerMasteryEntry> {
  const result = Object.create(null) as Record<FingerId, FingerMasteryEntry>;
  for (const finger of FINGER_IDS) {
    const entry = value?.[finger] ?? EMPTY_ENTRY;
    result[finger] = normalizeEntry(entry);
  }
  return result;
}

export function createDefaultFingerMasteryState(): FingerMasteryState {
  return {
    version: FINGER_MASTERY_VERSION,
    updatedAt: EPOCH,
    fingers: createFingerMap()
  };
}

export function readFingerMastery(storage: Storage | null | undefined): FingerMasteryState {
  if (!storage) return createDefaultFingerMasteryState();
  try {
    const raw = storage.getItem(FINGER_MASTERY_STORAGE_KEY);
    if (!raw) return createDefaultFingerMasteryState();
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return createDefaultFingerMasteryState();
    if (parsed.version !== FINGER_MASTERY_VERSION) return createDefaultFingerMasteryState();
    const updatedAt =
      typeof parsed.updatedAt === "string" && parsed.updatedAt.length > 0 ? parsed.updatedAt : EPOCH;
    return {
      version: FINGER_MASTERY_VERSION,
      updatedAt,
      fingers: createFingerMap(parsed.fingers)
    };
  } catch {
    return createDefaultFingerMasteryState();
  }
}

export function writeFingerMastery(
  storage: Storage | null | undefined,
  state: FingerMasteryState
): void {
  if (!storage) return;
  const payload: FingerMasteryState = {
    version: FINGER_MASTERY_VERSION,
    updatedAt:
      typeof state.updatedAt === "string" && state.updatedAt.length > 0
        ? state.updatedAt
        : new Date().toISOString(),
    fingers: createFingerMap(state.fingers)
  };
  try {
    storage.setItem(FINGER_MASTERY_STORAGE_KEY, JSON.stringify(payload));
  } catch {
    // ignore storage failures
  }
}

export function applyFingerMasteryDelta(
  state: FingerMasteryState,
  delta: FingerMasteryDelta
): FingerMasteryState {
  const next = createFingerMap(state.fingers);
  for (const finger of FINGER_IDS) {
    const current = next[finger];
    const patch = delta?.[finger];
    if (!patch) continue;
    current.attempts = clampCount(current.attempts + clampCount(patch.attempts));
    current.errors = clampCount(current.errors + clampCount(patch.errors));
    current.timingSamples = clampCount(current.timingSamples + clampCount(patch.timingSamples));
    current.timingTotalMs = clampTotal(current.timingTotalMs + clampTotal(patch.timingTotalMs));
    next[finger] = current;
  }
  return {
    version: FINGER_MASTERY_VERSION,
    updatedAt: new Date().toISOString(),
    fingers: next
  };
}

export function buildFingerMasteryProgress(
  entry: FingerMasteryEntry,
  target: FingerMasteryTarget = FINGER_MASTERY_TARGET
): FingerMasteryProgress {
  const attempts = clampCount(entry.attempts);
  const errors = clampCount(entry.errors);
  const timingSamples = clampCount(entry.timingSamples);
  const accuracy = attempts > 0 ? Math.max(0, Math.min(1, (attempts - errors) / attempts)) : 0;
  const avgTimingMs =
    timingSamples > 0 && entry.timingTotalMs > 0 ? entry.timingTotalMs / timingSamples : null;
  const accuracyProgress = target.accuracy > 0 ? Math.min(1, accuracy / target.accuracy) : 1;
  const timingProgress =
    avgTimingMs && target.timingMs > 0 ? Math.min(1, target.timingMs / avgTimingMs) : 0;
  const progress = Math.max(0, Math.min(1, Math.min(accuracyProgress, timingProgress)));
  const mastered =
    attempts >= target.minAttempts &&
    timingSamples >= target.minTimingSamples &&
    accuracy >= target.accuracy &&
    avgTimingMs !== null &&
    avgTimingMs <= target.timingMs;
  return {
    attempts,
    errors,
    timingSamples,
    accuracy,
    avgTimingMs,
    progress,
    mastered
  };
}

export function isModeUnlocked(
  mode: TypingDrillMode,
  state: FingerMasteryState,
  target: FingerMasteryTarget = FINGER_MASTERY_TARGET
): boolean {
  const rule = FINGER_MASTERY_UNLOCKS.find((entry) => entry.mode === mode);
  if (!rule) return true;
  return rule.requires.every((finger) => buildFingerMasteryProgress(state.fingers[finger], target).mastered);
}
