import homeRow from "../../data/wordlists/lesson_home_row.json" with { type: "json" };
import topRow from "../../data/wordlists/lesson_top_row.json" with { type: "json" };
import bottomRow from "../../data/wordlists/lesson_bottom_row.json" with { type: "json" };
import numbersBasic from "../../data/wordlists/numbers_basic.json" with { type: "json" };
import punctuationBasic from "../../data/wordlists/punctuation_basic.json" with { type: "json" };
import punctuationSentences from "../../data/wordlists/punctuation_sentences.json" with { type: "json" };
import mixedReview from "../../data/wordlists/lesson_mixed_review.json" with { type: "json" };
import castleTheme from "../../data/wordlists/castle_theme_basic.json" with { type: "json" };

export type LessonCategory = "fundamentals" | "numbers" | "punctuation" | "review";

export type LessonWordlist = {
  id: string;
  lesson: number;
  words: string[];
  weights?: number[];
  allowProper: boolean;
  introducedLetters?: string;
  allowedCharacters?: string;
};

export type TypingLesson = {
  id: string;
  order: number;
  label: string;
  description: string;
  category: LessonCategory;
  wordlistIds: string[];
};

export type LessonPathViewState = {
  totalLessons: number;
  completedLessons: number;
  next: TypingLesson | null;
};

type LessonWordlistSource = {
  id?: unknown;
  lesson?: unknown;
  words?: unknown;
  weights?: unknown;
  allowProper?: unknown;
  introducedLetters?: unknown;
  allowedCharacters?: unknown;
};

function clampLesson(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.floor(value));
}

function normalizeWordArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((entry) => typeof entry === "string" && entry.trim().length > 0);
}

function normalizeWordlist(source: LessonWordlistSource | null | undefined): LessonWordlist | null {
  if (!source || typeof source !== "object") return null;
  const id = typeof source.id === "string" ? source.id.trim() : "";
  if (!id) return null;
  const words = normalizeWordArray(source.words);
  if (words.length === 0) return null;
  let weights: number[] | undefined;
  if (Array.isArray(source.weights) && source.weights.length === words.length) {
    const normalized = source.weights.filter(
      (entry) => typeof entry === "number" && Number.isFinite(entry)
    );
    if (normalized.length === words.length) {
      weights = normalized;
    }
  }
  return {
    id,
    lesson: clampLesson(source.lesson),
    words,
    weights,
    allowProper: Boolean(source.allowProper),
    introducedLetters: typeof source.introducedLetters === "string" ? source.introducedLetters : undefined,
    allowedCharacters: typeof source.allowedCharacters === "string" ? source.allowedCharacters : undefined
  };
}

const WORDLIST_SOURCES: LessonWordlistSource[] = [
  homeRow as LessonWordlistSource,
  topRow as LessonWordlistSource,
  bottomRow as LessonWordlistSource,
  numbersBasic as LessonWordlistSource,
  punctuationBasic as LessonWordlistSource,
  punctuationSentences as LessonWordlistSource,
  mixedReview as LessonWordlistSource,
  castleTheme as LessonWordlistSource
];

const WORDLISTS: LessonWordlist[] = WORDLIST_SOURCES.map((entry) => normalizeWordlist(entry)).filter(
  (entry): entry is LessonWordlist => Boolean(entry)
);

const WORDLISTS_BY_ID = new Map(WORDLISTS.map((entry) => [entry.id, entry]));

const LESSONS: TypingLesson[] = [
  {
    id: "home-row",
    order: 1,
    label: "Home Row Foundations",
    description: "Build comfort on ASDF JKL; before moving outward.",
    category: "fundamentals",
    wordlistIds: ["lesson-home-row"]
  },
  {
    id: "top-row",
    order: 2,
    label: "Top Row Reach",
    description: "Add QWERTYUIOP while keeping accuracy steady.",
    category: "fundamentals",
    wordlistIds: ["lesson-top-row"]
  },
  {
    id: "bottom-row",
    order: 3,
    label: "Bottom Row Control",
    description: "Introduce ZXCVBNM and stabilize full-alpha flow.",
    category: "fundamentals",
    wordlistIds: ["lesson-bottom-row"]
  },
  {
    id: "numbers",
    order: 4,
    label: "Numbers",
    description: "Practice digits with short, repeatable strings.",
    category: "numbers",
    wordlistIds: ["numbers-basic"]
  },
  {
    id: "punctuation",
    order: 5,
    label: "Punctuation",
    description: "Add common marks and simple sentence rhythm.",
    category: "punctuation",
    wordlistIds: ["punctuation-basic", "punctuation-sentences"]
  },
  {
    id: "mixed-review",
    order: 6,
    label: "Mixed Review",
    description: "Blend letters, numbers, and themed words for fluency.",
    category: "review",
    wordlistIds: ["lesson-mixed-review", "castle-theme-basic"]
  }
];

const LESSON_CATALOG = [...LESSONS].sort((a, b) => a.order - b.order);
const LESSONS_BY_ID = new Map(LESSON_CATALOG.map((lesson) => [lesson.id, lesson]));

export const TYPING_LESSON_CATALOG: TypingLesson[] = LESSON_CATALOG;
export const TYPING_LESSON_WORDLISTS: LessonWordlist[] = WORDLISTS;

export function listTypingLessons(): TypingLesson[] {
  return LESSON_CATALOG;
}

export function getTypingLesson(id: string): TypingLesson | undefined {
  return LESSONS_BY_ID.get(id);
}

export function listLessonWordlists(lessonId: string): LessonWordlist[] {
  const lesson = LESSONS_BY_ID.get(lessonId);
  if (!lesson) return [];
  return lesson.wordlistIds
    .map((id) => WORDLISTS_BY_ID.get(id))
    .filter((entry): entry is LessonWordlist => Boolean(entry));
}

export function listLessonWordlistsById(ids: string[]): LessonWordlist[] {
  return (ids ?? [])
    .map((id) => WORDLISTS_BY_ID.get(id))
    .filter((entry): entry is LessonWordlist => Boolean(entry));
}

export function getLessonWordlist(id: string): LessonWordlist | undefined {
  return WORDLISTS_BY_ID.get(id);
}

export function listLessonWordlistsAll(): LessonWordlist[] {
  return WORDLISTS;
}

export function buildLessonPathViewState(
  lessonCompletions: Record<string, number> | null | undefined
): LessonPathViewState {
  const completions = lessonCompletions ?? {};
  const totalLessons = LESSON_CATALOG.length;
  let completedLessons = 0;
  let nextLesson: TypingLesson | null = null;
  for (const lesson of LESSON_CATALOG) {
    const count = completions[lesson.id] ?? 0;
    if (count > 0) {
      completedLessons += 1;
      continue;
    }
    if (!nextLesson) {
      nextLesson = lesson;
    }
  }
  return {
    totalLessons,
    completedLessons,
    next: nextLesson
  };
}
