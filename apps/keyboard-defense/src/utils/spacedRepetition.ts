const STORAGE_KEY = "keyboard-defense:spaced-repetition";
export const SPACED_REPETITION_VERSION = "v1";

export type SpacedRepetitionKind = "key" | "digraph";

export type SpacedRepetitionPatternStats = {
  attempts: number;
  errors: number;
};

export type SpacedRepetitionObservedStats = {
  keys?: Record<string, SpacedRepetitionPatternStats>;
  digraphs?: Record<string, SpacedRepetitionPatternStats>;
};

export type SpacedRepetitionItem = {
  id: string;
  kind: SpacedRepetitionKind;
  pattern: string;
  dueAtMs: number;
  intervalDays: number;
  easeFactor: number;
  repetitions: number;
  lapses: number;
  lastReviewedAtMs: number | null;
  lastGrade: number | null;
  createdAtMs: number;
};

export type SpacedRepetitionState = {
  version: string;
  items: Record<string, SpacedRepetitionItem>;
  updatedAt: string;
};

const MIN_EASE_FACTOR = 1.3;
const MAX_EASE_FACTOR = 2.6;
const DEFAULT_EASE_FACTOR = 2.1;
const MIN_INTERVAL_DAYS = 0.004;
const MAX_INTERVAL_DAYS = 365;

const MIN_ATTEMPTS_KEY = 3;
const MIN_ATTEMPTS_DIGRAPH = 2;

const DEFAULT_STATE: SpacedRepetitionState = {
  version: SPACED_REPETITION_VERSION,
  items: {},
  updatedAt: new Date().toISOString()
};

function clampNumber(value: unknown, min: number, max: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return min;
  return Math.max(min, Math.min(max, value));
}

function clampNonNegativeInt(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.floor(value));
}

function normalizePattern(value: unknown): { kind: SpacedRepetitionKind; pattern: string } | null {
  if (typeof value !== "string") return null;
  const pattern = value.trim().toLowerCase();
  if (pattern.length === 1 && /^[a-z]$/.test(pattern)) {
    return { kind: "key", pattern };
  }
  if (pattern.length === 2 && /^[a-z]{2}$/.test(pattern)) {
    return { kind: "digraph", pattern };
  }
  return null;
}

function itemId(kind: SpacedRepetitionKind, pattern: string): string {
  return `${kind}:${pattern}`;
}

function normalizeItem(raw: unknown): SpacedRepetitionItem | null {
  if (!raw || typeof raw !== "object") return null;
  const data = raw as Record<string, unknown>;
  const kind = data.kind === "digraph" ? "digraph" : data.kind === "key" ? "key" : null;
  const patternInfo = normalizePattern(data.pattern);
  if (!kind || !patternInfo || patternInfo.kind !== kind) {
    return null;
  }
  const id = typeof data.id === "string" && data.id.length > 0 ? data.id : itemId(kind, patternInfo.pattern);
  const createdAtMs = clampNonNegativeInt(data.createdAtMs ?? Date.now());
  const dueAtMs = clampNonNegativeInt(data.dueAtMs ?? Date.now());
  const intervalDays = clampNumber(data.intervalDays, MIN_INTERVAL_DAYS, MAX_INTERVAL_DAYS);
  const easeFactor = clampNumber(data.easeFactor, MIN_EASE_FACTOR, MAX_EASE_FACTOR);
  const repetitions = clampNonNegativeInt(data.repetitions);
  const lapses = clampNonNegativeInt(data.lapses);
  const lastReviewedAtMs =
    typeof data.lastReviewedAtMs === "number" && Number.isFinite(data.lastReviewedAtMs)
      ? Math.max(0, Math.floor(data.lastReviewedAtMs))
      : null;
  const lastGrade =
    typeof data.lastGrade === "number" && Number.isFinite(data.lastGrade)
      ? Math.max(0, Math.min(5, Math.floor(data.lastGrade)))
      : null;
  return {
    id,
    kind,
    pattern: patternInfo.pattern,
    dueAtMs,
    intervalDays,
    easeFactor,
    repetitions,
    lapses,
    lastReviewedAtMs,
    lastGrade,
    createdAtMs
  };
}

export function createDefaultSpacedRepetitionState(): SpacedRepetitionState {
  return structuredClone(DEFAULT_STATE);
}

export function readSpacedRepetitionState(storage: Storage | null | undefined): SpacedRepetitionState {
  if (!storage) return createDefaultSpacedRepetitionState();
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return createDefaultSpacedRepetitionState();
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return createDefaultSpacedRepetitionState();
    if (parsed.version !== SPACED_REPETITION_VERSION) return createDefaultSpacedRepetitionState();
    const items: Record<string, SpacedRepetitionItem> = {};
    const rawItems = (parsed as Record<string, unknown>).items;
    if (rawItems && typeof rawItems === "object") {
      for (const [key, value] of Object.entries(rawItems as Record<string, unknown>)) {
        const normalized = normalizeItem(value);
        if (!normalized) continue;
        items[key] = normalized;
      }
    }
    const updatedAt =
      typeof (parsed as Record<string, unknown>).updatedAt === "string" &&
      (parsed as Record<string, unknown>).updatedAt
        ? ((parsed as Record<string, unknown>).updatedAt as string)
        : new Date().toISOString();
    return {
      version: SPACED_REPETITION_VERSION,
      items,
      updatedAt
    };
  } catch {
    return createDefaultSpacedRepetitionState();
  }
}

export function writeSpacedRepetitionState(
  storage: Storage | null | undefined,
  state: SpacedRepetitionState
): SpacedRepetitionState {
  if (!storage) return state;
  const normalized: SpacedRepetitionState = {
    version: SPACED_REPETITION_VERSION,
    items: state.items ?? {},
    updatedAt: state.updatedAt ?? new Date().toISOString()
  };
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(normalized));
  } catch {
    // ignore persistence failures
  }
  return normalized;
}

export function computeSpacedRepetitionGrade(stats: SpacedRepetitionPatternStats): number | null {
  const attempts = clampNonNegativeInt(stats.attempts);
  const errors = clampNonNegativeInt(stats.errors);
  if (attempts <= 0) return null;
  const accuracy = Math.max(0, Math.min(1, (attempts - errors) / attempts));

  if (accuracy >= 0.99 && errors === 0) return 5;
  if (accuracy >= 0.96) return 4;
  if (accuracy >= 0.9) return 3;
  if (accuracy >= 0.8) return 2;
  return 1;
}

function computeNextEaseFactor(current: number, grade: number): number {
  const q = Math.max(0, Math.min(5, Math.floor(grade)));
  const diff = 5 - q;
  const next = current + (0.1 - diff * (0.08 + diff * 0.02));
  return clampNumber(next, MIN_EASE_FACTOR, MAX_EASE_FACTOR);
}

function computeInitialIntervalDays(grade: number): number {
  if (grade >= 4) return 0.02;
  if (grade === 3) return 0.008;
  return 0.004;
}

function computeNextIntervalDays(previous: number, repetitions: number, easeFactor: number): number {
  if (repetitions <= 1) {
    return Math.max(previous, 0.15);
  }
  if (repetitions === 2) {
    return Math.max(previous, 1);
  }
  return clampNumber(previous * easeFactor, MIN_INTERVAL_DAYS, MAX_INTERVAL_DAYS);
}

export function recordSpacedRepetitionReview(
  state: SpacedRepetitionState,
  review: { kind: SpacedRepetitionKind; pattern: string; grade: number; nowMs?: number }
): SpacedRepetitionState {
  const nowMs = typeof review.nowMs === "number" && Number.isFinite(review.nowMs) ? review.nowMs : Date.now();
  const normalizedPattern = normalizePattern(review.pattern);
  if (!normalizedPattern || normalizedPattern.kind !== review.kind) return state;
  const grade = Math.max(0, Math.min(5, Math.floor(clampNumber(review.grade, 0, 5))));
  const id = itemId(review.kind, normalizedPattern.pattern);

  const existing = state.items?.[id] ?? null;
  const base: SpacedRepetitionItem = existing ?? {
    id,
    kind: review.kind,
    pattern: normalizedPattern.pattern,
    dueAtMs: nowMs,
    intervalDays: computeInitialIntervalDays(grade),
    easeFactor: DEFAULT_EASE_FACTOR,
    repetitions: 0,
    lapses: 0,
    lastReviewedAtMs: null,
    lastGrade: null,
    createdAtMs: nowMs
  };

  const nextEaseFactor = computeNextEaseFactor(base.easeFactor, grade);
  const wasSuccess = grade >= 3;
  const nextRepetitions = wasSuccess ? base.repetitions + 1 : 0;
  const nextLapses = wasSuccess ? base.lapses : base.lapses + 1;
  const nextIntervalDays = wasSuccess
    ? computeNextIntervalDays(base.intervalDays, nextRepetitions, nextEaseFactor)
    : computeInitialIntervalDays(grade);
  const dueAtMs = nowMs + Math.round(nextIntervalDays * 24 * 60 * 60 * 1000);

  const nextItem: SpacedRepetitionItem = {
    ...base,
    easeFactor: nextEaseFactor,
    repetitions: nextRepetitions,
    lapses: nextLapses,
    intervalDays: clampNumber(nextIntervalDays, MIN_INTERVAL_DAYS, MAX_INTERVAL_DAYS),
    dueAtMs,
    lastReviewedAtMs: Math.max(0, Math.floor(nowMs)),
    lastGrade: grade
  };

  return {
    version: SPACED_REPETITION_VERSION,
    items: { ...(state.items ?? {}), [id]: nextItem },
    updatedAt: new Date().toISOString()
  };
}

export function recordSpacedRepetitionObservedStats(
  state: SpacedRepetitionState,
  observed: SpacedRepetitionObservedStats,
  options: { nowMs?: number } = {}
): SpacedRepetitionState {
  const nowMs = typeof options.nowMs === "number" && Number.isFinite(options.nowMs) ? options.nowMs : Date.now();
  let nextState = state;

  const apply = (kind: SpacedRepetitionKind, statsMap: Record<string, SpacedRepetitionPatternStats> | undefined) => {
    if (!statsMap) return;
    const minAttempts = kind === "digraph" ? MIN_ATTEMPTS_DIGRAPH : MIN_ATTEMPTS_KEY;
    for (const [rawPattern, stats] of Object.entries(statsMap)) {
      const normalized = normalizePattern(rawPattern);
      if (!normalized || normalized.kind !== kind) continue;
      const attempts = clampNonNegativeInt(stats?.attempts);
      const errors = clampNonNegativeInt(stats?.errors);
      if (attempts < minAttempts) continue;

      const id = itemId(kind, normalized.pattern);
      const known = Boolean(nextState.items?.[id]);
      if (!known && errors === 0) continue;

      const grade = computeSpacedRepetitionGrade({ attempts, errors });
      if (grade === null) continue;
      nextState = recordSpacedRepetitionReview(nextState, {
        kind,
        pattern: normalized.pattern,
        grade,
        nowMs
      });
    }
  };

  apply("key", observed.keys);
  apply("digraph", observed.digraphs);
  return nextState;
}

export function listDueSpacedRepetitionItems(
  state: SpacedRepetitionState,
  options: { nowMs?: number; limit?: number } = {}
): SpacedRepetitionItem[] {
  const nowMs = typeof options.nowMs === "number" && Number.isFinite(options.nowMs) ? options.nowMs : Date.now();
  const limit =
    typeof options.limit === "number" && Number.isFinite(options.limit) && options.limit > 0
      ? Math.floor(options.limit)
      : 12;
  const items = Object.values(state.items ?? {}).filter((item) => (item?.dueAtMs ?? Infinity) <= nowMs);
  items.sort((a, b) => a.dueAtMs - b.dueAtMs || a.easeFactor - b.easeFactor || a.pattern.localeCompare(b.pattern));
  return items.slice(0, limit);
}

export function listDueSpacedRepetitionPatterns(
  state: SpacedRepetitionState,
  options: { nowMs?: number; limit?: number; includeKinds?: SpacedRepetitionKind[] } = {}
): string[] {
  const includeKinds = Array.isArray(options.includeKinds) ? options.includeKinds : null;
  const allowedKinds =
    includeKinds && includeKinds.length > 0
      ? new Set(includeKinds.filter((k) => k === "key" || k === "digraph"))
      : null;
  const due = listDueSpacedRepetitionItems(state, { nowMs: options.nowMs, limit: options.limit });
  const patterns: string[] = [];
  for (const item of due) {
    if (allowedKinds && !allowedKinds.has(item.kind)) continue;
    patterns.push(item.pattern);
  }
  return patterns;
}

