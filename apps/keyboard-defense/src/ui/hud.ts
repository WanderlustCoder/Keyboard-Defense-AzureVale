import { type CastleLevelConfig, type GameConfig } from "../core/config.js";
import {
  type CastlePassive,
  type GameMode,
  type GameState,
  type GoldEvent,
  type DefeatAnimationPreference,
  type TypingDrillMode,
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
import { type SeasonTrackViewState } from "../data/seasonTrack.js";
import { type LessonMedalTier, type LessonMedalViewState } from "../utils/lessonMedals.js";
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

const FINGER_SHIFTED_KEY_MAP: Record<string, string> = {
  "!": "1",
  "@": "2",
  "#": "3",
  $: "4",
  "%": "5",
  "^": "6",
  "&": "7",
  "*": "8",
  "(": "9",
  ")": "0",
  _: "-",
  "+": "=",
  "{": "[",
  "}": "]",
  ":": ";",
  '"': "'",
  "|": "\\",
  "<": ",",
  ">": ".",
  "?": "/",
  "~": "`"
};

const FINGER_LOOKUP: Record<string, string> = (() => {
  const zones: Array<[string, string[]]> = [
    ["Left pinky", ["`", "1", "q", "a", "z"]],
    ["Left ring", ["2", "w", "s", "x"]],
    ["Left middle", ["3", "e", "d", "c"]],
    ["Left index", ["4", "5", "r", "t", "f", "g", "v", "b"]],
    ["Right index", ["6", "7", "y", "u", "h", "j", "n", "m"]],
    ["Right middle", ["8", "i", "k", ","]],
    ["Right ring", ["9", "o", "l", "."]],
    ["Right pinky", ["0", "-", "=", "p", "[", "]", ";", "'", "/", "\\"]]
  ];
  const map: Record<string, string> = {};
  for (const [finger, keys] of zones) {
    for (const key of keys) {
      map[key] = finger;
      map[key.toLowerCase()] = finger;
      map[key.toUpperCase()] = finger;
    }
  }
  return map;
})();
const ACCESSIBILITY_SELF_TEST_DEFAULT = {
  lastRunAt: null,
  soundConfirmed: false,
  visualConfirmed: false,
  motionConfirmed: false
};
const CERTIFICATE_NAME_KEY = "keyboard-defense:certificate-name";

type CastleSkinId = "classic" | "dusk" | "aurora" | "ember";
type CompanionMood = "calm" | "happy" | "cheer" | "sad";

type ContrastAuditResult = {
  label: string;
  ratio: number;
  status: "pass" | "warn" | "fail";
  rect: { x: number; y: number; width: number; height: number };
};

type StickerBookEntry = {
  id: string;
  title: string;
  description: string;
  icon: "castle" | "combo" | "shield" | "treasure" | "scroll" | "drill" | "perfect" | "calm";
  status: "locked" | "unlocked" | "in-progress";
  progress: number;
  goal: number;
  unlockedLabel?: string;
};

export type LoreScrollViewEntry = {
  id: string;
  title: string;
  summary: string;
  body: string;
  requiredLessons: number;
  unlocked: boolean;
  progress: number;
  remaining: number;
};

export type LoreScrollViewState = {
  lessonsCompleted: number;
  total: number;
  unlocked: number;
  next?: { requiredLessons: number; remaining: number; title: string } | null;
  entries: LoreScrollViewEntry[];
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
  onScreenShakeToggle?: (enabled: boolean) => void;
  onScreenShakeIntensityChange?: (intensity: number) => void;
  onScreenShakePreview?: () => void;
  onContrastAuditRequested?: () => void;
  onCastleSkinChange?: (skin: CastleSkinId) => void;
  onAccessibilitySelfTestRun?: () => void;
  onAccessibilitySelfTestConfirm?: (
    kind: "sound" | "visual" | "motion",
    confirmed: boolean
  ) => void;
  onDiagnosticsToggle(visible: boolean): void;
  onVirtualKeyboardToggle?: (enabled: boolean) => void;
  onLowGraphicsToggle?: (enabled: boolean) => void;
  onTextSizeChange?: (scale: number) => void;
  onHapticsToggle?: (enabled: boolean) => void;
  onWaveScorecardContinue(): void;
  onLessonMedalReplay?: (options?: { mode?: TypingDrillMode; hint?: string }) => void;
  onReducedMotionToggle(enabled: boolean): void;
  onCheckeredBackgroundToggle(enabled: boolean): void;
  onReadableFontToggle(enabled: boolean): void;
  onDyslexiaFontToggle(enabled: boolean): void;
  onDyslexiaSpacingToggle?: (enabled: boolean) => void;
  onCognitiveLoadToggle?: (enabled: boolean) => void;
  onColorblindPaletteToggle(enabled: boolean): void;
  onColorblindPaletteModeChange?: (mode: string) => void;
  onHotkeyPauseChange?: (key: string) => void;
  onHotkeyShortcutsChange?: (key: string) => void;
  onBackgroundBrightnessChange?: (value: number) => void;
  onDefeatAnimationModeChange(mode: DefeatAnimationPreference): void;
  onHudFontScaleChange(scale: number): void;
  onHudZoomChange(scale: number): void;
  onHudLayoutToggle?: (leftHanded: boolean) => void;
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
  screenShakeToggle?: string;
  screenShakeSlider?: string;
  screenShakeValue?: string;
  screenShakePreview?: string;
  screenShakeDemo?: string;
  contrastAuditButton?: string;
  selfTestContainer?: string;
  selfTestRun?: string;
  selfTestStatus?: string;
  selfTestSoundToggle?: string;
  selfTestVisualToggle?: string;
  selfTestMotionToggle?: string;
  selfTestSoundIndicator?: string;
  selfTestVisualIndicator?: string;
  selfTestMotionIndicator?: string;
  diagnosticsToggle: string;
  virtualKeyboardToggle?: string;
  lowGraphicsToggle: string;
  textSizeSelect?: string;
  hapticsToggle?: string;
  reducedMotionToggle: string;
  checkeredBackgroundToggle: string;
  readableFontToggle: string;
  dyslexiaFontToggle: string;
  dyslexiaSpacingToggle?: string;
  cognitiveLoadToggle?: string;
  colorblindPaletteToggle: string;
  colorblindPaletteSelect?: string;
  hotkeyPauseSelect?: string;
  hotkeyShortcutsSelect?: string;
  backgroundBrightnessSlider?: string;
  backgroundBrightnessValue?: string;
  fontScaleSelect: string;
  hudZoomSelect: string;
  hudLayoutToggle?: string;
  castleSkinSelect?: string;
  defeatAnimationSelect: string;
  stickerBookButton?: string;
  seasonTrackButton?: string;
  lessonMedalButton?: string;
  museumButton?: string;
  sideQuestButton?: string;
  masteryCertificateButton?: string;
  loreScrollsButton?: string;
  parentSummaryButton?: string;
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
  tip?: string;
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

type ParentalOverlayElements = {
  container: string;
  closeButton: string;
};

type ContrastOverlayElements = {
  container: string;
  list: string;
  summary: string;
  closeButton: string;
  markers: string;
};

type StickerBookOverlayElements = {
  container: string;
  list: string;
  summary: string;
  closeButton: string;
};

type LoreScrollOverlayElements = {
  container: string;
  list: string;
  summary: string;
  progress?: string;
  closeButton: string;
};

type SeasonTrackOverlayElements = {
  container: string;
  list: string;
  progress: string;
  lessons?: string;
  next?: string;
  closeButton: string;
};

type LessonMedalOverlayElements = {
  container: string;
  closeButton: string;
  badge?: string;
  last?: string;
  next?: string;
  bestList?: string;
  historyList?: string;
  replayButton?: string;
};

type MuseumOverlayElements = {
  container: string;
  closeButton: string;
  list: string;
  subtitle?: string;
};

type SideQuestOverlayElements = {
  container: string;
  closeButton: string;
  list: string;
  subtitle?: string;
};

type MasteryCertificateElements = {
  container: string;
  closeButton: string;
  downloadButton?: string;
  nameInput?: string;
  summary?: string;
  statsList?: string;
  date?: string;
};

type MentorFocus = "accuracy" | "speed" | "neutral";

type ParentSummaryOverlayElements = {
  container: string;
  closeButton: string;
  closeSecondary?: string;
  title?: string;
  subtitle?: string;
  progress?: string;
  note?: string;
  time?: string;
  accuracy?: string;
  wpm?: string;
  combo?: string;
  perfect?: string;
  breaches?: string;
  drills?: string;
  repairs?: string;
  download?: string;
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
  microTip?: string | null;
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
  private readonly fingerHint: HTMLElement | null = null;
  private readonly typingInput: HTMLInputElement;
  private companionPet: HTMLElement | null = null;
  private companionMoodLabel: HTMLElement | null = null;
  private companionTip: HTMLElement | null = null;
  private companionMood: CompanionMood = "calm";
  private readonly fullscreenButton: HTMLButtonElement | null = null;
  private readonly capsLockWarning: HTMLElement | null = null;
  private readonly lockIndicatorCaps: HTMLElement | null = null;
  private readonly lockIndicatorNum: HTMLElement | null = null;
  private readonly upgradePanel: HTMLElement;
  private readonly comboLabel: HTMLElement;
  private readonly comboAccuracyDelta: HTMLElement;
  private readonly logList: HTMLUListElement;
  private readonly tutorialBanner?: TutorialBannerElements;
  private tutorialBannerExpanded = true;
  private readonly virtualKeyboard?: VirtualKeyboard;
  private virtualKeyboardEnabled = false;
  private readonly focusTraps = new Map<HTMLElement, (event: KeyboardEvent) => void>();
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
  private readonly parentalOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
  };
  private readonly contrastOverlay?: {
    container: HTMLElement;
    list: HTMLUListElement;
    summary: HTMLElement;
    closeButton: HTMLButtonElement;
    markers: HTMLElement;
  };
  private readonly stickerBookOverlay?: {
    container: HTMLElement;
    list: HTMLElement;
    summary: HTMLElement;
    closeButton: HTMLButtonElement;
  };
  private stickerBookEntries: StickerBookEntry[] = [];
  private readonly loreScrollOverlay?: {
    container: HTMLElement;
    list: HTMLElement;
    summary: HTMLElement;
    progress?: HTMLElement;
    closeButton: HTMLButtonElement;
  };
  private loreScrollPanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    progress?: HTMLElement;
    lessons?: HTMLElement;
    next?: HTMLElement;
    openButton?: HTMLButtonElement;
  };
  private loreScrollState?: LoreScrollViewState;
  private loreScrollHighlightTimeout: number | null = null;
  private readonly seasonTrackOverlay?: {
    container: HTMLElement;
    list: HTMLElement;
    progress: HTMLElement;
    lessons?: HTMLElement;
    next?: HTMLElement;
    closeButton: HTMLButtonElement;
  };
  private readonly seasonTrackPanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    progress?: HTMLElement;
    lessons?: HTMLElement;
    next?: HTMLElement;
    requirement?: HTMLElement;
    openButton?: HTMLButtonElement;
  };
  private seasonTrackState?: SeasonTrackViewState;
  private readonly lessonMedalOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    badge?: HTMLElement;
    last?: HTMLElement;
    next?: HTMLElement;
    bestList?: HTMLElement;
    historyList?: HTMLElement;
    replayButton?: HTMLButtonElement;
  };
  private readonly lessonMedalPanel?: {
    container?: HTMLElement;
    badge?: HTMLElement;
    summary?: HTMLElement;
    best?: HTMLElement;
    next?: HTMLElement;
    openButton?: HTMLButtonElement;
  };
  private lessonMedalState?: LessonMedalViewState;
  private lessonMedalHighlightTimeout: number | null = null;
  private readonly masteryCertificatePanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    stats?: HTMLElement;
    date?: HTMLElement;
    nameInput?: HTMLInputElement;
    openButton?: HTMLButtonElement;
  };
  private readonly masteryCertificate?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    downloadButton?: HTMLButtonElement;
    nameInput?: HTMLInputElement;
    summary?: HTMLElement;
    statsList?: HTMLElement;
    date?: HTMLElement;
  };
  private readonly sideQuestPanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    stats?: HTMLElement;
    openButton?: HTMLButtonElement;
  };
  private readonly sideQuestOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    list: HTMLElement;
    subtitle?: HTMLElement;
  };
  private sideQuestEntries: Array<{
    id: string;
    title: string;
    description: string;
    progress: number;
    total: number;
    status: "locked" | "active" | "completed";
    meta: string;
  }> = [];
  private lessonsCompletedCount = 0;
  private readonly museumOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    list: HTMLElement;
    subtitle?: HTMLElement;
  };
  private readonly museumPanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    stats?: HTMLElement;
    openButton?: HTMLButtonElement;
  };
  private museumEntries: Array<{ id: string; title: string; description: string; unlocked: boolean; meta: string }> =
    [];
  private certificateName: string = "";
  private certificateStats?: {
    lessonsCompleted: number;
    accuracyPct: number;
    wpm: number;
    bestCombo: number;
    drillsCompleted: number;
    timeMinutes: number;
    recordedAt: string;
  };
  private readonly mentorDialogue?: {
    container: HTMLElement;
    text?: HTMLElement;
    focus?: HTMLElement;
  };
  private mentorFocus: MentorFocus = "neutral";
  private mentorMessageCursor: Record<MentorFocus, number> = {
    accuracy: 0,
    speed: 0,
    neutral: 0
  };
  private mentorNextUpdateAt = 0;
  private readonly milestoneCelebration?: {
    container: HTMLElement;
    title?: HTMLElement;
    detail?: HTMLElement;
    badge?: HTMLElement;
    eyebrow?: HTMLElement;
    closeButton?: HTMLButtonElement;
  };
  private milestoneCelebrationHideTimeout: number | null = null;
  private lastLessonMilestoneCelebrated = 0;
  private lastCertificateCelebratedAt: string | null = null;
  private readonly parentSummaryOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    closeSecondary?: HTMLButtonElement;
    title?: HTMLElement;
    subtitle?: HTMLElement;
    progress?: HTMLElement;
    note?: HTMLElement;
    time?: HTMLElement;
    accuracy?: HTMLElement;
    wpm?: HTMLElement;
    combo?: HTMLElement;
    perfect?: HTMLElement;
    breaches?: HTMLElement;
    drills?: HTMLElement;
    repairs?: HTMLElement;
    download?: HTMLButtonElement;
  };
  private parentSummary?: {
    timeMinutes: number;
    accuracyPct: number;
    wpm: number;
    bestCombo: number;
    perfectWords: number;
    breaches: number;
    drills: number;
    repairs: number;
  };
  private castleSkin: CastleSkinId = "classic";
  private parentalOverlayTrigger?: HTMLElement | null;
  private lastShieldTelemetry = { current: false, next: false };
  private lastAffixTelemetry = { current: false, next: false };
  private lastWavePreviewEntries: WaveSpawnPreview[] = [];
  private lastWavePreviewColorBlind = false;
  private lastGold = 0;
  private maxCombo = 0;
  private goldTimeout: number | null = null;
  private typingAccuracyLabel: HTMLElement | null = null;
  private typingWpmLabel: HTMLElement | null = null;
  private readonly logEntries: string[] = [];
  private typingErrorHint:
    | { expected: string | null; received: string | null; enemyId: string | null; timestamp: number }
    | null = null;
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
    screenShakeToggle?: HTMLInputElement;
    screenShakeSlider?: HTMLInputElement;
    screenShakeValue?: HTMLElement;
    screenShakePreview?: HTMLButtonElement;
    screenShakeDemo?: HTMLElement;
    contrastAuditButton?: HTMLButtonElement;
    stickerBookButton?: HTMLButtonElement;
    seasonTrackButton?: HTMLButtonElement;
    museumButton?: HTMLButtonElement;
    sideQuestButton?: HTMLButtonElement;
    lessonMedalButton?: HTMLButtonElement;
    masteryCertificateButton?: HTMLButtonElement;
    loreScrollsButton?: HTMLButtonElement;
    selfTestContainer?: HTMLElement;
    selfTestRun?: HTMLButtonElement;
    selfTestStatus?: HTMLElement;
    selfTestSoundToggle?: HTMLInputElement;
    selfTestVisualToggle?: HTMLInputElement;
    selfTestMotionToggle?: HTMLInputElement;
    selfTestSoundIndicator?: HTMLElement;
    selfTestVisualIndicator?: HTMLElement;
    selfTestMotionIndicator?: HTMLElement;
    diagnosticsToggle: HTMLInputElement;
    virtualKeyboardToggle?: HTMLInputElement;
    lowGraphicsToggle?: HTMLInputElement;
    textSizeSelect?: HTMLSelectElement;
    hapticsToggle?: HTMLInputElement;
    reducedMotionToggle: HTMLInputElement;
    checkeredBackgroundToggle: HTMLInputElement;
    readableFontToggle: HTMLInputElement;
    dyslexiaFontToggle: HTMLInputElement;
    dyslexiaSpacingToggle?: HTMLInputElement;
    cognitiveLoadToggle?: HTMLInputElement;
    colorblindPaletteToggle: HTMLInputElement;
    colorblindPaletteSelect?: HTMLSelectElement;
    hotkeyPauseSelect?: HTMLSelectElement;
    hotkeyShortcutsSelect?: HTMLSelectElement;
    backgroundBrightnessSlider?: HTMLInputElement;
    backgroundBrightnessValue?: HTMLElement;
    hudZoomSelect: HTMLSelectElement;
    hudLayoutToggle?: HTMLInputElement;
    castleSkinSelect?: HTMLSelectElement;
    fontScaleSelect: HTMLSelectElement;
    defeatAnimationSelect: HTMLSelectElement;
    telemetryToggle?: HTMLInputElement;
    telemetryWrapper?: HTMLElement;
    crystalPulseToggle?: HTMLInputElement;
    crystalPulseWrapper?: HTMLElement;
    eliteAffixToggle?: HTMLInputElement;
    eliteAffixWrapper?: HTMLElement;
    analyticsExportButton?: HTMLButtonElement;
    parentSummaryButton?: HTMLButtonElement;
  };
  private readonly waveScorecard?: {
    container: HTMLElement;
    statsList: HTMLUListElement;
    continueBtn: HTMLButtonElement;
    tip?: HTMLElement;
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
  typingAccuracy?: string;
  typingWpm?: string;
  typingInput: string;
  virtualKeyboard?: string;
  upgradePanel: string;
  comboLabel: string;
  comboAccuracyDelta: string;
      eventLog: string;
      fullscreenButton?: string;
      companionPet?: string;
      companionMoodLabel?: string;
      companionTip?: string;
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
      parentalOverlay?: ParentalOverlayElements;
      contrastOverlay?: ContrastOverlayElements;
      stickerBookOverlay?: StickerBookOverlayElements;
      seasonTrackOverlay?: SeasonTrackOverlayElements;
      museumOverlay?: MuseumOverlayElements;
      sideQuestOverlay?: SideQuestOverlayElements;
      lessonMedalOverlay?: LessonMedalOverlayElements;
      masteryCertificateOverlay?: MasteryCertificateElements;
      loreScrollOverlay?: LoreScrollOverlayElements;
      parentSummaryOverlay?: ParentSummaryOverlayElements;
    },
    private readonly callbacks: HudCallbacks
  ) {
    this.certificateName = this.readCertificateName();
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
    if (rootIds.typingAccuracy) {
      const acc = document.getElementById(rootIds.typingAccuracy);
      this.typingAccuracyLabel = acc instanceof HTMLElement ? acc : null;
    }
    if (rootIds.typingWpm) {
      const wpm = document.getElementById(rootIds.typingWpm);
      this.typingWpmLabel = wpm instanceof HTMLElement ? wpm : null;
    }
    const fingerHintEl = document.getElementById("finger-hint");
    this.fingerHint = fingerHintEl instanceof HTMLElement ? fingerHintEl : null;
    this.typingInput = this.getElement(rootIds.typingInput) as HTMLInputElement;
    if (rootIds.companionPet) {
      const pet = document.getElementById(rootIds.companionPet);
      if (pet instanceof HTMLElement) {
        this.companionPet = pet;
        this.companionPet.dataset.mood = this.companionMood;
        this.companionPet.setAttribute("aria-label", "Companion mood: Calm");
      }
    }
    if (rootIds.companionMoodLabel) {
      const moodLabel = document.getElementById(rootIds.companionMoodLabel);
      if (moodLabel instanceof HTMLElement) {
        this.companionMoodLabel = moodLabel;
        this.companionMoodLabel.textContent = "Calm";
      }
    }
    if (rootIds.companionTip) {
      const tip = document.getElementById(rootIds.companionTip);
      this.companionTip = tip instanceof HTMLElement ? tip : null;
    }
    const lockCaps = document.getElementById("lock-indicator-caps");
    const lockNum = document.getElementById("lock-indicator-num");
    this.lockIndicatorCaps = lockCaps instanceof HTMLElement ? lockCaps : null;
    this.lockIndicatorNum = lockNum instanceof HTMLElement ? lockNum : null;
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
        this.addFocusTrap(shortcutContainer);
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
      const screenShakeToggle = rootIds.optionsOverlay.screenShakeToggle
        ? document.getElementById(rootIds.optionsOverlay.screenShakeToggle)
        : null;
      const screenShakeSlider = rootIds.optionsOverlay.screenShakeSlider
        ? document.getElementById(rootIds.optionsOverlay.screenShakeSlider)
        : null;
      const screenShakeValue = rootIds.optionsOverlay.screenShakeValue
        ? document.getElementById(rootIds.optionsOverlay.screenShakeValue)
        : null;
      const screenShakePreview = rootIds.optionsOverlay.screenShakePreview
        ? document.getElementById(rootIds.optionsOverlay.screenShakePreview)
        : null;
      const screenShakeDemo = rootIds.optionsOverlay.screenShakeDemo
        ? document.getElementById(rootIds.optionsOverlay.screenShakeDemo)
        : null;
      const contrastAuditButton = rootIds.optionsOverlay.contrastAuditButton
        ? document.getElementById(rootIds.optionsOverlay.contrastAuditButton)
        : null;
      const stickerBookButton = rootIds.optionsOverlay.stickerBookButton
        ? document.getElementById(rootIds.optionsOverlay.stickerBookButton)
        : null;
      const seasonTrackButton = rootIds.optionsOverlay.seasonTrackButton
        ? document.getElementById(rootIds.optionsOverlay.seasonTrackButton)
        : null;
      const museumButton = rootIds.optionsOverlay.museumButton
        ? document.getElementById(rootIds.optionsOverlay.museumButton)
        : null;
      const sideQuestButton = rootIds.optionsOverlay.sideQuestButton
        ? document.getElementById(rootIds.optionsOverlay.sideQuestButton)
        : null;
      const masteryCertificateButton = rootIds.optionsOverlay.masteryCertificateButton
        ? document.getElementById(rootIds.optionsOverlay.masteryCertificateButton)
        : null;
      const lessonMedalButton = rootIds.optionsOverlay.lessonMedalButton
        ? document.getElementById(rootIds.optionsOverlay.lessonMedalButton)
        : null;
      const loreScrollsButton = rootIds.optionsOverlay.loreScrollsButton
        ? document.getElementById(rootIds.optionsOverlay.loreScrollsButton)
        : null;
      const parentSummaryButton = rootIds.optionsOverlay.parentSummaryButton
        ? document.getElementById(rootIds.optionsOverlay.parentSummaryButton)
        : null;
      const selfTestContainer = rootIds.optionsOverlay.selfTestContainer
        ? document.getElementById(rootIds.optionsOverlay.selfTestContainer)
        : null;
      const selfTestRun = rootIds.optionsOverlay.selfTestRun
        ? document.getElementById(rootIds.optionsOverlay.selfTestRun)
        : null;
      const selfTestStatus = rootIds.optionsOverlay.selfTestStatus
        ? document.getElementById(rootIds.optionsOverlay.selfTestStatus)
        : null;
      const selfTestSoundToggle = rootIds.optionsOverlay.selfTestSoundToggle
        ? document.getElementById(rootIds.optionsOverlay.selfTestSoundToggle)
        : null;
      const selfTestVisualToggle = rootIds.optionsOverlay.selfTestVisualToggle
        ? document.getElementById(rootIds.optionsOverlay.selfTestVisualToggle)
        : null;
      const selfTestMotionToggle = rootIds.optionsOverlay.selfTestMotionToggle
        ? document.getElementById(rootIds.optionsOverlay.selfTestMotionToggle)
        : null;
      const selfTestSoundIndicator = rootIds.optionsOverlay.selfTestSoundIndicator
        ? document.getElementById(rootIds.optionsOverlay.selfTestSoundIndicator)
        : null;
      const selfTestVisualIndicator = rootIds.optionsOverlay.selfTestVisualIndicator
        ? document.getElementById(rootIds.optionsOverlay.selfTestVisualIndicator)
        : null;
      const selfTestMotionIndicator = rootIds.optionsOverlay.selfTestMotionIndicator
        ? document.getElementById(rootIds.optionsOverlay.selfTestMotionIndicator)
        : null;
      const diagnosticsToggle = document.getElementById(rootIds.optionsOverlay.diagnosticsToggle);
      const virtualKeyboardToggle = rootIds.optionsOverlay.virtualKeyboardToggle
        ? document.getElementById(rootIds.optionsOverlay.virtualKeyboardToggle)
        : null;
      const lowGraphicsToggle = document.getElementById(rootIds.optionsOverlay.lowGraphicsToggle);
      const textSizeSelect = document.getElementById(rootIds.optionsOverlay.textSizeSelect);
      const hapticsToggle = rootIds.optionsOverlay.hapticsToggle
        ? document.getElementById(rootIds.optionsOverlay.hapticsToggle)
        : null;
      const reducedMotionToggle = document.getElementById(
        rootIds.optionsOverlay.reducedMotionToggle
      );
      const checkeredBackgroundToggle = document.getElementById(
        rootIds.optionsOverlay.checkeredBackgroundToggle
      );
      const readableFontToggle = document.getElementById(rootIds.optionsOverlay.readableFontToggle);
      const dyslexiaFontToggle = document.getElementById(rootIds.optionsOverlay.dyslexiaFontToggle);
      const dyslexiaSpacingToggle = rootIds.optionsOverlay.dyslexiaSpacingToggle
        ? document.getElementById(rootIds.optionsOverlay.dyslexiaSpacingToggle)
        : null;
      const cognitiveLoadToggle = rootIds.optionsOverlay.cognitiveLoadToggle
        ? document.getElementById(rootIds.optionsOverlay.cognitiveLoadToggle)
        : null;
      const backgroundBrightnessSlider = rootIds.optionsOverlay.backgroundBrightnessSlider
        ? document.getElementById(rootIds.optionsOverlay.backgroundBrightnessSlider)
        : null;
      const backgroundBrightnessValue = rootIds.optionsOverlay.backgroundBrightnessValue
        ? document.getElementById(rootIds.optionsOverlay.backgroundBrightnessValue)
        : null;
      const colorblindPaletteToggle = document.getElementById(
        rootIds.optionsOverlay.colorblindPaletteToggle
      );
      const colorblindPaletteSelect = rootIds.optionsOverlay.colorblindPaletteSelect
        ? document.getElementById(rootIds.optionsOverlay.colorblindPaletteSelect)
        : null;
      const castleSkinSelect = rootIds.optionsOverlay.castleSkinSelect
        ? document.getElementById(rootIds.optionsOverlay.castleSkinSelect)
        : null;
      const hotkeyPauseSelect = rootIds.optionsOverlay.hotkeyPauseSelect
        ? document.getElementById(rootIds.optionsOverlay.hotkeyPauseSelect)
        : null;
      const hotkeyShortcutsSelect = rootIds.optionsOverlay.hotkeyShortcutsSelect
        ? document.getElementById(rootIds.optionsOverlay.hotkeyShortcutsSelect)
        : null;
      const hudZoomSelect = document.getElementById(rootIds.optionsOverlay.hudZoomSelect);
      const hudLayoutToggle = rootIds.optionsOverlay.hudLayoutToggle
        ? document.getElementById(rootIds.optionsOverlay.hudLayoutToggle)
        : null;
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
        (screenShakeToggle === null || screenShakeToggle instanceof HTMLInputElement) &&
        (screenShakeSlider === null || screenShakeSlider instanceof HTMLInputElement) &&
        (screenShakeValue === null || screenShakeValue instanceof HTMLElement) &&
        (screenShakePreview === null || screenShakePreview instanceof HTMLButtonElement) &&
        (screenShakeDemo === null || screenShakeDemo instanceof HTMLElement) &&
        (contrastAuditButton === null || contrastAuditButton instanceof HTMLButtonElement) &&
        (stickerBookButton === null || stickerBookButton instanceof HTMLButtonElement) &&
        (seasonTrackButton === null || seasonTrackButton instanceof HTMLButtonElement) &&
        (museumButton === null || museumButton instanceof HTMLButtonElement) &&
        (loreScrollsButton === null || loreScrollsButton instanceof HTMLButtonElement) &&
        (parentSummaryButton === null || parentSummaryButton instanceof HTMLButtonElement) &&
        (selfTestContainer === null || selfTestContainer instanceof HTMLElement) &&
        (selfTestRun === null || selfTestRun instanceof HTMLButtonElement) &&
        (selfTestStatus === null || selfTestStatus instanceof HTMLElement) &&
        (selfTestSoundToggle === null || selfTestSoundToggle instanceof HTMLInputElement) &&
        (selfTestVisualToggle === null || selfTestVisualToggle instanceof HTMLInputElement) &&
        (selfTestMotionToggle === null || selfTestMotionToggle instanceof HTMLInputElement) &&
        (selfTestSoundIndicator === null || selfTestSoundIndicator instanceof HTMLElement) &&
        (selfTestVisualIndicator === null || selfTestVisualIndicator instanceof HTMLElement) &&
        (selfTestMotionIndicator === null || selfTestMotionIndicator instanceof HTMLElement) &&
        diagnosticsToggle instanceof HTMLInputElement &&
        reducedMotionToggle instanceof HTMLInputElement &&
        checkeredBackgroundToggle instanceof HTMLInputElement &&
        readableFontToggle instanceof HTMLInputElement &&
        dyslexiaFontToggle instanceof HTMLInputElement &&
        (dyslexiaSpacingToggle === null || dyslexiaSpacingToggle instanceof HTMLInputElement) &&
        (cognitiveLoadToggle === null || cognitiveLoadToggle instanceof HTMLInputElement) &&
        (backgroundBrightnessSlider === null ||
          backgroundBrightnessSlider instanceof HTMLInputElement) &&
        (backgroundBrightnessValue === null || backgroundBrightnessValue instanceof HTMLElement) &&
        colorblindPaletteToggle instanceof HTMLInputElement &&
        (colorblindPaletteSelect === null || colorblindPaletteSelect instanceof HTMLSelectElement) &&
        (castleSkinSelect === null || castleSkinSelect instanceof HTMLSelectElement) &&
        (hotkeyPauseSelect === null || hotkeyPauseSelect instanceof HTMLSelectElement) &&
        (hotkeyShortcutsSelect === null || hotkeyShortcutsSelect instanceof HTMLSelectElement) &&
        hudZoomSelect instanceof HTMLSelectElement &&
        (hudLayoutToggle === null || hudLayoutToggle instanceof HTMLInputElement) &&
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
          screenShakeToggle:
            screenShakeToggle instanceof HTMLInputElement ? screenShakeToggle : undefined,
          screenShakeSlider:
            screenShakeSlider instanceof HTMLInputElement ? screenShakeSlider : undefined,
          screenShakeValue: screenShakeValue instanceof HTMLElement ? screenShakeValue : undefined,
          screenShakePreview:
            screenShakePreview instanceof HTMLButtonElement ? screenShakePreview : undefined,
        screenShakeDemo: screenShakeDemo instanceof HTMLElement ? screenShakeDemo : undefined,
        contrastAuditButton:
          contrastAuditButton instanceof HTMLButtonElement ? contrastAuditButton : undefined,
        stickerBookButton:
          stickerBookButton instanceof HTMLButtonElement ? stickerBookButton : undefined,
        seasonTrackButton:
          seasonTrackButton instanceof HTMLButtonElement ? seasonTrackButton : undefined,
        museumButton: museumButton instanceof HTMLButtonElement ? museumButton : undefined,
        sideQuestButton: sideQuestButton instanceof HTMLButtonElement ? sideQuestButton : undefined,
        masteryCertificateButton:
          masteryCertificateButton instanceof HTMLButtonElement ? masteryCertificateButton : undefined,
        lessonMedalButton:
          lessonMedalButton instanceof HTMLButtonElement ? lessonMedalButton : undefined,
        loreScrollsButton:
          loreScrollsButton instanceof HTMLButtonElement ? loreScrollsButton : undefined,
        selfTestContainer:
          selfTestContainer instanceof HTMLElement ? selfTestContainer : undefined,
        selfTestRun: selfTestRun instanceof HTMLButtonElement ? selfTestRun : undefined,
          selfTestStatus: selfTestStatus instanceof HTMLElement ? selfTestStatus : undefined,
          selfTestSoundToggle:
            selfTestSoundToggle instanceof HTMLInputElement ? selfTestSoundToggle : undefined,
          selfTestVisualToggle:
            selfTestVisualToggle instanceof HTMLInputElement ? selfTestVisualToggle : undefined,
          selfTestMotionToggle:
            selfTestMotionToggle instanceof HTMLInputElement ? selfTestMotionToggle : undefined,
          selfTestSoundIndicator:
            selfTestSoundIndicator instanceof HTMLElement ? selfTestSoundIndicator : undefined,
          selfTestVisualIndicator:
            selfTestVisualIndicator instanceof HTMLElement ? selfTestVisualIndicator : undefined,
          selfTestMotionIndicator:
            selfTestMotionIndicator instanceof HTMLElement ? selfTestMotionIndicator : undefined,
          diagnosticsToggle,
          virtualKeyboardToggle:
            virtualKeyboardToggle instanceof HTMLInputElement ? virtualKeyboardToggle : undefined,
          lowGraphicsToggle:
            lowGraphicsToggle instanceof HTMLInputElement ? lowGraphicsToggle : undefined,
          textSizeSelect:
            textSizeSelect instanceof HTMLSelectElement ? textSizeSelect : undefined,
          hapticsToggle: hapticsToggle instanceof HTMLInputElement ? hapticsToggle : undefined,
          reducedMotionToggle,
          checkeredBackgroundToggle,
          readableFontToggle,
          dyslexiaFontToggle,
          dyslexiaSpacingToggle:
            dyslexiaSpacingToggle instanceof HTMLInputElement ? dyslexiaSpacingToggle : undefined,
          cognitiveLoadToggle:
            cognitiveLoadToggle instanceof HTMLInputElement ? cognitiveLoadToggle : undefined,
          backgroundBrightnessSlider:
            backgroundBrightnessSlider instanceof HTMLInputElement
              ? backgroundBrightnessSlider
              : undefined,
          backgroundBrightnessValue:
            backgroundBrightnessValue instanceof HTMLElement ? backgroundBrightnessValue : undefined,
          colorblindPaletteToggle,
          colorblindPaletteSelect:
            colorblindPaletteSelect instanceof HTMLSelectElement ? colorblindPaletteSelect : undefined,
          castleSkinSelect: castleSkinSelect instanceof HTMLSelectElement ? castleSkinSelect : undefined,
          hotkeyPauseSelect:
            hotkeyPauseSelect instanceof HTMLSelectElement ? hotkeyPauseSelect : undefined,
          hotkeyShortcutsSelect:
            hotkeyShortcutsSelect instanceof HTMLSelectElement ? hotkeyShortcutsSelect : undefined,
          hudZoomSelect,
          hudLayoutToggle: hudLayoutToggle instanceof HTMLInputElement ? hudLayoutToggle : undefined,
          fontScaleSelect,
          defeatAnimationSelect,
          telemetryToggle: telemetryToggle instanceof HTMLInputElement ? telemetryToggle : undefined,
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
          parentSummaryButton:
            parentSummaryButton instanceof HTMLButtonElement ? parentSummaryButton : undefined,
          analyticsExportButton:
            analyticsExportButton instanceof HTMLButtonElement ? analyticsExportButton : undefined
        };
        this.addFocusTrap(optionsContainer);
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
        if (this.optionsOverlay.screenShakeToggle) {
          this.optionsOverlay.screenShakeToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onScreenShakeToggle?.(
              this.optionsOverlay!.screenShakeToggle!.checked
            );
          });
        }
        if (this.optionsOverlay.screenShakeSlider) {
          this.optionsOverlay.screenShakeSlider.addEventListener("input", () => {
            if (this.syncingOptionToggles) return;
            const rawValue = Number.parseFloat(this.optionsOverlay!.screenShakeSlider!.value);
            if (!Number.isFinite(rawValue)) return;
            this.updateScreenShakeIntensityDisplay(rawValue);
            this.callbacks.onScreenShakeIntensityChange?.(rawValue);
          });
        }
        if (this.optionsOverlay.screenShakePreview) {
          this.optionsOverlay.screenShakePreview.addEventListener("click", () => {
            if (this.optionsOverlay?.screenShakePreview?.dataset.disabled === "true") return;
            this.playScreenShakePreview();
            this.callbacks.onScreenShakePreview?.();
          });
        }
        if (this.optionsOverlay.contrastAuditButton) {
          this.optionsOverlay.contrastAuditButton.addEventListener("click", () => {
            this.callbacks.onContrastAuditRequested?.();
          });
        }
        if (this.optionsOverlay.stickerBookButton) {
          this.optionsOverlay.stickerBookButton.addEventListener("click", () => {
            this.showStickerBookOverlay();
          });
        }
        if (this.optionsOverlay.seasonTrackButton) {
          this.optionsOverlay.seasonTrackButton.addEventListener("click", () => {
            this.showSeasonTrackOverlay();
          });
        }
        if (this.optionsOverlay.museumButton) {
          this.optionsOverlay.museumButton.addEventListener("click", () => {
            this.showMuseumOverlay();
          });
        }
        if (this.optionsOverlay.sideQuestButton) {
          this.optionsOverlay.sideQuestButton.addEventListener("click", () => {
            this.showSideQuestOverlay();
          });
        }
        if (this.optionsOverlay.masteryCertificateButton) {
          this.optionsOverlay.masteryCertificateButton.addEventListener("click", () => {
            this.showMasteryCertificateOverlay();
          });
        }
        if (this.optionsOverlay.lessonMedalButton) {
          this.optionsOverlay.lessonMedalButton.addEventListener("click", () => {
            this.showLessonMedalOverlay();
          });
        }
        if (this.optionsOverlay.loreScrollsButton) {
          this.optionsOverlay.loreScrollsButton.addEventListener("click", () => {
            this.showLoreScrollOverlay();
          });
        }
        if (this.optionsOverlay.parentSummaryButton) {
          this.optionsOverlay.parentSummaryButton.addEventListener("click", () => {
            this.showParentSummary();
          });
        }
        if (this.optionsOverlay.selfTestRun) {
          this.optionsOverlay.selfTestRun.addEventListener("click", () => {
            this.playAccessibilitySelfTestCues({
              includeMotion: this.optionsOverlay?.selfTestMotionToggle?.disabled !== true,
              soundEnabled: this.optionsOverlay?.selfTestSoundToggle?.disabled !== true
            });
            this.callbacks.onAccessibilitySelfTestRun?.();
          });
        }
        if (this.optionsOverlay.selfTestSoundToggle) {
          this.optionsOverlay.selfTestSoundToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onAccessibilitySelfTestConfirm?.(
              "sound",
              this.optionsOverlay!.selfTestSoundToggle!.checked
            );
          });
        }
        if (this.optionsOverlay.selfTestVisualToggle) {
          this.optionsOverlay.selfTestVisualToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onAccessibilitySelfTestConfirm?.(
              "visual",
              this.optionsOverlay!.selfTestVisualToggle!.checked
            );
          });
        }
        if (this.optionsOverlay.selfTestMotionToggle) {
          this.optionsOverlay.selfTestMotionToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onAccessibilitySelfTestConfirm?.(
              "motion",
              this.optionsOverlay!.selfTestMotionToggle!.checked
            );
          });
        }
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
        if (this.optionsOverlay.textSizeSelect) {
          this.optionsOverlay.textSizeSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const rawValue = this.getSelectValue(this.optionsOverlay!.textSizeSelect);
            const parsed = Number.parseFloat(rawValue ?? "1");
            if (Number.isFinite(parsed)) {
              this.callbacks.onTextSizeChange?.(parsed);
            }
          });
        }
        if (this.optionsOverlay.hapticsToggle) {
          this.optionsOverlay.hapticsToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onHapticsToggle?.(this.optionsOverlay!.hapticsToggle!.checked);
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
        if (this.optionsOverlay.backgroundBrightnessSlider) {
          this.optionsOverlay.backgroundBrightnessSlider.addEventListener("input", () => {
            if (this.syncingOptionToggles) return;
            const rawValue = Number.parseFloat(this.optionsOverlay!.backgroundBrightnessSlider!.value);
            if (!Number.isFinite(rawValue)) return;
            this.updateBackgroundBrightnessDisplay(rawValue);
            this.callbacks.onBackgroundBrightnessChange?.(rawValue);
          });
        }
        if (this.optionsOverlay.dyslexiaSpacingToggle) {
          this.optionsOverlay.dyslexiaSpacingToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onDyslexiaSpacingToggle?.(
              this.optionsOverlay!.dyslexiaSpacingToggle!.checked
            );
          });
        }
        if (this.optionsOverlay.cognitiveLoadToggle) {
          this.optionsOverlay.cognitiveLoadToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onCognitiveLoadToggle?.(
              this.optionsOverlay!.cognitiveLoadToggle!.checked
            );
          });
        }
        colorblindPaletteToggle.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          this.callbacks.onColorblindPaletteToggle(colorblindPaletteToggle.checked);
        });
        if (this.optionsOverlay.colorblindPaletteSelect) {
          this.optionsOverlay.colorblindPaletteSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const next = this.getSelectValue(this.optionsOverlay!.colorblindPaletteSelect!);
            if (next) {
              this.callbacks.onColorblindPaletteModeChange?.(next);
            }
          });
        }
        if (this.optionsOverlay.castleSkinSelect) {
          this.optionsOverlay.castleSkinSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const next = (this.getSelectValue(this.optionsOverlay!.castleSkinSelect!) ??
              "classic") as CastleSkinId;
            this.setCastleSkin(next);
            this.callbacks.onCastleSkinChange?.(next);
          });
        }
        if (this.optionsOverlay.hotkeyPauseSelect) {
          this.optionsOverlay.hotkeyPauseSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const next = this.getSelectValue(this.optionsOverlay!.hotkeyPauseSelect!);
            if (next) {
              this.callbacks.onHotkeyPauseChange?.(next);
            }
          });
        }
        if (this.optionsOverlay.hotkeyShortcutsSelect) {
          this.optionsOverlay.hotkeyShortcutsSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const next = this.getSelectValue(this.optionsOverlay!.hotkeyShortcutsSelect!);
            if (next) {
              this.callbacks.onHotkeyShortcutsChange?.(next);
            }
          });
        }
        this.optionsOverlay.defeatAnimationSelect.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          const nextMode = this.optionsOverlay!.defeatAnimationSelect!.value as DefeatAnimationPreference;
          this.callbacks.onDefeatAnimationModeChange(nextMode);
        });
        this.optionsOverlay.hudZoomSelect.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          const rawValue = this.getSelectValue(this.optionsOverlay!.hudZoomSelect);
          const nextValue = Number.parseFloat(rawValue ?? "");
          if (!Number.isFinite(nextValue)) return;
          this.callbacks.onHudZoomChange(nextValue);
        });
        if (this.optionsOverlay.hudLayoutToggle) {
          this.optionsOverlay.hudLayoutToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onHudLayoutToggle?.(this.optionsOverlay!.hudLayoutToggle!.checked);
          });
        }
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
        const parentalButton = document.getElementById("options-parental-info");
        if (parentalButton instanceof HTMLButtonElement) {
          parentalButton.addEventListener("click", () => this.showParentalOverlay(parentalButton));
        }
      } else {
        console.warn("Options overlay elements missing; pause overlay disabled.");
      }
    }

    if (rootIds.waveScorecard) {
      const scorecardContainer = document.getElementById(rootIds.waveScorecard.container);
      const scorecardStats = document.getElementById(rootIds.waveScorecard.stats);
      const scorecardContinue = document.getElementById(rootIds.waveScorecard.continue);
      const scorecardTip = rootIds.waveScorecard.tip
        ? document.getElementById(rootIds.waveScorecard.tip)
        : null;
      if (
        scorecardContainer instanceof HTMLElement &&
        isElementWithTag<HTMLUListElement>(scorecardStats, "ul") &&
        scorecardContinue instanceof HTMLButtonElement
      ) {
        this.waveScorecard = {
          container: scorecardContainer,
          statsList: scorecardStats,
          continueBtn: scorecardContinue,
          tip: scorecardTip instanceof HTMLElement ? scorecardTip : undefined
        };
        this.addFocusTrap(scorecardContainer);
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
        this.addFocusTrap(overlayContainer);
      } else {
        console.warn("Roadmap overlay elements missing; roadmap overlay disabled.");
      }
    }

    if (rootIds.parentalOverlay) {
      const parentalContainer = document.getElementById(rootIds.parentalOverlay.container);
      const parentalClose = document.getElementById(rootIds.parentalOverlay.closeButton);
      if (parentalContainer instanceof HTMLElement && parentalClose instanceof HTMLButtonElement) {
        this.parentalOverlay = {
          container: parentalContainer,
          closeButton: parentalClose
        };
        this.parentalOverlay.container.dataset.visible =
          this.parentalOverlay.container.dataset.visible ?? "false";
        this.parentalOverlay.container.setAttribute("aria-hidden", "true");
        this.addFocusTrap(parentalContainer);
        parentalClose.addEventListener("click", () => this.hideParentalOverlay());
      } else {
        console.warn("Parental info overlay missing; parental info dialog disabled.");
      }
    }
    if (rootIds.contrastOverlay) {
      const overlayContainer = document.getElementById(rootIds.contrastOverlay.container);
      const overlayList = document.getElementById(rootIds.contrastOverlay.list);
      const overlaySummary = document.getElementById(rootIds.contrastOverlay.summary);
      const overlayClose = document.getElementById(rootIds.contrastOverlay.closeButton);
      const overlayMarkers = document.getElementById(rootIds.contrastOverlay.markers);
      if (
        overlayContainer instanceof HTMLElement &&
        isElementWithTag<HTMLUListElement>(overlayList, "ul") &&
        overlaySummary instanceof HTMLElement &&
        overlayClose instanceof HTMLButtonElement &&
        overlayMarkers instanceof HTMLElement
      ) {
        this.contrastOverlay = {
          container: overlayContainer,
          list: overlayList,
          summary: overlaySummary,
          closeButton: overlayClose,
          markers: overlayMarkers
        };
        overlayContainer.dataset.visible = overlayContainer.dataset.visible ?? "false";
        overlayContainer.setAttribute("aria-hidden", "true");
        overlayClose.addEventListener("click", () => this.hideContrastOverlay());
      } else {
        console.warn("Contrast overlay elements missing; contrast audit disabled.");
      }
    }
    if (rootIds.stickerBookOverlay) {
      const stickerContainer = document.getElementById(rootIds.stickerBookOverlay.container);
      const stickerList = document.getElementById(rootIds.stickerBookOverlay.list);
      const stickerSummary = document.getElementById(rootIds.stickerBookOverlay.summary);
      const stickerClose = document.getElementById(rootIds.stickerBookOverlay.closeButton);
      if (
        stickerContainer instanceof HTMLElement &&
        stickerList instanceof HTMLElement &&
        stickerSummary instanceof HTMLElement &&
        stickerClose instanceof HTMLButtonElement
      ) {
        this.stickerBookOverlay = {
          container: stickerContainer,
          list: stickerList,
          summary: stickerSummary,
          closeButton: stickerClose
        };
        stickerContainer.dataset.visible = stickerContainer.dataset.visible ?? "false";
        stickerContainer.setAttribute("aria-hidden", "true");
        stickerClose.addEventListener("click", () => this.hideStickerBookOverlay());
        this.addFocusTrap(stickerContainer);
      } else {
        console.warn("Sticker book elements missing; sticker overlay disabled.");
      }
    }
    if (rootIds.loreScrollOverlay) {
      const scrollContainer = document.getElementById(rootIds.loreScrollOverlay.container);
      const scrollList = document.getElementById(rootIds.loreScrollOverlay.list);
      const scrollSummary = document.getElementById(rootIds.loreScrollOverlay.summary);
      const scrollProgress = rootIds.loreScrollOverlay.progress
        ? document.getElementById(rootIds.loreScrollOverlay.progress)
        : null;
      const scrollClose = document.getElementById(rootIds.loreScrollOverlay.closeButton);
      if (
        scrollContainer instanceof HTMLElement &&
        scrollList instanceof HTMLElement &&
        scrollSummary instanceof HTMLElement &&
        scrollClose instanceof HTMLButtonElement
      ) {
        this.loreScrollOverlay = {
          container: scrollContainer,
          list: scrollList,
          summary: scrollSummary,
          progress: scrollProgress instanceof HTMLElement ? scrollProgress : undefined,
          closeButton: scrollClose
        };
        scrollContainer.dataset.visible = scrollContainer.dataset.visible ?? "false";
        scrollContainer.setAttribute("aria-hidden", "true");
        scrollClose.addEventListener("click", () => this.hideLoreScrollOverlay());
        this.addFocusTrap(scrollContainer);
      } else {
        console.warn("Lore scroll overlay elements missing; scroll overlay disabled.");
      }
    }

    if (rootIds.seasonTrackOverlay) {
      const seasonContainer = document.getElementById(rootIds.seasonTrackOverlay.container);
      const seasonList = document.getElementById(rootIds.seasonTrackOverlay.list);
      const seasonProgress = document.getElementById(rootIds.seasonTrackOverlay.progress);
      const seasonLessons = rootIds.seasonTrackOverlay.lessons
        ? document.getElementById(rootIds.seasonTrackOverlay.lessons)
        : null;
      const seasonNext = rootIds.seasonTrackOverlay.next
        ? document.getElementById(rootIds.seasonTrackOverlay.next)
        : null;
      const seasonClose = document.getElementById(rootIds.seasonTrackOverlay.closeButton);
      if (
        seasonContainer instanceof HTMLElement &&
        seasonList instanceof HTMLElement &&
        seasonProgress instanceof HTMLElement &&
        seasonClose instanceof HTMLButtonElement
      ) {
        this.seasonTrackOverlay = {
          container: seasonContainer,
          list: seasonList,
          progress: seasonProgress,
          lessons: seasonLessons instanceof HTMLElement ? seasonLessons : undefined,
          next: seasonNext instanceof HTMLElement ? seasonNext : undefined,
          closeButton: seasonClose
        };
        seasonContainer.dataset.visible = seasonContainer.dataset.visible ?? "false";
        seasonContainer.setAttribute("aria-hidden", "true");
        seasonClose.addEventListener("click", () => this.hideSeasonTrackOverlay());
        this.addFocusTrap(seasonContainer);
      } else {
        console.warn("Season track overlay elements missing; reward track disabled.");
      }
    }

  if (rootIds.lessonMedalOverlay) {
      const medalContainer = document.getElementById(rootIds.lessonMedalOverlay.container);
      const medalBadge = rootIds.lessonMedalOverlay.badge
        ? document.getElementById(rootIds.lessonMedalOverlay.badge)
        : null;
      const medalLast = rootIds.lessonMedalOverlay.last
        ? document.getElementById(rootIds.lessonMedalOverlay.last)
        : null;
      const medalNext = rootIds.lessonMedalOverlay.next
        ? document.getElementById(rootIds.lessonMedalOverlay.next)
        : null;
      const medalBestList = rootIds.lessonMedalOverlay.bestList
        ? document.getElementById(rootIds.lessonMedalOverlay.bestList)
        : null;
      const medalHistory = rootIds.lessonMedalOverlay.historyList
        ? document.getElementById(rootIds.lessonMedalOverlay.historyList)
        : null;
      const medalReplay = rootIds.lessonMedalOverlay.replayButton
        ? document.getElementById(rootIds.lessonMedalOverlay.replayButton)
        : null;
      const medalClose = document.getElementById(rootIds.lessonMedalOverlay.closeButton);
      if (
        medalContainer instanceof HTMLElement &&
        medalClose instanceof HTMLButtonElement &&
        medalHistory instanceof HTMLElement
      ) {
        this.lessonMedalOverlay = {
          container: medalContainer,
          closeButton: medalClose,
          badge: medalBadge instanceof HTMLElement ? medalBadge : undefined,
          last: medalLast instanceof HTMLElement ? medalLast : undefined,
          next: medalNext instanceof HTMLElement ? medalNext : undefined,
          bestList: medalBestList instanceof HTMLElement ? medalBestList : undefined,
          historyList: medalHistory,
          replayButton: medalReplay instanceof HTMLButtonElement ? medalReplay : undefined
        };
        if (this.lessonMedalOverlay.replayButton) {
          this.lessonMedalOverlay.replayButton.addEventListener("click", () => {
            const mode = this.lessonMedalState?.last?.mode ?? "burst";
            const hint = this.lessonMedalState?.nextTarget?.hint;
            this.callbacks.onLessonMedalReplay?.({ mode, hint });
          });
        }
        medalContainer.dataset.visible = medalContainer.dataset.visible ?? "false";
        medalContainer.setAttribute("aria-hidden", "true");
        medalClose.addEventListener("click", () => this.hideLessonMedalOverlay());
        this.addFocusTrap(medalContainer);
      } else {
        console.warn("Lesson medal overlay elements missing; medal overlay disabled.");
      }
    }

    if (rootIds.museumOverlay) {
      const museumContainer = document.getElementById(rootIds.museumOverlay.container);
      const museumClose = document.getElementById(rootIds.museumOverlay.closeButton);
      const museumList = document.getElementById(rootIds.museumOverlay.list);
      const museumSubtitle = rootIds.museumOverlay.subtitle
        ? document.getElementById(rootIds.museumOverlay.subtitle)
        : null;
      if (
        museumContainer instanceof HTMLElement &&
        museumClose instanceof HTMLButtonElement &&
        museumList instanceof HTMLElement
      ) {
        this.museumOverlay = {
          container: museumContainer,
          closeButton: museumClose,
          list: museumList,
          subtitle: museumSubtitle instanceof HTMLElement ? museumSubtitle : undefined
        };
        museumContainer.dataset.visible = museumContainer.dataset.visible ?? "false";
        museumContainer.setAttribute("aria-hidden", "true");
        museumClose.addEventListener("click", () => this.hideMuseumOverlay());
        this.addFocusTrap(museumContainer);
      } else {
        console.warn("Museum overlay elements missing; museum overlay disabled.");
      }
    }

    if (rootIds.sideQuestOverlay) {
      const questContainer = document.getElementById(rootIds.sideQuestOverlay.container);
      const questClose = document.getElementById(rootIds.sideQuestOverlay.closeButton);
      const questList = document.getElementById(rootIds.sideQuestOverlay.list);
      const questSubtitle = rootIds.sideQuestOverlay.subtitle
        ? document.getElementById(rootIds.sideQuestOverlay.subtitle)
        : null;
      if (
        questContainer instanceof HTMLElement &&
        questClose instanceof HTMLButtonElement &&
        questList instanceof HTMLElement
      ) {
        this.sideQuestOverlay = {
          container: questContainer,
          closeButton: questClose,
          list: questList,
          subtitle: questSubtitle instanceof HTMLElement ? questSubtitle : undefined
        };
        questContainer.dataset.visible = questContainer.dataset.visible ?? "false";
        questContainer.setAttribute("aria-hidden", "true");
        questClose.addEventListener("click", () => this.hideSideQuestOverlay());
        this.addFocusTrap(questContainer);
      } else {
        console.warn("Side quest overlay elements missing; quest overlay disabled.");
      }
    }

    if (rootIds.masteryCertificateOverlay) {
      const certContainer = document.getElementById(rootIds.masteryCertificateOverlay.container);
      const certClose = document.getElementById(rootIds.masteryCertificateOverlay.closeButton);
      const certDownload = rootIds.masteryCertificateOverlay.downloadButton
        ? document.getElementById(rootIds.masteryCertificateOverlay.downloadButton)
        : null;
      const certNameInput = rootIds.masteryCertificateOverlay.nameInput
        ? document.getElementById(rootIds.masteryCertificateOverlay.nameInput)
        : null;
      const certSummary = rootIds.masteryCertificateOverlay.summary
        ? document.getElementById(rootIds.masteryCertificateOverlay.summary)
        : null;
      const certStats = rootIds.masteryCertificateOverlay.statsList
        ? document.getElementById(rootIds.masteryCertificateOverlay.statsList)
        : null;
      const certDate = rootIds.masteryCertificateOverlay.date
        ? document.getElementById(rootIds.masteryCertificateOverlay.date)
        : null;
      if (certContainer instanceof HTMLElement && certClose instanceof HTMLButtonElement) {
        this.masteryCertificate = {
          container: certContainer,
          closeButton: certClose,
          downloadButton: certDownload instanceof HTMLButtonElement ? certDownload : undefined,
          nameInput: certNameInput instanceof HTMLInputElement ? certNameInput : undefined,
          summary: certSummary instanceof HTMLElement ? certSummary : undefined,
          statsList: certStats instanceof HTMLElement ? certStats : undefined,
          date: certDate instanceof HTMLElement ? certDate : undefined
        };
        certContainer.dataset.visible = certContainer.dataset.visible ?? "false";
        certContainer.setAttribute("aria-hidden", "true");
        certClose.addEventListener("click", () => this.hideMasteryCertificateOverlay());
        if (this.masteryCertificate.downloadButton) {
          this.masteryCertificate.downloadButton.addEventListener("click", () =>
            this.downloadMasteryCertificate()
          );
        }
        if (this.masteryCertificate.nameInput) {
          this.masteryCertificate.nameInput.value = this.certificateName;
          this.masteryCertificate.nameInput.addEventListener("input", (event) => {
            const target = event.target as HTMLInputElement;
            this.setCertificateName(target.value ?? "");
          });
        }
        this.addFocusTrap(certContainer);
      } else {
        console.warn("Mastery certificate overlay elements missing; certificate overlay disabled.");
      }
    }

    const loreScrollPanel = document.getElementById("lore-scroll-panel");
    const loreScrollSummary = document.getElementById("lore-scrolls-summary");
    const loreScrollProgress = document.getElementById("lore-scrolls-progress");
    const loreScrollLessons = document.getElementById("lore-scrolls-lessons");
    const loreScrollNext = document.getElementById("lore-scrolls-next");
    const loreScrollOpen = document.getElementById("lore-scrolls-open");
    this.loreScrollPanel = {
      container: loreScrollPanel instanceof HTMLElement ? loreScrollPanel : undefined,
      summary: loreScrollSummary instanceof HTMLElement ? loreScrollSummary : undefined,
      progress: loreScrollProgress instanceof HTMLElement ? loreScrollProgress : undefined,
      lessons: loreScrollLessons instanceof HTMLElement ? loreScrollLessons : undefined,
      next: loreScrollNext instanceof HTMLElement ? loreScrollNext : undefined,
      openButton: loreScrollOpen instanceof HTMLButtonElement ? loreScrollOpen : undefined
    };
    if (this.loreScrollPanel.openButton) {
      this.loreScrollPanel.openButton.addEventListener("click", () => this.showLoreScrollOverlay());
    }

    const museumPanel = document.getElementById("castle-museum-panel");
    const museumSummary = document.getElementById("castle-museum-summary");
    const museumStats = document.getElementById("castle-museum-stats");
    const museumOpen = document.getElementById("castle-museum-open");
    this.museumPanel = {
      container: museumPanel instanceof HTMLElement ? museumPanel : undefined,
      summary: museumSummary instanceof HTMLElement ? museumSummary : undefined,
      stats: museumStats instanceof HTMLElement ? museumStats : undefined,
      openButton: museumOpen instanceof HTMLButtonElement ? museumOpen : undefined
    };
    if (this.museumPanel.openButton) {
      this.museumPanel.openButton.addEventListener("click", () => this.showMuseumOverlay());
    }

    const sideQuestPanel = document.getElementById("side-quest-panel");
    const sideQuestSummary = document.getElementById("side-quest-summary");
    const sideQuestStats = document.getElementById("side-quest-stats");
    const sideQuestOpen = document.getElementById("side-quest-open");
    this.sideQuestPanel = {
      container: sideQuestPanel instanceof HTMLElement ? sideQuestPanel : undefined,
      summary: sideQuestSummary instanceof HTMLElement ? sideQuestSummary : undefined,
      stats: sideQuestStats instanceof HTMLElement ? sideQuestStats : undefined,
      openButton: sideQuestOpen instanceof HTMLButtonElement ? sideQuestOpen : undefined
    };
    if (this.sideQuestPanel.openButton) {
      this.sideQuestPanel.openButton.addEventListener("click", () => this.showSideQuestOverlay());
    }

    const seasonTrackPanel = document.getElementById("season-track-panel");
    const seasonTrackSummary = document.getElementById("season-track-summary");
    const seasonTrackProgress = document.getElementById("season-track-progress-pill");
    const seasonTrackLessons = document.getElementById("season-track-lessons");
    const seasonTrackNext = document.getElementById("season-track-next");
    const seasonTrackRequirement = document.getElementById("season-track-next-requirement");
    const seasonTrackOpen = document.getElementById("season-track-open");
    this.seasonTrackPanel = {
      container: seasonTrackPanel instanceof HTMLElement ? seasonTrackPanel : undefined,
      summary: seasonTrackSummary instanceof HTMLElement ? seasonTrackSummary : undefined,
      progress: seasonTrackProgress instanceof HTMLElement ? seasonTrackProgress : undefined,
      lessons: seasonTrackLessons instanceof HTMLElement ? seasonTrackLessons : undefined,
      next: seasonTrackNext instanceof HTMLElement ? seasonTrackNext : undefined,
      requirement: seasonTrackRequirement instanceof HTMLElement ? seasonTrackRequirement : undefined,
      openButton: seasonTrackOpen instanceof HTMLButtonElement ? seasonTrackOpen : undefined
    };
    if (this.seasonTrackPanel.openButton) {
      this.seasonTrackPanel.openButton.addEventListener("click", () => this.showSeasonTrackOverlay());
    }

    const lessonMedalPanel = document.getElementById("lesson-medal-panel");
    const lessonMedalBadge = document.getElementById("lesson-medal-badge");
    const lessonMedalSummary = document.getElementById("lesson-medal-summary");
    const lessonMedalBest = document.getElementById("lesson-medal-best");
    const lessonMedalNext = document.getElementById("lesson-medal-next");
    const lessonMedalOpen = document.getElementById("lesson-medal-open");
    this.lessonMedalPanel = {
      container: lessonMedalPanel instanceof HTMLElement ? lessonMedalPanel : undefined,
      badge: lessonMedalBadge instanceof HTMLElement ? lessonMedalBadge : undefined,
      summary: lessonMedalSummary instanceof HTMLElement ? lessonMedalSummary : undefined,
      best: lessonMedalBest instanceof HTMLElement ? lessonMedalBest : undefined,
      next: lessonMedalNext instanceof HTMLElement ? lessonMedalNext : undefined,
      openButton: lessonMedalOpen instanceof HTMLButtonElement ? lessonMedalOpen : undefined
    };
    if (this.lessonMedalPanel.openButton) {
      this.lessonMedalPanel.openButton.addEventListener("click", () => this.showLessonMedalOverlay());
    }

    const masteryCertificatePanel = document.getElementById("mastery-certificate-panel");
    const masteryCertificateSummary = document.getElementById("mastery-certificate-summary");
    const masteryCertificateStats = document.getElementById("mastery-certificate-stats");
    const masteryCertificateDate = document.getElementById("mastery-certificate-date");
    const masteryCertificateName = document.getElementById("mastery-certificate-name") as
      | HTMLInputElement
      | null;
    const masteryCertificateOpen = document.getElementById("mastery-certificate-open");
    this.masteryCertificatePanel = {
      container: masteryCertificatePanel instanceof HTMLElement ? masteryCertificatePanel : undefined,
      summary: masteryCertificateSummary instanceof HTMLElement ? masteryCertificateSummary : undefined,
      stats: masteryCertificateStats instanceof HTMLElement ? masteryCertificateStats : undefined,
      date: masteryCertificateDate instanceof HTMLElement ? masteryCertificateDate : undefined,
      nameInput: masteryCertificateName ?? undefined,
      openButton: masteryCertificateOpen instanceof HTMLButtonElement ? masteryCertificateOpen : undefined
    };
    if (this.masteryCertificatePanel.nameInput) {
      this.masteryCertificatePanel.nameInput.value = this.certificateName;
      this.masteryCertificatePanel.nameInput.addEventListener("input", (event) => {
        const nextValue = (event.target as HTMLInputElement)?.value ?? "";
        this.setCertificateName(nextValue);
      });
    }
    if (this.masteryCertificatePanel.openButton) {
      this.masteryCertificatePanel.openButton.addEventListener("click", () => this.showMasteryCertificateOverlay());
    }

    const mentorContainer = document.getElementById("mentor-dialogue");
    const mentorText = document.getElementById("mentor-dialogue-text");
    const mentorFocus = document.getElementById("mentor-dialogue-focus");
    if (mentorContainer instanceof HTMLElement) {
      this.mentorDialogue = {
        container: mentorContainer,
        text: mentorText instanceof HTMLElement ? mentorText : undefined,
        focus: mentorFocus instanceof HTMLElement ? mentorFocus : undefined
      };
      mentorContainer.dataset.focus = mentorContainer.dataset.focus ?? "neutral";
    }

    const milestoneContainer = document.getElementById("milestone-celebration");
    const milestoneTitle = document.getElementById("milestone-celebration-title");
    const milestoneDetail = document.getElementById("milestone-celebration-detail");
    const milestoneBadge = document.getElementById("milestone-celebration-badge");
    const milestoneEyebrow = document.getElementById("milestone-celebration-eyebrow");
    const milestoneClose = document.getElementById("milestone-celebration-close");
    if (milestoneContainer instanceof HTMLElement) {
      this.milestoneCelebration = {
        container: milestoneContainer,
        title: milestoneTitle instanceof HTMLElement ? milestoneTitle : undefined,
        detail: milestoneDetail instanceof HTMLElement ? milestoneDetail : undefined,
        badge: milestoneBadge instanceof HTMLElement ? milestoneBadge : undefined,
        eyebrow: milestoneEyebrow instanceof HTMLElement ? milestoneEyebrow : undefined,
        closeButton: milestoneClose instanceof HTMLButtonElement ? milestoneClose : undefined
      };
      milestoneContainer.dataset.visible = milestoneContainer.dataset.visible ?? "false";
      milestoneContainer.setAttribute("aria-hidden", "true");
      if (this.milestoneCelebration.closeButton) {
        this.milestoneCelebration.closeButton.addEventListener("click", () =>
          this.hideMilestoneCelebration()
        );
      }
    }

    if (rootIds.parentSummaryOverlay) {
      const summaryContainer = document.getElementById(rootIds.parentSummaryOverlay.container);
      const summaryClose = document.getElementById(rootIds.parentSummaryOverlay.closeButton);
      const summaryCloseSecondary = rootIds.parentSummaryOverlay.closeSecondary
        ? document.getElementById(rootIds.parentSummaryOverlay.closeSecondary)
        : null;
      const summaryTitle = rootIds.parentSummaryOverlay.title
        ? document.getElementById(rootIds.parentSummaryOverlay.title)
        : null;
      const summarySubtitle = rootIds.parentSummaryOverlay.subtitle
        ? document.getElementById(rootIds.parentSummaryOverlay.subtitle)
        : null;
      const summaryProgress = rootIds.parentSummaryOverlay.progress
        ? document.getElementById(rootIds.parentSummaryOverlay.progress)
        : null;
      const summaryNote = rootIds.parentSummaryOverlay.note
        ? document.getElementById(rootIds.parentSummaryOverlay.note)
        : null;
      const summaryTime = rootIds.parentSummaryOverlay.time
        ? document.getElementById(rootIds.parentSummaryOverlay.time)
        : null;
      const summaryAccuracy = rootIds.parentSummaryOverlay.accuracy
        ? document.getElementById(rootIds.parentSummaryOverlay.accuracy)
        : null;
      const summaryWpm = rootIds.parentSummaryOverlay.wpm
        ? document.getElementById(rootIds.parentSummaryOverlay.wpm)
        : null;
      const summaryCombo = rootIds.parentSummaryOverlay.combo
        ? document.getElementById(rootIds.parentSummaryOverlay.combo)
        : null;
      const summaryPerfect = rootIds.parentSummaryOverlay.perfect
        ? document.getElementById(rootIds.parentSummaryOverlay.perfect)
        : null;
      const summaryBreaches = rootIds.parentSummaryOverlay.breaches
        ? document.getElementById(rootIds.parentSummaryOverlay.breaches)
        : null;
      const summaryDrills = rootIds.parentSummaryOverlay.drills
        ? document.getElementById(rootIds.parentSummaryOverlay.drills)
        : null;
      const summaryRepairs = rootIds.parentSummaryOverlay.repairs
        ? document.getElementById(rootIds.parentSummaryOverlay.repairs)
        : null;
      const summaryDownload = rootIds.parentSummaryOverlay.download
        ? document.getElementById(rootIds.parentSummaryOverlay.download)
        : null;

      if (
        summaryContainer instanceof HTMLElement &&
        summaryClose instanceof HTMLButtonElement
      ) {
        this.parentSummaryOverlay = {
          container: summaryContainer,
          closeButton: summaryClose,
          closeSecondary:
            summaryCloseSecondary instanceof HTMLButtonElement ? summaryCloseSecondary : undefined,
          title: summaryTitle instanceof HTMLElement ? summaryTitle : undefined,
          subtitle: summarySubtitle instanceof HTMLElement ? summarySubtitle : undefined,
          progress: summaryProgress instanceof HTMLElement ? summaryProgress : undefined,
          note: summaryNote instanceof HTMLElement ? summaryNote : undefined,
          time: summaryTime instanceof HTMLElement ? summaryTime : undefined,
          accuracy: summaryAccuracy instanceof HTMLElement ? summaryAccuracy : undefined,
          wpm: summaryWpm instanceof HTMLElement ? summaryWpm : undefined,
          combo: summaryCombo instanceof HTMLElement ? summaryCombo : undefined,
          perfect: summaryPerfect instanceof HTMLElement ? summaryPerfect : undefined,
          breaches: summaryBreaches instanceof HTMLElement ? summaryBreaches : undefined,
          drills: summaryDrills instanceof HTMLElement ? summaryDrills : undefined,
          repairs: summaryRepairs instanceof HTMLElement ? summaryRepairs : undefined,
          download: summaryDownload instanceof HTMLButtonElement ? summaryDownload : undefined
        };
        summaryContainer.dataset.visible = summaryContainer.dataset.visible ?? "false";
        summaryContainer.setAttribute("aria-hidden", "true");
        summaryClose.addEventListener("click", () => this.hideParentSummary());
        summaryCloseSecondary?.addEventListener("click", () => this.hideParentSummary());
        summaryDownload?.addEventListener("click", () => this.downloadParentSummary());
        this.addFocusTrap(summaryContainer);
      } else {
        console.warn("Parent summary overlay elements missing; parent summary disabled.");
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

    this.applyCastleSkinDataset(this.castleSkin);
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

  setLockIndicators(options: { capsOn: boolean; numOn: boolean }): void {
    if (this.lockIndicatorCaps) {
      this.lockIndicatorCaps.dataset.active = options.capsOn ? "true" : "false";
      this.lockIndicatorCaps.setAttribute(
        "aria-label",
        `Caps Lock ${options.capsOn ? "on" : "off"}`
      );
    }
    if (this.lockIndicatorNum) {
      this.lockIndicatorNum.dataset.active = options.numOn ? "true" : "false";
      this.lockIndicatorNum.setAttribute(
        "aria-label",
        `Num Lock ${options.numOn ? "on" : "off"}`
      );
    }
  }

  private getFocusableElements(container: HTMLElement): HTMLElement[] {
    const candidates = Array.from(
      container.querySelectorAll<HTMLElement>(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      )
    );
    return candidates.filter((el) => {
      if (el.hasAttribute("disabled") || el.getAttribute("aria-hidden") === "true") {
        return false;
      }
      return el.tabIndex >= 0 && this.isElementVisible(el);
    });
  }

  private isElementVisible(element: HTMLElement): boolean {
    return !!(element.offsetParent || element.getClientRects().length);
  }

  private addFocusTrap(container: HTMLElement): void {
    if (this.focusTraps.has(container)) return;
    const handler = (event: KeyboardEvent) => {
      if (event.key !== "Tab") return;
      const focusable = this.getFocusableElements(container);
      if (!focusable.length) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      const active = (document.activeElement as HTMLElement | null) ?? null;
      const within = active ? container.contains(active) : false;
      if (!within) {
        event.preventDefault();
        (event.shiftKey ? last : first).focus();
        return;
      }
      if (!event.shiftKey && active === last) {
        event.preventDefault();
        first.focus();
      } else if (event.shiftKey && active === first) {
        event.preventDefault();
        last.focus();
      }
    };
    container.addEventListener("keydown", handler);
    this.focusTraps.set(container, handler);
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
    screenShakeEnabled: boolean;
    screenShakeIntensity: number;
    selfTest?: {
      lastRunAt: string | null;
      soundConfirmed: boolean;
      visualConfirmed: boolean;
      motionConfirmed: boolean;
    };
    diagnosticsVisible: boolean;
    lowGraphicsEnabled: boolean;
    virtualKeyboardEnabled?: boolean;
    hapticsEnabled?: boolean;
    textSizeScale?: number;
    reducedMotionEnabled: boolean;
    checkeredBackgroundEnabled: boolean;
    readableFontEnabled: boolean;
    dyslexiaFontEnabled: boolean;
    dyslexiaSpacingEnabled?: boolean;
    reducedCognitiveLoadEnabled?: boolean;
    backgroundBrightness?: number;
    colorblindPaletteEnabled: boolean;
    colorblindPaletteMode?: string;
    castleSkin?: CastleSkinId;
    hudZoom: number;
    hudLayout: "left" | "right";
    hudFontScale: number;
    defeatAnimationMode: DefeatAnimationPreference;
    hotkeys?: { pause?: string; shortcuts?: string };
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
    const shakeDisabled = state.reducedMotionEnabled;
    if (this.optionsOverlay.screenShakeToggle) {
      this.optionsOverlay.screenShakeToggle.checked =
        state.screenShakeEnabled && !state.reducedMotionEnabled;
      this.optionsOverlay.screenShakeToggle.disabled = shakeDisabled;
      this.optionsOverlay.screenShakeToggle.setAttribute(
        "aria-disabled",
        shakeDisabled ? "true" : "false"
      );
      this.optionsOverlay.screenShakeToggle.tabIndex = shakeDisabled ? -1 : 0;
    }
    if (this.optionsOverlay.screenShakeSlider) {
      this.optionsOverlay.screenShakeSlider.disabled = shakeDisabled;
      this.optionsOverlay.screenShakeSlider.setAttribute(
        "aria-disabled",
        shakeDisabled ? "true" : "false"
      );
      this.optionsOverlay.screenShakeSlider.tabIndex = shakeDisabled ? -1 : 0;
      this.optionsOverlay.screenShakeSlider.value = state.screenShakeIntensity.toString();
    }
    if (this.optionsOverlay.screenShakePreview) {
      this.optionsOverlay.screenShakePreview.disabled = shakeDisabled;
      this.optionsOverlay.screenShakePreview.setAttribute(
        "aria-disabled",
        shakeDisabled ? "true" : "false"
      );
      this.optionsOverlay.screenShakePreview.dataset.disabled = shakeDisabled ? "true" : "false";
    }
    if (this.optionsOverlay.screenShakeDemo) {
      this.optionsOverlay.screenShakeDemo.dataset.disabled = shakeDisabled ? "true" : "false";
    }
    this.updateScreenShakeIntensityDisplay(state.screenShakeIntensity);
    this.updateAccessibilitySelfTestDisplay(state.selfTest, {
      soundEnabled: state.soundEnabled,
      reducedMotionEnabled: state.reducedMotionEnabled
    });
    this.optionsOverlay.diagnosticsToggle.checked = state.diagnosticsVisible;
    if (this.optionsOverlay.virtualKeyboardToggle && state.virtualKeyboardEnabled !== undefined) {
      this.optionsOverlay.virtualKeyboardToggle.checked = state.virtualKeyboardEnabled;
    }
    if (this.optionsOverlay.lowGraphicsToggle) {
      this.optionsOverlay.lowGraphicsToggle.checked = state.lowGraphicsEnabled;
    }
    if (this.optionsOverlay.textSizeSelect && state.textSizeScale !== undefined) {
      this.setSelectValue(this.optionsOverlay.textSizeSelect, state.textSizeScale.toString());
    }
    if (this.optionsOverlay.hapticsToggle && state.hapticsEnabled !== undefined) {
      this.optionsOverlay.hapticsToggle.checked = state.hapticsEnabled;
    }
    this.optionsOverlay.reducedMotionToggle.checked = state.reducedMotionEnabled;
    this.optionsOverlay.checkeredBackgroundToggle.checked = state.checkeredBackgroundEnabled;
    this.optionsOverlay.readableFontToggle.checked = state.readableFontEnabled;
    this.optionsOverlay.dyslexiaFontToggle.checked = state.dyslexiaFontEnabled;
    if (this.optionsOverlay.dyslexiaSpacingToggle && state.dyslexiaSpacingEnabled !== undefined) {
      this.optionsOverlay.dyslexiaSpacingToggle.checked = state.dyslexiaSpacingEnabled;
    }
    if (
      this.optionsOverlay.cognitiveLoadToggle &&
      state.reducedCognitiveLoadEnabled !== undefined
    ) {
      this.optionsOverlay.cognitiveLoadToggle.checked = state.reducedCognitiveLoadEnabled;
    }
    if (
      this.optionsOverlay.backgroundBrightnessSlider &&
      typeof state.backgroundBrightness === "number"
    ) {
      this.optionsOverlay.backgroundBrightnessSlider.value = state.backgroundBrightness.toString();
      this.updateBackgroundBrightnessDisplay(state.backgroundBrightness);
    }
    this.optionsOverlay.colorblindPaletteToggle.checked = state.colorblindPaletteEnabled;
    if (this.optionsOverlay.colorblindPaletteSelect) {
      this.setSelectValue(
        this.optionsOverlay.colorblindPaletteSelect,
        state.colorblindPaletteMode ?? (state.colorblindPaletteEnabled ? "deuteran" : "off")
      );
    }
    const castleSkin = state.castleSkin ?? this.castleSkin ?? "classic";
    if (this.optionsOverlay.castleSkinSelect) {
      this.setSelectValue(this.optionsOverlay.castleSkinSelect, castleSkin);
    }
    this.setCastleSkin(castleSkin as CastleSkinId);
    if (this.optionsOverlay.hotkeyPauseSelect) {
      const pause = state.hotkeys?.pause ?? "p";
      this.setSelectValue(this.optionsOverlay.hotkeyPauseSelect, pause);
    }
    if (this.optionsOverlay.hotkeyShortcutsSelect) {
      const shortcuts = state.hotkeys?.shortcuts ?? "?";
      this.setSelectValue(this.optionsOverlay.hotkeyShortcutsSelect, shortcuts);
    }
    this.setSelectValue(this.optionsOverlay.hudZoomSelect, state.hudZoom.toString());
    if (this.optionsOverlay.hudLayoutToggle) {
      this.optionsOverlay.hudLayoutToggle.checked = state.hudLayout === "left";
    }
    this.setSelectValue(this.optionsOverlay.fontScaleSelect, state.hudFontScale.toString());
    this.setSelectValue(
      this.optionsOverlay.defeatAnimationSelect,
      state.defeatAnimationMode ?? "auto"
    );
    this.setHudLayoutSide(state.hudLayout ?? "right");
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
    options: {
      colorBlindFriendly?: boolean;
      tutorialCompleted?: boolean;
      loreUnlocked?: number;
      lessonsCompleted?: number;
    } = {}
  ): void {
    const now = typeof performance !== "undefined" ? performance.now() : Date.now();
    this.lastState = state;
    const wpm = this.computeWpm(state);
    if (typeof options.lessonsCompleted === "number") {
      this.lessonsCompletedCount = Math.max(0, Math.floor(options.lessonsCompleted));
    }
    this.updateCastleBonusHint(state);
    this.refreshParentSummary(state);
    this.refreshMasteryCertificate(state, options.lessonsCompleted ?? 0);
    this.maybeCelebrateLessonMilestone(options.lessonsCompleted ?? 0);
    this.updateMentorDialogue(state, wpm);
    this.renderMuseumPanel();
    this.renderSideQuestPanel();
    if (this.analyticsViewer) {
      const modeValue = state.mode === "practice" ? "practice" : "campaign";
      this.analyticsViewer.container.dataset.mode = modeValue;
      this.analyticsViewer.container.dataset.practice =
        state.mode === "practice" ? "true" : "false";
    }
    this.updateShieldTelemetry(upcoming);
    this.updateAffixTelemetry(upcoming);
    this.refreshRoadmap(state, options);
    this.updateCompanionMood(state);
    const hpRatio = Math.max(0, state.castle.health / state.castle.maxHealth);
    (this.healthBar as HTMLElement).style.width = `${hpRatio * 100}%`;
    const gold = Math.floor(state.resources.gold);
    this.goldLabel.textContent = gold.toString();
    this.handleGoldDelta(gold);
    this.typingInput.value = state.typing.buffer;
    if (this.typingAccuracyLabel) {
      const pct = Math.max(0, Math.min(100, Math.round((state.typing.accuracy ?? 0) * 100)));
      this.typingAccuracyLabel.textContent = `${pct}%`;
    }
    if (this.typingWpmLabel) {
      this.typingWpmLabel.textContent = wpm.toString();
    }

    const activeEnemy = state.typing.activeEnemyId
      ? state.enemies.find((enemy) => enemy.id === state.typing.activeEnemyId)
      : null;
    const hint = this.typingErrorHint;
    const hintFresh = Boolean(hint) && now - (hint?.timestamp ?? 0) < 2000;
    if (hintFresh && activeEnemy && activeEnemy.typed > 0) {
      this.typingErrorHint = null;
    }
    const hasTypingError =
      hintFresh && (!hint?.enemyId || hint?.enemyId === activeEnemy?.id);
    const expectedKey: string | null = hasTypingError ? hint?.expected ?? null : null;
    if (activeEnemy) {
      const typed = activeEnemy.word.slice(0, activeEnemy.typed);
      const remaining = activeEnemy.word.slice(activeEnemy.typed);
      const shielded = Boolean(activeEnemy.shield && activeEnemy.shield.current > 0);
      const errorHint =
        hasTypingError && expectedKey
          ? `<span class="word-error-hint" role="status" aria-live="polite"><span class="word-error-key">${expectedKey.toUpperCase()}</span><span>Needed this key</span></span>`
          : "";
      const segments = `<span class="word-text${hasTypingError ? " word-text-error" : ""}"><span class="typed">${typed}</span><span>${remaining}</span></span>${errorHint}`;
      if (shielded) {
        this.activeWord.innerHTML = `<span class="word-status shielded" role="status" aria-live="polite">🛡 Shielded</span>${segments}`;
        this.activeWord.dataset.shielded = "true";
      } else {
        this.activeWord.innerHTML = segments;
        delete this.activeWord.dataset.shielded;
      }
      if (hasTypingError) {
        this.activeWord.dataset.error = "true";
      } else {
        delete this.activeWord.dataset.error;
      }
    } else {
      if (hintFresh && hint?.expected) {
        this.activeWord.innerHTML = `<span class="word-error-hint solo" role="status" aria-live="polite"><span class="word-error-key">${hint.expected.toUpperCase()}</span><span>Needed this key</span></span>`;
        this.activeWord.dataset.error = "true";
      } else {
        this.activeWord.innerHTML = "";
        delete this.activeWord.dataset.error;
      }
      delete this.activeWord.dataset.shielded;
    }
    if (this.typingErrorHint && !hintFresh) {
      this.typingErrorHint = null;
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
    const nextFingerChar =
      (hasTypingError && expectedKey ? expectedKey : activeEnemy?.word?.charAt(activeEnemy.typed)) ??
      null;
    this.renderFingerHint(nextFingerChar);
    this.refreshStickerBookState(state);
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

  showTypingErrorHint(hint: { expected: string | null; received: string | null; enemyId: string | null }): void {
    this.typingErrorHint = {
      expected: hint.expected,
      received: hint.received,
      enemyId: hint.enemyId,
      timestamp: typeof performance !== "undefined" ? performance.now() : Date.now()
    };
  }

  private renderFingerHint(targetChar: string | null): void {
    if (!this.fingerHint) return;
    const mapping = this.getFingerMapping(targetChar);
    if (!mapping) {
      this.fingerHint.dataset.visible = "false";
      this.fingerHint.setAttribute("aria-hidden", "true");
      this.fingerHint.textContent = "";
      return;
    }
    const { finger, keyLabel } = mapping;
    this.fingerHint.dataset.visible = "true";
    this.fingerHint.setAttribute("aria-hidden", "false");
    this.fingerHint.replaceChildren();
    const fingerSpan = document.createElement("span");
    fingerSpan.className = "finger-finger";
    fingerSpan.textContent = finger;
    const keySpan = document.createElement("span");
    keySpan.className = "finger-key";
    keySpan.textContent = keyLabel;
    this.fingerHint.append(fingerSpan, keySpan);
  }

  private getFingerMapping(char: string | null): { finger: string; keyLabel: string } | null {
    if (!char || char.length === 0) return null;
    if (char === " ") {
      return { finger: "Thumb", keyLabel: "Space" };
    }
    if (char === "\t") {
      return { finger: "Left pinky", keyLabel: "Tab" };
    }
    if (char === "\n") {
      return { finger: "Right pinky", keyLabel: "Enter" };
    }
    const normalizedKey = this.normalizeFingerKey(char);
    const finger = FINGER_LOOKUP[normalizedKey];
    if (!finger) {
      return null;
    }
    return {
      finger,
      keyLabel: this.formatFingerKeyLabel(char)
    };
  }

  private normalizeFingerKey(char: string): string {
    const mapped = FINGER_SHIFTED_KEY_MAP[char] ?? char;
    if (!mapped || mapped.length === 0) {
      return "";
    }
    return mapped.charAt(0).toLowerCase();
  }

  private formatFingerKeyLabel(char: string): string {
    if (char === " ") return "Space";
    if (char === "\t") return "Tab";
    if (char === "\n") return "Enter";
    if (char.length === 1 && /[a-z]/i.test(char)) {
      return char.toUpperCase();
    }
    return char;
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
    if (this.waveScorecard.tip) {
      const text = (data.microTip ?? "").trim();
      if (text) {
        this.waveScorecard.tip.textContent = text;
        this.waveScorecard.tip.dataset.visible = "true";
        this.waveScorecard.tip.setAttribute("aria-hidden", "false");
      } else {
        this.waveScorecard.tip.textContent = "";
        this.waveScorecard.tip.dataset.visible = "false";
        this.waveScorecard.tip.setAttribute("aria-hidden", "true");
      }
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

  private showParentalOverlay(trigger?: HTMLElement): void {
    if (!this.parentalOverlay) return;
    this.parentalOverlayTrigger = trigger ?? null;
    this.parentalOverlay.container.dataset.visible = "true";
    this.parentalOverlay.container.setAttribute("aria-hidden", "false");
    this.parentalOverlay.closeButton.focus();
  }

  private hideParentalOverlay(): void {
    if (!this.parentalOverlay) return;
    this.parentalOverlay.container.dataset.visible = "false";
    this.parentalOverlay.container.setAttribute("aria-hidden", "true");
    const target = this.parentalOverlayTrigger;
    this.parentalOverlayTrigger = null;
    if (target instanceof HTMLElement) {
      target.focus();
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

  private updateScreenShakeIntensityDisplay(intensity: number): void {
    if (this.optionsOverlay?.screenShakeValue) {
      const percent = Math.round(intensity * 100);
      this.optionsOverlay.screenShakeValue.textContent = `${percent}%`;
    }
    if (this.optionsOverlay?.screenShakeDemo) {
      this.optionsOverlay.screenShakeDemo.style.setProperty(
        "--shake-strength",
        intensity.toString()
      );
    }
  }

  playScreenShakePreview(): void {
    const demo = this.optionsOverlay?.screenShakeDemo;
    if (!demo || demo.dataset.disabled === "true") return;
    demo.dataset.shaking = "false";
    // force reflow to restart animation
    void demo.offsetWidth;
    demo.dataset.shaking = "true";
    setTimeout(() => {
      demo.dataset.shaking = "false";
    }, 450);
  }

  private updateAccessibilitySelfTestDisplay(
    selfTest:
      | {
          lastRunAt: string | null;
          soundConfirmed: boolean;
          visualConfirmed: boolean;
          motionConfirmed: boolean;
        }
      | undefined,
    options: { soundEnabled: boolean; reducedMotionEnabled: boolean } = {
      soundEnabled: true,
      reducedMotionEnabled: false
    }
  ): void {
    if (!this.optionsOverlay) return;
    const state = selfTest ?? ACCESSIBILITY_SELF_TEST_DEFAULT;
    const soundDisabled = !(options?.soundEnabled ?? true);
    const motionDisabled = Boolean(options?.reducedMotionEnabled);
    if (this.optionsOverlay.selfTestContainer) {
      this.optionsOverlay.selfTestContainer.dataset.soundDisabled = soundDisabled ? "true" : "false";
      this.optionsOverlay.selfTestContainer.dataset.motionDisabled = motionDisabled ? "true" : "false";
    }
    if (this.optionsOverlay.selfTestStatus) {
      const label = state.lastRunAt
        ? `Last run: ${state.lastRunAt.slice(0, 16).replace("T", " ")}`
        : "Not run yet";
      this.optionsOverlay.selfTestStatus.textContent = label;
    }
    this.applySelfTestToggleState(
      this.optionsOverlay.selfTestSoundToggle,
      this.optionsOverlay.selfTestSoundIndicator,
      state.soundConfirmed && !soundDisabled,
      soundDisabled
    );
    this.applySelfTestToggleState(
      this.optionsOverlay.selfTestVisualToggle,
      this.optionsOverlay.selfTestVisualIndicator,
      state.visualConfirmed,
      false
    );
    this.applySelfTestToggleState(
      this.optionsOverlay.selfTestMotionToggle,
      this.optionsOverlay.selfTestMotionIndicator,
      state.motionConfirmed && !motionDisabled,
      motionDisabled
    );
  }

  private applySelfTestToggleState(
    toggle: HTMLInputElement | undefined,
    indicator: HTMLElement | undefined,
    confirmed: boolean,
    disabled: boolean
  ): void {
    if (toggle) {
      toggle.checked = confirmed;
      toggle.disabled = disabled;
      toggle.tabIndex = disabled ? -1 : 0;
      toggle.setAttribute("aria-disabled", disabled ? "true" : "false");
    }
    const row =
      (indicator?.closest(".option-selftest-row") as HTMLElement | null) ??
      (toggle?.closest(".option-selftest-row") as HTMLElement | null);
    if (row) {
      row.dataset.disabled = disabled ? "true" : "false";
      row.dataset.confirmed = confirmed ? "true" : "false";
    }
    if (indicator) {
      indicator.dataset.disabled = disabled ? "true" : "false";
      indicator.dataset.confirmed = confirmed ? "true" : "false";
    }
  }

  playAccessibilitySelfTestCues(options: { includeMotion?: boolean; soundEnabled?: boolean } = {}): void {
    const includeMotion = options.includeMotion !== false;
    const soundAllowed = options.soundEnabled !== false;
    const pulse = (el: HTMLElement | undefined, duration = 700) => {
      if (!el) return;
      el.dataset.active = "false";
      void el.offsetWidth;
      el.dataset.active = "true";
      setTimeout(() => {
        el.dataset.active = "false";
      }, duration);
    };
    if (soundAllowed) {
      pulse(this.optionsOverlay?.selfTestSoundIndicator, 700);
    }
    pulse(this.optionsOverlay?.selfTestVisualIndicator, 760);
    if (includeMotion) {
      pulse(this.optionsOverlay?.selfTestMotionIndicator, 650);
    }
  }

  runContrastAudit(): void {
    if (!this.contrastOverlay) {
      console.warn("Contrast overlay is not available; cannot run audit.");
      return;
    }
    const results = this.collectContrastAuditResults();
    this.presentContrastAudit(results);
  }

  presentContrastAudit(results: ContrastAuditResult[]): void {
    if (!this.contrastOverlay) return;
    const container = this.contrastOverlay.container;
    const list = this.contrastOverlay.list;
    const markers = this.contrastOverlay.markers;
    list.replaceChildren();
    markers.replaceChildren();

    let warnCount = 0;
    let failCount = 0;
    for (const result of results) {
      if (result.status === "warn") warnCount += 1;
      if (result.status === "fail") failCount += 1;
      const item = document.createElement("li");
      item.className = "contrast-overlay-item";
      item.dataset.status = result.status;
      const label = document.createElement("div");
      label.className = "contrast-overlay-label";
      label.textContent = result.label;
      const ratio = document.createElement("span");
      ratio.className = "contrast-overlay-ratio";
      ratio.textContent = `${result.ratio.toFixed(2)} : 1`;
      item.appendChild(label);
      item.appendChild(ratio);
      list.appendChild(item);

      const marker = document.createElement("div");
      marker.className = "contrast-overlay-marker";
      marker.dataset.status = result.status;
      marker.style.left = `${result.rect.x + window.scrollX}px`;
      marker.style.top = `${result.rect.y + window.scrollY}px`;
      marker.style.width = `${result.rect.width}px`;
      marker.style.height = `${result.rect.height}px`;
      markers.appendChild(marker);
    }

    const total = results.length;
    if (this.contrastOverlay.summary) {
      if (total === 0) {
        this.contrastOverlay.summary.textContent = "No elements were inspected.";
      } else {
        this.contrastOverlay.summary.textContent = `Checked ${total} regions / ${failCount} fail, ${warnCount} warn (target 4.5:1).`;
      }
    }

    container.dataset.visible = "true";
    container.setAttribute("aria-hidden", "false");
  }

  hideContrastOverlay(): void {
    if (!this.contrastOverlay) return;
    this.contrastOverlay.container.dataset.visible = "false";
    this.contrastOverlay.container.setAttribute("aria-hidden", "true");
    this.contrastOverlay.list.replaceChildren();
    this.contrastOverlay.markers.replaceChildren();
  }

  setCastleSkin(skin: CastleSkinId): void {
    const normalized = this.normalizeCastleSkin(skin);
    if (this.castleSkin === normalized && this.optionsOverlay?.castleSkinSelect) {
      this.setSelectValue(this.optionsOverlay.castleSkinSelect, normalized);
      return;
    }
    this.castleSkin = normalized;
    this.applyCastleSkinDataset(normalized);
    if (this.optionsOverlay?.castleSkinSelect) {
      this.setSelectValue(this.optionsOverlay.castleSkinSelect, normalized);
    }
  }

  showStickerBookOverlay(): void {
    if (!this.stickerBookOverlay) return;
    if (this.lastState) {
      this.refreshStickerBookState(this.lastState);
    }
    this.renderStickerBook(this.stickerBookEntries);
    this.stickerBookOverlay.container.dataset.visible = "true";
    this.stickerBookOverlay.container.setAttribute("aria-hidden", "false");
    const focusable = this.getFocusableElements(this.stickerBookOverlay.container);
    focusable[0]?.focus();
  }

  hideStickerBookOverlay(): void {
    if (!this.stickerBookOverlay) return;
    this.stickerBookOverlay.container.dataset.visible = "false";
    this.stickerBookOverlay.container.setAttribute("aria-hidden", "true");
  }

  showSeasonTrackOverlay(): void {
    if (!this.seasonTrackOverlay) return;
    if (this.seasonTrackState) {
      this.renderSeasonTrackOverlay(this.seasonTrackState);
    } else {
      this.renderSeasonTrackOverlay({
        lessonsCompleted: 0,
        total: 0,
        unlocked: 0,
        next: null,
        entries: []
      });
    }
    this.seasonTrackOverlay.container.dataset.visible = "true";
    this.seasonTrackOverlay.container.setAttribute("aria-hidden", "false");
    const focusable = this.getFocusableElements(this.seasonTrackOverlay.container);
    focusable[0]?.focus();
  }

  hideSeasonTrackOverlay(): void {
    if (!this.seasonTrackOverlay) return;
    this.seasonTrackOverlay.container.dataset.visible = "false";
    this.seasonTrackOverlay.container.setAttribute("aria-hidden", "true");
  }

  showParentSummary(): void {
    if (!this.parentSummaryOverlay) return;
    this.renderParentSummary();
    this.parentSummaryOverlay.container.dataset.visible = "true";
    this.parentSummaryOverlay.container.setAttribute("aria-hidden", "false");
    const focusable = this.getFocusableElements(this.parentSummaryOverlay.container);
    focusable[0]?.focus();
  }

  hideParentSummary(): void {
    if (!this.parentSummaryOverlay) return;
    this.parentSummaryOverlay.container.dataset.visible = "false";
    this.parentSummaryOverlay.container.setAttribute("aria-hidden", "true");
  }

  downloadParentSummary(): void {
    if (!this.parentSummaryOverlay) return;
    const wasVisible = this.parentSummaryOverlay.container.dataset.visible === "true";
    if (!wasVisible) {
      this.showParentSummary();
    }
    if (typeof window !== "undefined" && typeof window.print === "function") {
      window.print();
    }
    if (!wasVisible) {
      this.hideParentSummary();
    }
  }

  setStickerBookEntries(entries: StickerBookEntry[]): void {
    this.stickerBookEntries = entries;
    this.updateStickerBookSummary();
    if (this.stickerBookOverlay?.container.dataset.visible === "true") {
      this.renderStickerBook(entries);
    }
  }

  setSeasonTrackProgress(state: SeasonTrackViewState): void {
    this.seasonTrackState = state;
    if (this.seasonTrackPanel?.progress) {
      this.seasonTrackPanel.progress.textContent = `${state.unlocked} / ${state.total} unlocked`;
    }
    if (this.seasonTrackPanel?.lessons) {
      const lessonLabel = state.lessonsCompleted === 1 ? "lesson completed" : "lessons completed";
      this.seasonTrackPanel.lessons.textContent = `${state.lessonsCompleted} ${lessonLabel}`;
    }
    if (this.seasonTrackPanel?.next) {
      this.seasonTrackPanel.next.textContent =
        state.next && state.next.remaining > 0
          ? `Next reward after ${state.next.remaining} more lessons`
          : "All rewards unlocked!";
    }
    if (this.seasonTrackPanel?.requirement) {
      if (state.next) {
        this.seasonTrackPanel.requirement.textContent = `Upcoming: ${state.next.title} (needs ${state.next.requiredLessons} lessons)`;
      } else {
        this.seasonTrackPanel.requirement.textContent = "Season complete. Enjoy your rewards!";
      }
    }
    if (this.seasonTrackOverlay) {
      this.renderSeasonTrackOverlay(state);
    }
  }

  private readCertificateName(): string {
    if (typeof window === "undefined" || !window.localStorage) return "";
    try {
      const raw = window.localStorage.getItem(CERTIFICATE_NAME_KEY);
      return typeof raw === "string" ? raw : "";
    } catch {
      return "";
    }
  }

  private persistCertificateName(name: string): void {
    if (typeof window === "undefined" || !window.localStorage) return;
    try {
      window.localStorage.setItem(CERTIFICATE_NAME_KEY, name);
    } catch {
      // ignore storage write failures
    }
  }

  private setCertificateName(name: string): void {
    const next = name?.trim() ?? "";
    this.certificateName = next;
    this.persistCertificateName(next);
    this.renderMasteryCertificatePanel();
    this.renderMasteryCertificateOverlay();
  }

  showLessonMedalOverlay(): void {
    if (!this.lessonMedalOverlay) return;
    this.lessonMedalOverlay.container.dataset.visible = "true";
    this.lessonMedalOverlay.container.setAttribute("aria-hidden", "false");
    this.renderLessonMedalOverlay(this.lessonMedalState ?? this.getEmptyLessonMedalState());
    const focusable = this.getFocusableElements(this.lessonMedalOverlay.container);
    focusable[0]?.focus();
  }

  hideLessonMedalOverlay(): void {
    if (!this.lessonMedalOverlay) return;
    this.lessonMedalOverlay.container.dataset.visible = "false";
    this.lessonMedalOverlay.container.setAttribute("aria-hidden", "true");
  }

  showMasteryCertificateOverlay(): void {
    if (!this.masteryCertificate) return;
    this.masteryCertificate.container.dataset.visible = "true";
    this.masteryCertificate.container.setAttribute("aria-hidden", "false");
    this.renderMasteryCertificateOverlay();
    const focusable = this.getFocusableElements(this.masteryCertificate.container);
    focusable[0]?.focus();
  }

  hideMasteryCertificateOverlay(): void {
    if (!this.masteryCertificate) return;
    this.masteryCertificate.container.dataset.visible = "false";
    this.masteryCertificate.container.setAttribute("aria-hidden", "true");
  }

  showSideQuestOverlay(): void {
    if (!this.sideQuestOverlay) return;
    this.renderSideQuestOverlay();
    this.sideQuestOverlay.container.dataset.visible = "true";
    this.sideQuestOverlay.container.setAttribute("aria-hidden", "false");
    const focusable = this.getFocusableElements(this.sideQuestOverlay.container);
    focusable[0]?.focus();
  }

  hideSideQuestOverlay(): void {
    if (!this.sideQuestOverlay) return;
    this.sideQuestOverlay.container.dataset.visible = "false";
    this.sideQuestOverlay.container.setAttribute("aria-hidden", "true");
  }

  showMuseumOverlay(): void {
    if (!this.museumOverlay) return;
    this.renderMuseumOverlay();
    this.museumOverlay.container.dataset.visible = "true";
    this.museumOverlay.container.setAttribute("aria-hidden", "false");
    const focusable = this.getFocusableElements(this.museumOverlay.container);
    focusable[0]?.focus();
  }

  hideMuseumOverlay(): void {
    if (!this.museumOverlay) return;
    this.museumOverlay.container.dataset.visible = "false";
    this.museumOverlay.container.setAttribute("aria-hidden", "true");
  }

  celebrateMilestone(options: {
    title: string;
    detail: string;
    tone?: "gold" | "platinum" | "lesson" | "default";
    eyebrow?: string;
    durationMs?: number;
  }): void {
    if (!this.milestoneCelebration) return;
    const { container, title, detail, badge, eyebrow } = this.milestoneCelebration;
    if (title) {
      title.textContent = options.title;
    }
    if (detail) {
      detail.textContent = options.detail;
    }
    if (eyebrow) {
      eyebrow.textContent = options.eyebrow ?? "Milestone reached";
    }
    if (badge) {
      const tone = options.tone ?? "default";
      if (tone === "gold") {
        badge.textContent = "Gold milestone";
      } else if (tone === "platinum") {
        badge.textContent = "Platinum milestone";
      } else if (tone === "lesson") {
        badge.textContent = "Lessons";
      } else {
        badge.textContent = "Milestone";
      }
      if (tone === "gold" || tone === "platinum" || tone === "lesson") {
        badge.dataset.tone = tone;
      } else {
        delete badge.dataset.tone;
      }
    }
    container.dataset.visible = "true";
    container.setAttribute("aria-hidden", "false");
    this.scheduleMilestoneHide(options.durationMs ?? 4800);
  }

  hideMilestoneCelebration(): void {
    if (!this.milestoneCelebration) return;
    this.milestoneCelebration.container.dataset.visible = "false";
    this.milestoneCelebration.container.setAttribute("aria-hidden", "true");
    if (this.milestoneCelebrationHideTimeout) {
      window.clearTimeout(this.milestoneCelebrationHideTimeout);
      this.milestoneCelebrationHideTimeout = null;
    }
  }

  private scheduleMilestoneHide(durationMs: number): void {
    if (this.milestoneCelebrationHideTimeout) {
      window.clearTimeout(this.milestoneCelebrationHideTimeout);
    }
    this.milestoneCelebrationHideTimeout = window.setTimeout(() => {
      this.hideMilestoneCelebration();
    }, durationMs);
  }

  private updateMentorDialogue(state: GameState, wpm: number): void {
    if (!this.mentorDialogue) return;
    const now = typeof performance !== "undefined" ? performance.now() : Date.now();
    const accuracy = Math.max(0, Math.min(1, state.typing.accuracy ?? 0));
    const totalInputs = Math.max(0, state.typing.totalInputs ?? 0);
    let focus: MentorFocus = "neutral";
    if (totalInputs >= 20) {
      if (accuracy < 0.9) {
        focus = "accuracy";
      } else if (accuracy >= 0.95 && wpm < 40) {
        focus = "speed";
      } else if (accuracy >= 0.96 && wpm >= 55) {
        focus = "speed";
      } else if (accuracy < 0.93 && wpm >= 45) {
        focus = "accuracy";
      } else {
        focus = "neutral";
      }
    }

    if (focus === this.mentorFocus && now < this.mentorNextUpdateAt) {
      return;
    }

    const focusLabel =
      focus === "accuracy" ? "Accuracy focus" : focus === "speed" ? "Speed focus" : "Balanced";
    if (this.mentorDialogue.focus) {
      this.mentorDialogue.focus.textContent = focusLabel;
    }
    this.mentorFocus = focus;
    this.mentorDialogue.container.dataset.focus = focus;

    const messages: Record<MentorFocus, string[]> = {
      accuracy: [
        "Dial back and steady accuracy - slow until errors disappear.",
        "Accuracy first: breathe, reset fingers, and chase clean streaks.",
        "Focus on clean inputs; short words and calm rhythm beat speed right now."
      ],
      speed: [
        "Accuracy looks solid - add a small speed burst for the next wave.",
        "Try a quicker tempo for 10 seconds while keeping combos alive.",
        "Feeling steady? Nudge speed up and keep accuracy above 95%."
      ],
      neutral: [
        "Balanced focus: keep accuracy steady, then push speed in sprints.",
        "Nice balance - stay relaxed and hold your rhythm.",
        "Keep the flow: calm hands, even pacing, clean combos."
      ]
    };
    const messagePool = messages[focus] ?? messages.neutral;
    const message = this.pickMentorMessage(focus, messagePool);
    if (this.mentorDialogue.text) {
      this.mentorDialogue.text.textContent = message;
    }
    this.mentorNextUpdateAt = now + 6000;
  }

  private pickMentorMessage(focus: MentorFocus, pool: string[]): string {
    if (!pool.length) return "";
    const index = this.mentorMessageCursor[focus] ?? 0;
    const message = pool[index % pool.length];
    this.mentorMessageCursor[focus] = (index + 1) % pool.length;
    return message;
  }

  private buildMuseumEntries(): Array<{
    id: string;
    title: string;
    description: string;
    unlocked: boolean;
    meta: string;
  }> {
    const lessons = this.lessonMedalState?.recent?.length ?? 0;
    const lessonMedalsUnlocked =
      (this.lessonMedalState?.totals?.bronze ?? 0) +
        (this.lessonMedalState?.totals?.silver ?? 0) +
        (this.lessonMedalState?.totals?.gold ?? 0) +
        (this.lessonMedalState?.totals?.platinum ?? 0) >
      0;
    const loreUnlocked = this.loreScrollState?.unlocked ?? 0;
    const seasonUnlocks = this.seasonTrackState?.unlocked ?? 0;
    const skinsUnlocked = this.castleSkin ? 1 : 0;
    const certificateUnlocked = Boolean(this.certificateStats);
    const companionMood = this.companionMood;

    return [
      {
        id: "castle-skins",
        title: "Castle Skins",
        description: "Concept art and palettes for your unlocked castle skins.",
        unlocked: skinsUnlocked > 0,
        meta: `Active skin: ${this.castleSkin}`
      },
      {
        id: "reward-track",
        title: "Season Artifacts",
        description: "Artifacts from the season reward track displayed in the hall.",
        unlocked: seasonUnlocks > 0,
        meta: `${seasonUnlocks} reward${seasonUnlocks === 1 ? "" : "s"} unlocked`
      },
      {
        id: "companion-gallery",
        title: "Companion Gallery",
        description: "Moods and sketches of your companion friend.",
        unlocked: companionMood === "happy" || companionMood === "cheer",
        meta: `Mood: ${companionMood}`
      },
      {
        id: "lore-shelves",
        title: "Lore Shelves",
        description: "Codex scrolls and lore snippets you've unlocked.",
        unlocked: loreUnlocked > 0,
        meta: `${loreUnlocked} scroll${loreUnlocked === 1 ? "" : "s"} collected`
      },
      {
        id: "medal-hall",
        title: "Medal Hall",
        description: "Frames for lesson medals and best runs.",
        unlocked: lessonMedalsUnlocked,
        meta: lessonMedalsUnlocked
          ? "Medals earned; best runs highlighted"
          : "Earn a medal to mount your first frame"
      },
      {
        id: "certificate-wing",
        title: "Certificate Wing",
        description: "Mastery certificate prints and signatures.",
        unlocked: certificateUnlocked,
        meta: certificateUnlocked ? "Certificate unlocked" : "Complete a run with strong accuracy"
      },
      {
        id: "practice-archives",
        title: "Practice Archives",
        description: "Gallery of drills and practice reels.",
        unlocked: lessons > 0,
        meta: `${lessons} drill${lessons === 1 ? "" : "s"} tracked`
      }
    ];
  }

  private renderMuseumPanel(): void {
    if (!this.museumPanel) return;
    this.museumEntries = this.buildMuseumEntries();
    const unlocked = this.museumEntries.filter((entry) => entry.unlocked).length;
    const total = this.museumEntries.length;
    if (this.museumPanel.summary) {
      this.museumPanel.summary.textContent = unlocked
        ? "Artifacts are being curated in the castle museum."
        : "Earn skins, medals, and scrolls to fill the museum.";
    }
    if (this.museumPanel.stats) {
      this.museumPanel.stats.textContent = `${unlocked} / ${total} on display`;
    }
  }

  private renderMuseumOverlay(): void {
    if (!this.museumOverlay) return;
    this.museumEntries = this.buildMuseumEntries();
    if (this.museumOverlay.subtitle) {
      const unlocked = this.museumEntries.filter((entry) => entry.unlocked).length;
      const total = this.museumEntries.length;
      this.museumOverlay.subtitle.textContent = `${unlocked} of ${total} artifacts are on display.`;
    }
    this.museumOverlay.list.replaceChildren();
    for (const entry of this.museumEntries) {
      const tile = document.createElement("div");
      tile.className = "museum-tile";
      tile.dataset.status = entry.unlocked ? "unlocked" : "locked";
      tile.setAttribute("role", "listitem");
      const title = document.createElement("p");
      title.className = "museum-tile__title";
      title.textContent = entry.title;
      const desc = document.createElement("p");
      desc.className = "museum-tile__desc";
      desc.textContent = entry.description;
      const meta = document.createElement("div");
      meta.className = "museum-tile__meta";
      const pill = document.createElement("span");
      pill.className = "museum-pill";
      pill.textContent = entry.unlocked ? "Unlocked" : "Locked";
      const metaText = document.createElement("span");
      metaText.textContent = entry.meta;
      meta.append(pill, metaText);
      tile.append(title, desc, meta);
      this.museumOverlay.list.appendChild(tile);
    }
  }

  private buildSideQuestEntries(): typeof this.sideQuestEntries {
    const lessonsCompleted = this.lessonsCompletedCount;
    const loreUnlocked = this.loreScrollState?.unlocked ?? 0;
    const medals = this.lessonMedalState?.totals ?? {
      bronze: 0,
      silver: 0,
      gold: 0,
      platinum: 0
    };
    const goldAndHigher = (medals.gold ?? 0) + (medals.platinum ?? 0);
    const drillsCompleted = this.lessonMedalState?.recent?.length ?? 0;

    return [
      {
        id: "quest-lessons",
        title: "Complete 3 lessons",
        description: "Finish three lessons or drills to stay sharp.",
        progress: Math.min(lessonsCompleted, 3),
        total: 3,
        status: lessonsCompleted >= 3 ? "completed" : "active",
        meta: `${Math.min(lessonsCompleted, 3)}/3`
      },
      {
        id: "quest-medal",
        title: "Earn a Gold medal",
        description: "Chase a Gold or Platinum medal on any drill.",
        progress: Math.min(goldAndHigher, 1),
        total: 1,
        status: goldAndHigher >= 1 ? "completed" : "active",
        meta: goldAndHigher >= 1 ? "Complete" : "0/1"
      },
      {
        id: "quest-lore",
        title: "Unlock a lore scroll",
        description: "Finish lessons to discover a new scroll.",
        progress: Math.min(loreUnlocked, 1),
        total: 1,
        status: loreUnlocked >= 1 ? "completed" : "active",
        meta: loreUnlocked >= 1 ? "Complete" : "0/1"
      },
      {
        id: "quest-drills",
        title: "Play 5 practice drills",
        description: "Keep fingers fresh with practice runs.",
        progress: Math.min(drillsCompleted, 5),
        total: 5,
        status: drillsCompleted >= 5 ? "completed" : "active",
        meta: `${Math.min(drillsCompleted, 5)}/5`
      }
    ];
  }

  private renderSideQuestPanel(): void {
    if (!this.sideQuestPanel) return;
    this.sideQuestEntries = this.buildSideQuestEntries();
    const completed = this.sideQuestEntries.filter((entry) => entry.status === "completed").length;
    const active = this.sideQuestEntries.length - completed;
    if (this.sideQuestPanel.summary) {
      this.sideQuestPanel.summary.textContent = completed
        ? "Quests are updating as you play."
        : "Pick a quest and aim for clean runs.";
    }
    if (this.sideQuestPanel.stats) {
      this.sideQuestPanel.stats.textContent = `${active} active / ${completed} completed`;
    }
  }

  private renderSideQuestOverlay(): void {
    if (!this.sideQuestOverlay) return;
    this.sideQuestEntries = this.buildSideQuestEntries();
    const completed = this.sideQuestEntries.filter((entry) => entry.status === "completed").length;
    const total = this.sideQuestEntries.length;
    if (this.sideQuestOverlay.subtitle) {
      this.sideQuestOverlay.subtitle.textContent = `${completed} of ${total} quests completed`;
    }
    this.sideQuestOverlay.list.replaceChildren();
    for (const entry of this.sideQuestEntries) {
      const tile = document.createElement("div");
      tile.className = "quest-tile";
      tile.dataset.status = entry.status;
      tile.setAttribute("role", "listitem");
      const title = document.createElement("p");
      title.className = "quest-tile__title";
      title.textContent = entry.title;
      const desc = document.createElement("p");
      desc.className = "quest-tile__desc";
      desc.textContent = entry.description;
      const meta = document.createElement("div");
      meta.className = "quest-tile__meta";
      const pill = document.createElement("span");
      pill.className = "quest-pill";
      pill.textContent = entry.status === "completed" ? "Completed" : "Active";
      const metaText = document.createElement("span");
      metaText.textContent = entry.meta;
      meta.append(pill, metaText);
      const progress = document.createElement("div");
      progress.className = "quest-progress";
      const bar = document.createElement("div");
      bar.className = "quest-progress__bar";
      const ratio = entry.total > 0 ? Math.min(1, entry.progress / entry.total) : 0;
      bar.style.width = `${ratio * 100}%`;
      progress.appendChild(bar);
      tile.append(title, desc, meta, progress);
      this.sideQuestOverlay.list.appendChild(tile);
    }
  }

  private maybeCelebrateLessonMilestone(lessonsCompleted: number): void {
    if (!Number.isFinite(lessonsCompleted)) return;
    const thresholds = [5, 10, 20, 30, 50, 75, 100];
    const nextThreshold = thresholds.find(
      (value) => lessonsCompleted >= value && this.lastLessonMilestoneCelebrated < value
    );
    if (!nextThreshold) {
      if (lessonsCompleted < this.lastLessonMilestoneCelebrated) {
        this.lastLessonMilestoneCelebrated = lessonsCompleted;
      }
      return;
    }
    this.lastLessonMilestoneCelebrated = nextThreshold;
    this.celebrateMilestone({
      title: `${nextThreshold} lessons completed!`,
      detail: `You have completed ${lessonsCompleted} lessons—hydrate, stretch, then tackle the next challenge.`,
      tone: "lesson",
      eyebrow: "Lesson milestone"
    });
  }

  downloadMasteryCertificate(): void {
    if (!this.masteryCertificate) return;
    const wasVisible = this.masteryCertificate.container.dataset.visible === "true";
    if (!wasVisible) {
      this.showMasteryCertificateOverlay();
    }
    if (typeof window !== "undefined" && typeof window.print === "function") {
      window.print();
    }
    if (!wasVisible) {
      this.hideMasteryCertificateOverlay();
    }
  }

  setLessonMedalProgress(state: LessonMedalViewState): void {
    const previousTimestamp = this.lessonMedalState?.last?.timestamp ?? 0;
    this.lessonMedalState = state;
    this.updateLessonMedalPanel(state);
    if (this.lessonMedalOverlay?.container.dataset.visible === "true") {
      this.renderLessonMedalOverlay(state);
    }
    if ((state.last?.timestamp ?? 0) > previousTimestamp) {
      if (state.last?.tier === "gold" || state.last?.tier === "platinum") {
        const tierLabel =
          state.last.tier.charAt(0).toUpperCase() + state.last.tier.slice(1).toLowerCase();
        const modeLabel =
          state.last.mode === "burst"
            ? "Burst"
            : state.last.mode === "endurance"
              ? "Endurance"
              : "Precision";
        const accuracy = Number.isFinite(state.last.accuracy)
          ? `${Math.round(Math.max(0, Math.min(1, state.last.accuracy)) * 100)}% accuracy`
          : "Great accuracy";
        this.celebrateMilestone({
          title: `${tierLabel} medal earned!`,
          detail: `${modeLabel} drill completed with ${accuracy}.`,
          tone: state.last.tier === "platinum" ? "platinum" : "gold",
          eyebrow: "Lesson milestone"
        });
      }
      this.flashLessonMedalHighlight();
    }
  }

  private getEmptyLessonMedalState(): LessonMedalViewState {
    return {
      last: null,
      recent: [],
      bestByMode: { burst: null, endurance: null, precision: null },
      totals: { bronze: 0, silver: 0, gold: 0, platinum: 0 },
      nextTarget: null
    };
  }

  private flashLessonMedalHighlight(): void {
    if (!this.lessonMedalPanel?.container) return;
    this.lessonMedalPanel.container.dataset.highlight = "true";
    if (this.lessonMedalHighlightTimeout) {
      window.clearTimeout(this.lessonMedalHighlightTimeout);
    }
    this.lessonMedalHighlightTimeout = window.setTimeout(() => {
      if (this.lessonMedalPanel?.container) {
        this.lessonMedalPanel.container.dataset.highlight = "false";
      }
      this.lessonMedalHighlightTimeout = null;
    }, 2200);
  }

  private updateLessonMedalPanel(state: LessonMedalViewState): void {
    if (!this.lessonMedalPanel) return;
    const lastTier = state.last?.tier ?? "bronze";
    const tierLabel = lastTier.charAt(0).toUpperCase() + lastTier.slice(1);
    const modeLabel = state.last ? this.formatTypingDrillMode(state.last.mode) : null;
    if (this.lessonMedalPanel.badge) {
      this.lessonMedalPanel.badge.dataset.tier = lastTier;
      this.lessonMedalPanel.badge.textContent = tierLabel;
    }
    if (this.lessonMedalPanel.summary) {
      if (state.last) {
        const accuracy = Math.round(state.last.accuracy * 100);
        const wpm = Math.round(state.last.wpm);
        this.lessonMedalPanel.summary.textContent = `${tierLabel} / ${modeLabel} / ${accuracy}% / ${wpm} WPM`;
      } else {
        this.lessonMedalPanel.summary.textContent =
          "Complete a typing drill to start earning medals.";
      }
    }
    if (this.lessonMedalPanel.best) {
      this.lessonMedalPanel.best.textContent = this.formatBestMedalLine(state);
    }
    if (this.lessonMedalPanel.next) {
      this.lessonMedalPanel.next.textContent =
        state.nextTarget?.hint ?? "Platinum secured—keep the streak alive.";
    }
  }

  private renderLessonMedalOverlay(state: LessonMedalViewState): void {
    if (!this.lessonMedalOverlay) return;
    const lastTier = state.last?.tier ?? "bronze";
    const tierLabel = lastTier.charAt(0).toUpperCase() + lastTier.slice(1);
    if (this.lessonMedalOverlay.badge) {
      this.lessonMedalOverlay.badge.dataset.tier = lastTier;
      this.lessonMedalOverlay.badge.textContent = tierLabel;
    }
    if (this.lessonMedalOverlay.last) {
      this.lessonMedalOverlay.last.textContent = state.last
        ? `${tierLabel} in ${this.formatTypingDrillMode(state.last.mode)} / ${Math.round(state.last.accuracy * 100)}% accuracy / ${Math.round(state.last.wpm)} WPM`
        : "Complete a typing drill to claim your first medal.";
    }
    if (this.lessonMedalOverlay.next) {
      this.lessonMedalOverlay.next.textContent =
        state.nextTarget?.hint ?? "Replay drills to keep medals fresh.";
    }
    if (this.lessonMedalOverlay.bestList) {
      const modes: Array<{ id: TypingDrillMode; label: string }> = [
        { id: "burst", label: "Burst Warmup" },
        { id: "endurance", label: "Endurance" },
        { id: "precision", label: "Shield Breaker" }
      ];
      this.lessonMedalOverlay.bestList.replaceChildren();
      for (const mode of modes) {
        const entry = state.bestByMode[mode.id];
        const card = document.createElement("div");
        card.className = "lesson-medal-mode";
        card.dataset.tier = entry?.tier ?? "bronze";
        const title = document.createElement("p");
        title.className = "lesson-medal-mode__title";
        title.textContent = mode.label;
        const badge = document.createElement("span");
        badge.className = "lesson-medal-mode__badge";
        badge.textContent = entry ? this.formatMedalTier(entry.tier) : "None";
        const stats = document.createElement("p");
        stats.className = "lesson-medal-mode__stats";
        if (entry) {
          stats.textContent = `${Math.round(entry.accuracy * 100)}% / ${Math.round(entry.wpm)} WPM / combo x${entry.bestCombo}`;
        } else {
          stats.textContent = "No medal yet—run this drill to set a baseline.";
        }
        title.appendChild(badge);
        card.appendChild(title);
        card.appendChild(stats);
        this.lessonMedalOverlay.bestList.appendChild(card);
      }
    }
    if (this.lessonMedalOverlay.historyList) {
      this.lessonMedalOverlay.historyList.replaceChildren();
      for (const entry of state.recent) {
        const item = document.createElement("li");
        item.className = "lesson-medal-history__item";
        item.dataset.tier = entry.tier;
        const badge = document.createElement("span");
        badge.className = "lesson-medal-history__badge";
        badge.textContent = this.formatMedalTier(entry.tier);
        const text = document.createElement("span");
        text.className = "lesson-medal-history__text";
        text.textContent = `${this.formatTypingDrillMode(entry.mode)} / ${Math.round(entry.accuracy * 100)}% / ${Math.round(entry.wpm)} WPM / combo x${entry.bestCombo} / ${entry.errors} error${entry.errors === 1 ? "" : "s"}`;
        item.appendChild(badge);
        item.appendChild(text);
        this.lessonMedalOverlay.historyList.appendChild(item);
      }
      if (!state.recent.length) {
        const empty = document.createElement("li");
        empty.className = "lesson-medal-history__item lesson-medal-history__item--empty";
        empty.textContent = "Run a drill to start building medal history.";
        this.lessonMedalOverlay.historyList.appendChild(empty);
      }
    }
    if (this.lessonMedalOverlay.replayButton) {
      this.lessonMedalOverlay.replayButton.textContent = state.nextTarget
        ? `Replay for ${this.formatMedalTier(state.nextTarget.tier)}`
        : "Replay drill";
    }
  }

  private formatMedalTier(tier: LessonMedalTier | string | null | undefined): string {
    const value = typeof tier === "string" && tier.length > 0 ? tier : "";
    if (!value) return "None";
    return value.charAt(0).toUpperCase() + value.slice(1);
  }

  private formatTypingDrillMode(mode: TypingDrillMode): string {
    switch (mode) {
      case "precision":
        return "Shield Breaker";
      case "endurance":
        return "Endurance";
      case "burst":
      default:
        return "Burst Warmup";
    }
  }

  private formatBestMedalLine(state: LessonMedalViewState): string {
    const parts: string[] = [];
    const modes: Array<{ id: TypingDrillMode; label: string }> = [
      { id: "burst", label: "Burst" },
      { id: "endurance", label: "Endurance" },
      { id: "precision", label: "Precision" }
    ];
    for (const mode of modes) {
      const entry = state.bestByMode[mode.id];
      parts.push(`${mode.label}: ${entry ? this.formatMedalTier(entry.tier) : "None"}`);
    }
    return parts.join(" / ");
  }

  showLoreScrollOverlay(): void {
    if (!this.loreScrollOverlay) return;
    if (this.loreScrollState) {
      this.renderLoreScrollOverlay(this.loreScrollState);
    } else {
      this.renderLoreScrollOverlay({
        lessonsCompleted: 0,
        total: 0,
        unlocked: 0,
        next: null,
        entries: []
      });
    }
    this.loreScrollOverlay.container.dataset.visible = "true";
    this.loreScrollOverlay.container.setAttribute("aria-hidden", "false");
    const focusable = this.getFocusableElements(this.loreScrollOverlay.container);
    focusable[0]?.focus();
  }

  hideLoreScrollOverlay(): void {
    if (!this.loreScrollOverlay) return;
    this.loreScrollOverlay.container.dataset.visible = "false";
    this.loreScrollOverlay.container.setAttribute("aria-hidden", "true");
  }

  private renderSeasonTrackOverlay(state: SeasonTrackViewState): void {
    if (!this.seasonTrackOverlay) return;
    this.seasonTrackOverlay.progress.textContent = `${state.unlocked} / ${state.total} unlocked`;
    if (this.seasonTrackOverlay.lessons) {
      const lessonLabel = state.lessonsCompleted === 1 ? "lesson completed" : "lessons completed";
      this.seasonTrackOverlay.lessons.textContent = `${state.lessonsCompleted} ${lessonLabel}`;
    }
    if (this.seasonTrackOverlay.next) {
      this.seasonTrackOverlay.next.textContent =
        state.next && state.next.remaining > 0
          ? `${state.next.title} unlocks after ${state.next.remaining} more lessons`
          : "You have unlocked every seasonal reward.";
    }
    this.seasonTrackOverlay.list.replaceChildren();
    for (const entry of state.entries) {
      const item = document.createElement("li");
      item.className = "season-track-card";
      item.dataset.status = entry.unlocked ? "unlocked" : "locked";
      const titleRow = document.createElement("p");
      titleRow.className = "season-track-card__title";
      titleRow.textContent = entry.title;
      const pill = document.createElement("span");
      pill.className = "season-track-card__pill";
      pill.textContent = entry.unlocked
        ? "Unlocked"
        : `${entry.remaining} lesson${entry.remaining === 1 ? "" : "s"} to go`;
      titleRow.appendChild(pill);
      const desc = document.createElement("p");
      desc.className = "season-track-card__desc";
      desc.textContent = entry.description;
      const meta = document.createElement("p");
      meta.className = "season-track-card__requirement";
      meta.textContent = `Requires ${entry.requiredLessons} lesson${entry.requiredLessons === 1 ? "" : "s"}`;
      item.appendChild(titleRow);
      item.appendChild(desc);
      item.appendChild(meta);
      this.seasonTrackOverlay.list.appendChild(item);
    }
  }

  setMasteryCertificate(state: {
    lessonsCompleted: number;
    accuracyPct: number;
    wpm: number;
    bestCombo: number;
    drillsCompleted: number;
    timeMinutes: number;
    recordedAt: string;
  }): void {
    const isNewCertificate = state.recordedAt !== this.lastCertificateCelebratedAt;
    this.certificateStats = state;
    if (isNewCertificate) {
      this.lastCertificateCelebratedAt = state.recordedAt;
      if (state.accuracyPct >= 95) {
        const name = this.certificateName || "Learner";
        this.celebrateMilestone({
          title: "Mastery certificate earned",
          detail: `${name} hit ${state.accuracyPct}% accuracy and ${state.wpm} WPM.`,
          tone: "platinum",
          eyebrow: "Certificate ready"
        });
      }
    }
    this.renderMasteryCertificatePanel();
    if (this.masteryCertificate?.container.dataset.visible === "true") {
      this.renderMasteryCertificateOverlay();
    }
  }

  private renderMasteryCertificatePanel(): void {
    if (!this.masteryCertificatePanel) return;
    const stats = this.certificateStats;
    if (this.masteryCertificatePanel.summary) {
      if (stats) {
        this.masteryCertificatePanel.summary.textContent = `${this.certificateName || "Learner"} is tracking towards mastery.`;
      } else {
        this.masteryCertificatePanel.summary.textContent =
          "Complete a session to generate a mastery certificate.";
      }
    }
    if (this.masteryCertificatePanel.stats) {
      if (stats) {
        this.masteryCertificatePanel.stats.textContent = `${stats.lessonsCompleted} lessons • ${stats.accuracyPct}% accuracy • ${stats.wpm} WPM • combo x${stats.bestCombo}`;
      } else {
        this.masteryCertificatePanel.stats.textContent = "Progress appears here after your next run.";
      }
    }
    if (this.masteryCertificatePanel.date) {
      this.masteryCertificatePanel.date.textContent = stats
        ? `Updated ${new Date(stats.recordedAt).toLocaleDateString()}`
        : "";
    }
    if (this.masteryCertificatePanel.nameInput) {
      if (this.masteryCertificatePanel.nameInput.value !== this.certificateName) {
        this.masteryCertificatePanel.nameInput.value = this.certificateName;
      }
    }
  }

  private renderMasteryCertificateOverlay(): void {
    if (!this.masteryCertificate) return;
    const stats = this.certificateStats;
    const name = this.certificateName || "Learner";
    if (this.masteryCertificate.nameInput) {
      if (this.masteryCertificate.nameInput.value !== this.certificateName) {
        this.masteryCertificate.nameInput.value = this.certificateName;
      }
    }
    if (this.masteryCertificate.summary) {
      this.masteryCertificate.summary.textContent = stats
        ? `${name} earned this certificate with ${stats.accuracyPct}% accuracy and ${stats.wpm} WPM.`
        : "Complete a run to generate a mastery certificate.";
    }
    if (this.masteryCertificate.date) {
      this.masteryCertificate.date.textContent = stats
        ? new Date(stats.recordedAt).toLocaleDateString()
        : "";
    }
    if (this.masteryCertificate.statsList) {
      this.masteryCertificate.statsList.replaceChildren();
      const list = this.masteryCertificate.statsList;
      const entries = stats
        ? [
            `Lessons completed: ${stats.lessonsCompleted}`,
            `Accuracy: ${stats.accuracyPct}%`,
            `WPM: ${stats.wpm}`,
            `Best combo: x${stats.bestCombo}`,
            `Typing drills: ${stats.drillsCompleted}`,
            `Time practiced: ${Math.round(stats.timeMinutes)} minutes`
          ]
        : ["Complete a lesson or drill to populate your certificate."];
      for (const text of entries) {
        const item = document.createElement("li");
        item.textContent = text;
        list.appendChild(item);
      }
    }
  }

  setLoreScrollProgress(state: LoreScrollViewState): void {
    const previousUnlocked = this.loreScrollState?.unlocked ?? 0;
    this.loreScrollState = state;
    this.updateLoreScrollPanel(state);
    if (this.loreScrollOverlay?.container.dataset.visible === "true") {
      this.renderLoreScrollOverlay(state);
    }
    if (state.unlocked > previousUnlocked) {
      this.flashLoreScrollHighlight();
    }
  }

  private flashLoreScrollHighlight(): void {
    if (!this.loreScrollPanel?.container) return;
    this.loreScrollPanel.container.dataset.highlight = "true";
    if (this.loreScrollHighlightTimeout) {
      window.clearTimeout(this.loreScrollHighlightTimeout);
    }
    this.loreScrollHighlightTimeout = window.setTimeout(() => {
      if (this.loreScrollPanel?.container) {
        this.loreScrollPanel.container.dataset.highlight = "false";
      }
      this.loreScrollHighlightTimeout = null;
    }, 2400);
  }

  private renderLoreScrollOverlay(state: LoreScrollViewState): void {
    if (!this.loreScrollOverlay) return;
    const { list, summary, progress } = this.loreScrollOverlay;
    summary.textContent = `Unlocked ${state.unlocked} of ${state.total} scrolls`;
    if (progress) {
      const lessonsLabel = state.lessonsCompleted === 1 ? "lesson" : "lessons";
      progress.textContent = `${state.lessonsCompleted} ${lessonsLabel} completed`;
    }
    list.replaceChildren();
    for (const entry of state.entries) {
      const item = document.createElement("li");
      item.className = "scroll-card";
      item.dataset.status = entry.unlocked ? "unlocked" : "locked";

      const header = document.createElement("div");
      header.className = "scroll-card__header";
      const title = document.createElement("p");
      title.className = "scroll-card__title";
      title.textContent = entry.title;
      const summaryText = document.createElement("p");
      summaryText.className = "scroll-card__summary";
      summaryText.textContent = entry.summary;
      header.appendChild(title);
      header.appendChild(summaryText);

      const meta = document.createElement("div");
      meta.className = "scroll-card__meta";
      const pill = document.createElement("span");
      pill.className = "scroll-card__pill";
      pill.textContent = entry.unlocked
        ? "Unlocked"
        : `Locked / ${entry.requiredLessons} lesson${entry.requiredLessons === 1 ? "" : "s"}`;
      const progressBar = document.createElement("div");
      progressBar.className = "scroll-card__progress";
      const progressFill = document.createElement("div");
      progressFill.className = "scroll-card__progress-fill";
      const required = Math.max(1, entry.requiredLessons);
      const percent = Math.max(
        0,
        Math.min(100, Math.round((Math.min(entry.progress, required) / required) * 100))
      );
      progressFill.style.width = `${percent}%`;
      const progressLabel = document.createElement("span");
      progressLabel.className = "scroll-card__progress-label";
      progressLabel.textContent = entry.unlocked
        ? "Complete"
        : `${Math.min(entry.progress, required)} / ${required}`;
      progressBar.appendChild(progressFill);
      progressBar.appendChild(progressLabel);
      meta.appendChild(pill);
      meta.appendChild(progressBar);

      const body = document.createElement("p");
      body.className = "scroll-card__body";
      body.textContent = entry.unlocked
        ? entry.body
        : `Complete ${entry.requiredLessons} lesson${entry.requiredLessons === 1 ? "" : "s"} to read this scroll.`;

      item.appendChild(header);
      item.appendChild(meta);
      item.appendChild(body);
      list.appendChild(item);
    }
  }

  private updateLoreScrollPanel(state: LoreScrollViewState): void {
    if (!this.loreScrollPanel) return;
    const lessonsLabel = state.lessonsCompleted === 1 ? "lesson" : "lessons";
    if (this.loreScrollPanel.summary) {
      this.loreScrollPanel.summary.textContent =
        "Finish lessons to unlock calming lore scrolls between waves.";
    }
    if (this.loreScrollPanel.progress) {
      this.loreScrollPanel.progress.textContent = `${state.unlocked} / ${state.total} scrolls`;
    }
    if (this.loreScrollPanel.lessons) {
      this.loreScrollPanel.lessons.textContent = `${state.lessonsCompleted} ${lessonsLabel} completed`;
    }
    if (this.loreScrollPanel.next) {
      if (!state.next) {
        this.loreScrollPanel.next.textContent = "All scrolls unlocked. Revisit any time.";
      } else {
        const remainingLabel = state.next.remaining === 1 ? "lesson" : "lessons";
        this.loreScrollPanel.next.textContent =
          state.next.remaining <= 0
            ? `Next scroll ready: ${state.next.title}`
            : `Next scroll unlocks after ${state.next.remaining} more ${remainingLabel}.`;
      }
    }
  }

  private normalizeCastleSkin(value: string): CastleSkinId {
    if (value === "dusk" || value === "aurora" || value === "ember") return value;
    return "classic";
  }

  private applyCastleSkinDataset(skin: CastleSkinId): void {
    const root = document.documentElement;
    if (root) {
      root.dataset.castleSkin = skin;
    }
    if (document.body) {
      document.body.dataset.castleSkin = skin;
    }
    if (this.hudRoot) {
      this.hudRoot.dataset.castleSkin = skin;
    }
  }

  private updateCompanionMood(state: GameState): void {
    if (!this.companionPet) return;
    const healthRatio =
      state.castle && typeof state.castle.health === "number" && typeof state.castle.maxHealth === "number"
        ? Math.max(0, Math.min(1, state.castle.health / Math.max(1, state.castle.maxHealth)))
        : 1;
    const breaches = state.analytics?.sessionBreaches ?? state.analytics?.breaches ?? 0;
    const accuracy = Math.max(0, Math.min(1, state.typing?.accuracy ?? 0));
    const totalInputs = Math.max(0, state.typing?.totalInputs ?? 0);
    const combo = Math.max(
      state.typing?.combo ?? 0,
      state.analytics?.sessionBestCombo ?? 0,
      state.analytics?.waveMaxCombo ?? 0
    );
    let mood: CompanionMood = "calm";
    if (healthRatio < 0.35 || breaches > 0) {
      mood = "sad";
    } else if (combo >= 25 || (combo >= 12 && accuracy >= 0.95)) {
      mood = "cheer";
    } else if (combo >= 6 || (accuracy >= 0.9 && totalInputs >= 10)) {
      mood = "happy";
    }
    this.applyCompanionMood(mood);
  }

  private applyCompanionMood(mood: CompanionMood): void {
    if (!this.companionPet) return;
    if (this.companionMood === mood && this.companionPet.dataset.mood === mood) {
      return;
    }
    this.companionMood = mood;
    this.companionPet.dataset.mood = mood;
    const label = this.describeCompanionMood(mood);
    this.companionPet.setAttribute("aria-label", `Companion mood: ${label}`);
    if (this.companionMoodLabel) {
      this.companionMoodLabel.textContent = label;
    }
    if (this.companionTip) {
      if (mood === "sad") {
        this.companionTip.textContent = "Patch the gates and keep accuracy steady to calm them.";
      } else if (mood === "cheer") {
        this.companionTip.textContent = "Great streak! Ride the momentum to keep them cheering.";
      } else if (mood === "happy") {
        this.companionTip.textContent = "Clean typing keeps your companion upbeat.";
      } else {
        this.companionTip.textContent = "Keep clean streaks to cheer them up.";
      }
    }
  }

  private refreshParentSummary(state: GameState): void {
    const timeMinutes = Math.max(0, (state.time ?? 0) / 60);
    const accuracyPct = Math.round(Math.max(0, Math.min(100, (state.typing?.accuracy ?? 0) * 100)));
    const wpm =
      timeMinutes > 0
        ? Math.max(0, Math.round((state.typing?.correctInputs ?? 0) / 5 / timeMinutes))
        : 0;
    const bestCombo = Math.max(
      state.analytics?.sessionBestCombo ?? 0,
      state.typing?.combo ?? 0,
      state.analytics?.waveMaxCombo ?? 0
    );
    const perfectWords =
      state.analytics?.totalPerfectWords ??
      state.analytics?.wavePerfectWords ??
      state.analytics?.waveHistory?.reduce((sum, wave) => sum + (wave.perfectWords ?? 0), 0) ??
      0;
    const breaches = state.analytics?.sessionBreaches ?? state.analytics?.breaches ?? 0;
    const drills = Array.isArray(state.analytics?.typingDrills)
      ? state.analytics.typingDrills.length
      : 0;
    const repairs = state.analytics?.totalCastleRepairs ?? 0;
    this.parentSummary = {
      timeMinutes,
      accuracyPct,
      wpm,
      bestCombo,
      perfectWords,
      breaches,
      drills,
      repairs
    };
    this.renderParentSummary();
  }

  private refreshMasteryCertificate(state: GameState, lessonsCompleted: number): void {
    const timeMinutes = Math.max(0, (state.time ?? 0) / 60);
    const accuracyPct = Math.round(Math.max(0, Math.min(100, (state.typing?.accuracy ?? 0) * 100)));
    const wpm =
      timeMinutes > 0
        ? Math.max(0, Math.round((state.typing?.correctInputs ?? 0) / 5 / timeMinutes))
        : 0;
    const bestCombo = Math.max(
      state.analytics?.sessionBestCombo ?? 0,
      state.typing?.combo ?? 0,
      state.analytics?.waveMaxCombo ?? 0
    );
    const drills = Array.isArray(state.analytics?.typingDrills)
      ? state.analytics.typingDrills.length
      : 0;
    this.setMasteryCertificate({
      lessonsCompleted: Math.max(0, Math.floor(lessonsCompleted)),
      accuracyPct,
      wpm,
      bestCombo,
      drillsCompleted: drills,
      timeMinutes,
      recordedAt: new Date().toISOString()
    });
  }

  private renderParentSummary(): void {
    if (!this.parentSummaryOverlay || !this.parentSummary) return;
    const summary = this.parentSummary;
    const minutesLabel =
      summary.timeMinutes < 90
        ? `${Math.round(summary.timeMinutes)} minutes`
        : `${(summary.timeMinutes / 60).toFixed(1)} hours`;
    const progressText = `${minutesLabel} / ${summary.accuracyPct}% accuracy / ${summary.wpm} WPM`;
    if (this.parentSummaryOverlay.progress) {
      this.parentSummaryOverlay.progress.textContent = progressText;
    }
    if (this.parentSummaryOverlay.note) {
      if (summary.breaches > 3) {
        this.parentSummaryOverlay.note.textContent =
          "Consider shorter runs or more repairs to reduce castle breaches.";
      } else if (summary.accuracyPct < 85) {
        this.parentSummaryOverlay.note.textContent =
          "Slow down for a session to rebuild accuracy, then ramp WPM later.";
      } else if (summary.drills > 0) {
        this.parentSummaryOverlay.note.textContent =
          "Great job mixing drills into the week. Keep streaks short and steady.";
      } else {
        this.parentSummaryOverlay.note.textContent =
          "Tip: add a few drills between waves to keep accuracy comfortable.";
      }
    }
    if (this.parentSummaryOverlay.time) {
      this.parentSummaryOverlay.time.textContent = minutesLabel;
    }
    if (this.parentSummaryOverlay.accuracy) {
      this.parentSummaryOverlay.accuracy.textContent = `${summary.accuracyPct}%`;
    }
    if (this.parentSummaryOverlay.wpm) {
      this.parentSummaryOverlay.wpm.textContent = summary.wpm.toString();
    }
    if (this.parentSummaryOverlay.combo) {
      this.parentSummaryOverlay.combo.textContent = `x${summary.bestCombo}`;
    }
    if (this.parentSummaryOverlay.perfect) {
      this.parentSummaryOverlay.perfect.textContent = summary.perfectWords.toString();
    }
    if (this.parentSummaryOverlay.breaches) {
      this.parentSummaryOverlay.breaches.textContent = summary.breaches.toString();
    }
    if (this.parentSummaryOverlay.drills) {
      this.parentSummaryOverlay.drills.textContent = summary.drills.toString();
    }
    if (this.parentSummaryOverlay.repairs) {
      this.parentSummaryOverlay.repairs.textContent = summary.repairs.toString();
    }
  }

  private describeCompanionMood(mood: CompanionMood): string {
    switch (mood) {
      case "cheer":
        return "Cheering";
      case "happy":
        return "Happy";
      case "sad":
        return "Concerned";
      default:
        return "Calm";
    }
  }

  private renderStickerBook(entries: StickerBookEntry[]): void {
    if (!this.stickerBookOverlay) return;
    const list = this.stickerBookOverlay.list;
    list.replaceChildren();
    for (const entry of entries) {
      const item = document.createElement("li");
      item.className = "sticker-card";
      item.dataset.status = entry.status;
      item.dataset.icon = entry.icon;

      const art = document.createElement("div");
      art.className = `sticker-icon sticker-icon--${entry.icon}`;
      art.setAttribute("aria-hidden", "true");
      item.appendChild(art);

      const content = document.createElement("div");
      const title = document.createElement("p");
      title.className = "sticker-card__title";
      title.textContent = entry.title;
      const desc = document.createElement("p");
      desc.className = "sticker-card__desc";
      desc.textContent = entry.description;

      const meta = document.createElement("div");
      meta.className = "sticker-card__meta";
      const statusPill = document.createElement("span");
      statusPill.className = "sticker-status-pill";
      statusPill.textContent =
        entry.status === "unlocked"
          ? entry.unlockedLabel ?? "Unlocked"
          : entry.status === "in-progress"
            ? "In progress"
            : "Locked";
      const progress = document.createElement("div");
      progress.className = "sticker-progress";
      const progressBar = document.createElement("div");
      progressBar.className = "sticker-progress-bar";
      const progressFill = document.createElement("div");
      progressFill.className = "sticker-progress-fill";
      const percent = Math.max(
        0,
        Math.min(100, Math.round(((entry.progress ?? 0) / Math.max(1, entry.goal)) * 100))
      );
      progressFill.style.width = `${percent}%`;
      const progressLabel = document.createElement("span");
      progressLabel.className = "sticker-progress-label";
      progressLabel.textContent =
        entry.status === "unlocked"
          ? "Complete"
          : `${Math.min(entry.progress, entry.goal)} / ${entry.goal}`;
      progressBar.appendChild(progressFill);
      progress.appendChild(progressBar);
      progress.appendChild(progressLabel);
      meta.appendChild(statusPill);
      meta.appendChild(progress);

      const footer = document.createElement("div");
      footer.className = "sticker-card__footer";
      footer.appendChild(meta);

      content.appendChild(title);
      content.appendChild(desc);
      content.appendChild(footer);

      item.appendChild(content);
      list.appendChild(item);
    }
    this.updateStickerBookSummary();
  }

  private updateStickerBookSummary(): void {
    if (!this.stickerBookOverlay) return;
    const unlocked = this.stickerBookEntries.filter((entry) => entry.status === "unlocked").length;
    const inProgress = this.stickerBookEntries.filter(
      (entry) => entry.status === "in-progress"
    ).length;
    this.stickerBookOverlay.summary.textContent = `Unlocked ${unlocked} of ${this.stickerBookEntries.length} / ${inProgress} in progress`;
  }

  private refreshStickerBookState(state: GameState): void {
    const entries = this.buildStickerBookEntriesFromState(state);
    this.setStickerBookEntries(entries);
  }

  private buildStickerBookEntriesFromState(state: GameState): StickerBookEntry[] {
    const wavesCleared = Math.max(0, Math.floor(state.wave?.index ?? 0));
    const breaches = state.analytics?.sessionBreaches ?? state.analytics?.breaches ?? 0;
    const comboPeak = Math.max(
      state.analytics?.sessionBestCombo ?? 0,
      state.typing?.combo ?? 0,
      state.analytics?.waveMaxCombo ?? 0
    );
    const shieldBreaks =
      state.analytics?.totalShieldBreaks ?? state.analytics?.waveShieldBreaks ?? 0;
    const goldHeld = Math.round(Math.max(0, state.resources?.gold ?? 0));
    const perfectWords =
      state.analytics?.totalPerfectWords ??
      state.analytics?.wavePerfectWords ??
      state.analytics?.waveHistory?.reduce((sum, wave) => sum + (wave.perfectWords ?? 0), 0) ??
      0;
    const typingDrills = Array.isArray(state.analytics?.typingDrills)
      ? state.analytics.typingDrills.length
      : 0;
    const accuracyPct = Math.round(Math.max(0, (state.typing?.accuracy ?? 0) * 100));

    const makeStatus = (progress: number, goal: number, unlocked = false): StickerBookEntry["status"] => {
      if (unlocked || progress >= goal) return "unlocked";
      if (progress > 0) return "in-progress";
      return "locked";
    };

    const entries: StickerBookEntry[] = [
      {
        id: "gate-guardian",
        title: "Gate Guardian",
        description: "Clear your first wave without a breach.",
        icon: "castle",
        goal: 1,
        progress: wavesCleared >= 1 && breaches === 0 ? 1 : wavesCleared,
        status: makeStatus(wavesCleared, 1, wavesCleared >= 1 && breaches === 0),
        unlockedLabel: breaches === 0 && wavesCleared >= 1 ? "Flawless opener" : undefined
      },
      {
        id: "combo-spark",
        title: "Combo Spark",
        description: "Hit a 5x combo without dropping the chain.",
        icon: "combo",
        goal: 5,
        progress: Math.min(comboPeak, 5),
        status: makeStatus(comboPeak, 5)
      },
      {
        id: "shield-breaker",
        title: "Shield Breaker",
        description: "Shatter 5 shields in a single session.",
        icon: "shield",
        goal: 5,
        progress: Math.min(shieldBreaks, 5),
        status: makeStatus(shieldBreaks, 5)
      },
      {
        id: "gold-keeper",
        title: "Gold Keeper",
        description: "Hold 350 gold at once without spending it.",
        icon: "treasure",
        goal: 350,
        progress: Math.min(goldHeld, 350),
        status: makeStatus(goldHeld, 350)
      },
      {
        id: "perfect-words",
        title: "Perfect Words",
        description: "Stack up 10 perfect words across any waves.",
        icon: "perfect",
        goal: 10,
        progress: Math.min(perfectWords, 10),
        status: makeStatus(perfectWords, 10)
      },
      {
        id: "calm-focus",
        title: "Calm Focus",
        description: "Finish a wave with 95%+ accuracy.",
        icon: "calm",
        goal: 95,
        progress: Math.min(accuracyPct, 95),
        status: makeStatus(accuracyPct, 95)
      },
      {
        id: "drill-runner",
        title: "Drill Runner",
        description: "Complete any typing drill this session.",
        icon: "drill",
        goal: 1,
        progress: Math.min(typingDrills, 1),
        status: makeStatus(typingDrills, 1)
      }
    ];

    return entries;
  }

  private collectContrastAuditResults(): ContrastAuditResult[] {
    if (typeof document === "undefined") return [];
    const selectors = [
      "#hud",
      "#options-overlay .option-toggle",
      "#options-overlay .option-range",
      "#options-overlay button",
      "#wave-scorecard",
      "#battle-log",
      "#typing-drills-overlay",
      "#diagnostics-overlay",
      ".roadmap-card",
      "#wave-preview",
      "#shortcut-overlay",
      "#hud .metrics",
      "#hud .castle-section"
    ];
    const visited = new Set<HTMLElement>();
    const results: ContrastAuditResult[] = [];
    for (const selector of selectors) {
      const nodes = Array.from(document.querySelectorAll(selector));
      for (const node of nodes) {
        if (!(node instanceof HTMLElement)) continue;
        if (visited.has(node)) continue;
        visited.add(node);
        const measured = this.measureElementContrast(node);
        if (measured) {
          results.push(measured);
        }
      }
    }
    return results;
  }

  private measureElementContrast(el: HTMLElement): ContrastAuditResult | null {
    const rect = el.getBoundingClientRect();
    if (rect.width === 0 || rect.height === 0) return null;
    const styles = getComputedStyle(el);
    const fg = this.parseColor(styles.color);
    const bg = this.resolveBackgroundColor(el);
    if (!fg || !bg) return null;
    const ratio = this.computeContrastRatio(fg, bg);
    const status: "pass" | "warn" | "fail" =
      ratio >= 4.5 ? "pass" : ratio >= 3 ? "warn" : "fail";
    return {
      label: this.describeNode(el),
      ratio,
      status,
      rect: { x: rect.left, y: rect.top, width: rect.width, height: rect.height }
    };
  }

  private describeNode(el: HTMLElement): string {
    const aria = el.getAttribute("aria-label");
    if (aria) return aria;
    if (el.id) return `#${el.id}`;
    if (el.dataset.label) return el.dataset.label;
    if (el.className) return `${el.tagName.toLowerCase()}.${(el.className as string)
      .split(" ")
      .filter(Boolean)
      .slice(0, 2)
      .join(".")}`;
    return el.tagName.toLowerCase();
  }

  private resolveBackgroundColor(el: HTMLElement): [number, number, number, number] | null {
    let current: HTMLElement | null = el;
    while (current) {
      const bg = getComputedStyle(current).backgroundColor;
      const parsed = this.parseColor(bg);
      if (parsed && parsed[3] > 0) {
        return parsed;
      }
      current = current.parentElement;
    }
    return this.parseColor(getComputedStyle(document.body).backgroundColor) ?? [15, 23, 42, 1];
  }

  private parseColor(value: string | null): [number, number, number, number] | null {
    if (!value) return null;
    const rgbMatch = value.match(
      /rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*(\d*(?:\.\d+)?))?\s*\)/
    );
    if (rgbMatch) {
      const [, r, g, b, a] = rgbMatch;
      return [
        Number.parseInt(r, 10),
        Number.parseInt(g, 10),
        Number.parseInt(b, 10),
        a !== undefined ? Number.parseFloat(a) : 1
      ];
    }
    if (value.startsWith("#")) {
      const hex = value.replace("#", "");
      if (hex.length === 6) {
        const r = Number.parseInt(hex.slice(0, 2), 16);
        const g = Number.parseInt(hex.slice(2, 4), 16);
        const b = Number.parseInt(hex.slice(4, 6), 16);
        return [r, g, b, 1];
      }
    }
    return null;
  }

  private computeContrastRatio(
    fg: [number, number, number, number],
    bg: [number, number, number, number]
  ): number {
    const toLinear = (channel: number) => {
      const normalized = channel / 255;
      return normalized <= 0.03928
        ? normalized / 12.92
        : Math.pow((normalized + 0.055) / 1.055, 2.4);
    };
    const fgLum =
      0.2126 * toLinear(fg[0]) + 0.7152 * toLinear(fg[1]) + 0.0722 * toLinear(fg[2]);
    const bgLum =
      0.2126 * toLinear(bg[0]) + 0.7152 * toLinear(bg[1]) + 0.0722 * toLinear(bg[2]);
    const lighter = Math.max(fgLum, bgLum);
    const darker = Math.min(fgLum, bgLum);
    return Math.round(((lighter + 0.05) / (darker + 0.05)) * 100) / 100;
  }

  private updateBackgroundBrightnessDisplay(value: number): void {
    if (!this.optionsOverlay?.backgroundBrightnessValue) return;
    const percent = Math.round(value * 100);
    this.optionsOverlay.backgroundBrightnessValue.textContent = `${percent}%`;
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

  setHudZoom(scale: number): void {
    if (typeof document !== "undefined") {
      document.documentElement.style.setProperty("--hud-zoom", scale.toString());
    }
    if (this.hudRoot) {
      this.hudRoot.dataset.zoom = scale.toString();
    }
  }
  setHudLayoutSide(side: "left" | "right"): void {
    if (typeof document !== "undefined") {
      document.body.dataset.hudLayout = side;
    }
    if (this.hudRoot) {
      this.hudRoot.dataset.layout = side;
    }
  }

  setHudFontScale(scale: number): void {
    if (typeof document === "undefined") return;
    document.documentElement.style.setProperty("--hud-font-scale", scale.toString());
  }

  private computeWpm(state: GameState): number {
    const minutes = Math.max(state.time / 60, 0.1);
    return Math.max(0, Math.round((state.typing.correctInputs / 5) / minutes));
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
