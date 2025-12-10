const STORAGE_KEY = "keyboard-defense:day-night-theme";

export type DayNightMode = "day" | "night";

export type DayNightThemeState = {
  mode: DayNightMode;
  updatedAt: string | null;
};

const DEFAULT_STATE: DayNightThemeState = {
  mode: "night",
  updatedAt: null
};

function normalizeMode(value: unknown): DayNightMode {
  return value === "day" ? "day" : "night";
}

export function readDayNightTheme(storage: Storage | null | undefined): DayNightThemeState {
  if (!storage) return { ...DEFAULT_STATE };
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_STATE };
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return { ...DEFAULT_STATE };
    const mode = normalizeMode((parsed as Record<string, unknown>).mode);
    const updatedAt =
      typeof (parsed as Record<string, unknown>).updatedAt === "string"
        ? ((parsed as Record<string, unknown>).updatedAt as string)
        : null;
    return { mode, updatedAt };
  } catch {
    return { ...DEFAULT_STATE };
  }
}

export function writeDayNightTheme(
  storage: Storage | null | undefined,
  state: DayNightThemeState
): void {
  if (!storage) return;
  storage.setItem(
    STORAGE_KEY,
    JSON.stringify({
      mode: normalizeMode(state?.mode),
      updatedAt: state?.updatedAt ?? new Date().toISOString()
    })
  );
}
