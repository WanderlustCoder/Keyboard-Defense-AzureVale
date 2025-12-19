import { type GameMode, type GameStatus, type WaveSummary } from "../core/types.js";

const STORAGE_KEY = "keyboard-defense:session-goals";
export const SESSION_GOALS_VERSION = "v1";
export const SESSION_GOALS_CONSISTENCY_WAVES = 3;

export type SessionGoalStatus = "pending" | "in-progress" | "met" | "missed";

export type SessionGoalsTargets = {
  accuracyPct: number;
  wpm: number;
  consistencyRangePct: number;
};

export type SessionGoalsModel = {
  runs: number;
  accuracyEma: number;
  wpmEma: number;
  consistencyRangeEma: number;
};

export type SessionGoalsRunMetrics = {
  durationSeconds: number;
  wavesCompleted: number;
  accuracyPct: number;
  wpm: number;
  consistencyRangePct: number | null;
  consistencyWaveCount: number;
};

export type SessionGoalsRunRecord = {
  capturedAt: string;
  mode: GameMode;
  outcome: "victory" | "defeat";
  goals: SessionGoalsTargets;
  metrics: SessionGoalsRunMetrics;
  results: {
    accuracy: SessionGoalStatus;
    wpm: SessionGoalStatus;
    consistency: SessionGoalStatus;
  };
};

export type SessionGoalsState = {
  version: string;
  model: SessionGoalsModel;
  goals: SessionGoalsTargets;
  seededFromPlacement?: boolean;
  lastRun: SessionGoalsRunRecord | null;
  updatedAt: string;
};

export type SessionGoalsViewGoal = {
  id: "accuracy" | "wpm" | "consistency";
  label: string;
  status: SessionGoalStatus;
};

export type SessionGoalsViewState = {
  summary: string;
  goals: SessionGoalsViewGoal[];
  lastRun: SessionGoalsRunRecord | null;
};

const DEFAULT_GOALS: SessionGoalsTargets = {
  accuracyPct: 90,
  wpm: 25,
  consistencyRangePct: 12
};

const DEFAULT_MODEL: SessionGoalsModel = {
  runs: 0,
  accuracyEma: 0.89,
  wpmEma: 23,
  consistencyRangeEma: 13
};

const DEFAULT_STATE: SessionGoalsState = {
  version: SESSION_GOALS_VERSION,
  model: { ...DEFAULT_MODEL },
  goals: { ...DEFAULT_GOALS },
  lastRun: null,
  updatedAt: new Date().toISOString()
};

const SMOOTHING_ALPHA = 0.2;
const ACCURACY_CHALLENGE_PCT = 1;
const WPM_CHALLENGE = 2;
const CONSISTENCY_IMPROVE_FACTOR = 0.9;
const MAX_ACCURACY_DELTA_PCT = 2;
const MAX_WPM_DELTA = 6;
const MAX_CONSISTENCY_DELTA_PCT = 2;

function clampRatio(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

function clampNonNegative(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, value);
}

function clampNumber(value: unknown, min: number, max: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return min;
  return Math.max(min, Math.min(max, value));
}

function roundTo(value: number, step: number): number {
  if (!Number.isFinite(value) || !Number.isFinite(step) || step <= 0) return 0;
  return Math.round(value / step) * step;
}

function limitDelta(previous: number, next: number, maxDelta: number): number {
  if (!Number.isFinite(previous)) return next;
  if (!Number.isFinite(next)) return previous;
  const delta = next - previous;
  const limited = Math.max(-maxDelta, Math.min(maxDelta, delta));
  return previous + limited;
}

function normalizeTargets(raw: unknown): SessionGoalsTargets {
  if (!raw || typeof raw !== "object") return { ...DEFAULT_GOALS };
  const data = raw as Record<string, unknown>;
  return {
    accuracyPct: clampNumber(data.accuracyPct, 70, 99.9),
    wpm: Math.round(clampNumber(data.wpm, 5, 200)),
    consistencyRangePct: clampNumber(data.consistencyRangePct, 2, 30)
  };
}

function normalizeModel(raw: unknown): SessionGoalsModel {
  if (!raw || typeof raw !== "object") return { ...DEFAULT_MODEL };
  const data = raw as Record<string, unknown>;
  return {
    runs: Math.max(0, Math.floor(clampNonNegative(data.runs))),
    accuracyEma: clampRatio(data.accuracyEma),
    wpmEma: clampNonNegative(data.wpmEma),
    consistencyRangeEma: clampNumber(data.consistencyRangeEma, 0, 50)
  };
}

function deriveTargets(model: SessionGoalsModel, previous?: SessionGoalsTargets | null): SessionGoalsTargets {
  const baseAccuracy = clampNumber(model.accuracyEma * 100 + ACCURACY_CHALLENGE_PCT, 75, 99);
  const baseWpm = clampNumber(model.wpmEma + WPM_CHALLENGE, 8, 160);
  const baseConsistency = clampNumber(model.consistencyRangeEma * CONSISTENCY_IMPROVE_FACTOR, 3, 25);

  const next: SessionGoalsTargets = {
    accuracyPct: roundTo(baseAccuracy, 0.5),
    wpm: Math.round(baseWpm),
    consistencyRangePct: roundTo(baseConsistency, 0.5)
  };

  if (!previous) return next;
  return {
    accuracyPct: roundTo(limitDelta(previous.accuracyPct, next.accuracyPct, MAX_ACCURACY_DELTA_PCT), 0.5),
    wpm: Math.round(limitDelta(previous.wpm, next.wpm, MAX_WPM_DELTA)),
    consistencyRangePct: roundTo(
      limitDelta(previous.consistencyRangePct, next.consistencyRangePct, MAX_CONSISTENCY_DELTA_PCT),
      0.5
    )
  };
}

function normalizeMode(value: unknown): GameMode {
  return value === "practice" ? "practice" : "campaign";
}

function normalizeOutcome(value: unknown): "victory" | "defeat" {
  return value === "victory" ? "victory" : "defeat";
}

function normalizeGoalStatus(value: unknown): SessionGoalStatus {
  return value === "met" || value === "missed" || value === "in-progress" ? value : "pending";
}

function normalizeRunMetrics(raw: unknown): SessionGoalsRunMetrics {
  if (!raw || typeof raw !== "object") {
    return {
      durationSeconds: 0,
      wavesCompleted: 0,
      accuracyPct: 0,
      wpm: 0,
      consistencyRangePct: null,
      consistencyWaveCount: 0
    };
  }
  const data = raw as Record<string, unknown>;
  const consistencyRange =
    typeof data.consistencyRangePct === "number" && Number.isFinite(data.consistencyRangePct)
      ? clampNumber(data.consistencyRangePct, 0, 100)
      : null;
  return {
    durationSeconds: clampNonNegative(data.durationSeconds),
    wavesCompleted: Math.max(0, Math.floor(clampNonNegative(data.wavesCompleted))),
    accuracyPct: clampNumber(data.accuracyPct, 0, 100),
    wpm: Math.round(clampNonNegative(data.wpm)),
    consistencyRangePct: consistencyRange,
    consistencyWaveCount: Math.max(0, Math.floor(clampNonNegative(data.consistencyWaveCount)))
  };
}

function normalizeRunRecord(raw: unknown): SessionGoalsRunRecord | null {
  if (!raw || typeof raw !== "object") return null;
  const data = raw as Record<string, unknown>;
  const capturedAt =
    typeof data.capturedAt === "string" && data.capturedAt.length > 0
      ? data.capturedAt
      : new Date().toISOString();
  const mode = normalizeMode(data.mode);
  const outcome = normalizeOutcome(data.outcome);
  const goals = normalizeTargets(data.goals);
  const metrics = normalizeRunMetrics(data.metrics);
  const resultsRaw = data.results && typeof data.results === "object" ? (data.results as Record<string, unknown>) : null;
  const results = {
    accuracy: normalizeGoalStatus(resultsRaw?.accuracy),
    wpm: normalizeGoalStatus(resultsRaw?.wpm),
    consistency: normalizeGoalStatus(resultsRaw?.consistency)
  };
  return { capturedAt, mode, outcome, goals, metrics, results };
}

export function createDefaultSessionGoalsState(): SessionGoalsState {
  return structuredClone(DEFAULT_STATE);
}

export function readSessionGoals(storage: Storage | null | undefined): SessionGoalsState {
  if (!storage) return createDefaultSessionGoalsState();
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return createDefaultSessionGoalsState();
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return createDefaultSessionGoalsState();
    if (parsed.version !== SESSION_GOALS_VERSION) return createDefaultSessionGoalsState();
    const model = normalizeModel(parsed.model);
    const goals = normalizeTargets(parsed.goals);
    const seededFromPlacement = Boolean(parsed.seededFromPlacement);
    const lastRun = normalizeRunRecord(parsed.lastRun);
    const updatedAt =
      typeof parsed.updatedAt === "string" && parsed.updatedAt.length > 0 ? parsed.updatedAt : new Date().toISOString();
    return {
      version: SESSION_GOALS_VERSION,
      model,
      goals,
      seededFromPlacement,
      lastRun,
      updatedAt
    };
  } catch {
    return createDefaultSessionGoalsState();
  }
}

export function writeSessionGoals(storage: Storage | null | undefined, state: SessionGoalsState): SessionGoalsState {
  if (!storage) return state;
  const normalized: SessionGoalsState = {
    version: SESSION_GOALS_VERSION,
    model: normalizeModel(state.model),
    goals: normalizeTargets(state.goals),
    seededFromPlacement: Boolean(state.seededFromPlacement),
    lastRun: state.lastRun ?? null,
    updatedAt: state.updatedAt ?? new Date().toISOString()
  };
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(normalized));
  } catch {
    // ignore storage failures
  }
  return normalized;
}

export function resetSessionGoalsState(state: SessionGoalsState): SessionGoalsState {
  return {
    ...createDefaultSessionGoalsState(),
    seededFromPlacement: Boolean(state.seededFromPlacement)
  };
}

export function seedSessionGoalsFromPlacement(
  state: SessionGoalsState,
  placement: { accuracy: unknown; wpm: unknown } | null | undefined
): SessionGoalsState {
  if (!placement || typeof placement !== "object") return state;
  if (state.model?.runs > 0) return state;
  if (state.seededFromPlacement) return state;
  const accuracy = clampRatio((placement as Record<string, unknown>).accuracy);
  const wpm = clampNonNegative((placement as Record<string, unknown>).wpm);
  const nextModel: SessionGoalsModel = {
    ...normalizeModel(state.model),
    accuracyEma: accuracy > 0 ? accuracy : normalizeModel(state.model).accuracyEma,
    wpmEma: wpm > 0 ? wpm : normalizeModel(state.model).wpmEma
  };
  return {
    ...state,
    seededFromPlacement: true,
    model: nextModel,
    goals: deriveTargets(nextModel, state.goals),
    updatedAt: new Date().toISOString()
  };
}

export function computeSessionWpm(correctInputs: number, elapsedSeconds: number): number {
  const safeInputs = Math.max(0, Math.floor(clampNonNegative(correctInputs)));
  const minutes = Math.max(clampNonNegative(elapsedSeconds) / 60, 0.1);
  return Math.max(0, Math.round(safeInputs / 5 / minutes));
}

export function computeWaveAccuracyRangePct(
  waves: WaveSummary[],
  windowSize: number = SESSION_GOALS_CONSISTENCY_WAVES
): { rangePct: number | null; waveCount: number } {
  const resolvedWindow = Math.max(1, Math.floor(clampNonNegative(windowSize)));
  const list = Array.isArray(waves) ? waves.slice(-resolvedWindow) : [];
  const accuracies = list
    .map((entry) => (typeof entry.accuracy === "number" && Number.isFinite(entry.accuracy) ? entry.accuracy : null))
    .filter((value): value is number => typeof value === "number");
  const count = accuracies.length;
  if (count < resolvedWindow) {
    return { rangePct: null, waveCount: count };
  }
  const min = Math.min(...accuracies);
  const max = Math.max(...accuracies);
  const rangePct = Math.max(0, (max - min) * 100);
  return { rangePct: Math.round(rangePct * 10) / 10, waveCount: count };
}

export function buildSessionGoalsMetrics(options: {
  mode: GameMode;
  status: GameStatus;
  elapsedSeconds: number;
  correctInputs: number;
  accuracy: number;
  waveSummaries: WaveSummary[];
}): SessionGoalsRunMetrics {
  const waveSummaries = Array.isArray(options.waveSummaries) ? options.waveSummaries : [];
  const range = computeWaveAccuracyRangePct(waveSummaries, SESSION_GOALS_CONSISTENCY_WAVES);
  const elapsedSeconds = clampNonNegative(options.elapsedSeconds);
  return {
    durationSeconds: elapsedSeconds,
    wavesCompleted: waveSummaries.length,
    accuracyPct: Math.round(clampRatio(options.accuracy) * 1000) / 10,
    wpm: computeSessionWpm(options.correctInputs, elapsedSeconds),
    consistencyRangePct: range.rangePct,
    consistencyWaveCount: range.waveCount
  };
}

export function evaluateSessionGoals(
  goals: SessionGoalsTargets,
  metrics: SessionGoalsRunMetrics,
  context: { status: GameStatus }
): SessionGoalsRunRecord["results"] {
  const ended = context.status === "victory" || context.status === "defeat";
  const accuracyMet = metrics.accuracyPct >= goals.accuracyPct;
  const wpmMet = metrics.wpm >= goals.wpm;
  const consistencyMet =
    typeof metrics.consistencyRangePct === "number" && Number.isFinite(metrics.consistencyRangePct)
      ? metrics.consistencyRangePct <= goals.consistencyRangePct
      : null;

  return {
    accuracy: accuracyMet ? "met" : ended ? "missed" : "in-progress",
    wpm: wpmMet ? "met" : ended ? "missed" : "in-progress",
    consistency:
      consistencyMet === null
        ? "pending"
        : consistencyMet
          ? "met"
          : ended
            ? "missed"
            : "in-progress"
  };
}

export function recordSessionGoalsRun(
  state: SessionGoalsState,
  run: {
    capturedAt: string;
    mode: GameMode;
    outcome: "victory" | "defeat";
    metrics: SessionGoalsRunMetrics;
    status: GameStatus;
  }
): SessionGoalsState {
  const previous = readSessionGoals(null);
  const current = state && typeof state === "object" ? state : previous;
  const model = normalizeModel(current.model);
  const goals = normalizeTargets(current.goals);

  const nextModel: SessionGoalsModel = {
    ...model,
    runs: model.runs + 1,
    accuracyEma:
      model.accuracyEma * (1 - SMOOTHING_ALPHA) +
      (clampNumber(run.metrics.accuracyPct, 0, 100) / 100) * SMOOTHING_ALPHA,
    wpmEma: model.wpmEma * (1 - SMOOTHING_ALPHA) + clampNonNegative(run.metrics.wpm) * SMOOTHING_ALPHA,
    consistencyRangeEma: model.consistencyRangeEma
  };
  if (typeof run.metrics.consistencyRangePct === "number" && Number.isFinite(run.metrics.consistencyRangePct)) {
    nextModel.consistencyRangeEma =
      model.consistencyRangeEma * (1 - SMOOTHING_ALPHA) + run.metrics.consistencyRangePct * SMOOTHING_ALPHA;
  }

  const nextGoals = deriveTargets(nextModel, goals);
  const results = evaluateSessionGoals(goals, run.metrics, { status: run.status });
  const lastRun: SessionGoalsRunRecord = {
    capturedAt: run.capturedAt,
    mode: run.mode,
    outcome: run.outcome,
    goals,
    metrics: run.metrics,
    results
  };
  return {
    version: SESSION_GOALS_VERSION,
    model: nextModel,
    goals: nextGoals,
    seededFromPlacement: Boolean(current.seededFromPlacement),
    lastRun,
    updatedAt: new Date().toISOString()
  };
}

export function buildSessionGoalsView(
  state: SessionGoalsState,
  metrics: SessionGoalsRunMetrics,
  status: GameStatus
): SessionGoalsViewState {
  const goals = normalizeTargets(state.goals);
  const showNextGoals = status === "victory" || status === "defeat";
  const results: SessionGoalsRunRecord["results"] = showNextGoals
    ? { accuracy: "pending", wpm: "pending", consistency: "pending" }
    : evaluateSessionGoals(goals, metrics, { status });

  const goalViews: SessionGoalsViewGoal[] = [
    {
      id: "accuracy",
      label: showNextGoals
        ? `Accuracy ≥ ${goals.accuracyPct.toFixed(goals.accuracyPct % 1 === 0 ? 0 : 1)}%`
        : `Accuracy ≥ ${goals.accuracyPct.toFixed(goals.accuracyPct % 1 === 0 ? 0 : 1)}% (now ${metrics.accuracyPct.toFixed(1)}%)`,
      status: results.accuracy
    },
    {
      id: "wpm",
      label: showNextGoals ? `Speed ≥ ${goals.wpm} WPM` : `Speed ≥ ${goals.wpm} WPM (now ${metrics.wpm})`,
      status: results.wpm
    },
    {
      id: "consistency",
      label: showNextGoals
        ? `Consistency ≤ ${goals.consistencyRangePct.toFixed(1)}% spread (last ${SESSION_GOALS_CONSISTENCY_WAVES} waves)`
        : (() => {
            const consistencyLabel =
              typeof metrics.consistencyRangePct === "number" && Number.isFinite(metrics.consistencyRangePct)
                ? `${metrics.consistencyRangePct.toFixed(1)}%`
                : `${metrics.consistencyWaveCount}/${SESSION_GOALS_CONSISTENCY_WAVES} waves`;
            return `Consistency ≤ ${goals.consistencyRangePct.toFixed(1)}% spread (last ${SESSION_GOALS_CONSISTENCY_WAVES}: ${consistencyLabel})`;
          })(),
      status: results.consistency
    }
  ];

  let summary = "Adaptive session goals tune after each run.";
  const lastRun = state.lastRun ?? null;
  if (lastRun) {
    const statuses = [lastRun.results.accuracy, lastRun.results.wpm, lastRun.results.consistency];
    const completed = statuses.filter((entry) => entry === "met").length;
    const total = statuses.filter((entry) => entry !== "pending").length || statuses.length;
    summary = `Last run: ${completed}/${total} goals met (${lastRun.outcome}). New goals ready.`;
  }
  return { summary, goals: goalViews, lastRun };
}
