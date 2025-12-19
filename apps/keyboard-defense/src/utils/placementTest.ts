export const PLACEMENT_TEST_STORAGE_KEY = "keyboard-defense:placement-test";
export const PLACEMENT_TEST_VERSION = "v1";

export type PlacementHand = "left" | "right" | "neutral";
export type PlacementFocus = "balanced" | "left" | "right";

export type PlacementRecommendation = {
  tutorialPacing: number;
  focus: PlacementFocus;
  note: string;
};

export type PlacementTestResult = {
  version: string;
  capturedAt: string;
  elapsedMs: number;
  accuracy: number;
  wpm: number;
  leftAccuracy: number;
  rightAccuracy: number;
  leftSamples: number;
  rightSamples: number;
  recommendation: PlacementRecommendation;
};

const LEFT_HAND_KEYS = new Set("qwertasdfgzxcvb12345".split(""));
const RIGHT_HAND_KEYS = new Set("yuiophjklnm67890".split(""));

const TUTORIAL_PACING_MIN = 0.75;
const TUTORIAL_PACING_MAX = 1.25;

function clampRatio(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

function clampNonNegative(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, value);
}

function clampPositive(value: unknown, fallback: number): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) return fallback;
  return value;
}

function clampTutorialPacing(value: number): number {
  const clamped = Math.max(TUTORIAL_PACING_MIN, Math.min(TUTORIAL_PACING_MAX, value));
  return Math.round(clamped * 100) / 100;
}

export function classifyHand(char: string | null | undefined): PlacementHand {
  if (typeof char !== "string" || char.length === 0) return "neutral";
  const normalized = char.toLowerCase();
  if (LEFT_HAND_KEYS.has(normalized)) return "left";
  if (RIGHT_HAND_KEYS.has(normalized)) return "right";
  return "neutral";
}

export function buildPlacementRecommendation(metrics: {
  accuracy: number;
  wpm: number;
  leftAccuracy: number;
  rightAccuracy: number;
  leftSamples: number;
  rightSamples: number;
}): PlacementRecommendation {
  const accuracy = clampRatio(metrics.accuracy);
  const wpm = clampNonNegative(metrics.wpm);
  const leftAccuracy = clampRatio(metrics.leftAccuracy);
  const rightAccuracy = clampRatio(metrics.rightAccuracy);
  const leftSamples = Math.max(0, Math.floor(metrics.leftSamples ?? 0));
  const rightSamples = Math.max(0, Math.floor(metrics.rightSamples ?? 0));

  let tutorialPacing = 1;
  if (accuracy < 0.82 || wpm < 20) {
    tutorialPacing = 0.85;
  } else if (accuracy < 0.9 || wpm < 30) {
    tutorialPacing = 0.95;
  } else if (accuracy >= 0.97 && wpm >= 55) {
    tutorialPacing = 1.15;
  } else if (accuracy >= 0.95 && wpm >= 40) {
    tutorialPacing = 1.05;
  }
  tutorialPacing = clampTutorialPacing(tutorialPacing);

  let focus: PlacementFocus = "balanced";
  if (leftSamples >= 10 && rightSamples >= 10) {
    const delta = leftAccuracy - rightAccuracy;
    if (delta <= -0.08) {
      focus = "left";
    } else if (delta >= 0.08) {
      focus = "right";
    }
  }

  const paceLabel =
    tutorialPacing <= 0.9 ? "Slow" : tutorialPacing < 1 ? "Steady" : tutorialPacing >= 1.1 ? "Fast" : "Normal";
  const focusLabel = focus === "balanced" ? "Both hands" : `${focus} hand`;
  const noteParts = [
    `Suggested tutorial pace: ${paceLabel} (${Math.round(tutorialPacing * 100)}%).`,
    `${focusLabel} focus: tap the first three letters cleanly before speeding up.`
  ];

  return { tutorialPacing, focus, note: noteParts.join(" ") };
}

export function createPlacementTestResult(options: {
  capturedAt?: string;
  elapsedMs: number;
  accuracy: number;
  wpm: number;
  leftCorrect: number;
  leftTotal: number;
  rightCorrect: number;
  rightTotal: number;
}): PlacementTestResult {
  const leftSamples = Math.max(0, Math.floor(options.leftTotal ?? 0));
  const rightSamples = Math.max(0, Math.floor(options.rightTotal ?? 0));
  const leftAccuracy = leftSamples > 0 ? clampRatio((options.leftCorrect ?? 0) / leftSamples) : 1;
  const rightAccuracy = rightSamples > 0 ? clampRatio((options.rightCorrect ?? 0) / rightSamples) : 1;
  const recommendation = buildPlacementRecommendation({
    accuracy: options.accuracy,
    wpm: options.wpm,
    leftAccuracy,
    rightAccuracy,
    leftSamples,
    rightSamples
  });

  return {
    version: PLACEMENT_TEST_VERSION,
    capturedAt: options.capturedAt ?? new Date().toISOString(),
    elapsedMs: clampNonNegative(options.elapsedMs),
    accuracy: clampRatio(options.accuracy),
    wpm: clampNonNegative(options.wpm),
    leftAccuracy,
    rightAccuracy,
    leftSamples,
    rightSamples,
    recommendation
  };
}

export function readPlacementTestResult(storage: Storage | null | undefined): PlacementTestResult | null {
  if (!storage) return null;
  try {
    const raw = storage.getItem(PLACEMENT_TEST_STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return null;
    if (parsed.version !== PLACEMENT_TEST_VERSION) return null;
    const capturedAt =
      typeof parsed.capturedAt === "string" && parsed.capturedAt.length > 0
        ? parsed.capturedAt
        : new Date().toISOString();
    const recommendationRaw =
      parsed.recommendation && typeof parsed.recommendation === "object" ? parsed.recommendation : null;
    const recommendation = buildPlacementRecommendation({
      accuracy: parsed.accuracy,
      wpm: parsed.wpm,
      leftAccuracy: parsed.leftAccuracy,
      rightAccuracy: parsed.rightAccuracy,
      leftSamples: parsed.leftSamples,
      rightSamples: parsed.rightSamples
    });
    if (recommendationRaw) {
      const pacing = clampTutorialPacing(clampPositive(recommendationRaw.tutorialPacing, recommendation.tutorialPacing));
      const focus =
        recommendationRaw.focus === "left" || recommendationRaw.focus === "right" ? recommendationRaw.focus : "balanced";
      const note =
        typeof recommendationRaw.note === "string" && recommendationRaw.note.length > 0
          ? recommendationRaw.note
          : recommendation.note;
      recommendation.tutorialPacing = pacing;
      recommendation.focus = focus;
      recommendation.note = note;
    }
    return {
      version: PLACEMENT_TEST_VERSION,
      capturedAt,
      elapsedMs: clampNonNegative(parsed.elapsedMs),
      accuracy: clampRatio(parsed.accuracy),
      wpm: clampNonNegative(parsed.wpm),
      leftAccuracy: clampRatio(parsed.leftAccuracy),
      rightAccuracy: clampRatio(parsed.rightAccuracy),
      leftSamples: Math.max(0, Math.floor(parsed.leftSamples ?? 0)),
      rightSamples: Math.max(0, Math.floor(parsed.rightSamples ?? 0)),
      recommendation
    };
  } catch {
    return null;
  }
}

export function writePlacementTestResult(
  storage: Storage | null | undefined,
  result: PlacementTestResult
): void {
  if (!storage) return;
  const base = {
    version: PLACEMENT_TEST_VERSION,
    capturedAt:
      typeof result.capturedAt === "string" && result.capturedAt.length > 0
        ? result.capturedAt
        : new Date().toISOString(),
    elapsedMs: clampNonNegative(result.elapsedMs),
    accuracy: clampRatio(result.accuracy),
    wpm: clampNonNegative(result.wpm),
    leftAccuracy: clampRatio(result.leftAccuracy),
    rightAccuracy: clampRatio(result.rightAccuracy),
    leftSamples: Math.max(0, Math.floor(result.leftSamples ?? 0)),
    rightSamples: Math.max(0, Math.floor(result.rightSamples ?? 0))
  };
  const normalizedRecommendation = buildPlacementRecommendation({
    accuracy: base.accuracy,
    wpm: base.wpm,
    leftAccuracy: base.leftAccuracy,
    rightAccuracy: base.rightAccuracy,
    leftSamples: base.leftSamples,
    rightSamples: base.rightSamples
  });
  const recommendationRaw =
    result.recommendation && typeof result.recommendation === "object" ? result.recommendation : null;
  const tutorialPacing = clampTutorialPacing(
    typeof recommendationRaw?.tutorialPacing === "number"
      ? recommendationRaw.tutorialPacing
      : normalizedRecommendation.tutorialPacing
  );
  const focus =
    recommendationRaw?.focus === "left" || recommendationRaw?.focus === "right"
      ? recommendationRaw.focus
      : normalizedRecommendation.focus;
  const note =
    typeof recommendationRaw?.note === "string" && recommendationRaw.note.length > 0
      ? recommendationRaw.note
      : normalizedRecommendation.note;
  const normalized: PlacementTestResult = {
    ...base,
    recommendation: { tutorialPacing, focus, note }
  };
  try {
    storage.setItem(PLACEMENT_TEST_STORAGE_KEY, JSON.stringify(normalized));
  } catch {
    // ignore storage failures
  }
}
