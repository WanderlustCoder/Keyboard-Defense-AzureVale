import { type TypingDrillMode, type TypingDrillSummary } from "../core/types.js";

const STORAGE_KEY = "keyboard-defense:wpm-ladder";
export const WPM_LADDER_VERSION = "v1";
const MAX_RUNS = 30;

export type WpmLadderRun = {
  id: string;
  mode: TypingDrillMode;
  wpm: number;
  accuracy: number;
  bestCombo: number;
  errors: number;
  elapsedMs: number;
  timestamp: number;
};

export type WpmLadderProgress = {
  version: string;
  runs: WpmLadderRun[];
  updatedAt: string;
};

export type WpmLadderViewState = {
  totalRuns: number;
  updatedAt: string | null;
  lastRun: WpmLadderRun | null;
  bestByMode: Record<TypingDrillMode, WpmLadderRun | null>;
  ladderByMode: Record<TypingDrillMode, WpmLadderRun[]>;
  topRuns: WpmLadderRun[];
};

function clampRatio(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

function clampNonNegative(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, value);
}

function normalizeMode(value: unknown): TypingDrillMode {
  return value === "precision" ||
    value === "endurance" ||
    value === "sprint" ||
    value === "sentences" ||
    value === "reading" ||
    value === "rhythm" ||
    value === "reaction" ||
    value === "combo" ||
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

function normalizeRun(raw: unknown): WpmLadderRun | null {
  if (!raw || typeof raw !== "object") return null;
  const data = raw as Record<string, unknown>;
  const timestamp = Number.isFinite(data.timestamp as number)
    ? (data.timestamp as number)
    : Date.now();
  const id =
    typeof data.id === "string" && data.id.trim().length > 0
      ? data.id
      : `wpm-${timestamp.toString(36)}`;
  return {
    id,
    mode: normalizeMode(data.mode),
    wpm: clampNonNegative(data.wpm),
    accuracy: clampRatio(data.accuracy),
    bestCombo: clampNonNegative(data.bestCombo),
    errors: clampNonNegative(data.errors),
    elapsedMs: clampNonNegative(data.elapsedMs),
    timestamp
  };
}

function sortRuns(a: WpmLadderRun, b: WpmLadderRun): number {
  if (a.wpm !== b.wpm) return b.wpm - a.wpm;
  if (a.accuracy !== b.accuracy) return b.accuracy - a.accuracy;
  if (a.bestCombo !== b.bestCombo) return b.bestCombo - a.bestCombo;
  return b.timestamp - a.timestamp;
}

function findBestRunForMode(runs: WpmLadderRun[], mode: TypingDrillMode): WpmLadderRun | null {
  const matches = runs.filter((run) => run.mode === mode);
  if (!matches.length) return null;
  const sorted = [...matches].sort(sortRuns);
  return sorted[0] ?? null;
}

const DEFAULT_PROGRESS: WpmLadderProgress = {
  version: WPM_LADDER_VERSION,
  runs: [],
  updatedAt: new Date().toISOString()
};

export function readWpmLadderProgress(storage: Storage | null | undefined): WpmLadderProgress {
  if (!storage) return { ...DEFAULT_PROGRESS };
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_PROGRESS };
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return { ...DEFAULT_PROGRESS };
    if (parsed.version !== WPM_LADDER_VERSION) return { ...DEFAULT_PROGRESS };
    const runs: WpmLadderRun[] = [];
    if (Array.isArray(parsed.runs)) {
      for (const entry of parsed.runs) {
        const normalized = normalizeRun(entry);
        if (normalized) {
          runs.push(normalized);
        }
      }
    }
    const trimmed = runs.length > MAX_RUNS ? runs.slice(runs.length - MAX_RUNS) : runs;
    const updatedAt =
      typeof parsed.updatedAt === "string" && parsed.updatedAt.length > 0
        ? parsed.updatedAt
        : new Date().toISOString();
    return {
      version: WPM_LADDER_VERSION,
      runs: trimmed,
      updatedAt
    };
  } catch {
    return { ...DEFAULT_PROGRESS };
  }
}

export function writeWpmLadderProgress(
  storage: Storage | null | undefined,
  progress: WpmLadderProgress
): void {
  if (!storage) return;
  const normalizedRuns: WpmLadderRun[] = [];
  for (const entry of progress.runs.slice(-MAX_RUNS)) {
    const normalized = normalizeRun(entry);
    if (normalized) {
      normalizedRuns.push(normalized);
    }
  }
  const payload: WpmLadderProgress = {
    version: WPM_LADDER_VERSION,
    runs: normalizedRuns,
    updatedAt: progress.updatedAt ?? new Date().toISOString()
  };
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch {
    // ignore persistence failures
  }
}

export function recordWpmLadderRun(
  progress: WpmLadderProgress,
  summary: TypingDrillSummary
): { progress: WpmLadderProgress; run: WpmLadderRun; improvedMode: TypingDrillMode | null } {
  const run: WpmLadderRun = {
    id: `wpm-${Date.now().toString(36)}`,
    mode: normalizeMode(summary.mode),
    wpm: clampNonNegative(summary.wpm),
    accuracy: clampRatio(summary.accuracy),
    bestCombo: clampNonNegative(summary.bestCombo),
    errors: clampNonNegative(summary.errors),
    elapsedMs: clampNonNegative(summary.elapsedMs),
    timestamp: Number.isFinite(summary.timestamp) ? (summary.timestamp as number) : Date.now()
  };
  const nextRuns = [...progress.runs, run];
  if (nextRuns.length > MAX_RUNS) {
    nextRuns.splice(0, nextRuns.length - MAX_RUNS);
  }
  const nextProgress: WpmLadderProgress = {
    version: WPM_LADDER_VERSION,
    runs: nextRuns,
    updatedAt: new Date().toISOString()
  };
  const previousBest = findBestRunForMode(progress.runs, run.mode);
  const nextBest = findBestRunForMode(nextRuns, run.mode);
  const improved =
    !!nextBest &&
    nextBest.id === run.id &&
    (!previousBest ||
      nextBest.wpm > previousBest.wpm ||
      (nextBest.wpm === previousBest.wpm && nextBest.accuracy > previousBest.accuracy));
  return { progress: nextProgress, run, improvedMode: improved ? run.mode : null };
}

export function buildWpmLadderView(progress: WpmLadderProgress): WpmLadderViewState {
  const runs = progress.runs ?? [];
  const byMode: Record<TypingDrillMode, WpmLadderRun[]> = {
    burst: [],
    warmup: [],
    endurance: [],
    sprint: [],
    sentences: [],
    reading: [],
    rhythm: [],
    reaction: [],
    combo: [],
    precision: [],
    symbols: [],
    placement: [],
    hand: [],
    support: [],
    shortcuts: [],
    shift: [],
    focus: []
  };
  for (const run of runs) {
    byMode[run.mode]?.push(run);
  }
  const ladderByMode: WpmLadderViewState["ladderByMode"] = {
    burst: (byMode.burst ?? []).sort(sortRuns).slice(0, 5),
    warmup: (byMode.warmup ?? []).sort(sortRuns).slice(0, 5),
    endurance: (byMode.endurance ?? []).sort(sortRuns).slice(0, 5),
    sprint: (byMode.sprint ?? []).sort(sortRuns).slice(0, 5),
    sentences: (byMode.sentences ?? []).sort(sortRuns).slice(0, 5),
    reading: (byMode.reading ?? []).sort(sortRuns).slice(0, 5),
    rhythm: (byMode.rhythm ?? []).sort(sortRuns).slice(0, 5),
    reaction: (byMode.reaction ?? []).sort(sortRuns).slice(0, 5),
    combo: (byMode.combo ?? []).sort(sortRuns).slice(0, 5),
    precision: (byMode.precision ?? []).sort(sortRuns).slice(0, 5),
    symbols: (byMode.symbols ?? []).sort(sortRuns).slice(0, 5),
    placement: (byMode.placement ?? []).sort(sortRuns).slice(0, 5),
    hand: (byMode.hand ?? []).sort(sortRuns).slice(0, 5),
    support: (byMode.support ?? []).sort(sortRuns).slice(0, 5),
    shortcuts: (byMode.shortcuts ?? []).sort(sortRuns).slice(0, 5),
    shift: (byMode.shift ?? []).sort(sortRuns).slice(0, 5),
    focus: (byMode.focus ?? []).sort(sortRuns).slice(0, 5)
  };
  const bestByMode: Record<TypingDrillMode, WpmLadderRun | null> = {
    burst: ladderByMode.burst[0] ?? null,
    warmup: ladderByMode.warmup[0] ?? null,
    endurance: ladderByMode.endurance[0] ?? null,
    sprint: ladderByMode.sprint[0] ?? null,
    sentences: ladderByMode.sentences[0] ?? null,
    reading: ladderByMode.reading[0] ?? null,
    rhythm: ladderByMode.rhythm[0] ?? null,
    reaction: ladderByMode.reaction[0] ?? null,
    combo: ladderByMode.combo[0] ?? null,
    precision: ladderByMode.precision[0] ?? null,
    symbols: ladderByMode.symbols[0] ?? null,
    placement: ladderByMode.placement[0] ?? null,
    hand: ladderByMode.hand[0] ?? null,
    support: ladderByMode.support[0] ?? null,
    shortcuts: ladderByMode.shortcuts[0] ?? null,
    shift: ladderByMode.shift[0] ?? null,
    focus: ladderByMode.focus[0] ?? null
  };
  const topRuns = [...runs].sort(sortRuns).slice(0, 6);
  const lastRun = runs.length > 0 ? runs[runs.length - 1] : null;
  return {
    totalRuns: runs.length,
    updatedAt: progress.updatedAt ?? null,
    lastRun,
    bestByMode,
    ladderByMode,
    topRuns
  };
}
