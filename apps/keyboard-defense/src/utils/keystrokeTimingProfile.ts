import { summarizeKeystrokeTimings } from "./keystrokeTimingReport.js";

const STORAGE_KEY = "keyboard-defense:keystroke-timing-profile";
export const KEYSTROKE_TIMING_PROFILE_VERSION = "v1";
export const KEYSTROKE_TIMING_PROFILE_MIN_SAMPLES = 30;

export type KeystrokeTimingBand = "starter" | "steady" | "swift" | "turbo";

export type KeystrokeTimingProfileModel = {
  runs: number;
  medianMsEma: number;
  jitterMsEma: number;
  tempoWpmEma: number;
};

export type KeystrokeTimingProfileRun = {
  capturedAt: string;
  outcome: "victory" | "defeat";
  sampleCount: number;
  medianMs: number | null;
  p90Ms: number | null;
  jitterMs: number | null;
  tempoWpm: number | null;
  band: KeystrokeTimingBand | null;
};

export type KeystrokeTimingProfileState = {
  version: string;
  model: KeystrokeTimingProfileModel;
  lastRun: KeystrokeTimingProfileRun | null;
  updatedAt: string;
};

export type KeystrokeTimingGateSnapshot = {
  sampleCount: number;
  medianMs: number | null;
  p90Ms: number | null;
  jitterMs: number | null;
  tempoWpm: number | null;
  band: KeystrokeTimingBand | null;
  multiplier: number;
  source: "live" | "model" | "pending";
};

const DEFAULT_MODEL: KeystrokeTimingProfileModel = {
  runs: 0,
  medianMsEma: 320,
  jitterMsEma: 140,
  tempoWpmEma: 35
};

const DEFAULT_STATE: KeystrokeTimingProfileState = {
  version: KEYSTROKE_TIMING_PROFILE_VERSION,
  model: { ...DEFAULT_MODEL },
  lastRun: null,
  updatedAt: new Date().toISOString()
};

const SMOOTHING_ALPHA = 0.2;
const MIN_GATE_MULTIPLIER = 0.85;
const MAX_GATE_MULTIPLIER = 1;

function clampNonNegative(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, value);
}

function clampNumber(value: unknown, min: number, max: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return min;
  return Math.max(min, Math.min(max, value));
}

function roundTo(value: number, decimals: number): number {
  if (!Number.isFinite(value)) return 0;
  const factor = 10 ** Math.max(0, Math.floor(clampNonNegative(decimals)));
  return Math.round(value * factor) / factor;
}

function updateEma(previous: number, next: number, alpha: number): number {
  if (!Number.isFinite(previous)) return next;
  const clampedAlpha = clampNumber(alpha, 0, 1);
  return previous * (1 - clampedAlpha) + next * clampedAlpha;
}

function normalizeBand(value: unknown): KeystrokeTimingBand | null {
  return value === "starter" || value === "steady" || value === "swift" || value === "turbo"
    ? value
    : null;
}

function normalizeOutcome(value: unknown): "victory" | "defeat" {
  return value === "victory" ? "victory" : "defeat";
}

function normalizeModel(raw: unknown): KeystrokeTimingProfileModel {
  if (!raw || typeof raw !== "object") return { ...DEFAULT_MODEL };
  const data = raw as Record<string, unknown>;
  return {
    runs: Math.max(0, Math.floor(clampNonNegative(data.runs))),
    medianMsEma: clampNumber(data.medianMsEma, 40, 2500),
    jitterMsEma: clampNumber(data.jitterMsEma, 0, 2000),
    tempoWpmEma: clampNumber(data.tempoWpmEma, 0, 200)
  };
}

function normalizeRun(raw: unknown): KeystrokeTimingProfileRun | null {
  if (!raw || typeof raw !== "object") return null;
  const data = raw as Record<string, unknown>;
  const capturedAt =
    typeof data.capturedAt === "string" && data.capturedAt.length > 0
      ? data.capturedAt
      : new Date().toISOString();
  const outcome = normalizeOutcome(data.outcome);
  const sampleCount = Math.max(0, Math.floor(clampNonNegative(data.sampleCount)));
  const medianMs = typeof data.medianMs === "number" && Number.isFinite(data.medianMs) ? data.medianMs : null;
  const p90Ms = typeof data.p90Ms === "number" && Number.isFinite(data.p90Ms) ? data.p90Ms : null;
  const jitterMs = typeof data.jitterMs === "number" && Number.isFinite(data.jitterMs) ? data.jitterMs : null;
  const tempoWpm = typeof data.tempoWpm === "number" && Number.isFinite(data.tempoWpm) ? data.tempoWpm : null;
  const band = normalizeBand(data.band);
  return {
    capturedAt,
    outcome,
    sampleCount,
    medianMs,
    p90Ms,
    jitterMs,
    tempoWpm,
    band
  };
}

export function createDefaultKeystrokeTimingProfileState(): KeystrokeTimingProfileState {
  return structuredClone(DEFAULT_STATE);
}

export function readKeystrokeTimingProfile(storage: Storage | null | undefined): KeystrokeTimingProfileState {
  if (!storage) return createDefaultKeystrokeTimingProfileState();
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return createDefaultKeystrokeTimingProfileState();
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return createDefaultKeystrokeTimingProfileState();
    if (parsed.version !== KEYSTROKE_TIMING_PROFILE_VERSION) return createDefaultKeystrokeTimingProfileState();
    const model = normalizeModel(parsed.model);
    const lastRun = normalizeRun(parsed.lastRun);
    const updatedAt =
      typeof parsed.updatedAt === "string" && parsed.updatedAt.length > 0 ? parsed.updatedAt : new Date().toISOString();
    return {
      version: KEYSTROKE_TIMING_PROFILE_VERSION,
      model,
      lastRun,
      updatedAt
    };
  } catch {
    return createDefaultKeystrokeTimingProfileState();
  }
}

export function writeKeystrokeTimingProfile(
  storage: Storage | null | undefined,
  state: KeystrokeTimingProfileState
): KeystrokeTimingProfileState {
  if (!storage) return state;
  const normalized: KeystrokeTimingProfileState = {
    version: KEYSTROKE_TIMING_PROFILE_VERSION,
    model: normalizeModel(state.model),
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

export function computeTempoWpmFromMedianMs(medianMs: number): number {
  if (!Number.isFinite(medianMs) || medianMs <= 0) return 0;
  return Math.max(0, Math.round(12000 / Math.max(1, medianMs)));
}

export function classifyTempoBand(tempoWpm: number | null): KeystrokeTimingBand | null {
  if (typeof tempoWpm !== "number" || !Number.isFinite(tempoWpm)) return null;
  if (tempoWpm < 20) return "starter";
  if (tempoWpm < 35) return "steady";
  if (tempoWpm < 50) return "swift";
  return "turbo";
}

export function buildKeystrokeTimingMetrics(samples: number[]): Omit<KeystrokeTimingGateSnapshot, "multiplier" | "source"> {
  const summary = summarizeKeystrokeTimings(samples);
  const sampleCount = summary.count;
  const medianMs = typeof summary.p50Ms === "number" && Number.isFinite(summary.p50Ms) ? summary.p50Ms : null;
  const p90Ms = typeof summary.p90Ms === "number" && Number.isFinite(summary.p90Ms) ? summary.p90Ms : null;
  const jitterMs =
    typeof medianMs === "number" && typeof p90Ms === "number" ? Math.max(0, p90Ms - medianMs) : null;
  const tempoWpm = typeof medianMs === "number" ? computeTempoWpmFromMedianMs(medianMs) : null;
  const band = classifyTempoBand(tempoWpm);
  return { sampleCount, medianMs, p90Ms, jitterMs, tempoWpm, band };
}

export function computeSpawnSpeedGateMultiplier(metrics: {
  sampleCount: number;
  medianMs: number | null;
  jitterMs: number | null;
  tempoWpm: number | null;
}): number {
  if (
    metrics.sampleCount < KEYSTROKE_TIMING_PROFILE_MIN_SAMPLES ||
    typeof metrics.medianMs !== "number" ||
    typeof metrics.jitterMs !== "number" ||
    typeof metrics.tempoWpm !== "number"
  ) {
    return 1;
  }

  const jitterScore = clampNumber((metrics.jitterMs - 90) / 170, 0, 1);
  const tempoScore = clampNumber((32 - metrics.tempoWpm) / 14, 0, 1);
  const penalty = jitterScore * 0.12 + tempoScore * 0.08;
  const multiplier = clampNumber(1 - penalty, MIN_GATE_MULTIPLIER, MAX_GATE_MULTIPLIER);
  return roundTo(multiplier, 2);
}

export function buildKeystrokeTimingGate(options: {
  samples: number[];
  profile?: KeystrokeTimingProfileState | null | undefined;
}): KeystrokeTimingGateSnapshot {
  const metrics = buildKeystrokeTimingMetrics(options.samples);
  if (metrics.sampleCount >= KEYSTROKE_TIMING_PROFILE_MIN_SAMPLES) {
    return {
      ...metrics,
      multiplier: computeSpawnSpeedGateMultiplier({
        sampleCount: metrics.sampleCount,
        medianMs: metrics.medianMs,
        jitterMs: metrics.jitterMs,
        tempoWpm: metrics.tempoWpm
      }),
      source: "live"
    };
  }

  const model = options.profile?.model;
  if (model && model.runs > 0) {
    const medianMs = clampNumber(model.medianMsEma, 40, 2500);
    const jitterMs = clampNumber(model.jitterMsEma, 0, 2000);
    const tempoWpm = computeTempoWpmFromMedianMs(medianMs);
    const band = classifyTempoBand(tempoWpm);
    const multiplier = computeSpawnSpeedGateMultiplier({
      sampleCount: KEYSTROKE_TIMING_PROFILE_MIN_SAMPLES,
      medianMs,
      jitterMs,
      tempoWpm
    });
    return {
      sampleCount: metrics.sampleCount,
      medianMs,
      p90Ms: medianMs + jitterMs,
      jitterMs,
      tempoWpm,
      band,
      multiplier,
      source: "model"
    };
  }

  return {
    ...metrics,
    multiplier: 1,
    source: "pending"
  };
}

export function recordKeystrokeTimingProfileRun(
  state: KeystrokeTimingProfileState,
  run: { capturedAt: string; outcome: "victory" | "defeat"; samples: number[] }
): KeystrokeTimingProfileState {
  const previous = readKeystrokeTimingProfile(null);
  const current = state && typeof state === "object" ? state : previous;
  const model = normalizeModel(current.model);
  const metrics = buildKeystrokeTimingMetrics(run.samples);

  const lastRun: KeystrokeTimingProfileRun = {
    capturedAt: run.capturedAt,
    outcome: run.outcome,
    ...metrics
  };

  if (
    metrics.sampleCount < KEYSTROKE_TIMING_PROFILE_MIN_SAMPLES ||
    typeof metrics.medianMs !== "number" ||
    typeof metrics.jitterMs !== "number" ||
    typeof metrics.tempoWpm !== "number"
  ) {
    return {
      version: KEYSTROKE_TIMING_PROFILE_VERSION,
      model,
      lastRun,
      updatedAt: new Date().toISOString()
    };
  }

  const firstRun = model.runs <= 0;
  const nextModel: KeystrokeTimingProfileModel = {
    runs: model.runs + 1,
    medianMsEma: clampNumber(
      firstRun ? metrics.medianMs : updateEma(model.medianMsEma, metrics.medianMs, SMOOTHING_ALPHA),
      40,
      2500
    ),
    jitterMsEma: clampNumber(
      firstRun ? metrics.jitterMs : updateEma(model.jitterMsEma, metrics.jitterMs, SMOOTHING_ALPHA),
      0,
      2000
    ),
    tempoWpmEma: clampNumber(
      firstRun ? metrics.tempoWpm : updateEma(model.tempoWpmEma, metrics.tempoWpm, SMOOTHING_ALPHA),
      0,
      200
    )
  };

  return {
    version: KEYSTROKE_TIMING_PROFILE_VERSION,
    model: nextModel,
    lastRun,
    updatedAt: new Date().toISOString()
  };
}

