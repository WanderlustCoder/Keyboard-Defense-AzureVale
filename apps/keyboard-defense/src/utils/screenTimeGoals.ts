export const SCREEN_TIME_SETTINGS_STORAGE_KEY = "keyboard-defense:screen-time-settings";
export const SCREEN_TIME_USAGE_STORAGE_KEY = "keyboard-defense:screen-time-usage";

export type ScreenTimeLockoutMode = "off" | "rest-15" | "rest-30" | "rest-60" | "today";

export type ScreenTimeSettings = {
  goalMinutes: number;
  lockoutMode: ScreenTimeLockoutMode;
};

export type ScreenTimeUsage = {
  day: string;
  totalMs: number;
  lockoutUntilMs: number | null;
};

const DEFAULT_SETTINGS: ScreenTimeSettings = { goalMinutes: 0, lockoutMode: "off" };
const GOAL_MINUTES_ALLOWED = new Set([0, 15, 20, 30, 45, 60, 90, 120]);
const LOCKOUT_MODE_ALLOWED = new Set<ScreenTimeLockoutMode>([
  "off",
  "rest-15",
  "rest-30",
  "rest-60",
  "today"
]);

function normalizeGoalMinutes(value: unknown): number {
  const parsed = typeof value === "number" ? value : Number.parseInt(String(value ?? ""), 10);
  if (!Number.isFinite(parsed)) return DEFAULT_SETTINGS.goalMinutes;
  const minutes = Math.max(0, Math.floor(parsed));
  if (!GOAL_MINUTES_ALLOWED.has(minutes)) return DEFAULT_SETTINGS.goalMinutes;
  return minutes;
}

function normalizeLockoutMode(value: unknown): ScreenTimeLockoutMode {
  const raw = typeof value === "string" ? value.trim() : "";
  if (!raw) return DEFAULT_SETTINGS.lockoutMode;
  const normalized = raw.toLowerCase() as ScreenTimeLockoutMode;
  if (!LOCKOUT_MODE_ALLOWED.has(normalized)) return DEFAULT_SETTINGS.lockoutMode;
  return normalized;
}

export function getLocalDayKey(date: Date | number = Date.now()): string {
  const value = date instanceof Date ? date : new Date(date);
  const year = value.getFullYear();
  const month = String(value.getMonth() + 1).padStart(2, "0");
  const day = String(value.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function normalizeUsage(value: unknown, day: string): ScreenTimeUsage {
  if (!value || typeof value !== "object") {
    return { day, totalMs: 0, lockoutUntilMs: null };
  }
  const data = value as Record<string, unknown>;
  const storedDay = typeof data.day === "string" ? data.day.trim() : "";
  const totalRaw = typeof data.totalMs === "number" ? data.totalMs : Number(data.totalMs);
  const totalMs = Number.isFinite(totalRaw) ? Math.max(0, totalRaw) : 0;
  const lockoutRaw =
    typeof data.lockoutUntilMs === "number" ? data.lockoutUntilMs : Number(data.lockoutUntilMs);
  const lockoutUntilMs = Number.isFinite(lockoutRaw) ? Math.max(0, lockoutRaw) : null;
  if (!storedDay || storedDay !== day) {
    return { day, totalMs: 0, lockoutUntilMs: null };
  }
  return { day: storedDay, totalMs, lockoutUntilMs };
}

export function readScreenTimeSettings(storage: Storage | null | undefined): ScreenTimeSettings {
  if (!storage) return { ...DEFAULT_SETTINGS };
  let raw;
  try {
    raw = storage.getItem(SCREEN_TIME_SETTINGS_STORAGE_KEY);
  } catch {
    return { ...DEFAULT_SETTINGS };
  }
  if (!raw) return { ...DEFAULT_SETTINGS };
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { ...DEFAULT_SETTINGS };
  }
  if (!parsed || typeof parsed !== "object") return { ...DEFAULT_SETTINGS };
  const data = parsed as Record<string, unknown>;
  return {
    goalMinutes: normalizeGoalMinutes(data.goalMinutes),
    lockoutMode: normalizeLockoutMode(data.lockoutMode)
  };
}

export function writeScreenTimeSettings(
  storage: Storage | null | undefined,
  settings: Partial<ScreenTimeSettings>
): ScreenTimeSettings {
  const current = readScreenTimeSettings(storage);
  const next: ScreenTimeSettings = {
    goalMinutes:
      settings.goalMinutes === undefined ? current.goalMinutes : normalizeGoalMinutes(settings.goalMinutes),
    lockoutMode:
      settings.lockoutMode === undefined ? current.lockoutMode : normalizeLockoutMode(settings.lockoutMode)
  };
  if (!storage) return next;
  try {
    storage.setItem(SCREEN_TIME_SETTINGS_STORAGE_KEY, JSON.stringify(next));
  } catch {
    return current;
  }
  return next;
}

export function readScreenTimeUsage(
  storage: Storage | null | undefined,
  nowMs: number = Date.now()
): ScreenTimeUsage {
  const day = getLocalDayKey(nowMs);
  if (!storage) return { day, totalMs: 0, lockoutUntilMs: null };
  let raw;
  try {
    raw = storage.getItem(SCREEN_TIME_USAGE_STORAGE_KEY);
  } catch {
    return { day, totalMs: 0, lockoutUntilMs: null };
  }
  if (!raw) return { day, totalMs: 0, lockoutUntilMs: null };
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { day, totalMs: 0, lockoutUntilMs: null };
  }
  return normalizeUsage(parsed, day);
}

export function writeScreenTimeUsage(
  storage: Storage | null | undefined,
  usage: ScreenTimeUsage
): void {
  if (!storage) return;
  try {
    storage.setItem(SCREEN_TIME_USAGE_STORAGE_KEY, JSON.stringify(usage));
  } catch {
    // best effort
  }
}

export function computeLockoutUntilMs(
  mode: ScreenTimeLockoutMode,
  nowMs: number = Date.now()
): number | null {
  if (mode === "off") return null;
  if (mode === "today") {
    const date = new Date(nowMs);
    date.setHours(24, 0, 0, 0);
    return date.getTime();
  }
  const match = mode.match(/^rest-(\d+)$/);
  if (match) {
    const minutes = Number.parseInt(match[1] ?? "", 10);
    if (!Number.isFinite(minutes) || minutes <= 0) return null;
    return nowMs + minutes * 60_000;
  }
  return null;
}

export function isLockoutActive(usage: ScreenTimeUsage, nowMs: number = Date.now()): boolean {
  const until = usage.lockoutUntilMs;
  return Number.isFinite(until ?? Number.NaN) && typeof until === "number" && until > nowMs;
}

export function getLockoutRemainingMs(
  usage: ScreenTimeUsage,
  nowMs: number = Date.now()
): number {
  const until = usage.lockoutUntilMs;
  if (!Number.isFinite(until ?? Number.NaN) || typeof until !== "number") return 0;
  return Math.max(0, until - nowMs);
}

