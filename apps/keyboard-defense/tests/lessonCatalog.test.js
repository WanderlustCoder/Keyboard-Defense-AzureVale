import { describe, expect, it } from "vitest";
import {
  buildLessonPathViewState,
  listLessonWordlists,
  listLessonWordlistsAll,
  listTypingLessons
} from "../src/data/lessons.ts";

describe("lesson catalog", () => {
  it("keeps lessons ordered and unique", () => {
    const lessons = listTypingLessons();
    const orders = lessons.map((lesson) => lesson.order);
    const sorted = [...orders].sort((a, b) => a - b);
    expect(orders).toEqual(sorted);
    const ids = new Set();
    for (const lesson of lessons) {
      expect(ids.has(lesson.id)).toBe(false);
      ids.add(lesson.id);
    }
  });

  it("maps each lesson to populated wordlists", () => {
    const lessons = listTypingLessons();
    for (const lesson of lessons) {
      const lists = listLessonWordlists(lesson.id);
      expect(lists.length).toBe(lesson.wordlistIds.length);
      for (const list of lists) {
        expect(list.words.length).toBeGreaterThan(0);
      }
    }
  });

  it("uses all available lesson wordlists", () => {
    const lessons = listTypingLessons();
    const referenced = new Set();
    for (const lesson of lessons) {
      for (const id of lesson.wordlistIds) {
        referenced.add(id);
      }
    }
    const allLists = listLessonWordlistsAll();
    expect(allLists.length).toBeGreaterThan(0);
    for (const list of allLists) {
      expect(referenced.has(list.id)).toBe(true);
    }
  });

  it("derives the next lesson from completion data", () => {
    const lessons = listTypingLessons();
    const first = lessons[0];
    const second = lessons[1] ?? null;
    const state = buildLessonPathViewState({ [first.id]: 1 });
    expect(state.completedLessons).toBe(1);
    expect(state.totalLessons).toBe(lessons.length);
    if (second) {
      expect(state.next?.id).toBe(second.id);
    } else {
      expect(state.next).toBe(null);
    }
  });
});
