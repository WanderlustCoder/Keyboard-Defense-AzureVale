import { test } from "vitest";
import assert from "node:assert/strict";
import { HudView } from "../dist/src/ui/hud.js";
import { defaultConfig } from "../dist/src/core/config.js";

class FakeElement {
  constructor(tag, id) {
    this.tag = tag;
    this.id = id ?? null;
    this.children = [];
    this.textContent = "";
    this._innerHTML = "";
    this.className = "";
    this.value = "";
    this.disabled = false;
    this.style = {};
    this.dataset = {};
    this.onclick = null;
    this.onchange = null;
    this.oninput = null;
    this.onmouseenter = null;
    this.onmouseleave = null;
    this.onfocusin = null;
    this.onfocusout = null;
    this.attributes = new Map();
    this.tabIndex = 0;
    this.parentElement = null;
    this.parentNode = null;
  }

  set innerHTML(value) {
    this._innerHTML = String(value ?? "");
    this.children = [];
    this.textContent = this._innerHTML.replace(/<[^>]*>/g, "");
  }

  get innerHTML() {
    return this._innerHTML;
  }

  appendChild(child) {
    if (child && child.isFragment) {
      for (const fragmentChild of child.children) {
        this.appendChild(fragmentChild);
      }
      child.children = [];
      return child;
    }
    this.children.push(child);
    if (child && typeof child === "object") {
      child.parentElement = this;
      child.parentNode = this;
      const childText =
        typeof child.textContent === "string"
          ? child.textContent
          : Array.isArray(child.children)
            ? child.children.map((node) => node.textContent ?? "").join("")
            : "";
      if (childText) {
        this.textContent = `${this.textContent}${childText}`;
      }
    }
    if (this.tag === "select" && this.value === "" && child && typeof child.value === "string") {
      this.value = child.value;
    }
    return child;
  }

  replaceChildren(...children) {
    this.children = [...children];
  }

  addEventListener(type, handler) {
    if (type === "click") {
      this.onclick = handler;
    } else if (type === "change") {
      this.onchange = handler;
    } else if (type === "input") {
      this.oninput = handler;
    } else if (type === "mouseenter") {
      this.onmouseenter = handler;
    } else if (type === "mouseleave") {
      this.onmouseleave = handler;
    } else if (type === "focusin") {
      this.onfocusin = handler;
    } else if (type === "focusout") {
      this.onfocusout = handler;
    }
  }

  focus() {}
  select() {}

  setAttribute(name, value) {
    this.attributes.set(name, String(value));
  }

  getAttribute(name) {
    return this.attributes.has(name) ? this.attributes.get(name) : null;
  }

  removeAttribute(name) {
    this.attributes.delete(name);
  }

  querySelector(selector) {
    if (typeof selector !== "string") return null;
    const dataFieldMatch = selector.match(/^\[data-field="(.+)"\]$/);
    if (!dataFieldMatch) return null;
    const target = dataFieldMatch[1];
    const queue = [this];
    while (queue.length > 0) {
      const node = queue.shift();
      if (node && node.dataset && node.dataset.field === target) {
        return node;
      }
      if (node && Array.isArray(node.children)) {
        for (const child of node.children) {
          if (child && typeof child === "object") {
            queue.push(child);
          }
        }
      }
    }
    return null;
  }
}

class FakeInputElement extends FakeElement {
  constructor(id, type = "text") {
    super("input", id);
    this.type = type;
    this.value = "";
    this.checked = false;
  }
}

class FakeDocumentFragment {
  constructor() {
    this.children = [];
    this.isFragment = true;
  }

  appendChild(child) {
    this.children.push(child);
    return child;
  }
}

const createStubDocument = () => {
  const registry = new Map();

  const register = (id, element) => {
    registry.set(id, element);
    return element;
  };

  const documentElement = new FakeElement("html");
  const body = new FakeElement("body");

  const documentStub = {
    getElementById(id) {
      const el = registry.get(id);
      if (!el) {
        throw new Error(`Missing element ${id}`);
      }
      return el;
    },
    createElement(tag) {
      return new FakeElement(tag);
    },
    createDocumentFragment() {
      return new FakeDocumentFragment();
    }
  };

  documentStub.documentElement = documentElement;
  documentStub.body = body;

  return { documentStub, register };
};

const initializeHud = () => {
  const originalDocument = global.document;
  const originalWindow = global.window;
  const originalHTMLElement = global.HTMLElement;
  const originalHTMLDivElement = global.HTMLDivElement;
  const originalHTMLButtonElement = global.HTMLButtonElement;
  const originalHTMLInputElement = global.HTMLInputElement;
  const originalHTMLTextAreaElement = global.HTMLTextAreaElement;
  const originalHTMLSelectElement = global.HTMLSelectElement;
  const originalHTMLUListElement = global.HTMLUListElement;
  const originalHTMLTableSectionElement = global.HTMLTableSectionElement;
  const { documentStub, register } = createStubDocument();

  const findByClass = (root, className) => {
    if (!root || !Array.isArray(root.children)) return undefined;
    for (const child of root.children) {
      if (child && child.className === className) {
        return child;
      }
      const nested = findByClass(child, className);
      if (nested) {
        return nested;
      }
    }
    return undefined;
  };

  global.HTMLElement = FakeElement;
  global.HTMLDivElement = FakeElement;
  global.HTMLButtonElement = FakeElement;
  global.HTMLInputElement = FakeInputElement;
  global.HTMLTextAreaElement = FakeElement;
  global.HTMLSelectElement = FakeElement;
  global.HTMLUListElement = FakeElement;
  global.HTMLTableSectionElement = FakeElement;

  const healthBar = new FakeElement("div", "castle-health-bar");
  const goldLabel = new FakeElement("span", "resource-gold");
  const goldDelta = new FakeElement("span", "resource-delta");
  const activeWord = new FakeElement("div", "active-word");
  const typingInput = new FakeInputElement("typing-input");
  const upgradePanel = new FakeElement("div", "upgrade-panel");
  const comboLabel = new FakeElement("div", "combo-stats");
  const logList = new FakeElement("ul", "battle-log");
  const wavePreview = new FakeElement("div", "wave-preview-list");
  const wavePreviewHint = new FakeElement("div", "wave-preview-hint");
  wavePreviewHint.dataset.visible = "false";
  wavePreviewHint.setAttribute("aria-hidden", "true");
  wavePreviewHint.setAttribute("role", "status");
  wavePreviewHint.setAttribute("aria-live", "polite");
  const tutorialBanner = new FakeElement("div", "tutorial-banner");
  const summaryContainer = new FakeElement("div", "tutorial-summary");
  const summaryStats = new FakeElement("ul", "tutorial-summary-stats");
  const summaryContinue = new FakeElement("button", "tutorial-summary-continue");
  const summaryReplay = new FakeElement("button", "tutorial-summary-replay");
  const pauseButton = new FakeElement("button", "pause-button");
  const optionsOverlay = new FakeElement("div", "options-overlay");
  optionsOverlay.dataset.visible = "false";
  const optionsClose = new FakeElement("button", "options-overlay-close");
  const optionsResume = new FakeElement("button", "options-resume-button");
  const soundToggle = new FakeInputElement("options-sound-toggle", "checkbox");
  const diagnosticsToggle = new FakeInputElement("options-diagnostics-toggle", "checkbox");
  const reducedMotionToggle = new FakeInputElement("options-reduced-motion-toggle", "checkbox");
  const checkeredBackgroundToggle = new FakeInputElement("options-checkered-bg-toggle", "checkbox");
  const readableFontToggle = new FakeInputElement("options-readable-font-toggle", "checkbox");
  const dyslexiaFontToggle = new FakeInputElement("options-dyslexia-font-toggle", "checkbox");
  const colorblindPaletteToggle = new FakeInputElement("options-colorblind-toggle", "checkbox");
  const soundVolumeSlider = new FakeInputElement("options-sound-volume", "range");
  soundVolumeSlider.value = "0.8";
  const soundVolumeValue = new FakeElement("span", "options-sound-volume-value");
  soundVolumeValue.textContent = "80%";
  const telemetryToggleWrapper = new FakeElement("label", "options-telemetry-toggle-wrapper");
  telemetryToggleWrapper.className = "option-toggle";
  const telemetryToggle = new FakeInputElement("options-telemetry-toggle", "checkbox");
  telemetryToggleWrapper.appendChild(telemetryToggle);
  const fontScaleSelect = new FakeElement("select", "options-font-scale");
  fontScaleSelect.value = "1";
  const analyticsExportButton = new FakeElement("button", "options-analytics-export");
  const optionsCastleBonus = new FakeElement("div", "options-castle-bonus");
  const optionsCastleBenefits = new FakeElement("ul", "options-castle-benefits");
  const waveScorecard = new FakeElement("div", "wave-scorecard");
  waveScorecard.dataset.visible = "false";
  const waveScorecardStats = new FakeElement("ul", "wave-scorecard-stats");
  const waveScorecardContinue = new FakeElement("button", "wave-scorecard-continue");
  const analyticsViewerContainer = new FakeElement("div", "debug-analytics-viewer");
  analyticsViewerContainer.dataset.visible = "false";
  analyticsViewerContainer.dataset.empty = "true";
  const analyticsViewerControls = new FakeElement("div");
  analyticsViewerControls.className = "analytics-viewer-controls";
  const analyticsFilterSelect = new FakeElement("select", "debug-analytics-viewer-filter");
  analyticsFilterSelect.value = "all";
  analyticsViewerControls.appendChild(analyticsFilterSelect);
  const analyticsViewerBody = new FakeElement("tbody", "debug-analytics-viewer-body");
  const placeholderRow = new FakeElement("tr");
  placeholderRow.className = "analytics-empty-row";
  const placeholderCell = new FakeElement("td");
  placeholderCell.colSpan = 20;
  placeholderCell.textContent = "No wave summaries yet - finish a wave to populate analytics.";
  placeholderRow.appendChild(placeholderCell);
  analyticsViewerBody.appendChild(placeholderRow);
  const analyticsViewerTable = new FakeElement("table");
  analyticsViewerTable.appendChild(analyticsViewerBody);
  analyticsViewerContainer.appendChild(analyticsViewerControls);
  analyticsViewerContainer.appendChild(analyticsViewerTable);

  const summaryFields = ["accuracy", "combo", "breaches", "gold"];
  for (const field of summaryFields) {
    const item = new FakeElement("li");
    item.dataset.field = field;
    summaryStats.appendChild(item);
  }
  summaryContainer.appendChild(summaryStats);
  summaryContainer.appendChild(summaryContinue);
  summaryContainer.appendChild(summaryReplay);

  const scorecardFields = [
    "wave",
    "accuracy",
    "combo",
    "session-combo",
    "defeated",
    "breaches",
    "perfect-words",
    "reaction",
    "dps",
    "dps-turret",
    "dps-typing",
    "damage-turret",
    "damage-typing",
    "shield-breaks",
    "repairs",
    "repair-health",
    "repair-gold",
    "bonus-gold",
    "castle-bonus",
    "gold"
  ];
  for (const field of scorecardFields) {
    const item = new FakeElement("li");
    item.dataset.field = field;
    waveScorecardStats.appendChild(item);
  }
  waveScorecard.appendChild(waveScorecardStats);
  waveScorecard.appendChild(waveScorecardContinue);

  register("castle-health-bar", healthBar);
  register("resource-gold", goldLabel);
  register("resource-delta", goldDelta);
  register("active-word", activeWord);
  register("typing-input", typingInput);
  register("upgrade-panel", upgradePanel);
  register("combo-stats", comboLabel);
  register("battle-log", logList);
  register("wave-preview-list", wavePreview);
  register("wave-preview-hint", wavePreviewHint);
  register("tutorial-banner", tutorialBanner);
  register("tutorial-summary", summaryContainer);
  register("tutorial-summary-stats", summaryStats);
  register("tutorial-summary-continue", summaryContinue);
  register("tutorial-summary-replay", summaryReplay);
  register("pause-button", pauseButton);
  register("options-overlay", optionsOverlay);
  register("options-overlay-close", optionsClose);
  register("options-resume-button", optionsResume);
  register("options-sound-toggle", soundToggle);
  register("options-diagnostics-toggle", diagnosticsToggle);
  register("options-checkered-bg-toggle", checkeredBackgroundToggle);
  register("options-reduced-motion-toggle", reducedMotionToggle);
  register("options-readable-font-toggle", readableFontToggle);
  register("options-dyslexia-font-toggle", dyslexiaFontToggle);
  register("options-colorblind-toggle", colorblindPaletteToggle);
  register("options-sound-volume", soundVolumeSlider);
  register("options-sound-volume-value", soundVolumeValue);
  register("options-telemetry-toggle-wrapper", telemetryToggleWrapper);
  register("options-telemetry-toggle", telemetryToggle);
  register("options-font-scale", fontScaleSelect);
  register("options-analytics-export", analyticsExportButton);
  register("options-castle-bonus", optionsCastleBonus);
  register("options-castle-benefits", optionsCastleBenefits);
  register("wave-scorecard", waveScorecard);
  register("wave-scorecard-stats", waveScorecardStats);
  register("wave-scorecard-continue", waveScorecardContinue);
  register("debug-analytics-viewer", analyticsViewerContainer);
  register("debug-analytics-viewer-filter", analyticsFilterSelect);
  register("debug-analytics-viewer-body", analyticsViewerBody);

  global.document = documentStub;
  global.window = {
    setTimeout: () => 0,
    clearTimeout: () => {}
  };

  let scorecardContinues = 0;
  const reducedMotionToggleEvents = [];
  const analyticsExportEvents = [];
  const checkeredBackgroundToggleEvents = [];
  const readableFontToggleEvents = [];
  const dyslexiaFontToggleEvents = [];
  const colorblindToggleEvents = [];
  const telemetryToggleEvents = [];
  const soundVolumeEvents = [];
  const fontScaleChangeEvents = [];
  const priorityChangeEvents = [];
  const turretHoverEvents = [];
  const turretPresetSaveEvents = [];
  const turretPresetApplyEvents = [];
  const turretPresetClearEvents = [];

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
      optionsOverlay: {
        container: "options-overlay",
        closeButton: "options-overlay-close",
        resumeButton: "options-resume-button",
        soundToggle: "options-sound-toggle",
        soundVolumeSlider: "options-sound-volume",
        soundVolumeValue: "options-sound-volume-value",
        diagnosticsToggle: "options-diagnostics-toggle",
        reducedMotionToggle: "options-reduced-motion-toggle",
        checkeredBackgroundToggle: "options-checkered-bg-toggle",
        readableFontToggle: "options-readable-font-toggle",
        dyslexiaFontToggle: "options-dyslexia-font-toggle",
        colorblindPaletteToggle: "options-colorblind-toggle",
        telemetryToggle: "options-telemetry-toggle",
        telemetryToggleWrapper: "options-telemetry-toggle-wrapper",
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
        filterSelect: "debug-analytics-viewer-filter"
      }
    },
    {
      onCastleUpgrade: () => {},
      onCastleRepair: () => {},
      onPlaceTurret: () => {},
      onUpgradeTurret: () => {},
      onTurretPriorityChange: (slotId, priority) => priorityChangeEvents.push({ slotId, priority }),
      onTurretHover: (slotId, context) =>
        turretHoverEvents.push({ slotId, context: context ? { ...context } : context }),
      onTurretPresetSave: (presetId) => turretPresetSaveEvents.push(presetId),
      onTurretPresetApply: (presetId) => turretPresetApplyEvents.push(presetId),
      onTurretPresetClear: (presetId) => turretPresetClearEvents.push(presetId),
      onPauseRequested: () => {},
      onResumeRequested: () => {},
      onSoundToggle: () => {},
      onSoundVolumeChange: (value) => soundVolumeEvents.push(value),
      onDiagnosticsToggle: () => {},
      onWaveScorecardContinue: () => scorecardContinues++,
      onReducedMotionToggle: (enabled) => reducedMotionToggleEvents.push(enabled),
      onCheckeredBackgroundToggle: (enabled) => checkeredBackgroundToggleEvents.push(enabled),
      onReadableFontToggle: (enabled) => readableFontToggleEvents.push(enabled),
      onDyslexiaFontToggle: (enabled) => dyslexiaFontToggleEvents.push(enabled),
      onColorblindPaletteToggle: (enabled) => colorblindToggleEvents.push(enabled),
      onTelemetryToggle: (enabled) => telemetryToggleEvents.push(enabled),
      onAnalyticsExport: () => analyticsExportEvents.push(true),
      onHudFontScaleChange: (scale) => fontScaleChangeEvents.push(scale)
    }
  );

  const castleStatus =
    findByClass(upgradePanel, "castle-status") ?? new FakeElement("span", "castle-status");

  const cleanup = () => {
    if (originalDocument !== undefined) {
      global.document = originalDocument;
    } else {
      delete global.document;
    }
    if (originalWindow !== undefined) {
      global.window = originalWindow;
    } else {
      delete global.window;
    }
    if (originalHTMLElement !== undefined) {
      global.HTMLElement = originalHTMLElement;
    } else {
      delete global.HTMLElement;
    }
    if (originalHTMLDivElement !== undefined) {
      global.HTMLDivElement = originalHTMLDivElement;
    } else {
      delete global.HTMLDivElement;
    }
    if (originalHTMLButtonElement !== undefined) {
      global.HTMLButtonElement = originalHTMLButtonElement;
    } else {
      delete global.HTMLButtonElement;
    }
    if (originalHTMLInputElement !== undefined) {
      global.HTMLInputElement = originalHTMLInputElement;
    } else {
      delete global.HTMLInputElement;
    }
    if (originalHTMLTextAreaElement !== undefined) {
      global.HTMLTextAreaElement = originalHTMLTextAreaElement;
    } else {
      delete global.HTMLTextAreaElement;
    }
    if (originalHTMLSelectElement !== undefined) {
      global.HTMLSelectElement = originalHTMLSelectElement;
    } else {
      delete global.HTMLSelectElement;
    }
    if (originalHTMLUListElement !== undefined) {
      global.HTMLUListElement = originalHTMLUListElement;
    } else {
      delete global.HTMLUListElement;
    }
    if (originalHTMLTableSectionElement !== undefined) {
      global.HTMLTableSectionElement = originalHTMLTableSectionElement;
    } else {
      delete global.HTMLTableSectionElement;
    }
  };

  return {
    hud,
    cleanup,
    elements: {
      activeWord,
      wavePreview,
      wavePreviewHint,
      comboLabel,
      goldDelta,
      logList,
      tutorialBanner,
      summaryContainer,
      summaryContinue,
      summaryReplay,
      optionsOverlay,
      optionsResume,
      analyticsExportButton,
      soundToggle,
      soundVolumeSlider,
      soundVolumeValue,
      diagnosticsToggle,
      reducedMotionToggle,
      checkeredBackgroundToggle,
      readableFontToggle,
      dyslexiaFontToggle,
      colorblindPaletteToggle,
      telemetryToggle,
      telemetryToggleWrapper,
      fontScaleSelect,
      optionsCastleBonus,
      optionsCastleBenefits,
      castleStatus,
      waveScorecard,
      waveScorecardStats,
      waveScorecardContinue,
      analyticsViewerContainer,
      analyticsViewerBody,
      analyticsFilterSelect,
      getScorecardContinueCount: () => scorecardContinues,
      getReducedMotionToggleEvents: () => [...reducedMotionToggleEvents],
      upgradePanel,
      getCheckeredBackgroundToggleEvents: () => [...checkeredBackgroundToggleEvents],
      getReadableFontToggleEvents: () => [...readableFontToggleEvents],
      getDyslexiaFontToggleEvents: () => [...dyslexiaFontToggleEvents],
      getColorblindToggleEvents: () => [...colorblindToggleEvents],
      getSoundVolumeEvents: () => [...soundVolumeEvents],
      getTelemetryToggleEvents: () => [...telemetryToggleEvents],
      getFontScaleEvents: () => [...fontScaleChangeEvents],
      getPriorityEvents: () => [...priorityChangeEvents],
      getTurretHoverEvents: () => [...turretHoverEvents],
      getTurretPresetSaveEvents: () => [...turretPresetSaveEvents],
      getTurretPresetApplyEvents: () => [...turretPresetApplyEvents],
      getTurretPresetClearEvents: () => [...turretPresetClearEvents]
    },
    getAnalyticsExportEvents: () => [...analyticsExportEvents]
  };
};

const buildInitialState = () => {
  const turretStates = defaultConfig.turretSlots.map((slot, index) => ({
    id: slot.id,
    lane: slot.lane,
    position: slot.position,
    unlocked: index < defaultConfig.castleLevels[0].unlockSlots,
    targetingPriority: "first",
    turret: undefined
  }));

  return {
    time: 0,
    status: "running",
    mode: "campaign",
    castle: {
      level: 1,
      maxHealth: 100,
      health: 100,
      armor: 0,
      regenPerSecond: 1,
      nextUpgradeCost: 180,
      repairCooldownRemaining: 0
    },
    resources: { gold: 200, score: 0 },
    turrets: turretStates,
    enemies: [],
    projectiles: [],
    wave: {
      index: 0,
      total: defaultConfig.waves.length,
      inCountdown: false,
      countdownRemaining: 0,
      timeInWave: 0
    },
    typing: {
      activeEnemyId: null,
      buffer: "",
      combo: 0,
      errors: 0
    },
    analytics: {
      activeWaveIndex: 0,
      waveStartTime: 0,
      lastSnapshotTime: 0,
      mode: "campaign",
      totalDamageDealt: 0,
      totalTurretDamage: 0,
      totalTypingDamage: 0,
      totalShieldBreaks: 0,
      totalCastleRepairs: 0,
      totalRepairHealth: 0,
      totalRepairGold: 0,
      enemiesDefeated: 0,
      breaches: 0,
      sessionBreaches: 0,
      startGold: 200,
      startTotalInputs: 0,
      startCorrectInputs: 0,
      waveSummaries: [],
      waveHistory: [],
      waveMaxCombo: 0,
      waveShieldBreaks: 0,
      waveRepairs: 0,
      waveRepairHealth: 0,
      waveRepairGold: 0,
      waveComboBaseline: 0,
      sessionBestCombo: 0,
      waveTurretDamage: 0,
      waveTurretDamageBySlot: {},
      waveTypingDamage: 0,
      tutorial: {
        events: [],
        assistsShown: 0,
        completedRuns: 0,
        replayedRuns: 0,
        skippedRuns: 0
      }
    }
  };
};

test("HudView highlights combos and gold deltas", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { wavePreview, comboLabel, goldDelta, logList, tutorialBanner } = elements;

  const baseState = buildInitialState();
  hud.update(baseState, []);
  assert.equal(wavePreview.children.length, 1);
  assert.equal(wavePreview.children[0].textContent, "All clear.");
  assert.equal(comboLabel.dataset.active, "false");

  const nextState = structuredClone(baseState);
  nextState.resources.gold = 260;
  nextState.typing.combo = 4;
  const upcoming = [
    {
      waveIndex: 0,
      lane: 1,
      tierId: "grunt",
      timeUntil: 1.2,
      scheduledTime: 1.2,
      isNextWave: false
    },
    { waveIndex: 1, lane: 2, tierId: "witch", timeUntil: 12, scheduledTime: 2, isNextWave: true }
  ];
  hud.update(nextState, upcoming);

  assert.equal(comboLabel.dataset.active, "true");
  assert.ok(comboLabel.textContent?.includes("x4"));
  assert.equal(goldDelta.dataset.visible, "true");
  assert.equal(goldDelta.textContent, "+60g");

  hud.appendLog("Test entry");
  assert.equal(logList.children.length, 1);
  assert.equal(logList.children[0].textContent, "Test entry");
  assert.equal(wavePreview.children.length, 3);
  const summary = wavePreview.children[0];
  assert.equal(summary.className, "wave-preview-summary");
  assert.ok(summary.children[0].textContent.includes("B"));
  const firstRow = wavePreview.children[1];
  assert.equal(firstRow.children[0].textContent, "B");
  const secondRow = wavePreview.children[2];
  assert.equal(secondRow.dataset.phase, "next");

  hud.setTutorialMessage("Practice typing", true);
  assert.equal(tutorialBanner.dataset.visible, "true");
  assert.equal(tutorialBanner.dataset.highlight, "true");
  assert.equal(tutorialBanner.textContent, "Practice typing");
  hud.setTutorialMessage(null);
  assert.equal(tutorialBanner.dataset.visible, "false");

  cleanup();
});

test("HudView surfaces shielded status for active enemy", () => {
  const { hud, cleanup, elements } = initializeHud();
  const state = buildInitialState();
  const enemy = {
    id: "enemy-1",
    tierId: "witch",
    word: "arcana",
    typed: 0,
    maxHealth: 52,
    health: 52,
    shield: { current: 24, max: 24 },
    speed: 0.04,
    baseSpeed: 0.04,
    distance: 0.35,
    lane: 1,
    damage: 12,
    reward: 18,
    status: "alive",
    effects: [],
    spawnedAt: 0,
    waveIndex: 0
  };
  state.enemies.push(enemy);
  state.typing.activeEnemyId = enemy.id;
  state.typing.buffer = "";

  hud.update(state, []);

  const activeWord = elements.activeWord;
  assert.equal(activeWord.dataset.shielded, "true");
  assert.ok(activeWord.innerHTML.includes("Shielded"));
  assert.ok(activeWord.innerHTML.includes("word-text"));

  enemy.shield.current = 0;
  hud.update(state, []);
  assert.ok(!("shielded" in activeWord.dataset));
  assert.ok(!activeWord.innerHTML.includes("Shielded"));

  cleanup();
});

test("HudView wave preview tags shielded entries", () => {
  const { hud, cleanup, elements } = initializeHud();
  const state = buildInitialState();
  const upcoming = [
    {
      waveIndex: 0,
      lane: 0,
      tierId: "witch",
      timeUntil: 2.5,
      scheduledTime: 2.5,
      isNextWave: false,
      shield: 50
    }
  ];

  hud.update(state, upcoming);

  assert.equal(elements.wavePreview.children.length, 2);
  const row = elements.wavePreview.children[1];
  const iconCell = row.children.find((child) => child.className === "preview-icon");
  assert.ok(iconCell, "expected enemy icon element");
  const enemyCell = row.children.find((child) => child.className === "preview-enemy");
  assert.ok(enemyCell, "expected enemy cell element");
  const badge = enemyCell.children.find((child) => child.className?.includes("preview-badge"));
  assert.ok(badge, "expected shield badge in preview");
  assert.ok(badge.textContent.includes("Shield"));
  assert.equal(row.dataset.shielded, "true");
  assert.equal(elements.wavePreview.dataset.shieldCurrent, "true");
  assert.ok(
    elements.castleStatus.textContent.includes("Shielded"),
    "expected castle status to announce shields"
  );

  cleanup();
});

test("HudView announces shield forecast for upcoming wave", () => {
  const { hud, cleanup, elements } = initializeHud();
  const state = buildInitialState();
  const upcoming = [
    {
      waveIndex: 1,
      lane: 2,
      tierId: "grunt",
      timeUntil: 9,
      scheduledTime: 9,
      isNextWave: true,
      shield: 75
    }
  ];

  hud.update(state, upcoming);

  assert.equal(elements.wavePreview.dataset.shieldCurrent ?? "false", "false");
  assert.equal(elements.wavePreview.dataset.shieldNext, "true");
  assert.ok(
    elements.castleStatus.textContent.includes("Next wave"),
    "expected castle status to warn about next wave shields"
  );

  cleanup();
});

test("HudView displays next castle upgrade benefits", () => {
  const { hud, cleanup, elements } = initializeHud();
  const baseState = buildInitialState();
  hud.update(baseState, []);

  const castleSection = elements.upgradePanel.children.find(
    (child) => child.className === "castle-upgrade"
  );
  assert.ok(castleSection, "expected castle upgrade container");
  const castleButtons = castleSection.children.filter((child) => child.tag === "button");
  const castleButton = castleButtons.find((child) => child.className !== "castle-repair");
  const repairButton = castleButtons.find((child) => child.className === "castle-repair");
  assert.ok(castleButton, "expected castle upgrade button");
  assert.ok(repairButton, "expected castle repair button");
  const benefitsList = castleSection.children.find(
    (child) => child.className === "castle-benefits"
  );
  assert.ok(benefitsList, "expected castle benefits list");
  assert.equal(benefitsList.dataset.visible, "true");
  assert.equal(benefitsList.hidden, false);
  const benefitTexts = benefitsList.children.map((child) => child.textContent ?? "");
  assert.ok(
    benefitTexts.some((text) => text.includes("HP")),
    "expected HP benefit"
  );
  const optionsBenefits = elements.optionsCastleBenefits;
  assert.ok(optionsBenefits, "expected options overlay benefits list");
  assert.equal(optionsBenefits.children.length, benefitTexts.length);
  for (const line of benefitTexts) {
    assert.ok(
      optionsBenefits.children.some((child) => (child.textContent ?? "").includes(line)),
      `expected options overlay to include benefit "${line}"`
    );
  }
  assert.equal(castleButton.getAttribute("aria-expanded"), "true");
  assert.equal(castleButton.getAttribute("aria-describedby"), benefitsList.id);
  assert.ok(
    (castleButton.getAttribute("aria-label") ?? "").includes("Next benefits"),
    "expected castle button aria-label to reference next benefits"
  );
  assert.equal(repairButton.disabled, true);
  assert.equal(repairButton.getAttribute("aria-disabled"), "true");
  assert.match(repairButton.title ?? "", /full health/i);

  const maxState = structuredClone(baseState);
  const maxConfig = defaultConfig.castleLevels[defaultConfig.castleLevels.length - 1];
  maxState.castle.level = maxConfig.level;
  maxState.castle.maxHealth = maxConfig.maxHealth;
  maxState.castle.health = maxConfig.maxHealth;
  maxState.castle.regenPerSecond = maxConfig.regenPerSecond;
  maxState.castle.armor = maxConfig.armor;
  maxState.castle.nextUpgradeCost = maxConfig.upgradeCost;

  hud.update(maxState, []);
  assert.equal(benefitsList.dataset.visible, "false");
  assert.equal(benefitsList.hidden, true);
  assert.equal(castleButton.getAttribute("aria-expanded"), "false");
  assert.equal(castleButton.getAttribute("aria-describedby"), null);
  assert.ok(
    (castleButton.getAttribute("aria-label") ?? "").includes("maximum"),
    "expected max level aria-label to announce castle is at maximum level"
  );
  assert.equal(repairButton.disabled, true);
  assert.ok(
    (optionsBenefits.children[0]?.textContent ?? "").toLowerCase().includes("maximum level"),
    "options overlay should mention maximum level when no upgrades remain"
  );

  cleanup();
});

test("HudView updates castle repair button state", () => {
  const { hud, cleanup, elements } = initializeHud();
  const baseState = buildInitialState();

  const findRepairButton = () => {
    const castleSection = elements.upgradePanel.children.find(
      (child) => child.className === "castle-upgrade"
    );
    if (!castleSection) return null;
    return castleSection.children.find((child) => child.className === "castle-repair") ?? null;
  };

  hud.update(baseState, []);
  const repairInitial = findRepairButton();
  assert.ok(repairInitial, "expected repair button");
  assert.equal(repairInitial.disabled, true);
  assert.equal(repairInitial.getAttribute("aria-disabled"), "true");
  assert.match(repairInitial.title ?? "", /full health/i);
  assert.equal(repairInitial.dataset.cooldown, undefined);

  const damagedState = structuredClone(baseState);
  damagedState.castle.health = 40;
  hud.update(damagedState, []);
  const repairAfterDamage = findRepairButton();
  assert.ok(repairAfterDamage, "expected repair button after damage");
  assert.equal(repairAfterDamage.disabled, false);
  assert.equal(repairAfterDamage.getAttribute("aria-disabled"), "false");
  assert.match(repairAfterDamage.getAttribute("aria-label") ?? "", /restoring up to 60/i);
  assert.equal(repairAfterDamage.dataset.cooldown, undefined);

  const cooldownState = structuredClone(damagedState);
  cooldownState.castle.repairCooldownRemaining = 5;
  hud.update(cooldownState, []);
  const repairDuringCooldown = findRepairButton();
  assert.ok(repairDuringCooldown, "expected repair button during cooldown");
  assert.equal(repairDuringCooldown.disabled, true);
  assert.equal(repairDuringCooldown.getAttribute("aria-disabled"), "true");
  assert.equal(repairDuringCooldown.dataset.cooldown, "5.0");
  assert.match(repairDuringCooldown.title ?? "", /Cooldown 5\.0s/i);

  const lowGoldState = structuredClone(damagedState);
  lowGoldState.resources.gold = 50;
  hud.update(lowGoldState, []);
  const repairLowGold = findRepairButton();
  assert.ok(repairLowGold, "expected repair button with low gold");
  assert.equal(repairLowGold.disabled, true);
  assert.match(repairLowGold.title ?? "", /Not enough gold/i);
  assert.match(repairLowGold.getAttribute("aria-label") ?? "", /Not enough gold/i);

  cleanup();
});

test("HudView turret priority controls reflect state and emit changes", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { upgradePanel, getPriorityEvents } = elements;

  const baseState = buildInitialState();
  baseState.turrets[0].turret = {
    slotId: "slot-1",
    typeId: "arrow",
    level: 1,
    cooldown: 0
  };
  baseState.turrets[0].targetingPriority = "weakest";
  baseState.turrets[1].targetingPriority = "strongest";

  hud.update(baseState, []);

  const findByClass = (node, targetClass) => {
    if (!node || typeof node !== "object") return null;
    if (node.className === targetClass) return node;
    if (Array.isArray(node.children)) {
      for (const child of node.children) {
        const match = findByClass(child, targetClass);
        if (match) return match;
      }
    }
    return null;
  };

  const slotElements = upgradePanel.children.filter(
    (child) => child && child.className === "turret-slot"
  );
  const [firstSlot, secondSlot, thirdSlot] = slotElements;

  const firstPrioritySelect = findByClass(firstSlot, "slot-priority-select");
  const firstPriorityContainer = findByClass(firstSlot, "slot-priority");
  const secondPrioritySelect = findByClass(secondSlot, "slot-priority-select");
  const thirdPriorityContainer = findByClass(thirdSlot, "slot-priority");
  const thirdPrioritySelect = findByClass(thirdSlot, "slot-priority-select");

  assert.ok(firstPrioritySelect, "expected priority select for first slot");
  assert.equal(firstPrioritySelect.value, "weakest");
  const firstStatus = findByClass(firstSlot, "slot-status");
  assert.ok(firstStatus?.textContent.includes("Weakest"));

  assert.ok(secondPrioritySelect, "expected priority select for second slot");
  assert.equal(secondPrioritySelect.value, "strongest");

  assert.ok(thirdPriorityContainer?.dataset.disabled === "true");
  assert.equal(thirdPrioritySelect?.disabled, true);

  firstPrioritySelect.value = "strongest";
  firstPrioritySelect.onchange?.();

  assert.deepEqual(getPriorityEvents(), [{ slotId: "slot-1", priority: "strongest" }]);

  cleanup();
});

test("HudView turret presets render summaries and emit callbacks", () => {
  const { hud, cleanup, elements } = initializeHud();
  const {
    upgradePanel,
    getTurretPresetSaveEvents,
    getTurretPresetApplyEvents,
    getTurretPresetClearEvents
  } = elements;

  const findByClass = (node, targetClass) => {
    if (!node || typeof node !== "object") return null;
    if (node.className === targetClass) {
      return node;
    }
    if (Array.isArray(node.children)) {
      for (const child of node.children) {
        const match = findByClass(child, targetClass);
        if (match) return match;
      }
    }
    return null;
  };

  const presets = [
    {
      id: "preset-a",
      label: "Preset A",
      hasPreset: true,
      active: true,
      applyCost: 500,
      applyDisabled: false,
      applyMessage: "Apply Preset A (-500g)",
      savedAtLabel: "Saved 08:30",
      statusLabel: "Cost 500g",
      slots: [
        { slotId: "slot-1", typeId: "arcane", level: 2, priority: "weakest" },
        { slotId: "slot-2", typeId: "flame", level: 1 }
      ]
    },
    {
      id: "preset-b",
      label: "Preset B",
      hasPreset: false,
      active: false,
      applyCost: null,
      applyDisabled: true,
      applyMessage: "Save Preset B to enable quick swaps.",
      savedAtLabel: "Not saved",
      statusLabel: null,
      slots: []
    }
  ];

  try {
    hud.updateTurretPresets(presets);

    const presetContainer = findByClass(upgradePanel, "turret-presets");
    assert.ok(presetContainer, "expected presets container");
    const presetList = findByClass(presetContainer, "turret-presets-list");
    assert.ok(presetList, "expected presets list container");
    const presetItems = presetList.children.filter((child) => child?.className === "turret-preset");
    const presetById = Object.fromEntries(
      presetItems
        .filter((item) => item?.dataset?.presetId)
        .map((item) => [item.dataset.presetId, item])
    );

    const firstPreset = presetById["preset-a"];
    const secondPreset = presetById["preset-b"];
    assert.ok(firstPreset, "expected Preset A entry");
    assert.ok(secondPreset, "expected Preset B entry");
    const firstSummary = findByClass(firstPreset, "turret-preset-summary");
    const firstStatus = findByClass(firstPreset, "turret-preset-status");
    const firstApply = findByClass(firstPreset, "turret-preset-apply");
    const firstClear = findByClass(firstPreset, "turret-preset-clear");
    assert.ok(firstSummary);
    assert.equal(firstSummary.textContent, "S1 Arcane Focus Lv2 (Weakest) • S2 Flame Thrower Lv1");
    assert.equal(firstStatus?.textContent, "Cost 500g");
    assert.equal(firstPreset.dataset.active, "true");
    assert.equal(firstPreset.dataset.saved, "true");
    assert.equal(firstApply?.disabled, false);
    firstApply?.onclick?.({ preventDefault() {} });
    assert.deepEqual(getTurretPresetApplyEvents(), ["preset-a"]);
    firstClear?.onclick?.({ preventDefault() {} });
    assert.deepEqual(getTurretPresetClearEvents(), ["preset-a"]);

    const secondSummary = findByClass(secondPreset, "turret-preset-summary");
    const secondApply = findByClass(secondPreset, "turret-preset-apply");
    const secondSave = findByClass(secondPreset, "turret-preset-save");
    assert.equal(secondSummary?.dataset.empty, "true");
    assert.equal(secondApply?.disabled, true);
    secondSave?.onclick?.({ preventDefault() {} });
    assert.deepEqual(getTurretPresetSaveEvents(), ["preset-b"]);
  } finally {
    cleanup();
  }
});

test("turret hover emits range preview context", () => {
  const { hud, cleanup, elements } = initializeHud();
  try {
    const state = buildInitialState();
    state.turrets[0].unlocked = true;
    state.turrets[0].turret = {
      slotId: "slot-1",
      typeId: "arrow",
      level: 2,
      cooldown: 0
    };

    hud.update(state, []);

    const slotElements = elements.upgradePanel.children.filter(
      (child) => child && child.className === "turret-slot"
    );
    const firstSlot = slotElements[0];
    assert.ok(firstSlot, "expected first slot element");

    firstSlot.onmouseenter?.();
    const hoverEvents = elements.getTurretHoverEvents();
    assert.ok(hoverEvents.length > 0, "hover event should be recorded");
    const { slotId, context } = hoverEvents[hoverEvents.length - 1];
    assert.equal(slotId, "slot-1");
    assert.equal(context?.typeId, "arrow");
    assert.equal(context?.level, 2);

    firstSlot.onmouseleave?.();
    const clearedEvents = elements.getTurretHoverEvents();
    const lastEvent = clearedEvents[clearedEvents.length - 1];
    assert.equal(lastEvent.slotId, null);
  } finally {
    cleanup();
  }
});

test("HudView wave preview highlight toggles accessibility cues", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { wavePreview, wavePreviewHint } = elements;

  assert.equal(wavePreview.dataset.tutorialHighlight, undefined);
  assert.equal(wavePreview.getAttribute("aria-live"), null);
  assert.equal(wavePreviewHint.dataset.visible, "false");
  assert.equal(wavePreviewHint.getAttribute("aria-hidden"), "true");
  assert.equal(wavePreviewHint.textContent, "");

  hud.setWavePreviewHighlight(true, "Enemies queue here.");
  assert.equal(wavePreview.dataset.tutorialHighlight, "true");
  assert.equal(wavePreview.getAttribute("aria-live"), "polite");
  assert.equal(wavePreviewHint.dataset.visible, "true");
  assert.equal(wavePreviewHint.getAttribute("aria-hidden"), "false");
  assert.equal(wavePreviewHint.textContent, "Enemies queue here.");

  hud.setWavePreviewHighlight(false);
  assert.equal(wavePreview.dataset.tutorialHighlight, undefined);
  assert.equal(wavePreview.getAttribute("aria-live"), null);
  assert.equal(wavePreviewHint.dataset.visible, "false");
  assert.equal(wavePreviewHint.getAttribute("aria-hidden"), "true");
  assert.equal(wavePreviewHint.textContent, "");

  cleanup();
});

test("HudView updates castle bonus hint in options overlay", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { optionsCastleBonus, optionsCastleBenefits } = elements;
  const state = buildInitialState();
  state.castle.level = 2;
  state.castle.goldBonusPercent = 0.05;
  hud.update(state, []);

  const hint = optionsCastleBonus.textContent ?? "";
  assert.match(hint, /Next upgrade unlocks/i, "options overlay should describe upcoming upgrade");

  const benefitCount = optionsCastleBenefits.children.length;
  assert.ok(benefitCount > 0, "upgrade benefits list should be populated");
  assert.match(
    hint,
    new RegExp(`\\b${benefitCount}\\b`),
    "hint should mention the number of upcoming bonuses"
  );
  assert.match(hint, /bonus/i, "hint should label the listed bonuses");

  const benefitLines = optionsCastleBenefits.children.map(
    (child) => child?.textContent?.trim() ?? ""
  );
  assert.ok(
    benefitLines.some((line) => line.length > 0),
    "benefit list should render readable entries"
  );

  state.castle.level = defaultConfig.castleLevels.at(-1)?.level ?? 4;
  const maxConfig = defaultConfig.castleLevels.find((c) => c.level === state.castle.level);
  state.castle.goldBonusPercent = maxConfig?.goldBonusPercent ?? state.castle.goldBonusPercent;
  hud.update(state, []);

  const maxLevelMessage = optionsCastleBenefits.children[0]?.textContent ?? "";
  assert.match(
    maxLevelMessage,
    /Castle is at maximum level/i,
    "max-level messaging should surface in the benefits list"
  );

  cleanup();
});

test("HudView tutorial summary overlay toggles and handlers respond", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { summaryContainer, summaryContinue, summaryReplay } = elements;
  let continued = 0;
  let replayed = 0;

  hud.showTutorialSummary(
    { accuracy: 0.93, bestCombo: 8, breaches: 2, gold: 187 },
    {
      onContinue: () => continued++,
      onReplay: () => replayed++
    }
  );

  assert.equal(summaryContainer.dataset.visible, "true");
  summaryContinue.onclick?.();
  summaryReplay.onclick?.();
  assert.equal(continued, 1);
  assert.equal(replayed, 1);

  hud.hideTutorialSummary();
  assert.equal(summaryContainer.dataset.visible, "false");
  assert.equal(summaryContinue.onclick, null);
  assert.equal(summaryReplay.onclick, null);

  cleanup();
});

test("HudView options overlay syncs controls and visibility", () => {
  const { hud, cleanup, elements } = initializeHud();
  const {
    optionsOverlay,
    soundToggle,
    soundVolumeSlider,
    soundVolumeValue,
    diagnosticsToggle,
    reducedMotionToggle,
    checkeredBackgroundToggle,
    readableFontToggle,
    dyslexiaFontToggle,
    colorblindPaletteToggle,
    telemetryToggle,
    telemetryToggleWrapper,
    fontScaleSelect,
    getReducedMotionToggleEvents,
    getCheckeredBackgroundToggleEvents,
    getReadableFontToggleEvents,
    getDyslexiaFontToggleEvents,
    getColorblindToggleEvents,
    getSoundVolumeEvents,
    getTelemetryToggleEvents,
    getFontScaleEvents
  } = elements;

  hud.syncOptionsOverlayState({
    soundEnabled: false,
    soundVolume: 0.8,
    diagnosticsVisible: false,
    reducedMotionEnabled: true,
    checkeredBackgroundEnabled: false,
    readableFontEnabled: false,
    dyslexiaFontEnabled: false,
    colorblindPaletteEnabled: false,
    hudFontScale: 1,
    telemetry: { available: false, checked: false, disabled: true }
  });
  assert.equal(soundToggle.checked, false);
  assert.equal(soundVolumeSlider.value, "0.8");
  assert.equal(soundVolumeValue.textContent, "80%");
  assert.equal(soundVolumeSlider.disabled, true);
  assert.equal(soundVolumeSlider.getAttribute("aria-disabled"), "true");
  assert.equal(diagnosticsToggle.checked, false);
  assert.equal(reducedMotionToggle.checked, true);
  assert.equal(checkeredBackgroundToggle.checked, false);
  assert.equal(readableFontToggle.checked, false);
  assert.equal(dyslexiaFontToggle.checked, false);
  assert.equal(colorblindPaletteToggle.checked, false);
  assert.equal(telemetryToggle.checked, false);
  assert.equal(telemetryToggle.disabled, true);
  assert.equal(telemetryToggleWrapper.style.display, "none");
  assert.equal(fontScaleSelect.value, "1");
  assert.equal(hud.isOptionsOverlayVisible(), false);

  hud.syncOptionsOverlayState({
    soundEnabled: true,
    soundVolume: 0.8,
    diagnosticsVisible: false,
    reducedMotionEnabled: true,
    checkeredBackgroundEnabled: false,
    readableFontEnabled: false,
    dyslexiaFontEnabled: false,
    colorblindPaletteEnabled: false,
    hudFontScale: 1,
    telemetry: { available: false, checked: false, disabled: true }
  });
  assert.equal(soundToggle.checked, true);
  assert.equal(soundVolumeSlider.disabled, false);
  assert.equal(soundVolumeSlider.getAttribute("aria-disabled"), "false");

  hud.syncOptionsOverlayState({
    soundEnabled: true,
    soundVolume: 0.55,
    diagnosticsVisible: false,
    reducedMotionEnabled: true,
    checkeredBackgroundEnabled: false,
    readableFontEnabled: false,
    dyslexiaFontEnabled: true,
    colorblindPaletteEnabled: true,
    hudFontScale: 1.15,
    telemetry: { available: true, checked: true, disabled: false }
  });
  assert.equal(soundVolumeSlider.value, "0.55");
  assert.equal(soundVolumeValue.textContent, "55%");
  assert.equal(colorblindPaletteToggle.checked, true);
  assert.equal(telemetryToggleWrapper.style.display, "");
  assert.equal(telemetryToggle.disabled, false);
  assert.equal(telemetryToggle.checked, true);

  hud.showOptionsOverlay();
  assert.equal(optionsOverlay.dataset.visible, "true");
  assert.equal(hud.isOptionsOverlayVisible(), true);

  reducedMotionToggle.checked = false;
  reducedMotionToggle.onchange?.();
  assert.deepEqual(getReducedMotionToggleEvents(), [false]);

  checkeredBackgroundToggle.checked = true;
  checkeredBackgroundToggle.onchange?.();
  assert.deepEqual(getCheckeredBackgroundToggleEvents(), [true]);

  readableFontToggle.checked = true;
  readableFontToggle.onchange?.();
  assert.deepEqual(getReadableFontToggleEvents(), [true]);

  assert.equal(dyslexiaFontToggle.checked, true);
  dyslexiaFontToggle.checked = false;
  dyslexiaFontToggle.onchange?.();
  assert.deepEqual(getDyslexiaFontToggleEvents(), [false]);

  soundVolumeSlider.value = "0.6";
  soundVolumeSlider.oninput?.();
  assert.deepEqual(getSoundVolumeEvents(), [0.6]);
  assert.equal(soundVolumeValue.textContent, "60%");

  colorblindPaletteToggle.checked = true;
  colorblindPaletteToggle.onchange?.();
  assert.deepEqual(getColorblindToggleEvents(), [true]);

  telemetryToggle.checked = false;
  telemetryToggle.onchange?.();
  assert.deepEqual(getTelemetryToggleEvents(), [false]);

  fontScaleSelect.value = "1.2";
  fontScaleSelect.onchange?.();
  assert.deepEqual(getFontScaleEvents(), [1.2]);

  hud.hideOptionsOverlay();
  assert.equal(optionsOverlay.dataset.visible, "false");
  assert.equal(hud.isOptionsOverlayVisible(), false);

  cleanup();
});

test("HudView toggles analytics export availability", () => {
  const { hud, cleanup, elements, getAnalyticsExportEvents } = initializeHud();
  const { analyticsExportButton } = elements;

  hud.setAnalyticsExportEnabled(false);
  assert.equal(analyticsExportButton.style.display, "none");
  assert.equal(analyticsExportButton.disabled, true);
  assert.equal(analyticsExportButton.getAttribute("aria-hidden"), "true");
  assert.equal(analyticsExportButton.tabIndex, -1);

  hud.setAnalyticsExportEnabled(true);
  assert.equal(analyticsExportButton.style.display, "");
  assert.equal(analyticsExportButton.disabled, false);
  assert.equal(analyticsExportButton.getAttribute("aria-hidden"), "false");
  assert.equal(analyticsExportButton.tabIndex, 0);

  analyticsExportButton.onclick?.({ preventDefault() {} });
  assert.equal(getAnalyticsExportEvents().length, 1);

  cleanup();
});

test("HudView analytics viewer toggles visibility", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { analyticsViewerContainer } = elements;

  assert.equal(hud.hasAnalyticsViewer(), true);
  assert.equal(hud.isAnalyticsViewerVisible(), false);
  assert.equal(analyticsViewerContainer.dataset.visible, "false");

  hud.toggleAnalyticsViewer();
  assert.equal(hud.isAnalyticsViewerVisible(), true);
  assert.equal(analyticsViewerContainer.dataset.visible, "true");

  hud.toggleAnalyticsViewer();
  assert.equal(hud.isAnalyticsViewerVisible(), false);
  assert.equal(analyticsViewerContainer.dataset.visible, "false");

  cleanup();
});

test("HudView analytics viewer renders wave summaries with filters and summary row", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { analyticsViewerBody, analyticsViewerContainer, analyticsFilterSelect } = elements;
  const state = buildInitialState();

  state.analytics.waveSummaries = Array.from({ length: 6 }, (_, index) => ({
    index,
    mode: index % 2 === 0 ? "practice" : "campaign",
    duration: 8 + index,
    accuracy: 0.84 + index * 0.01,
    enemiesDefeated: 6 + index,
    breaches: index % 2,
    perfectWords: 2 + index,
    averageReaction: 1 + index * 0.05,
    dps: 16 + index,
    goldEarned: 40 + index * 3,
    bonusGold: index % 2 === 0 ? 10 : 0,
    castleBonusGold: index % 2 === 0 ? 6 : 0,
    maxCombo: 3 + index,
    sessionBestCombo: 12,
    turretDamage: 110 + index * 24,
    typingDamage: 55 + index * 12,
    turretDps: 11 + index,
    typingDps: 6 + index * 0.6,
    shieldBreaks: index % 3,
    repairsUsed: index % 2,
    repairHealth: 50 + index * 5,
    repairGold: 120 + index * 10
  }));
  state.analytics.waveHistory = state.analytics.waveSummaries.map((summary) => ({ ...summary }));

  hud.update(state, []);
  hud.toggleAnalyticsViewer();

  assert.equal(analyticsViewerContainer.dataset.empty, "false");
  assert.equal(analyticsViewerBody.children.length, 7);
  const summaryRow = analyticsViewerBody.children[0];
  assert.equal(summaryRow.className, "analytics-summary-row");
  assert.equal(summaryRow.children[0].textContent, "Summary");
  assert.equal(summaryRow.children[1].textContent, "Mixed");
  assert.ok(summaryRow.children[2].textContent?.includes("%"));

  const latestRow = analyticsViewerBody.children[1];
  assert.equal(latestRow.dataset.recent, "true");
  assert.equal(latestRow.children[0].textContent, "#6");
  assert.equal(latestRow.children[1].textContent, "Campaign");

  analyticsFilterSelect.value = "last-5";
  analyticsFilterSelect.onchange?.();
  assert.equal(analyticsViewerBody.children.length, 6);

  analyticsFilterSelect.value = "all";
  analyticsFilterSelect.onchange?.();
  assert.equal(analyticsViewerBody.children.length, 7);

  analyticsFilterSelect.value = "breaches";
  analyticsFilterSelect.onchange?.();
  assert.equal(analyticsViewerBody.children.length, 4);

  analyticsFilterSelect.value = "shielded";
  analyticsFilterSelect.onchange?.();
  assert.equal(analyticsViewerBody.children.length, 5);

  cleanup();
});

test("HudView wave scorecard renders summary details", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { waveScorecard, waveScorecardStats, waveScorecardContinue, getScorecardContinueCount } =
    elements;

  assert.equal(hud.isWaveScorecardVisible(), false);

  hud.showWaveScorecard({
    waveIndex: 1,
    waveTotal: 4,
    accuracy: 0.925,
    enemiesDefeated: 18,
    breaches: 1,
    perfectWords: 5,
    averageReaction: 1.23,
    dps: 47.8,
    turretDps: 28.3,
    typingDps: 19.5,
    turretDamage: 226,
    typingDamage: 156,
    shieldBreaks: 3,
    repairsUsed: 2,
    repairHealth: 180,
    repairGold: 150,
    castleBonusGold: 12,
    bonusGold: 45,
    goldEarned: 132,
    bestCombo: 6,
    sessionBestCombo: 9
  });

  assert.equal(waveScorecard.dataset.visible, "true");
  const accuracyRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "accuracy"
  );
  assert.ok(accuracyRow, "expected accuracy row to exist");
  assert.equal(accuracyRow.children[0].textContent, "Accuracy");
  assert.equal(accuracyRow.children[1].textContent, "92.5%");
  const turretDpsRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "dps-turret"
  );
  assert.ok(turretDpsRow, "expected turret DPS row to exist");
  assert.equal(turretDpsRow.children[1].textContent, "28.3");
  const typingDamageRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "damage-typing"
  );
  assert.ok(typingDamageRow, "expected typing damage row to exist");
  assert.equal(typingDamageRow.children[1].textContent, "156");
  const shieldBreakRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "shield-breaks"
  );
  assert.ok(shieldBreakRow, "expected shield break row to exist");
  assert.equal(shieldBreakRow.children[1].textContent, "3");
  const perfectWordsRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "perfect-words"
  );
  assert.ok(perfectWordsRow, "expected perfect words row to exist");
  assert.equal(perfectWordsRow.children[1].textContent, "5");
  const reactionRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "reaction"
  );
  assert.ok(reactionRow, "expected reaction row to exist");
  assert.equal(reactionRow.children[1].textContent, "1.23s");
  const repairCountRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "repairs"
  );
  assert.ok(repairCountRow, "expected repairs row to exist");
  assert.equal(repairCountRow.children[1].textContent, "2");
  const repairHealingRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "repair-health"
  );
  assert.ok(repairHealingRow, "expected repair health row to exist");
  assert.equal(repairHealingRow.children[1].textContent, "180");
  const repairGoldRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "repair-gold"
  );
  assert.ok(repairGoldRow, "expected repair gold row to exist");
  assert.equal(repairGoldRow.children[1].textContent, "150g");
  const bonusGoldRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "bonus-gold"
  );
  assert.ok(bonusGoldRow, "expected bonus gold row to exist");
  assert.equal(bonusGoldRow.children[1].textContent, "+45g");
  const castleBonusRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "castle-bonus"
  );
  assert.ok(castleBonusRow, "expected castle bonus row to exist");
  assert.equal(castleBonusRow.children[1].textContent, "+12g");
  const comboRow = waveScorecardStats.children.find((child) => child.dataset.field === "combo");
  assert.ok(comboRow, "expected combo row to exist");
  assert.equal(comboRow.children[1].textContent, "x6");
  const sessionComboRow = waveScorecardStats.children.find(
    (child) => child.dataset.field === "session-combo"
  );
  assert.ok(sessionComboRow, "expected session combo row to exist");
  assert.equal(sessionComboRow.children[1].textContent, "x9");

  waveScorecardContinue.onclick?.();
  assert.equal(getScorecardContinueCount(), 1);

  hud.hideWaveScorecard();
  assert.equal(waveScorecard.dataset.visible, "false");
  cleanup();
});
