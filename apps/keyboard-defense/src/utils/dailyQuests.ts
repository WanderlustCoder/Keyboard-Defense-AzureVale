const STORAGE_KEY = "keyboard-defense:daily-quests";
export const DAILY_QUESTS_VERSION = "v1";

export type DailyQuestId = "drills" | "gold-medal" | "campaign-waves" | "campaign-accuracy";

export type DailyQuestEntry = {
  id: DailyQuestId;
  progress: number;
  target: number;
  completedAt: string | null;
};

export type DailyQuestState = {
  version: string;
  day: string;
  entries: DailyQuestEntry[];
  updatedAt: string;
};

export type DailyQuestEntryView = DailyQuestEntry & {
  title: string;
  description: string;
  status: "active" | "completed";
  meta: string;
};

export type DailyQuestBoardViewState = {
  day: string;
  completed: number;
  total: number;
  summary: string;
  entries: DailyQuestEntryView[];
  updatedAt: string | null;
};

function clampNumber(value: unknown, min: number, max: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return min;
  return Math.max(min, Math.min(max, value));
}

function clampInteger(value: unknown, min: number, max: number): number {
  const parsed = typeof value === "number" ? value : Number.parseInt(String(value ?? ""), 10);
  if (!Number.isFinite(parsed)) return min;
  const rounded = Math.floor(parsed);
  return Math.max(min, Math.min(max, rounded));
}

function getUtcDayKey(now: number = Date.now()): string {
  return new Date(now).toISOString().slice(0, 10);
}

function hashSeed(value: string): number {
  let seed = 2166136261;
  for (let i = 0; i < value.length; i += 1) {
    seed ^= value.charCodeAt(i);
    seed = Math.imul(seed, 16777619);
  }
  return Math.abs(seed);
}

function createDailyQuestBoard(day: string): DailyQuestState {
  const seed = hashSeed(day);
  const drillTargets = [1, 2, 3];
  const waveTargets = [3, 4, 5];
  const accuracyTargets = [88, 90, 92];
  const drillTarget = drillTargets[seed % drillTargets.length] ?? 2;
  const campaignChoice = (seed >> 3) % 2;
  const campaignQuest: DailyQuestEntry =
    campaignChoice === 0
      ? {
          id: "campaign-waves",
          progress: 0,
          target: waveTargets[(seed >> 5) % waveTargets.length] ?? 3,
          completedAt: null
        }
      : {
          id: "campaign-accuracy",
          progress: 0,
          target: accuracyTargets[(seed >> 7) % accuracyTargets.length] ?? 90,
          completedAt: null
        };
  return {
    version: DAILY_QUESTS_VERSION,
    day,
    entries: [
      { id: "drills", progress: 0, target: drillTarget, completedAt: null },
      { id: "gold-medal", progress: 0, target: 1, completedAt: null },
      campaignQuest
    ],
    updatedAt: new Date().toISOString()
  };
}

function normalizeId(value: unknown): DailyQuestId | null {
  if (value === "drills" || value === "gold-medal" || value === "campaign-waves" || value === "campaign-accuracy") {
    return value;
  }
  return null;
}

function normalizeEntry(raw: unknown): DailyQuestEntry | null {
  if (!raw || typeof raw !== "object") return null;
  const data = raw as Record<string, unknown>;
  const id = normalizeId(data.id);
  if (!id) return null;
  const target =
    id === "drills"
      ? clampInteger(data.target, 1, 3)
      : id === "gold-medal"
        ? 1
        : id === "campaign-waves"
          ? clampInteger(data.target, 2, 12)
          : clampInteger(data.target, 75, 100);
  const progressRaw = clampNumber(data.progress, 0, 1000);
  const progress =
    id === "campaign-accuracy"
      ? clampInteger(progressRaw, 0, 100)
      : id === "campaign-waves"
        ? clampInteger(progressRaw, 0, 99)
        : clampInteger(progressRaw, 0, target);
  const completedAt =
    typeof data.completedAt === "string" && data.completedAt.length > 0 ? data.completedAt : null;
  return { id, progress, target, completedAt };
}

function normalizeBoard(raw: unknown, day: string): DailyQuestState {
  if (!raw || typeof raw !== "object") return createDailyQuestBoard(day);
  const data = raw as Record<string, unknown>;
  if (data.version !== DAILY_QUESTS_VERSION) return createDailyQuestBoard(day);
  const storedDay = typeof data.day === "string" ? data.day.trim() : "";
  if (!storedDay || storedDay !== day) {
    return createDailyQuestBoard(day);
  }
  const entries: DailyQuestEntry[] = [];
  if (Array.isArray(data.entries)) {
    for (const entry of data.entries) {
      const normalized = normalizeEntry(entry);
      if (normalized) {
        entries.push(normalized);
      }
    }
  }
  const required = new Set<DailyQuestId>(["drills", "gold-medal", "campaign-waves", "campaign-accuracy"]);
  const unique = new Set(entries.map((entry) => entry.id));
  for (const id of unique) {
    required.delete(id);
  }
  const hasCampaignQuest =
    entries.some((entry) => entry.id === "campaign-waves") ||
    entries.some((entry) => entry.id === "campaign-accuracy");
  const hasDrills = entries.some((entry) => entry.id === "drills");
  const hasMedal = entries.some((entry) => entry.id === "gold-medal");
  if (!hasCampaignQuest || !hasDrills || !hasMedal || entries.length !== 3) {
    return createDailyQuestBoard(day);
  }
  const updatedAt =
    typeof data.updatedAt === "string" && data.updatedAt.length > 0 ? data.updatedAt : new Date().toISOString();
  return {
    version: DAILY_QUESTS_VERSION,
    day,
    entries,
    updatedAt
  };
}

export function readDailyQuestBoard(storage: Storage | null | undefined, nowMs: number = Date.now()): DailyQuestState {
  const day = getUtcDayKey(nowMs);
  if (!storage) return createDailyQuestBoard(day);
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return createDailyQuestBoard(day);
    return normalizeBoard(JSON.parse(raw), day);
  } catch {
    return createDailyQuestBoard(day);
  }
}

export function writeDailyQuestBoard(storage: Storage | null | undefined, state: DailyQuestState): DailyQuestState {
  if (!storage) return state;
  const day = typeof state.day === "string" && state.day.length > 0 ? state.day : getUtcDayKey();
  const normalized = normalizeBoard(state, day);
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(normalized));
  } catch {
    // ignore persistence failures
  }
  return normalized;
}

export function recordDailyQuestDrill(
  state: DailyQuestState,
  options: { medalTier?: "bronze" | "silver" | "gold" | "platinum" } = {}
): DailyQuestState {
  const now = Date.now();
  const day = getUtcDayKey(now);
  const current = state.day === day ? state : createDailyQuestBoard(day);
  const nextEntries = current.entries.map((entry) => {
    if (entry.id === "drills") {
      const nextProgress = Math.min(entry.target, entry.progress + 1);
      const completedAt =
        nextProgress >= entry.target ? entry.completedAt ?? new Date(now).toISOString() : entry.completedAt;
      return { ...entry, progress: nextProgress, completedAt };
    }
    if (entry.id === "gold-medal") {
      const earned =
        options.medalTier === "gold" || options.medalTier === "platinum";
      if (!earned) return entry;
      const nextProgress = 1;
      const completedAt = entry.completedAt ?? new Date(now).toISOString();
      return { ...entry, progress: nextProgress, completedAt };
    }
    return entry;
  });
  return { ...current, entries: nextEntries, updatedAt: new Date(now).toISOString() };
}

export function recordDailyQuestCampaignRun(
  state: DailyQuestState,
  options: { wavesCompleted?: number; accuracyPct?: number } = {}
): DailyQuestState {
  const now = Date.now();
  const day = getUtcDayKey(now);
  const current = state.day === day ? state : createDailyQuestBoard(day);
  const wavesCompleted = clampInteger(options.wavesCompleted, 0, 99);
  const accuracyPct = clampInteger(options.accuracyPct, 0, 100);
  const nextEntries = current.entries.map((entry) => {
    if (entry.id === "campaign-waves") {
      const nextProgress = Math.max(entry.progress, Math.min(entry.target, wavesCompleted));
      const completedAt =
        nextProgress >= entry.target ? entry.completedAt ?? new Date(now).toISOString() : entry.completedAt;
      return { ...entry, progress: nextProgress, completedAt };
    }
    if (entry.id === "campaign-accuracy") {
      const nextProgress = Math.max(entry.progress, Math.min(entry.target, accuracyPct));
      const completedAt =
        nextProgress >= entry.target ? entry.completedAt ?? new Date(now).toISOString() : entry.completedAt;
      return { ...entry, progress: nextProgress, completedAt };
    }
    return entry;
  });
  return { ...current, entries: nextEntries, updatedAt: new Date(now).toISOString() };
}

function describeEntry(entry: DailyQuestEntry): { title: string; description: string; meta: string } {
  if (entry.id === "drills") {
    const noun = entry.target === 1 ? "drill" : "drills";
    return {
      title: `Complete ${entry.target} ${noun}`,
      description: "Finish typing drills to keep your streak alive.",
      meta: entry.progress >= entry.target ? "Complete" : `${entry.progress}/${entry.target}`
    };
  }
  if (entry.id === "gold-medal") {
    return {
      title: "Earn a Gold medal",
      description: "Hit Gold or Platinum in any lesson drill.",
      meta: entry.progress >= 1 ? "Complete" : "0/1"
    };
  }
  if (entry.id === "campaign-waves") {
    const progress = Math.min(entry.target, entry.progress);
    return {
      title: `Reach wave ${entry.target}`,
      description: "Finish a campaign run with defenses holding steady.",
      meta: progress >= entry.target ? "Complete" : `${progress}/${entry.target}`
    };
  }
  const progress = Math.min(entry.target, entry.progress);
  return {
    title: `Hit ${entry.target}% accuracy`,
    description: "Finish a campaign run with clean typing.",
    meta: progress >= entry.target ? "Complete" : `${progress}/${entry.target}%`
  };
}

export function buildDailyQuestBoardView(state: DailyQuestState): DailyQuestBoardViewState {
  const day = typeof state?.day === "string" ? state.day : getUtcDayKey();
  const entries = Array.isArray(state?.entries) ? state.entries : [];
  const viewEntries: DailyQuestEntryView[] = entries.map((entry) => {
    const info = describeEntry(entry);
    const completed = entry.progress >= entry.target;
    return {
      ...entry,
      title: info.title,
      description: info.description,
      meta: info.meta,
      status: completed ? "completed" : "active"
    };
  });
  const completedCount = viewEntries.filter((entry) => entry.status === "completed").length;
  const total = viewEntries.length;
  const summary =
    total > 0
      ? `${completedCount} of ${total} daily quests completed. New quests arrive every day.`
      : "Daily quests refresh each day.";
  return {
    day,
    completed: completedCount,
    total,
    summary,
    entries: viewEntries,
    updatedAt: state?.updatedAt ?? null
  };
}

