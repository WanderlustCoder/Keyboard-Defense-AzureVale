import { type CastleLevelConfig, type GameConfig } from "../core/config.js";
import {
  type CastlePassive,
  type GameStatus,
  type GameMode,
  type GameState,
  type GoldEvent,
  type LaneHazardState,
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
import { type LessonPathViewState } from "../data/lessons.js";
import { type LessonMedalTier, type LessonMedalViewState } from "../utils/lessonMedals.js";
import { type WpmLadderViewState } from "../utils/wpmLadder.js";
import { type BiomeGalleryViewState } from "../utils/biomeGallery.js";
import { type TrainingCalendarViewState } from "../utils/trainingCalendar.js";
import { type SessionGoalsViewState } from "../utils/sessionGoals.js";
import { type DailyQuestBoardViewState } from "../utils/dailyQuests.js";
import { type WeeklyQuestBoardViewState } from "../utils/weeklyQuest.js";
import { type DayNightMode } from "../utils/dayNightTheme.js";
import { type ParallaxScene } from "../utils/parallaxBackground.js";
import { type FocusOutlinePreset } from "../utils/focusOutlines.js";
import { NarrationManager } from "../utils/narration.js";
import { type SfxLibraryViewState } from "../utils/sfxLibrary.js";
import { type MusicStemViewState } from "../utils/musicStems.js";
import { getUiSchemeDefinition, type UiSchemeViewState } from "../utils/uiSoundScheme.js";
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
type ResolvedParallaxScene = Exclude<ParallaxScene, "auto">;
type BattleLogCategory = "breach" | "perfect" | "medal" | "quest" | "upgrade" | "system";
type BattleLogFilterCategory = Exclude<BattleLogCategory, "system">;
type BattleLogEntry = {
  message: string;
  category: BattleLogCategory;
  timestamp: number;
};
type BattleLogSummaryState = Record<BattleLogCategory, { count: number; lastMessage: string | null }>;
type BattleLogSummaryItem = {
  button: HTMLButtonElement;
  count: HTMLElement;
  last: HTMLElement;
};
type WavePreviewSnapshot = {
  entries: WaveSpawnPreview[];
  colorBlindFriendly: boolean;
  laneHazards: LaneHazardState[];
  emptyMessage: string | null;
};

const BATTLE_LOG_FILTERS: BattleLogFilterCategory[] = [
  "breach",
  "perfect",
  "medal",
  "quest",
  "upgrade"
];

const BATTLE_LOG_EMPTY_LABELS: Record<BattleLogFilterCategory, string> = {
  breach: "No breaches yet.",
  perfect: "No perfect words yet.",
  medal: "No medals earned yet.",
  quest: "No quest updates yet.",
  upgrade: "No upgrades yet."
};

const createBattleLogSummaryState = (): BattleLogSummaryState => ({
  breach: { count: 0, lastMessage: null },
  perfect: { count: 0, lastMessage: null },
  medal: { count: 0, lastMessage: null },
  quest: { count: 0, lastMessage: null },
  upgrade: { count: 0, lastMessage: null },
  system: { count: 0, lastMessage: null }
});

const isBattleLogFilterCategory = (
  value: string | null | undefined
): value is BattleLogFilterCategory => BATTLE_LOG_FILTERS.includes(value as BattleLogFilterCategory);

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

const PHYSICAL_FINGER_LOOKUP: Record<string, string> = (() => {
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

const VIRTUAL_KEYBOARD_LAYOUT_ROWS: Record<string, string[][]> = {
  qwerty: [
    ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
    ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"],
    ["z", "x", "c", "v", "b", "n", "m"]
  ],
  qwertz: [
    ["q", "w", "e", "r", "t", "z", "u", "i", "o", "p"],
    ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"],
    ["y", "x", "c", "v", "b", "n", "m"]
  ],
  azerty: [
    ["a", "z", "e", "r", "t", "y", "u", "i", "o", "p"],
    ["q", "s", "d", "f", "g", "h", "j", "k", "l", "m"],
    ["w", "x", "c", "v", "b", "n", ";"]
  ]
};

const FINGER_LOOKUP_BY_LAYOUT: Record<string, Record<string, string>> = (() => {
  const physicalRows = VIRTUAL_KEYBOARD_LAYOUT_ROWS.qwerty;
  const maps: Record<string, Record<string, string>> = {};
  for (const [layoutId, rows] of Object.entries(VIRTUAL_KEYBOARD_LAYOUT_ROWS)) {
    const map: Record<string, string> = { ...PHYSICAL_FINGER_LOOKUP };
    for (let rowIndex = 0; rowIndex < rows.length; rowIndex += 1) {
      const layoutRow = rows[rowIndex];
      const physicalRow = physicalRows[rowIndex] ?? [];
      for (let colIndex = 0; colIndex < layoutRow.length; colIndex += 1) {
        const physicalKey = physicalRow[colIndex];
        const label = layoutRow[colIndex];
        const finger = physicalKey ? PHYSICAL_FINGER_LOOKUP[physicalKey] : undefined;
        if (!label || !finger) continue;
        map[label] = finger;
        map[label.toLowerCase()] = finger;
        map[label.toUpperCase()] = finger;
      }
    }
    maps[layoutId] = map;
  }
  return maps;
})();

type ReadabilityTier = "base" | "fast" | "heavy" | "shield" | "caster" | "boss";

type ReadabilityGuideEntry = {
  id: string;
  name: string;
  tier: ReadabilityTier;
  color: string;
  accent: string;
  shape: "base" | "runner" | "brute" | "shield" | "caster" | "boss";
  summary: string;
  tags: string[];
  tips: string[];
};

const READABILITY_GUIDE: ReadabilityGuideEntry[] = [
  {
    id: "grunt",
    name: "Grunt",
    tier: "base",
    color: "#38bdf8",
    accent: "#0ea5e9",
    shape: "base",
    summary: "Rounded silhouette, mid height, balanced contrast.",
    tags: ["Rounded silhouette", "Calm blue accent", "Short words"],
    tips: [
      "Keep outlines thick so letters never blend into the body.",
      "Avoid internal detail; a flat fill preserves legibility on motion.",
      "Use 1- or 2-syllable words for quick lock-on."
    ]
  },
  {
    id: "runner",
    name: "Runner",
    tier: "fast",
    color: "#22c55e",
    accent: "#4ade80",
    shape: "runner",
    summary: "Lean, forward tilt with a high-contrast edge.",
    tags: ["Leaning silhouette", "Bright edge glow", "Short/medium words"],
    tips: [
      "Keep the head/tail clear so the direction reads instantly.",
      "Use a bright accent on the leading edge to signal speed.",
      "Prefer 4–7 letter words for fair reaction windows."
    ]
  },
  {
    id: "brute",
    name: "Brute",
    tier: "heavy",
    color: "#a855f7",
    accent: "#c084fc",
    shape: "brute",
    summary: "Tall, blocky mass with slow cadence and deep shadows.",
    tags: ["Wide stance", "Soft purple core", "Longer words"],
    tips: [
      "Use chunky silhouettes with no spindly limbs.",
      "Add a soft ambient rim light so letters pop on dark scenes.",
      "Favor 6–9 letter words to match slower travel speed."
    ]
  },
  {
    id: "guardian",
    name: "Guardian",
    tier: "shield",
    color: "#fbbf24",
    accent: "#facc15",
    shape: "shield",
    summary: "Rectangle shield profile with bright crest for callouts.",
    tags: ["Shield slab", "Warm crest", "Medium words"],
    tips: [
      "Anchor a high-contrast crest so shielded state reads at a glance.",
      "Hold a darker body so bright letters stay readable.",
      "Show damage cracks with thin lines only—avoid text overlap."
    ]
  },
  {
    id: "hexcaster",
    name: "Hexcaster",
    tier: "caster",
    color: "#f97316",
    accent: "#fb923c",
    shape: "caster",
    summary: "Orb-like caster with airy outline and floating accent.",
    tags: ["Floating silhouette", "Amber glow", "Medium words"],
    tips: [
      "Keep the core circular with a glow that never eclipses letters.",
      "Use a thin outline to separate the orb from overlapping effects.",
      "Surface a brief pre-cast flash for accessibility."
    ]
  },
  {
    id: "siege",
    name: "Siege/Boss",
    tier: "boss",
    color: "#ef4444",
    accent: "#fb7185",
    shape: "boss",
    summary: "Broad, grounded frame with layered color bands.",
    tags: ["Largest silhouette", "Crimson core", "Long words"],
    tips: [
      "Cap on-screen footprint so text still fits inside the silhouette.",
      "Use layered color bands to separate weak points from body.",
      "Add a neutral backdrop strip if other effects would clash."
    ]
  }
];

const ACCESSIBILITY_SELF_TEST_DEFAULT = {
  lastRunAt: null,
  soundConfirmed: false,
  visualConfirmed: false,
  motionConfirmed: false
};
const CERTIFICATE_NAME_KEY = "keyboard-defense:certificate-name";
const MASTERY_CERTIFICATE_MILESTONE_SHOWN_KEY =
  "keyboard-defense:mastery-certificate-milestone-shown";
const MILESTONE_CELEBRATIONS_DISABLED_KEY = "keyboard-defense:milestone-celebrations-disabled";

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
  onBuildMenuToggle?: (open: boolean) => void;
  onTurretPresetSave?: (presetId: string) => void;
  onTurretPresetApply?: (presetId: string) => void;
  onTurretPresetClear?: (presetId: string) => void;
  onAnalyticsExport?: () => void;
  onSessionTimelineExport?: () => void;
  onKeystrokeTimingExport?: () => void;
  onBreakReminderIntervalChange?: (minutes: number) => void;
  onScreenTimeGoalChange?: (minutes: number) => void;
  onScreenTimeLockoutModeChange?: (mode: string) => void;
  onScreenTimeReset?: () => void;
  onProgressExport?: () => void;
  onProgressImport?: () => void;
  onDropoffReasonSelected?: (reasonId: string) => void;
  onTelemetryToggle?: (enabled: boolean) => void;
  onTelemetryQueueDownload?: () => void;
  onTelemetryQueueClear?: () => void;
  onCrystalPulseToggle?: (enabled: boolean) => void;
  onEliteAffixesToggle?: (enabled: boolean) => void;
  onPauseRequested(): void;
  onResumeRequested(): void;
  onSoundToggle(enabled: boolean): void;
  onSoundVolumeChange(volume: number): void;
  onSoundIntensityChange(intensity: number): void;
  onMusicToggle?: (enabled: boolean) => void;
  onMusicLevelChange?: (level: number) => void;
  onMusicLibrarySelect?: (suiteId: string) => void;
  onMusicLibraryPreview?: (suiteId: string) => void;
  onUiSoundPreview?: () => void;
  onUiSoundSchemeSelect?: (schemeId: string) => void;
  onUiSoundSchemePreview?: (schemeId: string) => void;
  onSfxLibrarySelect?: (libraryId: string) => void;
  onSfxLibraryPreview?: (libraryId: string) => void;
  onScreenShakeToggle?: (enabled: boolean) => void;
  onScreenShakeIntensityChange?: (intensity: number) => void;
  onScreenShakePreview?: () => void;
  onContrastAuditRequested?: () => void;
  onCastleSkinChange?: (skin: CastleSkinId) => void;
  onBiomeSelect?: (biomeId: string) => void;
  onAccessibilitySelfTestRun?: () => void;
  onAccessibilitySelfTestConfirm?: (
    kind: "sound" | "visual" | "motion",
    confirmed: boolean
  ) => void;
  onDiagnosticsToggle(visible: boolean): void;
  onVirtualKeyboardToggle?: (enabled: boolean) => void;
  onVirtualKeyboardLayoutChange?: (layout: string) => void;
  onLowGraphicsToggle?: (enabled: boolean) => void;
  onTextSizeChange?: (scale: number) => void;
  onHapticsToggle?: (enabled: boolean) => void;
  onWaveScorecardContinue(): void;
  onWaveScorecardSuggestedDrill?: (drill: WaveScorecardCoachDrill) => void;
  onLessonMedalReplay?: (options?: { mode?: TypingDrillMode; hint?: string }) => void;
  onReducedMotionToggle(enabled: boolean): void;
  onCheckeredBackgroundToggle(enabled: boolean): void;
  onAccessibilityPresetToggle?: (enabled: boolean) => void;
  onReadableFontToggle(enabled: boolean): void;
  onDyslexiaFontToggle(enabled: boolean): void;
  onDyslexiaSpacingToggle?: (enabled: boolean) => void;
  onLatencySparklineToggle?: (enabled: boolean) => void;
  onLargeSubtitlesToggle?: (enabled: boolean) => void;
  onTutorialSkip?: () => void;
  onTutorialStepReplay?: (stepId: string) => void;
  onTutorialPacingChange?: (value: number) => void;
  onCognitiveLoadToggle?: (enabled: boolean) => void;
  onAudioNarrationToggle?: (enabled: boolean) => void;
  onVoicePackChange?: (packId: string) => void;
  onColorblindPaletteToggle(enabled: boolean): void;
  onColorblindPaletteModeChange?: (mode: string) => void;
  onFocusOutlineChange?: (preset: FocusOutlinePreset) => void;
  onHotkeyPauseChange?: (key: string) => void;
  onHotkeyShortcutsChange?: (key: string) => void;
  onBackgroundBrightnessChange?: (value: number) => void;
  onDayNightThemeChange?: (mode: DayNightMode) => void;
  onParallaxSceneChange?: (scene: ParallaxScene) => void;
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
  titleText: HTMLSpanElement;
  hazardBadge: HTMLSpanElement;
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

type TutorialProgress = {
  index: number;
  total: number;
  label: string;
  stepId?: string;
  anchor?: "left" | "right";
};

type TutorialDockStep = {
  id: string;
  label: string;
  status: "done" | "active" | "pending";
};

type TutorialDockState = {
  active: boolean;
  steps: TutorialDockStep[];
  currentStepId?: string | null;
};

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
  progress?: HTMLButtonElement | null;
  close?: HTMLButtonElement | null;
  skip?: HTMLButtonElement | null;
};

type TutorialDockElements = {
  container: HTMLElement;
  toggle: HTMLButtonElement;
  steps: HTMLOListElement;
  summary?: HTMLElement | null;
};

type TutorialDockModalElements = {
  container: HTMLElement;
  title: HTMLElement;
  copy: HTMLElement;
  confirm: HTMLButtonElement;
  cancel: HTMLButtonElement;
};

type ShortcutOverlayElements = {
  container: string;
  closeButton: string;
  launchButton: string;
};

type ReadabilityOverlayElements = {
  container: string;
  closeButton: string;
  list: string;
  summary?: string;
};

type SfxOverlayElements = {
  container: string;
  closeButton: string;
  list: string;
  summary?: string;
};

type MusicOverlayElements = {
  container: string;
  closeButton: string;
  list: string;
  summary?: string;
};

type UiSoundOverlayElements = {
  container: string;
  closeButton: string;
  list: string;
  summary?: string;
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
  musicToggle?: string;
  musicLevelSlider?: string;
  musicLevelValue?: string;
  musicLibraryButton?: string;
  musicLibrarySummary?: string;
  uiSoundLibraryButton?: string;
  uiSoundLibrarySummary?: string;
  uiSoundPreviewButton?: string;
  screenShakeToggle?: string;
  screenShakeSlider?: string;
  screenShakeValue?: string;
  screenShakePreview?: string;
  screenShakeDemo?: string;
  contrastAuditButton?: string;
  sfxLibraryButton?: string;
  sfxLibrarySummary?: string;
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
  virtualKeyboardLayoutSelect?: string;
  lowGraphicsToggle: string;
  textSizeSelect?: string;
  hapticsToggle?: string;
  reducedMotionToggle: string;
  checkeredBackgroundToggle: string;
  accessibilityPresetToggle?: string;
  breakReminderIntervalSelect?: string;
  screenTimeGoalSelect?: string;
  screenTimeLockoutSelect?: string;
  screenTimeStatus?: string;
  screenTimeResetButton?: string;
  voicePackSelect?: string;
  latencySparklineToggle?: string;
  readableFontToggle: string;
  dyslexiaFontToggle: string;
  dyslexiaSpacingToggle?: string;
  cognitiveLoadToggle?: string;
  milestonePopupsToggle?: string;
  audioNarrationToggle?: string;
  tutorialPacingSlider?: string;
  tutorialPacingValue?: string;
  colorblindPaletteToggle: string;
  colorblindPaletteSelect?: string;
  focusOutlineSelect?: string;
  subtitleLargeToggle?: string;
  subtitlePreviewButton?: string;
  postureChecklistButton?: string;
  postureChecklistSummary?: string;
  hotkeyPauseSelect?: string;
  hotkeyShortcutsSelect?: string;
  backgroundBrightnessSlider?: string;
  backgroundBrightnessValue?: string;
  fontScaleSelect: string;
  hudZoomSelect: string;
  hudLayoutToggle?: string;
  layoutPreviewButton?: string;
  castleSkinSelect?: string;
  dayNightThemeSelect?: string;
  parallaxSceneSelect?: string;
  defeatAnimationSelect: string;
  stickerBookButton?: string;
  seasonTrackButton?: string;
  readabilityGuideButton?: string;
  lessonMedalButton?: string;
  wpmLadderButton?: string;
  biomeGalleryButton?: string;
  trainingCalendarButton?: string;
  museumButton?: string;
  sideQuestButton?: string;
  masteryCertificateButton?: string;
  loreScrollsButton?: string;
  parentSummaryButton?: string;
  endSessionButton?: string;
  telemetryToggle?: string;
  telemetryToggleWrapper?: string;
  telemetryQueueDownloadButton?: string;
  telemetryQueueClearButton?: string;
  crystalPulseToggle?: string;
  crystalPulseToggleWrapper?: string;
  eliteAffixToggle?: string;
  eliteAffixToggleWrapper?: string;
  analyticsExportButton?: string;
  sessionTimelineExportButton?: string;
  keystrokeTimingExportButton?: string;
  progressExportButton?: string;
  progressImportButton?: string;
};

type AnalyticsViewerElements = {
  container: string;
  tableBody: string;
  filterSelect?: string;
  drills?: string;
  tabButtons?: string[];
  panels?: {
    summary?: string;
    traces?: string;
    exports?: string;
  };
  traces?: string;
  exportMeta?: {
    waves?: string;
    drills?: string;
    breaches?: string;
    timeToFirstTurret?: string;
    note?: string;
  };
};

type AnalyticsViewerTab = "summary" | "traces" | "exports";

type WaveScorecardElements = {
  container: string;
  stats: string;
  continue: string;
  tip?: string;
  coach?: string;
  coachList?: string;
  drill?: string;
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

type DropoffOverlayElements = {
  container: string;
  closeButton: string;
  cancelButton?: string;
  skipButton?: string;
};

type SubtitleOverlayElements = {
  container: string;
  closeButton: string;
  toggle?: string;
  summary?: string;
  samples?: string;
};

type LayoutOverlayElements = {
  container: string;
  closeButton: string;
  summary?: string;
  leftCard: string;
  rightCard: string;
  leftApply: string;
  rightApply: string;
};

type ContrastOverlayElements = {
  container: string;
  list: string;
  summary: string;
  closeButton: string;
  markers: string;
};

type PostureOverlayElements = {
  container: string;
  list: string;
  summary?: string;
  status?: string;
  closeButton: string;
  startButton: string;
  reviewButton: string;
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
  filters?: string[];
  searchInput?: string;
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

type WpmLadderOverlayElements = {
  container: string;
  closeButton: string;
  list: string;
  subtitle?: string;
  meta?: string;
};

type BiomeOverlayElements = {
  container: string;
  closeButton: string;
  list: string;
  subtitle?: string;
  meta?: string;
};

type TrainingCalendarOverlayElements = {
  container: string;
  closeButton: string;
  grid: string;
  subtitle?: string;
  legend?: string;
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
  statLessons?: string;
  statAccuracy?: string;
  statWpm?: string;
  statCombo?: string;
  statDrills?: string;
  statTime?: string;
  details?: string;
  detailsToggle?: string;
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

export type WaveScorecardCoachDrill = {
  mode: TypingDrillMode;
  label: string;
  reason: string;
};

export type WaveScorecardCoachSummary = {
  win: string;
  gap: string;
  drill: WaveScorecardCoachDrill | null;
};

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
  coach?: WaveScorecardCoachSummary | null;
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
  private readonly healthBarShell: HTMLElement | null = null;
  private castleHealthFlashTimeout: number | null = null;
  private reducedMotionEnabled = false;
  private readonly hazardPulseTimeouts = new Map<string, number>();
  private readonly lastLaneHazardKinds = new Map<number, string>();
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
  private tutorialProgressKey: string | null = null;
  private tutorialHintDismissed = false;
  private lastTutorialMessage: string | null = null;
  private tutorialDock?: TutorialDockElements;
  private readonly tutorialDockStorageKey = "keyboard-defense:tutorial-dock-collapsed";
  private tutorialDockCollapsed = false;
  private tutorialDockStateKey: string | null = null;
  private tutorialDockLabels = new Map<string, string>();
  private tutorialDockModal?:
    | (TutorialDockModalElements & {
        stepId: string | null;
      })
    | undefined;
  private readonly virtualKeyboard?: VirtualKeyboard;
  private virtualKeyboardEnabled = false;
  private virtualKeyboardLayout = "qwerty";
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
    tabs?: Partial<Record<AnalyticsViewerTab, HTMLButtonElement>>;
    panels?: Partial<Record<AnalyticsViewerTab, HTMLElement>>;
    traces?: HTMLElement;
    exportMeta?: {
      waves?: HTMLElement;
      drills?: HTMLElement;
      breaches?: HTMLElement;
      ttf?: HTMLElement;
      note?: HTMLElement;
    };
  };
  private analyticsViewerVisible = false;
  private analyticsViewerSignature = "";
  private analyticsViewerFilter: AnalyticsViewerFilter = "all";
  private analyticsViewerTab: AnalyticsViewerTab = "summary";
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
  private readonly dropoffOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    cancelButton?: HTMLButtonElement;
    skipButton?: HTMLButtonElement;
    reasonButtons: HTMLButtonElement[];
  };
  private readonly layoutOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    summary?: HTMLElement;
    leftCard: HTMLElement;
    rightCard: HTMLElement;
    leftApply: HTMLButtonElement;
    rightApply: HTMLButtonElement;
  };
  private readonly contrastOverlay?: {
    container: HTMLElement;
    list: HTMLUListElement;
    summary: HTMLElement;
    closeButton: HTMLButtonElement;
    markers: HTMLElement;
  };
  private readonly musicOverlay?: {
    container: HTMLElement;
    list: HTMLElement;
    summary?: HTMLElement;
    closeButton: HTMLButtonElement;
  };
  private readonly uiSoundOverlay?: {
    container: HTMLElement;
    list: HTMLElement;
    summary?: HTMLElement;
    closeButton: HTMLButtonElement;
  };
  private readonly sfxOverlay?: {
    container: HTMLElement;
    list: HTMLElement;
    summary?: HTMLElement;
    closeButton: HTMLButtonElement;
  };
  private readonly readabilityOverlay?: {
    container: HTMLElement;
    list: HTMLElement;
    summary?: HTMLElement;
    closeButton: HTMLButtonElement;
  };
  private readonly subtitleOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    toggle?: HTMLInputElement;
    summary?: HTMLElement;
    samples?: HTMLElement[];
  };
  private readonly postureOverlay?: {
    container: HTMLElement;
    list: HTMLElement;
    summary?: HTMLElement;
    status?: HTMLElement;
    closeButton: HTMLButtonElement;
    startButton: HTMLButtonElement;
    reviewButton: HTMLButtonElement;
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
    filters?: HTMLButtonElement[];
    searchInput?: HTMLInputElement;
  };
  private loreScrollFilter: "all" | "unlocked" | "locked" = "all";
  private loreScrollSearch = "";
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
    path?: HTMLElement;
    best?: HTMLElement;
    next?: HTMLElement;
    openButton?: HTMLButtonElement;
  };
  private lessonMedalState?: LessonMedalViewState;
  private lessonPathState?: LessonPathViewState;
  private lessonMedalHighlightTimeout: number | null = null;
  private readonly wpmLadderPanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    stats?: HTMLElement;
    top?: HTMLElement;
    openButton?: HTMLButtonElement;
  };
  private readonly wpmLadderOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    list: HTMLElement;
    subtitle?: HTMLElement;
    meta?: HTMLElement;
  };
  private wpmLadderState?: WpmLadderViewState;
  private sfxLibraryState?: SfxLibraryViewState;
  private uiSoundSchemeState?: UiSchemeViewState;
  private musicStemState?: MusicStemViewState;
  private wpmLadderHighlightTimeout: number | null = null;
  private readonly biomePanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    stats?: HTMLElement;
    openButton?: HTMLButtonElement;
  };
  private readonly biomeOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    list: HTMLElement;
    subtitle?: HTMLElement;
    meta?: HTMLElement;
  };
  private biomeState?: BiomeGalleryViewState;
  private biomeHighlightTimeout: number | null = null;
  private readonly trainingCalendarPanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    stats?: HTMLElement;
    openButton?: HTMLButtonElement;
  };
  private readonly trainingCalendarOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    grid: HTMLElement;
    subtitle?: HTMLElement;
    legend?: HTMLElement;
  };
  private trainingCalendarState?: TrainingCalendarViewState;
  private readonly streakTokenPanel?: {
    container?: HTMLElement;
    count?: HTMLElement;
    status?: HTMLElement;
  };
  private streakTokens: { tokens: number; streak: number; lastAwarded: string | null } = {
    tokens: 0,
    streak: 0,
    lastAwarded: null
  };
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
    statLessons?: HTMLElement;
    statAccuracy?: HTMLElement;
    statWpm?: HTMLElement;
    statCombo?: HTMLElement;
    statDrills?: HTMLElement;
    statTime?: HTMLElement;
    details?: HTMLElement;
    detailsToggle?: HTMLButtonElement;
  };
  private readonly sideQuestPanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    stats?: HTMLElement;
    openButton?: HTMLButtonElement;
  };
  private dailyQuestBoardState?: DailyQuestBoardViewState;
  private readonly dailyQuestPanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    list?: HTMLElement;
  };
  private weeklyQuestBoardState?: WeeklyQuestBoardViewState;
  private readonly weeklyQuestPanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    list?: HTMLElement;
    trialButton?: HTMLButtonElement;
  };
  private sessionGoalsState?: SessionGoalsViewState;
  private readonly sessionGoalsPanel?: {
    container?: HTMLElement;
    summary?: HTMLElement;
    list?: HTMLElement;
  };
  private readonly sideQuestOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    list: HTMLElement;
    subtitle?: HTMLElement;
    filters?: HTMLButtonElement[];
  };
  private sideQuestFilter: "all" | "active" | "completed" = "all";
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
    filters?: HTMLButtonElement[];
  };
  private museumFilter: "all" | "unlocked" | "locked" = "all";
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
  private certificateDetailsCollapsed = true;
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
  private lastMilestoneKey: string | null = null;
  private lastMilestoneAt = 0;
  private milestoneCelebrationsDisabled = false;
  private lastLessonMedalCelebratedId: string | null = null;
  private lastLessonMilestoneCelebrated = 0;
  private lessonMilestoneTrackingInitialized = false;
  private lastCertificateCelebratedAt: string | null = null;
  private masteryCertificateMilestoneShown = false;
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
  private dropoffOverlayTrigger?: HTMLElement | null;
  private lastShieldTelemetry = { current: false, next: false };
  private lastAffixTelemetry = { current: false, next: false };
  private lastWavePreviewEntries: WaveSpawnPreview[] = [];
  private lastWavePreviewColorBlind = false;
  private lastWavePreviewLaneHazards: LaneHazardState[] = [];
  private lastWavePreviewEmptyMessage: string | null = null;
  private wavePreviewFreezeUntil = 0;
  private pendingWavePreviewState: WavePreviewSnapshot | null = null;
  private wavePreviewThreatIndicatorsEnabled = false;
  private lastGold = 0;
  private maxCombo = 0;
  private goldTimeout: number | null = null;
  private typingAccuracyLabel: HTMLElement | null = null;
  private typingWpmLabel: HTMLElement | null = null;
  private readonly logEntries: BattleLogEntry[] = [];
  private readonly logSummary = createBattleLogSummaryState();
  private readonly logSummaryItems = new Map<BattleLogFilterCategory, BattleLogSummaryItem>();
  private readonly logFilterButtons = new Map<BattleLogFilterCategory, HTMLButtonElement>();
  private logFilterState = new Set<BattleLogFilterCategory>();
  private logFilterClearButton?: HTMLButtonElement;
  private typingErrorHint:
    | { expected: string | null; received: string | null; enemyId: string | null; timestamp: number }
    | null = null;
  private readonly logLimit = 6;
  private tutorialSlotLock: TutorialSlotLock | null = null;
  private passiveHighlightId: string | null = null;
  private lastState: GameState | null = null;
  private lastGameStatus: GameStatus | null = null;
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
  private sfxActiveLabel?: HTMLElement;
  private uiSoundActiveLabel?: HTMLElement;
  private musicActiveLabel?: HTMLElement;
  private postureReminder?:
    | {
        container: HTMLElement;
        tip: HTMLElement;
        dismiss: HTMLButtonElement;
      }
    | undefined;
  private postureReminderTimeout: number | null = null;
  private postureReminderInterval: number | null = null;
  private postureReminderTarget: number | null = null;
  private postureLastReviewed: number | null = null;
  private audioNarrationEnabled = false;
  private accessibilityPresetEnabled = false;
  private narration = new NarrationManager();
  private subtitleLargeEnabled = false;
  private focusOutlinePreset: FocusOutlinePreset = "system";
  private dayNightTheme: DayNightMode = "night";
  private parallaxSceneChoice: ParallaxScene = "auto";
  private parallaxSceneResolved: ResolvedParallaxScene = "night";
  private parallaxShell: HTMLElement | null = null;
  private parallaxPaused = false;
  private wavePreviewHint?: HTMLElement;
  private wavePreviewHintMessage = DEFAULT_WAVE_PREVIEW_HINT;
  private wavePreviewHintPinned = false;
  private wavePreviewHintTimeout: ReturnType<typeof setTimeout> | null = null;
  private tutorialPacing = 1;
  private readonly optionsOverlay?: {
    container: HTMLElement;
    closeButton: HTMLButtonElement;
    resumeButton: HTMLButtonElement;
    soundToggle: HTMLInputElement;
    soundVolumeSlider: HTMLInputElement;
    soundVolumeValue: HTMLElement;
    soundIntensitySlider: HTMLInputElement;
    soundIntensityValue: HTMLElement;
    musicToggle?: HTMLInputElement;
    musicLevelSlider?: HTMLInputElement;
    musicLevelValue?: HTMLElement;
    musicLibraryButton?: HTMLButtonElement;
    musicLibrarySummary?: HTMLElement;
    uiSoundLibraryButton?: HTMLButtonElement;
    uiSoundLibrarySummary?: HTMLElement;
    uiSoundPreviewButton?: HTMLButtonElement;
    screenShakeToggle?: HTMLInputElement;
    screenShakeSlider?: HTMLInputElement;
    screenShakeValue?: HTMLElement;
    screenShakePreview?: HTMLButtonElement;
    screenShakeDemo?: HTMLElement;
    contrastAuditButton?: HTMLButtonElement;
    sfxLibraryButton?: HTMLButtonElement;
    sfxLibrarySummary?: HTMLElement;
    stickerBookButton?: HTMLButtonElement;
    seasonTrackButton?: HTMLButtonElement;
    readabilityGuideButton?: HTMLButtonElement;
    museumButton?: HTMLButtonElement;
    sideQuestButton?: HTMLButtonElement;
    lessonMedalButton?: HTMLButtonElement;
    wpmLadderButton?: HTMLButtonElement;
    biomeGalleryButton?: HTMLButtonElement;
    trainingCalendarButton?: HTMLButtonElement;
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
    virtualKeyboardLayoutSelect?: HTMLSelectElement;
    lowGraphicsToggle?: HTMLInputElement;
    textSizeSelect?: HTMLSelectElement;
    hapticsToggle?: HTMLInputElement;
    reducedMotionToggle: HTMLInputElement;
    checkeredBackgroundToggle: HTMLInputElement;
    accessibilityPresetToggle?: HTMLInputElement;
    breakReminderIntervalSelect?: HTMLSelectElement;
    screenTimeGoalSelect?: HTMLSelectElement;
    screenTimeLockoutSelect?: HTMLSelectElement;
    screenTimeStatus?: HTMLElement;
    screenTimeResetButton?: HTMLButtonElement;
    voicePackSelect?: HTMLSelectElement;
    latencySparklineToggle?: HTMLInputElement;
    readableFontToggle: HTMLInputElement;
    dyslexiaFontToggle: HTMLInputElement;
    dyslexiaSpacingToggle?: HTMLInputElement;
    cognitiveLoadToggle?: HTMLInputElement;
    milestonePopupsToggle?: HTMLInputElement;
    audioNarrationToggle?: HTMLInputElement;
    tutorialPacingSlider?: HTMLInputElement;
    tutorialPacingValue?: HTMLElement;
    colorblindPaletteToggle: HTMLInputElement;
    colorblindPaletteSelect?: HTMLSelectElement;
    focusOutlineSelect?: HTMLSelectElement;
    subtitleLargeToggle?: HTMLInputElement;
    subtitlePreviewButton?: HTMLButtonElement;
    postureChecklistButton?: HTMLButtonElement;
    postureChecklistSummary?: HTMLElement;
    hotkeyPauseSelect?: HTMLSelectElement;
    hotkeyShortcutsSelect?: HTMLSelectElement;
    backgroundBrightnessSlider?: HTMLInputElement;
    backgroundBrightnessValue?: HTMLElement;
    hudZoomSelect: HTMLSelectElement;
    hudLayoutToggle?: HTMLInputElement;
    layoutPreviewButton?: HTMLButtonElement;
    castleSkinSelect?: HTMLSelectElement;
    dayNightThemeSelect?: HTMLSelectElement;
    parallaxSceneSelect?: HTMLSelectElement;
    fontScaleSelect: HTMLSelectElement;
    defeatAnimationSelect: HTMLSelectElement;
    telemetryToggle?: HTMLInputElement;
    telemetryWrapper?: HTMLElement;
    telemetryQueueDownloadButton?: HTMLButtonElement;
    telemetryQueueClearButton?: HTMLButtonElement;
    crystalPulseToggle?: HTMLInputElement;
    crystalPulseWrapper?: HTMLElement;
    eliteAffixToggle?: HTMLInputElement;
    eliteAffixWrapper?: HTMLElement;
    analyticsExportButton?: HTMLButtonElement;
    sessionTimelineExportButton?: HTMLButtonElement;
    keystrokeTimingExportButton?: HTMLButtonElement;
    progressExportButton?: HTMLButtonElement;
    progressImportButton?: HTMLButtonElement;
    parentSummaryButton?: HTMLButtonElement;
    endSessionButton?: HTMLButtonElement;
    panelContainer?: HTMLElement;
    panels?: HTMLElement[];
    mainColumn?: HTMLElement;
    navButtons?: HTMLButtonElement[];
  };
  private readonly waveScorecard?: {
    container: HTMLElement;
    statsList: HTMLUListElement;
    continueBtn: HTMLButtonElement;
    tip?: HTMLElement;
    coach?: HTMLElement;
    coachList?: HTMLUListElement;
    drillBtn?: HTMLButtonElement;
    suggestedDrill?: WaveScorecardCoachDrill | null;
  };
  private syncingOptionToggles = false;
  private comboBaselineAccuracy = 1;
  private lastAccuracy = 1;
  private hudRoot: HTMLElement | null = null;
  private hudLayoutSide: "left" | "right" = "right";
  private setHudDockPane: ((paneId: string) => void) | null = null;
  private setBuildDrawerOpen: ((open: boolean) => void) | null = null;
  private buildDrawer: HTMLElement | null = null;
  private buildDrawerToggle: HTMLButtonElement | null = null;
  private buildCommandInput: HTMLInputElement | null = null;
  private buildCommandStatus: HTMLElement | null = null;
  private buildCommandStatusTimeout: ReturnType<typeof setTimeout> | null = null;
  private evacBanner?:
    | {
        container: HTMLElement;
        title: HTMLElement;
        timer: HTMLElement;
        progress: HTMLElement;
        status: HTMLElement;
      }
    | undefined;
  private supportBoostBanner?:
    | {
        container: HTMLElement;
        label: HTMLElement;
        timer: HTMLElement;
      }
    | undefined;
  private fieldDrillBanner?:
    | {
        container: HTMLElement;
        title: HTMLElement;
        progress: HTMLElement;
        hint: HTMLElement;
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
      eventLogSummary?: string;
      eventLogFilters?: string;
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
      tutorialDock?: {
        container: string;
        toggle: string;
        steps: string;
        summary?: string;
        modal?: {
          container: string;
          title: string;
          copy: string;
          confirm: string;
          cancel: string;
        };
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
      dropoffOverlay?: DropoffOverlayElements;
      subtitleOverlay?: SubtitleOverlayElements;
      layoutOverlay?: LayoutOverlayElements;
      contrastOverlay?: ContrastOverlayElements;
      postureOverlay?: PostureOverlayElements;
      musicOverlay?: MusicOverlayElements;
      uiSoundOverlay?: UiSoundOverlayElements;
      sfxOverlay?: SfxOverlayElements;
      readabilityOverlay?: ReadabilityOverlayElements;
      stickerBookOverlay?: StickerBookOverlayElements;
      seasonTrackOverlay?: SeasonTrackOverlayElements;
      museumOverlay?: MuseumOverlayElements;
      sideQuestOverlay?: SideQuestOverlayElements;
      lessonMedalOverlay?: LessonMedalOverlayElements;
      wpmLadderOverlay?: WpmLadderOverlayElements;
      biomeOverlay?: BiomeOverlayElements;
      trainingCalendarOverlay?: TrainingCalendarOverlayElements;
      masteryCertificateOverlay?: MasteryCertificateElements;
      loreScrollOverlay?: LoreScrollOverlayElements;
      parentSummaryOverlay?: ParentSummaryOverlayElements;
    },
    private readonly callbacks: HudCallbacks
  ) {
    this.certificateName = this.readCertificateName();
    this.masteryCertificateMilestoneShown = this.readMasteryCertificateMilestoneShown();
    this.milestoneCelebrationsDisabled = this.readMilestoneCelebrationsDisabled();
    this.hudRoot = document.getElementById("hud");
    this.parallaxShell = document.getElementById("parallax-shell");
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

      const supportBanner = document.createElement("div");
      supportBanner.className = "support-boost-banner";
      supportBanner.dataset.visible = "false";
      supportBanner.style.display = "none";
      supportBanner.style.background = "rgba(15, 23, 42, 0.9)";
      supportBanner.style.color = "#e0f2fe";
      supportBanner.style.border = "1px solid rgba(56, 189, 248, 0.65)";
      supportBanner.style.borderRadius = "999px";
      supportBanner.style.padding = "6px 10px";
      supportBanner.style.gap = "10px";
      supportBanner.style.alignItems = "center";
      supportBanner.style.justifyContent = "space-between";
      supportBanner.style.boxShadow = "0 6px 14px rgba(0,0,0,0.2)";
      supportBanner.style.fontSize = "12px";
      supportBanner.style.fontVariantNumeric = "tabular-nums";
      supportBanner.style.lineHeight = "1.2";
      supportBanner.style.flexWrap = "wrap";
      supportBanner.style.position = "sticky";
      supportBanner.style.top = "6px";
      supportBanner.style.zIndex = "6";
      supportBanner.style.pointerEvents = "none";

      const supportLabel = document.createElement("div");
      supportLabel.style.fontWeight = "650";
      const supportTimer = document.createElement("div");
      supportTimer.style.opacity = "0.85";
      supportTimer.setAttribute("aria-hidden", "true");

      supportBanner.appendChild(supportLabel);
      supportBanner.appendChild(supportTimer);

      banner.after(supportBanner);
      this.supportBoostBanner = { container: supportBanner, label: supportLabel, timer: supportTimer };

      const drillBanner = document.createElement("div");
      drillBanner.className = "field-drill-banner";
      drillBanner.dataset.visible = "false";
      drillBanner.setAttribute("role", "status");
      drillBanner.setAttribute("aria-live", "polite");
      drillBanner.style.display = "none";
      drillBanner.style.background = "linear-gradient(90deg, rgba(15, 23, 42, 0.94), rgba(14, 116, 144, 0.5))";
      drillBanner.style.color = "#e2e8f0";
      drillBanner.style.border = "1px solid rgba(14, 165, 233, 0.65)";
      drillBanner.style.borderRadius = "10px";
      drillBanner.style.padding = "8px 10px";
      drillBanner.style.gap = "4px";
      drillBanner.style.display = "none";
      drillBanner.style.flexDirection = "column";
      drillBanner.style.boxShadow = "0 6px 12px rgba(0,0,0,0.2)";
      drillBanner.style.fontSize = "12px";
      drillBanner.style.lineHeight = "1.3";
      drillBanner.style.position = "sticky";
      drillBanner.style.top = "38px";
      drillBanner.style.zIndex = "5";
      drillBanner.style.pointerEvents = "none";

      const drillTitle = document.createElement("div");
      drillTitle.style.fontWeight = "650";
      const drillProgress = document.createElement("div");
      drillProgress.style.fontVariantNumeric = "tabular-nums";
      const drillHint = document.createElement("div");
      drillHint.style.opacity = "0.75";

      drillBanner.appendChild(drillTitle);
      drillBanner.appendChild(drillProgress);
      drillBanner.appendChild(drillHint);

      supportBanner.after(drillBanner);
      this.fieldDrillBanner = {
        container: drillBanner,
        title: drillTitle,
        progress: drillProgress,
        hint: drillHint
      };
    }

    this.healthBar = this.getElement(rootIds.healthBar);
    this.healthBarShell =
      this.healthBar.parentElement instanceof HTMLElement ? this.healthBar.parentElement : null;
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
    const buildDrawer = document.getElementById("build-drawer");
    const buildContent = document.getElementById("build-content");
    const buildToggle = document.getElementById("build-drawer-toggle");
    let openBuildDrawer: ((open: boolean) => void) | null = null;
    let buildDrawerOpenedOnce = false;
    if (
      buildDrawer instanceof HTMLElement &&
      buildContent instanceof HTMLElement &&
      buildToggle instanceof HTMLButtonElement
    ) {
      this.buildDrawer = buildDrawer;
      this.buildDrawerToggle = buildToggle;

      if (!document.getElementById("build-command-input")) {
        const commandPanel = document.createElement("div");
        commandPanel.className = "build-command-panel";
        commandPanel.setAttribute("role", "group");
        commandPanel.setAttribute("aria-label", "Build command line");

        const commandLabel = document.createElement("label");
        commandLabel.className = "build-command-label";
        commandLabel.textContent = "Command line";
        commandLabel.setAttribute("for", "build-command-input");

        const commandInput = document.createElement("input");
        commandInput.id = "build-command-input";
        commandInput.className = "build-command-input";
        commandInput.type = "text";
        commandInput.autocomplete = "off";
        commandInput.autocapitalize = "off";
        commandInput.spellcheck = false;
        commandInput.placeholder = 'Try: "s0 arrow", "s0 upgrade", "castle repair"';

        const commandHelp = document.createElement("div");
        commandHelp.className = "build-command-help";
        commandHelp.textContent = 'Enter: run command. Tab/Esc: close menu. Type "help" for examples.';

        const commandStatus = document.createElement("div");
        commandStatus.className = "build-command-status";
        commandStatus.setAttribute("role", "status");
        commandStatus.setAttribute("aria-live", "polite");
        commandStatus.textContent = "";

        commandPanel.append(commandLabel, commandInput, commandHelp, commandStatus);
        buildContent.prepend(commandPanel);

        this.buildCommandInput = commandInput;
        this.buildCommandStatus = commandStatus;

        commandInput.addEventListener("keydown", (event) => {
          if (event.key === "Enter") {
            event.preventDefault();
            const raw = commandInput.value;
            commandInput.value = "";
            this.executeBuildCommand(raw);
            commandInput.focus();
            return;
          }
          if (event.key === "Escape" || event.key === "Tab") {
            event.preventDefault();
            this.toggleBuildMenu(false);
          }
        });
      } else {
        const existing = document.getElementById("build-command-input");
        this.buildCommandInput = existing instanceof HTMLInputElement ? existing : null;
      }

      const setOpen = (open: boolean) => {
        const wasOpen = buildDrawer.dataset.open === "true";
        buildDrawer.dataset.open = open ? "true" : "false";
        buildContent.setAttribute("aria-hidden", open ? "false" : "true");
        buildContent.hidden = !open;
        buildToggle.setAttribute("aria-expanded", open ? "true" : "false");
        buildToggle.textContent = open ? "Close build menu" : "Open build menu";
        if (open) {
          buildDrawerOpenedOnce = true;
        }
        if (open !== wasOpen) {
          this.callbacks.onBuildMenuToggle?.(open);
        }
        if (open) {
          this.buildCommandInput?.focus?.();
        } else {
          this.focusTypingInput();
        }
      };
      openBuildDrawer = setOpen;
      this.setBuildDrawerOpen = setOpen;
      setOpen(false);
      buildToggle.addEventListener("click", () => {
        this.hideMilestoneCelebration();
        setOpen(buildDrawer.dataset.open !== "true");
      });
    }
    const hudDockTabs = Array.from(
      document.querySelectorAll<HTMLButtonElement>("#hud-dock-tabs .hud-dock-tab")
    );
    const hudPanes = Array.from(document.querySelectorAll<HTMLElement>(".hud-pane"));
    if (hudDockTabs.length > 0 && hudPanes.length > 0) {
      const setActivePane = (paneId: string) => {
        hudDockTabs.forEach((tab) => {
          const active = tab.dataset.paneTarget === paneId;
          tab.setAttribute("aria-selected", active ? "true" : "false");
          tab.setAttribute("tabindex", active ? "0" : "-1");
        });
        hudPanes.forEach((pane) => {
          const active = pane.dataset.pane === paneId;
          pane.hidden = !active;
          pane.setAttribute("aria-hidden", active ? "false" : "true");
        });
        if (paneId === "build" && openBuildDrawer && !buildDrawerOpenedOnce) {
          openBuildDrawer(true);
        }
      };
      this.setHudDockPane = setActivePane;
      setActivePane("build");
      hudDockTabs.forEach((tab) => {
        tab.addEventListener("click", () => {
          if (!tab.dataset.paneTarget) return;
          setActivePane(tab.dataset.paneTarget);
        });
        tab.addEventListener("keydown", (event) => {
          if (event.key !== "ArrowRight" && event.key !== "ArrowLeft") {
            return;
          }
          const currentIndex = hudDockTabs.indexOf(tab);
          const delta = event.key === "ArrowRight" ? 1 : -1;
          const nextIndex = (currentIndex + delta + hudDockTabs.length) % hudDockTabs.length;
          const nextTab = hudDockTabs[nextIndex];
          nextTab?.focus();
          if (nextTab?.dataset.paneTarget) {
            setActivePane(nextTab.dataset.paneTarget);
          }
        });
      });
    }
    this.comboLabel = this.getElement(rootIds.comboLabel);
    this.comboAccuracyDelta = this.getElement(rootIds.comboAccuracyDelta);
    this.hideComboAccuracyDelta();
    this.logList = this.getElement(rootIds.eventLog) as HTMLUListElement;
    this.initializeBattleLogControls(rootIds);
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
      const progressElement = tutorialBannerElement.querySelector<HTMLButtonElement>(
        "[data-role='tutorial-progress']"
      );
      const closeElement = tutorialBannerElement.querySelector<HTMLButtonElement>(
        "[data-role='tutorial-close']"
      );
      const skipElement = tutorialBannerElement.querySelector<HTMLButtonElement>(
        "[data-role='tutorial-skip']"
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
      if (progressElement) {
        progressElement.addEventListener("click", () => {
          if (toggleElement && !toggleElement.hidden) {
            toggleElement.focus();
          } else {
            tutorialBannerElement.focus();
          }
        });
      }
      if (closeElement) {
        closeElement.addEventListener("click", () => this.dismissTutorialHint());
      }
      if (skipElement) {
        skipElement.addEventListener("click", () => this.callbacks.onTutorialSkip?.());
      }
      this.tutorialBanner = {
        container: tutorialBannerElement,
        message: messageElement,
        toggle: toggleElement ?? undefined,
        progress: progressElement ?? undefined,
        close: closeElement ?? undefined,
        skip: skipElement ?? undefined
      };
    } else {
      this.tutorialBanner = undefined;
    }
    if (rootIds.tutorialDock) {
      const dockContainer = document.getElementById(rootIds.tutorialDock.container);
      const dockToggle = document.getElementById(rootIds.tutorialDock.toggle);
      const dockSteps = document.getElementById(rootIds.tutorialDock.steps);
      const dockSummary = rootIds.tutorialDock.summary
        ? document.getElementById(rootIds.tutorialDock.summary)
        : null;
      if (
        dockContainer instanceof HTMLElement &&
        dockToggle instanceof HTMLButtonElement &&
        dockSteps instanceof HTMLElement
      ) {
        this.tutorialDockCollapsed = this.readTutorialDockCollapsed();
        dockToggle.addEventListener("click", () => {
          this.tutorialDockCollapsed = !this.tutorialDockCollapsed;
          this.persistTutorialDockCollapsed();
          this.refreshTutorialDockLayout();
        });
        dockSteps.addEventListener("click", (event) => {
          const target = event.target as HTMLElement | null;
          const button = target?.closest<HTMLButtonElement>("button[data-step-id]");
          const stepId = button?.dataset.stepId ?? null;
          if (stepId) {
            this.showTutorialDockModal(stepId);
          }
        });
        this.tutorialDock = {
          container: dockContainer,
          toggle: dockToggle,
          steps: dockSteps as HTMLOListElement,
          summary: dockSummary
        };
      }
    }
    if (rootIds.tutorialDock?.modal) {
      const modalContainer = document.getElementById(rootIds.tutorialDock.modal.container);
      const modalTitle = document.getElementById(rootIds.tutorialDock.modal.title);
      const modalCopy = document.getElementById(rootIds.tutorialDock.modal.copy);
      const modalConfirm = document.getElementById(rootIds.tutorialDock.modal.confirm);
      const modalCancel = document.getElementById(rootIds.tutorialDock.modal.cancel);
      if (
        modalContainer instanceof HTMLElement &&
        modalTitle instanceof HTMLElement &&
        modalCopy instanceof HTMLElement &&
        modalConfirm instanceof HTMLButtonElement &&
        modalCancel instanceof HTMLButtonElement
      ) {
        this.tutorialDockModal = {
          container: modalContainer,
          title: modalTitle,
          copy: modalCopy,
          confirm: modalConfirm,
          cancel: modalCancel,
          stepId: null
        };
        this.addFocusTrap(modalContainer);
        modalConfirm.addEventListener("click", () => this.confirmTutorialDockModal());
        modalCancel.addEventListener("click", () => this.hideTutorialDockModal());
        modalContainer.addEventListener("keydown", (event) => {
          if (event.key === "Escape") {
            event.preventDefault();
            this.hideTutorialDockModal();
          }
        });
      }
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
      const optionsNav = document.getElementById("options-quick-nav");
      const navButtons = optionsNav
        ? Array.from(
            optionsNav.querySelectorAll<HTMLButtonElement>("button[data-target]")
          ).filter((btn): btn is HTMLButtonElement => btn instanceof HTMLButtonElement)
        : [];
      const optionsMainColumn = optionsContainer?.querySelector<HTMLElement>(".options-main-column");
      const optionsPanelContainer = optionsContainer?.querySelector<HTMLElement>("#options-panels");
      const optionPanels = optionsPanelContainer
        ? Array.from(optionsPanelContainer.querySelectorAll<HTMLElement>(".options-panel"))
        : [];
      const soundToggle = document.getElementById(rootIds.optionsOverlay.soundToggle);
      const soundVolumeSlider = document.getElementById(rootIds.optionsOverlay.soundVolumeSlider);
      const soundVolumeValue = document.getElementById(rootIds.optionsOverlay.soundVolumeValue);
      const soundIntensitySlider = document.getElementById(
        rootIds.optionsOverlay.soundIntensitySlider
      );
      const soundIntensityValue = document.getElementById(
        rootIds.optionsOverlay.soundIntensityValue
      );
      const musicToggle = rootIds.optionsOverlay.musicToggle
        ? document.getElementById(rootIds.optionsOverlay.musicToggle)
        : null;
      const musicLevelSlider = rootIds.optionsOverlay.musicLevelSlider
        ? document.getElementById(rootIds.optionsOverlay.musicLevelSlider)
        : null;
      const musicLevelValue = rootIds.optionsOverlay.musicLevelValue
        ? document.getElementById(rootIds.optionsOverlay.musicLevelValue)
        : null;
      const musicLibraryButton = rootIds.optionsOverlay.musicLibraryButton
        ? document.getElementById(rootIds.optionsOverlay.musicLibraryButton)
        : null;
      const musicLibrarySummary = rootIds.optionsOverlay.musicLibrarySummary
        ? document.getElementById(rootIds.optionsOverlay.musicLibrarySummary)
        : null;
      const uiSoundLibraryButton = rootIds.optionsOverlay.uiSoundLibraryButton
        ? document.getElementById(rootIds.optionsOverlay.uiSoundLibraryButton)
        : null;
      const uiSoundLibrarySummary = rootIds.optionsOverlay.uiSoundLibrarySummary
        ? document.getElementById(rootIds.optionsOverlay.uiSoundLibrarySummary)
        : null;
      const uiSoundPreviewButton = rootIds.optionsOverlay.uiSoundPreviewButton
        ? document.getElementById(rootIds.optionsOverlay.uiSoundPreviewButton)
        : null;
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
      const sfxLibraryButton = rootIds.optionsOverlay.sfxLibraryButton
        ? document.getElementById(rootIds.optionsOverlay.sfxLibraryButton)
        : null;
      const sfxLibrarySummary = rootIds.optionsOverlay.sfxLibrarySummary
        ? document.getElementById(rootIds.optionsOverlay.sfxLibrarySummary)
        : null;
      const stickerBookButton = rootIds.optionsOverlay.stickerBookButton
        ? document.getElementById(rootIds.optionsOverlay.stickerBookButton)
        : null;
      const seasonTrackButton = rootIds.optionsOverlay.seasonTrackButton
        ? document.getElementById(rootIds.optionsOverlay.seasonTrackButton)
        : null;
      const readabilityGuideButton = rootIds.optionsOverlay.readabilityGuideButton
        ? document.getElementById(rootIds.optionsOverlay.readabilityGuideButton)
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
      const wpmLadderButton = rootIds.optionsOverlay.wpmLadderButton
        ? document.getElementById(rootIds.optionsOverlay.wpmLadderButton)
        : null;
      const biomeGalleryButton = rootIds.optionsOverlay.biomeGalleryButton
        ? document.getElementById(rootIds.optionsOverlay.biomeGalleryButton)
        : null;
      const trainingCalendarButton = rootIds.optionsOverlay.trainingCalendarButton
        ? document.getElementById(rootIds.optionsOverlay.trainingCalendarButton)
        : null;
      const postureChecklistButton = rootIds.optionsOverlay.postureChecklistButton
        ? document.getElementById(rootIds.optionsOverlay.postureChecklistButton)
        : null;
      const postureChecklistSummary = rootIds.optionsOverlay.postureChecklistSummary
        ? document.getElementById(rootIds.optionsOverlay.postureChecklistSummary)
        : null;
      const loreScrollsButton = rootIds.optionsOverlay.loreScrollsButton
        ? document.getElementById(rootIds.optionsOverlay.loreScrollsButton)
        : null;
      const parentSummaryButton = rootIds.optionsOverlay.parentSummaryButton
        ? document.getElementById(rootIds.optionsOverlay.parentSummaryButton)
        : null;
      const endSessionButton = rootIds.optionsOverlay.endSessionButton
        ? document.getElementById(rootIds.optionsOverlay.endSessionButton)
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
      const virtualKeyboardLayoutSelect = rootIds.optionsOverlay.virtualKeyboardLayoutSelect
        ? document.getElementById(rootIds.optionsOverlay.virtualKeyboardLayoutSelect)
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
      const accessibilityPresetToggle = rootIds.optionsOverlay.accessibilityPresetToggle
        ? document.getElementById(rootIds.optionsOverlay.accessibilityPresetToggle)
        : null;
      const breakReminderIntervalSelect = rootIds.optionsOverlay.breakReminderIntervalSelect
        ? document.getElementById(rootIds.optionsOverlay.breakReminderIntervalSelect)
        : null;
      const screenTimeGoalSelect = rootIds.optionsOverlay.screenTimeGoalSelect
        ? document.getElementById(rootIds.optionsOverlay.screenTimeGoalSelect)
        : null;
      const screenTimeLockoutSelect = rootIds.optionsOverlay.screenTimeLockoutSelect
        ? document.getElementById(rootIds.optionsOverlay.screenTimeLockoutSelect)
        : null;
      const screenTimeStatus = rootIds.optionsOverlay.screenTimeStatus
        ? document.getElementById(rootIds.optionsOverlay.screenTimeStatus)
        : null;
      const screenTimeResetButton = rootIds.optionsOverlay.screenTimeResetButton
        ? document.getElementById(rootIds.optionsOverlay.screenTimeResetButton)
        : null;
      const voicePackSelect = rootIds.optionsOverlay.voicePackSelect
        ? document.getElementById(rootIds.optionsOverlay.voicePackSelect)
        : null;
      const readableFontToggle = document.getElementById(rootIds.optionsOverlay.readableFontToggle);
      const dyslexiaFontToggle = document.getElementById(rootIds.optionsOverlay.dyslexiaFontToggle);
      const dyslexiaSpacingToggle = rootIds.optionsOverlay.dyslexiaSpacingToggle
        ? document.getElementById(rootIds.optionsOverlay.dyslexiaSpacingToggle)
        : null;
      const latencySparklineToggle = rootIds.optionsOverlay.latencySparklineToggle
        ? document.getElementById(rootIds.optionsOverlay.latencySparklineToggle)
        : null;
      const cognitiveLoadToggle = rootIds.optionsOverlay.cognitiveLoadToggle
        ? document.getElementById(rootIds.optionsOverlay.cognitiveLoadToggle)
        : null;
      const milestonePopupsToggle = rootIds.optionsOverlay.milestonePopupsToggle
        ? document.getElementById(rootIds.optionsOverlay.milestonePopupsToggle)
        : null;
      const audioNarrationToggle = rootIds.optionsOverlay.audioNarrationToggle
        ? document.getElementById(rootIds.optionsOverlay.audioNarrationToggle)
        : null;
      const subtitleLargeToggle = rootIds.optionsOverlay.subtitleLargeToggle
        ? document.getElementById(rootIds.optionsOverlay.subtitleLargeToggle)
        : null;
      const subtitlePreviewButton = rootIds.optionsOverlay.subtitlePreviewButton
        ? document.getElementById(rootIds.optionsOverlay.subtitlePreviewButton)
        : null;
      const tutorialPacingSlider = rootIds.optionsOverlay.tutorialPacingSlider
        ? document.getElementById(rootIds.optionsOverlay.tutorialPacingSlider)
        : null;
      const tutorialPacingValue = rootIds.optionsOverlay.tutorialPacingValue
        ? document.getElementById(rootIds.optionsOverlay.tutorialPacingValue)
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
      const focusOutlineSelect = rootIds.optionsOverlay.focusOutlineSelect
        ? document.getElementById(rootIds.optionsOverlay.focusOutlineSelect)
        : null;
      const castleSkinSelect = rootIds.optionsOverlay.castleSkinSelect
        ? document.getElementById(rootIds.optionsOverlay.castleSkinSelect)
        : null;
      const dayNightThemeSelect = rootIds.optionsOverlay.dayNightThemeSelect
        ? document.getElementById(rootIds.optionsOverlay.dayNightThemeSelect)
        : null;
      const parallaxSceneSelect = rootIds.optionsOverlay.parallaxSceneSelect
        ? document.getElementById(rootIds.optionsOverlay.parallaxSceneSelect)
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
      const layoutPreviewButton = rootIds.optionsOverlay.layoutPreviewButton
        ? document.getElementById(rootIds.optionsOverlay.layoutPreviewButton)
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
      const telemetryQueueDownloadButton = rootIds.optionsOverlay.telemetryQueueDownloadButton
        ? document.getElementById(rootIds.optionsOverlay.telemetryQueueDownloadButton)
        : null;
      const telemetryQueueClearButton = rootIds.optionsOverlay.telemetryQueueClearButton
        ? document.getElementById(rootIds.optionsOverlay.telemetryQueueClearButton)
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
      const sessionTimelineExportButton = rootIds.optionsOverlay.sessionTimelineExportButton
        ? document.getElementById(rootIds.optionsOverlay.sessionTimelineExportButton)
        : null;
      const keystrokeTimingExportButton = rootIds.optionsOverlay.keystrokeTimingExportButton
        ? document.getElementById(rootIds.optionsOverlay.keystrokeTimingExportButton)
        : null;
      const progressExportButton = rootIds.optionsOverlay.progressExportButton
        ? document.getElementById(rootIds.optionsOverlay.progressExportButton)
        : null;
      const progressImportButton = rootIds.optionsOverlay.progressImportButton
        ? document.getElementById(rootIds.optionsOverlay.progressImportButton)
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
        (musicToggle === null || musicToggle instanceof HTMLInputElement) &&
        (musicLevelSlider === null || musicLevelSlider instanceof HTMLInputElement) &&
        (musicLevelValue === null || musicLevelValue instanceof HTMLElement) &&
        (musicLibraryButton === null || musicLibraryButton instanceof HTMLButtonElement) &&
        (musicLibrarySummary === null || musicLibrarySummary instanceof HTMLElement) &&
        (uiSoundLibraryButton === null || uiSoundLibraryButton instanceof HTMLButtonElement) &&
        (uiSoundLibrarySummary === null || uiSoundLibrarySummary instanceof HTMLElement) &&
        (uiSoundPreviewButton === null || uiSoundPreviewButton instanceof HTMLButtonElement) &&
        (screenShakeToggle === null || screenShakeToggle instanceof HTMLInputElement) &&
        (screenShakeSlider === null || screenShakeSlider instanceof HTMLInputElement) &&
        (screenShakeValue === null || screenShakeValue instanceof HTMLElement) &&
        (screenShakePreview === null || screenShakePreview instanceof HTMLButtonElement) &&
        (screenShakeDemo === null || screenShakeDemo instanceof HTMLElement) &&
        (contrastAuditButton === null || contrastAuditButton instanceof HTMLButtonElement) &&
        (sfxLibraryButton === null || sfxLibraryButton instanceof HTMLButtonElement) &&
        (sfxLibrarySummary === null || sfxLibrarySummary instanceof HTMLElement) &&
        (stickerBookButton === null || stickerBookButton instanceof HTMLButtonElement) &&
        (seasonTrackButton === null || seasonTrackButton instanceof HTMLButtonElement) &&
        (museumButton === null || museumButton instanceof HTMLButtonElement) &&
        (loreScrollsButton === null || loreScrollsButton instanceof HTMLButtonElement) &&
        (wpmLadderButton === null || wpmLadderButton instanceof HTMLButtonElement) &&
        (trainingCalendarButton === null || trainingCalendarButton instanceof HTMLButtonElement) &&
        (postureChecklistButton === null || postureChecklistButton instanceof HTMLButtonElement) &&
        (postureChecklistSummary === null || postureChecklistSummary instanceof HTMLElement) &&
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
        (accessibilityPresetToggle === null || accessibilityPresetToggle instanceof HTMLInputElement) &&
        (breakReminderIntervalSelect === null ||
          breakReminderIntervalSelect instanceof HTMLSelectElement) &&
        (screenTimeGoalSelect === null || screenTimeGoalSelect instanceof HTMLSelectElement) &&
        (screenTimeLockoutSelect === null || screenTimeLockoutSelect instanceof HTMLSelectElement) &&
        (screenTimeStatus === null || screenTimeStatus instanceof HTMLElement) &&
        (screenTimeResetButton === null || screenTimeResetButton instanceof HTMLButtonElement) &&
        (voicePackSelect === null || voicePackSelect instanceof HTMLSelectElement) &&
        (latencySparklineToggle === null || latencySparklineToggle instanceof HTMLInputElement) &&
        readableFontToggle instanceof HTMLInputElement &&
        dyslexiaFontToggle instanceof HTMLInputElement &&
        (dyslexiaSpacingToggle === null || dyslexiaSpacingToggle instanceof HTMLInputElement) &&
        (cognitiveLoadToggle === null || cognitiveLoadToggle instanceof HTMLInputElement) &&
        (milestonePopupsToggle === null || milestonePopupsToggle instanceof HTMLInputElement) &&
        (audioNarrationToggle === null || audioNarrationToggle instanceof HTMLInputElement) &&
        (subtitleLargeToggle === null || subtitleLargeToggle instanceof HTMLInputElement) &&
        (subtitlePreviewButton === null || subtitlePreviewButton instanceof HTMLButtonElement) &&
        (tutorialPacingSlider === null || tutorialPacingSlider instanceof HTMLInputElement) &&
        (tutorialPacingValue === null || tutorialPacingValue instanceof HTMLElement) &&
        (backgroundBrightnessSlider === null ||
          backgroundBrightnessSlider instanceof HTMLInputElement) &&
        (backgroundBrightnessValue === null || backgroundBrightnessValue instanceof HTMLElement) &&
        colorblindPaletteToggle instanceof HTMLInputElement &&
        (colorblindPaletteSelect === null || colorblindPaletteSelect instanceof HTMLSelectElement) &&
        (focusOutlineSelect === null || focusOutlineSelect instanceof HTMLSelectElement) &&
        (castleSkinSelect === null || castleSkinSelect instanceof HTMLSelectElement) &&
        (dayNightThemeSelect === null || dayNightThemeSelect instanceof HTMLSelectElement) &&
        (hotkeyPauseSelect === null || hotkeyPauseSelect instanceof HTMLSelectElement) &&
        (hotkeyShortcutsSelect === null || hotkeyShortcutsSelect instanceof HTMLSelectElement) &&
        hudZoomSelect instanceof HTMLSelectElement &&
        (hudLayoutToggle === null || hudLayoutToggle instanceof HTMLInputElement) &&
        (layoutPreviewButton === null || layoutPreviewButton instanceof HTMLButtonElement) &&
        fontScaleSelect instanceof HTMLSelectElement &&
        defeatAnimationSelect instanceof HTMLSelectElement
      ) {
        this.optionsOverlay = {
          container: optionsContainer,
          closeButton,
          resumeButton,
          mainColumn: optionsMainColumn ?? undefined,
          panelContainer: optionsPanelContainer ?? undefined,
          panels: optionPanels,
          navButtons: navButtons.length > 0 ? navButtons : undefined,
          soundToggle,
          soundVolumeSlider,
          soundVolumeValue,
          soundIntensitySlider,
          soundIntensityValue,
          musicToggle: musicToggle instanceof HTMLInputElement ? musicToggle : undefined,
          musicLevelSlider: musicLevelSlider instanceof HTMLInputElement ? musicLevelSlider : undefined,
          musicLevelValue: musicLevelValue instanceof HTMLElement ? musicLevelValue : undefined,
          musicLibraryButton:
            musicLibraryButton instanceof HTMLButtonElement ? musicLibraryButton : undefined,
          musicLibrarySummary:
            musicLibrarySummary instanceof HTMLElement ? musicLibrarySummary : undefined,
          uiSoundLibraryButton:
            uiSoundLibraryButton instanceof HTMLButtonElement ? uiSoundLibraryButton : undefined,
          uiSoundLibrarySummary:
            uiSoundLibrarySummary instanceof HTMLElement ? uiSoundLibrarySummary : undefined,
          uiSoundPreviewButton:
            uiSoundPreviewButton instanceof HTMLButtonElement ? uiSoundPreviewButton : undefined,
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
          sfxLibraryButton:
            sfxLibraryButton instanceof HTMLButtonElement ? sfxLibraryButton : undefined,
          sfxLibrarySummary:
            sfxLibrarySummary instanceof HTMLElement ? sfxLibrarySummary : undefined,
          stickerBookButton:
            stickerBookButton instanceof HTMLButtonElement ? stickerBookButton : undefined,
          seasonTrackButton:
            seasonTrackButton instanceof HTMLButtonElement ? seasonTrackButton : undefined,
          readabilityGuideButton:
            readabilityGuideButton instanceof HTMLButtonElement ? readabilityGuideButton : undefined,
          museumButton: museumButton instanceof HTMLButtonElement ? museumButton : undefined,
          sideQuestButton: sideQuestButton instanceof HTMLButtonElement ? sideQuestButton : undefined,
          masteryCertificateButton:
            masteryCertificateButton instanceof HTMLButtonElement ? masteryCertificateButton : undefined,
          lessonMedalButton:
            lessonMedalButton instanceof HTMLButtonElement ? lessonMedalButton : undefined,
          wpmLadderButton: wpmLadderButton instanceof HTMLButtonElement ? wpmLadderButton : undefined,
          biomeGalleryButton:
            biomeGalleryButton instanceof HTMLButtonElement ? biomeGalleryButton : undefined,
          trainingCalendarButton:
            trainingCalendarButton instanceof HTMLButtonElement ? trainingCalendarButton : undefined,
          loreScrollsButton:
            loreScrollsButton instanceof HTMLButtonElement ? loreScrollsButton : undefined,
          postureChecklistButton:
            postureChecklistButton instanceof HTMLButtonElement ? postureChecklistButton : undefined,
          postureChecklistSummary:
            postureChecklistSummary instanceof HTMLElement ? postureChecklistSummary : undefined,
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
          virtualKeyboardLayoutSelect:
            virtualKeyboardLayoutSelect instanceof HTMLSelectElement
              ? virtualKeyboardLayoutSelect
              : undefined,
          lowGraphicsToggle:
            lowGraphicsToggle instanceof HTMLInputElement ? lowGraphicsToggle : undefined,
          textSizeSelect:
            textSizeSelect instanceof HTMLSelectElement ? textSizeSelect : undefined,
          hapticsToggle: hapticsToggle instanceof HTMLInputElement ? hapticsToggle : undefined,
          reducedMotionToggle,
          checkeredBackgroundToggle,
          accessibilityPresetToggle:
            accessibilityPresetToggle instanceof HTMLInputElement
              ? accessibilityPresetToggle
              : undefined,
          breakReminderIntervalSelect:
            breakReminderIntervalSelect instanceof HTMLSelectElement
              ? breakReminderIntervalSelect
              : undefined,
          screenTimeGoalSelect:
            screenTimeGoalSelect instanceof HTMLSelectElement ? screenTimeGoalSelect : undefined,
          screenTimeLockoutSelect:
            screenTimeLockoutSelect instanceof HTMLSelectElement ? screenTimeLockoutSelect : undefined,
          screenTimeStatus: screenTimeStatus instanceof HTMLElement ? screenTimeStatus : undefined,
          screenTimeResetButton:
            screenTimeResetButton instanceof HTMLButtonElement ? screenTimeResetButton : undefined,
          voicePackSelect: voicePackSelect instanceof HTMLSelectElement ? voicePackSelect : undefined,
          latencySparklineToggle:
            latencySparklineToggle instanceof HTMLInputElement ? latencySparklineToggle : undefined,
          readableFontToggle,
          dyslexiaFontToggle,
          dyslexiaSpacingToggle:
            dyslexiaSpacingToggle instanceof HTMLInputElement ? dyslexiaSpacingToggle : undefined,
          cognitiveLoadToggle:
            cognitiveLoadToggle instanceof HTMLInputElement ? cognitiveLoadToggle : undefined,
          milestonePopupsToggle:
            milestonePopupsToggle instanceof HTMLInputElement ? milestonePopupsToggle : undefined,
          audioNarrationToggle:
            audioNarrationToggle instanceof HTMLInputElement ? audioNarrationToggle : undefined,
          tutorialPacingSlider:
            tutorialPacingSlider instanceof HTMLInputElement ? tutorialPacingSlider : undefined,
          tutorialPacingValue:
            tutorialPacingValue instanceof HTMLElement ? tutorialPacingValue : undefined,
          subtitleLargeToggle:
            subtitleLargeToggle instanceof HTMLInputElement ? subtitleLargeToggle : undefined,
          subtitlePreviewButton:
            subtitlePreviewButton instanceof HTMLButtonElement ? subtitlePreviewButton : undefined,
          backgroundBrightnessSlider:
            backgroundBrightnessSlider instanceof HTMLInputElement
              ? backgroundBrightnessSlider
              : undefined,
          backgroundBrightnessValue:
            backgroundBrightnessValue instanceof HTMLElement ? backgroundBrightnessValue : undefined,
          colorblindPaletteToggle,
          colorblindPaletteSelect:
            colorblindPaletteSelect instanceof HTMLSelectElement ? colorblindPaletteSelect : undefined,
          focusOutlineSelect:
            focusOutlineSelect instanceof HTMLSelectElement ? focusOutlineSelect : undefined,
          castleSkinSelect: castleSkinSelect instanceof HTMLSelectElement ? castleSkinSelect : undefined,
          dayNightThemeSelect:
            dayNightThemeSelect instanceof HTMLSelectElement ? dayNightThemeSelect : undefined,
          parallaxSceneSelect:
            parallaxSceneSelect instanceof HTMLSelectElement ? parallaxSceneSelect : undefined,
          hotkeyPauseSelect:
            hotkeyPauseSelect instanceof HTMLSelectElement ? hotkeyPauseSelect : undefined,
          hotkeyShortcutsSelect:
            hotkeyShortcutsSelect instanceof HTMLSelectElement ? hotkeyShortcutsSelect : undefined,
          hudZoomSelect,
          hudLayoutToggle: hudLayoutToggle instanceof HTMLInputElement ? hudLayoutToggle : undefined,
          layoutPreviewButton:
            layoutPreviewButton instanceof HTMLButtonElement ? layoutPreviewButton : undefined,
          fontScaleSelect,
          defeatAnimationSelect,
          telemetryToggle: telemetryToggle instanceof HTMLInputElement ? telemetryToggle : undefined,
          telemetryWrapper:
            telemetryToggleWrapper instanceof HTMLElement ? telemetryToggleWrapper : undefined,
          telemetryQueueDownloadButton:
            telemetryQueueDownloadButton instanceof HTMLButtonElement
              ? telemetryQueueDownloadButton
              : undefined,
          telemetryQueueClearButton:
            telemetryQueueClearButton instanceof HTMLButtonElement ? telemetryQueueClearButton : undefined,
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
          endSessionButton:
            endSessionButton instanceof HTMLButtonElement ? endSessionButton : undefined,
          analyticsExportButton:
            analyticsExportButton instanceof HTMLButtonElement ? analyticsExportButton : undefined,
          sessionTimelineExportButton:
            sessionTimelineExportButton instanceof HTMLButtonElement
              ? sessionTimelineExportButton
              : undefined,
          keystrokeTimingExportButton:
            keystrokeTimingExportButton instanceof HTMLButtonElement
              ? keystrokeTimingExportButton
              : undefined,
          progressExportButton:
            progressExportButton instanceof HTMLButtonElement ? progressExportButton : undefined,
          progressImportButton:
            progressImportButton instanceof HTMLButtonElement ? progressImportButton : undefined
        };
        this.addFocusTrap(optionsContainer);
        this.sfxActiveLabel = this.optionsOverlay.sfxLibrarySummary;
        this.uiSoundActiveLabel = this.optionsOverlay.uiSoundLibrarySummary;
        this.musicActiveLabel = this.optionsOverlay.musicLibrarySummary;
        const postureReminder = document.getElementById("posture-reminder");
        const postureReminderTip = document.getElementById("posture-reminder-tip");
        const postureReminderDismiss = document.getElementById("posture-reminder-dismiss");
        if (
          postureReminder instanceof HTMLElement &&
          postureReminderDismiss instanceof HTMLButtonElement
        ) {
          this.postureReminder = {
            container: postureReminder,
            tip: postureReminderTip instanceof HTMLElement ? postureReminderTip : postureReminder,
            dismiss: postureReminderDismiss
          };
          postureReminder.dataset.visible = postureReminder.dataset.visible ?? "false";
          postureReminder.setAttribute("aria-hidden", "true");
          postureReminderDismiss.addEventListener("click", () => this.clearPostureReminder());
        }
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
        if (this.optionsOverlay.musicToggle) {
          this.optionsOverlay.musicToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onMusicToggle?.(this.optionsOverlay!.musicToggle!.checked);
          });
        }
        if (this.optionsOverlay.musicLevelSlider) {
          this.optionsOverlay.musicLevelSlider.addEventListener("input", () => {
            if (this.syncingOptionToggles) return;
            const rawValue = Number.parseFloat(this.optionsOverlay!.musicLevelSlider!.value);
            if (!Number.isFinite(rawValue)) return;
            this.updateMusicLevelDisplay(rawValue);
            this.callbacks.onMusicLevelChange?.(rawValue);
          });
        }
        if (this.optionsOverlay.musicLibraryButton) {
          this.optionsOverlay.musicLibraryButton.addEventListener("click", () => {
            this.showMusicOverlay();
          });
        }
        if (this.optionsOverlay.uiSoundLibraryButton) {
          this.optionsOverlay.uiSoundLibraryButton.addEventListener("click", () => {
            this.showUiSoundOverlay();
          });
        }
        if (this.optionsOverlay.uiSoundPreviewButton) {
          this.optionsOverlay.uiSoundPreviewButton.addEventListener("click", () => {
            this.callbacks.onUiSoundPreview?.();
          });
        }
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
        if (this.optionsOverlay.sfxLibraryButton) {
          this.optionsOverlay.sfxLibraryButton.addEventListener("click", () => {
            this.showSfxOverlay();
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
        if (this.optionsOverlay.readabilityGuideButton) {
          this.optionsOverlay.readabilityGuideButton.addEventListener("click", () => {
            this.showReadabilityOverlay();
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
        if (this.optionsOverlay.wpmLadderButton) {
          this.optionsOverlay.wpmLadderButton.addEventListener("click", () => {
            this.showWpmLadderOverlay();
          });
        }
        if (this.optionsOverlay.biomeGalleryButton) {
          this.optionsOverlay.biomeGalleryButton.addEventListener("click", () => {
            this.showBiomeOverlay();
          });
        }
        if (this.optionsOverlay.trainingCalendarButton) {
          this.optionsOverlay.trainingCalendarButton.addEventListener("click", () => {
            this.showTrainingCalendarOverlay();
          });
        }
        if (this.optionsOverlay.postureChecklistButton) {
          this.optionsOverlay.postureChecklistButton.addEventListener("click", () => {
            this.showPostureOverlay();
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
        if (this.optionsOverlay.endSessionButton) {
          this.optionsOverlay.endSessionButton.addEventListener("click", () => {
            this.showDropoffOverlay(this.optionsOverlay!.endSessionButton);
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
        if (this.optionsOverlay.virtualKeyboardLayoutSelect) {
          this.optionsOverlay.virtualKeyboardLayoutSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const layout = this.getSelectValue(this.optionsOverlay!.virtualKeyboardLayoutSelect);
            if (layout) {
              this.callbacks.onVirtualKeyboardLayoutChange?.(layout);
            }
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
        if (this.optionsOverlay.accessibilityPresetToggle) {
          this.optionsOverlay.accessibilityPresetToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onAccessibilityPresetToggle?.(
              this.optionsOverlay!.accessibilityPresetToggle!.checked
            );
          });
        }
        if (this.optionsOverlay.breakReminderIntervalSelect) {
          this.optionsOverlay.breakReminderIntervalSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const rawValue = this.getSelectValue(this.optionsOverlay!.breakReminderIntervalSelect);
            const parsed = rawValue === "off" ? 0 : Number.parseInt(rawValue ?? "", 10);
            if (!Number.isFinite(parsed)) return;
            this.callbacks.onBreakReminderIntervalChange?.(Math.max(0, Math.floor(parsed)));
          });
        }
        if (this.optionsOverlay.screenTimeGoalSelect) {
          this.optionsOverlay.screenTimeGoalSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const rawValue = this.getSelectValue(this.optionsOverlay!.screenTimeGoalSelect);
            const parsed = rawValue === "off" ? 0 : Number.parseInt(rawValue ?? "", 10);
            if (!Number.isFinite(parsed)) return;
            this.callbacks.onScreenTimeGoalChange?.(Math.max(0, Math.floor(parsed)));
          });
        }
        if (this.optionsOverlay.screenTimeLockoutSelect) {
          this.optionsOverlay.screenTimeLockoutSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const mode = this.getSelectValue(this.optionsOverlay!.screenTimeLockoutSelect);
            if (mode) {
              this.callbacks.onScreenTimeLockoutModeChange?.(mode);
            }
          });
        }
        if (this.optionsOverlay.screenTimeResetButton) {
          this.optionsOverlay.screenTimeResetButton.addEventListener("click", () => {
            this.callbacks.onScreenTimeReset?.();
          });
        }
        if (this.optionsOverlay.latencySparklineToggle) {
          this.optionsOverlay.latencySparklineToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onLatencySparklineToggle?.(
              this.optionsOverlay!.latencySparklineToggle!.checked
            );
          });
        }
        readableFontToggle.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          this.callbacks.onReadableFontToggle(readableFontToggle.checked);
        });
        dyslexiaFontToggle.addEventListener("change", () => {
          if (this.syncingOptionToggles) return;
          this.callbacks.onDyslexiaFontToggle(dyslexiaFontToggle.checked);
        });
        if (this.optionsOverlay.voicePackSelect) {
          this.optionsOverlay.voicePackSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const value = this.getSelectValue(this.optionsOverlay!.voicePackSelect);
            if (value) {
              this.callbacks.onVoicePackChange?.(value);
            }
          });
        }
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
        if (this.optionsOverlay.audioNarrationToggle) {
          this.optionsOverlay.audioNarrationToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const enabled = this.optionsOverlay!.audioNarrationToggle!.checked;
            if (enabled) {
              this.narration.setEnabled(true);
              this.narration.speak(
                "Audio narration enabled. Menus and overlays will be spoken.",
                { interrupt: true }
              );
            } else {
              this.narration.speak("Audio narration disabled.", { interrupt: true });
              this.narration.setEnabled(false);
            }
            this.audioNarrationEnabled = enabled;
            this.callbacks.onAudioNarrationToggle?.(enabled);
          });
        }
        if (this.optionsOverlay.subtitleLargeToggle) {
          this.optionsOverlay.subtitleLargeToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const enabled = this.optionsOverlay!.subtitleLargeToggle!.checked;
            this.callbacks.onLargeSubtitlesToggle?.(enabled);
          });
        }
        if (this.optionsOverlay.subtitlePreviewButton && this.subtitleOverlay) {
          this.optionsOverlay.subtitlePreviewButton.addEventListener("click", () => {
            this.showSubtitleOverlay();
          });
        }
        if (this.optionsOverlay.tutorialPacingSlider) {
          this.optionsOverlay.tutorialPacingSlider.addEventListener("input", () => {
            const raw = this.optionsOverlay!.tutorialPacingSlider!.value;
            const parsed = Number.parseFloat(raw);
            if (!Number.isFinite(parsed)) return;
            this.tutorialPacing = parsed;
            this.updateTutorialPacingDisplay(parsed);
            this.callbacks.onTutorialPacingChange?.(parsed);
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
        if (this.optionsOverlay.milestonePopupsToggle) {
          this.optionsOverlay.milestonePopupsToggle.checked = !this.milestoneCelebrationsDisabled;
          this.optionsOverlay.milestonePopupsToggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const enabled = this.optionsOverlay!.milestonePopupsToggle!.checked;
            this.milestoneCelebrationsDisabled = !enabled;
            this.persistMilestoneCelebrationsDisabled(this.milestoneCelebrationsDisabled);
            if (!enabled) {
              this.hideMilestoneCelebration();
            }
            this.appendLog(`Milestone popups ${enabled ? "enabled" : "disabled"}.`);
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
        if (this.optionsOverlay.focusOutlineSelect) {
          this.optionsOverlay.focusOutlineSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const next =
              (this.getSelectValue(this.optionsOverlay!.focusOutlineSelect!) as FocusOutlinePreset | null) ??
              null;
            if (next) {
              this.callbacks.onFocusOutlineChange?.(next);
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
        if (this.optionsOverlay.dayNightThemeSelect) {
          this.optionsOverlay.dayNightThemeSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const next = (this.getSelectValue(this.optionsOverlay!.dayNightThemeSelect!) ??
              "night") as DayNightMode;
            this.setDayNightTheme(next);
            this.callbacks.onDayNightThemeChange?.(next);
          });
        }
        if (this.optionsOverlay.parallaxSceneSelect) {
          this.optionsOverlay.parallaxSceneSelect.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            const next = (this.getSelectValue(this.optionsOverlay!.parallaxSceneSelect!) ??
              "auto") as ParallaxScene;
            this.setParallaxScene(next);
            this.callbacks.onParallaxSceneChange?.(next);
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
        if (this.optionsOverlay.layoutPreviewButton && this.layoutOverlay) {
          this.optionsOverlay.layoutPreviewButton.addEventListener("click", () => {
            this.showLayoutOverlay();
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
        if (this.optionsOverlay.telemetryQueueDownloadButton) {
          this.optionsOverlay.telemetryQueueDownloadButton.addEventListener("click", () => {
            this.callbacks.onTelemetryQueueDownload?.();
          });
        }
        if (this.optionsOverlay.telemetryQueueClearButton) {
          this.optionsOverlay.telemetryQueueClearButton.addEventListener("click", () => {
            this.callbacks.onTelemetryQueueClear?.();
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
        if (this.optionsOverlay.sessionTimelineExportButton) {
          this.optionsOverlay.sessionTimelineExportButton.addEventListener("click", () => {
            this.callbacks.onSessionTimelineExport?.();
          });
        }
        if (this.optionsOverlay.keystrokeTimingExportButton) {
          this.optionsOverlay.keystrokeTimingExportButton.addEventListener("click", () => {
            this.callbacks.onKeystrokeTimingExport?.();
          });
        }
        if (this.optionsOverlay.progressExportButton) {
          this.optionsOverlay.progressExportButton.addEventListener("click", () => {
            this.callbacks.onProgressExport?.();
          });
        }
        if (this.optionsOverlay.progressImportButton) {
          this.optionsOverlay.progressImportButton.addEventListener("click", () => {
            this.callbacks.onProgressImport?.();
          });
        }
        const parentalButton = document.getElementById("options-parental-info");
        if (parentalButton instanceof HTMLButtonElement) {
          parentalButton.addEventListener("click", () => this.showParentalOverlay(parentalButton));
        }
        const panels = this.optionsOverlay?.panels ?? optionPanels;
        const mainColumn = this.optionsOverlay?.mainColumn ?? optionsMainColumn ?? undefined;
        if (navButtons.length > 0 && panels.length > 0) {
          const setActiveButton = (button: HTMLButtonElement | null) => {
            navButtons.forEach((btn) =>
              btn.setAttribute("aria-current", btn === button ? "true" : "false")
            );
          };
          const setActivePanel = (panelKey: string) => {
            let matched = false;
            for (const panel of panels) {
              const isMatch = panel.dataset.panel === panelKey;
              panel.dataset.active = isMatch ? "true" : "false";
              panel.setAttribute("aria-hidden", isMatch ? "false" : "true");
              panel.hidden = !isMatch;
              if (isMatch) {
                matched = true;
              }
            }
            if (!matched && panels.length > 0) {
              panels[0].dataset.active = "true";
              panels[0].setAttribute("aria-hidden", "false");
              panels[0].hidden = false;
            }
            if (mainColumn) {
              mainColumn.scrollTop = 0;
            }
          };
          const activate = (panelKey: string) => {
            const targetButton =
              navButtons.find((btn) => btn.dataset.target === panelKey) ?? navButtons[0];
            setActiveButton(targetButton ?? null);
            const resolvedKey =
              targetButton?.dataset.target ?? panelKey ?? panels[0]?.dataset.panel ?? "";
            setActivePanel(resolvedKey);
          };
          for (const button of navButtons) {
            button.addEventListener("click", () => {
              activate(button.dataset.target ?? "");
            });
          }
          const initialKey =
            navButtons.find((btn) => btn.getAttribute("aria-current") === "true")?.dataset
              .target ?? panels[0]?.dataset.panel ?? "";
          activate(initialKey);
        }
        const optionSections = Array.from(
          optionsContainer.querySelectorAll<HTMLElement>(".options-section")
        );
        for (const section of optionSections) {
          const toggle = section.querySelector<HTMLButtonElement>(".options-section-toggle");
          const body = section.querySelector<HTMLElement>(".options-section-body");
          const collapsed = section.dataset.collapsed === "true";
          const update = (next: boolean) => {
            section.dataset.collapsed = next ? "true" : "false";
            if (toggle) toggle.setAttribute("aria-expanded", next ? "false" : "true");
            if (toggle) toggle.textContent = next ? "Expand" : "Collapse";
            if (body) {
              body.style.display = next ? "none" : "";
            }
          };
          update(collapsed);
          if (toggle) {
            toggle.addEventListener("click", () => {
              const next = section.dataset.collapsed !== "true";
              update(next);
            });
          }
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
      const scorecardCoach = rootIds.waveScorecard.coach
        ? document.getElementById(rootIds.waveScorecard.coach)
        : null;
      const scorecardCoachList = rootIds.waveScorecard.coachList
        ? document.getElementById(rootIds.waveScorecard.coachList)
        : null;
      const scorecardDrill = rootIds.waveScorecard.drill
        ? document.getElementById(rootIds.waveScorecard.drill)
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
          tip: scorecardTip instanceof HTMLElement ? scorecardTip : undefined,
          coach: scorecardCoach instanceof HTMLElement ? scorecardCoach : undefined,
          coachList: isElementWithTag<HTMLUListElement>(scorecardCoachList, "ul")
            ? scorecardCoachList
            : undefined,
          drillBtn: scorecardDrill instanceof HTMLButtonElement ? scorecardDrill : undefined,
          suggestedDrill: null
        };
        this.addFocusTrap(scorecardContainer);
        scorecardContinue.addEventListener("click", () => this.callbacks.onWaveScorecardContinue());
        if (scorecardDrill instanceof HTMLButtonElement) {
          scorecardDrill.addEventListener("click", () => {
            const suggestion = this.waveScorecard?.suggestedDrill ?? null;
            if (!suggestion) return;
            this.callbacks.onWaveScorecardSuggestedDrill?.(suggestion);
          });
        }
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
      const tabButtons = rootIds.analyticsViewer.tabButtons
        ? rootIds.analyticsViewer.tabButtons
            .map((id) => document.getElementById(id))
            .filter((button): button is HTMLButtonElement => button instanceof HTMLButtonElement)
        : [];
      const panelsConfig = rootIds.analyticsViewer.panels ?? {};
      const summaryPanel = panelsConfig.summary
        ? document.getElementById(panelsConfig.summary)
        : null;
      const tracesPanel = panelsConfig.traces ? document.getElementById(panelsConfig.traces) : null;
      const exportsPanel = panelsConfig.exports
        ? document.getElementById(panelsConfig.exports)
        : null;
      const tracesContainer = rootIds.analyticsViewer.traces
        ? document.getElementById(rootIds.analyticsViewer.traces)
        : null;
      const exportMeta = rootIds.analyticsViewer.exportMeta
        ? {
            waves: document.getElementById(rootIds.analyticsViewer.exportMeta.waves ?? ""),
            drills: document.getElementById(rootIds.analyticsViewer.exportMeta.drills ?? ""),
            breaches: document.getElementById(rootIds.analyticsViewer.exportMeta.breaches ?? ""),
            ttf: document.getElementById(
              rootIds.analyticsViewer.exportMeta.timeToFirstTurret ?? ""
            ),
            note: rootIds.analyticsViewer.exportMeta.note
              ? document.getElementById(rootIds.analyticsViewer.exportMeta.note)
              : null
          }
        : null;
      if (
        viewerContainer instanceof HTMLElement &&
        isElementWithTag<HTMLTableSectionElement>(viewerBody, "tbody")
      ) {
        const tabMap: Partial<Record<AnalyticsViewerTab, HTMLButtonElement>> = {};
        for (const button of tabButtons) {
          const tabId = (button.dataset.tab as AnalyticsViewerTab | undefined) ?? null;
          if (tabId === "summary" || tabId === "traces" || tabId === "exports") {
            tabMap[tabId] = button;
          }
        }
        const panelMap: Partial<Record<AnalyticsViewerTab, HTMLElement>> = {};
        if (summaryPanel instanceof HTMLElement) panelMap.summary = summaryPanel;
        if (tracesPanel instanceof HTMLElement) panelMap.traces = tracesPanel;
        if (exportsPanel instanceof HTMLElement) panelMap.exports = exportsPanel;
        this.analyticsViewer = {
          container: viewerContainer,
          tableBody: viewerBody,
          filterSelect: viewerFilter instanceof HTMLSelectElement ? viewerFilter : undefined,
          drills: drillsContainer instanceof HTMLElement ? drillsContainer : undefined,
          tabs: tabMap,
          panels: panelMap,
          traces: tracesContainer instanceof HTMLElement ? tracesContainer : undefined,
          exportMeta: exportMeta
            ? {
                waves: exportMeta.waves instanceof HTMLElement ? exportMeta.waves : undefined,
                drills: exportMeta.drills instanceof HTMLElement ? exportMeta.drills : undefined,
                breaches:
                  exportMeta.breaches instanceof HTMLElement ? exportMeta.breaches : undefined,
                ttf: exportMeta.ttf instanceof HTMLElement ? exportMeta.ttf : undefined,
                note: exportMeta.note instanceof HTMLElement ? exportMeta.note : undefined
              }
            : undefined
        };
        this.analyticsViewerVisible = viewerContainer.dataset.visible === "true";
        viewerContainer.setAttribute("aria-hidden", this.analyticsViewerVisible ? "false" : "true");
        if (this.analyticsViewer.tabs) {
          (["summary", "traces", "exports"] as AnalyticsViewerTab[]).forEach((tab) => {
            const button = this.analyticsViewer?.tabs?.[tab];
            if (!button) return;
            button.addEventListener("click", () => this.setAnalyticsViewerTab(tab));
          });
        }
        if (this.analyticsViewer.panels) {
          (["summary", "traces", "exports"] as AnalyticsViewerTab[]).forEach((tab) => {
            const panel = this.analyticsViewer?.panels?.[tab];
            if (panel && !panel.dataset.tab) {
              panel.dataset.tab = tab;
            }
          });
        }
        this.setAnalyticsViewerTab(this.analyticsViewerTab);
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

    if (rootIds.dropoffOverlay) {
      const dropoffContainer = document.getElementById(rootIds.dropoffOverlay.container);
      const dropoffClose = document.getElementById(rootIds.dropoffOverlay.closeButton);
      const dropoffCancel = rootIds.dropoffOverlay.cancelButton
        ? document.getElementById(rootIds.dropoffOverlay.cancelButton)
        : null;
      const dropoffSkip = rootIds.dropoffOverlay.skipButton
        ? document.getElementById(rootIds.dropoffOverlay.skipButton)
        : null;

      if (dropoffContainer instanceof HTMLElement && dropoffClose instanceof HTMLButtonElement) {
        const reasonButtons = Array.from(
          dropoffContainer.querySelectorAll<HTMLButtonElement>("button[data-dropoff-reason]")
        ).filter((btn): btn is HTMLButtonElement => btn instanceof HTMLButtonElement);

        this.dropoffOverlay = {
          container: dropoffContainer,
          closeButton: dropoffClose,
          cancelButton: dropoffCancel instanceof HTMLButtonElement ? dropoffCancel : undefined,
          skipButton: dropoffSkip instanceof HTMLButtonElement ? dropoffSkip : undefined,
          reasonButtons
        };
        this.dropoffOverlay.container.dataset.visible =
          this.dropoffOverlay.container.dataset.visible ?? "false";
        this.dropoffOverlay.container.setAttribute("aria-hidden", "true");
        this.addFocusTrap(dropoffContainer);

        dropoffContainer.addEventListener("keydown", (event) => {
          if (event.key !== "Escape") return;
          event.preventDefault();
          event.stopPropagation();
          this.hideDropoffOverlay();
        });

        const hideOverlay = () => this.hideDropoffOverlay();
        dropoffClose.addEventListener("click", hideOverlay);
        this.dropoffOverlay.cancelButton?.addEventListener("click", hideOverlay);
        this.dropoffOverlay.skipButton?.addEventListener("click", () => {
          this.callbacks.onDropoffReasonSelected?.("skip");
          this.hideDropoffOverlay();
        });

        for (const button of reasonButtons) {
          button.addEventListener("click", () => {
            const reasonId = button.dataset.dropoffReason;
            if (!reasonId) return;
            this.callbacks.onDropoffReasonSelected?.(reasonId);
            this.hideDropoffOverlay();
          });
        }
      } else {
        console.warn("Drop-off overlay missing; drop-off prompt disabled.");
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
    if (rootIds.musicOverlay) {
      const musicContainer = document.getElementById(rootIds.musicOverlay.container);
      const musicList = document.getElementById(rootIds.musicOverlay.list);
      const musicSummary = rootIds.musicOverlay.summary
        ? document.getElementById(rootIds.musicOverlay.summary)
        : null;
      const musicClose = document.getElementById(rootIds.musicOverlay.closeButton);
      if (
        musicContainer instanceof HTMLElement &&
        musicList instanceof HTMLElement &&
        musicClose instanceof HTMLButtonElement
      ) {
        this.musicOverlay = {
          container: musicContainer,
          list: musicList,
          summary: musicSummary instanceof HTMLElement ? musicSummary : undefined,
          closeButton: musicClose
        };
        musicContainer.dataset.visible = musicContainer.dataset.visible ?? "false";
        musicContainer.setAttribute("aria-hidden", "true");
        musicClose.addEventListener("click", () => this.hideMusicOverlay());
        this.addFocusTrap(musicContainer);
      } else {
        console.warn("Music overlay elements missing; dynamic music picker disabled.");
      }
    }
    if (rootIds.uiSoundOverlay) {
      const uiContainer = document.getElementById(rootIds.uiSoundOverlay.container);
      const uiList = document.getElementById(rootIds.uiSoundOverlay.list);
      const uiSummary = rootIds.uiSoundOverlay.summary
        ? document.getElementById(rootIds.uiSoundOverlay.summary)
        : null;
      const uiClose = document.getElementById(rootIds.uiSoundOverlay.closeButton);
      if (
        uiContainer instanceof HTMLElement &&
        uiList instanceof HTMLElement &&
        uiClose instanceof HTMLButtonElement
      ) {
        this.uiSoundOverlay = {
          container: uiContainer,
          list: uiList,
          summary: uiSummary instanceof HTMLElement ? uiSummary : undefined,
          closeButton: uiClose
        };
        uiContainer.dataset.visible = uiContainer.dataset.visible ?? "false";
        uiContainer.setAttribute("aria-hidden", "true");
        uiClose.addEventListener("click", () => this.hideUiSoundOverlay());
        this.addFocusTrap(uiContainer);
      } else {
        console.warn("UI sound scheme overlay elements missing; UI sound picker disabled.");
      }
    }
    if (rootIds.sfxOverlay) {
      const sfxContainer = document.getElementById(rootIds.sfxOverlay.container);
      const sfxList = document.getElementById(rootIds.sfxOverlay.list);
      const sfxSummary = rootIds.sfxOverlay.summary
        ? document.getElementById(rootIds.sfxOverlay.summary)
        : null;
      const sfxClose = document.getElementById(rootIds.sfxOverlay.closeButton);
      if (
        sfxContainer instanceof HTMLElement &&
        sfxList instanceof HTMLElement &&
        sfxClose instanceof HTMLButtonElement
      ) {
        this.sfxOverlay = {
          container: sfxContainer,
          list: sfxList,
          summary: sfxSummary instanceof HTMLElement ? sfxSummary : undefined,
          closeButton: sfxClose
        };
        sfxContainer.dataset.visible = sfxContainer.dataset.visible ?? "false";
        sfxContainer.setAttribute("aria-hidden", "true");
        sfxClose.addEventListener("click", () => this.hideSfxOverlay());
        this.addFocusTrap(sfxContainer);
      } else {
        console.warn("SFX library overlay elements missing; audio library overlay disabled.");
      }
    }
    if (rootIds.readabilityOverlay) {
      const guideContainer = document.getElementById(rootIds.readabilityOverlay.container);
      const guideList = document.getElementById(rootIds.readabilityOverlay.list);
      const guideSummary = rootIds.readabilityOverlay.summary
        ? document.getElementById(rootIds.readabilityOverlay.summary)
        : null;
      const guideClose = document.getElementById(rootIds.readabilityOverlay.closeButton);
      if (
        guideContainer instanceof HTMLElement &&
        guideList instanceof HTMLElement &&
        guideClose instanceof HTMLButtonElement
      ) {
        this.readabilityOverlay = {
          container: guideContainer,
          list: guideList,
          summary: guideSummary instanceof HTMLElement ? guideSummary : undefined,
          closeButton: guideClose
        };
        guideContainer.dataset.visible = guideContainer.dataset.visible ?? "false";
        guideContainer.setAttribute("aria-hidden", "true");
        guideClose.addEventListener("click", () => this.hideReadabilityOverlay());
        this.addFocusTrap(guideContainer);
      } else {
        console.warn("Readability overlay elements missing; readability guide disabled.");
      }
    }
    if (rootIds.subtitleOverlay) {
      const subtitleContainer = document.getElementById(rootIds.subtitleOverlay.container);
      const subtitleClose = document.getElementById(rootIds.subtitleOverlay.closeButton);
      const subtitleToggle = rootIds.subtitleOverlay.toggle
        ? document.getElementById(rootIds.subtitleOverlay.toggle)
        : null;
      const subtitleSummary = rootIds.subtitleOverlay.summary
        ? document.getElementById(rootIds.subtitleOverlay.summary)
        : null;
      const subtitleSamples =
        rootIds.subtitleOverlay.samples &&
        document.querySelectorAll(`#${rootIds.subtitleOverlay.samples} [data-subtitle-line]`);
      if (
        subtitleContainer instanceof HTMLElement &&
        subtitleClose instanceof HTMLButtonElement &&
        (subtitleToggle === null || subtitleToggle instanceof HTMLInputElement)
      ) {
        this.subtitleOverlay = {
          container: subtitleContainer,
          closeButton: subtitleClose,
          toggle: subtitleToggle instanceof HTMLInputElement ? subtitleToggle : undefined,
          summary: subtitleSummary instanceof HTMLElement ? subtitleSummary : undefined,
          samples:
            subtitleSamples && subtitleSamples.length > 0
              ? Array.from(subtitleSamples).filter((el): el is HTMLElement => el instanceof HTMLElement)
              : undefined
        };
        subtitleContainer.dataset.visible = subtitleContainer.dataset.visible ?? "false";
        subtitleContainer.setAttribute("aria-hidden", "true");
        subtitleClose.addEventListener("click", () => this.hideSubtitleOverlay());
        this.addFocusTrap(subtitleContainer);
        if (this.subtitleOverlay.toggle) {
          this.subtitleOverlay.toggle.addEventListener("change", () => {
            if (this.syncingOptionToggles) return;
            this.callbacks.onLargeSubtitlesToggle?.(this.subtitleOverlay!.toggle!.checked);
          });
        }
      } else {
        console.warn("Subtitle overlay elements missing; subtitle preview disabled.");
      }
    }
    if (rootIds.layoutOverlay) {
      const layoutContainer = document.getElementById(rootIds.layoutOverlay.container);
      const layoutClose = document.getElementById(rootIds.layoutOverlay.closeButton);
      const layoutSummary = rootIds.layoutOverlay.summary
        ? document.getElementById(rootIds.layoutOverlay.summary)
        : null;
      const layoutLeftCard = document.getElementById(rootIds.layoutOverlay.leftCard);
      const layoutRightCard = document.getElementById(rootIds.layoutOverlay.rightCard);
      const layoutLeftApply = document.getElementById(rootIds.layoutOverlay.leftApply);
      const layoutRightApply = document.getElementById(rootIds.layoutOverlay.rightApply);
      if (
        layoutContainer instanceof HTMLElement &&
        layoutClose instanceof HTMLButtonElement &&
        layoutLeftCard instanceof HTMLElement &&
        layoutRightCard instanceof HTMLElement &&
        layoutLeftApply instanceof HTMLButtonElement &&
        layoutRightApply instanceof HTMLButtonElement
      ) {
        this.layoutOverlay = {
          container: layoutContainer,
          closeButton: layoutClose,
          summary: layoutSummary instanceof HTMLElement ? layoutSummary : undefined,
          leftCard: layoutLeftCard,
          rightCard: layoutRightCard,
          leftApply: layoutLeftApply,
          rightApply: layoutRightApply
        };
        layoutContainer.dataset.visible = layoutContainer.dataset.visible ?? "false";
        layoutContainer.setAttribute("aria-hidden", "true");
        layoutClose.addEventListener("click", () => this.hideLayoutOverlay());
        layoutLeftApply.addEventListener("click", () => this.applyLayoutPreview("left"));
        layoutRightApply.addEventListener("click", () => this.applyLayoutPreview("right"));
        this.addFocusTrap(layoutContainer);
      } else {
        console.warn("Layout overlay elements missing; layout preview disabled.");
      }
    }
    if (rootIds.postureOverlay) {
      const postureContainer = document.getElementById(rootIds.postureOverlay.container);
      const postureList = document.getElementById(rootIds.postureOverlay.list);
      const postureSummary = rootIds.postureOverlay.summary
        ? document.getElementById(rootIds.postureOverlay.summary)
        : null;
      const postureStatus = rootIds.postureOverlay.status
        ? document.getElementById(rootIds.postureOverlay.status)
        : null;
      const postureClose = document.getElementById(rootIds.postureOverlay.closeButton);
      const postureStart = document.getElementById(rootIds.postureOverlay.startButton);
      const postureReview = document.getElementById(rootIds.postureOverlay.reviewButton);
      if (
        postureContainer instanceof HTMLElement &&
        postureList instanceof HTMLElement &&
        postureClose instanceof HTMLButtonElement &&
        postureStart instanceof HTMLButtonElement &&
        postureReview instanceof HTMLButtonElement
      ) {
        this.postureOverlay = {
          container: postureContainer,
          list: postureList,
          summary: postureSummary instanceof HTMLElement ? postureSummary : undefined,
          status: postureStatus instanceof HTMLElement ? postureStatus : undefined,
          closeButton: postureClose,
          startButton: postureStart,
          reviewButton: postureReview
        };
        postureContainer.dataset.visible = postureContainer.dataset.visible ?? "false";
        postureContainer.setAttribute("aria-hidden", "true");
        postureClose.addEventListener("click", () => this.hidePostureOverlay());
        postureStart.addEventListener("click", () => this.startPostureReminder());
        postureReview.addEventListener("click", () => this.markPostureReviewed());
        this.addFocusTrap(postureContainer);
      } else {
        console.warn("Posture overlay elements missing; posture checklist disabled.");
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
      const scrollFilters = rootIds.loreScrollOverlay.filters
        ? rootIds.loreScrollOverlay.filters
            .map((id) => document.getElementById(id))
            .filter((el): el is HTMLButtonElement => el instanceof HTMLButtonElement)
        : [];
      const scrollSearch = rootIds.loreScrollOverlay.searchInput
        ? (document.getElementById(rootIds.loreScrollOverlay.searchInput) as HTMLInputElement | null)
        : null;
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
          closeButton: scrollClose,
          filters: scrollFilters,
          searchInput: scrollSearch ?? undefined
        };
        scrollContainer.dataset.visible = scrollContainer.dataset.visible ?? "false";
        scrollContainer.setAttribute("aria-hidden", "true");
        scrollClose.addEventListener("click", () => this.hideLoreScrollOverlay());
        for (const button of scrollFilters) {
          button.addEventListener("click", () => {
            const next = (button.dataset.scrollFilter as typeof this.loreScrollFilter | undefined) ?? "all";
            this.loreScrollFilter = next;
            scrollFilters.forEach((btn) =>
              btn.setAttribute("aria-pressed", btn === button ? "true" : "false")
            );
            if (this.loreScrollState) {
              this.renderLoreScrollOverlay(this.loreScrollState);
            }
          });
        }
        scrollFilters.forEach((btn) =>
          btn.setAttribute("aria-pressed", btn.dataset.scrollFilter === this.loreScrollFilter ? "true" : "false")
        );
        if (scrollSearch) {
          scrollSearch.addEventListener("input", () => {
            this.loreScrollSearch = scrollSearch.value.trim().toLowerCase();
            if (this.loreScrollState) {
              this.renderLoreScrollOverlay(this.loreScrollState);
            }
          });
        }
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

    if (rootIds.wpmLadderOverlay) {
      const ladderContainer = document.getElementById(rootIds.wpmLadderOverlay.container);
      const ladderClose = document.getElementById(rootIds.wpmLadderOverlay.closeButton);
      const ladderList = document.getElementById(rootIds.wpmLadderOverlay.list);
      const ladderSubtitle = rootIds.wpmLadderOverlay.subtitle
        ? document.getElementById(rootIds.wpmLadderOverlay.subtitle)
        : null;
      const ladderMeta = rootIds.wpmLadderOverlay.meta
        ? document.getElementById(rootIds.wpmLadderOverlay.meta)
        : null;
      if (
        ladderContainer instanceof HTMLElement &&
        ladderClose instanceof HTMLButtonElement &&
        ladderList instanceof HTMLElement
      ) {
        this.wpmLadderOverlay = {
          container: ladderContainer,
          closeButton: ladderClose,
          list: ladderList,
          subtitle: ladderSubtitle instanceof HTMLElement ? ladderSubtitle : undefined,
          meta: ladderMeta instanceof HTMLElement ? ladderMeta : undefined
        };
        ladderContainer.dataset.visible = ladderContainer.dataset.visible ?? "false";
        ladderContainer.setAttribute("aria-hidden", "true");
        ladderClose.addEventListener("click", () => this.hideWpmLadderOverlay());
        this.addFocusTrap(ladderContainer);
      } else {
        console.warn("WPM ladder overlay elements missing; ladder overlay disabled.");
      }
    }

    if (rootIds.biomeOverlay) {
      const biomeContainer = document.getElementById(rootIds.biomeOverlay.container);
      const biomeClose = document.getElementById(rootIds.biomeOverlay.closeButton);
      const biomeList = document.getElementById(rootIds.biomeOverlay.list);
      const biomeSubtitle = rootIds.biomeOverlay.subtitle
        ? document.getElementById(rootIds.biomeOverlay.subtitle)
        : null;
      const biomeMeta = rootIds.biomeOverlay.meta
        ? document.getElementById(rootIds.biomeOverlay.meta)
        : null;
      if (
        biomeContainer instanceof HTMLElement &&
        biomeClose instanceof HTMLButtonElement &&
        biomeList instanceof HTMLElement
      ) {
        this.biomeOverlay = {
          container: biomeContainer,
          closeButton: biomeClose,
          list: biomeList,
          subtitle: biomeSubtitle instanceof HTMLElement ? biomeSubtitle : undefined,
          meta: biomeMeta instanceof HTMLElement ? biomeMeta : undefined
        };
        biomeContainer.dataset.visible = biomeContainer.dataset.visible ?? "false";
        biomeContainer.setAttribute("aria-hidden", "true");
        biomeClose.addEventListener("click", () => this.hideBiomeOverlay());
        this.addFocusTrap(biomeContainer);
      } else {
        console.warn("Biome overlay elements missing; biome overlay disabled.");
      }
    }

    if (rootIds.trainingCalendarOverlay) {
      const calContainer = document.getElementById(rootIds.trainingCalendarOverlay.container);
      const calClose = document.getElementById(rootIds.trainingCalendarOverlay.closeButton);
      const calGrid = document.getElementById(rootIds.trainingCalendarOverlay.grid);
      const calSubtitle = rootIds.trainingCalendarOverlay.subtitle
        ? document.getElementById(rootIds.trainingCalendarOverlay.subtitle)
        : null;
      const calLegend = rootIds.trainingCalendarOverlay.legend
        ? document.getElementById(rootIds.trainingCalendarOverlay.legend)
        : null;
      if (
        calContainer instanceof HTMLElement &&
        calClose instanceof HTMLButtonElement &&
        calGrid instanceof HTMLElement
      ) {
        this.trainingCalendarOverlay = {
          container: calContainer,
          closeButton: calClose,
          grid: calGrid,
          subtitle: calSubtitle instanceof HTMLElement ? calSubtitle : undefined,
          legend: calLegend instanceof HTMLElement ? calLegend : undefined
        };
        calContainer.dataset.visible = calContainer.dataset.visible ?? "false";
        calContainer.setAttribute("aria-hidden", "true");
        calClose.addEventListener("click", () => this.hideTrainingCalendarOverlay());
        this.addFocusTrap(calContainer);
      } else {
        console.warn("Training calendar overlay elements missing; calendar overlay disabled.");
      }
    }

    if (rootIds.museumOverlay) {
      const museumContainer = document.getElementById(rootIds.museumOverlay.container);
      const museumClose = document.getElementById(rootIds.museumOverlay.closeButton);
      const museumList = document.getElementById(rootIds.museumOverlay.list);
      const museumSubtitle = rootIds.museumOverlay.subtitle
        ? document.getElementById(rootIds.museumOverlay.subtitle)
        : null;
      const museumFilters = museumContainer?.querySelectorAll<HTMLButtonElement>("[data-museum-filter]");
      const filterButtons = museumFilters
        ? Array.from(museumFilters).filter((btn): btn is HTMLButtonElement => btn instanceof HTMLButtonElement)
        : [];
      if (
        museumContainer instanceof HTMLElement &&
        museumClose instanceof HTMLButtonElement &&
        museumList instanceof HTMLElement
      ) {
        this.museumOverlay = {
          container: museumContainer,
          closeButton: museumClose,
          list: museumList,
          subtitle: museumSubtitle instanceof HTMLElement ? museumSubtitle : undefined,
          filters: filterButtons
        };
        museumContainer.dataset.visible = museumContainer.dataset.visible ?? "false";
        museumContainer.setAttribute("aria-hidden", "true");
        museumClose.addEventListener("click", () => this.hideMuseumOverlay());
        for (const button of filterButtons) {
          button.addEventListener("click", () => {
            const next = (button.dataset.museumFilter as typeof this.museumFilter | undefined) ?? "all";
            this.museumFilter = next;
            filterButtons.forEach((btn) =>
              btn.setAttribute("aria-pressed", btn === button ? "true" : "false")
            );
            this.renderMuseumOverlay();
          });
        }
        filterButtons.forEach((btn) =>
          btn.setAttribute("aria-pressed", btn.dataset.museumFilter === this.museumFilter ? "true" : "false")
        );
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
      const questFilters = questContainer?.querySelectorAll<HTMLButtonElement>("[data-quest-filter]");
      const filterButtons = questFilters
        ? Array.from(questFilters).filter((btn): btn is HTMLButtonElement => btn instanceof HTMLButtonElement)
        : [];
      if (
        questContainer instanceof HTMLElement &&
        questClose instanceof HTMLButtonElement &&
        questList instanceof HTMLElement
      ) {
        this.sideQuestOverlay = {
          container: questContainer,
          closeButton: questClose,
          list: questList,
          subtitle: questSubtitle instanceof HTMLElement ? questSubtitle : undefined,
          filters: filterButtons
        };
        questContainer.dataset.visible = questContainer.dataset.visible ?? "false";
        questContainer.setAttribute("aria-hidden", "true");
        questClose.addEventListener("click", () => this.hideSideQuestOverlay());
        for (const button of filterButtons) {
          button.addEventListener("click", () => {
            const next = (button.dataset.questFilter as typeof this.sideQuestFilter | undefined) ?? "all";
            this.sideQuestFilter = next;
            filterButtons.forEach((btn) =>
              btn.setAttribute("aria-pressed", btn === button ? "true" : "false")
            );
            this.renderSideQuestOverlay();
          });
        }
        filterButtons.forEach((btn) =>
          btn.setAttribute("aria-pressed", btn.dataset.questFilter === this.sideQuestFilter ? "true" : "false")
        );
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
      const certStatLessons = rootIds.masteryCertificateOverlay.statLessons
        ? document.getElementById(rootIds.masteryCertificateOverlay.statLessons)
        : null;
      const certStatAccuracy = rootIds.masteryCertificateOverlay.statAccuracy
        ? document.getElementById(rootIds.masteryCertificateOverlay.statAccuracy)
        : null;
      const certStatWpm = rootIds.masteryCertificateOverlay.statWpm
        ? document.getElementById(rootIds.masteryCertificateOverlay.statWpm)
        : null;
      const certStatCombo = rootIds.masteryCertificateOverlay.statCombo
        ? document.getElementById(rootIds.masteryCertificateOverlay.statCombo)
        : null;
      const certStatDrills = rootIds.masteryCertificateOverlay.statDrills
        ? document.getElementById(rootIds.masteryCertificateOverlay.statDrills)
        : null;
      const certStatTime = rootIds.masteryCertificateOverlay.statTime
        ? document.getElementById(rootIds.masteryCertificateOverlay.statTime)
        : null;
      const certDetails = rootIds.masteryCertificateOverlay.details
        ? document.getElementById(rootIds.masteryCertificateOverlay.details)
        : null;
      const certDetailsToggle = rootIds.masteryCertificateOverlay.detailsToggle
        ? document.getElementById(rootIds.masteryCertificateOverlay.detailsToggle)
        : null;
      if (certContainer instanceof HTMLElement && certClose instanceof HTMLButtonElement) {
        this.masteryCertificate = {
          container: certContainer,
          closeButton: certClose,
          downloadButton: certDownload instanceof HTMLButtonElement ? certDownload : undefined,
          nameInput: certNameInput instanceof HTMLInputElement ? certNameInput : undefined,
          summary: certSummary instanceof HTMLElement ? certSummary : undefined,
          statsList: certStats instanceof HTMLElement ? certStats : undefined,
          date: certDate instanceof HTMLElement ? certDate : undefined,
          statLessons: certStatLessons instanceof HTMLElement ? certStatLessons : undefined,
          statAccuracy: certStatAccuracy instanceof HTMLElement ? certStatAccuracy : undefined,
          statWpm: certStatWpm instanceof HTMLElement ? certStatWpm : undefined,
          statCombo: certStatCombo instanceof HTMLElement ? certStatCombo : undefined,
          statDrills: certStatDrills instanceof HTMLElement ? certStatDrills : undefined,
          statTime: certStatTime instanceof HTMLElement ? certStatTime : undefined,
          details: certDetails instanceof HTMLElement ? certDetails : undefined,
          detailsToggle: certDetailsToggle instanceof HTMLButtonElement ? certDetailsToggle : undefined
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
        if (this.masteryCertificate.details) {
          this.certificateDetailsCollapsed =
            this.masteryCertificate.details.dataset.collapsed !== "false";
          this.setMasteryCertificateDetailsCollapsed(this.certificateDetailsCollapsed);
        }
        if (this.masteryCertificate.detailsToggle) {
          this.masteryCertificate.detailsToggle.addEventListener("click", () =>
            this.setMasteryCertificateDetailsCollapsed(!this.certificateDetailsCollapsed)
          );
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

    const dailyQuestPanel = document.getElementById("daily-quest-panel");
    const dailyQuestSummary = document.getElementById("daily-quest-summary");
    const dailyQuestList = document.getElementById("daily-quest-list");
    this.dailyQuestPanel = {
      container: dailyQuestPanel instanceof HTMLElement ? dailyQuestPanel : undefined,
      summary: dailyQuestSummary instanceof HTMLElement ? dailyQuestSummary : undefined,
      list: dailyQuestList instanceof HTMLElement ? dailyQuestList : undefined
    };

    const weeklyQuestPanel = document.getElementById("weekly-quest-panel");
    const weeklyQuestSummary = document.getElementById("weekly-quest-summary");
    const weeklyQuestList = document.getElementById("weekly-quest-list");
    const weeklyQuestTrialStart = document.getElementById("weekly-quest-trial-start");
    this.weeklyQuestPanel = {
      container: weeklyQuestPanel instanceof HTMLElement ? weeklyQuestPanel : undefined,
      summary: weeklyQuestSummary instanceof HTMLElement ? weeklyQuestSummary : undefined,
      list: weeklyQuestList instanceof HTMLElement ? weeklyQuestList : undefined,
      trialButton: weeklyQuestTrialStart instanceof HTMLButtonElement ? weeklyQuestTrialStart : undefined
    };

    const sessionGoalsPanel = document.getElementById("session-goals-panel");
    const sessionGoalsSummary = document.getElementById("session-goals-summary");
    const sessionGoalsList = document.getElementById("session-goals-list");
    this.sessionGoalsPanel = {
      container: sessionGoalsPanel instanceof HTMLElement ? sessionGoalsPanel : undefined,
      summary: sessionGoalsSummary instanceof HTMLElement ? sessionGoalsSummary : undefined,
      list: sessionGoalsList instanceof HTMLElement ? sessionGoalsList : undefined
    };

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
    const lessonMedalPath = document.getElementById("lesson-medal-path");
    const lessonMedalBest = document.getElementById("lesson-medal-best");
    const lessonMedalNext = document.getElementById("lesson-medal-next");
    const lessonMedalOpen = document.getElementById("lesson-medal-open");
    this.lessonMedalPanel = {
      container: lessonMedalPanel instanceof HTMLElement ? lessonMedalPanel : undefined,
      badge: lessonMedalBadge instanceof HTMLElement ? lessonMedalBadge : undefined,
      summary: lessonMedalSummary instanceof HTMLElement ? lessonMedalSummary : undefined,
      path: lessonMedalPath instanceof HTMLElement ? lessonMedalPath : undefined,
      best: lessonMedalBest instanceof HTMLElement ? lessonMedalBest : undefined,
      next: lessonMedalNext instanceof HTMLElement ? lessonMedalNext : undefined,
      openButton: lessonMedalOpen instanceof HTMLButtonElement ? lessonMedalOpen : undefined
    };
    if (this.lessonMedalPanel.openButton) {
      this.lessonMedalPanel.openButton.addEventListener("click", () => this.showLessonMedalOverlay());
    }

    const wpmLadderPanel = document.getElementById("wpm-ladder-panel");
    const wpmLadderSummary = document.getElementById("wpm-ladder-summary");
    const wpmLadderStats = document.getElementById("wpm-ladder-stats");
    const wpmLadderTop = document.getElementById("wpm-ladder-top");
    const wpmLadderOpen = document.getElementById("wpm-ladder-open");
    this.wpmLadderPanel = {
      container: wpmLadderPanel instanceof HTMLElement ? wpmLadderPanel : undefined,
      summary: wpmLadderSummary instanceof HTMLElement ? wpmLadderSummary : undefined,
      stats: wpmLadderStats instanceof HTMLElement ? wpmLadderStats : undefined,
      top: wpmLadderTop instanceof HTMLElement ? wpmLadderTop : undefined,
      openButton: wpmLadderOpen instanceof HTMLButtonElement ? wpmLadderOpen : undefined
    };
    if (this.wpmLadderPanel.openButton) {
      this.wpmLadderPanel.openButton.addEventListener("click", () => this.showWpmLadderOverlay());
    }

    const biomePanel = document.getElementById("biome-gallery-panel");
    const biomeSummary = document.getElementById("biome-gallery-summary");
    const biomeStats = document.getElementById("biome-gallery-stats");
    const biomeOpen = document.getElementById("biome-gallery-open");
    this.biomePanel = {
      container: biomePanel instanceof HTMLElement ? biomePanel : undefined,
      summary: biomeSummary instanceof HTMLElement ? biomeSummary : undefined,
      stats: biomeStats instanceof HTMLElement ? biomeStats : undefined,
      openButton: biomeOpen instanceof HTMLButtonElement ? biomeOpen : undefined
    };
    if (this.biomePanel.openButton) {
      this.biomePanel.openButton.addEventListener("click", () => this.showBiomeOverlay());
    }

    const trainingCalendarPanel = document.getElementById("training-calendar-panel");
    const trainingCalendarSummary = document.getElementById("training-calendar-summary");
    const trainingCalendarStats = document.getElementById("training-calendar-stats");
    const trainingCalendarOpen = document.getElementById("training-calendar-open");
    this.trainingCalendarPanel = {
      container: trainingCalendarPanel instanceof HTMLElement ? trainingCalendarPanel : undefined,
      summary: trainingCalendarSummary instanceof HTMLElement ? trainingCalendarSummary : undefined,
      stats: trainingCalendarStats instanceof HTMLElement ? trainingCalendarStats : undefined,
      openButton: trainingCalendarOpen instanceof HTMLButtonElement ? trainingCalendarOpen : undefined
    };
    if (this.trainingCalendarPanel.openButton) {
      this.trainingCalendarPanel.openButton.addEventListener("click", () => this.showTrainingCalendarOverlay());
    }

    const streakTokenPanel = document.getElementById("streak-token-panel");
    const streakTokenCount = document.getElementById("streak-token-count");
    const streakTokenStatus = document.getElementById("streak-token-status");
    this.streakTokenPanel = {
      container: streakTokenPanel instanceof HTMLElement ? streakTokenPanel : undefined,
      count: streakTokenCount instanceof HTMLElement ? streakTokenCount : undefined,
      status: streakTokenStatus instanceof HTMLElement ? streakTokenStatus : undefined
    };

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

  isBuildMenuOpen(): boolean {
    return this.buildDrawer?.dataset.open === "true";
  }

  toggleBuildMenu(open?: boolean): boolean {
    if (!this.buildDrawer || !this.setBuildDrawerOpen) {
      return false;
    }
    const next =
      typeof open === "boolean" ? open : this.buildDrawer.dataset.open !== "true";
    if (next) {
      this.setHudDockPane?.("build");
    }
    this.setBuildDrawerOpen(next);
    return next;
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

  setVirtualKeyboardLayout(layout: string): void {
    const normalized = typeof layout === "string" ? layout.toLowerCase() : "qwerty";
    if (this.virtualKeyboardLayout === normalized) {
      return;
    }
    this.virtualKeyboardLayout = normalized;
    if (this.virtualKeyboard && typeof this.virtualKeyboard.setLayout === "function") {
      this.virtualKeyboard.setLayout(normalized);
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
    audioNarrationEnabled?: boolean;
    accessibilityPresetEnabled?: boolean;
    voicePackId?: string;
    tutorialPacing?: number;
    largeSubtitlesEnabled?: boolean;
    musicEnabled?: boolean;
    musicLevel?: number;
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
    virtualKeyboardLayout?: string;
    hapticsEnabled?: boolean;
    textSizeScale?: number;
    reducedMotionEnabled: boolean;
    latencySparklineEnabled?: boolean;
    checkeredBackgroundEnabled: boolean;
    readableFontEnabled: boolean;
    dyslexiaFontEnabled: boolean;
    dyslexiaSpacingEnabled?: boolean;
    reducedCognitiveLoadEnabled?: boolean;
    backgroundBrightness?: number;
    colorblindPaletteEnabled: boolean;
    colorblindPaletteMode?: string;
    focusOutlinePreset?: FocusOutlinePreset;
    castleSkin?: CastleSkinId;
    parallaxScene?: ParallaxScene;
    hudZoom: number;
    hudLayout: "left" | "right";
    hudFontScale: number;
    defeatAnimationMode: DefeatAnimationPreference;
    breakReminderIntervalMinutes?: number;
    screenTime?: {
      goalMinutes: number;
      lockoutMode: string;
      minutesToday: number;
      locked: boolean;
      lockoutRemainingMs?: number;
    };
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
    if (state.audioNarrationEnabled !== undefined) {
      this.audioNarrationEnabled = Boolean(state.audioNarrationEnabled);
      this.narration.setEnabled(this.audioNarrationEnabled);
    }
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
    const musicDisabled = !state.soundEnabled;
    if (this.optionsOverlay.musicToggle) {
      this.optionsOverlay.musicToggle.checked = state.musicEnabled !== false;
      this.optionsOverlay.musicToggle.disabled = musicDisabled;
      this.optionsOverlay.musicToggle.setAttribute(
        "aria-disabled",
        musicDisabled ? "true" : "false"
      );
      this.optionsOverlay.musicToggle.tabIndex = musicDisabled ? -1 : 0;
    }
    if (this.optionsOverlay.musicLevelSlider) {
      const slider = this.optionsOverlay.musicLevelSlider;
      slider.disabled = musicDisabled || state.musicEnabled === false;
      slider.setAttribute("aria-disabled", slider.disabled ? "true" : "false");
      slider.tabIndex = slider.disabled ? -1 : 0;
      const level =
        typeof state.musicLevel === "number" && !Number.isNaN(state.musicLevel)
          ? state.musicLevel
          : 0.65;
      slider.value = level.toString();
      this.updateMusicLevelDisplay(level);
    }
    const audioLibrariesDisabled = !state.soundEnabled;
    if (this.optionsOverlay.musicLibraryButton) {
      this.optionsOverlay.musicLibraryButton.disabled = audioLibrariesDisabled;
      this.optionsOverlay.musicLibraryButton.setAttribute(
        "aria-disabled",
        audioLibrariesDisabled ? "true" : "false"
      );
      this.optionsOverlay.musicLibraryButton.tabIndex = audioLibrariesDisabled ? -1 : 0;
    }
    if (this.optionsOverlay.uiSoundLibraryButton) {
      this.optionsOverlay.uiSoundLibraryButton.disabled = audioLibrariesDisabled;
      this.optionsOverlay.uiSoundLibraryButton.setAttribute(
        "aria-disabled",
        audioLibrariesDisabled ? "true" : "false"
      );
      this.optionsOverlay.uiSoundLibraryButton.tabIndex = audioLibrariesDisabled ? -1 : 0;
    }
    if (this.optionsOverlay.uiSoundPreviewButton) {
      this.optionsOverlay.uiSoundPreviewButton.disabled = audioLibrariesDisabled;
      this.optionsOverlay.uiSoundPreviewButton.setAttribute(
        "aria-disabled",
        audioLibrariesDisabled ? "true" : "false"
      );
      this.optionsOverlay.uiSoundPreviewButton.tabIndex = audioLibrariesDisabled ? -1 : 0;
    }
    if (this.optionsOverlay.sfxLibraryButton) {
      this.optionsOverlay.sfxLibraryButton.disabled = audioLibrariesDisabled;
      this.optionsOverlay.sfxLibraryButton.setAttribute(
        "aria-disabled",
        audioLibrariesDisabled ? "true" : "false"
      );
      this.optionsOverlay.sfxLibraryButton.tabIndex = audioLibrariesDisabled ? -1 : 0;
    }
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
    if (state.virtualKeyboardLayout) {
      this.setVirtualKeyboardLayout(state.virtualKeyboardLayout);
      if (this.optionsOverlay.virtualKeyboardLayoutSelect) {
        this.setSelectValue(
          this.optionsOverlay.virtualKeyboardLayoutSelect,
          state.virtualKeyboardLayout
        );
        const disabled = state.virtualKeyboardEnabled === false;
        this.optionsOverlay.virtualKeyboardLayoutSelect.disabled = disabled;
        this.optionsOverlay.virtualKeyboardLayoutSelect.setAttribute(
          "aria-disabled",
          disabled ? "true" : "false"
        );
        this.optionsOverlay.virtualKeyboardLayoutSelect.tabIndex = disabled ? -1 : 0;
      }
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
    if (
      this.optionsOverlay.accessibilityPresetToggle &&
      state.accessibilityPresetEnabled !== undefined
    ) {
      this.accessibilityPresetEnabled = Boolean(state.accessibilityPresetEnabled);
      this.optionsOverlay.accessibilityPresetToggle.checked = this.accessibilityPresetEnabled;
    }
    if (
      this.optionsOverlay.breakReminderIntervalSelect &&
      state.breakReminderIntervalMinutes !== undefined
    ) {
      const minutes = Math.max(0, Math.floor(state.breakReminderIntervalMinutes));
      this.setSelectValue(
        this.optionsOverlay.breakReminderIntervalSelect,
        minutes <= 0 ? "off" : minutes.toString()
      );
    }
    if (state.screenTime) {
      const screenTime = state.screenTime;
      const locked = Boolean(screenTime.locked);
      this.optionsOverlay.resumeButton.disabled = locked;
      this.optionsOverlay.resumeButton.setAttribute("aria-disabled", locked ? "true" : "false");
      this.optionsOverlay.resumeButton.tabIndex = locked ? -1 : 0;

      if (this.optionsOverlay.screenTimeGoalSelect) {
        const goalMinutes = Math.max(0, Math.floor(screenTime.goalMinutes ?? 0));
        this.setSelectValue(
          this.optionsOverlay.screenTimeGoalSelect,
          goalMinutes <= 0 ? "off" : goalMinutes.toString()
        );
      }
      if (this.optionsOverlay.screenTimeLockoutSelect) {
        this.setSelectValue(this.optionsOverlay.screenTimeLockoutSelect, screenTime.lockoutMode);
      }
      if (this.optionsOverlay.screenTimeStatus) {
        const minutesToday = Math.max(0, Math.floor(screenTime.minutesToday ?? 0));
        const goalMinutes = Math.max(0, Math.floor(screenTime.goalMinutes ?? 0));
        const base =
          goalMinutes > 0 ? `Today: ${minutesToday}/${goalMinutes} minutes` : `Today: ${minutesToday} minutes`;
        if (locked) {
          const remainingMs = Math.max(0, screenTime.lockoutRemainingMs ?? 0);
          const remainingMinutes = Math.max(1, Math.ceil(remainingMs / 60_000));
          this.optionsOverlay.screenTimeStatus.textContent = `${base}. Lockout: ${remainingMinutes}m remaining.`;
        } else {
          this.optionsOverlay.screenTimeStatus.textContent = base;
        }
      }
      if (this.optionsOverlay.screenTimeResetButton) {
        const minutesToday = Math.max(0, Math.floor(screenTime.minutesToday ?? 0));
        this.optionsOverlay.screenTimeResetButton.disabled = minutesToday <= 0;
        this.optionsOverlay.screenTimeResetButton.setAttribute(
          "aria-disabled",
          minutesToday <= 0 ? "true" : "false"
        );
        this.optionsOverlay.screenTimeResetButton.tabIndex = minutesToday <= 0 ? -1 : 0;
      }
    } else {
      this.optionsOverlay.resumeButton.disabled = false;
      this.optionsOverlay.resumeButton.setAttribute("aria-disabled", "false");
      this.optionsOverlay.resumeButton.tabIndex = 0;
    }
    if (this.optionsOverlay.audioNarrationToggle && state.audioNarrationEnabled !== undefined) {
      this.optionsOverlay.audioNarrationToggle.checked = state.audioNarrationEnabled;
    }
    if (this.optionsOverlay.voicePackSelect && state.voicePackId) {
      this.setSelectValue(this.optionsOverlay.voicePackSelect, state.voicePackId);
    }
    if (this.optionsOverlay.tutorialPacingSlider && state.tutorialPacing !== undefined) {
      const pacing = Number.isFinite(state.tutorialPacing) ? state.tutorialPacing : 1;
      this.tutorialPacing = pacing;
      this.optionsOverlay.tutorialPacingSlider.value = pacing.toString();
      this.optionsOverlay.tutorialPacingSlider.setAttribute("aria-valuenow", pacing.toString());
      this.updateTutorialPacingDisplay(pacing);
    }
    if (state.largeSubtitlesEnabled !== undefined) {
      this.subtitleLargeEnabled = Boolean(state.largeSubtitlesEnabled);
      if (this.optionsOverlay.subtitleLargeToggle) {
        this.optionsOverlay.subtitleLargeToggle.checked = this.subtitleLargeEnabled;
      }
      this.syncSubtitleOverlayState();
    }
    if (this.optionsOverlay.latencySparklineToggle && state.latencySparklineEnabled !== undefined) {
      this.optionsOverlay.latencySparklineToggle.checked = state.latencySparklineEnabled;
    }
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
    const focusOutline = (state.focusOutlinePreset ?? this.focusOutlinePreset) as FocusOutlinePreset;
    this.focusOutlinePreset = focusOutline;
    if (this.optionsOverlay.focusOutlineSelect) {
      this.setSelectValue(this.optionsOverlay.focusOutlineSelect, focusOutline);
    }
    const castleSkin = state.castleSkin ?? this.castleSkin ?? "classic";
    if (this.optionsOverlay.castleSkinSelect) {
      this.setSelectValue(this.optionsOverlay.castleSkinSelect, castleSkin);
    }
    this.setCastleSkin(castleSkin as CastleSkinId);
    if (this.optionsOverlay.dayNightThemeSelect) {
      this.setSelectValue(this.optionsOverlay.dayNightThemeSelect, this.dayNightTheme);
    }
    this.setParallaxScene(state.parallaxScene ?? this.parallaxSceneChoice);
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
    this.updatePostureSummary();
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
      wavePreviewEmptyMessage?: string;
      wallTimeSeconds?: number;
    } = {}
  ): void {
    const now = typeof performance !== "undefined" ? performance.now() : Date.now();
    const previousStatus = this.lastGameStatus;
    this.lastGameStatus = state.status;
    this.lastState = state;
    const wallTimeSeconds =
      typeof options.wallTimeSeconds === "number" && Number.isFinite(options.wallTimeSeconds)
        ? Math.max(0, options.wallTimeSeconds)
        : null;
    const timeSecondsForStats =
      wallTimeSeconds !== null ? wallTimeSeconds : Math.max(0, state.time ?? 0);
    const wpm = this.computeWpm(state, timeSecondsForStats);
    if (typeof options.lessonsCompleted === "number") {
      this.lessonsCompletedCount = Math.max(0, Math.floor(options.lessonsCompleted));
    }
    this.updateCastleBonusHint(state);
    this.refreshParentSummary(state, timeSecondsForStats);
    this.refreshMasteryCertificate(
      state,
      options.lessonsCompleted ?? 0,
      previousStatus,
      timeSecondsForStats
    );
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
    this.updateSupportBoost(state);
    this.updateEvacuation(state);
    this.renderWavePreview(
      upcoming,
      options.colorBlindFriendly,
      state.laneHazards ?? [],
      options.wavePreviewEmptyMessage ?? null
    );
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

  private setBuildCommandStatus(
    message: string,
    options: { tone?: "info" | "success" | "error"; timeoutMs?: number } = {}
  ): void {
    if (!this.buildCommandStatus) return;
    const tone = options.tone ?? "info";
    const timeoutMs =
      typeof options.timeoutMs === "number" && Number.isFinite(options.timeoutMs)
        ? Math.max(0, options.timeoutMs)
        : 2800;

    this.buildCommandStatus.textContent = message;
    this.buildCommandStatus.dataset.tone = tone;
    if (this.buildCommandStatusTimeout) {
      clearTimeout(this.buildCommandStatusTimeout);
      this.buildCommandStatusTimeout = null;
    }
    if (timeoutMs > 0) {
      this.buildCommandStatusTimeout = setTimeout(() => {
        if (!this.buildCommandStatus) return;
        this.buildCommandStatus.textContent = "";
        delete this.buildCommandStatus.dataset.tone;
        this.buildCommandStatusTimeout = null;
      }, timeoutMs);
    }
  }

  private resolveBuildSlotId(token: string): string | null {
    const raw = token?.trim?.() ?? "";
    if (!raw) return null;
    const normalized = raw.toLowerCase();

    let slotId: string | null = null;
    if (/^slot-\d+$/.test(normalized)) {
      slotId = normalized;
    } else if (/^slot\d+$/.test(normalized)) {
      slotId = `slot-${normalized.slice(4)}`;
    } else if (/^s\d+$/.test(normalized)) {
      slotId = `slot-${normalized.slice(1)}`;
    } else if (/^\d+$/.test(normalized)) {
      slotId = `slot-${normalized}`;
    }

    if (!slotId) return null;
    const exists = this.config.turretSlots.some((slot) => slot.id === slotId);
    return exists ? slotId : null;
  }

  private resolveBuildTurretTypeId(token: string): TurretTypeId | null {
    const raw = token?.trim?.() ?? "";
    if (!raw) return null;
    const normalized = raw.toLowerCase();

    const candidates = Object.keys(this.config.turretArchetypes) as TurretTypeId[];
    for (const typeId of candidates) {
      const archetype = this.config.turretArchetypes[typeId];
      const label = (archetype?.name ?? typeId).toLowerCase();
      if (normalized === typeId || normalized === label) {
        return typeId;
      }
    }

    if (normalized.length < 2) {
      return null;
    }
    const matches: TurretTypeId[] = [];
    for (const typeId of candidates) {
      const archetype = this.config.turretArchetypes[typeId];
      const label = (archetype?.name ?? typeId).toLowerCase();
      if (typeId.startsWith(normalized) || label.startsWith(normalized)) {
        matches.push(typeId);
      }
    }
    return matches.length === 1 ? matches[0] : null;
  }

  private normalizeBuildPriority(token: string): TurretTargetPriority | null {
    const raw = token?.trim?.() ?? "";
    const normalized = raw.toLowerCase();
    if (!normalized) return null;
    if (normalized === "first" || normalized === "f") return "first";
    if (normalized === "strongest" || normalized === "strong" || normalized === "s") return "strongest";
    if (normalized === "weakest" || normalized === "weak" || normalized === "w") return "weakest";
    return null;
  }

  private executeBuildCommand(raw: string): void {
    const text = raw?.trim?.() ?? "";
    if (!text) {
      this.setBuildCommandStatus('Type "help" for examples.', { tone: "info" });
      return;
    }

    const tokens = text.split(/\s+/g).filter(Boolean);
    const head = (tokens[0] ?? "").toLowerCase();

    if (head === "help" || head === "?") {
      this.setBuildCommandStatus(
        'Examples: "s0 arrow", "s0 upgrade", "s0 priority strongest", "castle repair".',
        { tone: "info", timeoutMs: 5200 }
      );
      return;
    }

    if (head === "castle" || head === "keep") {
      const action = (tokens[1] ?? "").toLowerCase();
      if (action === "upgrade" || action === "up") {
        this.callbacks.onCastleUpgrade();
        this.setBuildCommandStatus("Command sent: castle upgrade.", { tone: "success" });
        return;
      }
      if (action === "repair" || action === "heal") {
        this.callbacks.onCastleRepair();
        this.setBuildCommandStatus("Command sent: castle repair.", { tone: "success" });
        return;
      }
      this.setBuildCommandStatus('Try: "castle upgrade" or "castle repair".', { tone: "error" });
      return;
    }

    if (head === "upgrade" || head === "up") {
      const slotId = this.resolveBuildSlotId(tokens[1] ?? "");
      if (slotId) {
        this.callbacks.onUpgradeTurret(slotId);
        this.setBuildCommandStatus(`Command sent: ${this.formatSlotLabel(slotId)} upgrade.`, {
          tone: "success"
        });
      } else {
        this.callbacks.onCastleUpgrade();
        this.setBuildCommandStatus("Command sent: castle upgrade.", { tone: "success" });
      }
      return;
    }

    if (head === "repair" || head === "heal") {
      this.callbacks.onCastleRepair();
      this.setBuildCommandStatus("Command sent: castle repair.", { tone: "success" });
      return;
    }

    const slotId = this.resolveBuildSlotId(tokens[0] ?? "");
    if (!slotId) {
      this.setBuildCommandStatus(`Unknown command "${text}". Type "help".`, { tone: "error" });
      return;
    }

    const slotState = this.lastState?.turrets?.find((slot) => slot.id === slotId) ?? null;
    if (slotState && !slotState.unlocked) {
      this.showSlotMessage(slotId, "Slot locked.");
      this.setBuildCommandStatus(`${this.formatSlotLabel(slotId)} is locked.`, { tone: "error" });
      return;
    }

    const action = (tokens[1] ?? "").toLowerCase();
    if (!action) {
      this.setBuildCommandStatus(`Missing action for ${this.formatSlotLabel(slotId)}. Type "help".`, {
        tone: "error"
      });
      return;
    }

    if (action === "upgrade" || action === "up") {
      this.callbacks.onUpgradeTurret(slotId);
      this.setBuildCommandStatus(`Command sent: ${this.formatSlotLabel(slotId)} upgrade.`, {
        tone: "success"
      });
      return;
    }

    if (action === "downgrade" || action === "down" || action === "remove") {
      if (!this.callbacks.onDowngradeTurret) {
        this.setBuildCommandStatus("Downgrade unavailable in this mode.", { tone: "error" });
        return;
      }
      this.callbacks.onDowngradeTurret(slotId);
      this.setBuildCommandStatus(`Command sent: ${this.formatSlotLabel(slotId)} downgrade.`, {
        tone: "success"
      });
      return;
    }

    if (action === "priority" || action === "target") {
      const priority = this.normalizeBuildPriority(tokens[2] ?? "");
      if (!priority) {
        this.setBuildCommandStatus('Priority must be "first", "strongest", or "weakest".', {
          tone: "error"
        });
        return;
      }
      this.callbacks.onTurretPriorityChange(slotId, priority);
      this.setBuildCommandStatus(
        `Command sent: ${this.formatSlotLabel(slotId)} targeting ${this.describePriority(priority)}.`,
        { tone: "success" }
      );
      return;
    }

    const typeId = this.resolveBuildTurretTypeId(action);
    if (!typeId) {
      this.setBuildCommandStatus(`Unknown turret "${action}". Type "help".`, { tone: "error" });
      return;
    }
    this.callbacks.onPlaceTurret(slotId, typeId);
    this.setBuildCommandStatus(
      `Command sent: ${this.formatSlotLabel(slotId)} deploy ${this.getTurretDisplayName(typeId)}.`,
      { tone: "success" }
    );
  }

  showTypingErrorHint(hint: { expected: string | null; received: string | null; enemyId: string | null }): void {
    this.typingErrorHint = {
      expected: hint.expected,
      received: hint.received,
      enemyId: hint.enemyId,
      timestamp: typeof performance !== "undefined" ? performance.now() : Date.now()
    };
    this.flashCastleHealthOnError();
  }

  private flashCastleHealthOnError(): void {
    const bar = this.healthBarShell;
    if (!bar || this.reducedMotionEnabled || typeof window === "undefined") {
      return;
    }
    if (bar.dataset.errorFlash === "true") {
      delete bar.dataset.errorFlash;
      void bar.offsetWidth;
    }
    bar.dataset.errorFlash = "true";
    if (this.castleHealthFlashTimeout !== null) {
      window.clearTimeout(this.castleHealthFlashTimeout);
    }
    this.castleHealthFlashTimeout = window.setTimeout(() => {
      delete bar.dataset.errorFlash;
      this.castleHealthFlashTimeout = null;
    }, 450);
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
    const layoutId =
      typeof this.virtualKeyboardLayout === "string" && this.virtualKeyboardLayout.length > 0
        ? this.virtualKeyboardLayout.toLowerCase()
        : "qwerty";
    const lookup = FINGER_LOOKUP_BY_LAYOUT[layoutId] ?? FINGER_LOOKUP_BY_LAYOUT.qwerty;
    const finger = lookup[normalizedKey];
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

  private initializeBattleLogControls(rootIds: {
    eventLogSummary?: string;
    eventLogFilters?: string;
  }): void {
    if (typeof document === "undefined") return;
    const summaryId = rootIds.eventLogSummary ?? "battle-log-summary";
    const summaryElement = document.getElementById(summaryId);
    if (summaryElement instanceof HTMLElement) {
      const summaryButtons = Array.from(
        summaryElement.querySelectorAll<HTMLButtonElement>("[data-category]")
      );
      for (const button of summaryButtons) {
        const category = button.dataset.category;
        if (!isBattleLogFilterCategory(category)) continue;
        const count = button.querySelector<HTMLElement>(".battle-log-summary-count");
        const last = button.querySelector<HTMLElement>(".battle-log-summary-last");
        if (!count || !last) continue;
        this.logSummaryItems.set(category, { button, count, last });
        button.setAttribute("aria-pressed", "false");
        button.addEventListener("click", () => {
          this.toggleLogFilter(category, { exclusive: true });
        });
      }
    }

    const filtersId = rootIds.eventLogFilters ?? "battle-log-filters";
    const filtersElement = document.getElementById(filtersId);
    if (filtersElement instanceof HTMLElement) {
      const filterButtons = Array.from(
        filtersElement.querySelectorAll<HTMLButtonElement>("[data-category]")
      );
      for (const button of filterButtons) {
        const category = button.dataset.category;
        if (!isBattleLogFilterCategory(category)) continue;
        this.logFilterButtons.set(category, button);
        button.setAttribute("aria-pressed", "false");
        button.addEventListener("click", () => {
          this.toggleLogFilter(category);
        });
      }
      const clearButton = filtersElement.querySelector<HTMLButtonElement>("[data-action='clear']");
      if (clearButton) {
        this.logFilterClearButton = clearButton;
        clearButton.addEventListener("click", () => {
          this.clearLogFilters();
        });
      }
    }
    this.syncBattleLogFilters();
    this.updateBattleLogSummary();
  }

  private toggleLogFilter(
    category: BattleLogFilterCategory,
    options: { exclusive?: boolean } = {}
  ): void {
    const isActive = this.logFilterState.has(category);
    if (options.exclusive) {
      if (isActive && this.logFilterState.size === 1) {
        this.logFilterState.clear();
      } else {
        this.logFilterState.clear();
        this.logFilterState.add(category);
      }
    } else if (isActive) {
      this.logFilterState.delete(category);
    } else {
      this.logFilterState.add(category);
    }
    this.syncBattleLogFilters();
    this.renderLog();
  }

  private clearLogFilters(): void {
    if (this.logFilterState.size === 0) {
      return;
    }
    this.logFilterState.clear();
    this.syncBattleLogFilters();
    this.renderLog();
  }

  private syncBattleLogFilters(): void {
    const hasFilters = this.logFilterState.size > 0;
    for (const [category, button] of this.logFilterButtons.entries()) {
      const active = this.logFilterState.has(category);
      button.dataset.active = active ? "true" : "false";
      button.setAttribute("aria-pressed", active ? "true" : "false");
    }
    for (const [category, summary] of this.logSummaryItems.entries()) {
      const active = this.logFilterState.has(category);
      summary.button.dataset.active = active ? "true" : "false";
      summary.button.setAttribute("aria-pressed", active ? "true" : "false");
    }
    if (this.logFilterClearButton) {
      this.logFilterClearButton.disabled = !hasFilters;
      this.logFilterClearButton.setAttribute("aria-disabled", hasFilters ? "false" : "true");
    }
  }

  private updateBattleLogSummary(category?: BattleLogFilterCategory): void {
    const categories = category ? [category] : BATTLE_LOG_FILTERS;
    for (const key of categories) {
      const summary = this.logSummary[key];
      const item = this.logSummaryItems.get(key);
      if (!item) continue;
      item.count.textContent = String(summary.count);
      item.last.textContent = summary.lastMessage ?? BATTLE_LOG_EMPTY_LABELS[key];
      item.last.dataset.empty = summary.lastMessage ? "false" : "true";
    }
  }

  private recordLogSummary(entry: BattleLogEntry): void {
    const summary = this.logSummary[entry.category];
    summary.count += 1;
    summary.lastMessage = entry.message;
    if (isBattleLogFilterCategory(entry.category)) {
      this.updateBattleLogSummary(entry.category);
    }
  }

  appendLog(message: string, category: BattleLogCategory = "system"): void {
    this.logEntries.unshift({
      message,
      category,
      timestamp: Date.now()
    });
    if (this.logEntries.length > this.logLimit) {
      this.logEntries.length = this.logLimit;
    }
    this.recordLogSummary(this.logEntries[0]);
    this.renderLog();
  }

  setTutorialMessage(message: string | null, highlight?: boolean): void {
    const banner = this.tutorialBanner;
    if (!banner) return;
    const { container, message: content } = banner;
    const condensed = this.shouldCondenseTutorialBanner();
    const wasVisible = container.dataset.visible === "true";
    if (!message) {
      this.lastTutorialMessage = null;
      this.tutorialHintDismissed = false;
      container.dataset.visible = "false";
      container.setAttribute("aria-hidden", "true");
      content.textContent = "";
      delete container.dataset.highlight;
      this.tutorialBannerExpanded = condensed ? false : true;
      this.refreshTutorialBannerLayout();
      return;
    }
    if (message !== this.lastTutorialMessage) {
      this.lastTutorialMessage = message;
      this.tutorialHintDismissed = false;
    }
    if (highlight) {
      container.dataset.highlight = "true";
    } else {
      delete container.dataset.highlight;
    }
    content.textContent = message;
    const visible = !this.tutorialHintDismissed;
    container.dataset.visible = visible ? "true" : "false";
    container.setAttribute("aria-hidden", visible ? "false" : "true");
    if (visible && !wasVisible) {
      this.tutorialBannerExpanded = condensed ? false : true;
    } else if (visible && !condensed) {
      this.tutorialBannerExpanded = true;
    }
    this.refreshTutorialBannerLayout();
  }

  setTutorialProgress(progress: TutorialProgress | null): void {
    const banner = this.tutorialBanner;
    if (!banner || !banner.progress) return;
    const progressButton = banner.progress;
    if (!progress) {
      progressButton.hidden = true;
      progressButton.textContent = "";
      progressButton.removeAttribute("aria-label");
      progressButton.removeAttribute("title");
      this.tutorialProgressKey = null;
      if (banner.container) {
        delete banner.container.dataset.anchor;
      }
      this.refreshTutorialDockLayout();
      return;
    }
    const label = progress.label?.trim() || "Tutorial";
    const text = `Step ${progress.index}/${progress.total} - ${label}`;
    if (this.tutorialProgressKey === text) {
      progressButton.hidden = false;
      if (progress.anchor) {
        banner.container.dataset.anchor = progress.anchor;
      }
      return;
    }
    this.tutorialProgressKey = text;
    progressButton.hidden = false;
    progressButton.textContent = text;
    progressButton.setAttribute("aria-label", `Tutorial progress: ${text}`);
    progressButton.title = text;
    if (progress.anchor) {
      banner.container.dataset.anchor = progress.anchor;
    }
    this.refreshTutorialDockLayout();
  }

  setTutorialDock(state: TutorialDockState | null): void {
    const dock = this.tutorialDock;
    if (!dock) return;
    if (!state || !state.active || state.steps.length === 0) {
      dock.container.hidden = true;
      this.tutorialDockStateKey = null;
      return;
    }
    dock.container.hidden = false;
    this.tutorialDockLabels = new Map(state.steps.map((step) => [step.id, step.label]));
    const nextKey = state.steps.map((step) => `${step.id}:${step.status}`).join("|");
    if (nextKey !== this.tutorialDockStateKey) {
      dock.steps.replaceChildren();
      for (const step of state.steps) {
        const item = document.createElement("li");
        item.dataset.status = step.status;
        const button = document.createElement("button");
        button.type = "button";
        button.dataset.stepId = step.id;
        button.textContent = step.label;
        if (step.status === "active") {
          button.setAttribute("aria-current", "step");
        }
        item.appendChild(button);
        dock.steps.appendChild(item);
      }
      this.tutorialDockStateKey = nextKey;
    }
    this.refreshTutorialDockLayout();
  }

  private dismissTutorialHint(): void {
    if (!this.tutorialBanner) return;
    this.tutorialHintDismissed = true;
    this.tutorialBanner.container.dataset.visible = "false";
    this.tutorialBanner.container.setAttribute("aria-hidden", "true");
    this.refreshTutorialBannerLayout();
  }

  private readTutorialDockCollapsed(): boolean {
    if (typeof window === "undefined" || !window.localStorage) return false;
    try {
      return window.localStorage.getItem(this.tutorialDockStorageKey) === "true";
    } catch {
      return false;
    }
  }

  private persistTutorialDockCollapsed(): void {
    if (typeof window === "undefined" || !window.localStorage) return;
    try {
      window.localStorage.setItem(
        this.tutorialDockStorageKey,
        this.tutorialDockCollapsed ? "true" : "false"
      );
    } catch {
      // ignore storage failures
    }
  }

  private refreshTutorialDockLayout(): void {
    const dock = this.tutorialDock;
    if (!dock || dock.container.hidden) return;
    dock.container.dataset.collapsed = this.tutorialDockCollapsed ? "true" : "false";
    dock.toggle.setAttribute("aria-expanded", this.tutorialDockCollapsed ? "false" : "true");
    if (dock.summary) {
      dock.summary.textContent = this.tutorialProgressKey ?? "";
    }
  }

  private showTutorialDockModal(stepId: string): void {
    if (!this.tutorialDockModal) return;
    const label = this.tutorialDockLabels.get(stepId) ?? "Tutorial step";
    this.tutorialDockModal.stepId = stepId;
    this.tutorialDockModal.copy.textContent = `Replay "${label}" now? Your current step progress will reset.`;
    this.tutorialDockModal.container.dataset.visible = "true";
    this.tutorialDockModal.container.setAttribute("aria-hidden", "false");
    this.tutorialDockModal.confirm.focus();
  }

  private confirmTutorialDockModal(): void {
    if (!this.tutorialDockModal) return;
    const stepId = this.tutorialDockModal.stepId;
    if (stepId) {
      this.callbacks.onTutorialStepReplay?.(stepId);
    }
    this.hideTutorialDockModal();
  }

  private hideTutorialDockModal(): void {
    if (!this.tutorialDockModal) return;
    this.tutorialDockModal.container.dataset.visible = "false";
    this.tutorialDockModal.container.setAttribute("aria-hidden", "true");
    this.tutorialDockModal.stepId = null;
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

  setWavePreviewThreatIndicatorsEnabled(enabled: boolean): void {
    const next = Boolean(enabled);
    if (this.wavePreviewThreatIndicatorsEnabled === next) {
      return;
    }
    this.wavePreviewThreatIndicatorsEnabled = next;
    if (this.lastWavePreviewEntries.length > 0) {
      this.wavePreview.render(this.lastWavePreviewEntries, {
        colorBlindFriendly: this.lastWavePreviewColorBlind,
        selectedTierId: this.selectedEnemyBioId,
        onSelect: (tierId) => this.handleEnemyBioSelect(tierId),
        showThreatIndicators: this.wavePreviewThreatIndicatorsEnabled,
        laneHazards: this.lastWavePreviewLaneHazards,
        emptyMessage: this.lastWavePreviewEmptyMessage
      });
    }
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

  flashWavePreviewLane(lane: number): void {
    if (!Number.isFinite(lane)) return;
    const targetLane = Math.max(0, Math.floor(lane));
    const duration = 650;
    this.wavePreviewFreezeUntil = Date.now() + duration;
    this.wavePreview.flashLane(targetLane, { durationMs: duration });
  }

  private renderWavePreview(
    entries: WaveSpawnPreview[],
    colorBlindFriendly: boolean | undefined,
    laneHazards: LaneHazardState[] | undefined,
    emptyMessage: string | null
  ): void {
    const snapshot: WavePreviewSnapshot = {
      entries,
      colorBlindFriendly: Boolean(colorBlindFriendly),
      laneHazards: Array.isArray(laneHazards) ? laneHazards : [],
      emptyMessage: typeof emptyMessage === "string" ? emptyMessage : null
    };
    if (Date.now() < this.wavePreviewFreezeUntil) {
      this.pendingWavePreviewState = snapshot;
      return;
    }
    const nextSnapshot = this.pendingWavePreviewState ?? snapshot;
    this.pendingWavePreviewState = null;
    this.lastWavePreviewEntries = nextSnapshot.entries;
    this.lastWavePreviewColorBlind = nextSnapshot.colorBlindFriendly;
    this.lastWavePreviewLaneHazards = nextSnapshot.laneHazards;
    this.lastWavePreviewEmptyMessage = nextSnapshot.emptyMessage;
    const selected = this.syncEnemyBioSelection(nextSnapshot.entries);
    this.wavePreview.render(nextSnapshot.entries, {
      colorBlindFriendly: this.lastWavePreviewColorBlind,
      selectedTierId: selected,
      onSelect: (tierId) => this.handleEnemyBioSelect(tierId),
      showThreatIndicators: this.wavePreviewThreatIndicatorsEnabled,
      laneHazards: this.lastWavePreviewLaneHazards,
      emptyMessage: this.lastWavePreviewEmptyMessage
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
        onSelect: (nextTier) => this.handleEnemyBioSelect(nextTier),
        showThreatIndicators: this.wavePreviewThreatIndicatorsEnabled,
        laneHazards: this.lastWavePreviewLaneHazards,
        emptyMessage: this.lastWavePreviewEmptyMessage
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
    const hazardsByLane = new Map<number, LaneHazardState>();
    const nextHazardKinds = new Map<number, string>();
    for (const hazard of state.laneHazards ?? []) {
      hazardsByLane.set(hazard.lane, hazard);
      if (typeof hazard.kind === "string" && hazard.kind.length > 0) {
        nextHazardKinds.set(hazard.lane, hazard.kind);
      }
    }
    for (const slot of state.turrets) {
      const controls = this.slotControls.get(slot.id);
      if (!controls) continue;

      controls.titleText.textContent = `Slot ${slot.id.replace("slot-", "")} (Lane ${slot.lane + 1})`;

      const laneHazard = hazardsByLane.get(slot.lane);
      const previousHazardKind = this.lastLaneHazardKinds.get(slot.lane) ?? null;
      const nextHazardKind =
        laneHazard && typeof laneHazard.kind === "string" && laneHazard.kind.length > 0
          ? laneHazard.kind
          : null;
      if (laneHazard && typeof laneHazard.kind === "string" && laneHazard.kind.length > 0) {
        const hazardLabel = this.formatTitleLabel(laneHazard.kind);
        const remainingLabel = this.formatSeconds(Math.max(0, laneHazard.remaining));
        const fireRateEffect = this.formatFireRateEffect(laneHazard.fireRateMultiplier);
        const detail = fireRateEffect
          ? `${hazardLabel} active (${remainingLabel} left, ${fireRateEffect})`
          : `${hazardLabel} active (${remainingLabel} left)`;
        controls.hazardBadge.dataset.visible = "true";
        controls.hazardBadge.setAttribute("aria-hidden", "false");
        controls.hazardBadge.dataset.hazard = laneHazard.kind;
        controls.hazardBadge.textContent = hazardLabel;
        controls.hazardBadge.title = detail;
        controls.hazardBadge.setAttribute("aria-label", detail);
        if (nextHazardKind && nextHazardKind !== previousHazardKind) {
          this.pulseHazardBadge(slot.id, controls.hazardBadge);
        }
      } else {
        controls.hazardBadge.dataset.visible = "false";
        controls.hazardBadge.setAttribute("aria-hidden", "true");
        delete controls.hazardBadge.dataset.hazard;
        controls.hazardBadge.textContent = "";
        controls.hazardBadge.removeAttribute("title");
        controls.hazardBadge.removeAttribute("aria-label");
      }
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
    this.lastLaneHazardKinds.clear();
    for (const [lane, kind] of nextHazardKinds) {
      this.lastLaneHazardKinds.set(lane, kind);
    }
  }

  private pulseHazardBadge(slotId: string, badge: HTMLElement): void {
    if (!badge || this.reducedMotionEnabled || typeof window === "undefined") {
      return;
    }
    if (badge.dataset.pulse === "true") {
      delete badge.dataset.pulse;
      void badge.offsetWidth;
    }
    badge.dataset.pulse = "true";
    const existing = this.hazardPulseTimeouts.get(slotId);
    if (existing) {
      window.clearTimeout(existing);
    }
    const timeout = window.setTimeout(() => {
      delete badge.dataset.pulse;
      this.hazardPulseTimeouts.delete(slotId);
    }, 560);
    this.hazardPulseTimeouts.set(slotId, timeout);
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
      const titleText = document.createElement("span");
      titleText.className = "slot-title-text";
      titleText.textContent = `Slot ${slot.id.replace("slot-", "")} (Lane ${slot.lane + 1})`;
      title.appendChild(titleText);
      const hazardBadge = document.createElement("span");
      hazardBadge.className = "slot-hazard";
      hazardBadge.dataset.visible = "false";
      hazardBadge.setAttribute("aria-hidden", "true");
      title.appendChild(hazardBadge);
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
        titleText,
        hazardBadge,
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
    const hasFilters = this.logFilterState.size > 0;
    const entries = hasFilters
      ? this.logEntries.filter(
          (entry) =>
            isBattleLogFilterCategory(entry.category) && this.logFilterState.has(entry.category)
        )
      : this.logEntries;
    this.logList.replaceChildren();
    if (entries.length === 0) {
      const empty = document.createElement("li");
      empty.className = "battle-log-empty";
      empty.textContent =
        this.logEntries.length === 0
          ? "No battle log entries yet."
          : "No events match the current filters.";
      this.logList.appendChild(empty);
      return;
    }
    for (const entry of entries) {
      const item = document.createElement("li");
      item.textContent = entry.message;
      item.dataset.category = entry.category;
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

    const coach = data.coach ?? null;
    const coachContainer = this.waveScorecard.coach;
    const drillSuggestion = coach?.drill ?? null;
    if (coachContainer && this.waveScorecard.coachList) {
      if (coach && typeof coach.win === "string" && typeof coach.gap === "string") {
        coachContainer.dataset.visible = "true";
        coachContainer.setAttribute("aria-hidden", "false");
        this.setWaveScorecardCoachField("win", "Biggest Win", coach.win);
        this.setWaveScorecardCoachField("gap", "Biggest Gap", coach.gap);
        const drillLine = drillSuggestion
          ? `${drillSuggestion.label}: ${drillSuggestion.reason}`
          : "No drill suggestion available.";
        this.setWaveScorecardCoachField("drill", "Suggested Drill", drillLine);
      } else {
        coachContainer.dataset.visible = "false";
        coachContainer.setAttribute("aria-hidden", "true");
        for (const item of Array.from(this.waveScorecard.coachList.children)) {
          item.textContent = "";
        }
      }
    }

    if (this.waveScorecard.drillBtn) {
      this.waveScorecard.suggestedDrill = drillSuggestion;
      if (drillSuggestion) {
        this.waveScorecard.drillBtn.textContent = `Run ${drillSuggestion.label}`;
        this.waveScorecard.drillBtn.dataset.visible = "true";
        this.waveScorecard.drillBtn.setAttribute("aria-hidden", "false");
        this.waveScorecard.drillBtn.disabled = false;
        this.waveScorecard.drillBtn.tabIndex = 0;
      } else {
        this.waveScorecard.drillBtn.textContent = "Run Suggested Drill";
        this.waveScorecard.drillBtn.dataset.visible = "false";
        this.waveScorecard.drillBtn.setAttribute("aria-hidden", "true");
        this.waveScorecard.drillBtn.disabled = true;
        this.waveScorecard.drillBtn.tabIndex = -1;
      }
    } else if (this.waveScorecard) {
      this.waveScorecard.suggestedDrill = drillSuggestion;
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

  private setWaveScorecardCoachField(field: string, label: string, value: string): void {
    if (!this.waveScorecard?.coachList) return;
    const items = Array.from(this.waveScorecard.coachList.children) as HTMLElement[];
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

  private showDropoffOverlay(trigger?: HTMLElement): void {
    if (!this.dropoffOverlay) return;
    this.dropoffOverlayTrigger = trigger ?? null;
    this.dropoffOverlay.container.dataset.visible = "true";
    this.dropoffOverlay.container.setAttribute("aria-hidden", "false");
    this.dropoffOverlay.closeButton.focus();
  }

  private hideDropoffOverlay(): void {
    if (!this.dropoffOverlay) return;
    this.dropoffOverlay.container.dataset.visible = "false";
    this.dropoffOverlay.container.setAttribute("aria-hidden", "true");
    const target = this.dropoffOverlayTrigger;
    this.dropoffOverlayTrigger = null;
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
    const queueDownloadButton = this.optionsOverlay.telemetryQueueDownloadButton;
    const queueClearButton = this.optionsOverlay.telemetryQueueClearButton;
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
      if (queueDownloadButton) {
        queueDownloadButton.style.display = "none";
        queueDownloadButton.disabled = true;
        queueDownloadButton.tabIndex = -1;
        queueDownloadButton.setAttribute("aria-hidden", "true");
      }
      if (queueClearButton) {
        queueClearButton.style.display = "none";
        queueClearButton.disabled = true;
        queueClearButton.tabIndex = -1;
        queueClearButton.setAttribute("aria-hidden", "true");
      }
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
    if (queueDownloadButton) {
      queueDownloadButton.style.display = "";
      queueDownloadButton.disabled = false;
      queueDownloadButton.tabIndex = 0;
      queueDownloadButton.setAttribute("aria-hidden", "false");
    }
    if (queueClearButton) {
      queueClearButton.style.display = "";
      queueClearButton.disabled = false;
      queueClearButton.tabIndex = 0;
      queueClearButton.setAttribute("aria-hidden", "false");
    }
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

  private updateMusicLevelDisplay(level: number): void {
    if (!this.optionsOverlay?.musicLevelValue) return;
    const percent = Math.round(level * 100);
    this.optionsOverlay.musicLevelValue.textContent = `${percent}%`;
  }

  private updateTutorialPacingDisplay(scale: number): void {
    if (!this.optionsOverlay?.tutorialPacingValue) return;
    const percent = Math.round(scale * 100);
    this.optionsOverlay.tutorialPacingValue.textContent = `${percent}% speed`;
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

  setDayNightTheme(mode: DayNightMode): void {
    const normalized: DayNightMode = mode === "day" ? "day" : "night";
    this.dayNightTheme = normalized;
    this.applyDayNightTheme(normalized);
    if (this.parallaxSceneChoice === "auto") {
      this.applyParallaxScene(this.resolveParallaxScene(this.parallaxSceneChoice));
    }
    const select =
      this.optionsOverlay?.dayNightThemeSelect ??
      (document.getElementById("options-day-night-theme") as HTMLSelectElement | null);
    if (select) {
      this.setSelectValue(select, normalized);
    }
  }

  setParallaxScene(scene: ParallaxScene, resolved?: ResolvedParallaxScene): void {
    const normalized: ParallaxScene =
      scene === "day" || scene === "night" || scene === "storm" ? scene : "auto";
    this.parallaxSceneChoice = normalized;
    const active = resolved ?? this.resolveParallaxScene(normalized);
    this.applyParallaxScene(active);
    const select =
      this.optionsOverlay?.parallaxSceneSelect ??
      (document.getElementById("options-parallax-scene") as HTMLSelectElement | null);
    if (select) {
      this.setSelectValue(select, normalized);
    }
  }

  private resolveParallaxScene(scene: ParallaxScene): ResolvedParallaxScene {
    if (scene === "day") return "day";
    if (scene === "storm") return "storm";
    if (scene === "night") return "night";
    return this.dayNightTheme === "day" ? "day" : "night";
  }

  private applyParallaxScene(scene: ResolvedParallaxScene): void {
    const resolved: ResolvedParallaxScene =
      scene === "storm" ? "storm" : scene === "day" ? "day" : "night";
    this.parallaxSceneResolved = resolved;
    if (typeof document !== "undefined") {
      if (document.documentElement) {
        document.documentElement.dataset.parallaxScene = resolved;
      }
      if (document.body) {
        document.body.dataset.parallaxScene = resolved;
      }
    }
    if (this.hudRoot) {
      this.hudRoot.dataset.parallaxScene = resolved;
    }
    if (this.parallaxShell) {
      this.parallaxShell.dataset.scene = resolved;
    }
  }

  setParallaxMotionPaused(paused: boolean): void {
    this.parallaxPaused = paused;
    if (typeof document !== "undefined") {
      if (document.documentElement) {
        if (paused) {
          document.documentElement.dataset.parallaxPaused = "true";
        } else {
          document.documentElement.removeAttribute("data-parallax-paused");
        }
      }
      if (document.body) {
        if (paused) {
          document.body.dataset.parallaxPaused = "true";
        } else {
          document.body.removeAttribute("data-parallax-paused");
        }
      }
    }
    if (this.parallaxShell) {
      if (paused) {
        this.parallaxShell.dataset.paused = "true";
      } else {
        this.parallaxShell.removeAttribute("data-paused");
      }
    }
  }

  showMusicOverlay(): void {
    if (!this.musicOverlay) return;
    this.musicOverlay.container.dataset.visible = "true";
    this.musicOverlay.container.setAttribute("aria-hidden", "false");
    this.renderMusicOverlay(this.musicStemState ?? this.getEmptyMusicState());
    const focusable = this.getFocusableElements(this.musicOverlay.container);
    focusable[0]?.focus();
  }

  hideMusicOverlay(): void {
    if (!this.musicOverlay) return;
    this.musicOverlay.container.dataset.visible = "false";
    this.musicOverlay.container.setAttribute("aria-hidden", "true");
  }

  showUiSoundOverlay(): void {
    if (!this.uiSoundOverlay) return;
    this.uiSoundOverlay.container.dataset.visible = "true";
    this.uiSoundOverlay.container.setAttribute("aria-hidden", "false");
    this.renderUiSoundOverlay(this.uiSoundSchemeState ?? this.getEmptyUiSoundState());
    const focusable = this.getFocusableElements(this.uiSoundOverlay.container);
    focusable[0]?.focus();
  }

  hideUiSoundOverlay(): void {
    if (!this.uiSoundOverlay) return;
    this.uiSoundOverlay.container.dataset.visible = "false";
    this.uiSoundOverlay.container.setAttribute("aria-hidden", "true");
  }

  showSfxOverlay(): void {
    if (!this.sfxOverlay) return;
    this.sfxOverlay.container.dataset.visible = "true";
    this.sfxOverlay.container.setAttribute("aria-hidden", "false");
    this.renderSfxOverlay(this.sfxLibraryState ?? this.getEmptySfxLibraryState());
    const focusable = this.getFocusableElements(this.sfxOverlay.container);
    focusable[0]?.focus();
  }

  hideSfxOverlay(): void {
    if (!this.sfxOverlay) return;
    this.sfxOverlay.container.dataset.visible = "false";
    this.sfxOverlay.container.setAttribute("aria-hidden", "true");
  }

  showReadabilityOverlay(): void {
    if (!this.readabilityOverlay) return;
    this.renderReadabilityGuide();
    this.readabilityOverlay.container.dataset.visible = "true";
    this.readabilityOverlay.container.setAttribute("aria-hidden", "false");
    const focusable = this.getFocusableElements(this.readabilityOverlay.container);
    focusable[0]?.focus();
  }

  hideReadabilityOverlay(): void {
    if (!this.readabilityOverlay) return;
    this.readabilityOverlay.container.dataset.visible = "false";
    this.readabilityOverlay.container.setAttribute("aria-hidden", "true");
  }

  showSubtitleOverlay(): void {
    if (!this.subtitleOverlay) return;
    this.syncSubtitleOverlayState();
    this.subtitleOverlay.container.dataset.visible = "true";
    this.subtitleOverlay.container.setAttribute("aria-hidden", "false");
    const focusable = this.getFocusableElements(this.subtitleOverlay.container);
    (this.subtitleOverlay.toggle as HTMLElement | undefined)?.focus() ??
      focusable[0]?.focus();
  }

  hideSubtitleOverlay(): void {
    if (!this.subtitleOverlay) return;
    this.subtitleOverlay.container.dataset.visible = "false";
    this.subtitleOverlay.container.setAttribute("aria-hidden", "true");
    this.optionsOverlay?.subtitlePreviewButton?.focus();
  }

  private syncSubtitleOverlayState(): void {
    if (!this.subtitleOverlay) return;
    if (this.subtitleOverlay.toggle) {
      this.subtitleOverlay.toggle.checked = this.subtitleLargeEnabled;
    }
    if (this.subtitleOverlay.summary) {
      this.subtitleOverlay.summary.textContent = this.subtitleLargeEnabled
        ? "Large subtitles enabled. All subtitle lines render at larger sizes with extra contrast."
        : "Normal subtitles active. Enable large subtitles to boost size and contrast.";
    }
    if (this.subtitleOverlay.samples) {
      for (const sample of this.subtitleOverlay.samples) {
        sample.dataset.size = this.subtitleLargeEnabled ? "large" : "normal";
      }
    }
  }

  showLayoutOverlay(): void {
    if (!this.layoutOverlay) return;
    this.syncLayoutOverlayState();
    this.layoutOverlay.container.dataset.visible = "true";
    this.layoutOverlay.container.setAttribute("aria-hidden", "false");
    const focusable = this.getFocusableElements(this.layoutOverlay.container);
    const target =
      (this.hudLayoutSide === "left" ? this.layoutOverlay.leftApply : this.layoutOverlay.rightApply) ??
      focusable[0];
    target?.focus();
  }

  hideLayoutOverlay(): void {
    if (!this.layoutOverlay) return;
    this.layoutOverlay.container.dataset.visible = "false";
    this.layoutOverlay.container.setAttribute("aria-hidden", "true");
    this.optionsOverlay?.layoutPreviewButton?.focus();
  }

  private syncLayoutOverlayState(): void {
    if (!this.layoutOverlay) return;
    const isLeft = this.hudLayoutSide === "left";
    this.layoutOverlay.leftCard.dataset.active = isLeft ? "true" : "false";
    this.layoutOverlay.rightCard.dataset.active = isLeft ? "false" : "true";
    if (this.layoutOverlay.summary) {
      this.layoutOverlay.summary.textContent = isLeft
        ? "Left-handed layout active. HUD anchors left; canvas stays on the right."
        : "Right-handed layout active. HUD anchors right; canvas stays on the left.";
    }
  }

  private applyLayoutPreview(side: "left" | "right"): void {
    this.setHudLayoutSide(side);
    this.callbacks.onHudLayoutToggle?.(side === "left");
    this.hideLayoutOverlay();
  }

  showPostureOverlay(): void {
    if (!this.postureOverlay) return;
    this.postureOverlay.container.dataset.visible = "true";
    this.postureOverlay.container.setAttribute("aria-hidden", "false");
    this.renderPostureOverlay();
    const focusable = this.getFocusableElements(this.postureOverlay.container);
    focusable[0]?.focus();
  }

  hidePostureOverlay(): void {
    if (!this.postureOverlay) return;
    this.postureOverlay.container.dataset.visible = "false";
    this.postureOverlay.container.setAttribute("aria-hidden", "true");
  }

  private renderPostureOverlay(): void {
    this.updatePostureOverlayStatus();
    this.updatePostureSummary();
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

  private markPostureReviewed(): void {
    this.postureLastReviewed = Date.now();
    this.clearPostureReminder();
    this.updatePostureOverlayStatus("Reviewed just now.");
    this.updatePostureSummary();
    this.appendLog("Posture checklist reviewed.");
  }

  private startPostureReminder(minutes = 5): void {
    const durationMs = Math.max(1, minutes) * 60_000;
    this.clearPostureReminder();
    this.postureReminderTarget = Date.now() + durationMs;
    this.postureReminderTimeout = window.setTimeout(
      () => this.handlePostureReminderFired(),
      durationMs
    );
    this.postureReminderInterval = window.setInterval(
      () => this.updatePostureOverlayStatus(),
      1000
    );
    const minutesLabel = Math.round(durationMs / 60_000);
    this.updatePostureOverlayStatus(
      `Reminder in ${this.formatPostureCountdown(this.postureReminderTarget)}.`
    );
    this.updatePostureSummary();
    this.appendLog(`Posture reminder set for ${minutesLabel} minute${minutesLabel === 1 ? "" : "s"}.`);
  }

  private handlePostureReminderFired(): void {
    this.postureReminderTarget = null;
    if (this.postureReminderInterval) {
      clearInterval(this.postureReminderInterval);
      this.postureReminderInterval = null;
    }
    this.showPostureReminder(
      "Quick posture reset: feet flat, wrists lifted, shoulders relaxed, screen at eye height."
    );
    this.updatePostureOverlayStatus("Reminder ready now.");
    this.updatePostureSummary();
  }

  private clearPostureReminder(hideToast = true): void {
    if (this.postureReminderTimeout) {
      clearTimeout(this.postureReminderTimeout);
      this.postureReminderTimeout = null;
    }
    if (this.postureReminderInterval) {
      clearInterval(this.postureReminderInterval);
      this.postureReminderInterval = null;
    }
    this.postureReminderTarget = null;
    if (hideToast && this.postureReminder) {
      this.postureReminder.container.dataset.visible = "false";
      this.postureReminder.container.setAttribute("aria-hidden", "true");
    }
    this.updatePostureOverlayStatus();
    this.updatePostureSummary();
  }

  private updatePostureOverlayStatus(message?: string): void {
    if (this.postureOverlay?.status) {
      if (message) {
        this.postureOverlay.status.textContent = message;
      } else if (this.postureReminderTarget) {
        this.postureOverlay.status.textContent = `Reminder in ${this.formatPostureCountdown(
          this.postureReminderTarget
        )}.`;
      } else if (this.postureLastReviewed) {
        this.postureOverlay.status.textContent = `Last reviewed ${this.describeElapsedTime(
          this.postureLastReviewed
        )}.`;
      } else {
        this.postureOverlay.status.textContent = "No reminder active.";
      }
    }
  }

  private updatePostureSummary(): void {
    const summary = this.optionsOverlay?.postureChecklistSummary;
    if (!summary) return;
    if (this.postureReminderTarget) {
      summary.textContent = `Posture reminder in ${this.formatPostureCountdown(
        this.postureReminderTarget
      )}.`;
      return;
    }
    if (this.postureLastReviewed) {
      summary.textContent = `Last checked ${this.describeElapsedTime(this.postureLastReviewed)}.`;
      return;
    }
    summary.textContent = "Quick posture review and 5-minute micro-reminder.";
  }

  private showPostureReminder(message?: string): void {
    if (!this.postureReminder) return;
    if (message && this.postureReminder.tip) {
      this.postureReminder.tip.textContent = message;
    }
    this.postureReminder.container.dataset.visible = "true";
    this.postureReminder.container.setAttribute("aria-hidden", "false");
  }

  private describeElapsedTime(timestamp: number | null): string {
    if (!timestamp || Number.isNaN(timestamp)) return "just now";
    const deltaMs = Date.now() - timestamp;
    if (deltaMs < 30_000) return "just now";
    const minutes = Math.floor(deltaMs / 60_000);
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
  }

  private formatPostureCountdown(target: number | null): string {
    if (!target) return "00:00";
    const remaining = Math.max(0, target - Date.now());
    const totalSeconds = Math.floor(remaining / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
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

  private readMasteryCertificateMilestoneShown(): boolean {
    if (typeof window === "undefined" || !window.localStorage) return false;
    try {
      return window.localStorage.getItem(MASTERY_CERTIFICATE_MILESTONE_SHOWN_KEY) === "true";
    } catch {
      return false;
    }
  }

  private readMilestoneCelebrationsDisabled(): boolean {
    if (typeof window === "undefined") return false;
    const read = (storage: Storage | undefined | null): boolean => {
      if (!storage) return false;
      try {
        return storage.getItem(MILESTONE_CELEBRATIONS_DISABLED_KEY) === "true";
      } catch {
        return false;
      }
    };

    return read(window.localStorage) || read(window.sessionStorage);
  }

  private persistCertificateName(name: string): void {
    if (typeof window === "undefined" || !window.localStorage) return;
    try {
      window.localStorage.setItem(CERTIFICATE_NAME_KEY, name);
    } catch {
      // ignore storage write failures
    }
  }

  private persistMasteryCertificateMilestoneShown(shown: boolean): void {
    if (typeof window === "undefined" || !window.localStorage) return;
    try {
      window.localStorage.setItem(
        MASTERY_CERTIFICATE_MILESTONE_SHOWN_KEY,
        shown ? "true" : "false"
      );
    } catch {
      // ignore storage write failures
    }
  }

  private persistMilestoneCelebrationsDisabled(disabled: boolean): void {
    if (typeof window === "undefined") return;
    const write = (storage: Storage | undefined | null): void => {
      if (!storage) return;
      try {
        storage.setItem(MILESTONE_CELEBRATIONS_DISABLED_KEY, disabled ? "true" : "false");
      } catch {
        // ignore storage write failures
      }
    };

    write(window.localStorage);
    write(window.sessionStorage);
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
    force?: boolean;
  }): void {
    if (!this.milestoneCelebration) return;
    if (this.milestoneCelebrationsDisabled) return;
    const reducedCognitiveLoad =
      this.hudRoot?.dataset.cognitiveMode === "reduced" ||
      (typeof document !== "undefined" && document.body?.dataset.cognitiveMode === "reduced");
    if (reducedCognitiveLoad) return;
    const now = Date.now();
    const key = `${options.tone ?? "default"}|${options.title}|${options.detail}`;
    const tooSoon = !options.force && this.lastMilestoneKey === key && now - this.lastMilestoneAt < 8000;
    if (tooSoon) {
      return;
    }
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
    this.lastMilestoneKey = key;
    this.lastMilestoneAt = now;
  }

  hideMilestoneCelebration(): void {
    if (!this.milestoneCelebration) return;
    const timerHost: Partial<typeof globalThis> =
      typeof window !== "undefined" ? window : globalThis;
    this.milestoneCelebration.container.dataset.visible = "false";
    this.milestoneCelebration.container.setAttribute("aria-hidden", "true");
    if (this.milestoneCelebrationHideTimeout && typeof timerHost.clearTimeout === "function") {
      timerHost.clearTimeout(this.milestoneCelebrationHideTimeout);
    }
    this.milestoneCelebrationHideTimeout = null;
  }

  private scheduleMilestoneHide(durationMs: number): void {
    const timerHost: Partial<typeof globalThis> =
      typeof window !== "undefined" ? window : globalThis;
    if (this.milestoneCelebrationHideTimeout && typeof timerHost.clearTimeout === "function") {
      timerHost.clearTimeout(this.milestoneCelebrationHideTimeout);
    }
    if (typeof timerHost.setTimeout === "function") {
      this.milestoneCelebrationHideTimeout = timerHost.setTimeout(() => {
        this.hideMilestoneCelebration();
      }, durationMs) as unknown as number;
    } else {
      this.milestoneCelebrationHideTimeout = null;
    }
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
    const filtered = this.museumEntries.filter((entry) => {
      if (this.museumFilter === "unlocked") return entry.unlocked;
      if (this.museumFilter === "locked") return !entry.unlocked;
      return true;
    });
    if (this.museumOverlay.subtitle) {
      const unlocked = this.museumEntries.filter((entry) => entry.unlocked).length;
      const total = this.museumEntries.length;
      const filterLabel =
        this.museumFilter === "all"
          ? ""
          : this.museumFilter === "unlocked"
            ? " · Showing unlocked"
            : " · Showing locked";
      this.museumOverlay.subtitle.textContent = `${unlocked} of ${total} artifacts are on display${filterLabel}.`;
    }
    this.museumOverlay.list.replaceChildren();
    for (const entry of filtered) {
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

  setSessionGoals(state: SessionGoalsViewState): void {
    this.sessionGoalsState = state;
    if (this.sessionGoalsPanel?.summary) {
      this.sessionGoalsPanel.summary.textContent =
        typeof state.summary === "string" && state.summary.length > 0
          ? state.summary
          : "Adaptive session goals tune after each run.";
    }
    if (!this.sessionGoalsPanel?.list) return;
    const existing = this.sessionGoalsPanel.list.querySelectorAll("li");
    const nextGoals = Array.isArray(state.goals) ? state.goals : [];
    const shouldReplace = existing.length !== nextGoals.length;
    if (shouldReplace) {
      this.sessionGoalsPanel.list.replaceChildren();
    }
    const items: HTMLLIElement[] = shouldReplace
      ? []
      : Array.from(this.sessionGoalsPanel.list.querySelectorAll("li")).filter(
          (node): node is HTMLLIElement => node instanceof HTMLLIElement
        );

    for (let idx = 0; idx < nextGoals.length; idx += 1) {
      const goal = nextGoals[idx];
      const label = typeof goal?.label === "string" ? goal.label : "";
      const status = typeof goal?.status === "string" ? goal.status : "pending";
      const li =
        items[idx] ??
        (() => {
          const node = document.createElement("li");
          const marker = document.createElement("span");
          marker.className = "session-goals-panel__marker";
          marker.setAttribute("aria-hidden", "true");
          const text = document.createElement("span");
          text.className = "session-goals-panel__text";
          node.append(marker, text);
          this.sessionGoalsPanel!.list!.appendChild(node);
          items.push(node);
          return node;
        })();
      li.dataset.status = status;
      const text = li.querySelector(".session-goals-panel__text");
      if (text instanceof HTMLElement) {
        text.textContent = label;
      } else {
        li.textContent = label;
      }
    }

    for (let idx = nextGoals.length; idx < items.length; idx += 1) {
      items[idx]?.remove();
    }
  }

  setDailyQuestBoard(state: DailyQuestBoardViewState): void {
    this.dailyQuestBoardState = state;
    if (this.dailyQuestPanel?.summary) {
      this.dailyQuestPanel.summary.textContent =
        typeof state.summary === "string" && state.summary.length > 0
          ? state.summary
          : "Daily quests refresh each day.";
    }
    if (!this.dailyQuestPanel?.list) return;
    const existing = this.dailyQuestPanel.list.querySelectorAll("li");
    const nextEntries = Array.isArray(state.entries) ? state.entries : [];
    const shouldReplace = existing.length !== nextEntries.length;
    if (shouldReplace) {
      this.dailyQuestPanel.list.replaceChildren();
    }
    const items: HTMLLIElement[] = shouldReplace
      ? []
      : Array.from(this.dailyQuestPanel.list.querySelectorAll("li")).filter(
          (node): node is HTMLLIElement => node instanceof HTMLLIElement
        );

    for (let idx = 0; idx < nextEntries.length; idx += 1) {
      const entry = nextEntries[idx];
      const title = typeof entry?.title === "string" ? entry.title : "";
      const meta = typeof entry?.meta === "string" ? entry.meta : "";
      const progress = typeof entry?.progress === "number" ? entry.progress : 0;
      const isComplete = entry?.status === "completed";
      const status = isComplete ? "met" : progress > 0 ? "in-progress" : "pending";
      const label = meta ? `${title} (${meta})` : title;
      const li =
        items[idx] ??
        (() => {
          const node = document.createElement("li");
          const marker = document.createElement("span");
          marker.className = "session-goals-panel__marker";
          marker.setAttribute("aria-hidden", "true");
          const text = document.createElement("span");
          text.className = "session-goals-panel__text";
          node.append(marker, text);
          this.dailyQuestPanel!.list!.appendChild(node);
          items.push(node);
          return node;
        })();
      li.dataset.status = status;
      const text = li.querySelector(".session-goals-panel__text");
      if (text instanceof HTMLElement) {
        text.textContent = label;
      } else {
        li.textContent = label;
      }
    }

    for (let idx = nextEntries.length; idx < items.length; idx += 1) {
      items[idx]?.remove();
    }
  }

  setWeeklyQuestBoard(state: WeeklyQuestBoardViewState): void {
    this.weeklyQuestBoardState = state;
    if (this.weeklyQuestPanel?.summary) {
      const baseSummary =
        typeof state.summary === "string" && state.summary.length > 0
          ? state.summary
          : "Weekly quests refresh each Monday.";
      const attempts = typeof state.trial?.attempts === "number" ? state.trial.attempts : 0;
      const summary =
        state.trial?.status === "ready" && attempts > 0
          ? `${baseSummary} • ${attempts} attempt${attempts === 1 ? "" : "s"}`
          : baseSummary;
      this.weeklyQuestPanel.summary.textContent = summary;
    }
    if (this.weeklyQuestPanel?.trialButton) {
      const ready = state.trial?.status === "ready";
      this.weeklyQuestPanel.trialButton.dataset.visible = ready ? "true" : "false";
      this.weeklyQuestPanel.trialButton.disabled = !ready;
    }
    if (!this.weeklyQuestPanel?.list) return;
    const existing = this.weeklyQuestPanel.list.querySelectorAll("li");
    const nextEntries = Array.isArray(state.entries) ? state.entries : [];
    const shouldReplace = existing.length !== nextEntries.length;
    if (shouldReplace) {
      this.weeklyQuestPanel.list.replaceChildren();
    }
    const items: HTMLLIElement[] = shouldReplace
      ? []
      : Array.from(this.weeklyQuestPanel.list.querySelectorAll("li")).filter(
          (node): node is HTMLLIElement => node instanceof HTMLLIElement
        );

    for (let idx = 0; idx < nextEntries.length; idx += 1) {
      const entry = nextEntries[idx];
      const title = typeof entry?.title === "string" ? entry.title : "";
      const meta = typeof entry?.meta === "string" ? entry.meta : "";
      const progress = typeof entry?.progress === "number" ? entry.progress : 0;
      const isComplete = entry?.status === "completed";
      const status = isComplete ? "met" : progress > 0 ? "in-progress" : "pending";
      const label = meta ? `${title} (${meta})` : title;
      const li =
        items[idx] ??
        (() => {
          const node = document.createElement("li");
          const marker = document.createElement("span");
          marker.className = "session-goals-panel__marker";
          marker.setAttribute("aria-hidden", "true");
          const text = document.createElement("span");
          text.className = "session-goals-panel__text";
          node.append(marker, text);
          this.weeklyQuestPanel!.list!.appendChild(node);
          items.push(node);
          return node;
        })();
      li.dataset.status = status;
      const text = li.querySelector(".session-goals-panel__text");
      if (text instanceof HTMLElement) {
        text.textContent = label;
      } else {
        li.textContent = label;
      }
    }

    for (let idx = nextEntries.length; idx < items.length; idx += 1) {
      items[idx]?.remove();
    }
  }

  private renderSideQuestOverlay(): void {
    if (!this.sideQuestOverlay) return;
    this.sideQuestEntries = this.buildSideQuestEntries();
    const completed = this.sideQuestEntries.filter((entry) => entry.status === "completed").length;
    const total = this.sideQuestEntries.length;
    const filtered = this.sideQuestEntries.filter((entry) => {
      if (this.sideQuestFilter === "completed") return entry.status === "completed";
      if (this.sideQuestFilter === "active") return entry.status === "active";
      return true;
    });
    if (this.sideQuestOverlay.subtitle) {
      const filterLabel =
        this.sideQuestFilter === "all"
          ? ""
          : this.sideQuestFilter === "active"
            ? " · Showing active"
            : " · Showing completed";
      this.sideQuestOverlay.subtitle.textContent = `${completed} of ${total} quests completed${filterLabel}`;
    }
    this.sideQuestOverlay.list.replaceChildren();
    for (const entry of filtered) {
      const tile = document.createElement("div");
      tile.className = "quest-tile";
      tile.dataset.status = entry.status;
      tile.setAttribute("role", "listitem");
      const title = document.createElement("p");
      title.className = "quest-tile__title";
      title.textContent = entry.title;
      const desc = document.createElement("p");
      desc.className = "quest-tile__desc";
      desc.dataset.expanded = "false";
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
      const more = document.createElement("button");
      more.type = "button";
      more.className = "quest-more";
      const setExpanded = (expanded: boolean) => {
        desc.dataset.expanded = expanded ? "true" : "false";
        more.textContent = expanded ? "Less" : "More";
      };
      setExpanded(false);
      more.addEventListener("click", () => {
        setExpanded(desc.dataset.expanded !== "true");
      });
      tile.append(title, desc, meta, progress, more);
      this.sideQuestOverlay.list.appendChild(tile);
    }
  }

  private maybeCelebrateLessonMilestone(lessonsCompleted: number): void {
    if (!Number.isFinite(lessonsCompleted)) return;
    const safeLessons = Math.max(0, Math.floor(lessonsCompleted));
    if (!this.lessonMilestoneTrackingInitialized) {
      this.lessonMilestoneTrackingInitialized = true;
      this.lastLessonMilestoneCelebrated = safeLessons;
      return;
    }
    const thresholds = [5, 10, 20, 30, 50, 75, 100];
    const nextThreshold = thresholds.find(
      (value) => safeLessons >= value && this.lastLessonMilestoneCelebrated < value
    );
    if (!nextThreshold) {
      if (safeLessons < this.lastLessonMilestoneCelebrated) {
        this.lastLessonMilestoneCelebrated = safeLessons;
      }
      return;
    }
    this.lastLessonMilestoneCelebrated = nextThreshold;
    this.celebrateMilestone({
      title: `${nextThreshold} lessons completed!`,
      detail: `You have completed ${safeLessons} lessons-hydrate, stretch, then tackle the next challenge.`,
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

  setLessonPathProgress(state: LessonPathViewState): void {
    this.lessonPathState = state;
    if (!this.lessonMedalPanel?.path) return;
    const total = Math.max(0, Math.floor(state.totalLessons ?? 0));
    const completed = Math.max(0, Math.min(total, Math.floor(state.completedLessons ?? 0)));
    if (state.next) {
      const progressLabel = total > 0 ? ` (${completed}/${total} complete)` : "";
      this.lessonMedalPanel.path.textContent = `Next lesson: Lesson ${state.next.order} - ${state.next.label}${progressLabel}`;
      return;
    }
    if (total > 0) {
      this.lessonMedalPanel.path.textContent =
        "All lessons complete - revisit any lesson to stay sharp.";
      return;
    }
    this.lessonMedalPanel.path.textContent = "Lesson path unavailable.";
  }

  setLessonMedalProgress(
    state: LessonMedalViewState,
    options: { celebrate?: boolean } = {}
  ): void {
    const previousState = this.lessonMedalState ?? null;
    const previousLast = previousState?.last ?? null;
    const previousTimestamp =
      typeof previousLast?.timestamp === "number" && Number.isFinite(previousLast.timestamp)
        ? previousLast.timestamp
        : 0;
    this.lessonMedalState = state;
    this.updateLessonMedalPanel(state);
    if (this.lessonMedalOverlay?.container.dataset.visible === "true") {
      this.renderLessonMedalOverlay(state);
    }
    const celebrate = options.celebrate !== false;
    const last = state.last ?? null;
    const lastId = typeof last?.id === "string" && last.id.length > 0 ? last.id : null;
    const lastTimestamp =
      typeof last?.timestamp === "number" && Number.isFinite(last.timestamp) ? last.timestamp : 0;
    const isNewResult =
      !!lastId &&
      (!!last &&
        (!previousLast ||
          previousLast.id !== last.id ||
          previousLast.tier !== last.tier ||
          lastTimestamp > previousTimestamp));
    const alreadyCelebrated = !!lastId && this.lastLessonMedalCelebratedId === lastId;
    if (celebrate && isNewResult && !alreadyCelebrated) {
      const rankTier = (tier: LessonMedalTier): number => {
        if (tier === "platinum") return 3;
        if (tier === "gold") return 2;
        if (tier === "silver") return 1;
        return 0;
      };
      const mode = last?.mode ?? null;
      const previousBestForMode =
        mode && previousState?.bestByMode ? previousState.bestByMode[mode] ?? null : null;
      const previousModeBest =
        previousBestForMode ?? (previousLast?.mode === mode ? previousLast : null);
      const isTierUpgrade =
        !!last && (!previousModeBest || rankTier(last.tier) > rankTier(previousModeBest.tier));
      if (isTierUpgrade) {
        if (last.tier === "gold" || last.tier === "platinum") {
          const tierLabel = last.tier.charAt(0).toUpperCase() + last.tier.slice(1).toLowerCase();
          const modeLabel =
            last.mode === "burst"
              ? "Burst"
              : last.mode === "endurance"
                ? "Endurance"
                : last.mode === "sprint"
                  ? "Time Attack"
                  : last.mode === "sentences"
                    ? "Sentence Builder"
                    : last.mode === "rhythm"
                      ? "Rhythm Drill"
                : last.mode === "symbols"
                  ? "Symbols"
                  : "Precision";
          const accuracy = Number.isFinite(last.accuracy)
            ? `${Math.round(Math.max(0, Math.min(1, last.accuracy)) * 100)}% accuracy`
            : "Great accuracy";
          this.celebrateMilestone({
            title: `${tierLabel} medal earned!`,
            detail: `${modeLabel} drill completed with ${accuracy}.`,
            tone: last.tier === "platinum" ? "platinum" : "gold",
            eyebrow: "Lesson milestone"
          });
        }
        this.flashLessonMedalHighlight();
      }
    }
    if (lastId) {
      this.lastLessonMedalCelebratedId = lastId;
    }
  }

  private getEmptyLessonMedalState(): LessonMedalViewState {
    return {
      last: null,
      recent: [],
      bestByMode: {
        burst: null,
        lesson: null,
        warmup: null,
        endurance: null,
        sprint: null,
        sentences: null,
        reading: null,
        rhythm: null,
        reaction: null,
        combo: null,
        precision: null,
        symbols: null,
        placement: null,
        hand: null,
        support: null,
        shortcuts: null,
        shift: null,
        focus: null
      },
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
        { id: "hand", label: "Hand Isolation" },
        { id: "sentences", label: "Sentence Builder" },
        { id: "rhythm", label: "Rhythm Drill" },
        { id: "sprint", label: "Time Attack" },
        { id: "precision", label: "Shield Breaker" },
        { id: "symbols", label: "Numbers & Symbols" }
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
      case "placement":
        return "Placement Test";
      case "hand":
        return "Hand Isolation";
      case "support":
        return "Lane Support";
      case "shortcuts":
        return "Shortcut Practice";
      case "shift":
        return "Shift Timing";
      case "focus":
        return "Focus Drill";
      case "warmup":
        return "5-Min Warm-up";
      case "reaction":
        return "Reaction Challenge";
      case "combo":
        return "Combo Preservation";
      case "reading":
        return "Reading Quiz";
      case "precision":
        return "Shield Breaker";
      case "sprint":
        return "Time Attack";
      case "sentences":
        return "Sentence Builder";
      case "rhythm":
        return "Rhythm Drill";
      case "endurance":
        return "Endurance";
      case "symbols":
        return "Numbers & Symbols";
      case "lesson":
        return "Lesson";
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
      { id: "hand", label: "Hand" },
      { id: "sprint", label: "Time Attack" },
      { id: "sentences", label: "Sentences" },
      { id: "rhythm", label: "Rhythm" },
      { id: "precision", label: "Precision" },
      { id: "symbols", label: "Symbols" }
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
    if (this.loreScrollOverlay.filters) {
      this.loreScrollOverlay.filters.forEach((btn) =>
        btn.setAttribute("aria-pressed", btn.dataset.scrollFilter === this.loreScrollFilter ? "true" : "false")
      );
    }
    if (this.loreScrollOverlay.searchInput) {
      this.loreScrollOverlay.searchInput.value = this.loreScrollSearch;
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

  setWpmLadder(state: WpmLadderViewState): void {
    const previous = this.wpmLadderState;
    this.wpmLadderState = state;
    this.updateWpmLadderPanel(state);
    if (this.wpmLadderOverlay?.container.dataset.visible === "true") {
      this.renderWpmLadderOverlay(state);
    }
    if (previous) {
      const modes: TypingDrillMode[] = [
        "burst",
        "endurance",
        "hand",
        "sprint",
        "sentences",
        "rhythm",
        "precision",
        "symbols"
      ];
      const improved = modes.some((mode) => {
        const before = previous.bestByMode?.[mode];
        const after = state.bestByMode?.[mode];
        if (after && !before) return true;
        if (!after || !before) return false;
        if (after.wpm > before.wpm) return true;
        if (after.wpm === before.wpm && after.accuracy > before.accuracy) return true;
        return false;
      });
      if (improved) {
        this.flashWpmLadderHighlight();
      }
    }
  }

  setMusicStems(state: MusicStemViewState): void {
    this.musicStemState = state;
    this.updateMusicActiveLabel(state);
    if (this.musicOverlay?.container.dataset.visible === "true") {
      this.renderMusicOverlay(state);
    }
  }

  setUiSoundScheme(state: UiSchemeViewState): void {
    this.uiSoundSchemeState = state;
    this.updateUiSoundActiveLabel(state);
    if (this.uiSoundOverlay?.container.dataset.visible === "true") {
      this.renderUiSoundOverlay(state);
    }
  }

  setSfxLibrary(state: SfxLibraryViewState): void {
    this.sfxLibraryState = state;
    this.updateSfxActiveLabel(state);
    if (this.sfxOverlay?.container.dataset.visible === "true") {
      this.renderSfxOverlay(state);
    }
  }

  private getEmptyWpmLadderState(): WpmLadderViewState {
    return {
      totalRuns: 0,
      updatedAt: null,
      lastRun: null,
      bestByMode: {
        burst: null,
        lesson: null,
        warmup: null,
        endurance: null,
        sprint: null,
        sentences: null,
        reading: null,
        rhythm: null,
        reaction: null,
        combo: null,
        precision: null,
        symbols: null,
        placement: null,
        hand: null,
        support: null,
        shortcuts: null,
        shift: null,
        focus: null
      },
      ladderByMode: {
        burst: [],
        lesson: [],
        warmup: [],
        endurance: [],
        sprint: [],
        sentences: [],
        reading: [],
        rhythm: [],
        reaction: [],
        combo: [],
        precision: [],
        symbols: [],
        placement: [],
        hand: [],
        support: [],
        shortcuts: [],
        shift: [],
        focus: []
      },
      topRuns: []
    };
  }

  private flashWpmLadderHighlight(): void {
    if (!this.wpmLadderPanel?.container) return;
    this.wpmLadderPanel.container.dataset.highlight = "true";
    if (this.wpmLadderHighlightTimeout) {
      window.clearTimeout(this.wpmLadderHighlightTimeout);
    }
    this.wpmLadderHighlightTimeout = window.setTimeout(() => {
      if (this.wpmLadderPanel?.container) {
        this.wpmLadderPanel.container.dataset.highlight = "false";
      }
      this.wpmLadderHighlightTimeout = null;
    }, 2000);
  }

  private updateWpmLadderPanel(state: WpmLadderViewState): void {
    if (!this.wpmLadderPanel) return;
    const safeState = state ?? this.getEmptyWpmLadderState();
    const formatEntry = (entry: WpmLadderViewState["lastRun"] | null): string => {
      if (!entry) return "None";
      const accuracy = Math.round(entry.accuracy * 100);
      return `${Math.round(entry.wpm)} WPM @ ${accuracy}%`;
    };
    if (this.wpmLadderPanel.summary) {
      this.wpmLadderPanel.summary.textContent = safeState.totalRuns
        ? "Personal ladder tracks your fastest drills (stored locally)."
        : "Complete a typing drill to start your WPM ladder.";
    }
    if (this.wpmLadderPanel.stats) {
      this.wpmLadderPanel.stats.textContent = [
        `Burst: ${formatEntry(safeState.bestByMode.burst)}`,
        `Endurance: ${formatEntry(safeState.bestByMode.endurance)}`,
        `Time Attack: ${formatEntry(safeState.bestByMode.sprint)}`,
        `Sentences: ${formatEntry(safeState.bestByMode.sentences)}`,
        `Rhythm: ${formatEntry(safeState.bestByMode.rhythm)}`,
        `Precision: ${formatEntry(safeState.bestByMode.precision)}`,
        `Symbols: ${formatEntry(safeState.bestByMode.symbols)}`
      ].join(" · ");
    }
    if (this.wpmLadderPanel.top) {
      const top = safeState.topRuns[0] ?? null;
      if (top) {
        const accuracy = Math.round(top.accuracy * 100);
        this.wpmLadderPanel.top.textContent = `Top run: ${this.formatTypingDrillMode(top.mode)} at ${Math.round(top.wpm)} WPM (${accuracy}% accuracy).`;
      } else {
        this.wpmLadderPanel.top.textContent = "No runs recorded yet.";
      }
    }
  }

  private renderWpmLadderOverlay(state: WpmLadderViewState): void {
    if (!this.wpmLadderOverlay) return;
    const safeState = state ?? this.getEmptyWpmLadderState();
    const updatedLabel = safeState.updatedAt
      ? new Date(safeState.updatedAt).toLocaleString()
      : "not yet recorded";
    if (this.wpmLadderOverlay.subtitle) {
      this.wpmLadderOverlay.subtitle.textContent = safeState.totalRuns
        ? `Tracking ${safeState.totalRuns} runs; last updated ${updatedLabel}.`
        : "Complete a drill to populate your personal ladder.";
    }
    if (this.wpmLadderOverlay.meta) {
      const best = safeState.topRuns[0] ?? null;
      this.wpmLadderOverlay.meta.textContent = best
        ? `Best overall: ${Math.round(best.wpm)} WPM in ${this.formatTypingDrillMode(best.mode)} with ${Math.round(best.accuracy * 100)}% accuracy.`
        : "No recorded runs yet.";
    }
    this.wpmLadderOverlay.list.replaceChildren();
    const modes: Array<{ id: TypingDrillMode; label: string }> = [
      { id: "burst", label: "Burst Warmup" },
      { id: "endurance", label: "Endurance" },
      { id: "hand", label: "Hand Isolation" },
      { id: "sprint", label: "Time Attack" },
      { id: "sentences", label: "Sentence Builder" },
      { id: "rhythm", label: "Rhythm Drill" },
      { id: "precision", label: "Shield Breaker" },
      { id: "symbols", label: "Numbers & Symbols" }
    ];
    for (const mode of modes) {
      const column = document.createElement("div");
      column.className = "wpm-ladder-column";
      column.dataset.mode = mode.id;
      column.setAttribute("role", "listitem");
      column.setAttribute("aria-label", `${mode.label} ladder`);
      const header = document.createElement("div");
      header.className = "wpm-ladder-column__header";
      const title = document.createElement("p");
      title.className = "wpm-ladder-column__title";
      title.textContent = mode.label;
      const top = safeState.bestByMode[mode.id];
      const topStat = document.createElement("p");
      topStat.className = "wpm-ladder-column__stat";
      topStat.textContent = top
        ? `${Math.round(top.wpm)} WPM • ${Math.round(top.accuracy * 100)}% accuracy`
        : "No runs yet";
      header.append(title, topStat);
      column.appendChild(header);
      const entries = safeState.ladderByMode[mode.id] ?? [];
      if (!entries.length) {
        const empty = document.createElement("p");
        empty.className = "wpm-ladder-empty";
        empty.textContent = "Run this drill to start filling the ladder.";
        column.appendChild(empty);
      } else {
        entries.forEach((entry, index) => {
          const card = document.createElement("div");
          card.className = "wpm-ladder-card";
          card.dataset.mode = mode.id;
          const rank = document.createElement("span");
          rank.className = "wpm-ladder-card__rank";
          rank.textContent = `#${index + 1}`;
          const wpm = document.createElement("p");
          wpm.className = "wpm-ladder-card__wpm";
          wpm.textContent = `${Math.round(entry.wpm)} WPM`;
          const meta = document.createElement("p");
          meta.className = "wpm-ladder-card__meta";
          meta.textContent = `${Math.round(entry.accuracy * 100)}% accuracy · combo x${entry.bestCombo}`;
          const time = document.createElement("p");
          time.className = "wpm-ladder-card__time";
          time.textContent = `Logged ${new Date(entry.timestamp).toLocaleDateString()}`;
          card.append(rank, wpm, meta, time);
          column.appendChild(card);
        });
      }
      this.wpmLadderOverlay.list.appendChild(column);
    }
  }

  showWpmLadderOverlay(): void {
    if (!this.wpmLadderOverlay) return;
    this.wpmLadderOverlay.container.dataset.visible = "true";
    this.wpmLadderOverlay.container.setAttribute("aria-hidden", "false");
    this.renderWpmLadderOverlay(this.wpmLadderState ?? this.getEmptyWpmLadderState());
    const focusable = this.getFocusableElements(this.wpmLadderOverlay.container);
    focusable[0]?.focus();
  }

  hideWpmLadderOverlay(): void {
    if (!this.wpmLadderOverlay) return;
    this.wpmLadderOverlay.container.dataset.visible = "false";
    this.wpmLadderOverlay.container.setAttribute("aria-hidden", "true");
  }

  setBiomeGallery(state: BiomeGalleryViewState): void {
    const previous = this.biomeState;
    this.biomeState = state;
    this.updateBiomePanel(state);
    if (this.biomeOverlay?.container.dataset.visible === "true") {
      this.renderBiomeOverlay(state);
    }
    if (previous) {
      const prevActive = previous.cards.find((card) => card.id === previous.activeId);
      const nextActive = state.cards.find((card) => card.id === state.activeId);
      const improved =
        nextActive &&
        (!prevActive ||
          nextActive.stats.runs > prevActive.stats.runs ||
          nextActive.stats.lessons > prevActive.stats.lessons ||
          nextActive.stats.drills > prevActive.stats.drills);
      if (improved) {
        this.flashBiomeHighlight();
      }
    }
  }

  private getEmptyBiomeState(): BiomeGalleryViewState {
    return { activeId: "mossy-ruins", updatedAt: null, cards: [] };
  }

  private flashBiomeHighlight(): void {
    if (!this.biomePanel?.container) return;
    this.biomePanel.container.dataset.highlight = "true";
    if (this.biomeHighlightTimeout) {
      window.clearTimeout(this.biomeHighlightTimeout);
    }
    this.biomeHighlightTimeout = window.setTimeout(() => {
      if (this.biomePanel?.container) {
        this.biomePanel.container.dataset.highlight = "false";
      }
      this.biomeHighlightTimeout = null;
    }, 2000);
  }

  private updateBiomePanel(state: BiomeGalleryViewState): void {
    if (!this.biomePanel) return;
    const safe = state ?? this.getEmptyBiomeState();
    const active =
      safe.cards.find((card) => card.id === safe.activeId) ?? safe.cards[0] ?? null;
    if (this.biomePanel.summary) {
      this.biomePanel.summary.textContent = active
        ? `${active.name} · ${active.tagline}`
        : "Choose a biome to theme your drills.";
    }
    if (this.biomePanel.stats) {
      if (active) {
        const runs = active.stats.runs ?? 0;
        const lessons = active.stats.lessons ?? 0;
        const drills = active.stats.drills ?? 0;
        const best = Math.round(active.stats.bestWpm ?? 0);
        this.biomePanel.stats.textContent = `${runs} runs · ${lessons} lessons · ${drills} drills · Best ${best} WPM`;
      } else {
        this.biomePanel.stats.textContent = "No biome runs recorded yet.";
      }
    }
  }

  private renderBiomeOverlay(state: BiomeGalleryViewState): void {
    if (!this.biomeOverlay) return;
    const safe = state ?? this.getEmptyBiomeState();
    if (this.biomeOverlay.subtitle) {
      this.biomeOverlay.subtitle.textContent = safe.cards.length
        ? "Preview biomes, palettes, and focus bonuses. Stored locally."
        : "Complete a drill to populate your biome gallery.";
    }
    if (this.biomeOverlay.meta) {
      const updatedLabel = safe.updatedAt
        ? new Date(safe.updatedAt).toLocaleString()
        : "not yet updated";
      const active =
        safe.cards.find((card) => card.id === safe.activeId) ?? safe.cards[0] ?? null;
      this.biomeOverlay.meta.textContent = active
        ? `${active.name} focus: ${active.focus}. Last refreshed ${updatedLabel}.`
        : `Last refreshed ${updatedLabel}.`;
    }
    this.biomeOverlay.list.replaceChildren();
    if (!safe.cards.length) {
      const empty = document.createElement("p");
      empty.className = "biome-empty";
      empty.textContent = "Play a drill to unlock the biome gallery.";
      this.biomeOverlay.list.appendChild(empty);
      return;
    }
    for (const card of safe.cards) {
      const item = document.createElement("article");
      item.className = "biome-card";
      item.dataset.active = card.isActive ? "true" : "false";
      item.style.setProperty("--biome-sky", card.palette.sky);
      item.style.setProperty("--biome-mid", card.palette.mid);
      item.style.setProperty("--biome-ground", card.palette.ground);
      item.style.setProperty("--biome-accent", card.palette.accent);
      item.style.setProperty("--biome-heat", card.stats.heat.toString());

      const header = document.createElement("header");
      header.className = "biome-card__header";
      const title = document.createElement("h3");
      title.className = "biome-card__title";
      title.textContent = card.name;
      const badge = document.createElement("span");
      badge.className = "biome-card__badge";
      badge.textContent = card.isActive
        ? "Active"
        : card.difficulty === "spiky"
          ? "Spiky"
          : card.difficulty === "steady"
            ? "Steady"
            : "Calm";
      header.append(title, badge);

      const tagline = document.createElement("p");
      tagline.className = "biome-card__tagline";
      tagline.textContent = card.tagline;

      const focus = document.createElement("p");
      focus.className = "biome-card__focus";
      focus.textContent = `Focus: ${card.focus}`;

      const tags = document.createElement("div");
      tags.className = "biome-card__tags";
      for (const tag of card.tags) {
        const chip = document.createElement("span");
        chip.className = "biome-chip";
        chip.textContent = tag;
        tags.appendChild(chip);
      }

      const stats = document.createElement("div");
      stats.className = "biome-card__stats";
      const statRuns = document.createElement("p");
      statRuns.textContent = `${card.stats.runs} runs · ${card.stats.lessons} lessons · ${card.stats.drills} drills`;
      const statBest = document.createElement("p");
      statBest.textContent = `Best: ${Math.round(card.stats.bestWpm)} WPM @ ${Math.round(card.stats.bestAccuracy * 100)}% · combo x${Math.round(card.stats.bestCombo)}`;
      const statUpdated = document.createElement("p");
      statUpdated.className = "biome-card__updated";
      statUpdated.textContent = card.stats.lastPlayedAt
        ? `Last played ${new Date(card.stats.lastPlayedAt).toLocaleDateString()}`
        : "Not played yet";
      stats.append(statRuns, statBest, statUpdated);

      const actions = document.createElement("div");
      actions.className = "biome-card__actions";
      const selectButton = document.createElement("button");
      selectButton.type = "button";
      selectButton.className = card.isActive ? "secondary" : "primary";
      selectButton.textContent = card.isActive ? "Active" : "Set active";
      selectButton.disabled = card.isActive;
      selectButton.addEventListener("click", () => {
        this.callbacks.onBiomeSelect?.(card.id);
      });
      actions.appendChild(selectButton);

      item.append(header, tagline, focus, tags, stats, actions);
      this.biomeOverlay.list.appendChild(item);
    }
  }

  showBiomeOverlay(): void {
    if (!this.biomeOverlay) return;
    this.biomeOverlay.container.dataset.visible = "true";
    this.biomeOverlay.container.setAttribute("aria-hidden", "false");
    this.renderBiomeOverlay(this.biomeState ?? this.getEmptyBiomeState());
    const focusable = this.getFocusableElements(this.biomeOverlay.container);
    focusable[0]?.focus();
  }

  hideBiomeOverlay(): void {
    if (!this.biomeOverlay) return;
    this.biomeOverlay.container.dataset.visible = "false";
    this.biomeOverlay.container.setAttribute("aria-hidden", "true");
  }

  setTrainingCalendar(state: TrainingCalendarViewState): void {
    this.trainingCalendarState = state;
    this.updateTrainingCalendarPanel(state);
    if (this.trainingCalendarOverlay?.container.dataset.visible === "true") {
      this.renderTrainingCalendarOverlay(state);
    }
  }

  private getEmptyTrainingCalendarState(): TrainingCalendarViewState {
    return {
      days: [],
      totalLessons: 0,
      totalDrills: 0,
      lastUpdated: null
    };
  }

  private updateTrainingCalendarPanel(state: TrainingCalendarViewState): void {
    if (!this.trainingCalendarPanel) return;
    const safe = state ?? this.getEmptyTrainingCalendarState();
    if (this.trainingCalendarPanel.summary) {
      this.trainingCalendarPanel.summary.textContent = safe.totalLessons
        ? "Recent lessons and drills mapped per day (local only)."
        : "Complete a drill to start the training calendar.";
    }
    if (this.trainingCalendarPanel.stats) {
      this.trainingCalendarPanel.stats.textContent = `${safe.totalLessons} lessons · ${safe.totalDrills} drills last ${Math.max(1, Math.ceil((safe.days.length || 1) / 7))} weeks`;
    }
  }

  private renderTrainingCalendarOverlay(state: TrainingCalendarViewState): void {
    if (!this.trainingCalendarOverlay) return;
    const safe = state ?? this.getEmptyTrainingCalendarState();
    if (this.trainingCalendarOverlay.subtitle) {
      this.trainingCalendarOverlay.subtitle.textContent = safe.totalLessons
        ? `Lessons ${safe.totalLessons} · Drills ${safe.totalDrills}`
        : "No training sessions logged yet.";
    }
    if (this.trainingCalendarOverlay.legend) {
      this.trainingCalendarOverlay.legend.textContent = "Darker tiles = more sessions that day.";
    }
    this.trainingCalendarOverlay.grid.replaceChildren();
    if (!safe.days.length) {
      const empty = document.createElement("p");
      empty.className = "calendar-empty";
      empty.textContent = "Complete a drill to start the calendar.";
      this.trainingCalendarOverlay.grid.appendChild(empty);
      return;
    }
    const weeks = Math.max(...safe.days.map((d) => d.weekIndex)) + 1;
    const columns: HTMLElement[] = [];
    for (let i = 0; i < weeks; i += 1) {
      const column = document.createElement("div");
      column.className = "calendar-column";
      columns.push(column);
      this.trainingCalendarOverlay.grid.appendChild(column);
    }
    const intensity = (entry: TrainingCalendarViewState["days"][number]): number => {
      const total = entry.lessons + entry.drills;
      if (total === 0) return 0;
      if (total >= 4) return 1;
      if (total >= 2) return 0.7;
      return 0.45;
    };
    for (const day of safe.days) {
      const cell = document.createElement("div");
      cell.className = "calendar-cell";
      cell.dataset.level = intensity(day).toString();
      cell.title = `${day.date}: ${day.lessons} lesson${day.lessons === 1 ? "" : "s"}, ${day.drills} drill${day.drills === 1 ? "" : "s"}`;
      cell.setAttribute("aria-label", cell.title);
      if (columns[day.weekIndex]) {
        columns[day.weekIndex].appendChild(cell);
      }
    }
  }

  showTrainingCalendarOverlay(): void {
    if (!this.trainingCalendarOverlay) return;
    this.trainingCalendarOverlay.container.dataset.visible = "true";
    this.trainingCalendarOverlay.container.setAttribute("aria-hidden", "false");
    this.renderTrainingCalendarOverlay(this.trainingCalendarState ?? this.getEmptyTrainingCalendarState());
    const focusable = this.getFocusableElements(this.trainingCalendarOverlay.container);
    focusable[0]?.focus();
  }

  hideTrainingCalendarOverlay(): void {
    if (!this.trainingCalendarOverlay) return;
    this.trainingCalendarOverlay.container.dataset.visible = "false";
    this.trainingCalendarOverlay.container.setAttribute("aria-hidden", "true");
  }

  setStreakTokens(state: { tokens: number; streak: number; lastAwarded: string | null }): void {
    this.streakTokens = {
      tokens: Math.max(0, Math.floor(state?.tokens ?? 0)),
      streak: Math.max(0, Math.floor(state?.streak ?? 0)),
      lastAwarded: state?.lastAwarded ?? null
    };
    this.updateStreakTokenPanel();
  }

  private updateStreakTokenPanel(): void {
    if (!this.streakTokenPanel) return;
    const count = this.streakTokens.tokens;
    const streak = this.streakTokens.streak;
    if (this.streakTokenPanel.count) {
      this.streakTokenPanel.count.textContent = `${count} token${count === 1 ? "" : "s"} available`;
    }
    if (this.streakTokenPanel.status) {
      this.streakTokenPanel.status.textContent =
        streak > 0
          ? `Current streak: ${streak} day${streak === 1 ? "" : "s"} (earn a token after 5 days without a break).`
          : "No active streak yet. Complete a drill to start one.";
    }
    if (this.streakTokenPanel.container) {
      this.streakTokenPanel.container.dataset.highlight = count > 0 ? "true" : "false";
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
      if (!this.masteryCertificateMilestoneShown && state.accuracyPct >= 95) {
        this.masteryCertificateMilestoneShown = true;
        this.persistMasteryCertificateMilestoneShown(true);
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
    const minutesText = stats ? `${Math.max(0, Math.round(stats.timeMinutes))}m` : "0m";
    if (this.masteryCertificate.statLessons) {
      this.masteryCertificate.statLessons.textContent = stats
        ? `${stats.lessonsCompleted}`
        : "0";
    }
    if (this.masteryCertificate.statAccuracy) {
      this.masteryCertificate.statAccuracy.textContent = stats
        ? `${stats.accuracyPct}%`
        : "—";
    }
    if (this.masteryCertificate.statWpm) {
      this.masteryCertificate.statWpm.textContent = stats ? `${stats.wpm}` : "—";
    }
    if (this.masteryCertificate.statCombo) {
      this.masteryCertificate.statCombo.textContent = stats ? `x${stats.bestCombo}` : "x0";
    }
    if (this.masteryCertificate.statDrills) {
      this.masteryCertificate.statDrills.textContent = stats ? `${stats.drillsCompleted}` : "0";
    }
    if (this.masteryCertificate.statTime) {
      this.masteryCertificate.statTime.textContent = minutesText;
    }
    if (this.masteryCertificate.details) {
      this.setMasteryCertificateDetailsCollapsed(this.certificateDetailsCollapsed);
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

  private setMasteryCertificateDetailsCollapsed(collapsed: boolean): void {
    this.certificateDetailsCollapsed = collapsed;
    if (!this.masteryCertificate) return;
    if (this.masteryCertificate.details) {
      this.masteryCertificate.details.dataset.collapsed = collapsed ? "true" : "false";
    }
    if (this.masteryCertificate.detailsToggle) {
      this.masteryCertificate.detailsToggle.setAttribute("aria-expanded", collapsed ? "false" : "true");
      this.masteryCertificate.detailsToggle.textContent = collapsed ? "Expand" : "Collapse";
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
    const normalizedSearch = this.loreScrollSearch.trim().toLowerCase();
    const filteredEntries = state.entries.filter((entry) => {
      if (this.loreScrollFilter === "unlocked" && !entry.unlocked) return false;
      if (this.loreScrollFilter === "locked" && entry.unlocked) return false;
      if (normalizedSearch) {
        const haystack = `${entry.title} ${entry.summary}`.toLowerCase();
        if (!haystack.includes(normalizedSearch)) return false;
      }
      return true;
    });
    summary.textContent = `Unlocked ${state.unlocked} of ${state.total} scrolls`;
    if (progress) {
      const lessonsLabel = state.lessonsCompleted === 1 ? "lesson" : "lessons";
      const filterNote =
        this.loreScrollFilter === "all"
          ? ""
          : this.loreScrollFilter === "unlocked"
            ? " · Showing unlocked"
            : " · Showing locked";
      progress.textContent = `${state.lessonsCompleted} ${lessonsLabel} completed${filterNote}`;
    }
    list.replaceChildren();
    for (const entry of filteredEntries) {
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

  private applyDayNightTheme(mode: DayNightMode): void {
    const normalized: DayNightMode = mode === "day" ? "day" : "night";
    document.documentElement.dataset.theme = normalized;
    document.body.dataset.theme = normalized;
    if (this.hudRoot) {
      this.hudRoot.dataset.theme = normalized;
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

  private refreshParentSummary(state: GameState, timeSeconds: number): void {
    const timeMinutes = Math.max(0, (timeSeconds ?? 0) / 60);
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

  private refreshMasteryCertificate(
    state: GameState,
    lessonsCompleted: number,
    previousStatus: GameStatus | null,
    timeSeconds: number
  ): void {
    const sessionComplete = state.status === "defeat" || state.status === "victory";
    const previousComplete =
      previousStatus === "defeat" || previousStatus === "victory";
    if (!sessionComplete || previousComplete) {
      return;
    }

    const timeMinutes = Math.max(0, (timeSeconds ?? 0) / 60);
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

  private getEmptyMusicState(): MusicStemViewState {
    return { activeId: "siege-suite", dynamicEnabled: true, updatedAt: null, entries: [] };
  }

  private updateMusicActiveLabel(state: MusicStemViewState): void {
    if (!this.musicActiveLabel) return;
    const safe = state ?? this.getEmptyMusicState();
    const active =
      safe.entries.find((entry) => entry.active) ??
      safe.entries.find((entry) => entry.id === safe.activeId) ??
      null;
    const name = active?.name ?? "Siege Suite";
    const vibe = active?.vibe ?? "Cinematic";
    this.musicActiveLabel.textContent = `Music suite: ${name} (${vibe})`;
    this.musicActiveLabel.style.setProperty("--music-accent", active?.accent ?? "#f43f5e");
    this.musicActiveLabel.style.setProperty("--sfx-accent", active?.accent ?? "#f43f5e");
  }

  private renderMusicOverlay(state: MusicStemViewState): void {
    if (!this.musicOverlay) return;
    const safe = state ?? this.getEmptyMusicState();
    if (this.musicOverlay.summary) {
      const active =
        safe.entries.find((entry) => entry.active) ??
        safe.entries.find((entry) => entry.id === safe.activeId) ??
        null;
      const updated =
        safe.updatedAt && !Number.isNaN(Date.parse(safe.updatedAt))
          ? new Date(safe.updatedAt).toLocaleString()
          : "not yet refreshed";
      const label = active ? `${active.name} suite active` : "Pick a music suite";
      this.musicOverlay.summary.textContent = `${label} - refreshed ${updated}.`;
    }
    this.musicOverlay.list.replaceChildren();
    if (!safe.entries.length) {
      const empty = document.createElement("p");
      empty.className = "music-empty";
      empty.textContent = "No music suites available yet.";
      this.musicOverlay.list.appendChild(empty);
      return;
    }
    for (const entry of safe.entries) {
      const card = document.createElement("article");
      card.className = "sfx-card music-card";
      card.dataset.active = entry.active ? "true" : "false";
      card.dataset.auditioned = entry.auditioned ? "true" : "false";
      card.style.setProperty("--sfx-accent", entry.accent);

      const header = document.createElement("header");
      header.className = "sfx-card__header";
      const titleWrap = document.createElement("div");
      const vibe = document.createElement("p");
      vibe.className = "sfx-card__vibe";
      vibe.textContent = entry.vibe;
      const title = document.createElement("h3");
      title.className = "sfx-card__title";
      title.textContent = entry.name;
      titleWrap.append(vibe, title);
      const badge = document.createElement("span");
      badge.className = "sfx-card__badge";
      badge.textContent = entry.active ? "Active" : entry.auditioned ? "Auditioned" : "New";
      header.append(titleWrap, badge);

      const summary = document.createElement("p");
      summary.className = "sfx-card__summary";
      summary.textContent = entry.summary;

      const focus = document.createElement("p");
      focus.className = "sfx-card__focus";
      focus.textContent = entry.focus;

      const tags = document.createElement("div");
      tags.className = "sfx-card__tags";
      for (const tag of entry.tags) {
        const chip = document.createElement("span");
        chip.className = "sfx-tag";
        chip.textContent = tag;
        tags.appendChild(chip);
      }

      const preview = document.createElement("p");
      preview.className = "sfx-card__preview";
      preview.textContent = `Preview mix: ${entry.previewProfile} – ${entry.mixSummary}`;

      const actions = document.createElement("div");
      actions.className = "sfx-card__actions";
      const previewButton = document.createElement("button");
      previewButton.type = "button";
      previewButton.className = "ghost";
      previewButton.textContent = entry.auditioned ? "Preview again" : "Preview";
      if (this.callbacks.onMusicLibraryPreview) {
        previewButton.addEventListener("click", () => {
          this.callbacks.onMusicLibraryPreview?.(entry.id);
        });
      } else {
        previewButton.disabled = true;
      }

      const applyButton = document.createElement("button");
      applyButton.type = "button";
      applyButton.className = "secondary";
      applyButton.textContent = entry.active ? "Active" : "Set active";
      if (!entry.active && this.callbacks.onMusicLibrarySelect) {
        applyButton.addEventListener("click", () => {
          this.callbacks.onMusicLibrarySelect?.(entry.id);
        });
      } else if (entry.active) {
        applyButton.disabled = true;
      }

      actions.append(previewButton, applyButton);
      card.append(header, summary, focus, tags, preview, actions);
      this.musicOverlay.list.appendChild(card);
    }
  }

  private getEmptyUiSoundState(): UiSchemeViewState {
    return { activeId: "clarity", updatedAt: null, entries: [] };
  }

  private updateUiSoundActiveLabel(state: UiSchemeViewState): void {
    if (!this.uiSoundActiveLabel) return;
    const safe = state ?? this.getEmptyUiSoundState();
    const active =
      safe.entries.find((entry) => entry.active) ??
      safe.entries.find((entry) => entry.id === safe.activeId) ??
      null;
    const def = getUiSchemeDefinition(active?.id ?? safe.activeId);
    const name = active?.name ?? def.name;
    const vibe = active?.vibe ?? def.vibe;
    const accent = active?.accent ?? def.accent;
    this.uiSoundActiveLabel.textContent = `UI sounds: ${name} (${vibe})`;
    this.uiSoundActiveLabel.style.setProperty("--ui-accent", accent);
    this.uiSoundActiveLabel.style.setProperty("--sfx-accent", accent);
  }

  private renderUiSoundOverlay(state: UiSchemeViewState): void {
    if (!this.uiSoundOverlay) return;
    const safe = state ?? this.getEmptyUiSoundState();
    if (this.uiSoundOverlay.summary) {
      const active =
        safe.entries.find((entry) => entry.active) ??
        safe.entries.find((entry) => entry.id === safe.activeId) ??
        null;
      const updated =
        safe.updatedAt && !Number.isNaN(Date.parse(safe.updatedAt))
          ? new Date(safe.updatedAt).toLocaleString()
          : "not yet refreshed";
      const label = active ? `${active.name} set active` : "Pick a UI sound set";
      this.uiSoundOverlay.summary.textContent = `${label} - refreshed ${updated}.`;
    }
    this.uiSoundOverlay.list.replaceChildren();
    if (!safe.entries.length) {
      const empty = document.createElement("p");
      empty.className = "sfx-empty";
      empty.textContent = "No UI sound sets available yet.";
      this.uiSoundOverlay.list.appendChild(empty);
      return;
    }
    for (const entry of safe.entries) {
      const card = document.createElement("article");
      card.className = "sfx-card";
      card.dataset.active = entry.active ? "true" : "false";
      card.dataset.auditioned = entry.auditioned ? "true" : "false";
      card.style.setProperty("--sfx-accent", entry.accent);
      card.style.setProperty("--ui-accent", entry.accent);

      const header = document.createElement("header");
      header.className = "sfx-card__header";
      const titleWrap = document.createElement("div");
      const vibe = document.createElement("p");
      vibe.className = "sfx-card__vibe";
      vibe.textContent = entry.vibe;
      const title = document.createElement("h3");
      title.className = "sfx-card__title";
      title.textContent = entry.name;
      titleWrap.append(vibe, title);
      const badge = document.createElement("span");
      badge.className = "sfx-card__badge";
      badge.textContent = entry.active ? "Active" : entry.auditioned ? "Auditioned" : "New";
      header.append(titleWrap, badge);

      const summary = document.createElement("p");
      summary.className = "sfx-card__summary";
      summary.textContent = entry.summary;

      const focus = document.createElement("p");
      focus.className = "sfx-card__focus";
      focus.textContent = `Preview order: ${entry.preview.join(" -> ")}`;

      const tags = document.createElement("div");
      tags.className = "sfx-card__tags";
      for (const tag of entry.tags) {
        const chip = document.createElement("span");
        chip.className = "sfx-tag";
        chip.textContent = tag;
        tags.appendChild(chip);
      }

      const actions = document.createElement("div");
      actions.className = "sfx-card__actions";
      const previewButton = document.createElement("button");
      previewButton.type = "button";
      previewButton.className = "ghost";
      previewButton.textContent = entry.auditioned ? "Preview again" : "Preview";
      if (this.callbacks.onUiSoundSchemePreview) {
        previewButton.addEventListener("click", () => {
          this.callbacks.onUiSoundSchemePreview?.(entry.id);
        });
      } else {
        previewButton.disabled = true;
      }

      const applyButton = document.createElement("button");
      applyButton.type = "button";
      applyButton.className = entry.active ? "primary" : "secondary";
      applyButton.textContent = entry.active ? "Active" : "Set active";
      applyButton.disabled = entry.active;
      if (this.callbacks.onUiSoundSchemeSelect) {
        applyButton.addEventListener("click", () => {
          this.callbacks.onUiSoundSchemeSelect?.(entry.id);
        });
      } else {
        applyButton.disabled = true;
      }

      actions.append(previewButton, applyButton);
      card.append(header, summary, focus, tags, actions);
      this.uiSoundOverlay.list.appendChild(card);
    }
  }

  private getEmptySfxLibraryState(): SfxLibraryViewState {
    return { activeId: "classic", updatedAt: null, entries: [] };
  }

  private updateSfxActiveLabel(state: SfxLibraryViewState): void {
    if (!this.sfxActiveLabel) return;
    const safe = state ?? this.getEmptySfxLibraryState();
    const active =
      safe.entries.find((entry) => entry.active) ??
      safe.entries.find((entry) => entry.id === safe.activeId) ??
      null;
    const name = active?.name ?? "Classic Mix";
    const vibe = active?.vibe ?? "Balanced";
    this.sfxActiveLabel.textContent = `Active mix: ${name} (${vibe})`;
    this.sfxActiveLabel.style.setProperty("--sfx-accent", active?.accent ?? "#22c55e");
  }

  private renderSfxOverlay(state: SfxLibraryViewState): void {
    if (!this.sfxOverlay) return;
    const safe = state ?? this.getEmptySfxLibraryState();
    if (this.sfxOverlay.summary) {
      const active =
        safe.entries.find((entry) => entry.active) ??
        safe.entries.find((entry) => entry.id === safe.activeId) ??
        null;
      const updated =
        safe.updatedAt && !Number.isNaN(Date.parse(safe.updatedAt))
          ? new Date(safe.updatedAt).toLocaleString()
          : "not yet refreshed";
      const label = active ? `${active.name} mix active` : "Pick a mix to activate";
      this.sfxOverlay.summary.textContent = `${label} - refreshed ${updated}.`;
    }
    this.sfxOverlay.list.replaceChildren();
    if (!safe.entries.length) {
      const empty = document.createElement("p");
      empty.className = "sfx-empty";
      empty.textContent = "No sound mixes available yet.";
      this.sfxOverlay.list.appendChild(empty);
      return;
    }
    for (const entry of safe.entries) {
      const card = document.createElement("article");
      card.className = "sfx-card";
      card.dataset.active = entry.active ? "true" : "false";
      card.dataset.auditioned = entry.auditioned ? "true" : "false";
      card.style.setProperty("--sfx-accent", entry.accent);

      const header = document.createElement("header");
      header.className = "sfx-card__header";
      const titleWrap = document.createElement("div");
      const vibe = document.createElement("p");
      vibe.className = "sfx-card__vibe";
      vibe.textContent = entry.vibe;
      const title = document.createElement("h3");
      title.className = "sfx-card__title";
      title.textContent = entry.name;
      titleWrap.append(vibe, title);
      const badge = document.createElement("span");
      badge.className = "sfx-card__badge";
      badge.textContent = entry.active ? "Active" : entry.auditioned ? "Auditioned" : "New";
      header.append(titleWrap, badge);

      const summary = document.createElement("p");
      summary.className = "sfx-card__summary";
      summary.textContent = entry.summary;

      const focus = document.createElement("p");
      focus.className = "sfx-card__focus";
      focus.textContent = entry.focus;

      const tags = document.createElement("div");
      tags.className = "sfx-card__tags";
      for (const tag of entry.tags) {
        const chip = document.createElement("span");
        chip.className = "sfx-tag";
        chip.textContent = tag;
        tags.appendChild(chip);
      }

      const preview = document.createElement("p");
      preview.className = "sfx-card__preview";
      preview.textContent = `Preview: ${entry.preview.join(" -> ")}`;

      const actions = document.createElement("div");
      actions.className = "sfx-card__actions";
      const previewButton = document.createElement("button");
      previewButton.type = "button";
      previewButton.className = "ghost";
      previewButton.textContent = entry.auditioned ? "Preview again" : "Preview";
      if (this.callbacks.onSfxLibraryPreview) {
        previewButton.addEventListener("click", () => {
          this.callbacks.onSfxLibraryPreview?.(entry.id);
        });
      } else {
        previewButton.disabled = true;
      }
      const selectButton = document.createElement("button");
      selectButton.type = "button";
      selectButton.className = entry.active ? "primary" : "secondary";
      selectButton.textContent = entry.active ? "Active" : "Set active";
      selectButton.disabled = entry.active;
      if (this.callbacks.onSfxLibrarySelect) {
        selectButton.addEventListener("click", () => {
          this.callbacks.onSfxLibrarySelect?.(entry.id);
        });
      } else {
        selectButton.disabled = true;
      }
      actions.append(previewButton, selectButton);

      card.append(header, summary, focus, tags, preview, actions);
      this.sfxOverlay.list.appendChild(card);
    }
  }

  private renderReadabilityGuide(): void {
    if (!this.readabilityOverlay) return;
    const list = this.readabilityOverlay.list;
    list.replaceChildren();
    const total = READABILITY_GUIDE.length;
    if (this.readabilityOverlay.summary) {
      this.readabilityOverlay.summary.textContent = `${total} readability profiles refreshed with silhouette + color tags.`;
    }
    for (const entry of READABILITY_GUIDE) {
      const card = document.createElement("article");
      card.className = "readability-card";
      card.dataset.tier = entry.tier;
      card.setAttribute("role", "listitem");
      card.style.setProperty("--tone", entry.color);
      const header = document.createElement("div");
      header.className = "readability-card__header";
      const title = document.createElement("h3");
      title.className = "readability-name";
      title.textContent = entry.name;
      const tier = document.createElement("span");
      tier.className = "readability-tier";
      tier.textContent = this.describeReadabilityTier(entry.tier);
      tier.style.color = entry.accent;
      header.appendChild(title);
      header.appendChild(tier);

      const figure = document.createElement("div");
      figure.className = "readability-figure";
      const silhouette = document.createElement("div");
      silhouette.className = "readability-silhouette";
      if (entry.shape !== "base") {
        silhouette.dataset.shape = entry.shape;
      }
      silhouette.style.setProperty("--tone", entry.color);
      const accents = document.createElement("div");
      accents.className = "readability-accents";
      figure.appendChild(silhouette);
      figure.appendChild(accents);

      const meta = document.createElement("div");
      meta.className = "readability-meta";
      const summary = document.createElement("p");
      summary.className = "readability-summary";
      summary.textContent = entry.summary;
      const tags = document.createElement("div");
      tags.className = "readability-tags";
      for (const tag of entry.tags) {
        const chip = document.createElement("span");
        chip.className = "readability-tag";
        chip.textContent = tag;
        tags.appendChild(chip);
      }
      meta.appendChild(summary);
      meta.appendChild(tags);

      const tips = document.createElement("ul");
      tips.className = "readability-tips";
      for (const tip of entry.tips) {
        const li = document.createElement("li");
        li.textContent = tip;
        tips.appendChild(li);
      }

      card.appendChild(header);
      card.appendChild(figure);
      card.appendChild(meta);
      card.appendChild(tips);
      list.appendChild(card);
    }
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

  private describeReadabilityTier(tier: ReadabilityTier): string {
    switch (tier) {
      case "fast":
        return "Fast lane";
      case "heavy":
        return "Heavy";
      case "shield":
        return "Shielded";
      case "caster":
        return "Caster";
      case "boss":
        return "Boss/Siege";
      default:
        return "Baseline";
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
    this.hudLayoutSide = side;
    if (typeof document !== "undefined") {
      document.body.dataset.hudLayout = side;
    }
    if (this.hudRoot) {
      this.hudRoot.dataset.layout = side;
    }
    this.syncLayoutOverlayState();
  }

  setHudFontScale(scale: number): void {
    if (typeof document === "undefined") return;
    document.documentElement.style.setProperty("--hud-font-scale", scale.toString());
  }

  private computeWpm(state: GameState, timeSecondsOverride?: number): number {
    const timeSeconds =
      typeof timeSecondsOverride === "number" && Number.isFinite(timeSecondsOverride)
        ? Math.max(0, timeSecondsOverride)
        : Math.max(0, state.time ?? 0);
    const minutes = Math.max(timeSeconds / 60, 0.1);
    return Math.max(0, Math.round((state.typing.correctInputs / 5) / minutes));
  }

  setReducedMotionEnabled(enabled: boolean): void {
    this.reducedMotionEnabled = enabled;
    if (typeof document !== "undefined") {
      if (document.documentElement) {
        document.documentElement.dataset.reducedMotion = enabled ? "true" : "false";
        document.documentElement.dataset.vfxMode = enabled ? "reduced" : "full";
      }
      if (document.body) {
        document.body.dataset.reducedMotion = enabled ? "true" : "false";
        document.body.dataset.vfxMode = enabled ? "reduced" : "full";
      }
    }
    if (this.hudRoot) {
      this.hudRoot.dataset.reducedMotion = enabled ? "true" : "false";
      this.hudRoot.dataset.vfxMode = enabled ? "reduced" : "full";
    }
    this.setParallaxMotionPaused(enabled);
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

  private setAnalyticsViewerTab(tab: AnalyticsViewerTab): void {
    if (!this.analyticsViewer) return;
    this.analyticsViewerTab = tab;
    const tabs = this.analyticsViewer.tabs ?? {};
    const panels = this.analyticsViewer.panels ?? {};
    (["summary", "traces", "exports"] as AnalyticsViewerTab[]).forEach((key) => {
      const button = tabs[key];
      const panel = panels[key];
      const active = key === tab;
      if (button) {
        button.setAttribute("aria-selected", active ? "true" : "false");
      }
      if (panel) {
        panel.dataset.active = active ? "true" : "false";
        panel.setAttribute("aria-hidden", active ? "false" : "true");
      }
    });
    if (tab === "traces" && this.lastState) {
      const history = this.lastState.analytics.waveHistory?.length
        ? this.lastState.analytics.waveHistory
        : this.lastState.analytics.waveSummaries;
      this.renderAnalyticsTraces(history, {
        goldEvents: this.lastState.analytics.goldEvents ?? []
      });
    }
    if (tab === "exports" && this.lastState) {
      const history = this.lastState.analytics.waveHistory?.length
        ? this.lastState.analytics.waveHistory
        : this.lastState.analytics.waveSummaries;
      this.renderAnalyticsExportMeta(history, this.lastState.analytics.timeToFirstTurret ?? null);
    }
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
    if (this.analyticsViewer.panels || this.analyticsViewer.tabs) {
      this.setAnalyticsViewerTab(this.analyticsViewerTab);
    }
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

  private renderAnalyticsTraces(
    summaries: WaveSummary[],
    options: { goldEvents?: Array<{ gold?: number; delta?: number; timestamp?: number }> } = {}
  ): void {
    if (!this.analyticsViewer?.traces) {
      return;
    }
    const container = this.analyticsViewer.traces;
    container.replaceChildren();
    const traces: Array<{ label: string; meta: string; pill: string }> = [];
    const recentWaves = summaries.slice(-3).reverse();
    for (const summary of recentWaves) {
      const label = `Wave ${summary.index + 1} · ${summary.mode === "practice" ? "Practice" : "Campaign"}`;
      const durationLabel = `${Math.max(0, summary.duration).toFixed(1)}s`;
      const metaParts = [
        `${summary.enemiesDefeated} defeated`,
        `${summary.breaches} breaches`,
        durationLabel
      ];
      const perfect = Math.max(0, Math.floor(summary.perfectWords ?? 0));
      const pillLabel = `${(summary.accuracy * 100).toFixed(1)}% • ${perfect} perfect`;
      traces.push({
        label,
        meta: metaParts.join(" • "),
        pill: pillLabel
      });
    }
    const goldEvents = Array.isArray(options.goldEvents) ? options.goldEvents : [];
    const recentGold = goldEvents.slice(-2).reverse();
    for (const event of recentGold) {
      const delta = Math.round(event.delta ?? 0);
      const gold = Math.round(event.gold ?? 0);
      const label = "Treasury update";
      const timestamp =
        typeof event.timestamp === "number" && Number.isFinite(event.timestamp)
          ? `${event.timestamp.toFixed(1)}s`
          : "recent";
      const meta = `Gold ${gold} • ${timestamp}`;
      const pill = `${delta >= 0 ? "+" : ""}${delta}g`;
      traces.push({ label, meta, pill });
    }
    if (traces.length === 0) {
      const empty = document.createElement("p");
      empty.className = "analytics-traces__empty";
      empty.textContent = "No traces yet. Finish a wave to view castle alerts and gold events.";
      container.appendChild(empty);
      return;
    }
    for (const trace of traces) {
      const row = document.createElement("div");
      row.className = "analytics-trace";
      const label = document.createElement("p");
      label.className = "analytics-trace__label";
      label.textContent = trace.label;
      const meta = document.createElement("p");
      meta.className = "analytics-trace__meta";
      meta.textContent = trace.meta;
      const pill = document.createElement("span");
      pill.className = "analytics-trace__pill";
      pill.textContent = trace.pill;
      row.append(label, meta, pill);
      container.appendChild(row);
    }
  }

  private renderAnalyticsExportMeta(
    summaries: WaveSummary[],
    timeToFirstTurret: number | null
  ): void {
    if (!this.analyticsViewer?.exportMeta) {
      return;
    }
    const { waves, drills, breaches, ttf, note } = this.analyticsViewer.exportMeta;
    const waveCount = summaries.length;
    const drillCount = Array.isArray(this.lastState?.analytics?.typingDrills)
      ? this.lastState?.analytics?.typingDrills.length ?? 0
      : 0;
    const breachCount =
      this.lastState?.analytics?.sessionBreaches ?? this.lastState?.analytics?.breaches ?? 0;
    if (waves) {
      waves.textContent = waveCount.toString();
    }
    if (drills) {
      drills.textContent = drillCount.toString();
    }
    if (breaches) {
      breaches.textContent = breachCount.toString();
    }
    if (ttf) {
      ttf.textContent =
        timeToFirstTurret !== null && Number.isFinite(timeToFirstTurret)
          ? `${timeToFirstTurret.toFixed(1)}s`
          : "—";
    }
    if (note) {
      note.textContent =
        waveCount === 0
          ? "No wave analytics yet. Run a siege then export for a shareable dossier."
          : "Export includes drills, telemetry, and HUD preferences.";
    }
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
    this.renderAnalyticsTraces(summaries, {
      goldEvents: this.lastState?.analytics?.goldEvents ?? []
    });
    this.renderAnalyticsExportMeta(summaries, timeToFirstTurret);
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
      if (this.optionsOverlay.mainColumn) {
        this.optionsOverlay.mainColumn.scrollTop = 0;
      }
      this.optionsOverlay.resumeButton.focus();
      this.narration.speak(
        "Options open. Tab through panels or press Escape to resume.",
        { interrupt: true }
      );
    } else {
      this.narration.speak("Options closed. Resuming play.", { interrupt: true });
      this.focusTypingInput();
    }
  }

  setFieldDrillStatus(status: {
    active: boolean;
    title?: string;
    progress?: string;
    hint?: string;
    tone?: "lesson" | "intermission";
  }): void {
    if (!this.fieldDrillBanner) return;
    const { container, title, progress, hint } = this.fieldDrillBanner;
    if (!status.active) {
      container.dataset.visible = "false";
      container.style.display = "none";
      delete container.dataset.kind;
      title.textContent = "";
      progress.textContent = "";
      hint.textContent = "";
      return;
    }
    container.dataset.visible = "true";
    container.style.display = "flex";
    if (status.tone) {
      container.dataset.kind = status.tone;
    } else {
      delete container.dataset.kind;
    }
    title.textContent = status.title ?? "";
    progress.textContent = status.progress ?? "";
    hint.textContent = status.hint ?? "";
  }

  private updateSupportBoost(state: GameState): void {
    if (!this.supportBoostBanner) return;
    const boost =
      state.supportBoost ??
      ({
        lane: null,
        remaining: 0,
        duration: 0,
        multiplier: 1,
        cooldownRemaining: 0
      } satisfies GameState["supportBoost"]);

    const active = boost.remaining > 0 && Number.isFinite(boost.lane);
    const container = this.supportBoostBanner.container;

    if (!active) {
      container.dataset.visible = "false";
      container.style.display = "none";
      return;
    }

    container.dataset.visible = "true";
    container.style.display = "flex";

    const laneLabel = this.formatLaneLabel(boost.lane);
    const percentDelta =
      typeof boost.multiplier === "number" && Number.isFinite(boost.multiplier)
        ? Math.round((boost.multiplier - 1) * 100)
        : 0;
    const effectLabel =
      percentDelta !== 0
        ? `${percentDelta > 0 ? "+" : ""}${percentDelta}% fire rate`
        : `x${(boost.multiplier ?? 1).toFixed(2)}`;

    this.supportBoostBanner.label.textContent = `Support Surge: ${laneLabel} ${effectLabel}`;
    this.supportBoostBanner.timer.textContent = this.formatSeconds(boost.remaining);
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

  private formatSeconds(value: number): string {
    if (!Number.isFinite(value)) {
      return "-";
    }
    return `${value <= 9.95 ? value.toFixed(1) : Math.round(value)}s`;
  }

  private formatTitleLabel(value: string | null | undefined): string {
    if (!value) {
      return "";
    }
    return value
      .split(/[-_]/g)
      .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
      .join(" ");
  }

  private formatFireRateEffect(multiplier: number | null | undefined): string | null {
    if (typeof multiplier !== "number" || !Number.isFinite(multiplier) || multiplier <= 0) {
      return null;
    }
    const deltaPercent = Math.round((multiplier - 1) * 100);
    if (deltaPercent === 0) {
      return null;
    }
    const sign = deltaPercent > 0 ? "+" : "";
    return `${sign}${deltaPercent}% turret fire rate`;
  }
}
