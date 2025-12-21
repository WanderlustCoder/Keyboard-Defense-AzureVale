const STORAGE_KEY = "keyboard-defense:lesson-progress";
export const LESSON_PROGRESS_VERSION = "v1";

export interface LessonProgress {
  version: string;
  lessonsCompleted: number;
  unlockedScrolls: string[];
  lessonCompletions: Record<string, number>;
  updatedAt: string;
}

const EPOCH = "1970-01-01T00:00:00.000Z";

const DEFAULT_PROGRESS: LessonProgress = {
  version: LESSON_PROGRESS_VERSION,
  lessonsCompleted: 0,
  unlockedScrolls: [],
  lessonCompletions: {},
  updatedAt: EPOCH
};

function clampLessons(value: number | null | undefined): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.floor(value));
}

function normalizeScrollIds(ids: unknown): string[] {
  if (!Array.isArray(ids)) return [];
  const set = new Set<string>();
  for (const value of ids) {
    if (typeof value === "string" && value.trim().length > 0) {
      set.add(value);
    }
  }
  return Array.from(set);
}

function normalizeLessonCompletions(value: unknown): Record<string, number> {
  if (!value || typeof value !== "object") return {};
  const normalized: Record<string, number> = {};
  for (const [key, raw] of Object.entries(value)) {
    if (typeof key !== "string" || key.trim().length === 0) continue;
    if (typeof raw !== "number" || !Number.isFinite(raw)) continue;
    const count = Math.max(0, Math.floor(raw));
    if (count > 0) {
      normalized[key] = count;
    }
  }
  return normalized;
}

export function readLessonProgress(storage: Storage | null | undefined): LessonProgress {
  const fallback: LessonProgress = { ...DEFAULT_PROGRESS, updatedAt: new Date().toISOString() };
  if (!storage) return fallback;
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return fallback;
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") {
      return fallback;
    }
    if (parsed.version !== LESSON_PROGRESS_VERSION) {
      return fallback;
    }
    const lessonsCompleted = clampLessons(parsed.lessonsCompleted);
    const unlockedScrolls = normalizeScrollIds(parsed.unlockedScrolls ?? parsed.unlocked ?? []);
    const lessonCompletions = normalizeLessonCompletions(parsed.lessonCompletions ?? {});
    const updatedAt =
      typeof parsed.updatedAt === "string" && parsed.updatedAt.length > 0
        ? parsed.updatedAt
        : fallback.updatedAt;
    return {
      version: LESSON_PROGRESS_VERSION,
      lessonsCompleted,
      unlockedScrolls,
      lessonCompletions,
      updatedAt
    };
  } catch {
    return fallback;
  }
}

export function writeLessonProgress(storage: Storage | null | undefined, progress: LessonProgress): void {
  if (!storage) return;
  const payload: LessonProgress = {
    version: LESSON_PROGRESS_VERSION,
    lessonsCompleted: clampLessons(progress.lessonsCompleted),
    unlockedScrolls: normalizeScrollIds(progress.unlockedScrolls),
    lessonCompletions: normalizeLessonCompletions(progress.lessonCompletions),
    updatedAt: progress.updatedAt ?? new Date().toISOString()
  };
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch {
    // ignore storage failures
  }
}

export function incrementLessonCompletions(
  progress: LessonProgress,
  delta = 1
): LessonProgress {
  const increment = Math.max(0, Math.floor(delta));
  const nextLessons = clampLessons(progress.lessonsCompleted + increment);
  return {
    version: LESSON_PROGRESS_VERSION,
    lessonsCompleted: nextLessons,
    unlockedScrolls: normalizeScrollIds(progress.unlockedScrolls),
    lessonCompletions: normalizeLessonCompletions(progress.lessonCompletions),
    updatedAt: new Date().toISOString()
  };
}
