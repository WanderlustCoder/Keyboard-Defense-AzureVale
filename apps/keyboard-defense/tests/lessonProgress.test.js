import { expect, test } from "vitest";
import {
  LESSON_PROGRESS_VERSION,
  incrementLessonCompletions,
  readLessonProgress,
  writeLessonProgress
} from "../src/utils/lessonProgress.ts";
import {
  buildLoreScrollProgress,
  listNewLoreScrollsForLessons
} from "../src/data/loreScrolls.ts";

const createMemoryStorage = () => {
  const store = new Map();
  return {
    getItem: (key) => (store.has(key) ? store.get(key) : null),
    setItem: (key, value) => {
      store.set(key, String(value));
    },
    removeItem: (key) => {
      store.delete(key);
    },
    clear: () => store.clear()
  };
};

test("readLessonProgress returns defaults for missing or invalid payloads", () => {
  const storage = createMemoryStorage();
  const progress = readLessonProgress(storage);
  expect(progress.lessonsCompleted).toBe(0);
  expect(progress.unlockedScrolls).toEqual([]);
  expect(progress.version).toBe(LESSON_PROGRESS_VERSION);
});

test("writeLessonProgress persists normalized values", () => {
  const storage = createMemoryStorage();
  writeLessonProgress(storage, {
    version: LESSON_PROGRESS_VERSION,
    lessonsCompleted: 3.8,
    unlockedScrolls: ["scroll_home_row_oath", "scroll_home_row_oath", "scroll_courier_notes"],
    updatedAt: "today"
  });
  const raw = storage.getItem("keyboard-defense:lesson-progress");
  expect(raw).toBeTruthy();
  const parsed = JSON.parse(raw);
  expect(parsed.lessonsCompleted).toBe(3);
  expect(parsed.unlockedScrolls.sort()).toEqual([
    "scroll_courier_notes",
    "scroll_home_row_oath"
  ]);
  const readBack = readLessonProgress(storage);
  expect(readBack.lessonsCompleted).toBe(3);
  expect(readBack.unlockedScrolls.sort()).toEqual(parsed.unlockedScrolls.sort());
});

test("incrementLessonCompletions increases the lesson count safely", () => {
  const current = readLessonProgress(createMemoryStorage());
  const next = incrementLessonCompletions(current, 2);
  expect(next.lessonsCompleted).toBe(2);
  const clamped = incrementLessonCompletions({ ...current, lessonsCompleted: 1 }, -5);
  expect(clamped.lessonsCompleted).toBe(1);
});

test("lore scroll progress summarizes unlocks and next target", () => {
  const summary = buildLoreScrollProgress(4, []);
  expect(summary.total).toBeGreaterThan(0);
  expect(summary.unlocked).toBe(2); // lessons 1 and 3 unlock first two scrolls
  expect(summary.next?.requiredLessons).toBeGreaterThan(4);
  expect(summary.entries[0].unlocked).toBe(true);
});

test("listNewLoreScrollsForLessons only returns freshly reachable scrolls", () => {
  const firstUnlock = listNewLoreScrollsForLessons(1, []);
  expect(firstUnlock.length).toBe(1);
  const noneNew = listNewLoreScrollsForLessons(1, new Set(firstUnlock.map((s) => s.id)));
  expect(noneNew).toHaveLength(0);
  const nextUnlock = listNewLoreScrollsForLessons(5, new Set(firstUnlock.map((s) => s.id)));
  expect(nextUnlock.some((s) => s.requiredLessons === 3 || s.requiredLessons === 5)).toBe(true);
});
