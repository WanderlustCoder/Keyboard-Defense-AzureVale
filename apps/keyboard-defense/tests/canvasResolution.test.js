import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { calculateCanvasResolution, createDprListener } from "../src/utils/canvasResolution.ts";

describe("calculateCanvasResolution", () => {
  it("clamps css width to base width when larger", () => {
    const result = calculateCanvasResolution({
      baseWidth: 960,
      baseHeight: 540,
      availableWidth: 1400,
      devicePixelRatio: 1
    });
    expect(result.cssWidth).toBe(960);
    expect(result.renderWidth).toBe(960);
  });

  it("scales render size with device pixel ratio", () => {
    const result = calculateCanvasResolution({
      baseWidth: 960,
      baseHeight: 540,
      availableWidth: 600,
      devicePixelRatio: 2
    });
    expect(result.cssWidth).toBe(600);
    expect(result.renderWidth).toBe(1200);
    expect(result.cssHeight).toBe(Math.round((540 / 960) * 600));
  });

  it("respects minimum width fallback", () => {
    const result = calculateCanvasResolution({
      baseWidth: 960,
      baseHeight: 540,
      availableWidth: 100,
      devicePixelRatio: 1
    });
    expect(result.cssWidth).toBeGreaterThanOrEqual(320);
    expect(result.renderWidth).toBeGreaterThanOrEqual(320);
  });
});

describe("createDprListener", () => {
  let originalWindow;

  beforeEach(() => {
    vi.useFakeTimers();
    originalWindow = globalThis.window;
    globalThis.window = {
      devicePixelRatio: 1,
      matchMedia: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      setTimeout: globalThis.setTimeout,
      clearTimeout: globalThis.clearTimeout
    };
  });

  afterEach(() => {
    vi.useRealTimers();
    if (originalWindow === undefined) {
      delete globalThis.window;
    } else {
      globalThis.window = originalWindow;
    }
  });

  it("notifies when matchMedia triggers a DPR change", () => {
    const mediaHandlers = [];
    window.matchMedia = vi.fn().mockImplementation(() => {
      return {
        addEventListener: (_, handler) => {
          mediaHandlers.push(handler);
        },
        removeEventListener: vi.fn()
      };
    });
    const onChange = vi.fn();
    const handle = createDprListener({
      onChange,
      debounceMs: 0,
      getCurrent: () => window.devicePixelRatio
    });
    handle.start();
    expect(window.matchMedia).toHaveBeenCalledWith("(resolution: 1dppx)");
    window.devicePixelRatio = 2;
    mediaHandlers[0]?.();
    vi.runAllTimers();
    expect(onChange).toHaveBeenCalledTimes(1);
    expect(onChange.mock.calls[0][0]).toEqual({ previous: 1, next: 2, cause: "media" });
  });

  it("falls back to resize listeners and simulate()", () => {
    window.matchMedia = undefined;
    const addEventListener = vi.fn();
    const removeEventListener = vi.fn();
    window.addEventListener = addEventListener;
    window.removeEventListener = removeEventListener;
    const onChange = vi.fn();
    const handle = createDprListener({
      onChange,
      debounceMs: 0,
      getCurrent: () => window.devicePixelRatio
    });
    handle.start();
    expect(addEventListener).toHaveBeenCalledWith(
      "resize",
      expect.any(Function),
      expect.objectContaining({ passive: true })
    );
    handle.simulate(1.75);
    expect(onChange).toHaveBeenCalledTimes(1);
    expect(onChange.mock.calls[0][0]).toEqual({
      previous: 1,
      next: 1.75,
      cause: "simulate"
    });
    expect(handle.getCurrent()).toBe(1.75);
  });
});
