import { type DayNightMode } from "./dayNightTheme.js";

export type ParallaxScene = "auto" | "day" | "night" | "storm";

const STORAGE_KEY = "keyboard-defense:parallax-scene";
const DEFAULT_SCENE: ParallaxScene = "auto";

function normalizeScene(value: unknown): ParallaxScene {
  if (value === "day" || value === "night" || value === "storm") {
    return value;
  }
  if (value === "auto") {
    return "auto";
  }
  if (typeof value === "string") {
    const trimmed = value.trim().toLowerCase();
    if (trimmed === "day" || trimmed === "night" || trimmed === "storm") {
      return trimmed;
    }
  }
  return DEFAULT_SCENE;
}

export function readParallaxScene(storage: Storage | null | undefined): ParallaxScene {
  if (!storage) return DEFAULT_SCENE;
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return DEFAULT_SCENE;
    return normalizeScene(JSON.parse(raw));
  } catch {
    return DEFAULT_SCENE;
  }
}

export function writeParallaxScene(storage: Storage | null | undefined, scene: ParallaxScene): void {
  if (!storage) return;
  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(normalizeScene(scene)));
  } catch {
    // ignore persistence issues (private/local-only)
  }
}

export function resolveParallaxScene(
  scene: ParallaxScene,
  theme: DayNightMode
): Exclude<ParallaxScene, "auto"> {
  if (scene === "auto") {
    return theme === "day" ? "day" : "night";
  }
  return scene === "storm" ? "storm" : scene === "day" ? "day" : "night";
}
