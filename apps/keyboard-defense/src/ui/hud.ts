import { CastleLevelConfig, GameConfig } from "../core/config.js";
import {
  CastlePassive,
  GameMode,
  GameState,
  TurretTargetPriority,
  TurretTypeId,
  WaveSpawnPreview,
  WaveSummary
} from "../core/types.js";
import { WavePreviewPanel } from "./wavePreview.js";

let hudInstanceCounter = 0;

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
  onPauseRequested(): void;
  onResumeRequested(): void;
  onSoundToggle(enabled: boolean): void;
  onSoundVolumeChange(volume: number): void;
  onDiagnosticsToggle(visible: boolean): void;
  onWaveScorecardContinue(): void;
  onReducedMotionToggle(enabled: boolean): void;
  onCheckeredBackgroundToggle(enabled: boolean): void;
  onReadableFontToggle(enabled: boolean): void;
  onDyslexiaFontToggle(enabled: boolean): void;
  onColorblindPaletteToggle(enabled: boolean): void;
  onHudFontScaleChange(scale: number): void;
  onTurretHover?: (
    slotId: string | null,
    context?: { typeId?: TurretTypeId | null; level?: number | null }
  ) => void;
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
  diagnosticsToggle: string;
  reducedMotionToggle: string;
  checkeredBackgroundToggle: string;
  readableFontToggle: string;
  dyslexiaFontToggle: string;
  colorblindPaletteToggle: string;
  fontScaleSelect: string;
  telemetryToggle?: string;
  telemetryToggleWrapper?: string;
  crystalPulseToggle?: string;
  crystalPulseToggleWrapper?: string;
  analyticsExportButton?: string;
};

type AnalyticsViewerElements = {
  container: string;
  tableBody: string;
  filterSelect?: string;
};

type WaveScorecardElements = {
  container: string;
  stats: string;
  continue: string;
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

export class HudView {
  private readonly healthBar: HTMLElement;
  private readonly goldLabel: HTMLElement;
  private readonly goldDelta: HTMLElement;
  private readonly activeWord: HTMLElement;
  private readonly typingInput: HTMLInputElement;
  private readonly upgradePanel: HTMLElement;
  private readonly comboLabel: HTMLElement;
  private readonly logList: HTMLUListElement;
  private readonly tutorialBanner?: HTMLElement;
  private readonly castleButton: HTMLButtonElement;
  private readonly castleRepairButton: HTMLButtonElement;
  private readonly castleStatus: HTMLSpanElement;
  private readonly castleBenefits: HTMLUListElement;
  private readonly castlePassives: HTMLUListElement;
  private readonly wavePreview: WavePreviewPanel;
  private readonly slotControls = new Map<string, SlotControls>();
  private readonly presetControls = new Map<string, PresetControl>();
  private presetContainer: HTMLDivElement | null = null;
  private presetList: HTMLDivElement | null = null;
  private readonly analyticsViewer?: {
    container: HTMLElement;
    tableBody: HTMLTableSectionElement;
    filterSelect?: HTMLSelectElement;
  };
  private analyticsViewerVisible = false;
  private analyticsViewerSignature = "";
  private analyticsViewerFilter: AnalyticsViewerFilter = "all";
  private analyticsViewerFilterSelect?: HTMLSelectElement;
  private lastShieldTelemetry = { current: false, next: false };
  private lastGold = 0;
  private maxCombo = 0;
  private goldTimeout: number | null = null;
  private readonly logEntries: string[] = [];
  private readonly logLimit = 6;
  private tutorialSlotLock: TutorialSlotLock | null = null;
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
  private optionsCastleBonus?: HTMLElement;
  private optionsCastleBenefits?: HTMLUListElement;
  private optionsCastlePassives?: HTMLUListElement;
  private wavePreviewHint?: HTMLElement;
  private wavePreviewHintMessage = DEFAULT_WAVE_PREVIEW_HINT;
  private readonly optionsOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    resumeButton: HTMLButtonElement;
    soundToggle: HTMLInputElement;
    soundVolumeSlider: HTMLInputElement;
    soundVolumeValue: HTMLElement;
    diagnosticsToggle: HTMLInputElement;
    reducedMotionToggle: HTMLInputElement;
    checkeredBackgroundToggle: HTMLInputElement;
    readableFontToggle: HTMLInputElement;
    dyslexiaFontToggle: HTMLInputElement;
    colorblindPaletteToggle: HTMLInputElement;
    fontScaleSelect: HTMLSelectElement;
    telemetryToggle?: HTMLInputElement;
    telemetryWrapper?: HTMLElement;
    crystalPulseToggle?: HTMLInputElement;
    crystalPulseWrapper?: HTMLElement;
    analyticsExportButton?: HTMLButtonElement;
  };
  private readonly waveScorecard?: {
    container: HTMLElement;
    statsList: HTMLUListElement;
    continueBtn: HTMLButtonElement;
  };
  private syncingOptionToggles = false;

  constructor(
    private readonly config: GameConfig,
    rootIds: {
      healthBar: string;
      goldLabel: string;
      goldDelta: string;
      activeWord: string;
      typingInput: string;
      upgradePanel: string;
      comboLabel: string;
      eventLog: string;
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
    },
    private readonly callbacks: HudCallbacks
  ) {
    this.healthBar = this.getElement(rootIds.healthBar);
    this.goldLabel = this.getElement(rootIds.goldLabel);
    this.goldDelta = this.getElement(rootIds.goldDelta);
    this.activeWord = this.getElement(rootIds.activeWord);
    this.typingInput = this.getElement(rootIds.typingInput) as HTMLInputElement;
    this.upgradePanel = this.getElement(rootIds.upgradePanel);
    this.comboLabel = this.getElement(rootIds.comboLabel);
    this.logList = this.getElement(rootIds.eventLog) as HTMLUListElement;

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
    this.availableTurretTypes = Object.fromEntries(
      Object.keys(this.config.turretArchetypes).map((typeId) => [typeId, true])
    );
    this.tutorialBanner = document.getElementById(rootIds.tutorialBanner) ?? undefined;
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
      const diagnosticsToggle = document.getElementById(rootIds.optionsOverlay.diagnosticsToggle);
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
        diagnosticsToggle instanceof HTMLInputElement &&
        reducedMotionToggle instanceof HTMLInputElement &&
        checkeredBackgroundToggle instanceof HTMLInputElement &&
        readableFontToggle instanceof HTMLInputElement &&
        dyslexiaFontToggle instanceof HTMLInputElement &&
        colorblindPaletteToggle instanceof HTMLInputElement &&
        fontScaleSelect instanceof HTMLSelectElement
      ) {
        this.optionsOverlay = {
          container: optionsContainer,
          closeButton,
          resumeButton,
          soundToggle,
          soundVolumeSlider,
          soundVolumeValue,
          diagnosticsToggle,
          reducedMotionToggle,
          checkeredBackgroundToggle,
          readableFontToggle,
          dyslexiaFontToggle,
          colorblindPaletteToggle,
          fontScaleSelect,
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
        if (castleBenefitsList instanceof HTMLUListElement) {
          this.optionsCastleBenefits = castleBenefitsList;
          this.optionsCastleBenefits.replaceChildren();
        } else {
          console.warn("Options castle benefits element missing; upgrade summary disabled.");
        }
        const castlePassivesList = document.getElementById("options-castle-passives");
        if (castlePassivesList instanceof HTMLUListElement) {
          this.optionsCastlePassives = castlePassivesList;
          this.optionsCastlePassives.replaceChildren();
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
        diagnosticsToggle.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          this.callbacks.onDiagnosticsToggle(diagnosticsToggle.checked);
        });
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
        fontScaleSelect.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          const nextValue = Number.parseFloat(fontScaleSelect.value);
          if (!Number.isFinite(nextValue)) return;
          this.callbacks.onHudFontScaleChange(nextValue);
        });
        if (this.optionsOverlay.telemetryToggle) {
          this.optionsOverlay.telemetryToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onTelemetryToggle?.(this.optionsOverlay!.telemetryToggle!.checked);
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
      const scorecardStats = document.getElementById(
        rootIds.waveScorecard.stats
      ) as HTMLUListElement | null;
      const scorecardContinue = document.getElementById(rootIds.waveScorecard.continue);
      if (
        scorecardContainer instanceof HTMLElement &&
        scorecardStats instanceof HTMLUListElement &&
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
      if (viewerContainer instanceof HTMLElement && viewerBody instanceof HTMLTableSectionElement) {
        this.analyticsViewer = {
          container: viewerContainer,
          tableBody: viewerBody,
          filterSelect: viewerFilter instanceof HTMLSelectElement ? viewerFilter : undefined
        };
        this.analyticsViewerVisible = viewerContainer.dataset.visible === "true";
        viewerContainer.setAttribute("aria-hidden", this.analyticsViewerVisible ? "false" : "true");
        if (this.analyticsViewer.filterSelect) {
          this.analyticsViewerFilterSelect = this.analyticsViewer.filterSelect;
          this.analyticsViewerFilterSelect.value = this.analyticsViewerFilter;
          this.analyticsViewerFilterSelect.addEventListener("change", () => {
            const next = this.normalizeAnalyticsViewerFilter(
              this.analyticsViewerFilterSelect?.value ?? "all"
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
              this.analyticsViewerFilterSelect.value = this.analyticsViewerFilter;
            }
          });
        }
      } else {
        console.warn("Analytics viewer elements missing; debug analytics viewer disabled.");
      }
    }

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
    this.castlePassives = document.createElement("ul");
    this.castlePassives.className = "castle-passives";
    this.castlePassives.dataset.visible = "false";
    this.castlePassives.hidden = true;
    this.castlePassives.setAttribute("aria-label", "Active castle passive buffs");
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
    castleWrap.appendChild(this.castlePassives);
    castleWrap.appendChild(this.castleBenefits);
    this.upgradePanel.appendChild(castleWrap);

    this.castleButton.addEventListener("click", () => {
      this.callbacks.onCastleUpgrade();
    });
    this.castleRepairButton.addEventListener("click", () => {
      this.callbacks.onCastleRepair();
    });

    this.createTurretControls();
  }

  focusTypingInput(): void {
    this.typingInput.focus();
  }

  showShortcutOverlay(): void {
    this.setShortcutOverlayVisible(true);
  }

  hideShortcutOverlay(): void {
    this.setShortcutOverlayVisible(false);
  }

  toggleShortcutOverlay(): void {
    this.setShortcutOverlayVisible(!this.isShortcutOverlayVisible());
  }

  isShortcutOverlayVisible(): boolean {
    if (!this.shortcutOverlay) return false;
    return this.shortcutOverlay.container.dataset.visible === "true";
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
    diagnosticsVisible: boolean;
    reducedMotionEnabled: boolean;
    checkeredBackgroundEnabled: boolean;
    readableFontEnabled: boolean;
    dyslexiaFontEnabled: boolean;
    colorblindPaletteEnabled: boolean;
    hudFontScale: number;
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
    this.optionsOverlay.diagnosticsToggle.checked = state.diagnosticsVisible;
    this.optionsOverlay.reducedMotionToggle.checked = state.reducedMotionEnabled;
    this.optionsOverlay.checkeredBackgroundToggle.checked = state.checkeredBackgroundEnabled;
    this.optionsOverlay.readableFontToggle.checked = state.readableFontEnabled;
    this.optionsOverlay.dyslexiaFontToggle.checked = state.dyslexiaFontEnabled;
    this.optionsOverlay.colorblindPaletteToggle.checked = state.colorblindPaletteEnabled;
    this.optionsOverlay.fontScaleSelect.value = state.hudFontScale.toString();
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
    options: { colorBlindFriendly?: boolean } = {}
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

    this.wavePreview.setColorBlindFriendly(Boolean(options.colorBlindFriendly));
    this.updateCastleControls(state);
    this.updateTurretControls(state);
    this.updateCombo(state.typing.combo, state.typing.comboWarning, state.typing.comboTimer);
    this.wavePreview.render(upcoming);
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
    if (!this.tutorialBanner) return;
    if (!message) {
      this.tutorialBanner.dataset.visible = "false";
      this.tutorialBanner.textContent = "";
      delete this.tutorialBanner.dataset.highlight;
      return;
    }
    this.tutorialBanner.dataset.visible = "true";
    if (highlight) {
      this.tutorialBanner.dataset.highlight = "true";
    } else {
      delete this.tutorialBanner.dataset.highlight;
    }
    this.tutorialBanner.textContent = message;
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
    this.wavePreview.setTutorialHighlight(active);
    this.updateWavePreviewHint(active, message ?? null);
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
      list.dataset.visible = "false";
      list.hidden = true;
      return;
    }
    list.dataset.visible = "true";
    list.hidden = false;
    for (const passive of passives) {
      const item = document.createElement("li");
      item.textContent = this.formatCastlePassive(passive);
      list.appendChild(item);
    }
  }

  private renderOptionsCastlePassives(passives: CastlePassive[]): void {
    if (!this.optionsCastlePassives) return;
    const list = this.optionsCastlePassives;
    list.replaceChildren();
    if (!passives.length) {
      const item = document.createElement("li");
      item.textContent = "No passive buffs unlocked yet.";
      list.appendChild(item);
      return;
    }
    for (const passive of passives) {
      const item = document.createElement("li");
      item.textContent = this.formatCastlePassive(passive, { includeDelta: true });
      list.appendChild(item);
    }
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
      controls.prioritySelect.value = priority;

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
        let selectedType = (controls.select.value as TurretTypeId) ?? "arrow";
        if (!this.isTurretTypeEnabled(selectedType)) {
          const fallback = this.pickFirstEnabledTurretType();
          if (fallback) {
            controls.select.value = fallback;
            selectedType = fallback;
          }
        }
        const archetype = this.config.turretArchetypes[selectedType];
        const typeName = this.getTurretDisplayName(selectedType);
        const cost = archetype?.levels[0]?.cost ?? 0;
        const typeEnabled = this.isTurretTypeEnabled(selectedType);
        const hasEnabledTypes = this.hasEnabledTurretTypes();
        controls.select.disabled = !hasEnabledTypes;
        if (typeEnabled) {
          controls.action.onclick = () => {
            this.callbacks.onPlaceTurret(slot.id, controls.select.value as TurretTypeId);
          };
          const affordable = state.resources.gold >= cost;
          controls.action.disabled = !affordable;
          controls.action.textContent = `Place (${cost}g)`;
        } else {
          controls.action.onclick = null;
          controls.action.disabled = true;
          controls.action.textContent = `${typeName} (Disabled)`;
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
            controls.select.value = lock.forcedType;
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
    const selected = controls.select.value as TurretTypeId | "";
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
        select.appendChild(option);
      }
      this.applyAvailabilityToSelect(select);
      const firstEnabled = this.pickFirstEnabledTurretType();
      if (firstEnabled) {
        select.value = firstEnabled;
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
        const next = this.normalizePriority(prioritySelect.value);
        if (!next) {
          prioritySelect.value = "first";
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
    select.value = "first";
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

  private updateCombo(combo: number, warning: boolean, timer: number): void {
    this.maxCombo = Math.max(this.maxCombo, combo);
    if (combo > 0) {
      this.comboLabel.dataset.active = "true";
      const warningActive = warning && timer > 0;
      if (warningActive) {
        this.comboLabel.dataset.warning = "true";
        const seconds = Math.max(0, timer).toFixed(1);
        this.comboLabel.textContent = `Combo x${combo} (Best x${this.maxCombo}) - ${seconds}s`;
      } else {
        delete this.comboLabel.dataset.warning;
        this.comboLabel.textContent = `Combo x${combo} (Best x${this.maxCombo})`;
      }
    } else {
      this.comboLabel.dataset.active = "false";
      delete this.comboLabel.dataset.warning;
      this.comboLabel.textContent = `Combo x0 (Best x${this.maxCombo})`;
    }
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

  getShieldForecast(): { current: boolean; next: boolean } {
    return { ...this.lastShieldTelemetry };
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

  setAnalyticsExportEnabled(enabled: boolean): void {
    const button = this.optionsOverlay?.analyticsExportButton;
    if (!button) return;
    if (enabled) {
      button.style.display = "";
      button.disabled = false;
      button.setAttribute("aria-hidden", "false");
      button.tabIndex = 0;
    } else {
      button.style.display = "none";
      button.disabled = true;
      button.setAttribute("aria-hidden", "true");
      button.tabIndex = -1;
    }
  }

  setHudFontScale(scale: number): void {
    if (typeof document === "undefined") return;
    document.documentElement.style.setProperty("--hud-font-scale", scale.toString());
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

  setAnalyticsViewerVisible(visible: boolean): boolean {
    if (!this.analyticsViewer) {
      return false;
    }
    this.analyticsViewerVisible = visible;
    const { container } = this.analyticsViewer;
    container.dataset.visible = visible ? "true" : "false";
    container.setAttribute("aria-hidden", visible ? "false" : "true");
    if (visible && this.analyticsViewerFilterSelect) {
      this.analyticsViewerFilterSelect.value = this.analyticsViewerFilter;
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

  private refreshAnalyticsViewer(
    summaries: WaveSummary[],
    options: { force?: boolean; timeToFirstTurret?: number | null } = {}
  ): void {
    if (!this.analyticsViewer) {
      return;
    }
    const { force = false, timeToFirstTurret = null } = options;
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
}
