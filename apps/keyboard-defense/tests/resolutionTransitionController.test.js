import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { parseHTML } from "linkedom";
import { ResolutionTransitionController } from "../src/ui/ResolutionTransitionController.ts";

describe("ResolutionTransitionController", () => {
  let originalWindow;
  let originalDocument;
  let canvas;

  beforeEach(() => {
    vi.useFakeTimers();
    const { window, document } = parseHTML("<html><body></body></html>");
    originalWindow = globalThis.window;
    originalDocument = globalThis.document;
    window.requestAnimationFrame = (cb) => cb();
    window.setTimeout = globalThis.setTimeout.bind(globalThis);
    window.clearTimeout = globalThis.clearTimeout.bind(globalThis);
    if (window.HTMLCanvasElement?.prototype) {
      window.HTMLCanvasElement.prototype.getContext = () => ({
        drawImage: () => {}
      });
    }
    globalThis.window = window;
    globalThis.document = document;
    canvas = document.createElement("canvas");
    canvas.width = 960;
    canvas.height = 540;
    canvas.getBoundingClientRect = () => ({
      left: 0,
      top: 0,
      width: canvas.width,
      height: canvas.height
    });
    document.body.appendChild(canvas);
  });

  afterEach(() => {
    vi.useRealTimers();
    if (originalWindow === undefined) {
      delete globalThis.window;
    } else {
      globalThis.window = originalWindow;
    }
    if (originalDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = originalDocument;
    }
  });

  it("computes duration from fade/hold options", () => {
    const controller = new ResolutionTransitionController(canvas, {
      fadeMs: 200,
      holdMs: 50
    });
    expect(controller.getDuration()).toBe(250);
  });

  it("creates an overlay and returns to idle after the transition", () => {
    const states = [];
    const controller = new ResolutionTransitionController(canvas, {
      fadeMs: 20,
      holdMs: 10,
      onStateChange: (state) => states.push(state)
    });

    controller.trigger();

    const overlay = document.body.querySelector(".canvas-transition-overlay");
    expect(overlay).toBeTruthy();
    expect(overlay.dataset.transition).toBe("canvas-resolution");
    expect(states).toContain("running");

    vi.runAllTimers();

    expect(document.body.querySelector(".canvas-transition-overlay")).toBeNull();
    expect(states[states.length - 1]).toBe("idle");
  });

  it("destroys overlay and timers immediately when destroy() is called", () => {
    const controller = new ResolutionTransitionController(canvas, {
      fadeMs: 100,
      holdMs: 50
    });
    controller.trigger();
    expect(document.body.querySelector(".canvas-transition-overlay")).toBeTruthy();

    controller.destroy();

    expect(document.body.querySelector(".canvas-transition-overlay")).toBeNull();
  });
});
