import { test, expect } from "vitest";
import { readFileSync } from "node:fs";
import { parseHTML } from "linkedom";
import { TypingDrillsOverlay } from "../src/ui/typingDrills.ts";

const htmlSource = readFileSync(new URL("../public/index.html", import.meta.url), "utf8");

test("TypingDrillsOverlay symbols mode accepts digits and punctuation", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    performance: window.performance ?? global.performance
  });

  const originalRandom = Math.random;
  Math.random = () => 0;

  try {
    const root = document.getElementById("typing-drills-overlay");
    expect(root).toBeTruthy();
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("symbols", "test");
    overlay.start("symbols");

    const sendKey = (key) => {
      overlay["handleKey"]({ key, preventDefault: () => {} });
    };

    expect(overlay["state"].target).toBe("1-2-3");
    for (const char of "1-2-3") {
      sendKey(char);
    }

    overlay["state"].buffer = "";
    overlay["state"].target = "go!";
    for (const char of "go!") {
      sendKey(char);
    }

    overlay["state"].buffer = "";
    overlay["state"].target = "x^2";
    for (const char of "x^2") {
      sendKey(char);
    }

    expect(overlay["state"].wordsCompleted).toBe(3);
    expect(overlay["state"].errors).toBe(0);
  } finally {
    Math.random = originalRandom;
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay symbols mode gates advanced targets until unlocked", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  let randomValue = 0.9999;
  const originalRandom = Math.random;
  Math.random = () => randomValue;

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.setAdvancedSymbolsUnlocked(false);
    overlay.open("symbols", "test");
    expect(overlay["state"].target).toBe("under_score");

    overlay.setAdvancedSymbolsUnlocked(true);
    overlay.reset("symbols");
    expect(overlay["state"].target).toBe("(paren)");
  } finally {
    Math.random = originalRandom;
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay sprint mode starts a 60s timer", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    setInterval: global.setInterval,
    clearInterval: global.clearInterval,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    setInterval: window.setInterval?.bind(window) ?? global.setInterval,
    clearInterval: window.clearInterval?.bind(window) ?? global.clearInterval,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("sprint", "test");
    overlay.start("sprint");

    expect(overlay["state"].mode).toBe("sprint");
    expect(overlay["state"].timerEndsAt).not.toBeNull();
    expect(overlay["state"].timerEndsAt - overlay["state"].startTime).toBe(60000);

    overlay.reset("sprint");
  } finally {
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay sprint ghost shows pace and saves best run", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  class MemoryStorage {
    constructor(entries = {}) {
      this.entries = new Map(Object.entries(entries));
    }

    getItem(key) {
      return this.entries.has(key) ? this.entries.get(key) : null;
    }

    setItem(key, value) {
      this.entries.set(key, String(value));
    }

    removeItem(key) {
      this.entries.delete(key);
    }
  }

  const storageKey = "keyboard-defense:typing-drill-ghosts";
  const storage = new MemoryStorage({
    [storageKey]: JSON.stringify({
      version: 1,
      sprint: {
        mode: "sprint",
        timerMs: 60000,
        words: 20,
        accuracy: 0.91,
        bestCombo: 7,
        wpm: 55,
        createdAt: 1700000000000,
        timeline: [
          { tMs: 0, words: 0 },
          { tMs: 5000, words: 4 }
        ]
      }
    })
  });

  const hadLocalStorage = Object.prototype.hasOwnProperty.call(global, "localStorage");
  const originalLocalStorage = global.localStorage;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    setInterval: global.setInterval,
    clearInterval: global.clearInterval,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    setInterval: window.setInterval?.bind(window) ?? global.setInterval,
    clearInterval: window.clearInterval?.bind(window) ?? global.clearInterval,
    performance: window.performance ?? global.performance,
    localStorage: storage
  });

  window.localStorage = storage;

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  const originalTimers = {
    setInterval: window.setInterval,
    clearInterval: window.clearInterval
  };

  window.setInterval = () => 1;
  window.clearInterval = () => {};

  const originalPerformanceNow = window.performance?.now;
  let now = 1000;
  if (window.performance) {
    window.performance.now = () => now;
  }

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("sprint", "test");

    const progressLabel = document.getElementById("typing-drill-progress");
    expect(progressLabel?.textContent).toBe("Best: 20 words");

    overlay.start("sprint");
    overlay["state"].elapsedMs = 5000;
    overlay["state"].wordsCompleted = 6;
    overlay["updateMetrics"]();
    expect(progressLabel?.textContent).toBe("Words: 6 / Ghost: 4 (+2)");

    overlay["state"].wordsCompleted = 22;
    overlay["state"].correctInputs = 110;
    overlay["state"].totalInputs = 120;
    now = overlay["state"].startTime + 60000;
    overlay["finish"]("timeout");

    const updated = JSON.parse(storage.getItem(storageKey));
    expect(updated.version).toBe(1);
    expect(updated.sprint.words).toBe(22);
  } finally {
    if (window.performance && typeof originalPerformanceNow === "function") {
      window.performance.now = originalPerformanceNow;
    }
    Object.assign(window, originalTimers);
    Object.assign(global, originalGlobals);
    if (hadLocalStorage) {
      global.localStorage = originalLocalStorage;
    } else {
      // eslint-disable-next-line no-delete-var
      delete global.localStorage;
    }
  }
});

test("TypingDrillsOverlay hand mode toggles left/right pools", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    setInterval: global.setInterval,
    clearInterval: global.clearInterval,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    setInterval: window.setInterval?.bind(window) ?? global.setInterval,
    clearInterval: window.clearInterval?.bind(window) ?? global.clearInterval,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  const originalRandom = Math.random;
  Math.random = () => 0;

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("hand", "test");
    expect(overlay["state"].mode).toBe("hand");
    expect(overlay["state"].target).toBe("rest");

    overlay["handBtn"]?.click();
    expect(overlay["state"].target).toBe("lion");

    overlay.start("hand");
    expect(overlay["state"].mode).toBe("hand");
    expect(overlay["state"].target).toBe("lion");

    const sendKey = (key) => {
      overlay["handleKey"]({ key, preventDefault: () => {} });
    };

    for (const char of "lion") {
      sendKey(char);
    }

    expect(overlay["state"].wordsCompleted).toBe(1);
    expect(overlay["state"].errors).toBe(0);

    overlay.reset("hand");
  } finally {
    Math.random = originalRandom;
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay support mode routes the highlighted lane", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    setInterval: global.setInterval,
    clearInterval: global.clearInterval,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    setInterval: window.setInterval?.bind(window) ?? global.setInterval,
    clearInterval: window.clearInterval?.bind(window) ?? global.clearInterval,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  const originalRandom = Math.random;
  Math.random = () => 0;

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("support", "test");
    overlay.start("support");

    expect(overlay["state"].mode).toBe("support");
    expect(overlay["supportPromptLane"]).toBe(0);
    expect(overlay["supportPromptAction"]).toBe("Shield");

    overlay["handleKey"]({ key: "2", preventDefault: () => {} });
    expect(overlay["state"].errors).toBe(1);
    expect(overlay["state"].wordsCompleted).toBe(0);
    expect(overlay["supportPromptLane"]).toBe(1);

    overlay["handleKey"]({ key: "2", preventDefault: () => {} });
    expect(overlay["state"].correctInputs).toBe(1);
    expect(overlay["state"].wordsCompleted).toBe(1);
    expect(overlay["state"].errors).toBe(1);

    overlay.reset("support");
  } finally {
    Math.random = originalRandom;
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay sentences mode supports spaces and punctuation", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    setInterval: global.setInterval,
    clearInterval: global.clearInterval,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    setInterval: window.setInterval?.bind(window) ?? global.setInterval,
    clearInterval: window.clearInterval?.bind(window) ?? global.clearInterval,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("sentences", "test");
    overlay.start("sentences");

    const sendKey = (key) => {
      overlay["handleKey"]({ key, preventDefault: () => {} });
    };

    overlay["state"].buffer = "";
    overlay["state"].target = "slow is smooth; smooth is fast.";
    for (const char of overlay["state"].target) {
      sendKey(char);
    }

    expect(overlay["state"].wordsCompleted).toBe(1);
    expect(overlay["state"].errors).toBe(0);

    overlay.reset("sentences");
  } finally {
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay rhythm mode shows metronome toggle and accepts alternating patterns", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    setInterval: global.setInterval,
    clearInterval: global.clearInterval,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    setInterval: window.setInterval?.bind(window) ?? global.setInterval,
    clearInterval: window.clearInterval?.bind(window) ?? global.clearInterval,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("rhythm", "test");

    const metronomeBtn = document.getElementById("typing-drill-metronome");
    expect(metronomeBtn?.getAttribute("data-visible")).toBe("true");
    expect(metronomeBtn?.getAttribute("aria-pressed")).toBe("true");

    overlay.start("rhythm");
    expect(overlay["state"].mode).toBe("rhythm");

    metronomeBtn?.click();
    expect(metronomeBtn?.getAttribute("aria-pressed")).toBe("false");
    metronomeBtn?.click();
    expect(metronomeBtn?.getAttribute("aria-pressed")).toBe("true");

    const sendKey = (key) => {
      overlay["handleKey"]({ key, preventDefault: () => {} });
    };

    overlay["state"].buffer = "";
    overlay["state"].target = "1 6 1 6 1 6";
    for (const char of overlay["state"].target) {
      sendKey(char);
    }

    expect(overlay["state"].wordsCompleted).toBe(1);
    overlay.reset("rhythm");
  } finally {
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay shortcuts mode detects Ctrl/Cmd combos and supports skip", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("shortcuts", "test");
    overlay.start("shortcuts");

    const sendKey = (payload) => {
      overlay["handleKey"]({
        key: payload.key,
        ctrlKey: Boolean(payload.ctrlKey),
        metaKey: Boolean(payload.metaKey),
        shiftKey: Boolean(payload.shiftKey),
        altKey: Boolean(payload.altKey),
        repeat: Boolean(payload.repeat),
        preventDefault: () => {},
        stopPropagation: () => {},
        stopImmediatePropagation: () => {}
      });
    };

    expect(overlay["state"].shortcutStepIndex).toBe(0);
    expect(overlay["state"].target).toBe("Select All");

    sendKey({ key: "a", ctrlKey: true });
    expect(overlay["state"].shortcutStepIndex).toBe(1);
    expect(overlay["state"].wordsCompleted).toBe(1);
    expect(overlay["state"].target).toBe("Copy");

    sendKey({ key: "v" });
    expect(overlay["state"].shortcutStepIndex).toBe(1);
    expect(overlay["state"].errors).toBe(1);

    sendKey({ key: "c", metaKey: true });
    expect(overlay["state"].shortcutStepIndex).toBe(2);
    expect(overlay["state"].wordsCompleted).toBe(2);
    expect(overlay["state"].target).toBe("Cut");

    sendKey({ key: "Enter" });
    expect(overlay["state"].shortcutStepIndex).toBe(3);
    expect(overlay["state"].wordsCompleted).toBe(2);
    expect(overlay["state"].target).toBe("Paste");

    sendKey({ key: "v", ctrlKey: true });
    expect(overlay["state"].shortcutStepIndex).toBe(4);
    expect(overlay["state"].wordsCompleted).toBe(3);
    expect(overlay["state"].target).toBe("Undo");

    sendKey({ key: "z", ctrlKey: true });
    expect(overlay["state"].shortcutStepIndex).toBe(5);
    expect(overlay["state"].wordsCompleted).toBe(4);
    expect(overlay["state"].target).toBe("Redo");

    sendKey({ key: "y", ctrlKey: true });
    expect(overlay["state"].active).toBe(false);
    expect(overlay["state"].wordsCompleted).toBe(5);
  } finally {
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay shift mode practices Shift timing with hold/tap cues", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("shift", "test");

    const slowMoBtn = document.getElementById("typing-drill-slowmo");
    expect(slowMoBtn?.getAttribute("data-visible")).toBe("true");
    expect(slowMoBtn?.getAttribute("aria-pressed")).toBe("true");

    overlay.start("shift");
    expect(slowMoBtn?.disabled).toBe(true);

    const sendKey = (payload) => {
      overlay["handleKey"]({
        key: payload.key,
        shiftKey: Boolean(payload.shiftKey),
        ctrlKey: Boolean(payload.ctrlKey),
        metaKey: Boolean(payload.metaKey),
        altKey: Boolean(payload.altKey),
        repeat: Boolean(payload.repeat),
        preventDefault: () => {},
        stopPropagation: () => {},
        stopImmediatePropagation: () => {}
      });
    };

    expect(overlay["state"].shiftStepIndex).toBe(0);
    expect(overlay["state"].target).toBe("Capital A");

    sendKey({ key: "a", shiftKey: false });
    expect(overlay["state"].shiftStepIndex).toBe(0);
    expect(overlay["state"].errors).toBe(1);

    sendKey({ key: "Shift" });
    expect(overlay["state"].shiftHeld).toBe(true);

    sendKey({ key: "a", shiftKey: true });
    expect(overlay["state"].shiftStepIndex).toBe(1);
    expect(overlay["state"].wordsCompleted).toBe(1);
    expect(overlay["state"].target).toBe("Capital L");

    sendKey({ key: "Enter" });
    expect(overlay["state"].shiftStepIndex).toBe(2);
    expect(overlay["state"].wordsCompleted).toBe(1);
    expect(overlay["state"].target).toBe("Capital Q");

    sendKey({ key: "p", shiftKey: true });
    expect(overlay["state"].shiftStepIndex).toBe(2);
    expect(overlay["state"].errors).toBeGreaterThanOrEqual(2);

    sendKey({ key: "q", shiftKey: true });
    expect(overlay["state"].shiftStepIndex).toBe(3);
    expect(overlay["state"].wordsCompleted).toBe(2);
  } finally {
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay focus mode uses adaptive key segments", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  const originalRandom = Math.random;
  Math.random = () => 0;

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.setFocusKeys(["t", "r", "s"]);
    overlay.open("focus", "test");
    overlay.start("focus");

    expect(overlay["state"].mode).toBe("focus");
    expect(overlay["state"].target).toBe("ttttt");
    expect(
      Math.round((overlay["state"].timerEndsAt ?? 0) - overlay["state"].startTime)
    ).toBe(30000);

    const progressLabel = document.getElementById("typing-drill-progress");
    expect(progressLabel?.textContent).toBe("Key T (1/3)");

    const sendKey = (key) => {
      overlay["handleKey"]({ key, preventDefault: () => {} });
    };

    for (const char of "ttttt") {
      sendKey(char);
    }

    expect(overlay["state"].wordsCompleted).toBe(1);
    expect(overlay["state"].errors).toBe(0);
  } finally {
    Math.random = originalRandom;
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay focus mode supports digraph segments", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    performance: window.performance ?? global.performance
  });

  const originalRandom = Math.random;
  Math.random = () => 0;

  try {
    const root = document.getElementById("typing-drills-overlay");
    expect(root).toBeTruthy();
    const overlay = new TypingDrillsOverlay({ root });
    overlay.setFocusKeys(["th", "er", "a"]);
    overlay.open("focus", "test");
    overlay.start("focus");

    expect(overlay["state"].mode).toBe("focus");
    expect(overlay["state"].target).toBe("th th th th");
    expect(
      Math.round((overlay["state"].timerEndsAt ?? 0) - overlay["state"].startTime)
    ).toBe(30000);

    const progressLabel = document.getElementById("typing-drill-progress");
    expect(progressLabel?.textContent).toBe("Digraph TH (1/3)");
  } finally {
    Math.random = originalRandom;
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay warmup mode builds a five-minute plan from warmup keys", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  const originalRandom = Math.random;
  Math.random = () => 0;

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.setWarmupKeys(["b", "c", "d"]);
    expect(overlay["warmupSegments"]).toHaveLength(5);
    expect(overlay["warmupSegments"][1].label).toBe("Key B");

    overlay.open("warmup", "test");
    overlay.start("warmup");

    expect(overlay["state"].mode).toBe("warmup");
    expect(overlay["state"].target).toBe("arrow");
    expect(
      Math.round((overlay["state"].timerEndsAt ?? 0) - overlay["state"].startTime)
    ).toBe(300000);

    const progressLabel = document.getElementById("typing-drill-progress");
    expect(progressLabel?.textContent).toBe("Accuracy Reset (1/5)");
  } finally {
    Math.random = originalRandom;
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay reaction mode schedules random cues and scores hits", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    setInterval: global.setInterval,
    clearInterval: global.clearInterval,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    setInterval: window.setInterval?.bind(window) ?? global.setInterval,
    clearInterval: window.clearInterval?.bind(window) ?? global.clearInterval,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  const originalRandom = Math.random;
  Math.random = () => 0;

  const originalTimers = {
    setTimeout: window.setTimeout,
    clearTimeout: window.clearTimeout,
    setInterval: window.setInterval,
    clearInterval: window.clearInterval
  };

  let nextTimeoutId = 1;
  const timeouts = new Map();
  window.setTimeout = (fn, ms) => {
    const id = nextTimeoutId++;
    timeouts.set(id, { fn, ms });
    return id;
  };
  window.clearTimeout = (id) => {
    timeouts.delete(id);
  };

  let nextIntervalId = 1;
  const intervals = new Map();
  window.setInterval = (fn, ms) => {
    const id = nextIntervalId++;
    intervals.set(id, { fn, ms });
    return id;
  };
  window.clearInterval = (id) => {
    intervals.delete(id);
  };

  const runUntilPrompt = (overlay) => {
    let safety = 25;
    while (!overlay["reactionPromptKey"] && timeouts.size > 0 && safety > 0) {
      safety -= 1;
      const [id, next] = Array.from(timeouts.entries()).sort((a, b) => (a[1].ms ?? 0) - (b[1].ms ?? 0))[0];
      timeouts.delete(id);
      next.fn();
    }
  };

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("reaction", "test");
    overlay.start("reaction");

    expect(overlay["state"].mode).toBe("reaction");
    expect(overlay["reactionPromptKey"]).toBeNull();

    overlay["handleKey"]({ key: "a", preventDefault: () => {} });
    expect(overlay["state"].errors).toBe(1);

    runUntilPrompt(overlay);
    expect(overlay["reactionPromptKey"]).toBe("a");

    overlay["handleKey"]({ key: "a", preventDefault: () => {} });
    expect(overlay["state"].wordsCompleted).toBe(1);
    expect(overlay["state"].correctInputs).toBe(1);
    expect(typeof overlay["reactionLastLatencyMs"]).toBe("number");

    overlay.reset("reaction");
  } finally {
    Math.random = originalRandom;
    Object.assign(window, originalTimers);
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay combo mode preserves combo until the segment mistakes run out", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    setInterval: global.setInterval,
    clearInterval: global.clearInterval,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    setInterval: window.setInterval?.bind(window) ?? global.setInterval,
    clearInterval: window.clearInterval?.bind(window) ?? global.clearInterval,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  const originalRandom = Math.random;
  Math.random = () => 0;

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("combo", "test");
    overlay.start("combo");

    expect(overlay["state"].mode).toBe("combo");
    expect(overlay["comboSegments"]).toHaveLength(3);
    expect(overlay["comboMistakesRemaining"]).toBeGreaterThan(0);

    overlay["state"].combo = 3;
    overlay["state"].bestCombo = 3;

    const sendKey = (key) => {
      overlay["handleKey"]({ key, preventDefault: () => {} });
    };

    overlay["state"].buffer = "";
    overlay["state"].target = "abc";
    sendKey("a");
    sendKey("x");
    sendKey("Backspace");
    sendKey("b");
    sendKey("c");

    expect(overlay["state"].combo).toBe(3);
    expect(overlay["state"].wordsCompleted).toBe(1);
    expect(overlay["state"].errors).toBe(1);
    expect(overlay["comboMistakesRemaining"]).toBeGreaterThanOrEqual(0);

    overlay["comboMistakesRemaining"] = 0;
    overlay["state"].buffer = "";
    overlay["state"].target = "de";
    sendKey("d");
    sendKey("x");
    sendKey("Backspace");
    sendKey("e");

    expect(overlay["state"].combo).toBe(0);
    expect(overlay["state"].wordsCompleted).toBe(2);
    expect(overlay["state"].errors).toBe(2);

    overlay.reset("combo");
  } finally {
    Math.random = originalRandom;
    Object.assign(global, originalGlobals);
  }
});

test("TypingDrillsOverlay reading mode runs a quick comprehension quiz", () => {
  const { window } = parseHTML(htmlSource);
  const { document } = window;

  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLButtonElement: global.HTMLButtonElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    setInterval: global.setInterval,
    clearInterval: global.clearInterval,
    performance: global.performance
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLButtonElement: window.HTMLButtonElement,
    setTimeout: window.setTimeout?.bind(window) ?? global.setTimeout,
    clearTimeout: window.clearTimeout?.bind(window) ?? global.clearTimeout,
    setInterval: window.setInterval?.bind(window) ?? global.setInterval,
    clearInterval: window.clearInterval?.bind(window) ?? global.clearInterval,
    performance: window.performance ?? global.performance
  });

  const root = document.getElementById("typing-drills-overlay");
  expect(root).toBeTruthy();

  const originalRandom = Math.random;
  Math.random = () => 0;

  try {
    const overlay = new TypingDrillsOverlay({ root });
    overlay.open("reading", "test");
    overlay.start("reading");

    expect(overlay["state"].mode).toBe("reading");
    expect(overlay["readingQueue"]).toHaveLength(2);
    expect(overlay["readingTotalQuestions"]).toBe(4);
    expect(overlay["readingStage"]).toBe("passage");

    const sendKey = (key) => {
      overlay["handleKey"]({ key, preventDefault: () => {} });
    };

    sendKey("Enter");
    expect(overlay["readingStage"]).toBe("question");

    sendKey("a");
    expect(overlay["state"].totalInputs).toBe(1);
    expect(overlay["state"].correctInputs).toBe(1);
    expect(overlay["state"].wordsCompleted).toBe(1);
    expect(overlay["state"].errors).toBe(0);
    expect(overlay["state"].combo).toBe(1);

    sendKey("a");
    expect(overlay["state"].totalInputs).toBe(2);
    expect(overlay["state"].correctInputs).toBe(1);
    expect(overlay["state"].wordsCompleted).toBe(1);
    expect(overlay["state"].errors).toBe(1);
    expect(overlay["state"].combo).toBe(0);
    expect(overlay["readingStage"]).toBe("passage");
    expect(overlay["readingPassageIndex"]).toBe(1);

    sendKey("Enter");
    expect(overlay["readingStage"]).toBe("question");

    sendKey("a");
    sendKey("c");

    expect(overlay["state"].totalInputs).toBe(4);
    expect(overlay["state"].correctInputs).toBe(3);
    expect(overlay["state"].wordsCompleted).toBe(3);
    expect(overlay["state"].errors).toBe(1);
    expect(overlay["state"].bestCombo).toBe(2);
    expect(overlay["state"].active).toBe(false);

    const summary = overlay["buildSummary"]();
    expect(Math.round(summary.accuracy * 100)).toBe(75);

    overlay.reset("reading");
  } finally {
    Math.random = originalRandom;
    Object.assign(global, originalGlobals);
  }
});
