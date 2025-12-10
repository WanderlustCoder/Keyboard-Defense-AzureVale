import { type TypingDrillSummary } from "../core/types.js";

const STORAGE_KEY = "keyboard-defense:training-calendar";
export const TRAINING_CALENDAR_VERSION = "v1";
const MAX_DAYS = 90;

export type TrainingCalendarEntry = {
  date: string; // YYYY-MM-DD
  lessons: number;
  drills: number;
};

export type TrainingCalendarProgress = {
  version: string;
  entries: TrainingCalendarEntry[];
  updatedAt: string;
};

export type TrainingCalendarDayView = TrainingCalendarEntry & { weekIndex: number; weekday: number };

export type TrainingCalendarViewState = {
  days: TrainingCalendarDayView[];
  totalLessons: number;
  totalDrills: number;
  lastUpdated: string | null;
};

function clampCount(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.floor(value));
}

function normalizeDate(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) return null;
  return trimmed;
}

function normalizeEntry(raw: unknown): TrainingCalendarEntry | null {
  if (!raw || typeof raw !== "object") return null;
  const data = raw as Record<string, unknown>;
  const date = normalizeDate(data.date);
  if (!date) return null;
  return {
    date,
    lessons: clampCount(data.lessons),
    drills: clampCount(data.drills)
  };
}

const DEFAULT_PROGRESS: TrainingCalendarProgress = {
  version: TRAINING_CALENDAR_VERSION,
  entries: [],
  updatedAt: new Date().toISOString()
};

export function readTrainingCalendar(
  storage: Storage | null | undefined
): TrainingCalendarProgress {
  if (!storage) return { ...DEFAULT_PROGRESS };
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_PROGRESS };
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return { ...DEFAULT_PROGRESS };
    if (parsed.version !== TRAINING_CALENDAR_VERSION) return { ...DEFAULT_PROGRESS };
    const entries: TrainingCalendarEntry[] = [];
    if (Array.isArray(parsed.entries)) {
      for (const entry of parsed.entries) {
        const normalized = normalizeEntry(entry);
        if (normalized) {
          entries.push(normalized);
        }
      }
    }
    const trimmed = entries.length > MAX_DAYS ? entries.slice(entries.length - MAX_DAYS) : entries;
    const updatedAt =
      typeof parsed.updatedAt === "string" && parsed.updatedAt.length > 0
        ? parsed.updatedAt
        : new Date().toISOString();
    return {
      version: TRAINING_CALENDAR_VERSION,
      entries: trimmed,
      updatedAt
    };
  } catch {
    return { ...DEFAULT_PROGRESS };
  }
}

export function writeTrainingCalendar(
  storage: Storage | null | undefined,
  progress: TrainingCalendarProgress
): void {
  if (!storage) return;
  const normalizedEntries: TrainingCalendarEntry[] = [];
  for (const entry of progress.entries.slice(-MAX_DAYS)) {
    const normalized = normalizeEntry(entry);
    if (normalized) {
      normalizedEntries.push(normalized);
    }
  }
  const payload: TrainingCalendarProgress = {
    version: TRAINING_CALENDAR_VERSION,
    entries: normalizedEntries,
    updatedAt: progress.updatedAt ?? new Date().toISOString()
  };
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch {
    // ignore
  }
}

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

export function recordTrainingDay(
  progress: TrainingCalendarProgress,
  options: { lessonsDelta?: number; drillsDelta?: number }
): TrainingCalendarProgress {
  const date = todayIso();
  const lessonsDelta = clampCount(options.lessonsDelta);
  const drillsDelta = clampCount(options.drillsDelta);
  const entries = [...progress.entries];
  const existingIndex = entries.findIndex((entry) => entry.date === date);
  if (existingIndex >= 0) {
    const current = entries[existingIndex];
    entries[existingIndex] = {
      ...current,
      lessons: current.lessons + lessonsDelta,
      drills: current.drills + drillsDelta
    };
  } else {
    entries.push({ date, lessons: lessonsDelta, drills: drillsDelta });
  }
  if (entries.length > MAX_DAYS) {
    entries.splice(0, entries.length - MAX_DAYS);
  }
  return {
    version: TRAINING_CALENDAR_VERSION,
    entries,
    updatedAt: new Date().toISOString()
  };
}

export function buildTrainingCalendarView(
  progress: TrainingCalendarProgress,
  options: { weeks?: number } = {}
): TrainingCalendarViewState {
  const weeks = Math.max(2, Math.min(16, options.weeks ?? 8));
  const totalDays = weeks * 7;
  const days: TrainingCalendarDayView[] = [];
  const map = new Map(progress.entries.map((entry) => [entry.date, entry]));
  const today = new Date(todayIso());
  for (let i = totalDays - 1; i >= 0; i -= 1) {
    const day = new Date(today);
    day.setDate(today.getDate() - i);
    const date = day.toISOString().slice(0, 10);
    const weekIndex = Math.floor((totalDays - 1 - i) / 7);
    const weekday = day.getDay();
    const entry = map.get(date);
    days.push({
      date,
      lessons: entry?.lessons ?? 0,
      drills: entry?.drills ?? 0,
      weekIndex,
      weekday
    });
  }
  const totals = progress.entries.reduce(
    (acc, entry) => {
      acc.lessons += clampCount(entry.lessons);
      acc.drills += clampCount(entry.drills);
      return acc;
    },
    { lessons: 0, drills: 0 }
  );
  return {
    days,
    totalLessons: totals.lessons,
    totalDrills: totals.drills,
    lastUpdated: progress.updatedAt ?? null
  };
}

export function drillSummaryToCalendarDelta(summary: TypingDrillSummary): {
  lessonsDelta: number;
  drillsDelta: number;
} {
  const words = Math.max(0, summary?.words ?? 0);
  return {
    lessonsDelta: words > 0 ? 1 : 0,
    drillsDelta: 1
  };
}
