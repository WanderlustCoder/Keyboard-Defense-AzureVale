export type FatigueWaveSample = {
  waveIndex: number;
  capturedAtMs: number;
  accuracy: number;
  p50Ms: number | null;
  p90Ms: number | null;
};

export type FatiguePrompt = {
  kind: "fatigue-break";
  message: string;
  accuracyDropPct: number;
  latencyRiseMs: number;
};

export type FatigueDetectorState = {
  history: FatigueWaveSample[];
  lastPromptAtMs: number | null;
  snoozedUntilMs: number | null;
};

export type FatigueDetectorOptions = {
  maxHistory?: number;
  minHistory?: number;
  recentWindow?: number;
  baselineWindow?: number;
  minSessionMs?: number;
  minBaselineAccuracy?: number;
  minAccuracyDrop?: number;
  minLatencyRiseMs?: number;
  minLatencyRisePct?: number;
  cooldownMs?: number;
};

const DEFAULT_MAX_HISTORY = 18;
const DEFAULT_MIN_HISTORY = 4;
const DEFAULT_RECENT_WINDOW = 2;
const DEFAULT_BASELINE_WINDOW = 4;
const DEFAULT_MIN_SESSION_MS = 4 * 60_000;
const DEFAULT_MIN_BASELINE_ACCURACY = 0.86;
const DEFAULT_MIN_ACCURACY_DROP = 0.06;
const DEFAULT_MIN_LATENCY_RISE_MS = 60;
const DEFAULT_MIN_LATENCY_RISE_PCT = 0.18;
const DEFAULT_COOLDOWN_MS = 12 * 60_000;

function clampPositiveInteger(value: unknown, fallback: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return fallback;
  return Math.max(1, Math.floor(value));
}

function clampNonNegativeNumber(value: unknown, fallback: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return fallback;
  return Math.max(0, value);
}

function normalizeAccuracy(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  return Math.max(0, Math.min(1, value));
}

function normalizeLatency(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  if (value <= 0) return null;
  return value;
}

function mean(values: number[]): number | null {
  if (values.length === 0) return null;
  const sum = values.reduce((acc, value) => acc + value, 0);
  return sum / values.length;
}

export function createFatigueDetectorState(): FatigueDetectorState {
  return { history: [], lastPromptAtMs: null, snoozedUntilMs: null };
}

export function snoozeFatigueDetector(
  state: FatigueDetectorState,
  nowMs: number,
  durationMs: number
): FatigueDetectorState {
  const normalizedNow = clampNonNegativeNumber(nowMs, 0);
  const duration = clampPositiveInteger(durationMs, DEFAULT_COOLDOWN_MS);
  return {
    ...state,
    snoozedUntilMs: normalizedNow + duration
  };
}

export function updateFatigueDetector(
  state: FatigueDetectorState,
  sample: {
    waveIndex: unknown;
    capturedAtMs: unknown;
    accuracy: unknown;
    p50Ms?: unknown;
    p90Ms?: unknown;
  },
  options: FatigueDetectorOptions = {}
): { state: FatigueDetectorState; prompt: FatiguePrompt | null } {
  const maxHistory = clampPositiveInteger(options.maxHistory, DEFAULT_MAX_HISTORY);
  const minHistory = clampPositiveInteger(options.minHistory, DEFAULT_MIN_HISTORY);
  const recentWindow = clampPositiveInteger(options.recentWindow, DEFAULT_RECENT_WINDOW);
  const baselineWindow = clampPositiveInteger(options.baselineWindow, DEFAULT_BASELINE_WINDOW);
  const minSessionMs = clampPositiveInteger(options.minSessionMs, DEFAULT_MIN_SESSION_MS);
  const minBaselineAccuracy = normalizeAccuracy(options.minBaselineAccuracy) ?? DEFAULT_MIN_BASELINE_ACCURACY;
  const minAccuracyDrop = normalizeAccuracy(options.minAccuracyDrop) ?? DEFAULT_MIN_ACCURACY_DROP;
  const minLatencyRiseMs = clampPositiveInteger(options.minLatencyRiseMs, DEFAULT_MIN_LATENCY_RISE_MS);
  const minLatencyRisePct =
    typeof options.minLatencyRisePct === "number" && Number.isFinite(options.minLatencyRisePct)
      ? Math.max(0, options.minLatencyRisePct)
      : DEFAULT_MIN_LATENCY_RISE_PCT;
  const cooldownMs = clampPositiveInteger(options.cooldownMs, DEFAULT_COOLDOWN_MS);

  const waveIndex =
    typeof sample.waveIndex === "number" && Number.isFinite(sample.waveIndex)
      ? Math.max(0, Math.floor(sample.waveIndex))
      : null;
  const capturedAtMs = clampNonNegativeNumber(sample.capturedAtMs, 0);
  const accuracy = normalizeAccuracy(sample.accuracy);
  const p50Ms = normalizeLatency(sample.p50Ms);
  const p90Ms = normalizeLatency(sample.p90Ms);

  if (waveIndex === null || accuracy === null) {
    return { state, prompt: null };
  }

  const nextHistory = [
    ...(Array.isArray(state.history) ? state.history : []),
    { waveIndex, capturedAtMs, accuracy, p50Ms, p90Ms }
  ].slice(-maxHistory);

  const nextState: FatigueDetectorState = {
    history: nextHistory,
    lastPromptAtMs: state.lastPromptAtMs ?? null,
    snoozedUntilMs: state.snoozedUntilMs ?? null
  };

  if (capturedAtMs < minSessionMs) {
    return { state: nextState, prompt: null };
  }

  const snoozedUntil = nextState.snoozedUntilMs;
  if (typeof snoozedUntil === "number" && Number.isFinite(snoozedUntil) && capturedAtMs < snoozedUntil) {
    return { state: nextState, prompt: null };
  }

  const lastPrompt = nextState.lastPromptAtMs;
  const promptAge =
    typeof lastPrompt === "number" && Number.isFinite(lastPrompt)
      ? capturedAtMs - lastPrompt
      : Number.POSITIVE_INFINITY;
  if (promptAge >= 0 && promptAge < cooldownMs) {
    return { state: nextState, prompt: null };
  }

  if (nextHistory.length < minHistory) {
    return { state: nextState, prompt: null };
  }

  const recent = nextHistory.slice(-recentWindow);
  const baselineStart = Math.max(0, nextHistory.length - (recentWindow + baselineWindow));
  const baseline = nextHistory.slice(baselineStart, Math.max(baselineStart, nextHistory.length - recentWindow));
  if (recent.length === 0 || baseline.length === 0) {
    return { state: nextState, prompt: null };
  }

  const baselineAccuracy = Math.max(...baseline.map((entry) => entry.accuracy));
  if (!Number.isFinite(baselineAccuracy) || baselineAccuracy < minBaselineAccuracy) {
    return { state: nextState, prompt: null };
  }

  const baselineLatencies = baseline.map((entry) => entry.p50Ms).filter((value): value is number => {
    return typeof value === "number" && Number.isFinite(value) && value > 0;
  });
  const baselineLatency = baselineLatencies.length > 0 ? Math.min(...baselineLatencies) : null;
  if (baselineLatency === null) {
    return { state: nextState, prompt: null };
  }

  const recentAccuracy = mean(recent.map((entry) => entry.accuracy)) ?? accuracy;
  const recentLatencySamples = recent.map((entry) => entry.p50Ms).filter((value): value is number => {
    return typeof value === "number" && Number.isFinite(value) && value > 0;
  });
  const recentLatency = mean(recentLatencySamples);
  if (recentLatency === null) {
    return { state: nextState, prompt: null };
  }

  const accuracyDrop = baselineAccuracy - recentAccuracy;
  const requiredLatencyRise = Math.max(minLatencyRiseMs, baselineLatency * minLatencyRisePct);
  const latencyRise = recentLatency - baselineLatency;
  const shouldPrompt = accuracyDrop >= minAccuracyDrop && latencyRise >= requiredLatencyRise;
  if (!shouldPrompt) {
    return { state: nextState, prompt: null };
  }

  const accuracyDropPct = Math.round(accuracyDrop * 1000) / 10;
  const latencyRiseRounded = Math.round(latencyRise);
  const message =
    "Fatigue check: accuracy dipped and typing slowed. Consider a short stretch/water break before the next wave.";

  return {
    state: {
      ...nextState,
      lastPromptAtMs: capturedAtMs
    },
    prompt: {
      kind: "fatigue-break",
      message,
      accuracyDropPct,
      latencyRiseMs: latencyRiseRounded
    }
  };
}
