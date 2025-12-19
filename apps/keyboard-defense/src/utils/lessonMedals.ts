import { type TypingDrillMode, type TypingDrillSummary } from "../core/types.js";

const STORAGE_KEY = "keyboard-defense:lesson-medals";
export const LESSON_MEDAL_VERSION = "v1";
const MAX_HISTORY = 14;

export type LessonMedalTier = "bronze" | "silver" | "gold" | "platinum";

export type LessonMedalRecord = {
  id: string;
  tier: LessonMedalTier;
  mode: TypingDrillMode;
  accuracy: number;
  wpm: number;
  bestCombo: number;
  errors: number;
  words: number;
  elapsedMs: number;
  timestamp: number;
};

export type LessonMedalProgress = {
  version: string;
  history: LessonMedalRecord[];
  updatedAt: string;
};

export type LessonMedalViewState = {
  last: LessonMedalRecord | null;
  recent: LessonMedalRecord[];
  bestByMode: Record<TypingDrillMode, LessonMedalRecord | null>;
  totals: Record<LessonMedalTier, number>;
  nextTarget: { tier: LessonMedalTier; hint: string } | null;
};

type MedalThreshold = {
  tier: LessonMedalTier;
  minAccuracy: number;
  minWpm: number;
  minCombo: number;
  maxErrors: number;
};

const MEDAL_THRESHOLDS: MedalThreshold[] = [
  { tier: "bronze", minAccuracy: 0.65, minWpm: 0, minCombo: 0, maxErrors: 99 },
  { tier: "silver", minAccuracy: 0.9, minWpm: 20, minCombo: 3, maxErrors: 4 },
  { tier: "gold", minAccuracy: 0.95, minWpm: 32, minCombo: 5, maxErrors: 2 },
  { tier: "platinum", minAccuracy: 0.98, minWpm: 40, minCombo: 7, maxErrors: 1 }
];

const MEDAL_ORDER: LessonMedalTier[] = ["bronze", "silver", "gold", "platinum"];

function clampRatio(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

function clampNonNegative(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, value);
}

function clampInteger(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.floor(value));
}

function normalizeMode(value: unknown): TypingDrillMode {
  return value === "endurance" ||
    value === "sprint" ||
    value === "sentences" ||
    value === "reading" ||
    value === "rhythm" ||
    value === "reaction" ||
    value === "combo" ||
    value === "precision" ||
    value === "warmup" ||
    value === "symbols" ||
    value === "placement" ||
    value === "hand" ||
    value === "support" ||
    value === "shortcuts" ||
    value === "shift" ||
    value === "focus"
    ? value
    : "burst";
}

function normalizeTier(value: unknown): LessonMedalTier {
  return value === "silver" || value === "gold" || value === "platinum" ? value : "bronze";
}

function meetsThreshold(metrics: LessonMedalRecord, threshold: MedalThreshold): boolean {
  return (
    metrics.accuracy >= threshold.minAccuracy &&
    metrics.wpm >= threshold.minWpm &&
    metrics.bestCombo >= threshold.minCombo &&
    metrics.errors <= threshold.maxErrors
  );
}

function buildRequirements(metrics: LessonMedalRecord, threshold: MedalThreshold): string[] {
  const requirements: string[] = [];
  const accuracyTarget = Math.round(threshold.minAccuracy * 100);
  if (metrics.accuracy < threshold.minAccuracy) {
    requirements.push(`${accuracyTarget}% accuracy`);
  }
  if (metrics.wpm < threshold.minWpm) {
    requirements.push(`${threshold.minWpm} WPM`);
  }
  if (metrics.bestCombo < threshold.minCombo) {
    requirements.push(`combo x${threshold.minCombo}`);
  }
  if (metrics.errors > threshold.maxErrors) {
    requirements.push(
      threshold.maxErrors === 0 ? "zero errors" : `${threshold.maxErrors} error${threshold.maxErrors === 1 ? "" : "s"} max`
    );
  }
  return requirements;
}

function formatNextHint(targetTier: LessonMedalTier, requirements: string[]): string {
  const label = targetTier.charAt(0).toUpperCase() + targetTier.slice(1);
  if (requirements.length === 0) {
    return `Replay to lock in ${label} on back-to-back runs.`;
  }
  if (requirements.length === 1) {
    return `Replay for ${label}: ${requirements[0]}.`;
  }
  const last = requirements.pop();
  return `Replay for ${label}: ${requirements.join(", ")} and ${last}.`;
}

export function evaluateLessonMedal(
  summary: TypingDrillSummary
): { tier: LessonMedalTier; nextTarget: { tier: LessonMedalTier; hint: string } | null } {
  const normalized: LessonMedalRecord = {
    id: "pending",
    tier: "bronze",
    mode: normalizeMode(summary.mode),
    accuracy: clampRatio(summary.accuracy),
    wpm: clampNonNegative(summary.wpm),
    bestCombo: clampInteger(summary.bestCombo),
    errors: clampInteger(summary.errors),
    words: clampInteger(summary.words),
    elapsedMs: clampNonNegative(summary.elapsedMs),
    timestamp: summary.timestamp ?? Date.now()
  };
  let tier: LessonMedalTier = "bronze";
  for (const threshold of MEDAL_THRESHOLDS) {
    if (meetsThreshold(normalized, threshold)) {
      tier = threshold.tier;
    }
  }
  const currentIndex = MEDAL_ORDER.indexOf(tier);
  const nextThreshold = currentIndex >= 0 ? MEDAL_THRESHOLDS[currentIndex + 1] : null;
  const requirements = nextThreshold ? buildRequirements(normalized, nextThreshold) : [];
  return {
    tier,
    nextTarget: nextThreshold
      ? {
          tier: nextThreshold.tier,
          hint: formatNextHint(nextThreshold.tier, requirements)
        }
      : null
  };
}

function normalizeRecord(raw: unknown): LessonMedalRecord | null {
  if (!raw || typeof raw !== "object") return null;
  const data = raw as Record<string, unknown>;
  const timestamp = Number.isFinite(data.timestamp as number)
    ? (data.timestamp as number)
    : Date.now();
  const id =
    typeof data.id === "string" && data.id.trim().length > 0
      ? data.id
      : `medal-${timestamp.toString(36)}`;
  return {
    id,
    tier: normalizeTier(data.tier),
    mode: normalizeMode(data.mode),
    accuracy: clampRatio(data.accuracy),
    wpm: clampNonNegative(data.wpm),
    bestCombo: clampInteger(data.bestCombo),
    errors: clampInteger(data.errors),
    words: clampInteger(data.words),
    elapsedMs: clampNonNegative(data.elapsedMs),
    timestamp
  };
}

const DEFAULT_PROGRESS: LessonMedalProgress = {
  version: LESSON_MEDAL_VERSION,
  history: [],
  updatedAt: new Date().toISOString()
};

export function readLessonMedalProgress(storage: Storage | null | undefined): LessonMedalProgress {
  if (!storage) return { ...DEFAULT_PROGRESS };
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_PROGRESS };
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return { ...DEFAULT_PROGRESS };
    if (parsed.version !== LESSON_MEDAL_VERSION) return { ...DEFAULT_PROGRESS };
    const history: LessonMedalRecord[] = [];
    if (Array.isArray(parsed.history)) {
      for (const item of parsed.history) {
        const normalized = normalizeRecord(item);
        if (normalized) {
          history.push(normalized);
        }
      }
    }
    const trimmed =
      history.length > MAX_HISTORY ? history.slice(history.length - MAX_HISTORY) : history;
    const updatedAt =
      typeof parsed.updatedAt === "string" && parsed.updatedAt.length > 0
        ? parsed.updatedAt
        : new Date().toISOString();
    return {
      version: LESSON_MEDAL_VERSION,
      history: trimmed,
      updatedAt
    };
  } catch {
    return { ...DEFAULT_PROGRESS };
  }
}

export function writeLessonMedalProgress(
  storage: Storage | null | undefined,
  progress: LessonMedalProgress
): void {
  if (!storage) return;
  const normalizedHistory: LessonMedalRecord[] = [];
  for (const entry of progress.history.slice(-MAX_HISTORY)) {
    const normalized = normalizeRecord(entry);
    if (normalized) {
      normalizedHistory.push(normalized);
    }
  }
  const payload: LessonMedalProgress = {
    version: LESSON_MEDAL_VERSION,
    history: normalizedHistory,
    updatedAt: progress.updatedAt ?? new Date().toISOString()
  };
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch {
    // ignore persistence failures
  }
}

export function recordLessonMedal(
  progress: LessonMedalProgress,
  summary: TypingDrillSummary
): { progress: LessonMedalProgress; record: LessonMedalRecord; nextTarget: LessonMedalViewState["nextTarget"] } {
  const { tier, nextTarget } = evaluateLessonMedal(summary);
  const normalized: LessonMedalRecord = {
    id: `medal-${Date.now().toString(36)}`,
    tier,
    mode: normalizeMode(summary.mode),
    accuracy: clampRatio(summary.accuracy),
    wpm: clampNonNegative(summary.wpm),
    bestCombo: clampInteger(summary.bestCombo),
    errors: clampInteger(summary.errors),
    words: clampInteger(summary.words),
    elapsedMs: clampNonNegative(summary.elapsedMs),
    timestamp: summary.timestamp ?? Date.now()
  };
  const nextHistory = [...progress.history, normalized];
  if (nextHistory.length > MAX_HISTORY) {
    nextHistory.splice(0, nextHistory.length - MAX_HISTORY);
  }
  return {
    progress: {
      version: LESSON_MEDAL_VERSION,
      history: nextHistory,
      updatedAt: new Date().toISOString()
    },
    record: normalized,
    nextTarget
  };
}

export function buildLessonMedalViewState(progress: LessonMedalProgress): LessonMedalViewState {
  const history = progress.history ?? [];
  const recent = history.slice(-5).reverse();
  const bestByMode: Record<TypingDrillMode, LessonMedalRecord | null> = {
    burst: null,
    warmup: null,
    endurance: null,
    sprint: null,
    sentences: null,
    reading: null,
    rhythm: null,
    reaction: null,
    combo: null,
    precision: null,
    symbols: null,
    placement: null,
    hand: null,
    support: null,
    shortcuts: null,
    shift: null,
    focus: null
  };
  const totals: Record<LessonMedalTier, number> = {
    bronze: 0,
    silver: 0,
    gold: 0,
    platinum: 0
  };
  for (const entry of history) {
    totals[entry.tier] = (totals[entry.tier] ?? 0) + 1;
    const currentBest = bestByMode[entry.mode];
    if (!currentBest) {
      bestByMode[entry.mode] = entry;
      continue;
    }
    const currentRank = MEDAL_ORDER.indexOf(currentBest.tier);
    const nextRank = MEDAL_ORDER.indexOf(entry.tier);
    if (nextRank > currentRank) {
      bestByMode[entry.mode] = entry;
    } else if (nextRank === currentRank && entry.wpm > currentBest.wpm) {
      bestByMode[entry.mode] = entry;
    }
  }
  const last = history.length > 0 ? history[history.length - 1] : null;
  let nextTarget: LessonMedalViewState["nextTarget"] = null;
  if (last) {
    const currentIndex = MEDAL_ORDER.indexOf(last.tier);
    const nextThreshold = currentIndex >= 0 ? MEDAL_THRESHOLDS[currentIndex + 1] : null;
    if (nextThreshold) {
      const requirements = buildRequirements(last, nextThreshold);
      nextTarget = {
        tier: nextThreshold.tier,
        hint: formatNextHint(nextThreshold.tier, requirements)
      };
    }
  }
  return {
    last,
    recent,
    bestByMode,
    totals,
    nextTarget
  };
}
