import { type CastleLevelConfig, type GameConfig } from "../core/config.js";
import {
  type CastlePassive,
  type GameMode,
  type GameState,
  type GoldEvent,
  type DefeatAnimationPreference,
  type TurretTargetPriority,
  type TurretTypeId,
  type WaveSpawnPreview,
  type WaveSummary
} from "../core/types.js";
import { WavePreviewPanel } from "./wavePreview.js";
import type { ResolutionTransitionState } from "./ResolutionTransitionController.js";
import {
  SEASON_ROADMAP,
  evaluateRoadmap,
  type RoadmapEntryState
} from "../data/roadmap.js";
import { getEnemyBiography } from "../data/bestiary.js";
import {
  DEFAULT_ROADMAP_PREFERENCES,
  mergeRoadmapPreferences,
  readRoadmapPreferences,
  writeRoadmapPreferences,
  type RoadmapFilterPreferences,
  type RoadmapPreferences
} from "../utils/roadmapPreferences.js";
import { VirtualKeyboard } from "./virtualKeyboard.js";

let hudInstanceCounter = 0;

const PASSIVE_ICON_MAP: Record<
  string,
  {
    label: string;
  }
> = {
  regen: { label: "Regen passive icon" },
  armor: { label: "Armor passive icon" },
  gold: { label: "Bonus gold passive icon" },
  generic: { label: "Castle passive icon" }
};

const isElementWithTag = <T extends HTMLElement>(
  el: Element | null | undefined,
  tagName: string
): el is T => {
  return el instanceof HTMLElement && el.tagName.toLowerCase() === tagName.toLowerCase();
};

export interface HudCallbacks {
  onCastleUpgrade(): void;
  onCastleRepair(): void;
  onPlaceTurret(slotId: string, typeId: TurretTypeId): void;
  onUpgradeTurret(slotId: string): void;
  onDowngradeTurret?: (slotId: string) => void;
  onTurretPriorityChange(slotId: string, priority: TurretTargetPriority): void;
  onTurretPresetSave?: (presetId: string) => void;
  onTurretPresetApply?: (presetId: string) => void;
  onTurretPresetClear?: (presetId: string) => void;
  onAnalyticsExport?: () => void;
  onTelemetryToggle?: (enabled: boolean) => void;
  onCrystalPulseToggle?: (enabled: boolean) => void;
  onEliteAffixesToggle?: (enabled: boolean) => void;
  onPauseRequested(): void;
  onResumeRequested(): void;
  onSoundToggle(enabled: boolean): void;
  onSoundVolumeChange(volume: number): void;
  onSoundIntensityChange(intensity: number): void;
  onDiagnosticsToggle(visible: boolean): void;
  onVirtualKeyboardToggle?: (enabled: boolean) => void;
  onLowGraphicsToggle?: (enabled: boolean) => void;
  onWaveScorecardContinue(): void;
  onReducedMotionToggle(enabled: boolean): void;
  onCheckeredBackgroundToggle(enabled: boolean): void;
  onReadableFontToggle(enabled: boolean): void;
  onDyslexiaFontToggle(enabled: boolean): void;
  onColorblindPaletteToggle(enabled: boolean): void;
  onDefeatAnimationModeChange(mode: DefeatAnimationPreference): void;
  onHudFontScaleChange(scale: number): void;
  onFullscreenToggle?: (nextActive: boolean) => void;
  onTurretHover?: (
    slotId: string | null,
    context?: { typeId?: TurretTypeId | null; level?: number | null }
  ) => void;
  onCollapsePreferenceChange?: (prefs: HudCollapsePreferenceUpdate) => void;
}

interface SlotControls {
  container: HTMLDivElement;
  title: HTMLDivElement;
  status: HTMLDivElement;
  action: HTMLButtonElement;
  downgradeButton?: HTMLButtonElement;
  select: HTMLSelectElement;
  priorityContainer: HTMLDivElement;
  prioritySelect: HTMLSelectElement;
}

interface PresetControl {
  container: HTMLDivElement;
  label: HTMLSpanElement;
  applyButton: HTMLButtonElement;
  saveButton: HTMLButtonElement;
  clearButton: HTMLButtonElement;
  summary: HTMLDivElement;
  meta: HTMLDivElement;
  status: HTMLDivElement;
}

interface HudTurretPresetSlotData {
  slotId: string;
  typeId: TurretTypeId;
  level: number;
  priority?: TurretTargetPriority;
}

interface HudTurretPresetData {
  id: string;
  label: string;
  hasPreset: boolean;
  active: boolean;
  applyCost: number | null;
  applyDisabled: boolean;
  applyMessage: string;
  savedAtLabel: string;
  statusLabel: string | null;
  slots: HudTurretPresetSlotData[];
}

type TutorialSlotLock = {
  slotId: string;
  mode: "placement" | "upgrade";
  forcedType?: TurretTypeId;
};

export interface TutorialSummaryData {
  accuracy: number;
  bestCombo: number;
  breaches: number;
  gold: number;
}

type TutorialSummaryHandlers = {
  onContinue: () => void;
  onReplay: () => void;
};

type TutorialSummaryElements = {
  container: HTMLElement;
  statsList: HTMLUListElement;
  continueBtn: HTMLButtonElement;
  replayBtn: HTMLButtonElement;
};

type TutorialBannerElements = {
  container: HTMLElement;
  message: HTMLElement;
  toggle?: HTMLButtonElement | null;
};

type ShortcutOverlayElements = {
  container: string;
  closeButton: string;
  launchButton: string;
};

type OptionsOverlayElements = {
  container: string;
  closeButton: string;
  resumeButton: string;
  soundToggle: string;
  soundVolumeSlider: string;
  soundVolumeValue: string;
  soundIntensitySlider: string;
  soundIntensityValue: string;
  diagnosticsToggle: string;
  virtualKeyboardToggle?: string;
  lowGraphicsToggle: string;
  reducedMotionToggle: string;
  checkeredBackgroundToggle: string;
  readableFontToggle: string;
  dyslexiaFontToggle: string;
  colorblindPaletteToggle: string;
  fontScaleSelect: string;
  defeatAnimationSelect: string;
  telemetryToggle?: string;
  telemetryToggleWrapper?: string;
  crystalPulseToggle?: string;
  crystalPulseToggleWrapper?: string;
  eliteAffixToggle?: string;
  eliteAffixToggleWrapper?: string;
  analyticsExportButton?: string;
};

type AnalyticsViewerElements = {
  container: string;
  tableBody: string;
  filterSelect?: string;
  drills?: string;
};

type WaveScorecardElements = {
  container: string;
  stats: string;
  continue: string;
};

type RoadmapOverlayElements = {
  container: string;
  closeButton: string;
  list: string;
  summaryWave: string;
  summaryCastle: string;
  summaryLore: string;
  filterStory: string;
  filterSystems: string;
  filterChallenge: string;
  filterLore: string;
  filterCompleted: string;
  trackedContainer: string;
  trackedTitle: string;
  trackedProgress: string;
  trackedClear: string;
};

type RoadmapGlanceElements = {
  container: string;
  title: string;
  progress: string;
  openButton: string;
  clearButton: string;
};

type AnalyticsViewerFilter = "all" | "last-5" | "last-10" | "breaches" | "shielded";

export interface WaveScorecardData {
  waveIndex: number;
  waveTotal: number;
  mode: GameMode;
  accuracy: number;
  enemiesDefeated: number;
  breaches: number;
  perfectWords: number;
  averageReaction: number;
  dps: number;
  turretDps: number;
  typingDps: number;
  turretDamage: number;
  typingDamage: number;
  shieldBreaks: number;
  goldEarned: number;
  bestCombo: number;
  sessionBestCombo: number;
  repairsUsed: number;
  repairHealth: number;
  repairGold: number;
  castleBonusGold: number;
  bonusGold: number;
}

const DEFAULT_WAVE_PREVIEW_HINT =
  "Upcoming enemies appear here—use the preview to plan your defenses.";

type HudCondensedSectionId = "hud-passives" | "hud-gold-events";

export type HudCollapsePreferenceUpdate = {
  hudCastlePassivesCollapsed?: boolean | null;
  hudGoldEventsCollapsed?: boolean | null;
  optionsPassivesCollapsed?: boolean | null;
};

export interface HudCondensedStateSnapshot {
  tutorialBannerCondensed: boolean;
  tutorialBannerExpanded: boolean;
  hudCastlePassivesCollapsed: boolean | null;
  hudGoldEventsCollapsed: boolean | null;
  optionsPassivesCollapsed: boolean | null;
  compactHeight: boolean;
  prefersCondensedLists: boolean;
}

interface CondensedSection {
  container: HTMLDivElement;
  body: HTMLDivElement;
  list: HTMLUListElement;
  summary: HTMLSpanElement;
  toggle: HTMLButtonElement;
  title: string;
  collapsed: boolean;
}

export class HudView {
  private readonly healthBar: HTMLElement;
  private readonly goldLabel: HTMLElement;
  private readonly goldDelta: HTMLElement;
  private readonly activeWord: HTMLElement;
  private readonly typingInput: HTMLInputElement;
  private readonly fullscreenButton: HTMLButtonElement | null = null;
  private readonly capsLockWarning: HTMLElement | null = null;
  private readonly upgradePanel: HTMLElement;
  private readonly comboLabel: HTMLElement;
  private readonly comboAccuracyDelta: HTMLElement;
  private readonly logList: HTMLUListElement;
  private readonly tutorialBanner?: TutorialBannerElements;
  private tutorialBannerExpanded = true;
  private readonly virtualKeyboard?: VirtualKeyboard;
  private virtualKeyboardEnabled = false;
  private readonly castleButton: HTMLButtonElement;
  private readonly castleRepairButton: HTMLButtonElement;
  private readonly castleStatus: HTMLSpanElement;
  private readonly castleBenefits: HTMLUListElement;
  private readonly castleGoldEvents: HTMLUListElement;
  private readonly castlePassives: HTMLUListElement;
  private readonly castlePassivesSection: CondensedSection;
  private readonly castleGoldEventsSection: CondensedSection;
  private readonly wavePreview: WavePreviewPanel;
  private readonly slotControls = new Map<string, SlotControls>();
  private readonly presetControls = new Map<string, PresetControl>();
  private presetContainer: HTMLDivElement | null = null;
  private presetList: HTMLDivElement | null = null;
  private readonly analyticsViewer?: {
    container: HTMLElement;
    tableBody: HTMLTableSectionElement;
    filterSelect?: HTMLSelectElement;
    drills?: HTMLElement;
  };
  private analyticsViewerVisible = false;
  private analyticsViewerSignature = "";
  private analyticsViewerFilter: AnalyticsViewerFilter = "all";
  private analyticsViewerFilterSelect?: HTMLSelectElement;
  private roadmapPreferences: RoadmapPreferences = {
    ...DEFAULT_ROADMAP_PREFERENCES,
    filters: { ...DEFAULT_ROADMAP_PREFERENCES.filters }
  };
  private roadmapState: {
    entries: RoadmapEntryState[];
    completed: number;
    total: number;
    activeId: string | null;
  } | null = null;
  private readonly roadmapOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    list: HTMLUListElement;
    summaryWave: HTMLElement;
    summaryCastle: HTMLElement;
    summaryLore: HTMLElement;
    filters: {
      story: HTMLInputElement;
      systems: HTMLInputElement;
      challenge: HTMLInputElement;
      lore: HTMLInputElement;
      completed: HTMLInputElement;
    };
    tracked: {
      container: HTMLElement;
      title: HTMLElement;
      progress: HTMLElement;
      clear: HTMLButtonElement;
    };
  };
  private readonly roadmapGlance?: {
    container: HTMLElement;
    title: HTMLElement;
    progress: HTMLElement;
    openButton?: HTMLButtonElement;
    clearButton?: HTMLButtonElement;
  };
  private lastShieldTelemetry = { current: false, next: false };
  private lastAffixTelemetry = { current: false, next: false };
  private lastWavePreviewEntries: WaveSpawnPreview[] = [];
  private lastWavePreviewColorBlind = false;
  private lastGold = 0;
  private maxCombo = 0;
  private goldTimeout: number | null = null;
  private readonly logEntries: string[] = [];
  private readonly logLimit = 6;
  private tutorialSlotLock: TutorialSlotLock | null = null;
  private passiveHighlightId: string | null = null;
  private lastState: GameState | null = null;
  private availableTurretTypes: Record<string, boolean> = {};
  private turretDowngradeEnabled = false;
  private readonly tutorialSummary?: TutorialSummaryElements;
  private tutorialSummaryHandlers: TutorialSummaryHandlers | null = null;
  private readonly shortcutLaunchButton?: HTMLButtonElement;
  private readonly shortcutOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
  };
  private readonly enemyBioCard?: {
    container: HTMLElement;
    title: HTMLElement;
    role: HTMLElement;
    danger: HTMLElement;
    description: HTMLElement;
    abilities: HTMLUListElement;
    tips: HTMLUListElement;
  };
  private selectedEnemyBioId: string | null = null;
  private optionsCastleBonus?: HTMLElement;
  private optionsCastleBenefits?: HTMLUListElement;
  private optionsCastlePassives?: HTMLUListElement;
  private optionsPassivesSection?: HTMLElement;
  private optionsPassivesSummary?: HTMLElement;
  private optionsPassivesToggle?: HTMLButtonElement;
  private optionsPassivesBody?: HTMLElement;
  private optionsPassivesCollapsed = false;
  private optionsPassivesDefaultCollapsed = false;
  private wavePreviewHint?: HTMLElement;
  private wavePreviewHintMessage = DEFAULT_WAVE_PREVIEW_HINT;
  private wavePreviewHintPinned = false;
  private wavePreviewHintTimeout: ReturnType<typeof setTimeout> | null = null;
  private readonly optionsOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    resumeButton: HTMLButtonElement;
    soundToggle: HTMLInputElement;
    soundVolumeSlider: HTMLInputElement;
    soundVolumeValue: HTMLElement;
    soundIntensitySlider: HTMLInputElement;
    soundIntensityValue: HTMLElement;
    diagnosticsToggle: HTMLInputElement;
    virtualKeyboardToggle?: HTMLInputElement;
    lowGraphicsToggle?: HTMLInputElement;
    reducedMotionToggle: HTMLInputElement;
    checkeredBackgroundToggle: HTMLInputElement;
    readableFontToggle: HTMLInputElement;
    dyslexiaFontToggle: HTMLInputElement;
    colorblindPaletteToggle: HTMLInputElement;
    fontScaleSelect: HTMLSelectElement;
    defeatAnimationSelect: HTMLSelectElement;
    telemetryToggle?: HTMLInputElement;
    telemetryWrapper?: HTMLElement;
    crystalPulseToggle?: HTMLInputElement;
    crystalPulseWrapper?: HTMLElement;
    eliteAffixToggle?: HTMLInputElement;
    eliteAffixWrapper?: HTMLElement;
    analyticsExportButton?: HTMLButtonElement;
  };
  private readonly waveScorecard?: {
    container: HTMLElement;
    statsList: HTMLUListElement;
    continueBtn: HTMLButtonElement;
  };
  private syncingOptionToggles = false;
  private comboBaselineAccuracy = 1;
  private lastAccuracy = 1;
  private hudRoot: HTMLElement | null = null;
  private evacBanner?:
    | {
        container: HTMLElement;
        title: HTMLElement;
        timer: HTMLElement;
        progress: HTMLElement;
        status: HTMLElement;
      }
    | undefined;
  private evacHideTimeout: ReturnType<typeof setTimeout> | null = null;
  private evacResolvedState: "idle" | "success" | "fail" = "idle";

  constructor(
    private readonly config: GameConfig,
    rootIds: {
      healthBar: string;
      goldLabel: string;
      goldDelta: string;
      activeWord: string;
      typingInput: string;
      virtualKeyboard?: string;
      upgradePanel: string;
      comboLabel: string;
      comboAccuracyDelta: string;
      eventLog: string;
      fullscreenButton?: string;
      wavePreview: string;
      wavePreviewHint?: string;
      tutorialBanner: string;
      tutorialSummary: {
        container: string;
        stats: string;
        continue: string;
        replay: string;
      };
      pauseButton?: string;
      shortcutOverlay?: ShortcutOverlayElements;
      optionsOverlay?: OptionsOverlayElements;
      waveScorecard?: WaveScorecardElements;
      analyticsViewer?: AnalyticsViewerElements;
      roadmapOverlay?: RoadmapOverlayElements;
      roadmapGlance?: RoadmapGlanceElements;
      roadmapLaunch?: string;
    },
    private readonly callbacks: HudCallbacks
  ) {
    this.hudRoot = document.getElementById("hud");
    if (this.hudRoot && !this.hudRoot.dataset.canvasTransition) {
      this.hudRoot.dataset.canvasTransition = "idle";
    }
    if (this.hudRoot) {
      const banner = document.createElement("div");
      banner.className = "evac-banner";
      banner.dataset.visible = "false";
      banner.setAttribute("role", "status");
      banner.setAttribute("aria-live", "polite");
      banner.style.display = "none";
      banner.style.background = "linear-gradient(90deg, #0f172a, #0b2339)";
      banner.style.color = "#e0f2fe";
      banner.style.border = "1px solid #38bdf8";
      banner.style.borderRadius = "10px";
      banner.style.padding = "10px";
      banner.style.gap = "10px";
      banner.style.alignItems = "center";
      banner.style.justifyContent = "space-between";
      banner.style.boxShadow = "0 6px 14px rgba(0,0,0,0.25)";
      banner.style.marginBottom = "12px";
      banner.style.flexWrap = "wrap";
      banner.style.display = "none";
      banner.style.position = "relative";
      const title = document.createElement("div");
      title.className = "evac-title";
      title.style.fontWeight = "700";
      title.style.letterSpacing = "0.3px";
      const timer = document.createElement("div");
      timer.className = "evac-timer";
      timer.style.fontVariantNumeric = "tabular-nums";
      timer.style.fontSize = "14px";
      const status = document.createElement("div");
      status.className = "evac-status";
      status.style.fontSize = "12px";
      status.style.opacity = "0.85";
      const barOuter = document.createElement("div");
      barOuter.className = "evac-progress";
      barOuter.style.width = "100%";
      barOuter.style.height = "6px";
      barOuter.style.background = "rgba(255,255,255,0.08)";
      barOuter.style.borderRadius = "999px";
      const barInner = document.createElement("div");
      barInner.style.height = "100%";
      barInner.style.width = "0%";
      barInner.style.borderRadius = "999px";
      barInner.style.background = "linear-gradient(90deg, #38bdf8, #a5b4fc)";
      barOuter.appendChild(barInner);
      banner.appendChild(title);
      banner.appendChild(timer);
      banner.appendChild(status);
      banner.appendChild(barOuter);
      this.hudRoot.prepend(banner);
      this.evacBanner = { container: banner, title, timer, progress: barInner, status };
    }

    this.healthBar = this.getElement(rootIds.healthBar);
    this.goldLabel = this.getElement(rootIds.goldLabel);
    this.goldDelta = this.getElement(rootIds.goldDelta);
    this.activeWord = this.getElement(rootIds.activeWord);
    this.typingInput = this.getElement(rootIds.typingInput) as HTMLInputElement;
    this.fullscreenButton = (() => {
      if (!rootIds.fullscreenButton) return null;
      const el = document.getElementById(rootIds.fullscreenButton);
      return el instanceof HTMLButtonElement ? el : null;
    })();
    const capsEl = document.getElementById("caps-lock-warning");
    this.capsLockWarning = capsEl instanceof HTMLElement ? capsEl : null;
    if (this.capsLockWarning) {
      this.capsLockWarning.dataset.visible = this.capsLockWarning.dataset.visible ?? "false";
      this.capsLockWarning.setAttribute("aria-hidden", "true");
    }
    this.upgradePanel = this.getElement(rootIds.upgradePanel);
    this.comboLabel = this.getElement(rootIds.comboLabel);
    this.comboAccuracyDelta = this.getElement(rootIds.comboAccuracyDelta);
    this.hideComboAccuracyDelta();
    this.logList = this.getElement(rootIds.eventLog) as HTMLUListElement;
    if (rootIds.virtualKeyboard) {
      const virtualKeyboardEl = document.getElementById(rootIds.virtualKeyboard);
      if (virtualKeyboardEl instanceof HTMLElement) {
        this.virtualKeyboard = new VirtualKeyboard(virtualKeyboardEl);
      }
    }

    const previewContainer = this.getElement(rootIds.wavePreview);
    this.wavePreview = new WavePreviewPanel(previewContainer, this.config);
    if (rootIds.wavePreviewHint) {
      const hintElement = document.getElementById(rootIds.wavePreviewHint);
      if (hintElement instanceof HTMLElement) {
        this.wavePreviewHint = hintElement;
        this.wavePreviewHint.dataset.visible = this.wavePreviewHint.dataset.visible ?? "false";
        this.wavePreviewHint.setAttribute("aria-hidden", "true");
        this.wavePreviewHint.textContent = "";
      } else {
        console.warn("Wave preview hint element missing; tutorial hint disabled.");
      }
    }
    if (!this.wavePreviewHint) {
      const parent = previewContainer.parentElement ?? undefined;
      if (parent instanceof HTMLElement) {
        const hint = document.createElement("div");
        hint.className = "wave-preview-hint";
        hint.dataset.visible = "false";
        hint.setAttribute("aria-hidden", "true");
        hint.setAttribute("role", "status");
        hint.setAttribute("aria-live", "polite");
        parent.insertBefore(hint, previewContainer);
        this.wavePreviewHint = hint;
      }
    }
    const enemyBioContainer = document.getElementById("enemy-bio-card");
    const enemyBioTitle = document.getElementById("enemy-bio-title");
    const enemyBioRole = document.getElementById("enemy-bio-role");
    const enemyBioDanger = document.getElementById("enemy-bio-danger");
    const enemyBioDescription = document.getElementById("enemy-bio-description");
    const enemyBioAbilities = document.getElementById("enemy-bio-abilities");
    const enemyBioTips = document.getElementById("enemy-bio-tips");
    if (
      enemyBioContainer instanceof HTMLElement &&
      enemyBioTitle instanceof HTMLElement &&
      enemyBioRole instanceof HTMLElement &&
      enemyBioDanger instanceof HTMLElement &&
      enemyBioDescription instanceof HTMLElement &&
      isElementWithTag<HTMLUListElement>(enemyBioAbilities, "ul") &&
      isElementWithTag<HTMLUListElement>(enemyBioTips, "ul")
    ) {
      this.enemyBioCard = {
        container: enemyBioContainer,
        title: enemyBioTitle,
        role: enemyBioRole,
        danger: enemyBioDanger,
        description: enemyBioDescription,
        abilities: enemyBioAbilities,
        tips: enemyBioTips
      };
      this.enemyBioCard.container.dataset.visible = "false";
      this.enemyBioCard.container.setAttribute("aria-hidden", "true");
    } else {
      console.warn("Enemy biography elements missing; wave preview bios disabled.");
    }
    this.availableTurretTypes = Object.fromEntries(
      Object.keys(this.config.turretArchetypes).map((typeId) => [typeId, true])
    );
    if (typeof window !== "undefined" && window.localStorage) {
      this.roadmapPreferences = readRoadmapPreferences(window.localStorage);
    } else {
      this.roadmapPreferences = {
        ...DEFAULT_ROADMAP_PREFERENCES,
        filters: { ...DEFAULT_ROADMAP_PREFERENCES.filters }
      };
    }
    const tutorialBannerElement = document.getElementById(rootIds.tutorialBanner);
    if (tutorialBannerElement instanceof HTMLElement) {
      const messageElement =
        (tutorialBannerElement.querySelector("[data-role='tutorial-message']") as HTMLElement | null) ??
        tutorialBannerElement;
      const toggleElement = tutorialBannerElement.querySelector<HTMLButtonElement>(
        "[data-role='tutorial-toggle']"
      );
      if (toggleElement) {
        toggleElement.addEventListener("click", () => {
          if (tutorialBannerElement.dataset.visible !== "true") {
            return;
          }
          this.tutorialBannerExpanded = !this.tutorialBannerExpanded;
          this.refreshTutorialBannerLayout();
        });
      }
      this.tutorialBanner = {
        container: tutorialBannerElement,
        message: messageElement,
        toggle: toggleElement ?? undefined
      };
    } else {
      this.tutorialBanner = undefined;
    }
    const summaryContainer =
      document.getElementById(rootIds.tutorialSummary.container) ?? undefined;
    const summaryStats = document.getElementById(
      rootIds.tutorialSummary.stats
    ) as HTMLUListElement | null;
    const summaryContinue = document.getElementById(
      rootIds.tutorialSummary.continue
    ) as HTMLButtonElement | null;
    const summaryReplay = document.getElementById(
      rootIds.tutorialSummary.replay
    ) as HTMLButtonElement | null;
    if (summaryContainer && summaryStats && summaryContinue && summaryReplay) {
      this.tutorialSummary = {
        container: summaryContainer,
        statsList: summaryStats,
        continueBtn: summaryContinue,
        replayBtn: summaryReplay
      };
    } else {
      console.warn("Tutorial summary elements missing; wrap-up overlay disabled.");
    }

    if (rootIds.shortcutOverlay) {
      const shortcutContainer = document.getElementById(rootIds.shortcutOverlay.container);
      const closeButton = document.getElementById(rootIds.shortcutOverlay.closeButton);
      const launchButton = document.getElementById(rootIds.shortcutOverlay.launchButton);

      if (shortcutContainer instanceof HTMLElement && closeButton instanceof HTMLButtonElement) {
        this.shortcutOverlay = {
          container: shortcutContainer,
          closeButton
        };
        closeButton.addEventListener("click", () => this.hideShortcutOverlay());
      } else {
        console.warn("Shortcut overlay elements missing; reference overlay disabled.");
      }

      if (launchButton instanceof HTMLButtonElement) {
        this.shortcutLaunchButton = launchButton;
        launchButton.addEventListener("click", () => this.toggleShortcutOverlay());
      }
    }

    if (rootIds.pauseButton) {
      const pauseButton = document.getElementById(rootIds.pauseButton);
      if (pauseButton instanceof HTMLButtonElement) {
        pauseButton.addEventListener("click", () => this.callbacks.onPauseRequested());
      } else {
        console.warn("Pause button missing; pause overlay disabled.");
      }
    }

    if (rootIds.optionsOverlay) {
      const optionsContainer = document.getElementById(rootIds.optionsOverlay.container);
      const closeButton = document.getElementById(rootIds.optionsOverlay.closeButton);
      const resumeButton = document.getElementById(rootIds.optionsOverlay.resumeButton);
      const soundToggle = document.getElementById(rootIds.optionsOverlay.soundToggle);
      const soundVolumeSlider = document.getElementById(rootIds.optionsOverlay.soundVolumeSlider);
      const soundVolumeValue = document.getElementById(rootIds.optionsOverlay.soundVolumeValue);
      const soundIntensitySlider = document.getElementById(
        rootIds.optionsOverlay.soundIntensitySlider
      );
      const soundIntensityValue = document.getElementById(
        rootIds.optionsOverlay.soundIntensityValue
      );
      const diagnosticsToggle = document.getElementById(rootIds.optionsOverlay.diagnosticsToggle);
      const virtualKeyboardToggle = rootIds.optionsOverlay.virtualKeyboardToggle
        ? document.getElementById(rootIds.optionsOverlay.virtualKeyboardToggle)
        : null;
      const lowGraphicsToggle = document.getElementById(rootIds.optionsOverlay.lowGraphicsToggle);
      const reducedMotionToggle = document.getElementById(
        rootIds.optionsOverlay.reducedMotionToggle
      );
      const checkeredBackgroundToggle = document.getElementById(
        rootIds.optionsOverlay.checkeredBackgroundToggle
      );
      const readableFontToggle = document.getElementById(rootIds.optionsOverlay.readableFontToggle);
      const dyslexiaFontToggle = document.getElementById(rootIds.optionsOverlay.dyslexiaFontToggle);
      const colorblindPaletteToggle = document.getElementById(
        rootIds.optionsOverlay.colorblindPaletteToggle
      );
      const fontScaleSelect = document.getElementById(rootIds.optionsOverlay.fontScaleSelect);
      const defeatAnimationSelect = document.getElementById(
        rootIds.optionsOverlay.defeatAnimationSelect
      );
      const telemetryToggle = rootIds.optionsOverlay.telemetryToggle
        ? document.getElementById(rootIds.optionsOverlay.telemetryToggle)
        : null;
      const telemetryToggleWrapper = rootIds.optionsOverlay.telemetryToggleWrapper
        ? document.getElementById(rootIds.optionsOverlay.telemetryToggleWrapper)
        : null;
      const crystalPulseToggle = rootIds.optionsOverlay.crystalPulseToggle
        ? document.getElementById(rootIds.optionsOverlay.crystalPulseToggle)
        : null;
      const crystalPulseToggleWrapper = rootIds.optionsOverlay.crystalPulseToggleWrapper
        ? document.getElementById(rootIds.optionsOverlay.crystalPulseToggleWrapper)
        : null;
      const eliteAffixToggle = rootIds.optionsOverlay.eliteAffixToggle
        ? document.getElementById(rootIds.optionsOverlay.eliteAffixToggle)
        : null;
      const eliteAffixToggleWrapper = rootIds.optionsOverlay.eliteAffixToggleWrapper
        ? document.getElementById(rootIds.optionsOverlay.eliteAffixToggleWrapper)
        : null;
      const analyticsExportButton = rootIds.optionsOverlay.analyticsExportButton
        ? document.getElementById(rootIds.optionsOverlay.analyticsExportButton)
        : null;

      if (
        optionsContainer instanceof HTMLElement &&
        closeButton instanceof HTMLButtonElement &&
        resumeButton instanceof HTMLButtonElement &&
        soundToggle instanceof HTMLInputElement &&
        soundVolumeSlider instanceof HTMLInputElement &&
        soundVolumeValue instanceof HTMLElement &&
        soundIntensitySlider instanceof HTMLInputElement &&
        soundIntensityValue instanceof HTMLElement &&
        diagnosticsToggle instanceof HTMLInputElement &&
        reducedMotionToggle instanceof HTMLInputElement &&
        checkeredBackgroundToggle instanceof HTMLInputElement &&
        readableFontToggle instanceof HTMLInputElement &&
        dyslexiaFontToggle instanceof HTMLInputElement &&
        colorblindPaletteToggle instanceof HTMLInputElement &&
        fontScaleSelect instanceof HTMLSelectElement &&
        defeatAnimationSelect instanceof HTMLSelectElement
      ) {
        this.optionsOverlay = {
          container: optionsContainer,
          closeButton,
          resumeButton,
          soundToggle,
          soundVolumeSlider,
          soundVolumeValue,
          soundIntensitySlider,
          soundIntensityValue,
          diagnosticsToggle,
          virtualKeyboardToggle:
            virtualKeyboardToggle instanceof HTMLInputElement ? virtualKeyboardToggle : undefined,
          lowGraphicsToggle:
            lowGraphicsToggle instanceof HTMLInputElement ? lowGraphicsToggle : undefined,
          reducedMotionToggle,
          checkeredBackgroundToggle,
          readableFontToggle,
          dyslexiaFontToggle,
          colorblindPaletteToggle,
          fontScaleSelect,
          defeatAnimationSelect,
          telemetryToggle:
            telemetryToggle instanceof HTMLInputElement ? telemetryToggle : undefined,
          telemetryWrapper:
            telemetryToggleWrapper instanceof HTMLElement ? telemetryToggleWrapper : undefined,
          crystalPulseToggle:
            crystalPulseToggle instanceof HTMLInputElement ? crystalPulseToggle : undefined,
          crystalPulseWrapper:
            crystalPulseToggleWrapper instanceof HTMLElement
              ? crystalPulseToggleWrapper
              : undefined,
          eliteAffixToggle: eliteAffixToggle instanceof HTMLInputElement ? eliteAffixToggle : undefined,
          eliteAffixWrapper:
            eliteAffixToggleWrapper instanceof HTMLElement ? eliteAffixToggleWrapper : undefined,
          analyticsExportButton:
            analyticsExportButton instanceof HTMLButtonElement ? analyticsExportButton : undefined
        };
        const castleBonusHint = document.getElementById("options-castle-bonus");
        if (castleBonusHint instanceof HTMLElement) {
          this.optionsCastleBonus = castleBonusHint;
          this.optionsCastleBonus.textContent = "";
        } else {
          console.warn("Options castle bonus element missing; bonus hint disabled.");
        }
        const castleBenefitsList = document.getElementById("options-castle-benefits");
        if (isElementWithTag<HTMLUListElement>(castleBenefitsList, "ul")) {
          this.optionsCastleBenefits = castleBenefitsList;
          this.optionsCastleBenefits.replaceChildren();
        } else {
          console.warn("Options castle benefits element missing; upgrade summary disabled.");
        }
        const passivesSection = document.getElementById("options-passives-section");
        if (passivesSection instanceof HTMLElement) {
          this.optionsPassivesSection = passivesSection;
          const passivesBody = passivesSection.querySelector(".options-passives-body");
          if (passivesBody instanceof HTMLElement) {
            this.optionsPassivesBody = passivesBody;
          }
        }
        const passivesSummary = document.getElementById("options-passives-summary");
        if (passivesSummary instanceof HTMLElement) {
          this.optionsPassivesSummary = passivesSummary;
        }
        this.optionsPassivesDefaultCollapsed = this.prefersCondensedHudLists();
        this.optionsPassivesCollapsed = this.optionsPassivesDefaultCollapsed;
        const passivesToggle = document.getElementById("options-passives-toggle");
        if (passivesToggle instanceof HTMLButtonElement) {
          this.optionsPassivesToggle = passivesToggle;
          passivesToggle.addEventListener("click", () => {
            this.setOptionsPassivesCollapsed(!this.optionsPassivesCollapsed);
          });
        }
        const castlePassivesList = document.getElementById("options-castle-passives");
        if (isElementWithTag<HTMLUListElement>(castlePassivesList, "ul")) {
          this.optionsCastlePassives = castlePassivesList;
          this.optionsCastlePassives.replaceChildren();
          this.updateOptionsPassivesSummary("No passives");
          this.setOptionsPassivesCollapsed(this.optionsPassivesCollapsed, { silent: true });
        } else {
          console.warn("Options castle passives element missing; passive summary disabled.");
        }
        closeButton.addEventListener("click", () => this.callbacks.onResumeRequested());
        resumeButton.addEventListener("click", () => this.callbacks.onResumeRequested());
        soundToggle.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          this.callbacks.onSoundToggle(soundToggle.checked);
        });
        soundVolumeSlider.addEventListener("input", () => {
          if (this.syncingOptionToggles) return;
          const nextValue = Number.parseFloat(soundVolumeSlider.value);
          if (!Number.isFinite(nextValue)) return;
          this.updateSoundVolumeDisplay(nextValue);
          this.callbacks.onSoundVolumeChange(nextValue);
        });
        soundIntensitySlider.addEventListener("input", () => {
          if (this.syncingOptionToggles) return;
          const nextValue = Number.parseFloat(soundIntensitySlider.value);
          if (!Number.isFinite(nextValue)) return;
          this.updateSoundIntensityDisplay(nextValue);
          this.callbacks.onSoundIntensityChange(nextValue);
        });
        diagnosticsToggle.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          this.callbacks.onDiagnosticsToggle(diagnosticsToggle.checked);
        });
        if (this.optionsOverlay.virtualKeyboardToggle) {
          this.optionsOverlay.virtualKeyboardToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onVirtualKeyboardToggle?.(
              this.optionsOverlay!.virtualKeyboardToggle!.checked
            );
          });
        }
        if (this.optionsOverlay.lowGraphicsToggle) {
          this.optionsOverlay.lowGraphicsToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onLowGraphicsToggle?.(this.optionsOverlay!.lowGraphicsToggle!.checked);
          });
        }
        reducedMotionToggle.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          this.callbacks.onReducedMotionToggle(reducedMotionToggle.checked);
        });
        checkeredBackgroundToggle.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          this.callbacks.onCheckeredBackgroundToggle(checkeredBackgroundToggle.checked);
        });
        readableFontToggle.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          this.callbacks.onReadableFontToggle(readableFontToggle.checked);
        });
        dyslexiaFontToggle.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          this.callbacks.onDyslexiaFontToggle(dyslexiaFontToggle.checked);
        });
        colorblindPaletteToggle.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          this.callbacks.onColorblindPaletteToggle(colorblindPaletteToggle.checked);
        });
        this.optionsOverlay.defeatAnimationSelect.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          const nextMode = this.optionsOverlay!.defeatAnimationSelect!.value as DefeatAnimationPreference;
          this.callbacks.onDefeatAnimationModeChange(nextMode);
        });
        fontScaleSelect.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          const rawValue = this.getSelectValue(fontScaleSelect);
          const nextValue = Number.parseFloat(rawValue ?? "");
          if (!Number.isFinite(nextValue)) return;
          this.callbacks.onHudFontScaleChange(nextValue);
        });
        if (this.optionsOverlay.telemetryToggle) {
          this.optionsOverlay.telemetryToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onTelemetryToggle?.(this.optionsOverlay!.telemetryToggle!.checked);
          });
        }
        if (this.optionsOverlay.eliteAffixToggle) {
          this.optionsOverlay.eliteAffixToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onEliteAffixesToggle?.(this.optionsOverlay!.eliteAffixToggle!.checked);
          });
        }
        if (this.optionsOverlay.crystalPulseToggle) {
          this.optionsOverlay.crystalPulseToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onCrystalPulseToggle?.(this.optionsOverlay!.crystalPulseToggle!.checked);
          });
        }
        if (this.optionsOverlay.analyticsExportButton) {
          this.optionsOverlay.analyticsExportButton.addEventListener("click", () => {
            this.callbacks.onAnalyticsExport?.();
          });
        }
      } else {
        console.warn("Options overlay elements missing; pause overlay disabled.");
      }
    }

    if (rootIds.waveScorecard) {
      const scorecardContainer = document.getElementById(rootIds.waveScorecard.container);
      const scorecardStats = document.getElementById(rootIds.waveScorecard.stats);
      const scorecardContinue = document.getElementById(rootIds.waveScorecard.continue);
      if (
        scorecardContainer instanceof HTMLElement &&
        isElementWithTag<HTMLUListElement>(scorecardStats, "ul") &&
        scorecardContinue instanceof HTMLButtonElement
      ) {
        this.waveScorecard = {
          container: scorecardContainer,
          statsList: scorecardStats,
          continueBtn: scorecardContinue
        };
        scorecardContinue.addEventListener("click", () => this.callbacks.onWaveScorecardContinue());
      } else {
        console.warn("Wave scorecard elements missing; wave summary overlay disabled.");
      }
    }

    if (rootIds.analyticsViewer) {
      const viewerContainer = document.getElementById(rootIds.analyticsViewer.container);
      const viewerBody = document.getElementById(rootIds.analyticsViewer.tableBody);
      const viewerFilter = rootIds.analyticsViewer.filterSelect
        ? document.getElementById(rootIds.analyticsViewer.filterSelect)
        : null;
      const drillsContainer = rootIds.analyticsViewer.drills
        ? document.getElementById(rootIds.analyticsViewer.drills)
        : null;
      if (
        viewerContainer instanceof HTMLElement &&
        isElementWithTag<HTMLTableSectionElement>(viewerBody, "tbody")
      ) {
        this.analyticsViewer = {
          container: viewerContainer,
          tableBody: viewerBody,
          filterSelect: viewerFilter instanceof HTMLSelectElement ? viewerFilter : undefined,
          drills: drillsContainer instanceof HTMLElement ? drillsContainer : undefined
        };
        this.analyticsViewerVisible = viewerContainer.dataset.visible === "true";
        viewerContainer.setAttribute("aria-hidden", this.analyticsViewerVisible ? "false" : "true");
        if (this.analyticsViewer.filterSelect) {
          this.analyticsViewerFilterSelect = this.analyticsViewer.filterSelect;
          this.setSelectValue(this.analyticsViewerFilterSelect, this.analyticsViewerFilter);
          this.analyticsViewerFilterSelect.addEventListener("change", () => {
            const next = this.normalizeAnalyticsViewerFilter(
              this.getSelectValue(this.analyticsViewerFilterSelect) ?? "all"
            );
            if (next !== this.analyticsViewerFilter) {
              this.analyticsViewerFilter = next;
              if (this.lastState) {
                const history = this.lastState.analytics.waveHistory?.length
                  ? this.lastState.analytics.waveHistory
                  : this.lastState.analytics.waveSummaries;
                this.refreshAnalyticsViewer(history, {
                  force: true,
                  timeToFirstTurret: this.lastState?.analytics.timeToFirstTurret ?? null
                });
              }
            } else if (this.analyticsViewerFilterSelect) {
              this.setSelectValue(this.analyticsViewerFilterSelect, this.analyticsViewerFilter);
            }
          });
        }
      } else {
        console.warn("Analytics viewer elements missing; debug analytics viewer disabled.");
      }
    }

    if (rootIds.roadmapLaunch) {
      const launchButton = document.getElementById(rootIds.roadmapLaunch);
      if (launchButton instanceof HTMLButtonElement) {
        launchButton.addEventListener("click", () => this.showRoadmapOverlay());
      }
    }

    if (rootIds.roadmapGlance) {
      const glanceContainer = document.getElementById(rootIds.roadmapGlance.container);
      const glanceTitle = document.getElementById(rootIds.roadmapGlance.title);
      const glanceProgress = document.getElementById(rootIds.roadmapGlance.progress);
      const glanceOpen = document.getElementById(rootIds.roadmapGlance.openButton);
      const glanceClear = document.getElementById(rootIds.roadmapGlance.clearButton);
      if (
        glanceContainer instanceof HTMLElement &&
        glanceTitle instanceof HTMLElement &&
        glanceProgress instanceof HTMLElement
      ) {
        this.roadmapGlance = {
          container: glanceContainer,
          title: glanceTitle,
          progress: glanceProgress,
          openButton: glanceOpen instanceof HTMLButtonElement ? glanceOpen : undefined,
          clearButton: glanceClear instanceof HTMLButtonElement ? glanceClear : undefined
        };
        this.roadmapGlance.container.dataset.visible = "false";
        this.roadmapGlance.container.setAttribute("aria-hidden", "true");
        if (this.roadmapGlance.openButton) {
          this.roadmapGlance.openButton.addEventListener("click", () => this.showRoadmapOverlay());
        }
        if (this.roadmapGlance.clearButton) {
          this.roadmapGlance.clearButton.addEventListener("click", () => this.clearRoadmapTracking());
        }
      } else {
        console.warn("Roadmap glance elements missing; roadmap tracker disabled.");
      }
    }

    if (rootIds.roadmapOverlay) {
      const overlayContainer = document.getElementById(rootIds.roadmapOverlay.container);
      const closeButton = document.getElementById(rootIds.roadmapOverlay.closeButton);
      const list = document.getElementById(rootIds.roadmapOverlay.list);
      const summaryWave = document.getElementById(rootIds.roadmapOverlay.summaryWave);
      const summaryCastle = document.getElementById(rootIds.roadmapOverlay.summaryCastle);
      const summaryLore = document.getElementById(rootIds.roadmapOverlay.summaryLore);
      const filterStory = document.getElementById(rootIds.roadmapOverlay.filterStory);
      const filterSystems = document.getElementById(rootIds.roadmapOverlay.filterSystems);
      const filterChallenge = document.getElementById(rootIds.roadmapOverlay.filterChallenge);
      const filterLore = document.getElementById(rootIds.roadmapOverlay.filterLore);
      const filterCompleted = document.getElementById(rootIds.roadmapOverlay.filterCompleted);
      const trackedContainer = document.getElementById(rootIds.roadmapOverlay.trackedContainer);
      const trackedTitle = document.getElementById(rootIds.roadmapOverlay.trackedTitle);
      const trackedProgress = document.getElementById(rootIds.roadmapOverlay.trackedProgress);
      const trackedClear = document.getElementById(rootIds.roadmapOverlay.trackedClear);
      if (
        overlayContainer instanceof HTMLElement &&
        closeButton instanceof HTMLButtonElement &&
        list instanceof HTMLUListElement &&
        summaryWave instanceof HTMLElement &&
        summaryCastle instanceof HTMLElement &&
        summaryLore instanceof HTMLElement &&
        filterStory instanceof HTMLInputElement &&
        filterSystems instanceof HTMLInputElement &&
        filterChallenge instanceof HTMLInputElement &&
        filterLore instanceof HTMLInputElement &&
        filterCompleted instanceof HTMLInputElement &&
        trackedContainer instanceof HTMLElement &&
        trackedTitle instanceof HTMLElement &&
        trackedProgress instanceof HTMLElement &&
        trackedClear instanceof HTMLButtonElement
      ) {
        this.roadmapOverlay = {
          container: overlayContainer,
          closeButton,
          list,
          summaryWave,
          summaryCastle,
          summaryLore,
          filters: {
            story: filterStory,
            systems: filterSystems,
            challenge: filterChallenge,
            lore: filterLore,
            completed: filterCompleted
          },
          tracked: {
            container: trackedContainer,
            title: trackedTitle,
            progress: trackedProgress,
            clear: trackedClear
          }
        };
        closeButton.addEventListener("click", () => this.hideRoadmapOverlay());
        trackedClear.addEventListener("click", () => this.clearRoadmapTracking());
        const applyFilters = () => {
          this.applyRoadmapFilters({
            story: this.roadmapOverlay?.filters.story.checked ?? true,
            systems: this.roadmapOverlay?.filters.systems.checked ?? true,
            challenge: this.roadmapOverlay?.filters.challenge.checked ?? true,
            lore: this.roadmapOverlay?.filters.lore.checked ?? true,
            completed: this.roadmapOverlay?.filters.completed.checked ?? false
          });
        };
        filterStory.addEventListener("change", applyFilters);
        filterSystems.addEventListener("change", applyFilters);
        filterChallenge.addEventListener("change", applyFilters);
        filterLore.addEventListener("change", applyFilters);
        filterCompleted.addEventListener("change", applyFilters);
        filterStory.checked = this.roadmapPreferences.filters.story;
        filterSystems.checked = this.roadmapPreferences.filters.systems;
        filterChallenge.checked = this.roadmapPreferences.filters.challenge;
        filterLore.checked = this.roadmapPreferences.filters.lore;
        filterCompleted.checked = this.roadmapPreferences.filters.completed;
        this.roadmapOverlay.container.dataset.visible =
          this.roadmapOverlay.container.dataset.visible ?? "false";
        this.roadmapOverlay.container.setAttribute("aria-hidden", "true");
        const kicker = overlayContainer.querySelector(".roadmap-kicker");
        if (kicker instanceof HTMLElement) {
          kicker.textContent = SEASON_ROADMAP.season;
        }
        const subtitle = overlayContainer.querySelector(".roadmap-subtitle");
        if (subtitle instanceof HTMLElement && SEASON_ROADMAP.theme) {
          subtitle.textContent = SEASON_ROADMAP.theme;
        }
      } else {
        console.warn("Roadmap overlay elements missing; roadmap overlay disabled.");
      }
    }

    this.initializeViewportListeners();

    this.castleButton = document.createElement("button");
    this.castleButton.type = "button";
    this.castleButton.textContent = "Upgrade Castle";
    this.castleRepairButton = document.createElement("button");
    this.castleRepairButton.type = "button";
    this.castleRepairButton.className = "castle-repair";
    this.castleRepairButton.textContent = "Repair Castle";
    this.castleRepairButton.disabled = true;
    this.castleRepairButton.setAttribute("aria-disabled", "true");
    this.castleRepairButton.setAttribute("aria-label", "Repair castle ability unavailable.");
    this.castleStatus = document.createElement("span");
    this.castleStatus.className = "castle-status";
    this.castleStatus.setAttribute("role", "status");
    this.castleStatus.setAttribute("aria-live", "polite");
    const prefersCondensedLists = this.prefersCondensedHudLists();
    this.castlePassivesSection = this.createCondensedSection(
      {
        title: "Castle passives",
        listClass: "castle-passives",
        ariaLabel: "Active castle passive buffs",
        collapsedByDefault: prefersCondensedLists
      },
      "hud-passives"
    );
    this.castlePassives = this.castlePassivesSection.list;
    this.castleGoldEventsSection = this.createCondensedSection(
      {
        title: "Recent gold events",
        listClass: "castle-gold-events",
        ariaLabel: "Recent gold events",
        collapsedByDefault: prefersCondensedLists
      },
      "hud-gold-events"
    );
    this.castleGoldEvents = this.castleGoldEventsSection.list;
    this.castleBenefits = document.createElement("ul");
    this.castleBenefits.className = "castle-benefits";
    this.castleBenefits.dataset.visible = "false";
    this.castleBenefits.hidden = true;
    this.castleBenefits.setAttribute("aria-label", "Upcoming castle upgrade benefits");
    const benefitsId = `hud-castle-benefits-${++hudInstanceCounter}`;
    this.castleBenefits.id = benefitsId;
    this.castleButton.setAttribute("aria-controls", benefitsId);
    this.castleButton.setAttribute("aria-expanded", "false");
    const castleWrap = document.createElement("div");
    castleWrap.className = "castle-upgrade";
    castleWrap.appendChild(this.castleButton);
    castleWrap.appendChild(this.castleRepairButton);
    castleWrap.appendChild(this.castleStatus);
    castleWrap.appendChild(this.castlePassivesSection.container);
    castleWrap.appendChild(this.castleGoldEventsSection.container);
    castleWrap.appendChild(this.castleBenefits);
    this.upgradePanel.appendChild(castleWrap);

    this.castleButton.addEventListener("click", () => {
      this.callbacks.onCastleUpgrade();
    });
    this.castleRepairButton.addEventListener("click", () => {
      this.callbacks.onCastleRepair();
    });
    if (this.fullscreenButton && typeof this.callbacks.onFullscreenToggle === "function") {
      this.fullscreenButton.addEventListener("click", () => {
        const next = this.fullscreenButton?.dataset.active === "true" ? false : true;
        this.callbacks.onFullscreenToggle?.(next);
      });
    }

    this.createTurretControls();
  }

  focusTypingInput(): void {
    this.typingInput.focus();
  }

  setCapsLockWarning(visible: boolean): void {
    if (!this.capsLockWarning) return;
    this.capsLockWarning.dataset.visible = visible ? "true" : "false";
    this.capsLockWarning.setAttribute("aria-hidden", visible ? "false" : "true");
  }

  setFullscreenAvailable(available: boolean): void {
    if (!this.fullscreenButton) return;
    this.fullscreenButton.disabled = !available;
    this.fullscreenButton.setAttribute("aria-disabled", available ? "false" : "true");
    if (!available) {
      this.fullscreenButton.textContent = "Fullscreen Unavailable";
    }
  }

  setFullscreenActive(active: boolean): void {
    if (!this.fullscreenButton) return;
    this.fullscreenButton.dataset.active = active ? "true" : "false";
    this.fullscreenButton.setAttribute("aria-pressed", active ? "true" : "false");
    this.fullscreenButton.textContent = active ? "Exit Fullscreen" : "Fullscreen";
  }

  showShortcutOverlay(): void {
    this.setShortcutOverlayVisible(true);
  }

  hideShortcutOverlay(): void {
    this.setShortcutOverlayVisible(false);
  }

  setVirtualKeyboardEnabled(enabled: boolean): void {
    this.virtualKeyboardEnabled = Boolean(enabled);
    if (this.virtualKeyboard && !this.virtualKeyboardEnabled) {
      this.virtualKeyboard.setVisible(false);
      this.virtualKeyboard.setActiveWord(null, 0);
    }
  }

  toggleShortcutOverlay(): void {
    this.setShortcutOverlayVisible(!this.isShortcutOverlayVisible());
  }

  isShortcutOverlayVisible(): boolean {
    if (!this.shortcutOverlay) return false;
    return this.shortcutOverlay.container.dataset.visible === "true";
  }

  showRoadmapOverlay(): void {
    this.setRoadmapOverlayVisible(true);
  }

  hideRoadmapOverlay(): void {
    this.setRoadmapOverlayVisible(false);
  }

  toggleRoadmapOverlay(): void {
    this.setRoadmapOverlayVisible(!this.isRoadmapOverlayVisible());
  }

  isRoadmapOverlayVisible(): boolean {
    if (!this.roadmapOverlay) return false;
    return this.roadmapOverlay.container.dataset.visible === "true";
  }

  showOptionsOverlay(): void {
    this.setOptionsOverlayVisible(true);
  }

  hideOptionsOverlay(): void {
    this.setOptionsOverlayVisible(false);
  }

  isOptionsOverlayVisible(): boolean {
    if (!this.optionsOverlay) return false;
    return this.optionsOverlay.container.dataset.visible === "true";
  }

  syncOptionsOverlayState(state: {
    soundEnabled: boolean;
    soundVolume: number;
    soundIntensity: number;
    diagnosticsVisible: boolean;
    lowGraphicsEnabled: boolean;
    virtualKeyboardEnabled?: boolean;
    reducedMotionEnabled: boolean;
    checkeredBackgroundEnabled: boolean;
    readableFontEnabled: boolean;
    dyslexiaFontEnabled: boolean;
    colorblindPaletteEnabled: boolean;
    hudFontScale: number;
    defeatAnimationMode: DefeatAnimationPreference;
    telemetry?: {
      available: boolean;
      checked: boolean;
      disabled?: boolean;
    };
    turretFeatures?: {
      crystalPulse?: {
        enabled: boolean;
        disabled?: boolean;
      };
    };
    eliteAffixes?: {
      enabled: boolean;
      disabled?: boolean;
    };
  }): void {
    if (!this.optionsOverlay) return;
    this.syncingOptionToggles = true;
    this.optionsOverlay.soundToggle.checked = state.soundEnabled;
    this.optionsOverlay.soundVolumeSlider.disabled = !state.soundEnabled;
    this.optionsOverlay.soundVolumeSlider.setAttribute(
      "aria-disabled",
      state.soundEnabled ? "false" : "true"
    );
    this.optionsOverlay.soundVolumeSlider.tabIndex = state.soundEnabled ? 0 : -1;
    this.optionsOverlay.soundVolumeSlider.value = state.soundVolume.toString();
    this.updateSoundVolumeDisplay(state.soundVolume);
    this.optionsOverlay.soundIntensitySlider.disabled = !state.soundEnabled;
    this.optionsOverlay.soundIntensitySlider.setAttribute(
      "aria-disabled",
      state.soundEnabled ? "false" : "true"
    );
    this.optionsOverlay.soundIntensitySlider.tabIndex = state.soundEnabled ? 0 : -1;
    this.optionsOverlay.soundIntensitySlider.value = state.soundIntensity.toString();
    this.updateSoundIntensityDisplay(state.soundIntensity);
    this.optionsOverlay.diagnosticsToggle.checked = state.diagnosticsVisible;
    if (this.optionsOverlay.virtualKeyboardToggle && state.virtualKeyboardEnabled !== undefined) {
      this.optionsOverlay.virtualKeyboardToggle.checked = state.virtualKeyboardEnabled;
    }
    if (this.optionsOverlay.lowGraphicsToggle) {
      this.optionsOverlay.lowGraphicsToggle.checked = state.lowGraphicsEnabled;
    }
    this.optionsOverlay.reducedMotionToggle.checked = state.reducedMotionEnabled;
    this.optionsOverlay.checkeredBackgroundToggle.checked = state.checkeredBackgroundEnabled;
    this.optionsOverlay.readableFontToggle.checked = state.readableFontEnabled;
    this.optionsOverlay.dyslexiaFontToggle.checked = state.dyslexiaFontEnabled;
    this.optionsOverlay.colorblindPaletteToggle.checked = state.colorblindPaletteEnabled;
    this.setSelectValue(this.optionsOverlay.fontScaleSelect, state.hudFontScale.toString());
    this.setSelectValue(
      this.optionsOverlay.defeatAnimationSelect,
      state.defeatAnimationMode ?? "auto"
    );
    this.applyTelemetryOptionState(state.telemetry);
    if (this.optionsOverlay.crystalPulseToggle) {
      const toggle = this.optionsOverlay.crystalPulseToggle;
      const wrapper =
        this.optionsOverlay.crystalPulseWrapper ??
        (toggle.parentElement instanceof HTMLElement ? toggle.parentElement : undefined);
      const featureState = state.turretFeatures?.crystalPulse;
      const enabled = Boolean(featureState?.enabled);
      const disabled = Boolean(featureState?.disabled);
      toggle.checked = enabled;
      toggle.disabled = disabled;
      toggle.setAttribute("aria-disabled", disabled ? "true" : "false");
      toggle.tabIndex = disabled ? -1 : 0;
      if (wrapper) {
        wrapper.dataset.disabled = disabled ? "true" : "false";
      }
    }
    if (this.optionsOverlay.eliteAffixToggle) {
      const toggle = this.optionsOverlay.eliteAffixToggle;
      const wrapper =
        this.optionsOverlay.eliteAffixWrapper ??
        (toggle.parentElement instanceof HTMLElement ? toggle.parentElement : undefined);
      const featureState = state.eliteAffixes;
      const enabled = Boolean(featureState?.enabled);
      const disabled = Boolean(featureState?.disabled);
      toggle.checked = enabled;
      toggle.disabled = disabled;
      toggle.setAttribute("aria-disabled", disabled ? "true" : "false");
      toggle.tabIndex = disabled ? -1 : 0;
      if (wrapper) {
        wrapper.dataset.disabled = disabled ? "true" : "false";
      }
    }
    this.syncingOptionToggles = false;
    if (this.lastState) {
      this.updateCastleBonusHint(this.lastState);
    }
  }

  setTurretAvailability(availability: Record<string, boolean>): void {
    const next: Record<string, boolean> = {};
    for (const typeId of Object.keys(this.config.turretArchetypes)) {
      next[typeId] = availability?.[typeId] !== false;
    }
    this.availableTurretTypes = next;
    this.applyTurretAvailabilityToControls();
  }

  setTurretDowngradeEnabled(enabled: boolean): void {
    if (this.turretDowngradeEnabled === enabled) {
      return;
    }
    this.turretDowngradeEnabled = enabled;
    if (this.lastState) {
      this.updateTurretControls(this.lastState);
    } else if (!enabled) {
      for (const controls of this.slotControls.values()) {
        if (controls.downgradeButton) {
          controls.downgradeButton.style.display = "none";
          controls.downgradeButton.setAttribute("aria-hidden", "true");
          controls.downgradeButton.disabled = true;
          controls.downgradeButton.tabIndex = -1;
          controls.downgradeButton.onclick = null;
        }
      }
    }
  }

  showWaveScorecard(data: WaveScorecardData): void {
    if (!this.waveScorecard) return;
    this.renderWaveScorecard(data);
    this.setWaveScorecardVisible(true);
  }

  hideWaveScorecard(): void {
    this.setWaveScorecardVisible(false);
  }

  isWaveScorecardVisible(): boolean {
    if (!this.waveScorecard) return false;
    return this.waveScorecard.container.dataset.visible === "true";
  }

  update(
    state: GameState,
    upcoming: WaveSpawnPreview[],
    options: { colorBlindFriendly?: boolean; tutorialCompleted?: boolean; loreUnlocked?: number } = {}
  ): void {
    this.lastState = state;
    this.updateCastleBonusHint(state);
    if (this.analyticsViewer) {
      const modeValue = state.mode === "practice" ? "practice" : "campaign";
      this.analyticsViewer.container.dataset.mode = modeValue;
      this.analyticsViewer.container.dataset.practice =
        state.mode === "practice" ? "true" : "false";
    }
    this.updateShieldTelemetry(upcoming);
    this.updateAffixTelemetry(upcoming);
    this.refreshRoadmap(state, options);
    const hpRatio = Math.max(0, state.castle.health / state.castle.maxHealth);
    (this.healthBar as HTMLElement).style.width = `${hpRatio * 100}%`;
    const gold = Math.floor(state.resources.gold);
    this.goldLabel.textContent = gold.toString();
    this.handleGoldDelta(gold);
    this.typingInput.value = state.typing.buffer;

    const activeEnemy = state.typing.activeEnemyId
      ? state.enemies.find((enemy) => enemy.id === state.typing.activeEnemyId)
      : null;
    if (activeEnemy) {
      const typed = activeEnemy.word.slice(0, activeEnemy.typed);
      const remaining = activeEnemy.word.slice(activeEnemy.typed);
      const shielded = Boolean(activeEnemy.shield && activeEnemy.shield.current > 0);
      const segments = `<span class="word-text"><span class="typed">${typed}</span><span>${remaining}</span></span>`;
      if (shielded) {
        this.activeWord.innerHTML = `<span class="word-status shielded" role="status" aria-live="polite">🛡 Shielded</span>${segments}`;
        this.activeWord.dataset.shielded = "true";
      } else {
        this.activeWord.innerHTML = segments;
        delete this.activeWord.dataset.shielded;
      }
    } else {
      this.activeWord.innerHTML = "";
      delete this.activeWord.dataset.shielded;
    }

    if (this.virtualKeyboard) {
      if (this.virtualKeyboardEnabled && activeEnemy?.word) {
        this.virtualKeyboard.setVisible(true);
        this.virtualKeyboard.setActiveWord(activeEnemy.word, activeEnemy.typed);
      } else {
        this.virtualKeyboard.setActiveWord(null, 0);
        this.virtualKeyboard.setVisible(false);
      }
    }

    this.updateCastleControls(state);
    this.updateTurretControls(state);
    this.updateCombo(
      state.typing.combo,
      state.typing.comboWarning,
      state.typing.comboTimer,
      state.typing.accuracy
    );
    this.updateEvacuation(state);
    this.renderWavePreview(upcoming, options.colorBlindFriendly);
    this.applyTutorialSlotLock(state);
    const history = state.analytics.waveHistory?.length
      ? state.analytics.waveHistory
      : state.analytics.waveSummaries;
    this.refreshAnalyticsViewer(history, {
      timeToFirstTurret: state.analytics.timeToFirstTurret ?? null
    });
  }

  showCastleMessage(message: string): void {
    this.castleStatus.textContent = message;
    this.castleStatus.dataset.messageActive = "true";
    setTimeout(() => {
      this.castleStatus.textContent = "";
      delete this.castleStatus.dataset.messageActive;
    }, 1800);
  }

  showSlotMessage(slotId: string, message: string): void {
    const slot = this.slotControls.get(slotId);
    if (!slot) return;
    slot.status.textContent = message;
    slot.status.dataset.messageActive = "true";
    setTimeout(() => {
      slot.status.textContent = "";
      delete slot.status.dataset.messageActive;
    }, 2000);
  }

  appendLog(message: string): void {
    this.logEntries.unshift(message);
    if (this.logEntries.length > this.logLimit) {
      this.logEntries.length = this.logLimit;
    }
    this.renderLog();
  }

  setTutorialMessage(message: string | null, highlight?: boolean): void {
    const banner = this.tutorialBanner;
    if (!banner) return;
    const { container, message: content } = banner;
    const condensed = this.shouldCondenseTutorialBanner();
    const wasVisible = container.dataset.visible === "true";
    if (!message) {
      container.dataset.visible = "false";
      content.textContent = "";
      delete container.dataset.highlight;
      this.tutorialBannerExpanded = condensed ? false : true;
      this.refreshTutorialBannerLayout();
      return;
    }
    container.dataset.visible = "true";
    if (highlight) {
      container.dataset.highlight = "true";
    } else {
      delete container.dataset.highlight;
    }
    content.textContent = message;
    if (!wasVisible) {
      this.tutorialBannerExpanded = condensed ? false : true;
    } else if (!condensed) {
      this.tutorialBannerExpanded = true;
    }
    this.refreshTutorialBannerLayout();
  }

  private updateCastleBonusHint(state: GameState): void {
    if (!this.optionsCastleBonus) return;
    const container = this.optionsCastleBonus;
    const currentLevelConfig =
      this.config.castleLevels.find((level) => level.level === state.castle.level) ?? null;
    const percent = Math.round(Math.max(0, (state.castle.goldBonusPercent ?? 0) * 100));
    let summary: string;
    if (percent > 0) {
      summary = `Enemy rewards grant +${percent}% gold thanks to your treasury.`;
    } else {
      summary = "Enemy rewards currently receive no bonus—upgrade to unlock extra gold.";
    }
    const nextLevelConfig = this.config.castleLevels.find(
      (level) => level.level === state.castle.level + 1
    );
    if (nextLevelConfig) {
      const nextPercent = Math.round(Math.max(0, (nextLevelConfig.goldBonusPercent ?? 0) * 100));
      const delta = nextPercent - percent;
      if (delta > 0) {
        summary += ` Upgrade to level ${nextLevelConfig.level} to reach +${nextPercent}% (${delta}% more).`;
      } else {
        summary += ` Upgrade to level ${nextLevelConfig.level} for additional defenses.`;
      }
    } else {
      summary += " Castle is at maximum level.";
    }
    const heading = currentLevelConfig
      ? `Castle Level ${currentLevelConfig.level}`
      : `Castle Level ${state.castle.level}`;
    container.innerHTML = `<strong>${heading}</strong>${summary}`;
    container.dataset.empty = currentLevelConfig ? "false" : "true";
    container.setAttribute("aria-hidden", "false");
    this.renderOptionsCastlePassives(state.castle.passives ?? []);
  }

  private clearWavePreviewHintTimeout(): void {
    if (this.wavePreviewHintTimeout !== null) {
      clearTimeout(this.wavePreviewHintTimeout);
      this.wavePreviewHintTimeout = null;
    }
  }

  private updateWavePreviewHint(active: boolean, message: string | null): void {
    if (!this.wavePreviewHint) return;
    if (active) {
      const trimmed = message?.trim();
      if (trimmed && trimmed.length > 0) {
        this.wavePreviewHintMessage = trimmed;
      }
      this.wavePreviewHint.textContent = this.wavePreviewHintMessage;
      this.wavePreviewHint.dataset.visible = "true";
      this.wavePreviewHint.setAttribute("aria-hidden", "false");
    } else {
      this.wavePreviewHint.dataset.visible = "false";
      this.wavePreviewHint.setAttribute("aria-hidden", "true");
      this.wavePreviewHint.textContent = "";
    }
  }

  setWavePreviewHighlight(active: boolean, message?: string | null): void {
    this.wavePreviewHintPinned = active;
    if (active) {
      this.clearWavePreviewHintTimeout();
    }
    this.wavePreview.setTutorialHighlight(active);
    this.updateWavePreviewHint(active, message ?? null);
  }

  announceEnemyTaunt(message: string, options?: { durationMs?: number }): boolean {
    if (!this.wavePreviewHint || this.wavePreviewHintPinned) {
      return false;
    }
    const trimmed = message?.trim();
    if (!trimmed) {
      return false;
    }
    this.updateWavePreviewHint(true, trimmed);
    this.clearWavePreviewHintTimeout();
    const duration = Math.max(1000, options?.durationMs ?? 5000);
    this.wavePreviewHintTimeout = setTimeout(() => {
      this.wavePreviewHintTimeout = null;
      if (this.wavePreviewHintPinned) {
        return;
      }
      this.updateWavePreviewHint(false, null);
      this.wavePreviewHintMessage = DEFAULT_WAVE_PREVIEW_HINT;
    }, duration);
    return true;
  }

  private renderWavePreview(
    entries: WaveSpawnPreview[],
    colorBlindFriendly: boolean | undefined
  ): void {
    this.lastWavePreviewEntries = entries;
    this.lastWavePreviewColorBlind = Boolean(colorBlindFriendly);
    const selected = this.syncEnemyBioSelection(entries);
    this.wavePreview.render(entries, {
      colorBlindFriendly: this.lastWavePreviewColorBlind,
      selectedTierId: selected,
      onSelect: (tierId) => this.handleEnemyBioSelect(tierId)
    });
    this.renderEnemyBiography(selected);
  }

  private handleEnemyBioSelect(tierId: string): void {
    if (!tierId) return;
    this.selectedEnemyBioId = tierId;
    this.renderEnemyBiography(tierId);
    if (this.lastWavePreviewEntries.length > 0) {
      this.wavePreview.render(this.lastWavePreviewEntries, {
        colorBlindFriendly: this.lastWavePreviewColorBlind,
        selectedTierId: this.selectedEnemyBioId,
        onSelect: (nextTier) => this.handleEnemyBioSelect(nextTier)
      });
    }
  }

  private syncEnemyBioSelection(entries: WaveSpawnPreview[]): string | null {
    if (!this.enemyBioCard) {
      return null;
    }
    if (!entries.length) {
      this.selectedEnemyBioId = null;
      this.renderEnemyBiography(null);
      return null;
    }
    const availableIds = new Set(entries.map((entry) => entry.tierId));
    if (this.selectedEnemyBioId && availableIds.has(this.selectedEnemyBioId)) {
      return this.selectedEnemyBioId;
    }
    const fallbackId = entries[0]?.tierId ?? null;
    this.selectedEnemyBioId = fallbackId;
    return fallbackId;
  }

  private renderEnemyBiography(tierId: string | null): void {
    if (!this.enemyBioCard) return;
    if (!tierId) {
      this.enemyBioCard.container.dataset.visible = "false";
      this.enemyBioCard.container.setAttribute("aria-hidden", "true");
      return;
    }
    const tierConfig = this.config.enemyTiers[tierId];
    const bio = getEnemyBiography(tierId, tierConfig);
    this.enemyBioCard.title.textContent = bio.name;
    this.enemyBioCard.role.textContent = bio.role;
    this.enemyBioCard.danger.textContent = bio.danger;
    this.enemyBioCard.description.textContent = bio.description;
    const renderList = (target: HTMLUListElement, values: string[]) => {
      target.replaceChildren();
      if (!values || values.length === 0) {
        const item = document.createElement("li");
        item.textContent = "No notes yet.";
        target.appendChild(item);
        return;
      }
      for (const value of values) {
        const item = document.createElement("li");
        item.textContent = value;
        target.appendChild(item);
      }
    };
    renderList(this.enemyBioCard.abilities, bio.abilities);
    renderList(this.enemyBioCard.tips, bio.tips);
    this.enemyBioCard.container.dataset.visible = "true";
    this.enemyBioCard.container.setAttribute("aria-hidden", "false");
  }

  setSlotTutorialLock(lock: TutorialSlotLock): void {
    this.tutorialSlotLock = lock;
    if (this.lastState) {
      this.applyTutorialSlotLock(this.lastState);
    }
  }

  clearSlotTutorialLock(): void {
    this.tutorialSlotLock = null;
    if (this.lastState) {
      this.updateTurretControls(this.lastState);
      this.applyTutorialSlotLock(this.lastState);
    }
  }

  showTutorialSummary(data: TutorialSummaryData, handlers: TutorialSummaryHandlers): void {
    if (!this.tutorialSummary) return;
    this.tutorialSummaryHandlers = handlers;
    const container = this.tutorialSummary.container;
    container.dataset.visible = "true";

    const stats: Array<[string, string]> = [
      ["accuracy", `Accuracy: ${(data.accuracy * 100).toFixed(1)}%`],
      ["combo", `Best Combo: x${Math.max(1, Math.floor(data.bestCombo ?? 0))}`],
      ["breaches", `Breaches sustained: ${data.breaches}`],
      ["gold", `Gold remaining: ${Math.max(0, Math.floor(data.gold))}g`]
    ];

    for (const [field, value] of stats) {
      const item = container.querySelector<HTMLElement>(`[data-field="${field}"]`);
      if (item) {
        item.textContent = value;
      }
    }

    this.tutorialSummary.continueBtn.onclick = () => {
      this.tutorialSummaryHandlers?.onContinue();
    };
    this.tutorialSummary.replayBtn.onclick = () => {
      this.tutorialSummaryHandlers?.onReplay();
    };
  }

  hideTutorialSummary(): void {
    if (!this.tutorialSummary) return;
    this.tutorialSummary.container.dataset.visible = "false";
    this.tutorialSummary.continueBtn.onclick = null;
    this.tutorialSummary.replayBtn.onclick = null;
    this.tutorialSummaryHandlers = null;
  }

  private getCastleUpgradeBenefits(
    currentConfig: CastleLevelConfig | null,
    nextConfig: CastleLevelConfig | null
  ): string[] {
    if (!currentConfig || !nextConfig) {
      return [];
    }
    const benefits: string[] = [];
    const hpDelta = nextConfig.maxHealth - currentConfig.maxHealth;
    if (hpDelta > 0) {
      benefits.push(`+${hpDelta} HP (new max ${nextConfig.maxHealth})`);
    }
    const regenDelta = nextConfig.regenPerSecond - currentConfig.regenPerSecond;
    if (regenDelta > 0.001) {
      benefits.push(`+${regenDelta.toFixed(1)} HP/s regen`);
    }
    const armorDelta = nextConfig.armor - currentConfig.armor;
    if (armorDelta > 0) {
      benefits.push(`+${armorDelta} armor`);
    }
    const goldBonusDelta = nextConfig.goldBonusPercent - currentConfig.goldBonusPercent;
    if (goldBonusDelta > 0.0001) {
      const deltaPercent = Math.round(goldBonusDelta * 100);
      const totalPercent = Math.round((nextConfig.goldBonusPercent ?? 0) * 100);
      benefits.push(`+${deltaPercent}% gold from enemy rewards (total ${totalPercent}%)`);
    }
    const slotDelta = nextConfig.unlockSlots - currentConfig.unlockSlots;
    if (slotDelta > 0) {
      benefits.push(`Unlocks ${slotDelta} additional turret slot${slotDelta > 1 ? "s" : ""}`);
    }
    return benefits;
  }

  private renderCastlePassives(passives: CastlePassive[]): void {
    const list = this.castlePassives;
    list.replaceChildren();
    if (!passives.length) {
      this.setCondensedSectionVisibility(this.castlePassivesSection, false);
      this.updateCondensedSectionSummary(this.castlePassivesSection, "No passives");
      return;
    }
    this.setCondensedSectionVisibility(this.castlePassivesSection, true);
    for (const passive of passives) {
      list.appendChild(this.createPassiveListItem(passive));
    }
    const summary = passives.length === 1 ? "1 passive" : `${passives.length} passives`;
    this.updateCondensedSectionSummary(this.castlePassivesSection, summary);
    this.applyPassiveHighlight();
  }

  private renderCastleGoldEvents(events: GoldEvent[], currentTime: number): void {
    const list = this.castleGoldEvents;
    list.replaceChildren();
    if (!events.length) {
      this.setCondensedSectionVisibility(this.castleGoldEventsSection, false);
      this.updateCondensedSectionSummary(this.castleGoldEventsSection, "No recent events");
      return;
    }
    this.setCondensedSectionVisibility(this.castleGoldEventsSection, true);
    for (const event of events) {
      const item = document.createElement("li");
      item.className = "gold-event-entry";
      const deltaValue =
        typeof event.delta === "number" && Number.isFinite(event.delta)
          ? Math.round(event.delta)
          : null;
      const goldValue =
        typeof event.gold === "number" && Number.isFinite(event.gold)
          ? Math.round(event.gold)
          : null;
      const timestamp =
        typeof event.timestamp === "number" && Number.isFinite(event.timestamp)
          ? event.timestamp
          : null;
      const age =
        timestamp !== null && Number.isFinite(currentTime)
          ? Math.max(0, currentTime - timestamp)
          : null;
      if (deltaValue !== null) {
        item.dataset.deltaSign =
          deltaValue > 0 ? "positive" : deltaValue < 0 ? "negative" : "neutral";
      } else {
        item.dataset.deltaSign = "neutral";
      }
      const parts: string[] = [];
      if (deltaValue !== null) {
        const prefix = deltaValue >= 0 ? "+" : "";
        parts.push(`${prefix}${deltaValue}g`);
      } else {
        parts.push("??g");
      }
      if (goldValue !== null) {
        parts.push(`→ ${goldValue}g`);
      }
      if (timestamp !== null) {
        parts.push(`@ ${timestamp.toFixed(1)}s`);
      }
      if (age !== null) {
        parts.push(`(${age.toFixed(1)}s ago)`);
      }
      item.textContent = parts.join(" ");
      list.appendChild(item);
    }
    const descriptor = events.length === 1 ? "1 recent event" : `${events.length} recent events`;
    const latestDelta = events[0];
    const latestLabel =
      typeof latestDelta?.delta === "number" && Number.isFinite(latestDelta.delta)
        ? `${latestDelta.delta > 0 ? "+" : ""}${Math.round(latestDelta.delta)}g`
        : null;
    const summary = latestLabel ? `${descriptor} (last ${latestLabel})` : descriptor;
    this.updateCondensedSectionSummary(this.castleGoldEventsSection, summary);
  }

  private renderOptionsCastlePassives(passives: CastlePassive[]): void {
    if (!this.optionsCastlePassives) return;
    const list = this.optionsCastlePassives;
    list.replaceChildren();
    if (!passives.length) {
      const item = document.createElement("li");
      item.className = "passive-empty";
      item.textContent = "No passive buffs unlocked yet.";
      list.appendChild(item);
      if (this.optionsPassivesSection) {
        this.optionsPassivesSection.hidden = false;
      }
      this.updateOptionsPassivesSummary("No passives");
      this.setOptionsPassivesCollapsed(false);
      return;
    }
    for (const passive of passives) {
      list.appendChild(this.createPassiveListItem(passive, { includeDelta: true }));
    }
    if (this.optionsPassivesSection) {
      this.optionsPassivesSection.hidden = false;
    }
    const summary = passives.length === 1 ? "1 passive" : `${passives.length} passives`;
    this.updateOptionsPassivesSummary(summary);
    this.setOptionsPassivesCollapsed(this.optionsPassivesCollapsed, { silent: true });
    this.applyPassiveHighlight();
  }

  private formatCastlePassive(
    passive: CastlePassive,
    options: { includeDelta?: boolean } = {}
  ): string {
    const includeDelta = options.includeDelta ?? false;
    switch (passive.id) {
      case "regen": {
        const total = passive.total.toFixed(1);
        const delta = passive.delta.toFixed(1);
        return includeDelta ? `Regen ${total} HP/s (+${delta})` : `Regen ${total} HP/s`;
      }
      case "armor": {
        const total = passive.total.toFixed(0);
        const delta = passive.delta.toFixed(0);
        const prefix = `+${total} armor`;
        return includeDelta && passive.delta > 0 ? `${prefix} (+${delta})` : prefix;
      }
      case "gold": {
        const total = Math.round(passive.total * 100);
        const delta = Math.round(passive.delta * 100);
        return includeDelta && passive.delta > 0
          ? `+${total}% gold from rewards (+${delta}%)`
          : `+${total}% gold from rewards`;
      }
      default:
        return "Passive upgrade unlocked";
    }
  }

  private createPassiveListItem(
    passive: CastlePassive,
    options: { includeDelta?: boolean } = {}
  ): HTMLLIElement {
    const item = document.createElement("li");
    const icon = document.createElement("span");
    const label = document.createElement("span");
    const passiveId = passive.id ?? "generic";
    item.dataset.passiveId = passiveId;
    const iconMeta = PASSIVE_ICON_MAP[passiveId] ?? PASSIVE_ICON_MAP.generic;
    icon.className = `passive-icon passive-icon--${passiveId}`;
    icon.setAttribute("role", "img");
    icon.setAttribute("aria-label", iconMeta.label);
    icon.title = iconMeta.label;
    label.className = "passive-label";
    label.textContent = this.formatCastlePassive(passive, options);
    item.appendChild(icon);
    item.appendChild(label);
    return item;
  }

  setPassiveHighlight(
    passiveId: string | null,
    options: { autoExpand?: boolean; scrollIntoView?: boolean } = {}
  ): void {
    this.passiveHighlightId = passiveId;
    if (passiveId) {
      if (options.autoExpand !== false) {
        if (this.castlePassivesSection) {
          this.setCondensedSectionCollapsed(this.castlePassivesSection, false, {
            silent: true,
            sectionId: "hud-passives"
          });
        }
        if (this.optionsCastlePassives) {
          this.setOptionsPassivesCollapsed(false, { silent: true });
        }
      }
    }
    this.applyPassiveHighlight(options);
  }

  private applyPassiveHighlight(options: { scrollIntoView?: boolean } = {}): void {
    const highlight = this.passiveHighlightId;
    const targets: HTMLUListElement[] = [];
    if (this.castlePassives) targets.push(this.castlePassives);
    if (this.optionsCastlePassives) targets.push(this.optionsCastlePassives);
    for (const list of targets) {
      const items = Array.from(list.querySelectorAll<HTMLLIElement>("li"));
      for (const item of items) {
        const isMatch = Boolean(highlight && item.dataset.passiveId === highlight);
        if (isMatch) {
          item.classList.add("passive-item--highlight");
          if (options.scrollIntoView && typeof item.scrollIntoView === "function") {
            item.scrollIntoView({ block: "nearest" });
          }
        } else {
          item.classList.remove("passive-item--highlight");
        }
      }
    }
  }

  private updateOptionsPassivesSummary(summary: string): void {
    if (this.optionsPassivesSummary) {
      this.optionsPassivesSummary.textContent = summary;
    }
    this.applyOptionsPassivesToggleLabel();
  }

  private applyOptionsPassivesToggleLabel(): void {
    if (!this.optionsPassivesToggle) return;
    const summaryText = this.optionsPassivesSummary?.textContent?.trim();
    if (this.optionsPassivesCollapsed) {
      this.optionsPassivesToggle.textContent = summaryText
        ? `Show Active Passives (${summaryText})`
        : "Show Active Passives";
    } else {
      this.optionsPassivesToggle.textContent = "Hide Active Passives";
    }
  }

  private setOptionsPassivesCollapsed(
    collapsed: boolean,
    options: { silent?: boolean } = {}
  ): void {
    if (!this.optionsCastlePassives) {
      this.optionsPassivesCollapsed = collapsed;
      return;
    }
    this.optionsPassivesCollapsed = collapsed;
    if (this.optionsPassivesSection) {
      this.optionsPassivesSection.dataset.collapsed = collapsed ? "true" : "false";
    }
    if (this.optionsPassivesBody) {
      this.optionsPassivesBody.hidden = collapsed;
    }
    this.optionsCastlePassives.hidden = collapsed;
    this.optionsCastlePassives.dataset.visible = collapsed ? "false" : "true";
    if (this.optionsPassivesToggle) {
      this.optionsPassivesToggle.setAttribute("aria-expanded", collapsed ? "false" : "true");
    }
    this.applyOptionsPassivesToggleLabel();
    if (!options.silent) {
      this.callbacks.onCollapsePreferenceChange?.({
        optionsPassivesCollapsed: collapsed
      });
    }
  }

  private createCondensedSection(
    options: {
      title: string;
      listClass: string;
      ariaLabel: string;
      collapsedByDefault?: boolean;
    },
    sectionId: HudCondensedSectionId
  ): CondensedSection {
    const container = document.createElement("div");
    container.className = "hud-condensed-section";
    const header = document.createElement("div");
    header.className = "hud-condensed-header";
    const title = document.createElement("span");
    title.className = "hud-condensed-title";
    title.textContent = options.title;
    const summary = document.createElement("span");
    summary.className = "hud-condensed-summary";
    summary.textContent = "";
    const toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "hud-condensed-toggle";
    const body = document.createElement("div");
    body.className = "hud-condensed-body";
    const listId = `${options.listClass}-${++hudInstanceCounter}`;
    const list = document.createElement("ul");
    list.className = options.listClass;
    list.id = listId;
    list.setAttribute("aria-label", options.ariaLabel);
    header.append(title, summary, toggle);
    body.appendChild(list);
    container.append(header, body);
    const section: CondensedSection = {
      container,
      body,
      list,
      summary,
      toggle,
      title: options.title,
      collapsed: Boolean(options.collapsedByDefault)
    };
    toggle.setAttribute("aria-controls", listId);
    toggle.addEventListener("click", () => {
      this.setCondensedSectionCollapsed(section, !section.collapsed, { sectionId });
    });
    this.setCondensedSectionCollapsed(section, section.collapsed, {
      silent: true,
      sectionId
    });
    this.updateCondensedSectionSummary(section, "");
    this.setCondensedSectionVisibility(section, false);
    return section;
  }

  private setCondensedSectionCollapsed(
    section: CondensedSection,
    collapsed: boolean,
    options: { silent?: boolean; sectionId?: HudCondensedSectionId } = {}
  ): void {
    section.collapsed = collapsed;
    section.container.dataset.collapsed = collapsed ? "true" : "false";
    section.toggle.setAttribute("aria-expanded", collapsed ? "false" : "true");
    const summaryText = section.summary.textContent?.trim();
    if (collapsed) {
      section.toggle.textContent = summaryText
        ? `Show ${section.title} (${summaryText})`
        : `Show ${section.title}`;
    } else {
      section.toggle.textContent = `Hide ${section.title}`;
    }
    if (!options.silent) {
      const patch: HudCollapsePreferenceUpdate = {};
      if (options.sectionId === "hud-passives") {
        patch.hudCastlePassivesCollapsed = collapsed;
      } else if (options.sectionId === "hud-gold-events") {
        patch.hudGoldEventsCollapsed = collapsed;
      }
      if (Object.keys(patch).length > 0) {
        this.callbacks.onCollapsePreferenceChange?.(patch);
      }
    }
  }

  private updateCondensedSectionSummary(section: CondensedSection, summary: string): void {
    section.summary.textContent = summary;
    if (section.collapsed) {
      this.setCondensedSectionCollapsed(section, section.collapsed);
    }
  }

  private setCondensedSectionVisibility(section: CondensedSection, visible: boolean): void {
    section.container.hidden = !visible;
    if (!visible) {
      section.container.setAttribute("aria-hidden", "true");
    } else {
      section.container.removeAttribute("aria-hidden");
    }
    section.list.dataset.visible = visible ? "true" : "false";
    section.list.hidden = !visible;
  }

  applyCollapsePreferences(
    prefs: HudCollapsePreferenceUpdate,
    options: { silent?: boolean; fallbackToPreferred?: boolean } = {}
  ): void {
    const shouldFallback = options.fallbackToPreferred ?? false;
    if (this.castlePassivesSection) {
      const value = prefs.hudCastlePassivesCollapsed;
      if (typeof value === "boolean") {
        this.setCondensedSectionCollapsed(this.castlePassivesSection, value, {
          silent: options.silent,
          sectionId: "hud-passives"
        });
      } else if (shouldFallback) {
        this.setCondensedSectionCollapsed(
          this.castlePassivesSection,
          this.prefersCondensedHudLists(),
          { silent: true, sectionId: "hud-passives" }
        );
      }
    }
    if (this.castleGoldEventsSection) {
      const value = prefs.hudGoldEventsCollapsed;
      if (typeof value === "boolean") {
        this.setCondensedSectionCollapsed(this.castleGoldEventsSection, value, {
          silent: options.silent,
          sectionId: "hud-gold-events"
        });
      } else if (shouldFallback) {
        this.setCondensedSectionCollapsed(
          this.castleGoldEventsSection,
          this.prefersCondensedHudLists(),
          { silent: true, sectionId: "hud-gold-events" }
        );
      }
    }
    if (this.optionsCastlePassives) {
      const value = prefs.optionsPassivesCollapsed;
      if (typeof value === "boolean") {
        this.setOptionsPassivesCollapsed(value, { silent: options.silent });
      } else if (shouldFallback) {
        this.setOptionsPassivesCollapsed(this.optionsPassivesDefaultCollapsed, { silent: true });
      }
    }
  }

  getCondensedState(): HudCondensedStateSnapshot {
    const compactHeightActive =
      typeof document !== "undefined" &&
      typeof document.body !== "undefined" &&
      document.body.dataset.compactHeight === "true";
    return {
      tutorialBannerCondensed: this.shouldCondenseTutorialBanner(),
      tutorialBannerExpanded: this.tutorialBannerExpanded,
      hudCastlePassivesCollapsed: this.castlePassivesSection?.collapsed ?? null,
      hudGoldEventsCollapsed: this.castleGoldEventsSection?.collapsed ?? null,
      optionsPassivesCollapsed:
        typeof this.optionsPassivesCollapsed === "boolean" ? this.optionsPassivesCollapsed : null,
      compactHeight: compactHeightActive,
      prefersCondensedLists: this.prefersCondensedHudLists()
    };
  }

  private prefersCondensedHudLists(): boolean {
    return (
      this.matchesMediaQuery("(max-width: 768px)") ||
      this.matchesMediaQuery("(max-height: 540px)")
    );
  }

  private initializeViewportListeners(): void {
    if (typeof window === "undefined") {
      this.refreshTutorialBannerLayout();
      return;
    }
    const handleResize = () => this.refreshTutorialBannerLayout();
    if (typeof window.addEventListener === "function") {
      try {
        window.addEventListener("resize", handleResize, { passive: true });
      } catch {
        window.addEventListener("resize", handleResize);
      }
    }
    if (typeof window.matchMedia === "function") {
      try {
        const orientationQuery = window.matchMedia("(orientation: landscape)");
        const handleOrientation = () => this.refreshTutorialBannerLayout();
        if (typeof orientationQuery.addEventListener === "function") {
          orientationQuery.addEventListener("change", handleOrientation);
        } else if (typeof orientationQuery.addListener === "function") {
          orientationQuery.addListener(handleOrientation);
        }
      } catch {
        // ignore matchMedia failures
      }
    }
    this.refreshTutorialBannerLayout();
  }

  private refreshTutorialBannerLayout(): void {
    this.updateCompactHeightDataset();
    const banner = this.tutorialBanner;
    if (!banner) {
      return;
    }
    const condensed = this.shouldCondenseTutorialBanner();
    const container = banner.container;
    const toggle = banner.toggle ?? null;
    if (!condensed) {
      container.dataset.condensed = "false";
      container.dataset.expanded = "true";
      this.tutorialBannerExpanded = true;
      if (toggle) {
        toggle.hidden = true;
        toggle.textContent = "Show full tip";
        toggle.setAttribute("aria-expanded", "true");
        toggle.setAttribute("aria-label", "Show full tutorial tip");
      }
      return;
    }
    container.dataset.condensed = "true";
    container.dataset.expanded = this.tutorialBannerExpanded ? "true" : "false";
    if (toggle) {
      const expanded = this.tutorialBannerExpanded;
      const visible = container.dataset.visible === "true";
      toggle.hidden = !visible;
      toggle.textContent = expanded ? "Hide tutorial tip" : "Show full tip";
      toggle.setAttribute("aria-expanded", expanded ? "true" : "false");
      toggle.setAttribute(
        "aria-label",
        expanded ? "Hide full tutorial tip" : "Show full tutorial tip"
      );
    }
  }

  private updateCompactHeightDataset(): void {
    if (typeof document === "undefined" || !document.body) {
      return;
    }
    if (this.shouldCondenseTutorialBanner()) {
      document.body.dataset.compactHeight = "true";
    } else {
      delete document.body.dataset.compactHeight;
    }
  }

  private shouldCondenseTutorialBanner(): boolean {
    return this.matchesMediaQuery("(max-height: 540px)");
  }

  private matchesMediaQuery(query: string): boolean {
    if (typeof window === "undefined" || typeof window.matchMedia !== "function") {
      return false;
    }
    try {
      return window.matchMedia(query).matches;
    } catch {
      return false;
    }
  }

  private renderOptionsCastleBenefits(
    benefits: string[],
    nextConfig: CastleLevelConfig | null
  ): void {
    if (!this.optionsCastleBenefits) return;
    const list = this.optionsCastleBenefits;
    list.replaceChildren();
    if (!nextConfig || benefits.length === 0) {
      const item = document.createElement("li");
      item.textContent = nextConfig
        ? "No upgrade benefits available."
        : "Castle is at maximum level. Passive bonuses fully unlocked.";
      list.appendChild(item);
      return;
    }
    for (const line of benefits) {
      const item = document.createElement("li");
      item.textContent = line;
      list.appendChild(item);
    }
  }

  private updateCastleControls(state: GameState): void {
    const currentLevel = state.castle.level;
    const currentConfig = this.config.castleLevels.find((c) => c.level === currentLevel) ?? null;
    const nextConfig = this.config.castleLevels.find((c) => c.level === currentLevel + 1) ?? null;
    const passives = state.castle.passives ?? [];
    this.renderCastlePassives(passives);
    this.renderOptionsCastlePassives(passives);
    const recentGoldEvents = (state.analytics.goldEvents ?? []).slice(-3).reverse();
    this.renderCastleGoldEvents(recentGoldEvents, state.time ?? 0);

    this.castleBenefits.replaceChildren();
    this.castleBenefits.dataset.visible = "false";
    this.castleBenefits.hidden = true;
    this.castleButton.setAttribute("aria-expanded", "false");
    this.castleButton.removeAttribute("aria-describedby");
    this.castleButton.removeAttribute("title");

    if (!currentConfig) {
      this.castleButton.disabled = true;
      this.castleButton.setAttribute("aria-disabled", "true");
      this.castleButton.textContent = "Upgrade Castle";
      this.castleButton.setAttribute("aria-label", "Castle upgrade unavailable.");
      this.castleButton.title = "Castle upgrade unavailable.";
      this.updateCastleRepair(state);
      this.renderOptionsCastleBenefits([], null);
      return;
    }

    const currentBonusPercent = Math.max(
      0,
      Math.round((currentConfig.goldBonusPercent ?? 0) * 100)
    );
    const bonusNote =
      currentBonusPercent > 0
        ? `Current castle bonus: +${currentBonusPercent}% gold from enemy rewards.`
        : "";
    const appendBonusNote = (text: string): string =>
      bonusNote ? `${text ? `${text.trim()} ` : ""}${bonusNote}`.trim() : text;

    if (currentConfig.upgradeCost === null) {
      this.castleButton.disabled = true;
      this.castleButton.setAttribute("aria-disabled", "true");
      this.castleButton.textContent = "Castle Max Level";
      const message = "Castle is at maximum level.";
      const labelledMessage = appendBonusNote(message);
      this.castleButton.title = labelledMessage;
      this.castleButton.setAttribute("aria-label", labelledMessage);
      this.updateCastleRepair(state);
      this.renderOptionsCastleBenefits([], null);
      return;
    }

    const cost = currentConfig.upgradeCost;
    const canAfford = state.resources.gold >= cost;
    this.castleButton.disabled = !canAfford;
    this.castleButton.setAttribute("aria-disabled", canAfford ? "false" : "true");
    this.castleButton.textContent = `Upgrade Castle (${cost}g)`;
    let buttonLabel = `Upgrade Castle (${cost} gold)`;
    if (!canAfford) {
      buttonLabel += ". Not enough gold available.";
    }
    let finalLabel = buttonLabel;
    let tooltip = "";

    if (!nextConfig) {
      const labelled = appendBonusNote(finalLabel);
      this.castleButton.setAttribute("aria-label", labelled);
      this.castleButton.title = appendBonusNote(buttonLabel);
      this.updateCastleRepair(state);
      this.renderOptionsCastleBenefits([], null);
      return;
    }

    const benefits = this.getCastleUpgradeBenefits(currentConfig, nextConfig);

    if (benefits.length > 0) {
      this.castleBenefits.dataset.visible = "true";
      this.castleBenefits.hidden = false;
      for (const line of benefits) {
        const item = document.createElement("li");
        item.textContent = line;
        this.castleBenefits.appendChild(item);
      }
      this.castleButton.setAttribute("aria-expanded", "true");
      this.castleButton.setAttribute("aria-describedby", this.castleBenefits.id);
      const benefitSummary = benefits.join("; ");
      finalLabel = `${buttonLabel}. Next benefits: ${benefitSummary}.`;
      tooltip = `Next upgrade: ${benefitSummary}`;
    }

    finalLabel = appendBonusNote(finalLabel);
    const tooltipText = tooltip ? appendBonusNote(tooltip) : appendBonusNote(buttonLabel);

    this.castleButton.setAttribute("aria-label", finalLabel);
    this.castleButton.title = tooltipText;

    this.updateCastleRepair(state);
    this.renderOptionsCastleBenefits(benefits, nextConfig);
    if (this.optionsCastleBonus) {
      this.optionsCastleBonus.textContent =
        nextConfig && benefits.length > 0
          ? `Next upgrade unlocks ${benefits.length} bonus${benefits.length > 1 ? "es" : ""}:`
          : this.optionsCastleBonus.textContent;
    }
  }

  private updateCastleRepair(state: GameState): void {
    const repairSettings = this.config.castleRepair ?? null;

    if (!repairSettings) {
      this.castleRepairButton.hidden = true;
      this.castleRepairButton.disabled = true;
      this.castleRepairButton.setAttribute("aria-disabled", "true");
      this.castleRepairButton.setAttribute("aria-label", "Castle repair unavailable.");
      this.castleRepairButton.title = "";
      delete this.castleRepairButton.dataset.cooldown;
      return;
    }

    this.castleRepairButton.hidden = false;
    this.castleRepairButton.textContent = `Repair Castle (${repairSettings.cost}g)`;

    const cooldownRemaining = Math.max(0, state.castle.repairCooldownRemaining ?? 0);
    const missingHealth = Math.max(0, state.castle.maxHealth - state.castle.health);
    const healPreview =
      missingHealth > 0
        ? Math.min(missingHealth, repairSettings.healAmount)
        : repairSettings.healAmount;
    const cooledDown = cooldownRemaining <= 0.05;
    const hasGold = state.resources.gold >= repairSettings.cost;
    const canHeal = missingHealth > 0.5;

    const blockers: string[] = [];
    if (!hasGold) {
      blockers.push("Not enough gold");
    }
    if (!cooledDown) {
      blockers.push(`Cooldown ${cooldownRemaining.toFixed(1)}s remaining`);
    }
    if (!canHeal) {
      blockers.push("Castle already at full health");
    }

    const canRepair = blockers.length === 0;
    this.castleRepairButton.disabled = !canRepair;
    this.castleRepairButton.setAttribute("aria-disabled", canRepair ? "false" : "true");

    if (cooldownRemaining > 0.05) {
      this.castleRepairButton.dataset.cooldown = cooldownRemaining.toFixed(1);
    } else {
      delete this.castleRepairButton.dataset.cooldown;
    }

    const baseLabel = `Repair castle for ${repairSettings.cost} gold, restoring up to ${Math.round(
      healPreview
    )} health. Cooldown ${repairSettings.cooldownSeconds} seconds.`;
    const finalLabel = blockers.length > 0 ? `${baseLabel} ${blockers.join(". ")}.` : baseLabel;
    this.castleRepairButton.setAttribute("aria-label", finalLabel);

    if (blockers.length > 0) {
      this.castleRepairButton.title = blockers.join(". ");
    } else {
      this.castleRepairButton.title = `Restore up to ${Math.round(
        healPreview
      )} HP instantly. Cooldown ${repairSettings.cooldownSeconds}s.`;
    }
  }

  private updateTurretControls(state: GameState): void {
    for (const slot of state.turrets) {
      const controls = this.slotControls.get(slot.id);
      if (!controls) continue;

      controls.title.textContent = `Slot ${slot.id.replace("slot-", "")} (Lane ${slot.lane + 1})`;
      const priority = this.normalizePriority(slot.targetingPriority) ?? "first";
    this.setSelectValue(controls.prioritySelect, priority);

      if (!slot.unlocked) {
        controls.action.disabled = true;
        controls.action.textContent = "Locked";
        controls.select.disabled = true;
        controls.select.style.display = "none";
        controls.prioritySelect.disabled = true;
        controls.priorityContainer.dataset.disabled = "true";
        if (controls.downgradeButton) {
          controls.downgradeButton.style.display = "none";
          controls.downgradeButton.setAttribute("aria-hidden", "true");
          controls.downgradeButton.disabled = true;
          controls.downgradeButton.tabIndex = -1;
          controls.downgradeButton.onclick = null;
        }
        if (controls.status.dataset.messageActive !== "true") {
          controls.status.textContent = "Unlock by castle upgrade";
        }
        continue;
      }

      controls.prioritySelect.disabled = false;
      delete controls.priorityContainer.dataset.disabled;

      if (!slot.turret) {
        controls.select.style.display = "inline-block";
        this.applyAvailabilityToSelect(controls.select);
        let selectedType = (this.getSelectValue(controls.select) as TurretTypeId) ?? "arrow";
        if (!this.isTurretTypeEnabled(selectedType)) {
          const fallback = this.pickFirstEnabledTurretType();
          if (fallback) {
            this.setSelectValue(controls.select, fallback);
            selectedType = fallback;
          }
        }
        const archetype = this.config.turretArchetypes[selectedType];
        const typeName = this.getTurretDisplayName(selectedType);
        const cost = archetype?.levels[0]?.cost ?? 0;
        const typeEnabled = this.isTurretTypeEnabled(selectedType);
        const flavor = this.getTurretFlavor(selectedType);
        controls.select.title = flavor ?? "";
        controls.status.title = flavor ?? "";
        const hasEnabledTypes = this.hasEnabledTurretTypes();
        controls.select.disabled = !hasEnabledTypes;
        if (typeEnabled) {
          controls.action.onclick = () => {
            const next = (this.getSelectValue(controls.select) as TurretTypeId) ?? "arrow";
            this.callbacks.onPlaceTurret(slot.id, next);
          };
          const affordable = state.resources.gold >= cost;
          controls.action.disabled = !affordable;
          controls.action.textContent = `Place (${cost}g)`;
          controls.action.title = flavor ? `${typeName}: ${flavor}` : "";
        } else {
          controls.action.onclick = null;
          controls.action.disabled = true;
          controls.action.textContent = `${typeName} (Disabled)`;
          controls.action.title = flavor ? `${typeName}: ${flavor}` : "";
        }
        if (controls.status.dataset.messageActive !== "true") {
          controls.status.textContent = typeEnabled
            ? "Empty slot"
            : `${typeName} disabled. Enable it from the options menu to deploy.`;
        }
        if (controls.downgradeButton) {
          controls.downgradeButton.style.display = "none";
          controls.downgradeButton.setAttribute("aria-hidden", "true");
          controls.downgradeButton.disabled = true;
          controls.downgradeButton.tabIndex = -1;
          controls.downgradeButton.onclick = null;
        }
      } else {
        controls.select.style.display = "none";
        this.applyAvailabilityToSelect(controls.select);
        const turret = slot.turret;
        if (!turret) continue;
        const nextConfig = this.config.turretArchetypes[turret.typeId]?.levels.find(
          (level) => level.level === turret.level + 1
        );
        const priorityDescription = this.describePriority(priority);
        const turretEnabled = this.isTurretTypeEnabled(turret.typeId);
        const flavor = this.getTurretFlavor(turret.typeId);
        controls.status.title = flavor ?? "";
        if (!nextConfig) {
          controls.action.disabled = true;
          controls.action.textContent = `${turret.typeId.toUpperCase()} Lv.${turret.level} (Max)`;
          controls.action.onclick = null;
        } else if (!turretEnabled) {
          controls.action.disabled = true;
          controls.action.textContent = `${turret.typeId.toUpperCase()} Lv.${turret.level} (Disabled)`;
          controls.action.onclick = null;
        } else {
          controls.action.disabled = state.resources.gold < nextConfig.cost;
          controls.action.textContent = `Upgrade (${nextConfig.cost}g)`;
          controls.action.onclick = () => {
            this.callbacks.onUpgradeTurret(slot.id);
          };
        }
        controls.action.title = flavor ?? this.config.turretArchetypes[turret.typeId]?.description ?? "";
        if (controls.downgradeButton) {
          const canDowngrade =
            this.turretDowngradeEnabled && Boolean(this.callbacks.onDowngradeTurret);
          if (canDowngrade) {
            const archetype = this.config.turretArchetypes[turret.typeId];
            let refund = 0;
            if (turret.level > 1) {
              const currentLevel = archetype?.levels.find(
                (levelConfig) => levelConfig.level === turret.level
              );
              refund = currentLevel?.cost ?? 0;
            } else {
              refund = archetype?.levels[0]?.cost ?? 0;
            }
            const roundedRefund = Math.max(0, Math.round(refund));
            controls.downgradeButton.style.display = "";
            controls.downgradeButton.setAttribute("aria-hidden", "false");
            controls.downgradeButton.disabled = false;
            controls.downgradeButton.tabIndex = 0;
            controls.downgradeButton.textContent =
              turret.level > 1 ? `Downgrade (+${roundedRefund}g)` : `Refund (+${roundedRefund}g)`;
            controls.downgradeButton.title =
              turret.level > 1
                ? `Downgrade to level ${turret.level - 1} and refund ${roundedRefund} gold.`
                : `Remove turret and refund ${roundedRefund} gold.`;
            controls.downgradeButton.onclick = () => {
              this.callbacks.onDowngradeTurret?.(slot.id);
            };
          } else {
            controls.downgradeButton.style.display = "none";
            controls.downgradeButton.setAttribute("aria-hidden", "true");
            controls.downgradeButton.disabled = true;
            controls.downgradeButton.tabIndex = -1;
            controls.downgradeButton.onclick = null;
          }
        }
        if (controls.status.dataset.messageActive !== "true") {
          const statusParts: string[] = [
            `${turret.typeId.toUpperCase()} Lv.${turret.level}`,
            priorityDescription
          ];
          const affinitySummary = this.describeAffinity(turret.typeId);
          if (affinitySummary) {
            statusParts.push(affinitySummary);
          }
          const shieldSummary = this.describeShieldBonus(turret.typeId, turret.level);
          if (shieldSummary) {
            statusParts.push(shieldSummary);
          }
          if (!turretEnabled) {
            statusParts.push("Disabled");
          }
          controls.status.textContent = statusParts.filter(Boolean).join(" • ");
        }
      }
    }
  }

  updateTurretPresets(presets: HudTurretPresetData[]): void {
    if (!this.presetList) {
      return;
    }
    const seen = new Set<string>();
    for (const preset of presets) {
      const control = this.ensurePresetControl(preset);
      seen.add(preset.id);
      control.label.textContent = preset.label;
      const canSave = Boolean(this.callbacks.onTurretPresetSave);
      control.saveButton.disabled = !canSave;
      control.saveButton.setAttribute("aria-disabled", canSave ? "false" : "true");
      control.saveButton.setAttribute("aria-label", `Save ${preset.label}`);

      const canClear = Boolean(this.callbacks.onTurretPresetClear) && preset.hasPreset;
      control.clearButton.disabled = !canClear;
      control.clearButton.setAttribute("aria-disabled", canClear ? "false" : "true");
      control.clearButton.setAttribute(
        "aria-label",
        canClear ? `Clear ${preset.label}` : `${preset.label} is empty`
      );

      const canApply =
        Boolean(this.callbacks.onTurretPresetApply) && preset.hasPreset && !preset.applyDisabled;
      control.applyButton.disabled = !canApply;
      control.applyButton.setAttribute("aria-disabled", canApply ? "false" : "true");
      if (preset.hasPreset && preset.applyCost !== null && preset.applyCost !== undefined) {
        control.applyButton.textContent = `Apply (${Math.max(0, Math.round(preset.applyCost))}g)`;
      } else {
        control.applyButton.textContent = "Apply";
      }
      control.applyButton.title = preset.applyMessage ?? preset.label;

      control.summary.textContent = this.formatPresetSummary(preset.slots);
      control.summary.dataset.empty = preset.slots.length === 0 ? "true" : "false";

      control.meta.textContent = preset.savedAtLabel ?? "";
      control.meta.dataset.visible = preset.savedAtLabel ? "true" : "false";

      if (preset.statusLabel) {
        control.status.textContent = preset.statusLabel;
        control.status.dataset.visible = "true";
      } else {
        control.status.textContent = "";
        control.status.dataset.visible = "false";
      }

      control.container.dataset.active = preset.active ? "true" : "false";
      control.container.dataset.saved = preset.hasPreset ? "true" : "false";
      this.presetList.appendChild(control.container);
    }

    for (const [presetId, control] of this.presetControls.entries()) {
      if (!seen.has(presetId)) {
        control.container.remove();
        this.presetControls.delete(presetId);
      }
    }
  }

  private ensurePresetControl(preset: HudTurretPresetData): PresetControl {
    const existing = this.presetControls.get(preset.id);
    if (existing) {
      return existing;
    }
    if (!this.presetList) {
      throw new Error("Preset list container missing");
    }

    const container = document.createElement("div");
    container.className = "turret-preset";
    container.dataset.presetId = preset.id;

    const header = document.createElement("div");
    header.className = "turret-preset-header";
    const label = document.createElement("span");
    label.className = "turret-preset-label";
    header.appendChild(label);

    const actions = document.createElement("div");
    actions.className = "turret-preset-actions";

    const saveButton = document.createElement("button");
    saveButton.type = "button";
    saveButton.className = "turret-preset-save";
    saveButton.textContent = "Save Current";
    saveButton.addEventListener("click", () => {
      this.callbacks.onTurretPresetSave?.(preset.id);
    });
    actions.appendChild(saveButton);

    const clearButton = document.createElement("button");
    clearButton.type = "button";
    clearButton.className = "turret-preset-clear";
    clearButton.textContent = "Clear";
    clearButton.addEventListener("click", () => {
      this.callbacks.onTurretPresetClear?.(preset.id);
    });
    actions.appendChild(clearButton);

    header.appendChild(actions);
    container.appendChild(header);

    const applyButton = document.createElement("button");
    applyButton.type = "button";
    applyButton.className = "turret-preset-apply";
    applyButton.textContent = "Apply";
    applyButton.addEventListener("click", () => {
      this.callbacks.onTurretPresetApply?.(preset.id);
    });
    container.appendChild(applyButton);

    const summary = document.createElement("div");
    summary.className = "turret-preset-summary";
    container.appendChild(summary);

    const meta = document.createElement("div");
    meta.className = "turret-preset-meta";
    container.appendChild(meta);

    const status = document.createElement("div");
    status.className = "turret-preset-status";
    container.appendChild(status);

    this.presetList.appendChild(container);

    const control: PresetControl = {
      container,
      label,
      applyButton,
      saveButton,
      clearButton,
      summary,
      meta,
      status
    };

    this.presetControls.set(preset.id, control);
    return control;
  }

  private applyTutorialSlotLock(state: GameState): void {
    const lock = this.tutorialSlotLock;
    for (const slot of state.turrets) {
      const controls = this.slotControls.get(slot.id);
      if (!controls) continue;
      if (!lock) {
        delete controls.container.dataset.tutorialHighlight;
        delete controls.container.dataset.tutorialLocked;
        this.resetTutorialSelectOptions(controls.select);
        controls.prioritySelect.disabled = !slot.unlocked;
        if (slot.unlocked) {
          delete controls.priorityContainer.dataset.disabled;
        } else {
          controls.priorityContainer.dataset.disabled = "true";
        }
        continue;
      }
      const isTarget = slot.id === lock.slotId;
      if (isTarget) {
        controls.container.dataset.tutorialHighlight = "true";
        delete controls.container.dataset.tutorialLocked;
        if (lock.mode === "placement") {
          controls.select.disabled = false;
          controls.select.style.display = "inline-block";
          if (lock.forcedType) {
            this.setSelectValue(controls.select, lock.forcedType);
            this.applyForcedSelectOption(controls.select, lock.forcedType);
          } else {
            this.resetTutorialSelectOptions(controls.select);
          }
        } else {
          controls.select.disabled = true;
          controls.select.style.display = "none";
          this.resetTutorialSelectOptions(controls.select);
        }
        controls.prioritySelect.disabled = false;
        delete controls.priorityContainer.dataset.disabled;
      } else {
        delete controls.container.dataset.tutorialHighlight;
        controls.container.dataset.tutorialLocked = "true";
        controls.action.disabled = true;
        controls.select.disabled = true;
        controls.select.style.display = "none";
        controls.prioritySelect.disabled = true;
        controls.priorityContainer.dataset.disabled = "true";
        if (controls.status.dataset.messageActive !== "true") {
          controls.status.textContent = "Locked during tutorial";
        }
      }
    }
  }

  private applyForcedSelectOption(select: HTMLSelectElement, forced: TurretTypeId): void {
    for (const option of this.getSelectOptionNodes(select)) {
      if (typeof option.value === "string") {
        option.disabled = option.value !== forced;
      }
    }
  }

  private resetTutorialSelectOptions(select: HTMLSelectElement): void {
    for (const option of this.getSelectOptionNodes(select)) {
      option.disabled = false;
    }
  }

  private notifyTurretHover(slotId: string | null): void {
    if (!this.callbacks.onTurretHover) {
      return;
    }
    if (slotId === null) {
      this.callbacks.onTurretHover(null);
      return;
    }
    const context = this.buildTurretHoverContext(slotId);
    this.callbacks.onTurretHover(slotId, context ?? undefined);
  }

  private buildTurretHoverContext(
    slotId: string
  ): { typeId?: TurretTypeId | null; level?: number | null } | null {
    const runtimeSlot = this.lastState?.turrets.find((slot) => slot.id === slotId);
    if (runtimeSlot?.turret) {
      return {
        typeId: runtimeSlot.turret.typeId,
        level: runtimeSlot.turret.level
      };
    }
    const controls = this.slotControls.get(slotId);
    if (!controls) {
      return null;
    }
    const selected = this.getSelectValue(controls.select) as TurretTypeId | "";
    if (selected && this.config.turretArchetypes[selected]) {
      return {
        typeId: selected,
        level: 1
      };
    }
    return null;
  }

  private elementContains(container: HTMLElement, node: Node | null | undefined): boolean {
    if (!node) {
      return false;
    }
    if (typeof container.contains === "function") {
      try {
        return container.contains(node);
      } catch {
        /* fall through to manual traversal */
      }
    }
    let current: Node | null = node;
    while (current) {
      if (current === container) {
        return true;
      }
      const anyNode = current as Node & { parentElement?: Node | null };
      current = anyNode.parentNode ?? anyNode.parentElement ?? null;
    }
    return false;
  }

  private getSelectOptionNodes(
    select: HTMLSelectElement
  ): Array<{ value?: string; disabled?: boolean }> {
    const withOptions = (
      select as HTMLSelectElement & {
        options?: ArrayLike<{ value?: string; disabled?: boolean }>;
      }
    ).options;
    if (withOptions && typeof withOptions.length === "number") {
      return Array.from(withOptions);
    }
    if (select.children && select.children.length > 0) {
      return Array.from(select.children).map(
        (child) => child as unknown as { value?: string; disabled?: boolean }
      );
    }
    return [];
  }

  private createTurretControls(): void {
    const types = Object.values(this.config.turretArchetypes);

    if (!this.presetContainer) {
      const presetsContainer = document.createElement("div");
      presetsContainer.className = "turret-presets";
      const title = document.createElement("h3");
      title.className = "turret-presets-title";
      title.textContent = "Loadout Presets";
      presetsContainer.appendChild(title);
      const list = document.createElement("div");
      list.className = "turret-presets-list";
      presetsContainer.appendChild(list);
      this.presetContainer = presetsContainer;
      this.presetList = list;
      this.upgradePanel.appendChild(presetsContainer);
    }

    for (const slot of this.config.turretSlots) {
      const container = document.createElement("div");
      container.className = "turret-slot";

      const title = document.createElement("div");
      title.className = "slot-title";
      container.appendChild(title);

      const select = document.createElement("select");
      select.className = "slot-select";
      for (const type of types) {
        const option = document.createElement("option");
        option.value = type.id;
        option.textContent = `${type.name}`;
        option.dataset.baseLabel = type.name;
        const flavor = this.getTurretFlavor(type.id);
        if (flavor) {
          option.title = flavor;
        }
        select.appendChild(option);
      }
      this.applyAvailabilityToSelect(select);
      const firstEnabled = this.pickFirstEnabledTurretType();
      if (firstEnabled) {
        this.setSelectValue(select, firstEnabled);
      }
      container.appendChild(select);

      const action = document.createElement("button");
      action.className = "slot-action";
      container.appendChild(action);

      const downgrade = document.createElement("button");
      downgrade.className = "slot-downgrade";
      downgrade.type = "button";
      downgrade.textContent = "Downgrade";
      downgrade.style.display = "none";
      downgrade.setAttribute("aria-hidden", "true");
      downgrade.tabIndex = -1;
      container.appendChild(downgrade);

      const priorityContainer = document.createElement("div");
      priorityContainer.className = "slot-priority";

      const priorityLabel = document.createElement("label");
      priorityLabel.className = "slot-priority-label";
      const prioritySelect = document.createElement("select");
      prioritySelect.className = "slot-priority-select";
      prioritySelect.id = `${slot.id}-priority`;
      priorityLabel.htmlFor = prioritySelect.id;
      priorityLabel.textContent = "Targeting";

      this.populatePrioritySelect(prioritySelect);
      priorityContainer.appendChild(priorityLabel);
      priorityContainer.appendChild(prioritySelect);
      container.appendChild(priorityContainer);

      prioritySelect.addEventListener("change", () => {
        const next = this.normalizePriority(this.getSelectValue(prioritySelect) ?? "");
        if (!next) {
          this.setSelectValue(prioritySelect, "first");
          return;
        }
        this.callbacks.onTurretPriorityChange(slot.id, next);
      });

      const emitHover = () => this.notifyTurretHover(slot.id);
      const clearHover = () => this.notifyTurretHover(null);

      container.addEventListener("mouseenter", emitHover);
      container.addEventListener("mouseleave", clearHover);
      container.addEventListener("focusin", emitHover);
      container.addEventListener("focusout", (event) => {
        const isFocusEvent = typeof FocusEvent !== "undefined" && event instanceof FocusEvent;
        const related = (isFocusEvent ? (event.relatedTarget as Node | null) : null) ?? null;
        if (!this.elementContains(container, related)) {
          clearHover();
        }
      });

      select.addEventListener("change", () => {
        if (!this.callbacks.onTurretHover) return;
        const isHovered = typeof container.matches === "function" && container.matches(":hover");
        let activeElement: Element | null = null;
        if (typeof document !== "undefined") {
          const candidate = (
            document as Document & {
              activeElement?: Element | null;
            }
          ).activeElement;
          if (candidate && (typeof Element === "undefined" || candidate instanceof Element)) {
            activeElement = candidate;
          }
        }
        const isFocused = this.elementContains(container, activeElement);
        if (isHovered || isFocused) {
          emitHover();
        }
      });

      const status = document.createElement("div");
      status.className = "slot-status";
      container.appendChild(status);

      this.upgradePanel.appendChild(container);
      this.slotControls.set(slot.id, {
        container,
        title,
        status,
        action,
        downgradeButton: downgrade,
        select,
        priorityContainer,
        prioritySelect
      });
    }
  }

  private populatePrioritySelect(select: HTMLSelectElement): void {
    const options: Array<{ value: TurretTargetPriority; label: string }> = [
      { value: "first", label: "First" },
      { value: "strongest", label: "Strongest" },
      { value: "weakest", label: "Weakest" }
    ];
    for (const option of options) {
      const opt = document.createElement("option");
      opt.value = option.value;
      opt.textContent = option.label;
      select.appendChild(opt);
    }
    this.setSelectValue(select, "first");
  }

  private normalizePriority(value: string): TurretTargetPriority | null {
    if (value === "first" || value === "strongest" || value === "weakest") {
      return value;
    }
    return null;
  }

  private applyTurretAvailabilityToControls(): void {
    if (this.slotControls.size === 0) {
      return;
    }
    for (const controls of this.slotControls.values()) {
      this.applyAvailabilityToSelect(controls.select);
    }
    if (this.lastState) {
      this.updateTurretControls(this.lastState);
    }
  }

  private applyAvailabilityToSelect(select: HTMLSelectElement): void {
    const optionCollection = select.options;
    let options: Array<{
      value?: string;
      textContent?: string | null;
      disabled?: boolean;
      dataset?: Record<string, string>;
      setAttribute?: (name: string, value: string) => void;
      getAttribute?: (name: string) => string | null;
    }> = [];

    if (optionCollection && typeof optionCollection.length === "number") {
      options = Array.from(optionCollection) as unknown as typeof options;
    } else {
      const fallbackChildren = (select as unknown as { children?: unknown }).children;
      if (Array.isArray(fallbackChildren)) {
        options = [...(fallbackChildren as typeof options)];
      }
    }

    for (const option of options) {
      const typeId = option.value as TurretTypeId;
      if (!typeId) continue;

      const existingBaseLabel =
        option.getAttribute?.("data-base-label") ??
        option.dataset?.baseLabel ??
        option.textContent ??
        typeId.toUpperCase();

      option.setAttribute?.("data-base-label", existingBaseLabel);
      if (option.dataset) {
        option.dataset.baseLabel = existingBaseLabel;
      }

      const enabled = this.isTurretTypeEnabled(typeId);
      option.disabled = !enabled;
      option.textContent = enabled ? existingBaseLabel : `${existingBaseLabel} (Disabled)`;
    }
  }

  private pickFirstEnabledTurretType(): TurretTypeId | null {
    for (const typeId of Object.keys(this.config.turretArchetypes)) {
      if (this.isTurretTypeEnabled(typeId as TurretTypeId)) {
        return typeId as TurretTypeId;
      }
    }
    return null;
  }

  private hasEnabledTurretTypes(): boolean {
    return Object.keys(this.config.turretArchetypes).some((typeId) =>
      this.isTurretTypeEnabled(typeId as TurretTypeId)
    );
  }

  private isTurretTypeEnabled(typeId: TurretTypeId): boolean {
    return this.availableTurretTypes[typeId] !== false;
  }

  private getTurretDisplayName(typeId: TurretTypeId): string {
    const archetype = this.config.turretArchetypes[typeId];
    return archetype?.name ?? typeId.toUpperCase();
  }

  private getTurretFlavor(typeId: TurretTypeId): string | null {
    const archetype = this.config.turretArchetypes[typeId];
    if (!archetype) return null;
    return archetype.flavor ?? archetype.description ?? null;
  }

  private describePriority(priority: TurretTargetPriority): string {
    switch (priority) {
      case "strongest":
        return "Strongest";
      case "weakest":
        return "Weakest";
      default:
        return "First";
    }
  }

  private describeAffinity(typeId: TurretTypeId): string | null {
    const archetype = this.config.turretArchetypes[typeId];
    const multipliers = archetype?.affinityMultipliers;
    if (!multipliers) {
      return null;
    }
    const bonuses = Object.entries(multipliers)
      .filter(([, value]) => typeof value === "number" && value > 1)
      .sort((a, b) => (b[1] ?? 1) - (a[1] ?? 1))
      .slice(0, 2)
      .map(([tierId, value]) => {
        const percent = Math.round((value - 1) * 100);
        return `${this.formatEnemyTierName(tierId)} (+${percent}%)`;
      });
    if (bonuses.length === 0) {
      return null;
    }
    return `Favored vs ${bonuses.join(", ")}`;
  }

  private describeShieldBonus(typeId: TurretTypeId, level?: number | null): string | null {
    const archetype = this.config.turretArchetypes[typeId];
    if (!archetype) {
      return null;
    }
    let levelConfig =
      typeof level === "number"
        ? archetype.levels.find((entry) => entry.level === level)
        : undefined;
    if (!levelConfig) {
      levelConfig = archetype.levels[0];
    }
    const bonus = levelConfig?.shieldBonus ?? 0;
    if (!bonus || bonus <= 0) {
      return null;
    }
    return `Shield +${Math.round(bonus)}`;
  }

  private formatPresetSummary(slots: HudTurretPresetSlotData[]): string {
    if (!slots || slots.length === 0) {
      return "No turrets saved.";
    }
    return slots
      .map((slot) => {
        const typeName = this.getTurretDisplayName(slot.typeId);
        const slotLabel = this.formatSlotLabel(slot.slotId);
        const extras: string[] = [];
        if (slot.priority && slot.priority !== "first") {
          extras.push(this.describePriority(slot.priority));
        }
        const shieldSummary = this.describeShieldBonus(slot.typeId, slot.level);
        if (shieldSummary) {
          extras.push(shieldSummary);
        }
        if (!this.isTurretTypeEnabled(slot.typeId)) {
          extras.push("Disabled");
        }
        const suffix = extras.length > 0 ? ` (${extras.join(" • ")})` : "";
        return `${slotLabel} ${typeName} Lv${slot.level}${suffix}`;
      })
      .join(" • ");
  }

  private formatSlotLabel(slotId: string): string {
    const match = /^slot-(\d+)$/.exec(slotId);
    if (match) {
      return `S${match[1]}`;
    }
    return slotId;
  }

  private formatEnemyTierName(tierId: string): string {
    const tier = this.config.enemyTiers[tierId];
    const source = tier?.id ?? tierId;
    if (!source) {
      return "Unknown";
    }
    return source.charAt(0).toUpperCase() + source.slice(1);
  }

  private getElement(id: string): HTMLElement {
    const el = document.getElementById(id);
    if (!el) {
      throw new Error(`Expected element with id "${id}"`);
    }
    return el;
  }

  private handleGoldDelta(currentGold: number): void {
    if (!this.lastGold) {
      this.lastGold = currentGold;
      return;
    }
    const delta = currentGold - this.lastGold;
    if (delta !== 0) {
      this.goldDelta.textContent = `${delta > 0 ? "+" : ""}${delta}g`;
      this.goldDelta.style.color = delta > 0 ? "#22c55e" : "#f87171";
      this.goldDelta.dataset.visible = "true";
      if (this.goldTimeout !== null) {
        window.clearTimeout(this.goldTimeout);
      }
      this.goldTimeout = window.setTimeout(() => {
        this.goldDelta.dataset.visible = "false";
        this.goldDelta.textContent = "";
        this.goldTimeout = null;
      }, 1400);
    }
    this.lastGold = currentGold;
  }

  private updateCombo(
    combo: number,
    warning: boolean,
    timer: number,
    accuracy: number | undefined
  ): void {
    const safeAccuracy =
      typeof accuracy === "number" && Number.isFinite(accuracy)
        ? accuracy
        : (this.lastAccuracy ?? this.comboBaselineAccuracy);
    this.lastAccuracy = safeAccuracy ?? 1;
    this.maxCombo = Math.max(this.maxCombo, combo);
    if (combo > 0) {
      this.comboLabel.dataset.active = "true";
      const warningActive = warning && timer > 0;
      if (warningActive) {
        this.comboLabel.dataset.warning = "true";
        const seconds = Math.max(0, timer).toFixed(1);
        this.comboLabel.textContent = `Combo x${combo} (Best x${this.maxCombo}) - ${seconds}s`;
        this.showComboAccuracyDelta(safeAccuracy ?? 1);
      } else {
        delete this.comboLabel.dataset.warning;
        this.comboLabel.textContent = `Combo x${combo} (Best x${this.maxCombo})`;
        this.comboBaselineAccuracy = safeAccuracy ?? this.comboBaselineAccuracy;
        this.hideComboAccuracyDelta();
      }
    } else {
      this.comboLabel.dataset.active = "false";
      delete this.comboLabel.dataset.warning;
      this.comboLabel.textContent = `Combo x0 (Best x${this.maxCombo})`;
      this.comboBaselineAccuracy = safeAccuracy ?? this.comboBaselineAccuracy;
      this.hideComboAccuracyDelta();
    }
  }

  private showComboAccuracyDelta(currentAccuracy: number): void {
    const baseline = Number.isFinite(this.comboBaselineAccuracy)
      ? this.comboBaselineAccuracy
      : currentAccuracy;
    const delta = (currentAccuracy - baseline) * 100;
    const prefix = delta > 0 ? "+" : "";
    this.comboAccuracyDelta.textContent = `${prefix}${delta.toFixed(1)}% accuracy`;
    this.comboAccuracyDelta.dataset.visible = "true";
    if (delta > 0.05) {
      this.comboAccuracyDelta.dataset.trend = "up";
    } else if (delta < -0.05) {
      this.comboAccuracyDelta.dataset.trend = "down";
    } else {
      delete this.comboAccuracyDelta.dataset.trend;
    }
  }

  private hideComboAccuracyDelta(): void {
    this.comboAccuracyDelta.dataset.visible = "false";
    delete this.comboAccuracyDelta.dataset.trend;
    this.comboAccuracyDelta.textContent = "";
  }

  private renderLog(): void {
    this.logList.replaceChildren();
    for (const entry of this.logEntries) {
      const item = document.createElement("li");
      item.textContent = entry;
      this.logList.appendChild(item);
    }
  }

  private renderWaveScorecard(data: WaveScorecardData): void {
    if (!this.waveScorecard) return;
    this.waveScorecard.container.dataset.mode = data.mode;
    this.waveScorecard.container.dataset.practice = data.mode === "practice" ? "true" : "false";
    const entries: Array<{ field: string; label: string; value: string }> = [
      {
        field: "wave",
        label: "Wave",
        value: `Wave ${Math.max(1, data.waveIndex + 1)} / ${Math.max(data.waveTotal, 1)}${
          data.mode === "practice" ? " (Practice)" : ""
        }`
      },
      {
        field: "accuracy",
        label: "Accuracy",
        value: `${(data.accuracy * 100).toFixed(1)}%`
      },
      {
        field: "combo",
        label: "Wave Best Combo",
        value: `x${Math.max(0, Math.floor(data.bestCombo))}`
      },
      {
        field: "session-combo",
        label: "Session Best Combo",
        value: `x${Math.max(0, Math.floor(data.sessionBestCombo))}`
      },
      {
        field: "defeated",
        label: "Enemies Defeated",
        value: `${data.enemiesDefeated}`
      },
      {
        field: "breaches",
        label: "Breaches",
        value: `${data.breaches}`
      },
      {
        field: "perfect-words",
        label: "Perfect Words",
        value: `${Math.max(0, Math.floor(data.perfectWords))}`
      },
      {
        field: "reaction",
        label: "Avg Reaction",
        value: data.averageReaction > 0 ? `${data.averageReaction.toFixed(2)}s` : "—"
      },
      {
        field: "dps",
        label: "Damage / Second",
        value: `${data.dps.toFixed(1)}`
      },
      {
        field: "dps-turret",
        label: "Turret DPS",
        value: `${data.turretDps.toFixed(1)}`
      },
      {
        field: "dps-typing",
        label: "Typing DPS",
        value: `${data.typingDps.toFixed(1)}`
      },
      {
        field: "damage-turret",
        label: "Turret Damage",
        value: `${Math.round(data.turretDamage)}`
      },
      {
        field: "damage-typing",
        label: "Typing Damage",
        value: `${Math.round(data.typingDamage)}`
      },
      {
        field: "shield-breaks",
        label: "Shield Breaks",
        value: `${Math.max(0, Math.floor(data.shieldBreaks))}`
      },
      {
        field: "repairs",
        label: "Repairs Used",
        value: `${Math.max(0, Math.floor(data.repairsUsed))}`
      },
      {
        field: "repair-health",
        label: "HP Restored",
        value: `${Math.round(data.repairHealth)}`
      },
      {
        field: "repair-gold",
        label: "Gold Spent on Repairs",
        value: `${Math.round(data.repairGold)}g`
      },
      {
        field: "bonus-gold",
        label: "Objective Bonus",
        value: data.bonusGold > 0 ? `+${Math.round(data.bonusGold)}g` : "—"
      },
      {
        field: "castle-bonus",
        label: "Castle Bonus",
        value: data.castleBonusGold > 0 ? `+${Math.round(data.castleBonusGold)}g` : "—"
      },
      {
        field: "gold",
        label: "Gold Earned",
        value: `${Math.round(data.goldEarned)}g`
      }
    ];
    for (const entry of entries) {
      this.setWaveScorecardField(entry.field, entry.label, entry.value);
    }
  }

  private updateShieldTelemetry(entries: WaveSpawnPreview[]): void {
    const currentShielded = entries.some((entry) => !entry.isNextWave && (entry.shield ?? 0) > 0);
    const nextShielded = entries.some((entry) => entry.isNextWave && (entry.shield ?? 0) > 0);
    this.wavePreview.setShieldForecast(currentShielded, nextShielded);

    if (currentShielded && !this.lastShieldTelemetry.current) {
      this.showCastleMessage("Shielded enemies inbound! Let your turrets shatter the barrier.");
    } else if (!currentShielded && nextShielded && !this.lastShieldTelemetry.next) {
      this.showCastleMessage("Next wave includes shielded foes. Prepare turrets to break shields.");
    }

    this.lastShieldTelemetry = { current: currentShielded, next: nextShielded };
  }

  private updateAffixTelemetry(entries: WaveSpawnPreview[]): void {
    const currentAffixed = entries.some((entry) => !entry.isNextWave && (entry.affixes?.length ?? 0) > 0);
    const nextAffixed = entries.some((entry) => entry.isNextWave && (entry.affixes?.length ?? 0) > 0);
    if (currentAffixed && !this.lastAffixTelemetry.current) {
      const labels = this.summarizeAffixLabels(entries.filter((entry) => !entry.isNextWave));
      const message = labels.length > 0 ? `Elite affixes active: ${labels}.` : "Elite affixes active this wave.";
      this.showCastleMessage(message);
    } else if (!currentAffixed && nextAffixed && !this.lastAffixTelemetry.next) {
      this.showCastleMessage("Next wave spawns elite affixes. Prep turret coverage.");
    }
    this.lastAffixTelemetry = { current: currentAffixed, next: nextAffixed };
  }

  private summarizeAffixLabels(entries: WaveSpawnPreview[]): string {
    const labels = new Set<string>();
    for (const entry of entries) {
      const affixes = entry.affixes ?? [];
      for (const affix of affixes) {
        if (affix?.label) {
          labels.add(affix.label);
        } else if (affix?.id) {
          labels.add(affix.id);
        }
      }
      if (labels.size >= 3) break;
    }
    return Array.from(labels).slice(0, 3).join(", ");
  }

  private refreshRoadmap(
    state: GameState,
    options: { tutorialCompleted?: boolean; loreUnlocked?: number }
  ): void {
    if (!this.roadmapOverlay && !this.roadmapGlance) return;
    const completedWaves =
      state.analytics.waveHistory && state.analytics.waveHistory.length > 0
        ? state.analytics.waveHistory.length
        : state.analytics.waveSummaries?.length ?? 0;
    const currentWave = Math.max(1, (state.wave?.index ?? 0) + 1);
    const totalWaves = Math.max(state.wave?.total ?? currentWave, currentWave, completedWaves || 0);
    const loreUnlocked = Math.max(0, Math.floor(options?.loreUnlocked ?? 0));
    const tutorialCompleted =
      options?.tutorialCompleted ?? (state.analytics.tutorial?.completedRuns ?? 0) > 0;

    this.roadmapState = evaluateRoadmap({
      tutorialCompleted,
      currentWave,
      completedWaves,
      totalWaves,
      castleLevel: state.castle.level,
      loreUnlocked
    });

    if (this.roadmapOverlay) {
      this.roadmapOverlay.summaryWave.textContent = `Wave ${currentWave} / ${totalWaves}`;
      this.roadmapOverlay.summaryCastle.textContent = `Lv. ${state.castle.level}`;
      const loreLabel = loreUnlocked === 1 ? "entry" : "entries";
      this.roadmapOverlay.summaryLore.textContent = `${loreUnlocked} ${loreLabel}`;
      this.renderRoadmapList();
    }
    this.updateRoadmapTrackingDisplay();
  }

  getShieldForecast(): { current: boolean; next: boolean } {
    return { ...this.lastShieldTelemetry };
  }

  private renderRoadmapList(): void {
    if (!this.roadmapOverlay || !this.roadmapState) return;
    const filters = this.roadmapPreferences.filters;
    const items = this.roadmapState.entries.filter((entry) => {
      if (!filters.completed && entry.status === "done") return false;
      switch (entry.type) {
        case "story":
          return filters.story;
        case "systems":
          return filters.systems;
        case "challenge":
          return filters.challenge;
        case "lore":
          return filters.lore;
        default:
          return true;
      }
    });

    this.roadmapOverlay.list.replaceChildren();
    if (items.length === 0) {
      const placeholder = document.createElement("li");
      placeholder.className = "roadmap-placeholder";
      placeholder.textContent =
        'All visible steps are complete. Enable "Show completed" to review finished milestones.';
      this.roadmapOverlay.list.appendChild(placeholder);
      this.updateRoadmapTrackingDisplay();
      return;
    }

    for (const entry of items) {
      const li = document.createElement("li");
      li.className = "roadmap-item";
      li.dataset.status = entry.status;
      li.dataset.type = entry.type;
      const isTracked = this.roadmapPreferences.trackedId === entry.id;
      li.dataset.tracked = isTracked ? "true" : "false";

      const header = document.createElement("div");
      header.className = "roadmap-item-header";
      const titleBlock = document.createElement("div");
      titleBlock.className = "roadmap-title-block";
      const title = document.createElement("h3");
      title.className = "roadmap-item-title";
      title.textContent = entry.title;
      const phase = document.createElement("p");
      phase.className = "roadmap-phase";
      phase.textContent = entry.phase
        ? `${entry.phase} • ${entry.milestone}`
        : entry.milestone;
      titleBlock.appendChild(title);
      titleBlock.appendChild(phase);

      const statusBadge = document.createElement("span");
      statusBadge.className = "roadmap-status";
      statusBadge.dataset.status = entry.status;
      const statusLabel =
        entry.status === "done"
          ? "Complete"
          : entry.status === "active"
            ? "Active"
            : entry.status === "locked"
              ? "Locked"
              : "Upcoming";
      statusBadge.textContent = statusLabel;

      const tag = document.createElement("span");
      tag.className = "roadmap-tag";
      tag.dataset.type = entry.type;
      tag.textContent = entry.type;

      header.appendChild(titleBlock);
      const headerMeta = document.createElement("div");
      headerMeta.className = "roadmap-item-meta";
      headerMeta.appendChild(tag);
      headerMeta.appendChild(statusBadge);
      header.appendChild(headerMeta);
      li.appendChild(header);

      const summary = document.createElement("p");
      summary.className = "roadmap-item-body";
      summary.textContent = entry.summary;
      li.appendChild(summary);

      const progress = document.createElement("p");
      progress.className = "roadmap-progress";
      progress.textContent =
        entry.status === "done" ? "Complete" : entry.progressLabel || "In progress";
      li.appendChild(progress);

      if (entry.reward) {
        const reward = document.createElement("p");
        reward.className = "roadmap-progress";
        reward.textContent = `Reward: ${entry.reward}`;
        li.appendChild(reward);
      }

      if (entry.blockers.length > 0 && entry.status !== "done") {
        const blockers = document.createElement("p");
        blockers.className = "roadmap-blockers";
        blockers.textContent = `Next: ${entry.blockers.join(" • ")}`;
        li.appendChild(blockers);
      }

      const actions = document.createElement("div");
      actions.className = "roadmap-actions";
      const trackButton = document.createElement("button");
      trackButton.type = "button";
      trackButton.className = "roadmap-track-btn";
      trackButton.dataset.tracked = isTracked ? "true" : "false";
      trackButton.textContent = isTracked ? "Tracking" : "Track";
      trackButton.addEventListener("click", () =>
        this.updateRoadmapTracking(isTracked ? null : entry.id)
      );
      actions.appendChild(trackButton);
      li.appendChild(actions);

      this.roadmapOverlay.list.appendChild(li);
    }

    this.updateRoadmapTrackingDisplay();
  }

  private updateRoadmapTrackingDisplay(): void {
    const trackedId = this.roadmapPreferences.trackedId;
    const entry = this.roadmapState?.entries.find((item) => item.id === trackedId);
    const visible = Boolean(entry);
    const progressText = entry
      ? entry.status === "done"
        ? "Complete"
        : entry.progressLabel
      : "Track a step to pin it here.";

    if (this.roadmapOverlay) {
      this.roadmapOverlay.tracked.container.dataset.visible = visible ? "true" : "false";
      if (visible && entry) {
        this.roadmapOverlay.tracked.title.textContent = entry.title;
        this.roadmapOverlay.tracked.progress.textContent = progressText;
      } else {
        this.roadmapOverlay.tracked.title.textContent = "";
        this.roadmapOverlay.tracked.progress.textContent = "";
      }
    }

    if (this.roadmapGlance) {
      this.roadmapGlance.container.dataset.visible = visible ? "true" : "false";
      this.roadmapGlance.container.setAttribute("aria-hidden", visible ? "false" : "true");
      if (visible && entry) {
        this.roadmapGlance.title.textContent = entry.title;
        this.roadmapGlance.progress.textContent = progressText;
      } else {
        this.roadmapGlance.title.textContent = "Season roadmap";
        this.roadmapGlance.progress.textContent = "No step tracked.";
      }
    }
  }

  private applyRoadmapFilters(filters: RoadmapFilterPreferences): void {
    const mergedFilters: RoadmapFilterPreferences = {
      ...this.roadmapPreferences.filters,
      ...filters
    };
    this.roadmapPreferences = mergeRoadmapPreferences(this.roadmapPreferences, {
      filters: mergedFilters
    });
    if (this.roadmapOverlay) {
      this.roadmapOverlay.filters.story.checked = this.roadmapPreferences.filters.story;
      this.roadmapOverlay.filters.systems.checked = this.roadmapPreferences.filters.systems;
      this.roadmapOverlay.filters.challenge.checked =
        this.roadmapPreferences.filters.challenge;
      this.roadmapOverlay.filters.lore.checked = this.roadmapPreferences.filters.lore;
      this.roadmapOverlay.filters.completed.checked =
        this.roadmapPreferences.filters.completed;
    }
    this.persistRoadmapPreferences();
    this.renderRoadmapList();
    if (!this.roadmapOverlay) {
      this.updateRoadmapTrackingDisplay();
    }
  }

  private updateRoadmapTracking(nextId: string | null): void {
    this.roadmapPreferences = mergeRoadmapPreferences(this.roadmapPreferences, {
      trackedId: nextId
    });
    this.persistRoadmapPreferences();
    this.renderRoadmapList();
    if (!this.roadmapOverlay) {
      this.updateRoadmapTrackingDisplay();
    }
  }

  private clearRoadmapTracking(): void {
    this.updateRoadmapTracking(null);
  }

  private persistRoadmapPreferences(): void {
    if (typeof window === "undefined") return;
    writeRoadmapPreferences(window.localStorage, this.roadmapPreferences);
  }

  private setWaveScorecardField(field: string, label: string, value: string): void {
    if (!this.waveScorecard) return;
    const items = Array.from(this.waveScorecard.statsList.children) as HTMLElement[];
    const target = items.find((element) => element.dataset.field === field);
    if (!target) return;

    const labelSpan = document.createElement("span");
    labelSpan.textContent = label;
    const valueSpan = document.createElement("span");
    valueSpan.textContent = value;
    target.replaceChildren(labelSpan, valueSpan);
  }

  private setWaveScorecardVisible(visible: boolean): void {
    if (!this.waveScorecard) return;
    this.waveScorecard.container.dataset.visible = visible ? "true" : "false";
    if (visible) {
      this.waveScorecard.continueBtn.focus();
    } else {
      this.focusTypingInput();
    }
  }

  private setShortcutOverlayVisible(visible: boolean): void {
    if (!this.shortcutOverlay) return;
    this.shortcutOverlay.container.dataset.visible = visible ? "true" : "false";
    if (visible) {
      this.shortcutOverlay.closeButton.focus();
    } else {
      this.focusTypingInput();
    }
  }

  private setRoadmapOverlayVisible(visible: boolean): void {
    if (!this.roadmapOverlay) return;
    this.roadmapOverlay.container.dataset.visible = visible ? "true" : "false";
    this.roadmapOverlay.container.setAttribute("aria-hidden", visible ? "false" : "true");
    if (visible) {
      this.renderRoadmapList();
      this.roadmapOverlay.closeButton.focus();
    } else {
      this.focusTypingInput();
    }
  }

  private applyTelemetryOptionState(state?: {
    available: boolean;
    checked: boolean;
    disabled?: boolean;
  }): void {
    if (!this.optionsOverlay?.telemetryToggle) return;
    const toggle = this.optionsOverlay.telemetryToggle;
    const wrapper =
      this.optionsOverlay.telemetryWrapper ??
      (toggle.parentElement instanceof HTMLElement ? toggle.parentElement : undefined);
    const available = Boolean(state?.available);

    if (!available) {
      if (wrapper) {
        wrapper.style.display = "none";
        wrapper.setAttribute("aria-hidden", "true");
      } else {
        toggle.style.display = "none";
      }
      toggle.checked = false;
      toggle.disabled = true;
      toggle.setAttribute("aria-hidden", "true");
      toggle.tabIndex = -1;
      return;
    }

    if (wrapper) {
      wrapper.style.display = "";
      wrapper.setAttribute("aria-hidden", "false");
    } else {
      toggle.style.display = "";
    }
    toggle.setAttribute("aria-hidden", "false");
    toggle.disabled = Boolean(state?.disabled);
    toggle.tabIndex = toggle.disabled ? -1 : 0;
    toggle.checked = Boolean(state?.checked);
  }

  private updateSoundVolumeDisplay(volume: number): void {
    if (!this.optionsOverlay?.soundVolumeValue) return;
    const percent = Math.round(volume * 100);
    this.optionsOverlay.soundVolumeValue.textContent = `${percent}%`;
  }

  private updateSoundIntensityDisplay(intensity: number): void {
    if (!this.optionsOverlay?.soundIntensityValue) return;
    const percent = Math.round(intensity * 100);
    this.optionsOverlay.soundIntensityValue.textContent = `${percent}%`;
  }

  setAnalyticsExportEnabled(enabled: boolean): void {
    const button = this.optionsOverlay?.analyticsExportButton;
    if (!button) return;
    if (enabled) {
      button.style.display = "";
      button.disabled = false;
      button.setAttribute("aria-hidden", "false");
      button.tabIndex = 0;
      button.setAttribute("tabindex", "0");
    } else {
      button.style.display = "none";
      button.disabled = true;
      button.setAttribute("aria-hidden", "true");
      button.tabIndex = -1;
      button.setAttribute("tabindex", "-1");
    }
  }

  setHudFontScale(scale: number): void {
    if (typeof document === "undefined") return;
    document.documentElement.style.setProperty("--hud-font-scale", scale.toString());
  }

  setReducedMotionEnabled(enabled: boolean): void {
    if (typeof document !== "undefined") {
      if (document.documentElement) {
        document.documentElement.dataset.reducedMotion = enabled ? "true" : "false";
      }
      if (document.body) {
        document.body.dataset.reducedMotion = enabled ? "true" : "false";
      }
    }
    if (this.hudRoot) {
      this.hudRoot.dataset.reducedMotion = enabled ? "true" : "false";
    }
  }

  setCanvasTransitionState(state: ResolutionTransitionState): void {
    if (!this.hudRoot) return;
    this.hudRoot.dataset.canvasTransition = state;
    this.hudRoot.classList.toggle("hud--canvas-transition", state === "running");
  }

  hasAnalyticsViewer(): boolean {
    return Boolean(this.analyticsViewer);
  }

  toggleAnalyticsViewer(): boolean {
    const next = !this.analyticsViewerVisible;
    return this.setAnalyticsViewerVisible(next);
  }

  private normalizeAnalyticsViewerFilter(value: string): AnalyticsViewerFilter {
    if (value === "last-5" || value === "last-10" || value === "breaches" || value === "shielded") {
      return value;
    }
    return "all";
  }

  private describeAnalyticsViewerFilter(filter: AnalyticsViewerFilter): string {
    switch (filter) {
      case "last-5":
        return "last 5 waves";
      case "last-10":
        return "last 10 waves";
      case "breaches":
        return "waves with breaches";
      case "shielded":
        return "waves with shield breaks";
      default:
        return "all waves";
    }
  }

  private applyAnalyticsViewerFilter(summaries: WaveSummary[]): WaveSummary[] {
    switch (this.analyticsViewerFilter) {
      case "last-5":
        return summaries.slice(-5);
      case "last-10":
        return summaries.slice(-10);
      case "breaches":
        return summaries.filter((summary) => (summary.breaches ?? 0) > 0);
      case "shielded":
        return summaries.filter((summary) => (summary.shieldBreaks ?? 0) > 0);
      default:
        return summaries;
    }
  }

  private setSelectValue(select: HTMLSelectElement | undefined, value: string): void {
    if (!select) return;
    try {
      select.value = value;
    } catch {
      select.setAttribute("value", value);
    }
  }

  private getSelectValue(select: HTMLSelectElement | undefined): string | undefined {
    if (!select) return undefined;
    const direct = select.value;
    if (typeof direct === "string" && direct !== "") {
      return direct;
    }
    const options = Array.from(select.options ?? []);
    const selected = options.find((option) => option.selected);
    if (selected) {
      return selected.value ?? selected.getAttribute("value") ?? undefined;
    }
    return select.getAttribute("value") ?? undefined;
  }

  setAnalyticsViewerVisible(visible: boolean): boolean {
    if (!this.analyticsViewer) {
      return false;
    }
    this.analyticsViewerVisible = visible;
    const { container } = this.analyticsViewer;
    container.dataset.visible = visible ? "true" : "false";
    container.setAttribute("aria-hidden", visible ? "false" : "true");
    if (visible && this.analyticsViewerFilterSelect) {
      this.setSelectValue(this.analyticsViewerFilterSelect, this.analyticsViewerFilter);
    }
    if (visible && this.lastState) {
      const history = this.lastState.analytics.waveHistory?.length
        ? this.lastState.analytics.waveHistory
        : this.lastState.analytics.waveSummaries;
      this.refreshAnalyticsViewer(history, {
        force: true,
        timeToFirstTurret: this.lastState.analytics.timeToFirstTurret ?? null
      });
    }
    return this.analyticsViewerVisible;
  }

  isAnalyticsViewerVisible(): boolean {
    return this.analyticsViewerVisible;
  }

  private updateAnalyticsViewerDrills(): void {
    if (!this.analyticsViewer?.drills) {
      return;
    }
    const container = this.analyticsViewer.drills;
    container.replaceChildren();
    const drills = this.lastState?.analytics?.typingDrills ?? [];
    if (!Array.isArray(drills) || drills.length === 0) {
      const empty = document.createElement("div");
      empty.textContent = "Typing drills: none run yet.";
      container.appendChild(empty);
      return;
    }
    const last = drills[drills.length - 1];
    const headline = document.createElement("div");
    headline.className = "analytics-drills__headline";
    headline.textContent = `Typing drills (${drills.length})`;
    const meta = document.createElement("div");
    meta.className = "analytics-drills__meta";
    const mode = document.createElement("span");
    mode.className = "analytics-drills__pill";
    mode.textContent = `${last.mode}${last.source ? ` @${last.source}` : ""}`;
    const accuracy = document.createElement("span");
    accuracy.className = "analytics-drills__pill";
    const accuracyPct =
      typeof last.accuracy === "number" && Number.isFinite(last.accuracy)
        ? Math.round(Math.max(0, Math.min(1, last.accuracy)) * 100)
        : null;
    accuracy.textContent = accuracyPct !== null ? `${accuracyPct}% acc` : "acc ?";
    const wpm = document.createElement("span");
    wpm.className = "analytics-drills__pill";
    const wpmValue =
      typeof last.wpm === "number" && Number.isFinite(last.wpm) ? Math.round(last.wpm) : null;
    wpm.textContent = wpmValue !== null ? `${wpmValue} wpm` : "wpm ?";
    const combo = document.createElement("span");
    combo.className = "analytics-drills__pill";
    combo.textContent =
      typeof last.bestCombo === "number" && Number.isFinite(last.bestCombo)
        ? `combo x${last.bestCombo}`
        : "combo ?";
    const words = document.createElement("span");
    words.className = "analytics-drills__pill";
    const wordsText =
      typeof last.words === "number" && Number.isFinite(last.words) ? `${last.words} words` : "? words";
    const errorsText =
      typeof last.errors === "number" && Number.isFinite(last.errors)
        ? `${last.errors} errors`
        : "? errors";
    words.textContent = `${wordsText}, ${errorsText}`;
    meta.append(mode, accuracy, wpm, combo, words);

    const history = document.createElement("div");
    history.className = "analytics-drills__history";
    const recent = drills.slice(-3).reverse();
    const historyText = recent
      .map((entry) => {
        const acc =
          typeof entry.accuracy === "number" && Number.isFinite(entry.accuracy)
            ? `${Math.round(Math.max(0, Math.min(1, entry.accuracy)) * 100)}%`
            : "?%";
        const comboLabel =
          typeof entry.bestCombo === "number" && Number.isFinite(entry.bestCombo)
            ? `x${entry.bestCombo}`
            : "x?";
        const wpmLabel =
          typeof entry.wpm === "number" && Number.isFinite(entry.wpm)
            ? `${Math.round(entry.wpm)}wpm`
            : "?wpm";
        const sourceLabel = entry.source ? `@${entry.source}` : "";
        return `${entry.mode}${sourceLabel} ${acc} ${comboLabel} ${wpmLabel}`;
      })
      .join(" | ");
    history.textContent = historyText;

    container.append(headline, meta, history);
  }

  private refreshAnalyticsViewer(
    summaries: WaveSummary[],
    options: { force?: boolean; timeToFirstTurret?: number | null } = {}
  ): void {
    if (!this.analyticsViewer) {
      return;
    }
    const { force = false, timeToFirstTurret = null } = options;
    this.updateAnalyticsViewerDrills();
    const fallbackMode = this.lastState?.mode ?? "campaign";
    const filteredSummaries = this.applyAnalyticsViewerFilter(summaries);
    const signatureSource =
      filteredSummaries.length === 0
        ? "empty"
        : filteredSummaries
            .map((summary) =>
              [
                summary.index,
                summary.mode ?? fallbackMode,
                summary.enemiesDefeated,
                summary.breaches,
                summary.perfectWords ?? 0,
                (summary.averageReaction ?? 0).toFixed(2),
                Math.round(summary.goldEarned ?? 0),
                Math.round(summary.bonusGold ?? 0),
                Math.round(summary.castleBonusGold ?? 0),
                summary.dps.toFixed(2),
                summary.turretDps?.toFixed(2) ?? "0.00",
                summary.typingDps?.toFixed(2) ?? "0.00",
                Math.round(summary.turretDamage ?? 0),
                Math.round(summary.typingDamage ?? 0),
                summary.shieldBreaks ?? 0,
                summary.repairsUsed ?? 0,
                Math.round(summary.repairHealth ?? 0),
                Math.round(summary.repairGold ?? 0),
                summary.accuracy.toFixed(3),
                summary.duration.toFixed(2),
                summary.maxCombo,
                summary.sessionBestCombo
              ].join(":")
            )
            .join("|");
    const signature = `${this.analyticsViewerFilter}:${signatureSource}:${timeToFirstTurret ?? "null"}`;

    if (!force && signature === this.analyticsViewerSignature) {
      return;
    }

    this.analyticsViewerSignature = signature;
    const { container, tableBody } = this.analyticsViewer;
    tableBody.replaceChildren();

    const totalAvailable = summaries.length;
    const filterDescription = this.describeAnalyticsViewerFilter(this.analyticsViewerFilter);
    if (filteredSummaries.length === 0) {
      const row = document.createElement("tr");
      row.className = "analytics-empty-row";
      const cell = document.createElement("td");
      cell.colSpan = 20;
      cell.textContent =
        totalAvailable === 0
          ? "No wave summaries yet - finish a wave to populate analytics."
          : `No wave summaries match ${filterDescription}.`;
      row.appendChild(cell);
      tableBody.appendChild(row);
      container.dataset.empty = "true";
      return;
    }

    container.dataset.empty = "false";
    const recentIndex = filteredSummaries[filteredSummaries.length - 1]?.index ?? null;
    const modesInView = new Set(filteredSummaries.map((summary) => summary.mode ?? fallbackMode));
    container.dataset.practice =
      modesInView.size === 1 && modesInView.has("practice") ? "true" : "false";
    container.dataset.practiceMixed = modesInView.size > 1 ? "true" : "false";
    const summaryModeLabel =
      modesInView.size === 0
        ? fallbackMode === "practice"
          ? "Practice"
          : "Campaign"
        : modesInView.size === 1
          ? Array.from(modesInView)[0] === "practice"
            ? "Practice"
            : "Campaign"
          : "Mixed";

    const totals = filteredSummaries.reduce(
      (acc, summary) => {
        acc.count += 1;
        acc.accuracy += summary.accuracy;
        acc.breaches += summary.breaches;
        acc.enemies += summary.enemiesDefeated;
        acc.dps += summary.dps;
        acc.turretDps += summary.turretDps ?? 0;
        acc.typingDps += summary.typingDps ?? 0;
        acc.turretDamage += summary.turretDamage ?? 0;
        acc.typingDamage += summary.typingDamage ?? 0;
        acc.shieldBreaks += summary.shieldBreaks ?? 0;
        acc.repairsUsed += summary.repairsUsed ?? 0;
        acc.repairHealth += summary.repairHealth ?? 0;
        acc.repairGold += summary.repairGold ?? 0;
        acc.goldEarned += summary.goldEarned ?? 0;
        acc.perfectWords += summary.perfectWords ?? 0;
        acc.bonusGold += summary.bonusGold ?? 0;
        acc.castleBonus += summary.castleBonusGold ?? 0;
        acc.reaction += summary.averageReaction ?? 0;
        acc.duration += summary.duration;
        return acc;
      },
      {
        count: 0,
        accuracy: 0,
        breaches: 0,
        enemies: 0,
        dps: 0,
        turretDps: 0,
        typingDps: 0,
        turretDamage: 0,
        typingDamage: 0,
        shieldBreaks: 0,
        repairsUsed: 0,
        repairHealth: 0,
        repairGold: 0,
        goldEarned: 0,
        perfectWords: 0,
        bonusGold: 0,
        castleBonus: 0,
        reaction: 0,
        duration: 0
      }
    );

    if (totals.count > 0) {
      const summaryRow = document.createElement("tr");
      summaryRow.className = "analytics-summary-row";
      summaryRow.dataset.practice =
        summaryModeLabel === "Practice" ? "true" : summaryModeLabel === "Mixed" ? "mixed" : "false";

      const waveCell = document.createElement("td");
      waveCell.textContent = "Summary";

      const modeCell = document.createElement("td");
      modeCell.textContent = summaryModeLabel;

      const accuracyCell = document.createElement("td");
      const avgAccuracy = totals.accuracy / totals.count;
      accuracyCell.textContent = `${(avgAccuracy * 100).toFixed(1)}% avg`;

      const breachCell = document.createElement("td");
      breachCell.textContent = `${totals.breaches}`;

      const defeatedCell = document.createElement("td");
      defeatedCell.textContent = `${totals.enemies}`;

      const perfectWordsCell = document.createElement("td");
      perfectWordsCell.textContent = `${Math.round(totals.perfectWords)}`;

      const reactionCell = document.createElement("td");
      reactionCell.textContent =
        totals.reaction > 0 ? `${(totals.reaction / totals.count).toFixed(2)}s` : "—";

      const totalDpsCell = document.createElement("td");
      totalDpsCell.textContent = (totals.dps / totals.count).toFixed(1);

      const turretDpsCell = document.createElement("td");
      turretDpsCell.textContent = (totals.turretDps / totals.count).toFixed(1);

      const typingDpsCell = document.createElement("td");
      typingDpsCell.textContent = (totals.typingDps / totals.count).toFixed(1);

      const turretDamageCell = document.createElement("td");
      turretDamageCell.textContent = `${Math.round(totals.turretDamage)}`;

      const typingDamageCell = document.createElement("td");
      typingDamageCell.textContent = `${Math.round(totals.typingDamage)}`;

      const shieldBreakCell = document.createElement("td");
      shieldBreakCell.textContent = `${Math.round(totals.shieldBreaks)}`;

      const repairCountCell = document.createElement("td");
      repairCountCell.textContent = `${Math.round(totals.repairsUsed)}`;

      const repairHealthCell = document.createElement("td");
      repairHealthCell.textContent = `${Math.round(totals.repairHealth)}`;

      const repairGoldCell = document.createElement("td");
      const totalRepairGold = Math.round(totals.repairGold);
      repairGoldCell.textContent = `${totalRepairGold}g`;

      const goldCell = document.createElement("td");
      const totalGold = Math.round(totals.goldEarned);
      goldCell.textContent = `${totalGold >= 0 ? "+" : ""}${totalGold}g`;

      const bonusGoldCell = document.createElement("td");
      const totalBonusGold = Math.round(totals.bonusGold);
      bonusGoldCell.textContent =
        totalBonusGold !== 0 ? `${totalBonusGold >= 0 ? "+" : ""}${totalBonusGold}g` : "—";

      const castleBonusCell = document.createElement("td");
      const totalCastleBonus = Math.round(totals.castleBonus);
      castleBonusCell.textContent =
        totalCastleBonus !== 0 ? `${totalCastleBonus >= 0 ? "+" : ""}${totalCastleBonus}g` : "—";

      const durationCell = document.createElement("td");
      durationCell.textContent = `${(totals.duration / totals.count).toFixed(1)}s avg`;

      summaryRow.appendChild(waveCell);
      summaryRow.appendChild(modeCell);
      summaryRow.appendChild(accuracyCell);
      summaryRow.appendChild(breachCell);
      summaryRow.appendChild(defeatedCell);
      summaryRow.appendChild(perfectWordsCell);
      summaryRow.appendChild(reactionCell);
      summaryRow.appendChild(totalDpsCell);
      summaryRow.appendChild(turretDpsCell);
      summaryRow.appendChild(typingDpsCell);
      summaryRow.appendChild(turretDamageCell);
      summaryRow.appendChild(typingDamageCell);
      summaryRow.appendChild(shieldBreakCell);
      summaryRow.appendChild(repairCountCell);
      summaryRow.appendChild(repairHealthCell);
      summaryRow.appendChild(repairGoldCell);
      summaryRow.appendChild(goldCell);
      summaryRow.appendChild(bonusGoldCell);
      summaryRow.appendChild(castleBonusCell);
      summaryRow.appendChild(durationCell);

      tableBody.appendChild(summaryRow);
    }

    for (const summary of [...filteredSummaries].reverse()) {
      const row = document.createElement("tr");
      const modeValue = summary.mode ?? fallbackMode;
      if (summary.index === recentIndex) {
        row.dataset.recent = "true";
      } else {
        delete row.dataset.recent;
      }
      row.dataset.practice = modeValue === "practice" ? "true" : "false";

      const waveCell = document.createElement("td");
      waveCell.textContent = `#${summary.index + 1}`;

      const modeCell = document.createElement("td");
      modeCell.textContent = modeValue === "practice" ? "Practice" : "Campaign";

      const accuracyCell = document.createElement("td");
      accuracyCell.textContent = `${(summary.accuracy * 100).toFixed(1)}%`;

      const breachCell = document.createElement("td");
      breachCell.textContent = `${summary.breaches}`;

      const defeatedCell = document.createElement("td");
      defeatedCell.textContent = `${summary.enemiesDefeated}`;

      const perfectWordsCell = document.createElement("td");
      perfectWordsCell.textContent = `${Math.max(0, Math.floor(summary.perfectWords ?? 0))}`;

      const reactionCell = document.createElement("td");
      reactionCell.textContent = `${(summary.averageReaction ?? 0).toFixed(2)}s`;

      const totalDpsCell = document.createElement("td");
      totalDpsCell.textContent = summary.dps.toFixed(1);

      const turretDpsCell = document.createElement("td");
      turretDpsCell.textContent = (summary.turretDps ?? 0).toFixed(1);

      const typingDpsCell = document.createElement("td");
      typingDpsCell.textContent = (summary.typingDps ?? 0).toFixed(1);

      const turretDamageCell = document.createElement("td");
      turretDamageCell.textContent = `${Math.round(summary.turretDamage ?? 0)}`;

      const typingDamageCell = document.createElement("td");
      typingDamageCell.textContent = `${Math.round(summary.typingDamage ?? 0)}`;

      const shieldBreakCell = document.createElement("td");
      shieldBreakCell.textContent = `${Math.max(0, Math.floor(summary.shieldBreaks ?? 0))}`;

      const repairCountCell = document.createElement("td");
      repairCountCell.textContent = `${Math.max(0, Math.floor(summary.repairsUsed ?? 0))}`;

      const repairHealthCell = document.createElement("td");
      repairHealthCell.textContent = `${Math.round(summary.repairHealth ?? 0)}`;

      const repairGoldCell = document.createElement("td");
      const repairGoldValue = Math.round(summary.repairGold ?? 0);
      repairGoldCell.textContent = `${repairGoldValue}g`;

      const goldCell = document.createElement("td");
      const gold = Math.round(summary.goldEarned);
      goldCell.textContent = `${gold >= 0 ? "+" : ""}${gold}g`;

      const bonusGoldCell = document.createElement("td");
      const bonusGold = Math.round(summary.bonusGold ?? 0);
      bonusGoldCell.textContent =
        bonusGold !== 0 ? `${bonusGold >= 0 ? "+" : ""}${bonusGold}g` : "—";

      const castleBonusCell = document.createElement("td");
      const castleBonus = Math.round(summary.castleBonusGold ?? 0);
      castleBonusCell.textContent =
        castleBonus !== 0 ? `${castleBonus >= 0 ? "+" : ""}${castleBonus}g` : "—";

      const durationCell = document.createElement("td");
      durationCell.textContent = `${summary.duration.toFixed(1)}s`;

      row.appendChild(waveCell);
      row.appendChild(modeCell);
      row.appendChild(accuracyCell);
      row.appendChild(breachCell);
      row.appendChild(defeatedCell);
      row.appendChild(perfectWordsCell);
      row.appendChild(reactionCell);
      row.appendChild(totalDpsCell);
      row.appendChild(turretDpsCell);
      row.appendChild(typingDpsCell);
      row.appendChild(turretDamageCell);
      row.appendChild(typingDamageCell);
      row.appendChild(shieldBreakCell);
      row.appendChild(repairCountCell);
      row.appendChild(repairHealthCell);
      row.appendChild(repairGoldCell);
      row.appendChild(goldCell);
      row.appendChild(bonusGoldCell);
      row.appendChild(castleBonusCell);
      row.appendChild(durationCell);

      tableBody.appendChild(row);
    }
  }

  private setOptionsOverlayVisible(visible: boolean): void {
    if (!this.optionsOverlay) return;
    this.optionsOverlay.container.dataset.visible = visible ? "true" : "false";
    if (visible) {
      this.optionsOverlay.resumeButton.focus();
    } else {
      this.focusTypingInput();
    }
  }

  private updateEvacuation(state: GameState): void {
    if (!this.evacBanner) return;
    const evac =
      state.evacuation ?? {
        active: false,
        succeeded: false,
        failed: false,
        remaining: 0,
        duration: 0,
        lane: null,
        word: null,
        enemyId: null
      };
    const container = this.evacBanner.container;
    const title = this.evacBanner.title;
    const timerLabel = this.evacBanner.timer;
    const statusLabel = this.evacBanner.status;
    const reward = Math.max(0, this.config.evacuation?.rewardGold ?? 0);
    const penalty = Math.max(0, this.config.evacuation?.failPenaltyGold ?? 0);
    const visible = evac.active || evac.succeeded || evac.failed;

    if (!visible) {
      container.dataset.visible = "false";
      container.style.display = "none";
      statusLabel.textContent = "";
      this.evacResolvedState = "idle";
      if (this.evacHideTimeout) {
        clearTimeout(this.evacHideTimeout);
        this.evacHideTimeout = null;
      }
      return;
    }

    container.dataset.visible = "true";
    container.style.display = "flex";

    const laneLabel = this.formatLaneLabel(evac.lane);
    const wordLabel = evac.word ? `"${evac.word}"` : "transport";
    title.textContent = `${laneLabel} evacuation — ${wordLabel}`;

    const progressRatio =
      evac.duration > 0 ? Math.min(1, Math.max(0, (evac.duration - evac.remaining) / evac.duration)) : 0;
    this.evacBanner.progress.style.width = `${progressRatio * 100}%`;

    if (evac.succeeded) {
      container.dataset.state = "success";
      timerLabel.textContent = "Evacuated";
      statusLabel.textContent = reward > 0 ? `Reward +${reward}g` : "Evacuation secured";
      this.evacBanner.progress.style.width = "100%";
      if (this.evacResolvedState !== "success") {
        this.evacResolvedState = "success";
        this.scheduleEvacHide();
      }
      return;
    }

    if (evac.failed) {
      container.dataset.state = "fail";
      timerLabel.textContent = "Failed";
      statusLabel.textContent = penalty > 0 ? `Penalty -${penalty}g` : "Evacuation failed";
      if (this.evacResolvedState !== "fail") {
        this.evacResolvedState = "fail";
        this.scheduleEvacHide();
      }
      return;
    }

    this.evacResolvedState = "idle";
    if (this.evacHideTimeout) {
      clearTimeout(this.evacHideTimeout);
      this.evacHideTimeout = null;
    }
    container.dataset.state = "active";
    timerLabel.textContent = `${evac.remaining.toFixed(1)}s remaining`;
    statusLabel.textContent = `Hold until transport clears`;
  }

  private scheduleEvacHide(): void {
    if (this.evacHideTimeout) {
      clearTimeout(this.evacHideTimeout);
    }
    this.evacHideTimeout = setTimeout(() => {
      if (!this.evacBanner) return;
      this.evacBanner.container.dataset.visible = "false";
      this.evacBanner.container.style.display = "none";
      this.evacResolvedState = "idle";
      this.evacHideTimeout = null;
    }, 2200);
  }

  private formatLaneLabel(lane: number | null): string {
    if (!Number.isFinite(lane)) {
      return "Lane ?";
    }
    const index = Math.max(0, Math.floor(lane ?? 0));
    const letter = String.fromCharCode(65 + (index % 26));
    return `Lane ${letter}`;
  }
}
