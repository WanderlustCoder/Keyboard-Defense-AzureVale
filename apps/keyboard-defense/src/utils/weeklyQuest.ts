const STORAGE_KEY = "keyboard-defense:weekly-quest";
export const WEEKLY_QUEST_VERSION = "v1";

export type WeeklyQuestId = "drills" | "gold-medal" | "campaign-waves" | "campaign-accuracy";

export type WeeklyQuestEntry = {
  id: WeeklyQuestId;
  progress: number;
  target: number;
  completedAt: string | null;
};

export type WeeklyQuestTrialState = {
  unlockedAt: string | null;
  completedAt: string | null;
  attempts: number;
  lastOutcome: "victory" | "defeat" | null;
};

export type WeeklyQuestState = {
  version: string;
  week: string;
  entries: WeeklyQuestEntry[];
  trial: WeeklyQuestTrialState;
  updatedAt: string;
};

export type WeeklyQuestEntryView = WeeklyQuestEntry & {
  title: string;
  description: string;
  status: "active" | "completed";
  meta: string;
};

export type WeeklyQuestBoardViewState = {
  week: string;
  completed: number;
  total: number;
  summary: string;
  entries: WeeklyQuestEntryView[];
  trial: {
    status: "locked" | "ready" | "completed";
    attempts: number;
    lastOutcome: "victory" | "defeat" | null;
    unlockedAt: string | null;
    completedAt: string | null;
  };
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

function getUtcWeekKey(now: number = Date.now()): string {
  const date = new Date(now);
  const day = date.getUTCDay();
  const daysSinceMonday = (day + 6) % 7;
  date.setUTCDate(date.getUTCDate() - daysSinceMonday);
  date.setUTCHours(0, 0, 0, 0);
  return date.toISOString().slice(0, 10);
}

function hashSeed(value: string): number {
  let seed = 2166136261;
  for (let i = 0; i < value.length; i += 1) {
    seed ^= value.charCodeAt(i);
    seed = Math.imul(seed, 16777619);
  }
  return Math.abs(seed);
}

function createWeeklyQuestBoard(week: string): WeeklyQuestState {
  const seed = hashSeed(week);
  const drillTargets = [5, 6, 7, 8];
  const medalTargets = [2, 3];
  const waveTargets = [8, 10, 12];
  const accuracyTargets = [88, 90, 92];
  const drillTarget = drillTargets[seed % drillTargets.length] ?? 6;
  const medalTarget = medalTargets[(seed >> 3) % medalTargets.length] ?? 2;
  const campaignChoice = (seed >> 5) % 2;
  const campaignQuest: WeeklyQuestEntry =
    campaignChoice === 0
      ? {
          id: "campaign-waves",
          progress: 0,
          target: waveTargets[(seed >> 7) % waveTargets.length] ?? 10,
          completedAt: null
        }
      : {
          id: "campaign-accuracy",
          progress: 0,
          target: accuracyTargets[(seed >> 9) % accuracyTargets.length] ?? 90,
          completedAt: null
        };
  return {
    version: WEEKLY_QUEST_VERSION,
    week,
    entries: [
      { id: "drills", progress: 0, target: drillTarget, completedAt: null },
      { id: "gold-medal", progress: 0, target: medalTarget, completedAt: null },
      campaignQuest
    ],
    trial: { unlockedAt: null, completedAt: null, attempts: 0, lastOutcome: null },
    updatedAt: new Date().toISOString()
  };
}

function normalizeId(value: unknown): WeeklyQuestId | null {
  if (value === "drills" || value === "gold-medal" || value === "campaign-waves" || value === "campaign-accuracy") {
    return value;
  }
  return null;
}

function normalizeEntry(raw: unknown): WeeklyQuestEntry | null {
  if (!raw || typeof raw !== "object") return null;
  const data = raw as Record<string, unknown>;
  const id = normalizeId(data.id);
  if (!id) return null;
  const target =
    id === "drills"
      ? clampInteger(data.target, 3, 20)
      : id === "gold-medal"
        ? clampInteger(data.target, 1, 10)
        : id === "campaign-waves"
          ? clampInteger(data.target, 4, 30)
          : clampInteger(data.target, 75, 100);
  const progressRaw = clampNumber(data.progress, 0, 10_000);
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

function normalizeTrial(raw: unknown): WeeklyQuestTrialState {
  if (!raw || typeof raw !== "object") {
    return { unlockedAt: null, completedAt: null, attempts: 0, lastOutcome: null };
  }
  const data = raw as Record<string, unknown>;
  const unlockedAt =
    typeof data.unlockedAt === "string" && data.unlockedAt.length > 0 ? data.unlockedAt : null;
  const completedAt =
    typeof data.completedAt === "string" && data.completedAt.length > 0 ? data.completedAt : null;
  const attempts = clampInteger(data.attempts, 0, 99);
  const lastOutcomeRaw = typeof data.lastOutcome === "string" ? data.lastOutcome : null;
  const lastOutcome =
    lastOutcomeRaw === "victory" || lastOutcomeRaw === "defeat" ? lastOutcomeRaw : null;
  return { unlockedAt, completedAt, attempts, lastOutcome };
}

function normalizeBoard(raw: unknown, week: string): WeeklyQuestState {
  if (!raw || typeof raw !== "object") return createWeeklyQuestBoard(week);
  const data = raw as Record<string, unknown>;
  if (data.version !== WEEKLY_QUEST_VERSION) return createWeeklyQuestBoard(week);
  const storedWeek = typeof data.week === "string" ? data.week.trim() : "";
  if (!storedWeek || storedWeek !== week) {
    return createWeeklyQuestBoard(week);
  }
  const entries: WeeklyQuestEntry[] = [];
  if (Array.isArray(data.entries)) {
    for (const entry of data.entries) {
      const normalized = normalizeEntry(entry);
      if (normalized) {
        entries.push(normalized);
      }
    }
  }
  const hasCampaignQuest =
    entries.some((entry) => entry.id === "campaign-waves") ||
    entries.some((entry) => entry.id === "campaign-accuracy");
  const hasDrills = entries.some((entry) => entry.id === "drills");
  const hasMedal = entries.some((entry) => entry.id === "gold-medal");
  if (!hasCampaignQuest || !hasDrills || !hasMedal || entries.length !== 3) {
    return createWeeklyQuestBoard(week);
  }
  const updatedAt =
    typeof data.updatedAt === "string" && data.updatedAt.length > 0 ? data.updatedAt : new Date().toISOString();
  const trial = normalizeTrial(data.trial);
  return {
    version: WEEKLY_QUEST_VERSION,
    week,
    entries,
    trial,
    updatedAt
  };
}

export function readWeeklyQuestBoard(
  storage: Storage | null | undefined,
  nowMs: number = Date.now()
): WeeklyQuestState {
  const week = getUtcWeekKey(nowMs);
  if (!storage) return createWeeklyQuestBoard(week);
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return createWeeklyQuestBoard(week);
    return normalizeBoard(JSON.parse(raw), week);
  } catch {
    return createWeeklyQuestBoard(week);
  }
}

export function writeWeeklyQuestBoard(
  storage: Storage | null | undefined,
  state: WeeklyQuestState
): WeeklyQuestState {
  const week = typeof state.week === "string" && state.week.length > 0 ? state.week : getUtcWeekKey();
  const normalized = normalizeBoard(state, week);
  if (!storage) return normalized;
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(normalized));
  } catch {
    // ignore persistence failures
  }
  return normalized;
}

function unlockTrialIfReady(state: WeeklyQuestState, now: number): WeeklyQuestState {
  const allComplete = state.entries.every((entry) => entry.progress >= entry.target);
  if (!allComplete) return state;
  if (state.trial.unlockedAt) return state;
  return {
    ...state,
    trial: { ...state.trial, unlockedAt: new Date(now).toISOString() },
    updatedAt: new Date(now).toISOString()
  };
}

export function recordWeeklyQuestDrill(
  state: WeeklyQuestState,
  options: { medalTier?: "bronze" | "silver" | "gold" | "platinum" } = {}
): WeeklyQuestState {
  const now = Date.now();
  const week = getUtcWeekKey(now);
  const current = state.week === week ? state : createWeeklyQuestBoard(week);
  const nextEntries = current.entries.map((entry) => {
    if (entry.id === "drills") {
      const nextProgress = Math.min(entry.target, entry.progress + 1);
      const completedAt =
        nextProgress >= entry.target ? entry.completedAt ?? new Date(now).toISOString() : entry.completedAt;
      return { ...entry, progress: nextProgress, completedAt };
    }
    if (entry.id === "gold-medal") {
      const earned = options.medalTier === "gold" || options.medalTier === "platinum";
      if (!earned) return entry;
      const nextProgress = Math.min(entry.target, entry.progress + 1);
      const completedAt =
        nextProgress >= entry.target ? entry.completedAt ?? new Date(now).toISOString() : entry.completedAt;
      return { ...entry, progress: nextProgress, completedAt };
    }
    return entry;
  });
  const next = { ...current, entries: nextEntries, updatedAt: new Date(now).toISOString() };
  return unlockTrialIfReady(next, now);
}

export function recordWeeklyQuestCampaignRun(
  state: WeeklyQuestState,
  options: { wavesCompleted?: number; accuracyPct?: number } = {}
): WeeklyQuestState {
  const now = Date.now();
  const week = getUtcWeekKey(now);
  const current = state.week === week ? state : createWeeklyQuestBoard(week);
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
  const next = { ...current, entries: nextEntries, updatedAt: new Date(now).toISOString() };
  return unlockTrialIfReady(next, now);
}

export function recordWeeklyQuestTrialAttempt(
  state: WeeklyQuestState,
  outcome: "victory" | "defeat"
): WeeklyQuestState {
  const now = Date.now();
  const week = getUtcWeekKey(now);
  const current = state.week === week ? state : createWeeklyQuestBoard(week);
  const trial = current.trial;
  const unlockedAt = trial.unlockedAt ?? (current.entries.every((e) => e.progress >= e.target) ? new Date(now).toISOString() : null);
  const attempts = clampInteger(trial.attempts + 1, 0, 99);
  const completedAt =
    outcome === "victory" ? trial.completedAt ?? new Date(now).toISOString() : trial.completedAt;
  return {
    ...current,
    trial: { unlockedAt, completedAt, attempts, lastOutcome: outcome },
    updatedAt: new Date(now).toISOString()
  };
}

function describeEntry(entry: WeeklyQuestEntry): { title: string; description: string; meta: string } {
  if (entry.id === "drills") {
    const noun = entry.target === 1 ? "drill" : "drills";
    return {
      title: `Complete ${entry.target} ${noun}`,
      description: "Finish typing drills to keep your skills sharp.",
      meta: entry.progress >= entry.target ? "Complete" : `${entry.progress}/${entry.target}`
    };
  }
  if (entry.id === "gold-medal") {
    const noun = entry.target === 1 ? "medal" : "medals";
    return {
      title: `Earn ${entry.target} Gold ${noun}`,
      description: "Hit Gold or Platinum in lesson drills.",
      meta: entry.progress >= entry.target ? "Complete" : `${entry.progress}/${entry.target}`
    };
  }
  if (entry.id === "campaign-waves") {
    const noun = entry.target === 1 ? "wave" : "waves";
    return {
      title: `Hold for ${entry.target} ${noun}`,
      description: "Complete waves in Campaign mode.",
      meta: entry.progress >= entry.target ? "Complete" : `${entry.progress}/${entry.target}`
    };
  }
  const noun = entry.target === 100 ? "perfect" : "accuracy";
  return {
    title: `Reach ${entry.target}% ${noun}`,
    description: "Finish a Campaign run with steady accuracy.",
    meta: entry.progress >= entry.target ? "Complete" : `Best ${entry.progress}%`
  };
}

export function buildWeeklyQuestBoardView(
  state: WeeklyQuestState
): WeeklyQuestBoardViewState {
  const safe = state ?? createWeeklyQuestBoard(getUtcWeekKey());
  const entries = safe.entries.map((entry) => {
    const described = describeEntry(entry);
    const status: WeeklyQuestEntryView["status"] =
      entry.progress >= entry.target ? "completed" : "active";
    return {
      ...entry,
      ...described,
      status
    };
  });
  const completed = entries.filter((entry) => entry.status === "completed").length;
  const total = entries.length;
  const trialStatus: WeeklyQuestBoardViewState["trial"]["status"] = safe.trial.completedAt
    ? "completed"
    : safe.trial.unlockedAt
      ? "ready"
      : "locked";
  const summaryParts = [`${completed}/${total} quests complete`];
  if (trialStatus === "completed") {
    summaryParts.push("Weekly Trial complete");
  } else if (trialStatus === "ready") {
    summaryParts.push("Weekly Trial ready");
  } else {
    summaryParts.push("Weekly Trial locked");
  }
  return {
    week: safe.week,
    completed,
    total,
    summary: summaryParts.join(" • "),
    entries,
    trial: {
      status: trialStatus,
      attempts: safe.trial.attempts ?? 0,
      lastOutcome: safe.trial.lastOutcome ?? null,
      unlockedAt: safe.trial.unlockedAt ?? null,
      completedAt: safe.trial.completedAt ?? null
    },
    updatedAt: safe.updatedAt ?? null
  };
}

export function buildWeeklyTrialWaveConfig(week: string): {
  id: string;
  duration: number;
  rewardBonus: number;
  spawns: Array<{
    at: number;
    lane: number;
    tierId: string;
    count: number;
    cadence: number;
    shield?: number;
    taunt?: string;
  }>;
} {
  const safeWeek = typeof week === "string" && week.trim().length > 0 ? week.trim() : getUtcWeekKey();
  const seed = hashSeed(`weekly-trial:${safeWeek}`);
  const lanes = [0, 1, 2];
  const baseLane = lanes[seed % lanes.length] ?? 1;
  const nextLane = lanes[(seed >> 3) % lanes.length] ?? 0;
  const thirdLane = lanes[(seed >> 6) % lanes.length] ?? 2;
  return {
    id: `weekly-trial-${safeWeek}`,
    duration: 38,
    rewardBonus: 0,
    spawns: [
      { at: 0, lane: baseLane, tierId: "grunt", count: 6, cadence: 1.8, taunt: "Trial begins!" },
      { at: 2, lane: nextLane, tierId: "runner", count: 5, cadence: 2.1 },
      { at: 6, lane: thirdLane, tierId: "grunt", count: 7, cadence: 1.6 },
      { at: 12, lane: baseLane, tierId: "runner", count: 4, cadence: 2.4 },
      { at: 16, lane: nextLane, tierId: "brute", count: 2, cadence: 5.5 },
      { at: 20, lane: thirdLane, tierId: "witch", count: 1, cadence: 0 },
      { at: 24, lane: baseLane, tierId: "grunt", count: 6, cadence: 1.7 },
      { at: 28, lane: nextLane, tierId: "runner", count: 4, cadence: 2.2 },
      { at: 32, lane: thirdLane, tierId: "grunt", count: 4, cadence: 1.8 }
    ]
  };
}

