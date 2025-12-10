import { type TrainingCalendarViewState } from "./trainingCalendar.js";

const STORAGE_KEY = "keyboard-defense:streak-tokens";
export const STREAK_TOKEN_VERSION = "v1";
const AWARD_THRESHOLD_DAYS = 5;

export type StreakTokenState = {
  version: string;
  tokens: number;
  lastAwardedDate: string | null;
};

const DEFAULT_STATE: StreakTokenState = {
  version: STREAK_TOKEN_VERSION,
  tokens: 0,
  lastAwardedDate: null
};

function normalizeDate(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) return null;
  return trimmed;
}

export function readStreakTokens(storage: Storage | null | undefined): StreakTokenState {
  if (!storage) return { ...DEFAULT_STATE };
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_STATE };
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return { ...DEFAULT_STATE };
    if (parsed.version !== STREAK_TOKEN_VERSION) return { ...DEFAULT_STATE };
    const tokens = typeof parsed.tokens === "number" && Number.isFinite(parsed.tokens) ? parsed.tokens : 0;
    const lastAwardedDate = normalizeDate(parsed.lastAwardedDate) ?? null;
    return {
      version: STREAK_TOKEN_VERSION,
      tokens: Math.max(0, Math.floor(tokens)),
      lastAwardedDate
    };
  } catch {
    return { ...DEFAULT_STATE };
  }
}

export function writeStreakTokens(
  storage: Storage | null | undefined,
  state: StreakTokenState
): void {
  if (!storage) return;
  const payload: StreakTokenState = {
    version: STREAK_TOKEN_VERSION,
    tokens: Math.max(0, Math.floor(state.tokens ?? 0)),
    lastAwardedDate: normalizeDate(state.lastAwardedDate) ?? null
  };
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch {
    // ignore persistence failures
  }
}

export function computeCurrentStreak(calendar: TrainingCalendarViewState): number {
  if (!calendar?.days?.length) return 0;
  let streak = 0;
  for (let i = calendar.days.length - 1; i >= 0; i -= 1) {
    const day = calendar.days[i];
    const total = (day?.lessons ?? 0) + (day?.drills ?? 0);
    if (total > 0) {
      streak += 1;
    } else {
      break;
    }
  }
  return streak;
}

export function maybeAwardStreakToken(options: {
  calendar: TrainingCalendarViewState;
  state: StreakTokenState;
  today?: string;
}): { state: StreakTokenState; awarded: boolean } {
  const today =
    options.today && normalizeDate(options.today) ? (options.today as string) : new Date().toISOString().slice(0, 10);
  const streak = computeCurrentStreak(options.calendar);
  const alreadyAwardedToday = options.state.lastAwardedDate === today;
  if (streak >= AWARD_THRESHOLD_DAYS && !alreadyAwardedToday) {
    const next: StreakTokenState = {
      version: STREAK_TOKEN_VERSION,
      tokens: (options.state.tokens ?? 0) + 1,
      lastAwardedDate: today
    };
    return { state: next, awarded: true };
  }
  return { state: options.state, awarded: false };
}
