export type StuckKeyDetectorState = {
  key: string | null;
  streak: number;
  lastEventAt: number | null;
  lastWarningAt: number | null;
  warnedKeys: Set<string>;
};

export type StuckKeyDetectorOptions = {
  streakThreshold?: number;
  maxGapMs?: number;
  cooldownMs?: number;
};

export type StuckKeyWarning = {
  kind: "stuck-key";
  key: string;
  streak: number;
};

const DEFAULT_STREAK_THRESHOLD = 8;
const DEFAULT_MAX_GAP_MS = 450;
const DEFAULT_COOLDOWN_MS = 25_000;

export function createStuckKeyDetectorState(): StuckKeyDetectorState {
  return {
    key: null,
    streak: 0,
    lastEventAt: null,
    lastWarningAt: null,
    warnedKeys: new Set<string>()
  };
}

function clampPositiveInteger(value: unknown, fallback: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return fallback;
  return Math.max(1, Math.floor(value));
}

function isSingleChar(value: unknown): value is string {
  return typeof value === "string" && value.length === 1;
}

export function updateStuckKeyDetector(
  state: StuckKeyDetectorState,
  sample: { expected: unknown; received: unknown },
  nowMs: number,
  options: StuckKeyDetectorOptions = {}
): { state: StuckKeyDetectorState; warning: StuckKeyWarning | null } {
  const streakThreshold = clampPositiveInteger(options.streakThreshold, DEFAULT_STREAK_THRESHOLD);
  const maxGapMs = clampPositiveInteger(options.maxGapMs, DEFAULT_MAX_GAP_MS);
  const cooldownMs = clampPositiveInteger(options.cooldownMs, DEFAULT_COOLDOWN_MS);

  const rawExpected = sample?.expected;
  const rawReceived = sample?.received;
  if (!isSingleChar(rawReceived) || !isSingleChar(rawExpected)) {
    return { state, warning: null };
  }
  const expected = /[a-z]/i.test(rawExpected) ? rawExpected.toLowerCase() : rawExpected;
  const received = /[a-z]/i.test(rawReceived) ? rawReceived.toLowerCase() : rawReceived;
  if (received === expected) {
    return { state, warning: null };
  }
  if (typeof nowMs !== "number" || !Number.isFinite(nowMs) || nowMs < 0) {
    return { state, warning: null };
  }

  const hasGap =
    typeof state.lastEventAt === "number" && Number.isFinite(state.lastEventAt)
      ? nowMs - state.lastEventAt > maxGapMs
      : true;
  const sameKey = state.key === received && !hasGap;
  const nextStreak = sameKey ? state.streak + 1 : 1;
  const next: StuckKeyDetectorState = {
    key: received,
    streak: nextStreak,
    lastEventAt: nowMs,
    lastWarningAt: state.lastWarningAt,
    warnedKeys: state.warnedKeys
  };

  const alreadyWarned = next.warnedKeys.has(received);
  const lastWarningAge =
    typeof next.lastWarningAt === "number" && Number.isFinite(next.lastWarningAt)
      ? nowMs - next.lastWarningAt
      : Number.POSITIVE_INFINITY;
  const canWarn = !alreadyWarned && nextStreak >= streakThreshold && lastWarningAge >= cooldownMs;
  if (!canWarn) {
    return { state: next, warning: null };
  }

  const warnedKeys = new Set(next.warnedKeys);
  warnedKeys.add(received);
  const updated: StuckKeyDetectorState = {
    ...next,
    lastWarningAt: nowMs,
    warnedKeys
  };
  return {
    state: updated,
    warning: { kind: "stuck-key", key: received, streak: nextStreak }
  };
}
