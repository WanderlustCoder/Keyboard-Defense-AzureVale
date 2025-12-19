const MIN_CANVAS_WIDTH = 320;

export interface CanvasResolutionInput {
  baseWidth: number;
  baseHeight: number;
  availableWidth: number;
  availableHeight?: number;
  devicePixelRatio?: number;
  minWidth?: number;
}

export interface CanvasResolution {
  cssWidth: number;
  cssHeight: number;
  renderWidth: number;
  renderHeight: number;
}

export function calculateCanvasResolution(input: CanvasResolutionInput): CanvasResolution {
  const {
    baseWidth,
    baseHeight,
    availableWidth,
    availableHeight,
    devicePixelRatio = 1,
    minWidth = MIN_CANVAS_WIDTH
  } = input;

  const safeWidth = Number.isFinite(availableWidth) && availableWidth > 0 ? availableWidth : baseWidth;
  const aspectRatio = baseHeight / baseWidth;
  let boundedCssWidth = clamp(Math.round(safeWidth), minWidth, baseWidth);

  if (typeof availableHeight === "number" && Number.isFinite(availableHeight) && availableHeight > 0) {
    const maxWidthFromHeight = Math.max(1, Math.floor(availableHeight / aspectRatio));
    boundedCssWidth = Math.min(boundedCssWidth, maxWidthFromHeight);
  }

  const cssHeight = Math.round(boundedCssWidth * aspectRatio);
  const dpr = Math.max(1, devicePixelRatio);
  const renderWidth = Math.max(1, Math.round(boundedCssWidth * dpr));
  const renderHeight = Math.max(1, Math.round(cssHeight * dpr));

  return {
    cssWidth: boundedCssWidth,
    cssHeight,
    renderWidth,
    renderHeight
  };
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

export type DprChangeCause = "media" | "simulate" | "manual";

export interface DprChangeEvent {
  previous: number;
  next: number;
  cause: DprChangeCause;
}

export interface DprListenerOptions {
  onChange: (event: DprChangeEvent) => void;
  debounceMs?: number;
  getCurrent?: () => number;
}

export interface DprListenerHandle {
  start(): void;
  stop(): void;
  simulate(dpr: number, cause?: DprChangeCause): void;
  getCurrent(): number;
}

export function createDprListener(options: DprListenerOptions): DprListenerHandle {
  if (typeof window === "undefined") {
    return {
      start() {},
      stop() {},
      simulate() {},
      getCurrent: () => 1
    };
  }

  const debounceMs = Math.max(0, Number.isFinite(options.debounceMs) ? Number(options.debounceMs) : 120);
  const readCurrent =
    typeof options.getCurrent === "function"
      ? options.getCurrent
      : () => {
          const ratio = typeof window.devicePixelRatio === "number" ? window.devicePixelRatio : 1;
          return sanitizeDpr(ratio);
        };

  let currentDpr = readCurrent();
  let mediaQuery: MediaQueryList | null = null;
  let mediaHandler: (() => void) | null = null;
  let resizeHandler: (() => void) | null = null;
  let debounceTimer: number | null = null;

  const clearDebounce = () => {
    if (debounceTimer !== null) {
      window.clearTimeout(debounceTimer);
      debounceTimer = null;
    }
  };

  const notify = (next: number, cause: DprChangeCause) => {
    const normalized = sanitizeDpr(next);
    if (Math.abs(normalized - currentDpr) < 0.01) {
      return;
    }
    const previous = currentDpr;
    currentDpr = normalized;
    options.onChange?.({ previous, next: normalized, cause });
  };

  const scheduleRead = () => {
    clearDebounce();
    debounceTimer = window.setTimeout(() => {
      debounceTimer = null;
      notify(readCurrent(), "media");
      refreshMediaQuery();
    }, debounceMs);
  };

  const refreshMediaQuery = () => {
    cleanupListeners();
    const targetDpr = currentDpr;
    if (typeof window.matchMedia === "function") {
      try {
        mediaQuery = window.matchMedia(`(resolution: ${targetDpr}dppx)`);
      } catch {
        mediaQuery = null;
      }
      if (mediaQuery) {
        mediaHandler = () => scheduleRead();
        if (typeof mediaQuery.addEventListener === "function") {
          mediaQuery.addEventListener("change", mediaHandler);
        } else if (typeof mediaQuery.addListener === "function") {
          mediaQuery.addListener(mediaHandler);
        }
        return;
      }
    }
    resizeHandler = () => scheduleRead();
    window.addEventListener("resize", resizeHandler, { passive: true });
  };

  const cleanupListeners = () => {
    clearDebounce();
    if (mediaQuery && mediaHandler) {
      try {
        if (typeof mediaQuery.removeEventListener === "function") {
          mediaQuery.removeEventListener("change", mediaHandler);
        } else if (typeof mediaQuery.removeListener === "function") {
          mediaQuery.removeListener(mediaHandler);
        }
      } catch {
        // ignore
      }
    }
    if (resizeHandler) {
      window.removeEventListener("resize", resizeHandler);
    }
    mediaQuery = null;
    mediaHandler = null;
    resizeHandler = null;
  };

  return {
    start() {
      currentDpr = readCurrent();
      refreshMediaQuery();
    },
    stop() {
      cleanupListeners();
    },
    simulate(dpr: number, cause: DprChangeCause = "simulate") {
      cleanupListeners();
      notify(dpr, cause);
      refreshMediaQuery();
    },
    getCurrent() {
      return currentDpr;
    }
  };
}

function sanitizeDpr(value: number): number {
  if (!Number.isFinite(value) || value <= 0) {
    return 1;
  }
  return Math.round(value * 100) / 100;
}
