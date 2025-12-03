import { describe, expect, test, vi } from "vitest";
import { readFileSync } from "node:fs";
import { parseHTML } from "linkedom";
import { HudView } from "../src/ui/hud.ts";
import { defaultConfig } from "../src/core/config.ts";

const htmlSource = readFileSync(new URL("../public/index.html", import.meta.url), "utf8");

function createMatchMediaStub(state = {}) {
  const resolver =
    typeof state === "function" ? state : (query) => state[query] ?? state.default ?? false;
  return (query) => ({
    matches: Boolean(resolver(query)),
    media: query,
    onchange: null,
    addEventListener: () => {},
    removeEventListener: () => {},
    addListener: () => {},
    removeListener: () => {},
    dispatchEvent: () => false
  });
}

function normalizeHtml(html) {
  return html.replace(/\\n/g, " ").replace(/[\r\n]+/g, " ").replace(/\s+/g, " ").trim();
}

function setupHud() {
  const { window } = parseHTML(htmlSource);
  const { document } = window;
  const originalGlobals = {
    document: global.document,
    window: global.window,
    HTMLElement: global.HTMLElement,
    HTMLDivElement: global.HTMLDivElement,
    HTMLButtonElement: global.HTMLButtonElement,
    HTMLInputElement: global.HTMLInputElement,
    HTMLTextAreaElement: global.HTMLTextAreaElement,
    HTMLSelectElement: global.HTMLSelectElement,
    HTMLUListElement: global.HTMLUListElement,
    HTMLTableSectionElement: global.HTMLTableSectionElement,
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    matchMedia: global.matchMedia
  };

  Object.assign(global, {
    document,
    window,
    HTMLElement: window.HTMLElement,
    HTMLDivElement: window.HTMLDivElement,
    HTMLButtonElement: window.HTMLButtonElement,
    HTMLInputElement: window.HTMLInputElement,
    HTMLTextAreaElement: window.HTMLTextAreaElement,
    HTMLSelectElement: window.HTMLSelectElement,
    HTMLUListElement: window.HTMLUListElement,
    HTMLTableSectionElement: window.HTMLTableSectionElement,
    setTimeout: window.setTimeout?.bind(window) ?? ((fn) => {
      fn();
      return 0;
    }),
    clearTimeout: window.clearTimeout?.bind(window) ?? (() => {}),
    matchMedia: createMatchMediaStub({ default: false })
  });
  window.matchMedia = global.matchMedia;

  const noop = () => {};
  const hud = new HudView(
    defaultConfig,
    {
      healthBar: "castle-health-bar",
      goldLabel: "resource-gold",
      goldDelta: "resource-delta",
      activeWord: "active-word",
      typingInput: "typing-input",
      upgradePanel: "upgrade-panel",
      comboLabel: "combo-stats",
      comboAccuracyDelta: "combo-accuracy-delta",
      eventLog: "battle-log",
      wavePreview: "wave-preview-list",
      wavePreviewHint: "wave-preview-hint",
      tutorialBanner: "tutorial-banner",
      tutorialSummary: {
        container: "tutorial-summary",
        stats: "tutorial-summary-stats",
        continue: "tutorial-summary-continue",
        replay: "tutorial-summary-replay"
      },
      pauseButton: "pause-button",
      shortcutOverlay: {
        container: "shortcut-overlay",
        closeButton: "shortcut-overlay-close",
        launchButton: "shortcut-launch"
      },
      optionsOverlay: {
        container: "options-overlay",
        closeButton: "options-overlay-close",
        resumeButton: "options-resume-button",
        soundToggle: "options-sound-toggle",
        soundVolumeSlider: "options-sound-volume",
        soundVolumeValue: "options-sound-volume-value",
        soundIntensitySlider: "options-sound-intensity",
        soundIntensityValue: "options-sound-intensity-value",
        diagnosticsToggle: "options-diagnostics-toggle",
        reducedMotionToggle: "options-reduced-motion-toggle",
        checkeredBackgroundToggle: "options-checkered-bg-toggle",
        readableFontToggle: "options-readable-font-toggle",
        dyslexiaFontToggle: "options-dyslexia-font-toggle",
        colorblindPaletteToggle: "options-colorblind-toggle",
        defeatAnimationSelect: "options-defeat-animation",
        telemetryToggle: "options-telemetry-toggle",
        telemetryToggleWrapper: "options-telemetry-toggle-wrapper",
        hudZoomSelect: "options-hud-zoom",
        fontScaleSelect: "options-font-scale",
        analyticsExportButton: "options-analytics-export"
      },
      waveScorecard: {
        container: "wave-scorecard",
        stats: "wave-scorecard-stats",
        continue: "wave-scorecard-continue"
      },
      analyticsViewer: {
        container: "debug-analytics-viewer",
        tableBody: "debug-analytics-viewer-body",
        filterSelect: "debug-analytics-viewer-filter",
        drills: "debug-analytics-drills"
      }
    },
    {
      onCastleUpgrade: noop,
      onCastleRepair: noop,
      onPlaceTurret: noop,
      onUpgradeTurret: noop,
      onTurretPriorityChange: noop,
      onPauseRequested: noop,
      onResumeRequested: noop,
      onSoundToggle: noop,
      onSoundVolumeChange: noop,
      onSoundIntensityChange: noop,
      onDiagnosticsToggle: noop,
      onWaveScorecardContinue: noop,
      onReducedMotionToggle: noop,
      onCheckeredBackgroundToggle: noop,
      onReadableFontToggle: noop,
      onDyslexiaFontToggle: noop,
      onColorblindPaletteToggle: noop,
      onDefeatAnimationModeChange: noop,
      onHudFontScaleChange: noop
    }
  );

  const cleanup = () => {
    Object.assign(global, originalGlobals);
  };

  return { hud, cleanup, document };
}

describe("Tutorial summary snapshot", () => {
  test("renders stats and CTA wiring matches snapshot", () => {
    const { hud, cleanup, document } = setupHud();
    try {
      const onContinue = vi.fn();
      const onReplay = vi.fn();
      hud.showTutorialSummary(
        { accuracy: 0.985, bestCombo: 42, breaches: 1, gold: 375 },
        { onContinue, onReplay }
      );

      const container = document.getElementById("tutorial-summary");
      expect(container?.dataset.visible).toBe("true");

      const stats = Array.from(container?.querySelectorAll("li") ?? []).map((node) => [
        node.dataset.field ?? "",
        (node.textContent ?? "").trim()
      ]);
      expect(stats).toEqual([
        ["accuracy", "Accuracy: 98.5%"],
        ["combo", "Best Combo: x42"],
        ["breaches", "Breaches sustained: 1"],
        ["shield-breaks", ""],
        ["gold", "Gold remaining: 375g"]
      ]);

      const summaryHtml = normalizeHtml(container?.innerHTML ?? "");
      expect(summaryHtml).toBe(
        '<div class="tutorial-summary-card"> <h2 id="tutorial-summary-title">Training Complete</h2> <p id="tutorial-summary-copy">Great work defending the gate. Here\'s how you did:</p> <ul id="tutorial-summary-stats"> <li data-field="accuracy">Accuracy: 98.5%</li> <li data-field="combo">Best Combo: x42</li> <li data-field="breaches">Breaches sustained: 1</li> <li data-field="shield-breaks"></li> <li data-field="gold">Gold remaining: 375g</li> </ul> <div class="tutorial-summary-actions"> <button id="tutorial-summary-continue">Proceed to Campaign</button> <button id="tutorial-summary-replay">Replay Tutorial</button> </div> </div>'
      );

      container?.querySelector("#tutorial-summary-continue")?.click();
      container?.querySelector("#tutorial-summary-replay")?.click();
      expect(onContinue).toHaveBeenCalledTimes(1);
      expect(onReplay).toHaveBeenCalledTimes(1);
    } finally {
      cleanup();
    }
  });
});
