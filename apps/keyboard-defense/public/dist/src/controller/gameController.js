// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
import { defaultConfig } from "../core/config.js";
import { defaultWordBank } from "../core/wordBank.js";
import { GameEngine } from "../engine/gameEngine.js";
import { CanvasRenderer } from "../rendering/canvasRenderer.js";
import { ResolutionTransitionController } from "../ui/ResolutionTransitionController.js";
import { HudView } from "../ui/hud.js";
import { DiagnosticsOverlay } from "../ui/diagnostics.js";
import { TypingDrillsOverlay } from "../ui/typingDrills.js";
import { formatHudFontScale, getNextHudFontPreset, normalizeHudFontScaleValue } from "../ui/fontScale.js";
import { LoadingScreen } from "../ui/loadingScreen.js";
import { SessionWellness } from "../ui/sessionWellness.js";
import { DebugApi } from "../debug/debugApi.js";
import { SoundManager } from "../audio/soundManager.js";
import { AssetLoader, toSvgDataUri } from "../assets/assetLoader.js";
import { TutorialManager } from "../tutorial/tutorialManager.js";
import { clearTutorialCompletion, readTutorialCompletion, writeTutorialCompletion } from "../tutorial/tutorialPersistence.js";
import { createDefaultPlayerSettings, readPlayerSettings as loadPlayerSettingsFromStorage, withPatchedPlayerSettings, writePlayerSettings, TURRET_PRESET_IDS } from "../utils/playerSettings.js";
import { TelemetryClient } from "../telemetry/telemetryClient.js";
import { calculateCanvasResolution, createDprListener } from "../utils/canvasResolution.js";
import { buildResolutionChangeEntry } from "../utils/canvasTransition.js";
import { deriveStarfieldState } from "../utils/starfield.js";
import { defaultStarfieldConfig } from "../config/starfield.js";
import { listNewLoreForWave } from "../data/lore.js";
import { buildLoreScrollProgress, listNewLoreScrollsForLessons } from "../data/loreScrolls.js";
import { readLoreProgress, writeLoreProgress } from "../utils/lorePersistence.js";
import { readLessonProgress, writeLessonProgress, LESSON_PROGRESS_VERSION } from "../utils/lessonProgress.js";
import { buildLessonMedalViewState, readLessonMedalProgress, recordLessonMedal, writeLessonMedalProgress } from "../utils/lessonMedals.js";
import { exportProgressTransferPayload, importProgressTransferPayload } from "../utils/progressTransfer.js";
import { recordDropoffReason } from "../utils/dropoffReasons.js";
import { computeLockoutUntilMs, getLockoutRemainingMs, getLocalDayKey, isLockoutActive, readScreenTimeSettings, readScreenTimeUsage, writeScreenTimeSettings, writeScreenTimeUsage } from "../utils/screenTimeGoals.js";
import { buildSessionTimelineCsv } from "../utils/sessionTimelineReport.js";
import { buildKeystrokeTimingHistogramCsv, summarizeKeystrokeTimings } from "../utils/keystrokeTimingReport.js";
import { buildKeystrokeTimingGate, createDefaultKeystrokeTimingProfileState, readKeystrokeTimingProfile, recordKeystrokeTimingProfileRun, writeKeystrokeTimingProfile } from "../utils/keystrokeTimingProfile.js";
import { createDefaultSpacedRepetitionState, listDueSpacedRepetitionPatterns, readSpacedRepetitionState, recordSpacedRepetitionObservedStats, writeSpacedRepetitionState } from "../utils/spacedRepetition.js";
import { createStuckKeyDetectorState, updateStuckKeyDetector } from "../utils/inputAnomalies.js";
import { createFatigueDetectorState, snoozeFatigueDetector, updateFatigueDetector } from "../utils/fatigueDetector.js";
import { buildSessionGoalsMetrics, buildSessionGoalsView, createDefaultSessionGoalsState, readSessionGoals, recordSessionGoalsRun, seedSessionGoalsFromPlacement, writeSessionGoals } from "../utils/sessionGoals.js";
import { getTopExpectedKeys, readErrorClusterProgress, recordErrorClusterEntry, writeErrorClusterProgress } from "../utils/errorClusters.js";
import { readPlacementTestResult } from "../utils/placementTest.js";
import { buildWpmLadderView, readWpmLadderProgress, recordWpmLadderRun, writeWpmLadderProgress } from "../utils/wpmLadder.js";
import { buildSfxLibraryView, getSfxLibraryDefinition, markSfxLibraryAudition, readSfxLibraryState, setActiveSfxLibrary, writeSfxLibraryState } from "../utils/sfxLibrary.js";
import { buildUiSchemeView, getUiSchemeDefinition, markUiSchemeAudition, readUiSchemeState, setActiveUiScheme, writeUiSchemeState } from "../utils/uiSoundScheme.js";
import { buildMusicStemView, getMusicStemDefinition, markMusicStemAudition, readMusicStemState, setActiveMusicStem, writeMusicStemState } from "../utils/musicStems.js";
import { readDayNightTheme, writeDayNightTheme } from "../utils/dayNightTheme.js";
import { readPracticeLaneFocus, writePracticeLaneFocus } from "../utils/practiceLaneFocus.js";
import { CHALLENGE_MODIFIERS_VERSION, buildChallengeModifiersViewState, getDefaultChallengeModifiersSelection, normalizeChallengeModifiersSelection, readChallengeModifiers, writeChallengeModifiers } from "../utils/challengeModifiers.js";
import { readParallaxScene, resolveParallaxScene, writeParallaxScene } from "../utils/parallaxBackground.js";
import { normalizeFocusOutlinePreset } from "../utils/focusOutlines.js";
import { buildBiomeGalleryView, readBiomeGallery, recordBiomeRun, setActiveBiome, writeBiomeGallery } from "../utils/biomeGallery.js";
import { computeCurrentStreak, maybeAwardStreakToken, readStreakTokens, writeStreakTokens } from "../utils/streakTokens.js";
import { buildTrainingCalendarView, drillSummaryToCalendarDelta, readTrainingCalendar, recordTrainingDay, writeTrainingCalendar } from "../utils/trainingCalendar.js";
import { buildDailyQuestBoardView, readDailyQuestBoard, recordDailyQuestCampaignRun, recordDailyQuestDrill, writeDailyQuestBoard } from "../utils/dailyQuests.js";
import { buildWeeklyQuestBoardView, buildWeeklyTrialWaveConfig, readWeeklyQuestBoard, recordWeeklyQuestCampaignRun, recordWeeklyQuestDrill, recordWeeklyQuestTrialAttempt, writeWeeklyQuestBoard } from "../utils/weeklyQuest.js";
import { buildSeasonTrackProgress, listSeasonTrack } from "../data/seasonTrack.js";
import { selectAmbientProfile } from "../audio/ambientProfiles.js";
import { getEnemyBiography } from "../data/bestiary.js";
const FRAME_DURATION = 1 / 60;
const BUILD_MENU_TIME_SCALE = 0.35;
const TUTORIAL_VERSION = "v2";
const SOUND_VOLUME_MIN = 0;
const SOUND_VOLUME_MAX = 1;
const SOUND_VOLUME_DEFAULT = 0.8;
const AUDIO_INTENSITY_MIN = 0.5;
const AUDIO_INTENSITY_MAX = 1.5;
const AUDIO_INTENSITY_DEFAULT = 1;
const MUSIC_LEVEL_MIN = 0;
const MUSIC_LEVEL_MAX = 1;
const MUSIC_LEVEL_DEFAULT = 0.65;
const SCREEN_SHAKE_INTENSITY_MIN = 0;
const SCREEN_SHAKE_INTENSITY_MAX = 1.2;
const SCREEN_SHAKE_INTENSITY_DEFAULT = 0.65;
const SCREEN_SHAKE_BASE = {
    muzzle: 1.2,
    hit: 2.4,
    breach: 3.2,
    preview: 2.8
};
const SCREEN_SHAKE_DURATION = {
    muzzle: 0.25,
    hit: 0.4,
    breach: 0.55,
    preview: 0.45
};
const SCREEN_SHAKE_MAX_OFFSET = 8;
const ACCESSIBILITY_SELF_TEST_DEFAULT = {
    lastRunAt: null,
    soundConfirmed: false,
    visualConfirmed: false,
    motionConfirmed: false
};
const CANVAS_BASE_WIDTH = 960;
const CANVAS_BASE_HEIGHT = 540;
const BG_BRIGHTNESS_MIN = 0.9;
const BG_BRIGHTNESS_MAX = 1.1;
const BG_BRIGHTNESS_DEFAULT = 1;
const HUD_ZOOM_MIN = 0.8;
const HUD_ZOOM_MAX = 1.2;
const HUD_ZOOM_DEFAULT = 1;
const HUD_LAYOUT_DEFAULT = "right";
const FOCUS_OUTLINE_DEFAULT = "system";
const INPUT_LATENCY_SAMPLE_MS = 500;
const INPUT_LATENCY_WINDOW = 8;
const INPUT_LATENCY_WARN_MS = 40;
const INPUT_LATENCY_BAD_MS = 75;
const INPUT_LATENCY_SPARKLINE_WIDTH = 80;
const INPUT_LATENCY_SPARKLINE_HEIGHT = 18;
const INPUT_LATENCY_SPARKLINE_CAP_MS = 120;
const KEYSTROKE_TIMING_MAX_SAMPLES = 1500;
const KEYSTROKE_TIMING_MIN_GAP_MS = 20;
const KEYSTROKE_TIMING_MAX_GAP_MS = 2000;
const KEYSTROKE_TIMING_GATE_WINDOW_SAMPLES = 220;
const KEYSTROKE_TIMING_GATE_UPDATE_MS = 850;
const KEYSTROKE_TIMING_GATE_SMOOTHING_ALPHA = 0.2;
const LATENCY_SPARKLINE_KEY = "keyboard-defense:latency-sparkline";
const HUD_VISIBILITY_KEY = "keyboard-defense:hud-visibility";
const WAVE_PREVIEW_THREAT_KEY = "keyboard-defense:wave-preview-threat";
const COLORBLIND_MODE_KEY = "keyboard-defense:colorblind-mode";
const CONTEXTUAL_HINTS_KEY = "keyboard-defense:contextual-hints";
const HOTKEY_STORAGE_KEY = "keyboard-defense:hotkeys";
const VIRTUAL_KEYBOARD_LAYOUTS = new Set(["qwerty", "qwertz", "azerty"]);
const DEFAULT_VIRTUAL_KEYBOARD_LAYOUT = "qwerty";
const WAVE_MICRO_TIPS = [
    "Keep wrists lifted and let fingers hover over home row-no desk planting.",
    "Aim for light taps. If keys feel loud, ease up and keep rhythm steady.",
    "Reset posture: shoulders relaxed, elbows at 90°, screen at eye height.",
    "Eyes on the words, not the keys; touch typing keeps accuracy higher.",
    "Short breaths between waves keep hands loose and reduce errors.",
    "If accuracy dips, slow two beats, rebuild clean strokes, then speed up."
];
const LANE_LABELS = ["A", "B", "C", "D", "E"];
const CANVAS_RESIZE_FADE_MS = 250;
const CANVAS_RESOLUTION_HOLD_MS = 70;
const MAX_CANVAS_RESOLUTION_EVENTS = 10;
const STARFIELD_PRESETS = {
    calm: { scene: "calm", waveProgress: 0.15, castleHealthRatio: 1, freeze: true },
    warning: { scene: "warning", waveProgress: 0.55, castleHealthRatio: 0.55 },
    breach: { scene: "breach", waveProgress: 0.9, castleHealthRatio: 0.25 }
};
const LORE_VERSION = "v1";
const SESSION_TIMER_TICK_MS = 1000;
const BREAK_REMINDER_INTERVAL_DEFAULT_MINUTES = 20;
const BREAK_REMINDER_INTERVAL_ALLOWED_MINUTES = new Set([0, 10, 20, 30, 45]);
const BREAK_REMINDER_INTERVAL_STORAGE_KEY = "keyboard-defense:break-reminder-interval";
const BREAK_REMINDER_SNOOZE_MS = 10 * 60 * 1000;
const ASSET_PREWARM_BATCH = 32;
const ASSET_PREWARM_TIMEOUT_MS = 300;
const FIRST_ENCOUNTER_STORAGE_KEY = "keyboard-defense:first-encounter-enemies";
const ACCESSIBILITY_ONBOARDING_KEY = "keyboard-defense:accessibility-onboarding";
const MEMORY_SAMPLE_INTERVAL_MS = 5_000;
const MEMORY_WARNING_RATIO = 0.82;
function svgCircleDataUri(primary, accent) {
    const svg = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'>` +
        `<defs><radialGradient id='g' cx='50%' cy='40%' r='60%'>` +
        `<stop offset='0%' stop-color='${accent}'/>` +
        `<stop offset='100%' stop-color='${primary}'/>` +
        `</radialGradient></defs>` +
        `<circle cx='32' cy='32' r='28' fill='url(#g)'/>` +
        `</svg>`;
    return toSvgDataUri(svg);
}
function svgTurretDataUri(base, barrel) {
    const svg = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'>` +
        `<circle cx='26' cy='32' r='16' fill='${base}'/>` +
        `<rect x='26' y='28' width='28' height='8' rx='4' fill='${barrel}'/>` +
        `</svg>`;
    return toSvgDataUri(svg);
}
function svgCastleDataUri(visual, level) {
    const merlons = Math.max(3, Math.min(7, level + 2));
    const towerHeight = 44 + level * 2;
    const towerWidth = 30 + level * 3;
    const bodyHeight = 34 + level * 3;
    const bodyWidth = 46 + level * 4;
    const merlonWidth = bodyWidth / merlons;
    let merlonRects = "";
    for (let i = 0; i < merlons; i += 1) {
        const x = (64 - bodyWidth) / 2 + i * merlonWidth + 1;
        merlonRects += `<rect x='${x.toFixed(2)}' y='${64 - towerHeight - 10}' width='${(merlonWidth - 2).toFixed(2)}' height='6' rx='2' fill='${visual.border}' />`;
    }
    const svg = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'>` +
        `<rect x='${(64 - bodyWidth) / 2}' y='${64 - bodyHeight}' width='${bodyWidth}' height='${bodyHeight}' rx='4' fill='${visual.fill}' stroke='${visual.border}' stroke-width='3'/>` +
        `<rect x='${(64 - towerWidth) / 2}' y='${64 - towerHeight}' width='${towerWidth}' height='${towerHeight}' rx='5' fill='${visual.accent}' opacity='0.85'/>` +
        merlonRects +
        `<circle cx='32' cy='${64 - towerHeight + 10}' r='6' fill='${visual.border}' opacity='0.3'/>` +
        `</svg>`;
    return toSvgDataUri(svg);
}
export class GameController {
    constructor(options) {
        this.options = options;
        if (!options.canvas) {
            throw new Error("GameController requires a canvas element.");
        }
        this.canvas = options.canvas;
        this.canvasResolution = null;
        this.canvasResolutionEvents = [];
        this.currentDevicePixelRatio = this.getDevicePixelRatio();
        this.resolutionTransitionController =
            typeof window !== "undefined"
                ? new ResolutionTransitionController(this.canvas, {
                    fadeMs: CANVAS_RESIZE_FADE_MS - CANVAS_RESOLUTION_HOLD_MS,
                    holdMs: CANVAS_RESOLUTION_HOLD_MS,
                    onStateChange: (state) => this.handleCanvasTransitionStateChange(state)
                })
                : null;
        if (typeof document !== "undefined" && document.body) {
            document.body.dataset.canvasTransition = document.body.dataset.canvasTransition ?? "idle";
        }
        this.canvasResizeObserver = null;
        this.viewportResizeHandler = null;
        this.dprListener = null;
        this.canvasResizeTimeout = null;
        this.updateCanvasResolution(true, "initial");
        this.running = false;
        this.speedMultiplier = 1;
        this.uiTimeScaleMultiplier = 1;
        this.sessionWallTimeSeconds = 0;
        this.lastTimestamp = null;
        this.rafId = null;
        this.soundEnabled = true;
        this.soundVolume = SOUND_VOLUME_DEFAULT;
        this.audioIntensity = AUDIO_INTENSITY_DEFAULT;
        this.musicEnabled = true;
        this.musicLevel = MUSIC_LEVEL_DEFAULT;
        this.musicStems = {
            activeId: "siege-suite",
            auditioned: [],
            dynamicEnabled: true,
            updatedAt: null
        };
        this.musicPreviewTimeout = null;
        this.uiSoundScheme = { activeId: "clarity", auditioned: [], updatedAt: null };
        this.uiSchemePreviewTimeout = null;
        this.sfxLibrary = { activeId: "classic", auditioned: [], updatedAt: null };
        this.screenShakeEnabled = false;
        this.screenShakeIntensity = SCREEN_SHAKE_INTENSITY_DEFAULT;
        this.screenShakeBursts = [];
        this.accessibilitySelfTest = { ...ACCESSIBILITY_SELF_TEST_DEFAULT };
        this.reducedMotionEnabled = false;
        this.checkeredBackgroundEnabled = false;
        this.virtualKeyboardEnabled = false;
        this.virtualKeyboardLayout = DEFAULT_VIRTUAL_KEYBOARD_LAYOUT;
        this.hapticsEnabled = false;
        this.textSizeScale = 1;
        this.readableFontEnabled = false;
        this.dyslexiaFontEnabled = false;
        this.dyslexiaSpacingEnabled = false;
        this.reducedCognitiveLoadEnabled = false;
        this.audioNarrationEnabled = false;
        this.accessibilityPresetEnabled = false;
        this.voicePackId = "mentor-classic";
        this.tutorialPacing = 1;
        this.largeSubtitlesEnabled = false;
        this.backgroundBrightness = BG_BRIGHTNESS_DEFAULT;
        this.colorblindPaletteEnabled = false;
        this.colorblindPaletteMode = "off";
        this.lastColorblindMode = "deuteran";
        this.focusOutlinePreset = FOCUS_OUTLINE_DEFAULT;
        this.dayNightTheme = "night";
        this.parallaxScene = "auto";
        this.latencyIndicator = null;
        this.latencySparklineEnabled = this.loadLatencySparklineEnabled();
        this.latencySparkline = null;
        this.latencySamples = [];
        this.latencyMonitorTimeout = null;
        this.keystrokeTimingSamples = [];
        this.lastKeystrokeTimingAt = null;
        this.fatigueWaveTimingSamples = [];
        this.fatigueDetectorState = createFatigueDetectorState();
        this.sessionGoals = createDefaultSessionGoalsState();
        this.sessionGoalsFinalized = false;
        this.sessionGoalsNextUpdateAt = 0;
        this.keystrokeTimingProfile = createDefaultKeystrokeTimingProfileState();
        this.keystrokeTimingProfileFinalized = false;
        this.keystrokeTimingGateSnapshot = null;
        this.keystrokeTimingGateMultiplier = 1;
        this.keystrokeTimingGateNextUpdateAt = 0;
        this.spacedRepetition = createDefaultSpacedRepetitionState();
        this.spacedRepetitionLastSavedAt = 0;
        this.spacedRepetitionWaveStats = { keys: {}, digraphs: {} };
        this.spacedRepetitionLastProgress = { enemyId: null, buffer: "" };
        this.errorClusterProgress = null;
        this.errorClusterLastSavedAt = null;
        this.waveMicroTipIndex =
            Math.floor((typeof Math !== "undefined" ? Math.random() : 0) * WAVE_MICRO_TIPS.length) % WAVE_MICRO_TIPS.length;
        this.hudVisibility = this.loadHudVisibilityPrefs();
        this.wavePreviewThreatIndicatorsEnabled = this.loadWavePreviewThreatIndicatorsEnabled();
        this.contextualHintsSeen = this.loadContextualHintsSeen();
        this.hotkeys = this.loadHotkeys();
        this.accessibilityOnboardingSeen = this.loadAccessibilitySeen();
        this.accessibilityOverlay = null;
        this.resumeAfterAccessibility = false;
        this.loadingScreen =
            typeof document !== "undefined"
                ? new LoadingScreen({
                    containerId: "loading-screen",
                    statusId: "loading-status",
                    tipId: "loading-tip"
                })
                : null;
        if (this.loadingScreen) {
            this.loadingScreen.show("Loading pixel defenders...");
        }
        this.defeatAnimationMode = "auto";
        this.starfieldOverride = null;
        this.lastStarfieldSummary = null;
        this.starfieldConfig = defaultStarfieldConfig;
        this.starfieldState = null;
        this.lowGraphicsEnabled = false;
        this.lowGraphicsRestoreState = null;
        this.hudZoom = 1;
        this.hudLayout = HUD_LAYOUT_DEFAULT;
        this.castleSkin = "classic";
        this.hudFontScale = 1;
        this.firstEncounterSeen = this.loadFirstEncounterSeen();
        this.enemyIntroOverlay = null;
        this.enemyIntroActiveTier = null;
        this.resumeAfterEnemyIntro = false;
        this.impactEffects = [];
        this.turretRangeHighlightSlot = null;
        this.turretRangePreviewType = null;
        this.turretRangePreviewLevel = null;
        this.bestCombo = 0;
        this.sessionStartMs = typeof performance !== "undefined" ? performance.now() : 0;
        this.breakReminderIntervalMinutes = this.loadBreakReminderIntervalMinutes();
        this.sessionWellness = null;
        this.sessionTimerInterval = null;
        this.sessionNextReminderMs =
            this.breakReminderIntervalMinutes > 0
                ? this.breakReminderIntervalMinutes * 60 * 1000
                : Number.POSITIVE_INFINITY;
        this.sessionReminderActive = false;
        const screenTimeStorage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.screenTimeSettings = readScreenTimeSettings(screenTimeStorage);
        this.screenTimeUsage = readScreenTimeUsage(screenTimeStorage);
        this.screenTimeLastTickWallMs = Date.now();
        this.screenTimeNextPersistAtMs = 0;
        this.screenTimeLastTotalMs = this.screenTimeUsage.totalMs;
        this.screenTimeWarned = false;
        this.screenTimeGoalReached = false;
        this.screenTimeLockoutStarted = false;
        this.screenTimeTodayBadge =
            typeof document !== "undefined" ? document.getElementById("screen-time-today") : null;
        this.playerSettings = createDefaultPlayerSettings();
        this.lastAmbientProfile = null;
        this.lastGameStatus = null;
        this.unlockedLore = new Set();
        this.seasonTrackRewards = listSeasonTrack();
        this.lessonProgress = {
            lessonsCompleted: 0,
            unlockedScrolls: new Set()
        };
        this.turretLoadoutPresets = Object.create(null);
        this.activeTurretPresetId = null;
        this.lastTurretSignature = "";
        this.tutorialHoldLoop = false;
        this.waveScorecardActive = false;
        this.resumeAfterWaveScorecard = false;
        this.optionsOverlayActive = false;
        this.resumeAfterOptions = false;
        this.menuActive = false;
        this.fullscreenSupported =
            typeof document !== "undefined" &&
                (document.fullscreenEnabled ?? Boolean(document.documentElement?.requestFullscreen));
        this.fullscreenChangeHandler = null;
        this.isFullscreen = false;
        this.tutorialCompleted = false;
        this.pendingTutorialSummary = null;
        this.typingDrills = null;
        this.typingDrillsOverlayActive = false;
        this.shouldResumeAfterDrills = false;
        this.reopenOptionsAfterDrills = false;
        this.reopenWaveScorecardAfterDrills = false;
        this.lastWaveScorecardData = null;
        this.typingDrillCta = document.getElementById("typing-drills-cta-reco");
        this.typingDrillCtaMode =
            this.typingDrillCta?.querySelector?.(".typing-drills-cta-reco-mode") ?? null;
        this.typingDrillCtaLastRecommendation = null;
        this.typingDrillMenuReco = document.getElementById("main-menu-typing-drill-reco");
        this.typingDrillMenuRecoMode =
            this.typingDrillMenuReco?.querySelector?.(".main-menu-typing-drill-reco-mode") ?? null;
        this.typingDrillMenuRecoLastRecommendation = null;
        this.typingDrillMenuRunButton = document.getElementById("main-menu-typing-drill-run");
        this.practiceMode = false;
        this.practiceLaneFocusLane = null;
        this.challengeModifiers = null;
        this.lastTypingInputContext = null;
        this.typoRecoveryActive = false;
        this.typoRecoveryStep = 0;
        this.typoRecoveryDeadlineAtMs = 0;
        this.typoRecoveryWaveIndex = null;
        this.typoRecoveryComboBeforeError = 0;
        this.typoRecoveryCooldownUntilMs = 0;
        this.weeklyQuestBoard = null;
        this.weeklyTrialActive = false;
        this.weeklyTrialFinalized = false;
        this.weeklyTrialReturnPending = false;
        this.weeklyTrialBackup = null;
        this.allTurretArchetypes = Object.create(null);
        this.enabledTurretTypes = new Set();
        this.featureToggles = { ...defaultConfig.featureToggles };
        this.debugCrystalToggle = null;
        this.debugEliteToggle = null;
        this.debugDowngradeToggle = null;
        this.mainMenuCrystalToggle = null;
        this.mainMenuEliteToggle = null;
        const mergedTurretArchetypes = {
            ...defaultConfig.turretArchetypes,
            ...(options.config?.turretArchetypes ?? {})
        };
        const initialFeatureToggles = {
            ...defaultConfig.featureToggles,
            ...(options.config?.featureToggles ?? {})
        };
        this.featureToggles = { ...initialFeatureToggles };
        this.starfieldEnabled = Boolean(this.featureToggles.starfieldParallax);
        const mergedConfig = {
            ...defaultConfig,
            ...options.config,
            turretArchetypes: mergedTurretArchetypes,
            featureToggles: this.featureToggles
        };
        this.allTurretArchetypes = mergedTurretArchetypes;
        const config = this.applyTurretFeatureToggles(mergedConfig);
        const telemetryEnabled = Boolean(config.featureToggles.telemetry);
        this.telemetryClient = telemetryEnabled
            ? new TelemetryClient({
                enabled: true,
                onQueueChange: () => this.syncTelemetryDebugControls()
            })
            : null;
        this.engine = new GameEngine({
            config,
            seed: options.seed,
            telemetryClient: this.telemetryClient ?? undefined
        });
        this.analyticsExportEnabled = config.featureToggles.analyticsExport;
        this.telemetryEnabled = telemetryEnabled;
        this.telemetryEndpoint = this.telemetryClient?.getEndpoint?.() ?? null;
        this.telemetryDebugControls = null;
        this.soundDebugControls = null;
        this.memorySample = null;
        this.nextMemorySampleAt = 0;
        const atlasEnabled = Boolean(config.featureToggles?.assetAtlas);
        this.assetLoader = new AssetLoader({
            useAtlas: atlasEnabled,
            atlasUrl: "./assets/atlas.json"
        });
        this.assetIntegritySummary = this.assetLoader.getIntegritySummary?.() ?? null;
        this.assetIntegrityUnsubscribe =
            typeof this.assetLoader.onIntegrityUpdate === "function"
                ? this.assetLoader.onIntegrityUpdate((summary) => {
                    this.assetIntegritySummary = summary ?? null;
                    this.syncAssetIntegrityFlags();
                })
                : null;
        this.initializeLessonProgress();
        this.initializeLessonMedals();
        this.initializeSfxLibrary();
        this.initializeUiSoundScheme();
        this.initializeMusicStems();
        this.initializeWpmLadder();
        this.initializeTrainingCalendar();
        this.initializeDailyQuestBoard();
        this.initializeWeeklyQuestBoard();
        this.initializePracticeLaneFocus();
        this.initializeChallengeModifiers();
        this.initializeStreakTokens();
        this.initializeBiomeGallery();
        this.initializeDayNightTheme();
        this.initializeParallaxScene();
        this.initializeLoreProgress();
        this.assetReady = false;
        this.assetStartPending = false;
        this.assetReadyPromise = Promise.resolve();
        this.assetPrewarmScheduled = false;
        this.assetLoaderUnsubscribe = this.assetLoader.onImageLoaded(() => {
            this.handleAssetImageLoaded();
        });
        this.syncAssetIntegrityFlags();
        const setLoadingStatus = (text) => {
            if (this.loadingScreen && typeof text === "string") {
                this.loadingScreen.setStatus(text);
            }
        };
        const castleSprites = {};
        for (const levelConfig of config.castleLevels ?? []) {
            const spriteKey = levelConfig.spriteKey ?? `castle-level-${levelConfig.level}`;
            if (!spriteKey)
                continue;
            const visual = levelConfig.visual ?? {
                fill: "#475569",
                border: "#1f2937",
                accent: "#22d3ee"
            };
            castleSprites[spriteKey] = svgCastleDataUri(visual, levelConfig.level);
        }
        const fallbackSprites = {
            "enemy-grunt": svgCircleDataUri("#f87171", "#fca5a5"),
            "enemy-runner": svgCircleDataUri("#34d399", "#6ee7b7"),
            "enemy-brute": svgCircleDataUri("#a78bfa", "#c4b5fd"),
            "enemy-witch": svgCircleDataUri("#fb7185", "#fda4af"),
            "turret-arrow": svgTurretDataUri("#38bdf8", "#0c4a6e"),
            "turret-arcane": svgTurretDataUri("#c084fc", "#581c87"),
            "turret-flame": svgTurretDataUri("#fb923c", "#9a3412"),
            "turret-crystal": svgTurretDataUri("#67e8f9", "#0f766e"),
            ...castleSprites
        };
        if (atlasEnabled) {
            setLoadingStatus("Packing sprite atlas...");
        }
        else {
            setLoadingStatus("Loading sprites and defenses...");
        }
        const atlasPromise = atlasEnabled
            ? this.assetLoader
                .loadAtlas(this.assetLoader.atlasUrl ?? "./assets/atlas.json")
                .catch((error) => {
                console.warn("[assets] atlas load failed; falling back to loose sprites.", error);
                return undefined;
            })
            : Promise.resolve();
        const manifestPromise = atlasPromise
            .catch(() => undefined)
            .then(() => {
            setLoadingStatus("Loading sprites, sounds, and effects...");
            const skip = new Set(this.assetLoader.listAtlasKeys?.() ?? []);
            return this.assetLoader
                .loadManifest("./assets/manifest.json", { skip })
                .then(() => {
                const missing = Object.keys(fallbackSprites).filter((key) => !this.assetLoader.getImage(key));
                if (missing.length > 0) {
                    const subset = Object.fromEntries(missing.map((key) => [key, fallbackSprites[key]]));
                    return this.assetLoader.loadImages(subset);
                }
                return undefined;
            });
        })
            .catch((error) => {
            console.warn("Asset manifest load failed; using inline sprites.", error);
            return this.assetLoader.loadImages(fallbackSprites);
        });
        this.assetLoadPromise = manifestPromise.then(() => {
            setLoadingStatus("Preparing castle visuals...");
            this.syncDefeatAnimationPreferences();
            return undefined;
        });
        this.assetReadyPromise = manifestPromise
            .catch(() => undefined)
            .then(() => this.assetLoader.whenIdle())
            .then(() => {
            this.assetReady = true;
            if (this.assetLoaderUnsubscribe) {
                this.assetLoaderUnsubscribe();
                this.assetLoaderUnsubscribe = null;
            }
            setLoadingStatus("Finalizing battle prep...");
            this.syncDefeatAnimationPreferences();
            this.scheduleAssetPrewarm();
            if (this.loadingScreen) {
                this.loadingScreen.hide();
            }
        })
            .catch((error) => {
            console.warn("Asset loading encountered an issue; continuing with fallbacks.", error);
            this.assetReady = true;
            if (this.assetLoaderUnsubscribe) {
                this.assetLoaderUnsubscribe();
                this.assetLoaderUnsubscribe = null;
            }
            this.scheduleAssetPrewarm();
            if (this.loadingScreen) {
                this.loadingScreen.hide();
            }
        });
        manifestPromise
            .then(() => this.render())
            .catch((error) => {
            console.warn("Asset load failed, continuing with procedural sprites.", error);
        });
        this.renderer = new CanvasRenderer(options.canvas, this.engine.config, this.assetLoader);
        this.syncCanvasResizeCause();
        this.attachCanvasResizeObserver();
        this.attachDevicePixelRatioListener();
        this.syncDefeatAnimationPreferences();
        this.hud = new HudView(this.engine.config, {
            healthBar: "castle-health-bar",
            goldLabel: "resource-gold",
            goldDelta: "resource-delta",
            activeWord: "active-word",
            typingAccuracy: "typing-accuracy",
            typingWpm: "typing-wpm",
            typingInput: "typing-input",
            companionPet: "companion-pet",
            companionMoodLabel: "companion-mood-label",
            companionTip: "companion-tip",
            virtualKeyboard: "virtual-keyboard",
            fullscreenButton: "fullscreen-button",
            upgradePanel: "upgrade-panel",
            comboLabel: "combo-stats",
            comboAccuracyDelta: "combo-accuracy-delta",
            eventLog: "battle-log",
            eventLogSummary: "battle-log-summary",
            eventLogFilters: "battle-log-filters",
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
                musicToggle: "options-music-toggle",
                musicLevelSlider: "options-music-level",
                musicLevelValue: "options-music-level-value",
                musicLibraryButton: "options-music-library",
                musicLibrarySummary: "options-music-library-label",
                uiSoundLibraryButton: "options-ui-sound-library",
                uiSoundLibrarySummary: "options-ui-sound-library-label",
                uiSoundPreviewButton: "options-ui-sound-preview",
                screenShakeToggle: "options-screen-shake-toggle",
                screenShakeSlider: "options-screen-shake-intensity",
                screenShakeValue: "options-screen-shake-intensity-value",
                screenShakePreview: "options-screen-shake-preview",
                screenShakeDemo: "options-screen-shake-demo",
                contrastAuditButton: "options-contrast-audit",
                sfxLibraryButton: "options-sfx-library",
                sfxLibrarySummary: "options-sfx-library-label",
                stickerBookButton: "options-sticker-book",
                seasonTrackButton: "options-season-track",
                museumButton: "options-museum",
                sideQuestButton: "options-side-quests",
                masteryCertificateButton: "options-mastery-certificate",
                lessonMedalButton: "options-lesson-medals",
                wpmLadderButton: "options-wpm-ladder",
                trainingCalendarButton: "options-training-calendar",
                biomeGalleryButton: "options-biome-gallery",
                parentSummaryButton: "options-parent-summary",
                endSessionButton: "options-end-session",
                selfTestContainer: "options-self-test",
                selfTestRun: "options-self-test-run",
                selfTestStatus: "options-self-test-status",
                selfTestSoundToggle: "options-self-test-sound",
                selfTestVisualToggle: "options-self-test-visual",
                selfTestMotionToggle: "options-self-test-motion",
                selfTestSoundIndicator: "options-self-test-sound-indicator",
                selfTestVisualIndicator: "options-self-test-visual-indicator",
                selfTestMotionIndicator: "options-self-test-motion-indicator",
                diagnosticsToggle: "options-diagnostics-toggle",
                virtualKeyboardToggle: "options-virtual-keyboard-toggle",
                virtualKeyboardLayoutSelect: "options-virtual-keyboard-layout",
                lowGraphicsToggle: "options-low-graphics-toggle",
                hapticsToggle: "options-haptics-toggle",
                textSizeSelect: "options-text-size",
                reducedMotionToggle: "options-reduced-motion-toggle",
                checkeredBackgroundToggle: "options-checkered-bg-toggle",
                accessibilityPresetToggle: "options-accessibility-preset",
                breakReminderIntervalSelect: "options-break-reminder-interval",
                screenTimeGoalSelect: "options-screen-time-goal",
                screenTimeLockoutSelect: "options-screen-time-lockout",
                screenTimeStatus: "options-screen-time-status",
                screenTimeResetButton: "options-screen-time-reset",
                voicePackSelect: "options-voice-pack",
                latencySparklineToggle: "options-latency-sparkline",
                readableFontToggle: "options-readable-font-toggle",
                dyslexiaFontToggle: "options-dyslexia-font-toggle",
                dyslexiaSpacingToggle: "options-dyslexia-spacing-toggle",
                cognitiveLoadToggle: "options-cognitive-load",
                milestonePopupsToggle: "options-milestone-popups",
                audioNarrationToggle: "options-audio-narration",
                subtitleLargeToggle: "options-subtitle-large",
                subtitlePreviewButton: "options-subtitle-preview",
                tutorialPacingSlider: "options-tutorial-pacing",
                tutorialPacingValue: "options-tutorial-pacing-value",
                colorblindPaletteToggle: "options-colorblind-toggle",
                colorblindPaletteSelect: "options-colorblind-mode",
                focusOutlineSelect: "options-focus-outline",
                postureChecklistButton: "options-posture-checklist",
                postureChecklistSummary: "options-posture-summary",
                backgroundBrightnessSlider: "options-bg-brightness",
                backgroundBrightnessValue: "options-bg-brightness-value",
                hudZoomSelect: "options-hud-zoom",
                hudLayoutToggle: "options-hud-left",
                layoutPreviewButton: "options-layout-preview",
                castleSkinSelect: "options-castle-skin",
                dayNightThemeSelect: "options-day-night-theme",
                parallaxSceneSelect: "options-parallax-scene",
                fontScaleSelect: "options-font-scale",
                defeatAnimationSelect: "options-defeat-animation",
                telemetryToggle: "options-telemetry-toggle",
                telemetryToggleWrapper: "options-telemetry-toggle-wrapper",
                telemetryQueueDownloadButton: "options-telemetry-queue-download",
                telemetryQueueClearButton: "options-telemetry-queue-clear",
                eliteAffixToggle: "options-elite-affix-toggle",
                eliteAffixToggleWrapper: "options-elite-affix-toggle-wrapper",
                crystalPulseToggle: "options-crystal-toggle",
                crystalPulseToggleWrapper: "options-crystal-toggle-wrapper",
                readabilityGuideButton: "options-readability-guide",
                loreScrollsButton: "options-lore-scrolls",
                analyticsExportButton: "options-analytics-export",
                sessionTimelineExportButton: "options-session-timeline-export",
                keystrokeTimingExportButton: "options-keystroke-timing-export",
                progressExportButton: "options-progress-export",
                progressImportButton: "options-progress-import"
            },
            waveScorecard: {
                container: "wave-scorecard",
                stats: "wave-scorecard-stats",
                continue: "wave-scorecard-continue",
                tip: "wave-scorecard-tip",
                coach: "wave-scorecard-coach",
                coachList: "wave-scorecard-coach-list",
                drill: "wave-scorecard-drill"
            },
            analyticsViewer: {
                container: "debug-analytics-viewer",
                tableBody: "debug-analytics-viewer-body",
                filterSelect: "debug-analytics-viewer-filter",
                drills: "debug-analytics-drills",
                tabButtons: [
                    "debug-analytics-tab-summary",
                    "debug-analytics-tab-traces",
                    "debug-analytics-tab-exports"
                ],
                panels: {
                    summary: "debug-analytics-panel-summary",
                    traces: "debug-analytics-panel-traces",
                    exports: "debug-analytics-panel-exports"
                },
                traces: "debug-analytics-traces",
                exportMeta: {
                    waves: "debug-analytics-export-waves",
                    drills: "debug-analytics-export-drills",
                    breaches: "debug-analytics-export-breaches",
                    timeToFirstTurret: "debug-analytics-export-ttf",
                    note: "debug-analytics-export-note"
                }
            },
            roadmapOverlay: {
                container: "roadmap-overlay",
                closeButton: "roadmap-overlay-close",
                list: "roadmap-list",
                summaryWave: "roadmap-summary-wave",
                summaryCastle: "roadmap-summary-castle",
                summaryLore: "roadmap-summary-lore",
                filterStory: "roadmap-filter-story",
                filterSystems: "roadmap-filter-systems",
                filterChallenge: "roadmap-filter-challenge",
                filterLore: "roadmap-filter-lore",
                filterCompleted: "roadmap-filter-completed",
                trackedContainer: "roadmap-tracked",
                trackedTitle: "roadmap-tracked-title",
                trackedProgress: "roadmap-tracked-progress",
                trackedClear: "roadmap-tracked-clear"
            },
            roadmapGlance: {
                container: "roadmap-glance",
                title: "roadmap-glance-title",
                progress: "roadmap-glance-progress",
                openButton: "roadmap-glance-open",
                clearButton: "roadmap-glance-clear"
            },
            roadmapLaunch: "roadmap-launch",
            parentalOverlay: {
                container: "parental-overlay",
                closeButton: "parental-overlay-close"
            },
            dropoffOverlay: {
                container: "dropoff-overlay",
                closeButton: "dropoff-overlay-close",
                cancelButton: "dropoff-overlay-cancel",
                skipButton: "dropoff-overlay-skip"
            },
            subtitleOverlay: {
                container: "subtitle-overlay",
                closeButton: "subtitle-overlay-close",
                toggle: "subtitle-overlay-toggle",
                summary: "subtitle-overlay-summary",
                samples: "subtitle-overlay-samples"
            },
            layoutOverlay: {
                container: "layout-overlay",
                closeButton: "layout-overlay-close",
                summary: "layout-overlay-summary",
                leftCard: "layout-overlay-left",
                rightCard: "layout-overlay-right",
                leftApply: "layout-apply-left",
                rightApply: "layout-apply-right"
            },
            contrastOverlay: {
                container: "contrast-overlay",
                list: "contrast-overlay-list",
                summary: "contrast-overlay-summary",
                closeButton: "contrast-overlay-close",
                markers: "contrast-overlay-markers"
            },
            postureOverlay: {
                container: "posture-overlay",
                list: "posture-overlay-list",
                summary: "posture-overlay-summary",
                status: "posture-overlay-status",
                closeButton: "posture-overlay-close",
                startButton: "posture-overlay-start",
                reviewButton: "posture-overlay-review"
            },
            musicOverlay: {
                container: "music-overlay",
                closeButton: "music-overlay-close",
                list: "music-overlay-list",
                summary: "music-overlay-summary"
            },
            uiSoundOverlay: {
                container: "ui-sound-overlay",
                closeButton: "ui-sound-overlay-close",
                list: "ui-sound-overlay-list",
                summary: "ui-sound-overlay-summary"
            },
            sfxOverlay: {
                container: "sfx-overlay",
                closeButton: "sfx-overlay-close",
                list: "sfx-overlay-list",
                summary: "sfx-overlay-summary"
            },
            readabilityOverlay: {
                container: "readability-overlay",
                closeButton: "readability-overlay-close",
                list: "readability-overlay-list",
                summary: "readability-overlay-summary"
            },
            stickerBookOverlay: {
                container: "sticker-overlay",
                list: "sticker-overlay-list",
                summary: "sticker-overlay-summary",
                closeButton: "sticker-overlay-close"
            },
            parentSummaryOverlay: {
                container: "parent-summary-overlay",
                closeButton: "parent-summary-close",
                closeSecondary: "parent-summary-close-secondary",
                title: "parent-summary-title",
                subtitle: "parent-summary-subtitle",
                progress: "parent-summary-progress",
                note: "parent-summary-note",
                time: "parent-summary-time",
                accuracy: "parent-summary-accuracy",
                wpm: "parent-summary-wpm",
                combo: "parent-summary-combo",
                perfect: "parent-summary-perfect",
                breaches: "parent-summary-breaches",
                drills: "parent-summary-drills",
                repairs: "parent-summary-repairs",
                download: "parent-summary-download"
            },
            seasonTrackOverlay: {
                container: "season-track-overlay",
                list: "season-track-list",
                progress: "season-track-overlay-progress",
                lessons: "season-track-overlay-lessons",
                next: "season-track-overlay-next",
                closeButton: "season-track-close"
            },
            museumOverlay: {
                container: "museum-overlay",
                closeButton: "museum-close",
                list: "museum-list",
                subtitle: "museum-overlay-subtitle"
            },
            sideQuestOverlay: {
                container: "side-quest-overlay",
                closeButton: "side-quest-close",
                list: "side-quest-list",
                subtitle: "side-quest-overlay-subtitle"
            },
            masteryCertificateOverlay: {
                container: "mastery-certificate-overlay",
                closeButton: "mastery-certificate-close",
                downloadButton: "mastery-certificate-download",
                nameInput: "mastery-certificate-name-input",
                summary: "mastery-certificate-overlay-summary",
                statsList: "mastery-certificate-stats-list",
                date: "mastery-certificate-overlay-date",
                statLessons: "mastery-certificate-stat-lessons",
                statAccuracy: "mastery-certificate-stat-accuracy",
                statWpm: "mastery-certificate-stat-wpm",
                statCombo: "mastery-certificate-stat-combo",
                statDrills: "mastery-certificate-stat-drills",
                statTime: "mastery-certificate-stat-time",
                details: "mastery-cert-details",
                detailsToggle: "mastery-cert-details-toggle"
            },
            lessonMedalOverlay: {
                container: "lesson-medal-overlay",
                closeButton: "lesson-medal-close",
                badge: "lesson-medal-overlay-badge",
                last: "lesson-medal-overlay-last",
                next: "lesson-medal-overlay-next",
                bestList: "lesson-medal-best-list",
                historyList: "lesson-medal-history-list",
                replayButton: "lesson-medal-replay"
            },
            wpmLadderOverlay: {
                container: "wpm-ladder-overlay",
                closeButton: "wpm-ladder-close",
                list: "wpm-ladder-list",
                subtitle: "wpm-ladder-subtitle",
                meta: "wpm-ladder-meta"
            },
            biomeOverlay: {
                container: "biome-overlay",
                closeButton: "biome-overlay-close",
                list: "biome-overlay-list",
                subtitle: "biome-overlay-subtitle",
                meta: "biome-overlay-meta"
            },
            trainingCalendarOverlay: {
                container: "training-calendar-overlay",
                closeButton: "training-calendar-close",
                grid: "training-calendar-grid",
                subtitle: "training-calendar-subtitle",
                legend: "training-calendar-legend"
            },
            loreScrollOverlay: {
                container: "scrolls-overlay",
                list: "scrolls-overlay-list",
                summary: "scrolls-overlay-summary",
                progress: "scrolls-overlay-progress",
                closeButton: "scrolls-overlay-close",
                filters: [
                    "scrolls-filter-all",
                    "scrolls-filter-unlocked",
                    "scrolls-filter-locked"
                ],
                searchInput: "scrolls-overlay-search"
            }
        }, {
            onCastleUpgrade: () => this.handleCastleUpgrade(),
            onCastleRepair: () => this.handleCastleRepair(),
            onPlaceTurret: (slotId, typeId) => this.handlePlaceTurret(slotId, typeId),
            onUpgradeTurret: (slotId) => this.handleUpgradeTurret(slotId),
            onDowngradeTurret: (slotId) => this.handleDowngradeTurret(slotId),
            onTurretPriorityChange: (slotId, priority) => this.handleTurretPriorityChange(slotId, priority),
            onBuildMenuToggle: (open) => this.handleBuildMenuToggle(open),
            onAnalyticsExport: this.analyticsExportEnabled ? () => this.exportAnalytics() : undefined,
            onSessionTimelineExport: () => this.exportSessionTimeline(),
            onKeystrokeTimingExport: () => this.exportKeystrokeTiming(),
            onProgressExport: () => this.exportProgress(),
            onProgressImport: () => this.importProgress(),
            onDropoffReasonSelected: (reasonId) => this.handleDropoffReasonSelected(reasonId),
            onTelemetryToggle: (enabled) => this.setTelemetryEnabled(enabled),
            onTelemetryQueueDownload: () => this.exportTelemetryQueue(),
            onTelemetryQueueClear: () => this.purgeTelemetryQueue(),
            onCrystalPulseToggle: (enabled) => this.setCrystalPulseEnabled(enabled),
            onEliteAffixesToggle: (enabled) => this.setEliteAffixesEnabled(enabled),
            onPauseRequested: () => this.openOptionsOverlay(),
            onResumeRequested: () => this.closeOptionsOverlay(),
            onSoundToggle: (enabled) => this.setSoundEnabled(enabled),
            onSoundVolumeChange: (volume) => this.setSoundVolume(volume),
            onSoundIntensityChange: (value) => this.setAudioIntensity(value),
            onMusicToggle: (enabled) => this.setMusicEnabled(enabled),
            onMusicLevelChange: (value) => this.setMusicLevel(value),
            onMusicLibrarySelect: (suiteId) => this.setMusicSuiteSelection(suiteId),
            onMusicLibraryPreview: (suiteId) => this.previewMusicSuite(suiteId),
            onUiSoundPreview: () => this.previewUiSoundScheme(this.uiSoundScheme?.activeId ?? "clarity"),
            onUiSoundSchemeSelect: (schemeId) => this.setUiSoundSchemeSelection(schemeId),
            onUiSoundSchemePreview: (schemeId) => this.previewUiSoundScheme(schemeId),
            onSfxLibrarySelect: (libraryId) => this.setSfxLibrarySelection(libraryId),
            onSfxLibraryPreview: (libraryId) => this.previewSfxLibrary(libraryId),
            onScreenShakeToggle: (enabled) => this.setScreenShakeEnabled(enabled),
            onScreenShakeIntensityChange: (value) => this.setScreenShakeIntensity(value),
            onScreenShakePreview: () => this.previewScreenShake(),
            onContrastAuditRequested: () => this.hud.runContrastAudit(),
            onAccessibilitySelfTestRun: () => this.runAccessibilitySelfTest(),
            onAccessibilitySelfTestConfirm: (kind, value) => this.setAccessibilitySelfTestConfirmation(kind, value),
            onDiagnosticsToggle: (visible) => this.setDiagnosticsVisible(visible),
            onLowGraphicsToggle: (enabled) => this.setLowGraphicsEnabled(enabled),
            onVirtualKeyboardToggle: (enabled) => this.setVirtualKeyboardEnabled(enabled),
            onVirtualKeyboardLayoutChange: (layout) => this.setVirtualKeyboardLayout(layout),
            onTextSizeChange: (scale) => this.setTextSizeScale(scale),
            onHapticsToggle: (enabled) => this.setHapticsEnabled(enabled),
            onWaveScorecardContinue: () => this.handleWaveScorecardContinue(),
            onWaveScorecardSuggestedDrill: (drill) => this.handleWaveScorecardSuggestedDrill(drill),
            onLessonMedalReplay: (options) => {
                const lastMedal = this.lessonMedalProgress?.history?.[(this.lessonMedalProgress?.history?.length ?? 1) - 1];
                const mode = options?.mode ?? lastMedal?.mode ?? "burst";
                this.openTypingDrills("medal-replay", {
                    mode,
                    autoStart: true,
                    toastMessage: options?.hint ?? "Replay a drill to chase the next medal tier."
                });
            },
            onReducedMotionToggle: (enabled) => this.setReducedMotionEnabled(enabled),
            onCheckeredBackgroundToggle: (enabled) => this.setCheckeredBackgroundEnabled(enabled),
            onAccessibilityPresetToggle: (enabled) => this.setAccessibilityPresetEnabled(enabled),
            onLargeSubtitlesToggle: (enabled) => this.setLargeSubtitlesEnabled(enabled),
            onTutorialPacingChange: (value) => this.setTutorialPacing(value),
            onAudioNarrationToggle: (enabled) => this.setAudioNarrationEnabled(enabled),
            onBreakReminderIntervalChange: (minutes) => this.setBreakReminderIntervalMinutes(minutes),
            onScreenTimeGoalChange: (minutes) => this.setScreenTimeGoalMinutes(minutes),
            onScreenTimeLockoutModeChange: (mode) => this.setScreenTimeLockoutMode(mode),
            onScreenTimeReset: () => this.resetScreenTimeForToday(),
            onVoicePackChange: (packId) => this.setVoicePack(packId),
            onLatencySparklineToggle: (enabled) => this.setLatencySparklineEnabled(enabled),
            onReadableFontToggle: (enabled) => this.setReadableFontEnabled(enabled),
            onDyslexiaFontToggle: (enabled) => this.setDyslexiaFontEnabled(enabled),
            onDyslexiaSpacingToggle: (enabled) => this.setDyslexiaSpacingEnabled(enabled),
            onCognitiveLoadToggle: (enabled) => this.setReducedCognitiveLoadEnabled(enabled),
            onColorblindPaletteToggle: (enabled) => this.setColorblindPaletteEnabled(enabled),
            onColorblindPaletteModeChange: (mode) => this.setColorblindPaletteMode(mode),
            onFocusOutlineChange: (preset) => this.setFocusOutlinePreset(preset),
            onBackgroundBrightnessChange: (value) => this.setBackgroundBrightness(value),
            onCastleSkinChange: (skin) => this.setCastleSkin(skin, { updateOptions: false }),
            onDayNightThemeChange: (mode) => this.setDayNightTheme(mode),
            onParallaxSceneChange: (scene) => this.setParallaxScene(scene),
            onBiomeSelect: (biomeId) => this.setActiveBiomeSelection(biomeId),
            onHudZoomChange: (scale) => this.setHudZoom(scale),
            onHudLayoutToggle: (leftHanded) => this.setHudLayoutSide(leftHanded ? "left" : "right"),
            onDefeatAnimationModeChange: (mode) => this.setDefeatAnimationMode(mode),
            onHudFontScaleChange: (scale) => this.setHudFontScale(scale),
            onFullscreenToggle: (next) => this.toggleFullscreen(next),
            onTurretPresetSave: (presetId) => this.handleTurretPresetSave(presetId),
            onTurretPresetApply: (presetId) => this.handleTurretPresetApply(presetId),
            onTurretPresetClear: (presetId) => this.handleTurretPresetClear(presetId),
            onTurretHover: (slotId, context) => this.handleTurretHover(slotId, context),
            onCollapsePreferenceChange: (prefs) => this.handleHudCollapsePreferenceChange(prefs)
        });
        this.hud.setCanvasTransitionState("idle");
        this.applyHudLayoutSetting(this.hudLayout);
        this.updateHudTurretAvailability();
        this.hud.setTurretDowngradeEnabled(Boolean(this.featureToggles?.turretDowngrade));
        this.sessionWellness =
            typeof document !== "undefined"
                ? new SessionWellness({
                    timerId: "session-timer",
                    reminderId: "break-reminder",
                    tipId: "break-reminder-tip",
                    snoozeId: "break-reminder-snooze",
                    resetId: "break-reminder-reset",
                    onSnooze: () => this.handleBreakReminderSnooze(),
                    onReset: () => this.handleBreakReset()
                })
                : null;
        if (this.sessionWellness) {
            this.sessionWellness.setElapsed(0);
            this.sessionTimerInterval = window.setInterval(() => this.updateSessionWellness(), SESSION_TIMER_TICK_MS);
        }
        this.attachFocusTrap();
        this.debugApi = new DebugApi(this);
        this.debugApi.expose();
        this.manualTick = Boolean(options.manualTick);
        this.currentState = this.engine.getState();
        const diagnosticsContainer = document.getElementById("diagnostics-overlay");
        if (!diagnosticsContainer) {
            throw new Error("Diagnostics overlay container missing from DOM.");
        }
        this.diagnostics = new DiagnosticsOverlay(diagnosticsContainer, {
            sectionPreferences: this.playerSettings?.diagnosticsSections,
            onPreferencesChange: (prefs) => this.handleDiagnosticsSectionPreferenceChange(prefs)
        });
        this.diagnostics.setCanvasTransitionState("idle");
        if (typeof window !== "undefined" && "AudioContext" in window) {
            this.soundManager = new SoundManager();
            this.soundManager.setLibrary(this.sfxLibrary?.activeId ?? "classic");
            this.soundManager.setUiScheme(this.uiSoundScheme?.activeId ?? "clarity");
            this.soundManager.setMusicSuite(this.musicStems?.activeId ?? "siege-suite");
            this.soundManager.setMusicLevel(this.musicLevel);
            this.soundManager.setMusicEnabled(this.musicEnabled && this.soundEnabled);
            this.soundManager.setVolume(this.soundVolume);
            this.soundManager.setIntensity(this.audioIntensity);
        }
        this.initializePlayerSettings();
        this.initializeSessionGoals();
        this.initializeKeystrokeTimingProfile();
        this.initializeSpacedRepetition();
        this.hud.setAnalyticsExportEnabled(this.analyticsExportEnabled);
        this.syncLoreScrollsToHud();
        this.syncSeasonTrackToHud();
        this.syncDailyQuestBoardToHud();
        this.syncWeeklyQuestBoardToHud();
        this.syncLessonMedalsToHud(undefined, { celebrate: false });
        this.syncWpmLadderToHud();
        this.syncTrainingCalendarToHud();
        this.syncBiomeGalleryToHud();
        this.syncDayNightThemeToHud();
        this.syncParallaxSceneToHud();
        this.syncUiSoundSchemeToHud();
        this.syncSfxLibraryToHud();
        this.syncMusicStemsToHud();
        this.syncStreakTokensToHud();
        this.hud.setFullscreenAvailable(this.fullscreenSupported);
        this.attachInputHandlers(options.typingInput);
        this.attachTypingDrillHooks();
        this.attachWeeklyQuestHooks();
        this.attachDebugButtons();
        this.attachGlobalShortcuts();
        this.attachHudVisibilityToggles();
        this.attachHotkeyControls();
        this.attachContextualHints();
        this.attachLatencyIndicator();
        this.attachFullscreenListeners();
        this.attachAccessibilityOnboarding();
        this.attachEnemyIntroOverlay();
        this.registerHudListeners();
        if (config.featureToggles.tutorials) {
            const shouldSkipTutorial = this.shouldSkipTutorial();
            this.tutorialCompleted = shouldSkipTutorial;
            this.tutorialManager = new TutorialManager({
                engine: this.engine,
                hud: this.hud,
                pacing: this.tutorialPacing,
                pauseGame: () => this.pauseForTutorial(),
                resumeGame: () => this.resumeFromTutorial(),
                collectSummaryMetrics: () => this.collectTutorialSummary(),
                onRequestWrapUp: (summary) => this.presentTutorialSummary(summary),
                onComplete: () => {
                    console.info("[tutorial] Completed");
                }
            });
            this.tutorialManager?.setPacingMultiplier?.(this.tutorialPacing);
            this.initializeMainMenu(shouldSkipTutorial);
        }
        else {
            this.tutorialCompleted = true;
        }
        this.render();
        this.maybeShowAccessibilityOnboarding();
    }
    resolveStarfieldPreset(scene) {
        if (!scene)
            return null;
        const preset = STARFIELD_PRESETS[scene.toLowerCase()];
        return preset ? { ...preset } : null;
    }
    applyStarfieldOverride(state) {
        if (!state || !this.starfieldOverride) {
            return state;
        }
        const override = this.starfieldOverride;
        const clone = {
            ...state,
            layers: state.layers.map((layer) => ({ ...layer }))
        };
        if (typeof override.waveProgress === "number") {
            clone.waveProgress = Math.min(1, Math.max(0, override.waveProgress));
        }
        if (typeof override.castleHealthRatio === "number") {
            clone.castleHealthRatio = Math.min(1, Math.max(0, override.castleHealthRatio));
        }
        if (typeof override.depth === "number") {
            clone.depth = override.depth;
        }
        if (typeof override.driftMultiplier === "number") {
            clone.driftMultiplier = override.driftMultiplier;
        }
        if (typeof override.tint === "string" && override.tint.length > 0) {
            clone.tint = override.tint;
        }
        if (override.freeze) {
            for (const layer of clone.layers) {
                layer.velocity = 0;
            }
        }
        return clone;
    }
    buildStarfieldAnalyticsSummary(state) {
        if (!state) {
            return null;
        }
        return {
            driftMultiplier: Number(state.driftMultiplier.toFixed(3)),
            depth: Number(state.depth.toFixed(3)),
            tint: state.tint,
            waveProgress: Number(state.waveProgress.toFixed(3)),
            castleHealthRatio: Number(state.castleHealthRatio.toFixed(3)),
            severity: Number(state.severity.toFixed(3)),
            reducedMotionApplied: Boolean(state.reducedMotionApplied),
            layers: state.layers.map((layer) => ({
                id: layer.id,
                velocity: Number(layer.velocity.toFixed(4)),
                direction: layer.direction,
                depth: layer.depth,
                baseDepth: layer.baseDepth,
                depthOffset: layer.depth - layer.baseDepth
            }))
        };
    }
    handleStarfieldStateChange(summary) {
        const previous = this.lastStarfieldSummary;
        if (!summary && !previous) {
            return;
        }
        const changed = !summary ||
            !previous ||
            Math.abs(summary.depth - previous.depth) > 0.05 ||
            Math.abs(summary.driftMultiplier - previous.driftMultiplier) > 0.05 ||
            Math.abs(summary.castleHealthRatio - previous.castleHealthRatio) > 0.05 ||
            Math.abs(summary.severity - previous.severity) > 0.05 ||
            summary.reducedMotionApplied !== previous.reducedMotionApplied ||
            summary.tint !== previous.tint;
        if (!changed) {
            return;
        }
        this.lastStarfieldSummary = summary
            ? {
                ...summary,
                layers: summary.layers.map((layer) => ({ ...layer }))
            }
            : null;
        if (summary) {
            this.engine.events.emit("visual:starfield-state", summary);
            if (this.telemetryClient && typeof this.telemetryClient.track === "function") {
                this.telemetryClient.track("visual.starfieldStateChanged", summary);
            }
        }
    }
    recordTauntAnalytics(enemy) {
        if (!enemy || !enemy.taunt) {
            return;
        }
        const state = this.engine.getState?.() ?? this.currentState;
        if (!state || !state.analytics) {
            return;
        }
        if (!state.analytics.taunt) {
            state.analytics.taunt = {
                active: false,
                id: null,
                text: null,
                enemyType: null,
                lane: null,
                waveIndex: null,
                timestampMs: null,
                countPerWave: {},
                uniqueLines: [],
                history: []
            };
        }
        const tauntState = state.analytics.taunt;
        const waveIndex = typeof enemy.waveIndex === "number"
            ? enemy.waveIndex
            : typeof state.wave?.index === "number"
                ? state.wave.index
                : null;
        const timestamp = typeof state.time === "number" ? state.time : null;
        tauntState.active = true;
        tauntState.text = typeof enemy.taunt === "string" ? enemy.taunt : null;
        tauntState.enemyType = enemy.tierId ?? null;
        tauntState.lane = typeof enemy.lane === "number" ? enemy.lane : null;
        tauntState.waveIndex = waveIndex;
        tauntState.timestampMs = timestamp;
        tauntState.id =
            typeof enemy.tauntId === "string"
                ? enemy.tauntId
                : typeof enemy.id === "string"
                    ? enemy.id
                    : tauntState.text;
        if (typeof waveIndex === "number") {
            tauntState.countPerWave[waveIndex] = (tauntState.countPerWave[waveIndex] ?? 0) + 1;
        }
        if (tauntState.text && !tauntState.uniqueLines.includes(tauntState.text)) {
            tauntState.uniqueLines.push(tauntState.text);
        }
        if (!Array.isArray(tauntState.history)) {
            tauntState.history = [];
        }
        const entry = {
            id: tauntState.id,
            text: tauntState.text ?? "",
            enemyType: tauntState.enemyType,
            lane: tauntState.lane,
            waveIndex,
            timestamp: timestamp ?? 0
        };
        tauntState.history.push(entry);
        const historyLimit = 25;
        if (tauntState.history.length > historyLimit) {
            tauntState.history.splice(0, tauntState.history.length - historyLimit);
        }
        this.currentState.analytics.taunt = tauntState;
    }
    initializeMainMenu(shouldSkipTutorial) {
        const overlay = document.getElementById("main-menu-overlay");
        const copy = document.getElementById("main-menu-copy");
        const startBtn = document.getElementById("main-menu-start-tutorial");
        const skipBtn = document.getElementById("main-menu-skip-tutorial");
        const replayBtn = document.getElementById("main-menu-replay-tutorial");
        const practiceBtn = document.getElementById("main-menu-practice-mode");
        const drillsBtn = document.getElementById("main-menu-typing-drills");
        const telemetryWrapper = document.getElementById("main-menu-telemetry-toggle-wrapper");
        const telemetryToggle = document.getElementById("main-menu-telemetry-toggle");
        const crystalWrapper = document.getElementById("main-menu-crystal-toggle-wrapper");
        const crystalToggle = document.getElementById("main-menu-crystal-toggle");
        const eliteWrapper = document.getElementById("main-menu-elite-toggle-wrapper");
        const eliteToggle = document.getElementById("main-menu-elite-toggle");
        const laneFocusSelect = document.getElementById("main-menu-practice-lane-focus");
        if (!overlay || !copy || !skipBtn) {
            this.menuActive = false;
            if (!shouldSkipTutorial) {
                this.startTutorial();
            }
            return;
        }
        if (telemetryWrapper instanceof HTMLElement && telemetryToggle instanceof HTMLInputElement) {
            if (!this.telemetryClient) {
                telemetryWrapper.style.display = "none";
                telemetryWrapper.setAttribute("aria-hidden", "true");
                telemetryToggle.checked = Boolean(this.telemetryEnabled);
                telemetryToggle.disabled = true;
            }
            else {
                telemetryWrapper.style.display = "";
                telemetryWrapper.setAttribute("aria-hidden", "false");
                telemetryToggle.disabled = false;
                telemetryToggle.checked = Boolean(this.telemetryEnabled);
                telemetryToggle.addEventListener("change", () => {
                    this.setTelemetryEnabled(telemetryToggle.checked, { persist: true, silent: true });
                });
            }
        }
        if (crystalWrapper instanceof HTMLElement && crystalToggle instanceof HTMLInputElement) {
            this.mainMenuCrystalToggle = crystalToggle;
            crystalWrapper.style.display = "";
            crystalWrapper.setAttribute("aria-hidden", "false");
            crystalToggle.checked = Boolean(this.featureToggles.crystalPulse);
            crystalToggle.addEventListener("change", () => {
                this.setCrystalPulseEnabled(crystalToggle.checked);
            });
        }
        else {
            this.mainMenuCrystalToggle = null;
        }
        if (eliteWrapper instanceof HTMLElement && eliteToggle instanceof HTMLInputElement) {
            this.mainMenuEliteToggle = eliteToggle;
            eliteWrapper.style.display = "";
            eliteWrapper.setAttribute("aria-hidden", "false");
            eliteToggle.checked = Boolean(this.featureToggles.eliteAffixes);
            eliteToggle.addEventListener("change", () => {
                this.setEliteAffixesEnabled(eliteToggle.checked);
            });
        }
        else {
            this.mainMenuEliteToggle = null;
        }
        if (laneFocusSelect instanceof HTMLSelectElement) {
            laneFocusSelect.value =
                typeof this.practiceLaneFocusLane === "number" ? String(this.practiceLaneFocusLane) : "all";
            laneFocusSelect.addEventListener("change", () => {
                const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
                const nextLaneValue = laneFocusSelect.value;
                const parsedLane = nextLaneValue === "all" ? null : Number.parseInt(nextLaneValue, 10);
                const normalized = writePracticeLaneFocus(storage, typeof parsedLane === "number" && Number.isFinite(parsedLane) ? parsedLane : null);
                this.practiceLaneFocusLane = normalized;
                this.engine.setLaneFocus(normalized);
            });
        }
        const challengeEnabledToggle = document.getElementById("main-menu-challenge-enabled");
        const challengeFogToggle = document.getElementById("main-menu-challenge-fog");
        const challengeFastSpawnsToggle = document.getElementById("main-menu-challenge-fast-spawns");
        const challengeLimitedMistakesToggle = document.getElementById("main-menu-challenge-limited-mistakes");
        const challengeMistakeBudget = document.getElementById("main-menu-challenge-mistake-budget");
        if (challengeEnabledToggle instanceof HTMLInputElement) {
            challengeEnabledToggle.addEventListener("change", () => {
                this.persistChallengeModifiersSelection({ enabled: challengeEnabledToggle.checked });
            });
        }
        if (challengeFogToggle instanceof HTMLInputElement) {
            challengeFogToggle.addEventListener("change", () => {
                this.persistChallengeModifiersSelection({ fog: challengeFogToggle.checked, enabled: true });
            });
        }
        if (challengeFastSpawnsToggle instanceof HTMLInputElement) {
            challengeFastSpawnsToggle.addEventListener("change", () => {
                this.persistChallengeModifiersSelection({
                    fastSpawns: challengeFastSpawnsToggle.checked,
                    enabled: true
                });
            });
        }
        if (challengeLimitedMistakesToggle instanceof HTMLInputElement) {
            challengeLimitedMistakesToggle.addEventListener("change", () => {
                this.persistChallengeModifiersSelection({
                    limitedMistakes: challengeLimitedMistakesToggle.checked,
                    enabled: true
                });
            });
        }
        if (challengeMistakeBudget instanceof HTMLSelectElement) {
            challengeMistakeBudget.addEventListener("change", () => {
                const budget = Number.parseInt(challengeMistakeBudget.value, 10);
                if (!Number.isFinite(budget)) {
                    return;
                }
                this.persistChallengeModifiersSelection({ mistakeBudget: budget, enabled: true });
            });
        }
        this.syncChallengeModifiersMainMenu();
        const show = (el, visible) => {
            if (!el)
                return;
            el.style.display = visible ? "inline-flex" : "none";
        };
        if (practiceBtn instanceof HTMLButtonElement) {
            practiceBtn.addEventListener("click", () => {
                overlay.dataset.visible = "false";
                this.menuActive = false;
                this.startPracticeMode();
            });
        }
        if (drillsBtn instanceof HTMLButtonElement) {
            drillsBtn.addEventListener("click", () => {
                this.openTypingDrills("menu");
            });
        }
        const drillsRunBtn = document.getElementById("main-menu-typing-drill-run");
        if (drillsRunBtn instanceof HTMLButtonElement) {
            drillsRunBtn.addEventListener("click", () => {
                const recommendation = this.buildTypingDrillRecommendation();
                const resolved = recommendation ?? { mode: "burst", reason: "Fallback warmup (no recommendation)" };
                this.trackMenuDrillQuickstart(resolved, Boolean(recommendation));
                const label = this.getTypingDrillModeLabel(resolved.mode);
                const prefix = recommendation ? "Starting recommended drill" : "Starting fallback drill";
                this.hud.appendLog?.(`${prefix}: ${label}.`);
                this.openTypingDrills("menu-recommended", {
                    mode: resolved.mode,
                    reason: resolved.reason,
                    autoStart: true,
                    toastMessage: `${prefix}: ${label}`
                });
            });
        }
        const warmupBtn = document.getElementById("main-menu-typing-warmup");
        if (warmupBtn instanceof HTMLButtonElement) {
            warmupBtn.addEventListener("click", () => {
                this.openTypingDrills("menu-warmup", {
                    mode: "warmup",
                    autoStart: true,
                    toastMessage: "Starting 5-Min Warm-up"
                });
            });
        }
        const menuDrillReco = this.buildTypingDrillRecommendation();
        this.setTypingDrillMenuRecommendation(menuDrillReco);
        this.pause();
        this.menuActive = true;
        overlay.dataset.visible = "true";
        this.syncCrystalPulseControls();
        this.syncEliteAffixControls();
        if (!shouldSkipTutorial) {
            copy.textContent =
                "Welcome defender! Start with the guided tutorial or jump straight into the campaign.";
            show(startBtn, true);
            show(replayBtn, false);
            show(practiceBtn, true);
            skipBtn.textContent = "Skip Tutorial";
            startBtn?.addEventListener("click", () => {
                overlay.dataset.visible = "false";
                this.menuActive = false;
                this.clearTutorialProgress();
                this.setPracticeMode(false);
                this.startTutorial();
                this.start();
            }, { once: true });
            skipBtn.addEventListener("click", () => {
                overlay.dataset.visible = "false";
                this.menuActive = false;
                this.setPracticeMode(false);
                this.engine.recordTutorialSkip();
                this.markTutorialComplete();
                this.tutorialCompleted = true;
                this.hud.setTutorialMessage(null);
                this.start();
            }, { once: true });
        }
        else {
            copy.textContent = "Welcome back! Replay the tutorial or continue defending the realm.";
            show(startBtn, false);
            show(replayBtn, true);
            show(practiceBtn, true);
            skipBtn.textContent = "Continue Campaign";
            skipBtn.addEventListener("click", () => {
                overlay.dataset.visible = "false";
                this.menuActive = false;
                this.setPracticeMode(false);
                this.start();
            }, { once: true });
            replayBtn?.addEventListener("click", () => {
                overlay.dataset.visible = "false";
                this.menuActive = false;
                this.clearTutorialProgress();
                this.setPracticeMode(false);
                this.startTutorial(true);
                this.start();
            }, { once: true });
        }
    }
    start() {
        if (this.manualTick) {
            this.running = false;
            return;
        }
        if (this.running)
            return;
        if (this.menuActive) {
            this.running = false;
            this.lastTimestamp = null;
            return;
        }
        if (this.tutorialHoldLoop) {
            this.running = false;
            this.lastTimestamp = null;
            return;
        }
        if (this.waveScorecardActive) {
            this.running = false;
            this.lastTimestamp = null;
            return;
        }
        if (this.optionsOverlayActive) {
            this.running = false;
            this.lastTimestamp = null;
            return;
        }
        if (this.typingDrillsOverlayActive) {
            this.running = false;
            this.lastTimestamp = null;
            return;
        }
        if (this.isScreenTimeLockoutActive()) {
            this.running = false;
            this.lastTimestamp = null;
            this.handleScreenTimeLockoutAttempt("start");
            return;
        }
        if (!this.assetReady) {
            this.running = false;
            this.lastTimestamp = null;
            if (!this.assetStartPending) {
                this.assetStartPending = true;
                void this.assetReadyPromise.then(() => {
                    this.assetStartPending = false;
                    this.start();
                });
            }
            return;
        }
        this.assetStartPending = false;
        this.running = true;
        this.lastTimestamp = performance.now();
        this.rafId = requestAnimationFrame((timestamp) => this.tick(timestamp));
    }
    togglePause() {
        if (this.menuActive || this.waveScorecardActive)
            return;
        if (this.typingDrillsOverlayActive) {
            this.closeTypingDrills();
            return;
        }
        if (this.optionsOverlayActive) {
            this.closeOptionsOverlay();
        }
        else {
            this.openOptionsOverlay();
        }
    }
    pause() {
        this.running = false;
        if (this.rafId !== null) {
            cancelAnimationFrame(this.rafId);
            this.rafId = null;
        }
    }
    resume() {
        if (this.running || this.manualTick || this.optionsOverlayActive || this.waveScorecardActive)
            return;
        this.start();
    }
    step(frames = 1) {
        for (let i = 0; i < frames; i++) {
            this.engine.update(FRAME_DURATION * this.speedMultiplier);
        }
        this.render();
    }
    setSpeed(multiplier) {
        this.speedMultiplier = Math.max(0.1, multiplier);
    }
    getStateSnapshot() {
        return this.engine.getState();
    }
    spawnEnemy(payload) {
        this.engine.spawnEnemy(payload);
        this.render();
    }
    spawnPracticeDummy(lane = 1) {
        const clampedLane = Math.max(0, Math.min(2, Number.isFinite(lane) ? Number(lane) : 1));
        const enemy = this.engine.spawnEnemy({
            tierId: "dummy",
            lane: clampedLane,
            word: "practice",
            order: 999
        });
        if (enemy) {
            enemy.distance = 0.6;
            enemy.speed = 0;
            enemy.baseSpeed = 0;
            enemy.damage = 0;
            enemy.reward = 0;
            this.hud.appendLog?.(`Practice dummy spawned in lane ${["A", "B", "C"][clampedLane] ?? clampedLane + 1}.`);
        }
        this.render();
        return enemy?.id ?? null;
    }
    clearPracticeDummies() {
        const removed = this.engine.removeEnemiesByTier("dummy");
        if (removed > 0) {
            this.hud.appendLog?.(`Removed ${removed} practice dummy${removed === 1 ? "" : "ies"}.`);
        }
        this.render();
        return removed;
    }
    grantGold(amount) {
        this.engine.grantGold(amount);
        this.render();
    }
    getTutorialState() {
        if (!this.tutorialManager) {
            return null;
        }
        return this.tutorialManager.getState();
    }
    completeTutorialStep(stepId) {
        if (!this.tutorialManager) {
            return false;
        }
        const current = this.tutorialManager.getCurrentStepId?.();
        if (!current) {
            return false;
        }
        if (stepId && stepId !== current) {
            return false;
        }
        this.tutorialManager.completeStep(current);
        return true;
    }
    breakEnemyShield(enemyId) {
        if (!enemyId)
            return false;
        const stripped = this.engine.stripEnemyShield(enemyId);
        if (stripped) {
            this.render();
        }
        return stripped;
    }
    simulateTyping(text) {
        for (const char of text) {
            if (char === "\b") {
                this.engine.handleBackspace();
            }
            else {
                this.engine.inputCharacter(char);
            }
        }
        this.render();
    }
    damageCastle(amount) {
        this.engine.damageCastle(amount);
        this.render();
    }
    upgradeCastle() {
        const result = this.engine.upgradeCastle();
        if (!result.success) {
            this.hud.showCastleMessage(result.message ?? "Unable to upgrade castle");
        }
        else {
            const castle = this.engine.getState().castle;
            const bonusPercent = Math.round((castle.goldBonusPercent ?? 0) * 100);
            const message = bonusPercent > 0
                ? `Castle upgraded! Enemy rewards now grant +${bonusPercent}% gold.`
                : "Castle upgraded!";
            this.hud.showCastleMessage(message);
        }
        this.render();
    }
    repairCastle() {
        const result = this.engine.repairCastle();
        if (!result.success) {
            this.hud.showCastleMessage(result.message ?? "Unable to repair castle");
        }
        else {
            const healed = Math.round(result.healed ?? 0);
            const message = healed > 0 ? `Castle repaired for ${healed} HP!` : "Castle repaired!";
            this.hud.showCastleMessage(message);
        }
        this.render();
    }
    placeTurret(slotId, type) {
        if (!this.isTurretTypeEnabled(type)) {
            const label = this.getTurretArchetypeLabel(type);
            this.hud.showSlotMessage(slotId, `${label} is currently disabled.`);
            return;
        }
        const result = this.engine.placeTurret(slotId, type);
        if (!result.success) {
            this.hud.showSlotMessage(slotId, result.message ?? "Placement failed");
        }
        else {
            this.hud.showSlotMessage(slotId, "Turret placed!");
        }
        this.render();
    }
    upgradeTurret(slotId) {
        const result = this.engine.upgradeTurret(slotId);
        if (!result.success) {
            this.hud.showSlotMessage(slotId, result.message ?? "Upgrade failed");
        }
        else {
            this.hud.showSlotMessage(slotId, "Turret upgraded!");
        }
        this.render();
    }
    downgradeTurret(slotId) {
        if (!this.featureToggles?.turretDowngrade) {
            this.hud.showSlotMessage(slotId, "Turret downgrade disabled");
            return;
        }
        const result = this.engine.downgradeTurret(slotId);
        if (!result.success) {
            this.hud.showSlotMessage(slotId, result.message ?? "Downgrade failed");
        }
        else {
            const refund = Math.max(0, Math.round(result.refund ?? 0));
            const message = refund > 0
                ? result.removed
                    ? `Turret refunded (+${refund}g)`
                    : `Downgraded (+${refund}g)`
                : result.removed
                    ? "Turret removed."
                    : "Turret downgraded.";
            this.hud.showSlotMessage(slotId, message);
        }
        this.render();
    }
    setTurretTargetingPriority(slotId, priority, options = {}) {
        const result = this.engine.setTurretTargetingPriority(slotId, priority);
        if (!result) {
            if (!options.silent) {
                this.hud.showSlotMessage(slotId, "Targeting update failed");
            }
            return false;
        }
        if (options.persist !== false) {
            this.persistTurretTargetingPreference(slotId, result);
        }
        this.currentState = this.engine.getState();
        if (!options.silent) {
            this.hud.showSlotMessage(slotId, `Targeting: ${this.describeTargetingPriority(result)}`);
        }
        if (options.render !== false) {
            this.render();
        }
        return true;
    }
    describeTargetingPriority(priority) {
        switch (priority) {
            case "strongest":
                return "Strongest";
            case "weakest":
                return "Weakest";
            default:
                return "First";
        }
    }
    applyTurretFeatureToggles(config) {
        const toggles = config.featureToggles ?? defaultConfig.featureToggles;
        this.featureToggles = { ...toggles };
        this.enabledTurretTypes = this.computeEnabledTurretTypes(this.featureToggles);
        return {
            ...config,
            turretArchetypes: { ...config.turretArchetypes }
        };
    }
    computeEnabledTurretTypes(toggles) {
        const enabled = new Set(Object.keys(this.allTurretArchetypes ?? {}));
        if (!toggles?.crystalPulse) {
            enabled.delete("crystal");
        }
        return enabled;
    }
    isTurretTypeEnabled(typeId) {
        return this.enabledTurretTypes.has(typeId);
    }
    getTurretArchetypeLabel(typeId) {
        const archetype = this.allTurretArchetypes?.[typeId];
        return archetype?.name ?? typeId.toUpperCase();
    }
    updateHudTurretAvailability() {
        if (!this.hud)
            return;
        const availability = {};
        for (const typeId of Object.keys(this.allTurretArchetypes ?? {})) {
            availability[typeId] = this.enabledTurretTypes.has(typeId);
        }
        this.hud.setTurretAvailability(availability);
    }
    syncTurretDowngradeControls() {
        const enabled = Boolean(this.featureToggles?.turretDowngrade);
        if (this.debugDowngradeToggle instanceof HTMLButtonElement) {
            this.debugDowngradeToggle.textContent = enabled
                ? "Disable Turret Downgrade"
                : "Enable Turret Downgrade";
            this.debugDowngradeToggle.setAttribute("aria-pressed", enabled ? "true" : "false");
        }
    }
    syncCrystalPulseControls() {
        const enabled = Boolean(this.featureToggles?.crystalPulse);
        if (this.debugCrystalToggle instanceof HTMLButtonElement) {
            this.debugCrystalToggle.textContent = enabled
                ? "Disable Crystal Pulse"
                : "Enable Crystal Pulse";
            this.debugCrystalToggle.setAttribute("aria-pressed", enabled ? "true" : "false");
        }
        if (this.mainMenuCrystalToggle instanceof HTMLInputElement) {
            this.mainMenuCrystalToggle.checked = enabled;
        }
    }
    syncEliteAffixControls() {
        const enabled = Boolean(this.featureToggles?.eliteAffixes);
        if (this.debugEliteToggle instanceof HTMLButtonElement) {
            this.debugEliteToggle.textContent = enabled
                ? "Disable Elite Affixes"
                : "Enable Elite Affixes";
            this.debugEliteToggle.setAttribute("aria-pressed", enabled ? "true" : "false");
        }
        if (this.mainMenuEliteToggle instanceof HTMLInputElement) {
            this.mainMenuEliteToggle.checked = enabled;
        }
    }
    setCrystalPulseEnabled(enabled, options = {}) {
        const { persist = true, silent = false, force = false, skipSync = false } = options;
        const normalized = Boolean(enabled);
        const sync = () => {
            this.updateHudTurretAvailability();
            this.syncTurretPresetsToHud(this.currentState ?? this.engine.getState());
            this.updateOptionsOverlayState();
            this.syncCrystalPulseControls();
        };
        if (this.featureToggles.crystalPulse === normalized && !force) {
            if (!skipSync) {
                sync();
            }
            return;
        }
        this.featureToggles.crystalPulse = normalized;
        this.engine.config.featureToggles = {
            ...this.engine.config.featureToggles,
            crystalPulse: normalized
        };
        this.engine.config.turretArchetypes = { ...this.allTurretArchetypes };
        this.enabledTurretTypes = this.computeEnabledTurretTypes(this.featureToggles);
        if (persist) {
            this.persistPlayerSettings({ crystalPulseEnabled: normalized });
        }
        if (!silent) {
            this.hud.showCastleMessage(normalized
                ? "Crystal Pulse turret enabled. Experimental pulses are now available."
                : "Crystal Pulse turret disabled.");
        }
        if (!skipSync) {
            sync();
        }
    }
    setEliteAffixesEnabled(enabled, options = {}) {
        const { persist = true, silent = false, force = false, skipSync = false } = options;
        const normalized = Boolean(enabled);
        const sync = () => {
            this.updateOptionsOverlayState();
            this.syncEliteAffixControls();
        };
        if (this.featureToggles.eliteAffixes === normalized && !force) {
            if (!skipSync) {
                sync();
            }
            return this.featureToggles.eliteAffixes;
        }
        this.featureToggles.eliteAffixes = normalized;
        this.engine.config.featureToggles = {
            ...this.engine.config.featureToggles,
            eliteAffixes: normalized
        };
        if (persist) {
            this.persistPlayerSettings({ eliteAffixesEnabled: normalized });
        }
        if (!silent) {
            this.hud.appendLog(normalized
                ? "Elite affixes enabled. Expect armored, shielded, or aura elites."
                : "Elite affixes disabled.");
        }
        if (!skipSync) {
            sync();
        }
        return normalized;
    }
    setTurretDowngradeEnabled(enabled, options = {}) {
        const { silent = false } = options;
        const normalized = Boolean(enabled);
        if (this.featureToggles.turretDowngrade === normalized) {
            this.syncTurretDowngradeControls();
            return this.featureToggles.turretDowngrade;
        }
        this.featureToggles.turretDowngrade = normalized;
        this.engine.config.featureToggles = {
            ...this.engine.config.featureToggles,
            turretDowngrade: normalized
        };
        this.hud.setTurretDowngradeEnabled(normalized);
        this.syncTurretDowngradeControls();
        if (!silent) {
            this.hud.appendLog(normalized ? "Turret downgrade mode enabled." : "Turret downgrade mode disabled.");
        }
        return normalized;
    }
    toggleTurretDowngrade() {
        return this.setTurretDowngradeEnabled(!this.featureToggles.turretDowngrade);
    }
    setDiagnosticsVisible(visible, options = {}) {
        this.diagnostics.setVisible(visible);
        if (!options.silent) {
            this.hud.appendLog(`Diagnostics ${visible ? "shown" : "hidden"}`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false) {
            this.persistPlayerSettings({ diagnosticsVisible: visible });
        }
        if (options.render !== false) {
            this.render();
        }
    }
    toggleDiagnostics() {
        const next = !this.diagnostics.isVisible();
        this.setDiagnosticsVisible(next);
        this.tutorialManager?.notify({ type: "diagnostics:toggled" });
    }
    setSoundEnabled(enabled, options = {}) {
        this.soundEnabled = enabled;
        if (enabled) {
            void this.soundManager?.ensureInitialized().then(() => {
                this.soundManager?.setVolume(this.soundVolume);
                this.soundManager?.setEnabled(true);
                this.soundManager?.setMusicEnabled(this.musicEnabled);
                if (this.currentState) {
                    this.updateAmbientTrack(this.currentState);
                }
            });
        }
        else {
            this.soundManager?.setEnabled(false);
            this.soundManager?.stopAmbient?.();
            this.soundManager?.setMusicEnabled(false);
        }
        if (!options.silent) {
            this.hud.appendLog(`Sound ${enabled ? "enabled" : "muted"}`);
        }
        this.updateOptionsOverlayState();
        this.syncSoundDebugControls();
        if (options.persist !== false) {
            this.persistPlayerSettings({ soundEnabled: enabled });
        }
        if (options.render !== false) {
            this.render();
        }
    }
    setMusicEnabled(enabled, options = {}) {
        const next = Boolean(enabled);
        const changed = this.musicEnabled !== next;
        this.musicEnabled = next;
        if (this.musicStems) {
            this.musicStems = { ...this.musicStems, dynamicEnabled: next, updatedAt: new Date().toISOString() };
            if (typeof window !== "undefined" && window.localStorage) {
                writeMusicStemState(window.localStorage, this.musicStems);
            }
            this.syncMusicStemsToHud();
        }
        if (this.soundManager) {
            if (this.soundEnabled) {
                this.soundManager.setMusicEnabled(next);
                if (this.currentState) {
                    this.lastAmbientProfile = null;
                    this.updateAmbientTrack(this.currentState);
                }
            }
            else {
                this.soundManager.setMusicEnabled(false);
            }
        }
        if (!options.silent && changed) {
            this.hud.appendLog(`Dynamic music ${next ? "enabled" : "muted"}`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ musicEnabled: next });
        }
        if (options.render !== false && changed) {
            this.render();
        }
    }
    setMusicLevel(level, options = {}) {
        const normalized = this.normalizeMusicLevel(level);
        const changed = Math.abs(normalized - this.musicLevel) > 0.001;
        this.musicLevel = normalized;
        if (this.soundManager) {
            this.soundManager.setMusicLevel(normalized);
        }
        if (!options.silent && changed) {
            const percent = Math.round(normalized * 100);
            this.hud.appendLog(`Music level set to ${percent}%`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ musicLevel: normalized });
        }
    }
    setReducedMotionEnabled(enabled, options = {}) {
        this.reducedMotionEnabled = enabled;
        this.applyReducedMotionSetting(enabled);
        this.updateLatencySparklineVisibility();
        this.syncParallaxMotionPause();
        if (enabled) {
            this.screenShakeBursts = [];
            if (this.screenShakeEnabled) {
                this.setScreenShakeEnabled(false, {
                    persist: options.persist !== false,
                    silent: true,
                    render: false
                });
            }
        }
        if (!options.silent) {
            this.hud.appendLog(`Reduced motion ${enabled ? "enabled" : "disabled"}`);
        }
        this.updateOptionsOverlayState();
        this.syncDefeatAnimationPreferences();
        if (options.persist !== false) {
            this.persistPlayerSettings({ reducedMotionEnabled: enabled });
        }
        if (options.render !== false) {
            this.render();
        }
    }
    setCheckeredBackgroundEnabled(enabled, options = {}) {
        this.checkeredBackgroundEnabled = enabled;
        this.applyCheckeredBackgroundSetting(enabled);
        if (!options.silent) {
            this.hud.appendLog(`Checkered background ${enabled ? "enabled" : "disabled"}`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false) {
            this.persistPlayerSettings({ checkeredBackgroundEnabled: enabled });
        }
        if (options.render !== false) {
            this.render();
        }
    }
    setLowGraphicsEnabled(enabled, options = {}) {
        const next = Boolean(enabled);
        const force = options.force === true;
        if (!force && this.lowGraphicsEnabled === next) {
            return false;
        }
        const persist = options.persist !== false;
        const silent = Boolean(options.silent);
        if (next) {
            this.lowGraphicsRestoreState = {
                reducedMotion: this.reducedMotionEnabled,
                checkeredBackground: this.checkeredBackgroundEnabled,
                defeatAnimationMode: this.defeatAnimationMode,
                starfieldEnabled: this.starfieldEnabled
            };
            this.setReducedMotionEnabled(true, { persist, silent: true, render: false });
            this.setCheckeredBackgroundEnabled(false, { persist, silent: true, render: false });
            this.setDefeatAnimationMode("procedural", { persist, silent: true, render: false });
            this.starfieldEnabled = false;
        }
        else {
            const restore = this.lowGraphicsRestoreState;
            const restoredStarfield = restore?.starfieldEnabled ?? Boolean(this.featureToggles?.starfieldParallax);
            this.starfieldEnabled = restoredStarfield;
            if (restore) {
                this.setReducedMotionEnabled(restore.reducedMotion, { persist, silent: true, render: false });
                this.setCheckeredBackgroundEnabled(restore.checkeredBackground, {
                    persist,
                    silent: true,
                    render: false
                });
                this.setDefeatAnimationMode(restore.defeatAnimationMode ?? "auto", {
                    persist,
                    silent: true,
                    render: false
                });
            }
        }
        this.lowGraphicsEnabled = next;
        this.syncParallaxMotionPause();
        if (persist) {
            this.persistPlayerSettings({ lowGraphicsEnabled: next });
        }
        this.updateOptionsOverlayState();
        if (!silent) {
            this.hud.appendLog(`Low graphics ${next ? "enabled" : "disabled"}`);
        }
        this.render();
        return true;
    }
    setReadableFontEnabled(enabled, options = {}) {
        this.readableFontEnabled = enabled;
        this.applyReadableFontSetting(enabled);
        if (!options.silent) {
            this.hud.appendLog(`Readable font ${enabled ? "enabled" : "disabled"}`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false) {
            this.persistPlayerSettings({ readableFontEnabled: enabled });
        }
        if (options.render !== false) {
            this.render();
        }
    }
    setVirtualKeyboardEnabled(enabled, options = {}) {
        this.virtualKeyboardEnabled = Boolean(enabled);
        this.hud.setVirtualKeyboardEnabled(this.virtualKeyboardEnabled);
        if (!options.silent) {
            this.hud.appendLog(`On-screen keyboard ${this.virtualKeyboardEnabled ? "enabled" : "disabled"}`);
        }
        if (options.persist !== false) {
            this.persistPlayerSettings({ virtualKeyboardEnabled: this.virtualKeyboardEnabled });
        }
        this.updateOptionsOverlayState();
        if (options.render !== false) {
            this.render();
        }
    }
    normalizeVirtualKeyboardLayout(layout) {
        const normalized = typeof layout === "string" ? layout.toLowerCase() : "";
        return VIRTUAL_KEYBOARD_LAYOUTS.has(normalized)
            ? normalized
            : DEFAULT_VIRTUAL_KEYBOARD_LAYOUT;
    }
    setVirtualKeyboardLayout(layout, options = {}) {
        const normalized = this.normalizeVirtualKeyboardLayout(layout);
        if (this.virtualKeyboardLayout === normalized && options.force !== true) {
            return;
        }
        this.virtualKeyboardLayout = normalized;
        if (typeof this.hud?.setVirtualKeyboardLayout === "function") {
            this.hud.setVirtualKeyboardLayout(normalized);
        }
        if (!options.silent) {
            this.hud.appendLog(`Keyboard layout set to ${normalized.toUpperCase()}.`);
        }
        if (options.persist !== false) {
            this.persistPlayerSettings({ virtualKeyboardLayout: normalized });
        }
        this.updateOptionsOverlayState();
    }
    setHapticsEnabled(enabled, options = {}) {
        const next = Boolean(enabled);
        const changed = this.hapticsEnabled !== next;
        this.hapticsEnabled = next;
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ hapticsEnabled: next });
        }
        this.updateOptionsOverlayState();
        if (!options.silent && changed) {
            this.hud.appendLog(`Haptics ${next ? "enabled" : "disabled"}`);
        }
        return changed;
    }
    setDyslexiaFontEnabled(enabled, options = {}) {
        this.dyslexiaFontEnabled = enabled;
        this.applyDyslexiaFontSetting(enabled);
        if (!options.silent) {
            this.hud.appendLog(`Dyslexia-friendly font ${enabled ? "enabled" : "disabled"}`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false) {
            this.persistPlayerSettings({ dyslexiaFontEnabled: enabled });
        }
        if (options.render !== false) {
            this.render();
        }
    }
    setDyslexiaSpacingEnabled(enabled, options = {}) {
        const next = Boolean(enabled);
        const changed = this.dyslexiaSpacingEnabled !== next;
        this.dyslexiaSpacingEnabled = next;
        this.applyDyslexiaSpacingSetting(next);
        if (!options.silent && changed) {
            this.hud.appendLog(`Letter spacing ${next ? "increased" : "normal"}`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ dyslexiaSpacingEnabled: next });
        }
        if (options.render !== false && changed) {
            this.render();
        }
        return changed;
    }
    setReducedCognitiveLoadEnabled(enabled, options = {}) {
        const next = Boolean(enabled);
        const changed = this.reducedCognitiveLoadEnabled !== next;
        this.reducedCognitiveLoadEnabled = next;
        this.applyCognitiveLoadSetting(next);
        this.applyHudVisibility();
        this.syncHudVisibilityToggles();
        this.updateOptionsOverlayState();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ reducedCognitiveLoadEnabled: next });
        }
        if (!options.silent && changed) {
            this.hud.appendLog(`Reduced cognitive load ${next ? "enabled" : "disabled"}`);
        }
        if (options.render !== false && changed) {
            this.render();
        }
        return changed;
    }
    setBackgroundBrightness(value, options = {}) {
        const normalized = this.normalizeBackgroundBrightness(value);
        const changed = Math.abs(normalized - this.backgroundBrightness) > 0.001;
        this.backgroundBrightness = normalized;
        this.applyBackgroundBrightnessSetting(normalized);
        if (!options.silent && changed) {
            const percent = Math.round(normalized * 100);
            this.hud.appendLog(`Background brightness set to ${percent}%`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ backgroundBrightness: normalized });
        }
        return changed;
    }
    setSoundVolume(volume, options = {}) {
        const normalized = this.normalizeSoundVolume(volume);
        const changed = Math.abs(normalized - this.soundVolume) > 0.001;
        this.soundVolume = normalized;
        if (this.soundManager) {
            this.soundManager.setVolume(normalized);
        }
        if (changed && !options.silent) {
            const percent = Math.round(normalized * 100);
            this.hud.appendLog(`Sound volume set to ${percent}%`);
        }
        this.updateOptionsOverlayState();
        this.syncSoundDebugControls();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ soundVolume: normalized });
        }
    }
    setAudioIntensity(intensity, options = {}) {
        const normalized = this.normalizeAudioIntensity(intensity);
        const changed = Math.abs(normalized - this.audioIntensity) > 0.001;
        this.audioIntensity = normalized;
        if (this.soundManager) {
            this.soundManager.setIntensity(normalized);
        }
        if (changed && !options.silent) {
            const percent = Math.round(normalized * 100);
            this.hud.appendLog(`Audio intensity set to ${percent}%`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ audioIntensity: normalized });
        }
    }
    setMusicSuiteSelection(suiteId, options = {}) {
        const nextState = setActiveMusicStem(this.musicStems ?? {
            activeId: "siege-suite",
            auditioned: [],
            dynamicEnabled: true,
            updatedAt: null
        }, suiteId);
        const changed = (this.musicStems?.activeId ?? "siege-suite") !== nextState.activeId;
        this.musicStems = nextState;
        if (this.soundManager) {
            this.soundManager.setMusicSuite(nextState.activeId);
            if (this.musicEnabled && this.soundEnabled && this.currentState) {
                this.lastAmbientProfile = null;
                this.updateAmbientTrack(this.currentState);
            }
        }
        if (!options.silent) {
            const def = getMusicStemDefinition(nextState.activeId);
            this.hud.appendLog?.(`Music suite set to ${def.name} (${def.vibe}).`);
        }
        if (typeof window !== "undefined" && window.localStorage) {
            writeMusicStemState(window.localStorage, this.musicStems);
        }
        this.syncMusicStemsToHud();
        return changed;
    }
    previewMusicSuite(suiteId) {
        const current = this.musicStems?.activeId ?? "siege-suite";
        const target = getMusicStemDefinition(suiteId).id;
        const manager = this.soundManager;
        if (manager && this.soundEnabled) {
            manager.setMusicSuite(target);
            manager.setMusicEnabled(true);
            manager.setMusicProfile(this.lastAmbientProfile ?? "calm");
            if (this.musicPreviewTimeout) {
                window.clearTimeout(this.musicPreviewTimeout);
            }
            this.musicPreviewTimeout = window.setTimeout(() => {
                manager.setMusicSuite(current);
                manager.setMusicEnabled(this.musicEnabled && this.soundEnabled);
                manager.setMusicProfile(this.lastAmbientProfile ?? "calm");
                this.musicPreviewTimeout = null;
            }, 5000);
        }
        this.musicStems = markMusicStemAudition(this.musicStems ?? { activeId: current, auditioned: [], dynamicEnabled: true, updatedAt: null }, target);
        if (typeof window !== "undefined" && window.localStorage) {
            writeMusicStemState(window.localStorage, this.musicStems);
        }
        this.syncMusicStemsToHud();
    }
    setUiSoundSchemeSelection(schemeId, options = {}) {
        const nextState = setActiveUiScheme(this.uiSoundScheme ?? { activeId: "clarity", auditioned: [], updatedAt: null }, schemeId);
        const changed = (this.uiSoundScheme?.activeId ?? "clarity") !== nextState.activeId;
        this.uiSoundScheme = nextState;
        if (this.soundManager) {
            this.soundManager.setUiScheme(nextState.activeId);
            void this.soundManager.ensureInitialized?.();
        }
        if (!options.silent) {
            const def = getUiSchemeDefinition(nextState.activeId);
            this.hud.appendLog?.(`UI sounds set to ${def.name} (${def.vibe}).`);
        }
        if (typeof window !== "undefined" && window.localStorage) {
            writeUiSchemeState(window.localStorage, this.uiSoundScheme);
        }
        this.syncUiSoundSchemeToHud();
        return changed;
    }
    previewUiSoundScheme(schemeId) {
        const current = this.uiSoundScheme?.activeId ?? "clarity";
        const target = getUiSchemeDefinition(schemeId).id;
        const manager = this.soundManager;
        if (manager && this.soundEnabled) {
            manager.setUiScheme(target);
            void manager.ensureInitialized?.().then(() => {
                const previewKeys = ["ui-open", "ui-select", "ui-alert"];
                const delays = [0, 160, 340];
                previewKeys.forEach((key, idx) => {
                    window.setTimeout(() => manager.playUi(key), delays[idx] ?? idx * 120);
                });
                if (current !== target) {
                    window.setTimeout(() => manager.setUiScheme(current), 1200);
                }
            });
        }
        this.uiSoundScheme = markUiSchemeAudition(this.uiSoundScheme ?? { activeId: current, auditioned: [], updatedAt: null }, target);
        if (typeof window !== "undefined" && window.localStorage) {
            writeUiSchemeState(window.localStorage, this.uiSoundScheme);
        }
        this.syncUiSoundSchemeToHud();
    }
    setSfxLibrarySelection(libraryId, options = {}) {
        const nextState = setActiveSfxLibrary(this.sfxLibrary ?? { activeId: "classic", auditioned: [], updatedAt: null }, libraryId);
        const changed = (this.sfxLibrary?.activeId ?? "classic") !== nextState.activeId;
        this.sfxLibrary = nextState;
        if (this.soundManager) {
            this.soundManager.setLibrary(nextState.activeId);
            void this.soundManager.ensureInitialized?.();
        }
        if (!options.silent) {
            const def = getSfxLibraryDefinition(nextState.activeId);
            this.hud.appendLog?.(`SFX library set to ${def.name} (${def.vibe}).`);
        }
        if (typeof window !== "undefined" && window.localStorage) {
            writeSfxLibraryState(window.localStorage, this.sfxLibrary);
        }
        this.syncSfxLibraryToHud();
        return changed;
    }
    previewSfxLibrary(libraryId) {
        const current = this.sfxLibrary?.activeId ?? "classic";
        const target = getSfxLibraryDefinition(libraryId).id;
        const manager = this.soundManager;
        if (manager) {
            manager.setLibrary(target);
            void manager.ensureInitialized?.().then(() => {
                const previewKeys = [
                    ["projectile-arrow", 0],
                    ["impact-hit", 180],
                    ["upgrade", 360],
                    ["impact-breach", 640]
                ];
                for (const [key, delay] of previewKeys) {
                    window.setTimeout(() => manager.play(key), delay);
                }
                window.setTimeout(() => manager.playStinger?.("victory"), 820);
                if (current !== target) {
                    window.setTimeout(() => manager.setLibrary(current), 1000);
                }
            });
        }
        this.sfxLibrary = markSfxLibraryAudition(this.sfxLibrary ?? { activeId: current, auditioned: [], updatedAt: null }, target);
        if (typeof window !== "undefined" && window.localStorage) {
            writeSfxLibraryState(window.localStorage, this.sfxLibrary);
        }
        this.syncSfxLibraryToHud();
    }
    setScreenShakeEnabled(enabled, options = {}) {
        const next = Boolean(enabled) && !this.reducedMotionEnabled;
        const persist = options.persist !== false;
        const silent = Boolean(options.silent);
        const render = options.render !== false;
        const changed = this.screenShakeEnabled !== next;
        this.screenShakeEnabled = next;
        if (!next) {
            this.screenShakeBursts = [];
        }
        if (!silent) {
            const message = this.reducedMotionEnabled && enabled
                ? "Reduced motion is on; screen shake stays disabled."
                : `Screen shake ${next ? "enabled" : "disabled"}`;
            this.hud.appendLog(message);
        }
        this.updateOptionsOverlayState();
        if (persist && changed) {
            this.persistPlayerSettings({ screenShakeEnabled: next });
        }
        if (render) {
            this.render();
        }
        return changed;
    }
    setScreenShakeIntensity(intensity, options = {}) {
        const normalized = this.normalizeScreenShakeIntensity(intensity);
        const changed = Math.abs(normalized - this.screenShakeIntensity) > 0.001;
        this.screenShakeIntensity = normalized;
        if (!options.silent && changed) {
            const percent = Math.round(normalized * 100);
            this.hud.appendLog(`Screen shake intensity set to ${percent}%`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ screenShakeIntensity: normalized });
        }
        return changed;
    }
    previewScreenShake() {
        if (this.reducedMotionEnabled) {
            this.hud.appendLog("Reduced motion is on; screen shake preview skipped.");
            return false;
        }
        this.enqueueScreenShake("preview", {
            force: true,
            intensityOverride: this.screenShakeIntensity
        });
        this.hud.playScreenShakePreview?.();
        return true;
    }
    getAccessibilitySelfTestDefaults() {
        return { ...ACCESSIBILITY_SELF_TEST_DEFAULT };
    }
    runAccessibilitySelfTest() {
        const nextState = {
            lastRunAt: new Date().toISOString(),
            soundConfirmed: false,
            visualConfirmed: false,
            motionConfirmed: this.reducedMotionEnabled ? false : false
        };
        this.persistPlayerSettings({ accessibilitySelfTest: nextState });
        this.accessibilitySelfTest =
            this.playerSettings.accessibilitySelfTest ?? this.getAccessibilitySelfTestDefaults();
        this.updateOptionsOverlayState();
        this.playAccessibilitySelfTestCues();
    }
    setAccessibilitySelfTestConfirmation(kind, confirmed) {
        if (kind !== "sound" && kind !== "visual" && kind !== "motion") {
            return;
        }
        const current = this.playerSettings.accessibilitySelfTest ?? this.getAccessibilitySelfTestDefaults();
        const nextState = {
            ...current,
            [kind]: Boolean(confirmed)
        };
        this.persistPlayerSettings({ accessibilitySelfTest: nextState });
        this.accessibilitySelfTest =
            this.playerSettings.accessibilitySelfTest ?? this.getAccessibilitySelfTestDefaults();
        this.updateOptionsOverlayState();
    }
    playAccessibilitySelfTestCues() {
        if (this.soundManager && this.soundEnabled) {
            void this.soundManager.ensureInitialized().then(() => {
                this.soundManager?.play?.("impact-hit");
            });
        }
        this.hud.playAccessibilitySelfTestCues?.({
            includeMotion: !this.reducedMotionEnabled,
            soundEnabled: this.soundEnabled
        });
        if (!this.reducedMotionEnabled) {
            this.previewScreenShake();
        }
    }
    updateAmbientTrack(state) {
        if (!this.soundManager)
            return;
        if (!this.soundEnabled) {
            this.soundManager.stopAmbient?.();
            return;
        }
        const healthRatio = state && state.castle && state.castle.maxHealth > 0
            ? Math.max(0, Math.min(1, state.castle.health / state.castle.maxHealth))
            : 1;
        const profile = selectAmbientProfile(state?.wave?.index ?? 0, state?.wave?.total ?? 1, healthRatio);
        if (profile === this.lastAmbientProfile)
            return;
        this.lastAmbientProfile = profile;
        this.soundManager.setAmbientProfile(profile);
    }
    handleGameStatusAudio(status) {
        if (!this.soundManager || !this.soundEnabled)
            return;
        if (this.lastGameStatus === status)
            return;
        if (status === "victory") {
            this.soundManager.playStinger?.("victory");
        }
        else if (status === "defeat") {
            this.soundManager.playStinger?.("defeat");
        }
        this.lastGameStatus = status;
    }
    setColorblindPaletteEnabled(enabled, options = {}) {
        const nextMode = enabled && this.colorblindPaletteMode === "off"
            ? this.lastColorblindMode || "deuteran"
            : enabled
                ? this.colorblindPaletteMode
                : "off";
        return this.setColorblindPaletteMode(nextMode, options);
    }
    setAudioNarrationEnabled(enabled, options = {}) {
        const next = Boolean(enabled);
        if (this.audioNarrationEnabled === next) {
            return this.audioNarrationEnabled;
        }
        this.audioNarrationEnabled = next;
        this.applyAudioNarrationSetting(next);
        if (!options.silent) {
            this.hud.appendLog(`Audio narration ${next ? "enabled" : "disabled"}.`);
        }
        if (options.persist !== false) {
            this.persistPlayerSettings({ audioNarrationEnabled: next });
        }
        if (options.render !== false) {
            this.updateOptionsOverlayState();
        }
        return this.audioNarrationEnabled;
    }
    setTutorialPacing(value, options = {}) {
        const next = this.normalizeTutorialPacing(value);
        if (this.tutorialPacing === next) {
            return this.tutorialPacing;
        }
        this.tutorialPacing = next;
        this.tutorialManager?.setPacingMultiplier?.(next);
        if (!options.silent) {
            this.hud.appendLog(`Tutorial pacing set to ${Math.round(next * 100)}%.`);
        }
        if (options.persist !== false) {
            this.persistPlayerSettings({ tutorialPacing: next });
        }
        if (options.render !== false) {
            this.updateOptionsOverlayState();
        }
        return this.tutorialPacing;
    }
    setAccessibilityPresetEnabled(enabled, options = {}) {
        const next = Boolean(enabled);
        const applyPreset = options.applyPreset !== false;
        if (this.accessibilityPresetEnabled === next && !options.force) {
            return this.accessibilityPresetEnabled;
        }
        this.accessibilityPresetEnabled = next;
        if (applyPreset) {
            this.applyAccessibilityPreset(next, {
                persist: false,
                render: false,
                silent: true
            });
        }
        if (!options.silent) {
            this.hud.appendLog(next
                ? "Accessibility preset enabled for this profile."
                : "Accessibility preset disabled.");
        }
        if (options.persist !== false) {
            this.persistPlayerSettings({
                accessibilityPresetEnabled: next,
                reducedMotionEnabled: applyPreset ? this.reducedMotionEnabled : undefined,
                readableFontEnabled: applyPreset ? this.readableFontEnabled : undefined,
                dyslexiaFontEnabled: applyPreset ? this.dyslexiaFontEnabled : undefined,
                dyslexiaSpacingEnabled: applyPreset ? this.dyslexiaSpacingEnabled : undefined,
                reducedCognitiveLoadEnabled: applyPreset ? this.reducedCognitiveLoadEnabled : undefined,
                audioNarrationEnabled: applyPreset ? this.audioNarrationEnabled : undefined,
                largeSubtitlesEnabled: applyPreset ? this.largeSubtitlesEnabled : undefined,
                screenShakeEnabled: applyPreset ? this.screenShakeEnabled : undefined
            });
        }
        if (options.render !== false) {
            this.updateOptionsOverlayState();
        }
        return this.accessibilityPresetEnabled;
    }
    applyAccessibilityPreset(enabled, options = {}) {
        const presetOptions = {
            persist: options.persist ?? false,
            render: options.render ?? false,
            silent: options.silent ?? true
        };
        const target = Boolean(enabled);
        this.setReducedMotionEnabled(target, presetOptions);
        this.setReadableFontEnabled(target, presetOptions);
        this.setDyslexiaFontEnabled(target, presetOptions);
        this.setDyslexiaSpacingEnabled(target, presetOptions);
        this.setReducedCognitiveLoadEnabled(target, presetOptions);
        this.setAudioNarrationEnabled(target, presetOptions);
        this.setLargeSubtitlesEnabled(target, presetOptions);
        return target;
    }
    setVoicePack(packId, options = {}) {
        const next = this.normalizeVoicePack(packId);
        if (this.voicePackId === next && !options.force)
            return this.voicePackId;
        this.voicePackId = next;
        if (!options.silent) {
            this.hud.appendLog(`Voice pack set to ${next.replace("mentor-", "Mentor ")} (text stubs).`);
        }
        if (options.persist !== false) {
            this.persistPlayerSettings({ voicePackId: next });
        }
        if (options.render !== false) {
            this.updateOptionsOverlayState();
        }
        return this.voicePackId;
    }
    setLargeSubtitlesEnabled(enabled, options = {}) {
        const next = Boolean(enabled);
        if (this.largeSubtitlesEnabled === next) {
            return this.largeSubtitlesEnabled;
        }
        this.largeSubtitlesEnabled = next;
        this.applyLargeSubtitlesSetting(next);
        if (!options.silent) {
            this.hud.appendLog(`Large-text subtitles ${next ? "enabled" : "disabled"}.`);
        }
        if (options.persist !== false) {
            this.persistPlayerSettings({ largeSubtitlesEnabled: next });
        }
        if (options.render !== false) {
            this.updateOptionsOverlayState();
        }
        return this.largeSubtitlesEnabled;
    }
    setColorblindPaletteMode(mode, options = {}) {
        const normalized = this.normalizeColorblindMode(mode);
        const enabled = normalized !== "off";
        const changedMode = this.colorblindPaletteMode !== normalized;
        const changedEnabled = this.colorblindPaletteEnabled !== enabled;
        this.colorblindPaletteMode = normalized;
        this.colorblindPaletteEnabled = enabled;
        if (enabled) {
            this.lastColorblindMode = normalized;
        }
        this.applyColorblindPaletteSetting(normalized);
        if (!options.silent && (changedMode || changedEnabled)) {
            const label = normalized === "off"
                ? "disabled"
                : normalized === "deuteran"
                    ? "Deuteran (green-red separation)"
                    : normalized === "protan"
                        ? "Protan (red shift)"
                        : normalized === "tritan"
                            ? "Tritan (blue/yellow separation)"
                            : "High contrast";
            this.hud.appendLog(`Colorblind palette ${label}`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false && (changedMode || changedEnabled)) {
            this.persistColorblindMode(normalized);
            this.persistPlayerSettings({ colorblindPaletteEnabled: enabled });
        }
        if (options.render !== false && (changedMode || changedEnabled)) {
            this.render();
        }
        return changedMode || changedEnabled;
    }
    setFocusOutlinePreset(preset, options = {}) {
        const normalized = normalizeFocusOutlinePreset(preset);
        const changed = this.focusOutlinePreset !== normalized;
        this.focusOutlinePreset = normalized;
        this.applyFocusOutlinePreset(normalized);
        if (!options.silent && changed) {
            const label = normalized === "contrast"
                ? "high-contrast ring"
                : normalized === "glow"
                    ? "glow halo"
                    : "panel defaults";
            this.hud.appendLog?.(`Focus outline set to ${label}`);
        }
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ focusOutlinePreset: normalized });
        }
        if (options.render !== false) {
            this.updateOptionsOverlayState();
        }
        return changed;
    }
    setDefeatAnimationMode(mode, options = {}) {
        const normalized = mode === "sprite" || mode === "procedural" || mode === "auto" ? mode : "auto";
        if (normalized === this.defeatAnimationMode) {
            return;
        }
        this.defeatAnimationMode = normalized;
        this.syncDefeatAnimationPreferences();
        if (!options.silent) {
            this.hud.appendLog?.(`Defeat animations set to ${normalized}`);
        }
        if (options.persist !== false) {
            this.persistPlayerSettings({ defeatAnimationMode: normalized });
        }
    }
    setStarfieldScene(scene) {
        if (!scene) {
            this.starfieldOverride = null;
            this.render();
            return null;
        }
        let override = null;
        if (typeof scene === "string") {
            override = this.resolveStarfieldPreset(scene);
        }
        else if (typeof scene === "object") {
            const preset = scene && typeof scene.scene === "string" ? this.resolveStarfieldPreset(scene.scene) : null;
            override = {
                ...preset,
                ...scene
            };
        }
        this.starfieldOverride = override;
        this.render();
        return this.starfieldOverride;
    }
    syncDefeatAnimationPreferences() {
        if (this.renderer?.setDefeatAnimationMode) {
            this.renderer.setDefeatAnimationMode(this.defeatAnimationMode);
        }
        this.engine.setDefeatBurstModeResolver((enemy) => this.resolveDefeatBurstMode(enemy));
        this.updateOptionsOverlayState();
    }
    resolveDefeatBurstMode(enemy) {
        return this.shouldUseSpriteForTier(enemy?.tierId) ? "sprite" : "procedural";
    }
    shouldUseSpriteForTier(tierId) {
        if (!tierId ||
            this.reducedMotionEnabled ||
            this.defeatAnimationMode === "procedural" ||
            typeof this.assetLoader?.getDefeatAnimation !== "function" ||
            typeof this.assetLoader?.getImage !== "function") {
            return false;
        }
        const definition = this.assetLoader.getDefeatAnimation(tierId);
        if (!definition || !Array.isArray(definition.frames) || definition.frames.length === 0) {
            return false;
        }
        const hasRenderableFrame = definition.frames.some((frame) => !!this.assetLoader?.getImage?.(frame.key));
        if (!hasRenderableFrame) {
            return false;
        }
        return this.defeatAnimationMode === "sprite" || this.defeatAnimationMode === "auto";
    }
    setHudZoom(scale, options = {}) {
        const normalized = this.normalizeHudZoom(scale);
        const changed = Math.abs(normalized - this.hudZoom) > 0.001;
        this.hudZoom = normalized;
        this.applyHudZoomSetting(normalized);
        if (changed && !options.silent) {
            const percent = Math.round(normalized * 100);
            this.hud.appendLog(`HUD zoom set to ${percent}%`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ hudZoom: normalized });
        }
        if (options.render !== false && changed) {
            this.render();
        }
    }
    setHudLayoutSide(side, options = {}) {
        const normalized = this.normalizeHudLayout(side);
        const changed = normalized !== this.hudLayout;
        this.hudLayout = normalized;
        this.applyHudLayoutSetting(normalized);
        this.updateOptionsOverlayState();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ hudLayout: normalized });
        }
        if (!options.silent && changed) {
            this.hud.appendLog(`HUD layout set to ${normalized === "left" ? "left-handed" : "right-handed"}.`);
        }
        if (options.render !== false && changed) {
            this.render();
        }
    }
    setCastleSkin(skin, options = {}) {
        const normalized = this.normalizeCastleSkin(skin);
        const changed = normalized !== this.castleSkin;
        this.castleSkin = normalized;
        if (this.hud?.setCastleSkin) {
            this.hud.setCastleSkin(normalized);
        }
        if (changed && options.persist !== false) {
            this.persistPlayerSettings({ castleSkin: normalized });
        }
        if (changed && options.updateOptions !== false) {
            this.updateOptionsOverlayState();
        }
    }
    setHudFontScale(scale, options = {}) {
        const normalized = this.normalizeHudFontScale(scale);
        const changed = Math.abs(normalized - this.hudFontScale) > 0.001;
        this.hudFontScale = normalized;
        this.applyHudFontScaleSetting(normalized);
        if (changed && !options.silent) {
            this.hud.appendLog(`HUD font size set to ${formatHudFontScale(normalized)}`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ hudFontScale: normalized });
        }
        if (options.render !== false && changed) {
            this.render();
        }
    }
    setTextSizeScale(scale, options = {}) {
        const normalized = this.normalizeTextSizeScale(scale);
        const changed = Math.abs(normalized - this.textSizeScale) > 0.001;
        this.textSizeScale = normalized;
        this.applyTextSizeScaleSetting(normalized);
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ textSizeScale: normalized });
        }
        this.updateOptionsOverlayState();
        if (!options.silent && changed) {
            this.hud.appendLog(`Text size set to ${Math.round(normalized * 100)}%`);
        }
        if (options.render !== false && changed) {
            this.render();
        }
    }
    cycleHudFontScale(direction = 1) {
        const nextPreset = getNextHudFontPreset(this.hudFontScale, direction);
        this.setHudFontScale(nextPreset.value);
    }
    buildTelemetryExport(includeQueue = false) {
        const available = Boolean(this.telemetryClient);
        const queue = available ? [...this.telemetryClient.getQueue()] : [];
        const enabled = available
            ? typeof this.telemetryClient.isEnabled === "function"
                ? this.telemetryClient.isEnabled()
                : Boolean(this.telemetryEnabled)
            : Boolean(this.telemetryEnabled);
        const exportData = {
            available,
            enabled,
            endpoint: this.telemetryEndpoint ?? null,
            queueSize: queue.length,
            soundIntensity: this.audioIntensity
        };
        if (includeQueue) {
            exportData.queue = queue.map((event) => ({
                ...event,
                metadata: event.metadata ? { ...event.metadata } : undefined
            }));
        }
        return exportData;
    }
    normalizeHudZoom(value) {
        if (!Number.isFinite(value))
            return HUD_ZOOM_DEFAULT;
        const clamped = Math.min(HUD_ZOOM_MAX, Math.max(HUD_ZOOM_MIN, value));
        return Math.round(clamped * 100) / 100;
    }
    normalizeCastleSkin(value) {
        if (typeof value !== "string") {
            return "classic";
        }
        const normalized = value.toLowerCase();
        if (normalized === "dusk" || normalized === "aurora" || normalized === "ember") {
            return normalized;
        }
        return "classic";
    }
    normalizeHudLayout(side) {
        return side === "left" ? "left" : "right";
    }
    normalizeHudFontScale(value) {
        return normalizeHudFontScaleValue(value);
    }
    normalizeTextSizeScale(value) {
        if (!Number.isFinite(value))
            return 1;
        return Math.min(1.1, Math.max(0.9, Math.round(value * 100) / 100));
    }
    getNextWaveMicroTip() {
        if (!Array.isArray(WAVE_MICRO_TIPS) || WAVE_MICRO_TIPS.length === 0) {
            return null;
        }
        const tip = WAVE_MICRO_TIPS[this.waveMicroTipIndex % WAVE_MICRO_TIPS.length];
        this.waveMicroTipIndex = (this.waveMicroTipIndex + 1) % WAVE_MICRO_TIPS.length;
        return tip;
    }
    normalizeBackgroundBrightness(value) {
        if (!Number.isFinite(value))
            return BG_BRIGHTNESS_DEFAULT;
        const clamped = Math.min(BG_BRIGHTNESS_MAX, Math.max(BG_BRIGHTNESS_MIN, value));
        return Math.round(clamped * 100) / 100;
    }
    normalizeSoundVolume(value) {
        if (!Number.isFinite(value)) {
            return SOUND_VOLUME_DEFAULT;
        }
        const clamped = Math.min(SOUND_VOLUME_MAX, Math.max(SOUND_VOLUME_MIN, value));
        return Math.round(clamped * 100) / 100;
    }
    normalizeAudioIntensity(value) {
        if (!Number.isFinite(value)) {
            return AUDIO_INTENSITY_DEFAULT;
        }
        const clamped = Math.min(AUDIO_INTENSITY_MAX, Math.max(AUDIO_INTENSITY_MIN, value));
        return Math.round(clamped * 100) / 100;
    }
    normalizeVoicePack(value) {
        if (typeof value !== "string")
            return "mentor-classic";
        const normalized = value.toLowerCase();
        if (normalized === "mentor-calm" || normalized === "mentor-arcade") {
            return normalized;
        }
        return "mentor-classic";
    }
    normalizeMusicLevel(value) {
        if (!Number.isFinite(value)) {
            return MUSIC_LEVEL_DEFAULT;
        }
        const clamped = Math.min(MUSIC_LEVEL_MAX, Math.max(MUSIC_LEVEL_MIN, value));
        return Math.round(clamped * 100) / 100;
    }
    normalizeTutorialPacing(value) {
        const paced = Number.isFinite(value) ? value : 1;
        const clamped = Math.min(1.25, Math.max(0.75, paced));
        return Math.round(clamped * 100) / 100;
    }
    normalizeScreenShakeIntensity(value) {
        if (!Number.isFinite(value)) {
            return SCREEN_SHAKE_INTENSITY_DEFAULT;
        }
        const clamped = Math.min(SCREEN_SHAKE_INTENSITY_MAX, Math.max(SCREEN_SHAKE_INTENSITY_MIN, value));
        return Math.round(clamped * 100) / 100;
    }
    updateOptionsOverlayState() {
        if (!this.diagnostics)
            return;
        const selfTestState = this.playerSettings?.accessibilitySelfTest ?? ACCESSIBILITY_SELF_TEST_DEFAULT;
        const screenTimeStorage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        const nowWallMs = Date.now();
        const todayKey = getLocalDayKey(nowWallMs);
        if (!this.screenTimeSettings) {
            this.screenTimeSettings = readScreenTimeSettings(screenTimeStorage);
        }
        if (!this.screenTimeUsage || this.screenTimeUsage.day !== todayKey) {
            this.screenTimeUsage = readScreenTimeUsage(screenTimeStorage, nowWallMs);
        }
        const screenTimeGoalMinutes = Math.max(0, Math.floor(this.screenTimeSettings.goalMinutes ?? 0));
        const screenTimeMinutesToday = this.getScreenTimeMinutesToday(this.screenTimeUsage.totalMs);
        const screenTimeLocked = isLockoutActive(this.screenTimeUsage, nowWallMs);
        this.hud.syncOptionsOverlayState({
            soundEnabled: this.soundEnabled,
            soundVolume: this.soundVolume,
            soundIntensity: this.audioIntensity,
            audioNarrationEnabled: this.audioNarrationEnabled,
            accessibilityPresetEnabled: this.accessibilityPresetEnabled,
            breakReminderIntervalMinutes: this.breakReminderIntervalMinutes,
            screenTime: {
                goalMinutes: screenTimeGoalMinutes,
                lockoutMode: this.screenTimeSettings.lockoutMode ?? "off",
                minutesToday: screenTimeMinutesToday,
                locked: screenTimeLocked,
                lockoutRemainingMs: getLockoutRemainingMs(this.screenTimeUsage, nowWallMs)
            },
            voicePackId: this.voicePackId,
            tutorialPacing: this.tutorialPacing,
            largeSubtitlesEnabled: this.largeSubtitlesEnabled,
            musicEnabled: this.musicEnabled,
            musicLevel: this.musicLevel,
            screenShakeEnabled: this.screenShakeEnabled,
            screenShakeIntensity: this.screenShakeIntensity,
            diagnosticsVisible: this.diagnostics.isVisible(),
            lowGraphicsEnabled: this.lowGraphicsEnabled,
            virtualKeyboardEnabled: this.virtualKeyboardEnabled,
            virtualKeyboardLayout: this.virtualKeyboardLayout,
            hapticsEnabled: this.hapticsEnabled,
            textSizeScale: this.textSizeScale,
            reducedMotionEnabled: this.reducedMotionEnabled,
            latencySparklineEnabled: this.latencySparklineEnabled,
            checkeredBackgroundEnabled: this.checkeredBackgroundEnabled,
            readableFontEnabled: this.readableFontEnabled,
            dyslexiaFontEnabled: this.dyslexiaFontEnabled,
            dyslexiaSpacingEnabled: this.dyslexiaSpacingEnabled,
            reducedCognitiveLoadEnabled: this.reducedCognitiveLoadEnabled,
            backgroundBrightness: this.backgroundBrightness,
            colorblindPaletteEnabled: this.colorblindPaletteEnabled,
            colorblindPaletteMode: this.colorblindPaletteMode,
            focusOutlinePreset: this.focusOutlinePreset,
            castleSkin: this.castleSkin,
            parallaxScene: this.parallaxScene,
            selfTest: selfTestState,
            hudZoom: this.hudZoom,
            hudLayout: this.hudLayout,
            hudFontScale: this.hudFontScale,
            defeatAnimationMode: this.defeatAnimationMode,
            hotkeys: this.hotkeys,
            telemetry: {
                available: Boolean(this.telemetryClient),
                checked: Boolean(this.telemetryClient ? this.telemetryEnabled : false),
                disabled: !this.telemetryClient
            },
            eliteAffixes: {
                enabled: Boolean(this.featureToggles?.eliteAffixes),
                disabled: false
            },
            turretFeatures: {
                crystalPulse: {
                    enabled: Boolean(this.featureToggles?.crystalPulse),
                    disabled: false
                }
            }
        });
    }
    applyReducedMotionSetting(enabled) {
        if (typeof this.hud?.setReducedMotionEnabled === "function") {
            this.hud.setReducedMotionEnabled(enabled);
            return;
        }
        if (typeof document === "undefined")
            return;
        const root = document.documentElement;
        if (root) {
            root.dataset.reducedMotion = enabled ? "true" : "false";
            root.dataset.vfxMode = enabled ? "reduced" : "full";
        }
        const body = document.body;
        if (body) {
            body.dataset.reducedMotion = enabled ? "true" : "false";
            body.dataset.vfxMode = enabled ? "reduced" : "full";
        }
    }
    applyCheckeredBackgroundSetting(enabled) {
        if (typeof document === "undefined")
            return;
        const root = document.documentElement;
        if (root) {
            root.dataset.checkeredBackground = enabled ? "true" : "false";
        }
        const body = document.body;
        if (body) {
            body.dataset.checkeredBackground = enabled ? "true" : "false";
        }
    }
    applyReadableFontSetting(enabled) {
        if (typeof document === "undefined")
            return;
        const root = document.documentElement;
        if (root) {
            root.dataset.readableFont = enabled ? "true" : "false";
        }
        const body = document.body;
        if (body) {
            body.dataset.readableFont = enabled ? "true" : "false";
        }
    }
    applyDyslexiaFontSetting(enabled) {
        if (typeof document === "undefined")
            return;
        const root = document.documentElement;
        if (root) {
            root.dataset.dyslexiaFont = enabled ? "true" : "false";
        }
        const body = document.body;
        if (body) {
            body.dataset.dyslexiaFont = enabled ? "true" : "false";
        }
    }
    applyDyslexiaSpacingSetting(enabled) {
        if (typeof document === "undefined")
            return;
        const root = document.documentElement;
        if (root) {
            root.dataset.dyslexiaSpacing = enabled ? "true" : "false";
        }
        const body = document.body;
        if (body) {
            body.dataset.dyslexiaSpacing = enabled ? "true" : "false";
        }
    }
    applyCognitiveLoadSetting(enabled) {
        if (typeof document === "undefined")
            return;
        const root = document.documentElement;
        const body = document.body;
        const hud = document.getElementById("hud");
        const modeValue = enabled ? "reduced" : undefined;
        if (root) {
            if (modeValue) {
                root.dataset.cognitiveMode = modeValue;
            }
            else {
                delete root.dataset.cognitiveMode;
            }
        }
        if (body) {
            if (modeValue) {
                body.dataset.cognitiveMode = modeValue;
            }
            else {
                delete body.dataset.cognitiveMode;
            }
        }
        if (hud instanceof HTMLElement) {
            if (modeValue) {
                hud.dataset.cognitiveMode = modeValue;
            }
            else {
                hud.removeAttribute("data-cognitive-mode");
            }
        }
    }
    applyAudioNarrationSetting(enabled) {
        if (typeof document === "undefined")
            return;
        const root = document.documentElement;
        const body = document.body;
        if (root) {
            if (enabled) {
                root.dataset.audioNarration = "true";
            }
            else {
                delete root.dataset.audioNarration;
            }
        }
        if (body) {
            if (enabled) {
                body.dataset.audioNarration = "true";
            }
            else {
                delete body.dataset.audioNarration;
            }
        }
    }
    applyLargeSubtitlesSetting(enabled) {
        if (typeof document === "undefined")
            return;
        const root = document.documentElement;
        const body = document.body;
        const value = enabled ? "large" : undefined;
        if (root) {
            if (value) {
                root.dataset.subtitles = value;
            }
            else {
                delete root.dataset.subtitles;
            }
        }
        if (body) {
            if (value) {
                body.dataset.subtitles = value;
            }
            else {
                delete body.dataset.subtitles;
            }
        }
    }
    applyFocusOutlinePreset(preset) {
        if (typeof document === "undefined")
            return;
        const normalized = normalizeFocusOutlinePreset(preset);
        const root = document.documentElement;
        const body = document.body;
        const value = normalized === "system" ? null : normalized;
        if (root) {
            if (value) {
                root.dataset.focusOutline = value;
            }
            else {
                delete root.dataset.focusOutline;
            }
        }
        if (body) {
            if (value) {
                body.dataset.focusOutline = value;
            }
            else {
                delete body.dataset.focusOutline;
            }
        }
    }
    applyBackgroundBrightnessSetting(value) {
        if (typeof document === "undefined")
            return;
        const root = document.documentElement;
        if (root && root.style) {
            root.style.setProperty("--bg-brightness", value.toString());
        }
    }
    normalizeColorblindMode(mode) {
        const allowed = new Set(["off", "deuteran", "protan", "tritan", "high-contrast"]);
        if (typeof mode !== "string")
            return "off";
        const trimmed = mode.trim().toLowerCase();
        return allowed.has(trimmed) ? trimmed : "off";
    }
    applyColorblindPaletteSetting(mode) {
        if (typeof document === "undefined")
            return;
        const normalized = this.normalizeColorblindMode(mode);
        const root = document.documentElement;
        if (root) {
            if (normalized === "off") {
                delete root.dataset.colorblindPalette;
            }
            else {
                root.dataset.colorblindPalette = normalized;
            }
        }
        const body = document.body;
        if (body) {
            if (normalized === "off") {
                delete body.dataset.colorblindPalette;
            }
            else {
                body.dataset.colorblindPalette = normalized;
            }
        }
    }
    isColorblindPaletteActive() {
        return this.colorblindPaletteMode !== "off";
    }
    loadBreakReminderIntervalMinutes() {
        if (typeof window === "undefined" || !window.localStorage) {
            return BREAK_REMINDER_INTERVAL_DEFAULT_MINUTES;
        }
        try {
            const raw = window.localStorage.getItem(BREAK_REMINDER_INTERVAL_STORAGE_KEY);
            if (!raw)
                return BREAK_REMINDER_INTERVAL_DEFAULT_MINUTES;
            if (raw === "off")
                return 0;
            const parsed = Number.parseInt(raw, 10);
            if (!Number.isFinite(parsed))
                return BREAK_REMINDER_INTERVAL_DEFAULT_MINUTES;
            const minutes = Math.max(0, Math.floor(parsed));
            if (!BREAK_REMINDER_INTERVAL_ALLOWED_MINUTES.has(minutes)) {
                return BREAK_REMINDER_INTERVAL_DEFAULT_MINUTES;
            }
            return minutes;
        }
        catch {
            return BREAK_REMINDER_INTERVAL_DEFAULT_MINUTES;
        }
    }
    persistBreakReminderIntervalMinutes(minutes) {
        if (typeof window === "undefined" || !window.localStorage)
            return;
        try {
            window.localStorage.setItem(BREAK_REMINDER_INTERVAL_STORAGE_KEY, minutes.toString());
        }
        catch {
            // best effort
        }
    }
    setBreakReminderIntervalMinutes(minutes, options = {}) {
        const parsed = Number.isFinite(minutes) ? Math.floor(minutes) : BREAK_REMINDER_INTERVAL_DEFAULT_MINUTES;
        const next = BREAK_REMINDER_INTERVAL_ALLOWED_MINUTES.has(parsed)
            ? parsed
            : BREAK_REMINDER_INTERVAL_DEFAULT_MINUTES;
        if (this.breakReminderIntervalMinutes === next && options.force !== true) {
            return;
        }
        this.breakReminderIntervalMinutes = next;
        const now = typeof performance !== "undefined" ? performance.now() : Date.now();
        const elapsed = Math.max(0, now - this.sessionStartMs);
        this.sessionReminderActive = false;
        this.sessionWellness?.hideReminder?.();
        this.sessionNextReminderMs =
            next > 0 ? elapsed + next * 60 * 1000 : Number.POSITIVE_INFINITY;
        if (!options.silent) {
            if (next > 0) {
                this.hud?.appendLog?.(`Break reminders set to every ${next} minutes.`);
            }
            else {
                this.hud?.appendLog?.("Break reminders disabled.");
            }
        }
        if (options.persist !== false) {
            this.persistBreakReminderIntervalMinutes(next);
        }
        this.updateOptionsOverlayState();
    }
    getScreenTimeMinutesToday(totalMs) {
        if (!Number.isFinite(totalMs))
            return 0;
        return Math.max(0, Math.floor(totalMs / 60_000));
    }
    syncScreenTimeUi(nowMs = Date.now(), options = {}) {
        const badge = this.screenTimeTodayBadge;
        const settings = this.screenTimeSettings ?? { goalMinutes: 0, lockoutMode: "off" };
        const usage = this.screenTimeUsage ??
            { day: getLocalDayKey(nowMs), totalMs: 0, lockoutUntilMs: null };
        const minutesToday = this.getScreenTimeMinutesToday(usage.totalMs);
        const goalMinutes = Math.max(0, Math.floor(settings.goalMinutes ?? 0));
        const locked = isLockoutActive(usage, nowMs);
        let state = "ok";
        if (locked) {
            state = "locked";
        }
        else if (goalMinutes > 0) {
            if (minutesToday >= goalMinutes) {
                state = "limit";
            }
            else {
                const remaining = goalMinutes - minutesToday;
                const ratio = goalMinutes > 0 ? minutesToday / goalMinutes : 0;
                if (remaining <= 5 || ratio >= 0.8) {
                    state = "warn";
                }
            }
        }
        const force = options.force === true;
        if (badge instanceof HTMLElement) {
            const nextText = `${minutesToday}m`;
            if (force || badge.textContent !== nextText) {
                badge.textContent = nextText;
            }
            if (force || badge.dataset.state !== state) {
                badge.dataset.state = state;
            }
            let aria = "";
            if (locked) {
                const remainingMs = getLockoutRemainingMs(usage, nowMs);
                const remainingMinutes = Math.max(1, Math.ceil(remainingMs / 60_000));
                aria = `Screen time lockout active, ${remainingMinutes} minutes remaining.`;
            }
            else if (goalMinutes > 0) {
                aria = `Screen time today ${minutesToday} of ${goalMinutes} minutes.`;
            }
            else {
                aria = `Screen time today ${minutesToday} minutes.`;
            }
            if (force || badge.getAttribute("aria-label") !== aria) {
                badge.setAttribute("aria-label", aria);
            }
        }
        if (this.optionsOverlayActive) {
            this.updateOptionsOverlayState();
        }
    }
    tickScreenTimeGoals(nowMs = Date.now()) {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        const day = getLocalDayKey(nowMs);
        if (!this.screenTimeSettings) {
            this.screenTimeSettings = readScreenTimeSettings(storage);
        }
        if (!this.screenTimeUsage) {
            this.screenTimeUsage = readScreenTimeUsage(storage, nowMs);
        }
        if (this.screenTimeUsage.day !== day) {
            this.screenTimeUsage = { day, totalMs: 0, lockoutUntilMs: null };
            this.screenTimeLastTotalMs = 0;
            this.screenTimeWarned = false;
            this.screenTimeGoalReached = false;
            this.screenTimeLockoutStarted = false;
            this.screenTimeLastTickWallMs = nowMs;
            writeScreenTimeUsage(storage, this.screenTimeUsage);
        }
        const hidden = typeof document !== "undefined" ? Boolean(document.hidden) : false;
        const lastTick = Number.isFinite(this.screenTimeLastTickWallMs)
            ? this.screenTimeLastTickWallMs
            : nowMs;
        const deltaMs = nowMs - lastTick;
        this.screenTimeLastTickWallMs = nowMs;
        let mutated = false;
        const gapThresholdMs = 15_000;
        if (!hidden && Number.isFinite(deltaMs) && deltaMs > 0 && deltaMs <= gapThresholdMs) {
            this.screenTimeUsage.totalMs = Math.max(0, this.screenTimeUsage.totalMs + deltaMs);
            mutated = true;
        }
        const goalMinutes = Math.max(0, Math.floor(this.screenTimeSettings.goalMinutes ?? 0));
        const goalMs = goalMinutes > 0 ? goalMinutes * 60_000 : 0;
        const totalMs = Math.max(0, this.screenTimeUsage.totalMs);
        const warnThresholdMs = goalMs > 0 ? Math.max(goalMs * 0.8, goalMs - 5 * 60_000) : Number.POSITIVE_INFINITY;
        if (!this.screenTimeWarned && goalMs > 0 && totalMs >= warnThresholdMs && totalMs < goalMs) {
            this.screenTimeWarned = true;
            const minutesToday = this.getScreenTimeMinutesToday(totalMs);
            this.hud?.appendLog?.(`Screen time: ${minutesToday}/${goalMinutes} minutes. Almost at your daily goal.`);
        }
        const reached = goalMs > 0 && totalMs >= goalMs;
        if (reached && !this.screenTimeGoalReached) {
            this.screenTimeGoalReached = true;
            const minutesToday = this.getScreenTimeMinutesToday(totalMs);
            this.hud?.appendLog?.(`Daily screen-time goal reached (${minutesToday}/${goalMinutes} minutes).`);
        }
        const lockoutMode = this.screenTimeSettings.lockoutMode ?? "off";
        if (reached && lockoutMode !== "off" && this.screenTimeUsage.lockoutUntilMs === null) {
            const until = computeLockoutUntilMs(lockoutMode, nowMs);
            if (until) {
                this.screenTimeUsage.lockoutUntilMs = until;
                mutated = true;
            }
        }
        const locked = isLockoutActive(this.screenTimeUsage, nowMs);
        if (locked && !this.screenTimeLockoutStarted) {
            this.screenTimeLockoutStarted = true;
            const remainingMs = getLockoutRemainingMs(this.screenTimeUsage, nowMs);
            const remainingMinutes = Math.max(1, Math.ceil(remainingMs / 60_000));
            const noun = remainingMinutes === 1 ? "minute" : "minutes";
            const message = lockoutMode === "today"
                ? "Screen time lockout active until tomorrow."
                : `Screen time lockout active: ${remainingMinutes} ${noun} remaining.`;
            this.hud?.appendLog?.(message);
            if (this.running && !this.manualTick) {
                this.pause();
            }
            if (this.typingDrillsOverlayActive) {
                this.closeTypingDrills();
            }
            else if (!this.optionsOverlayActive && !this.menuActive && !this.waveScorecardActive) {
                this.openOptionsOverlay();
            }
        }
        if (mutated) {
            const persistAt = typeof this.screenTimeNextPersistAtMs === "number" ? this.screenTimeNextPersistAtMs : 0;
            if (storage && (this.screenTimeUsage.lockoutUntilMs !== null || nowMs >= persistAt)) {
                writeScreenTimeUsage(storage, this.screenTimeUsage);
                this.screenTimeNextPersistAtMs = nowMs + 10_000;
            }
        }
        this.syncScreenTimeUi(nowMs);
        this.screenTimeLastTotalMs = totalMs;
    }
    isScreenTimeLockoutActive(nowMs = Date.now()) {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        const day = getLocalDayKey(nowMs);
        if (!this.screenTimeUsage || this.screenTimeUsage.day !== day) {
            this.screenTimeUsage = readScreenTimeUsage(storage, nowMs);
        }
        return isLockoutActive(this.screenTimeUsage, nowMs);
    }
    handleScreenTimeLockoutAttempt(source = "start") {
        const nowMs = Date.now();
        const remainingMs = this.screenTimeUsage
            ? getLockoutRemainingMs(this.screenTimeUsage, nowMs)
            : 0;
        const remainingMinutes = Math.max(1, Math.ceil(Math.max(0, remainingMs) / 60_000));
        const noun = remainingMinutes === 1 ? "minute" : "minutes";
        if (this.menuActive && typeof document !== "undefined") {
            const copy = document.getElementById("main-menu-copy");
            if (copy instanceof HTMLElement) {
                copy.textContent = `Screen time lockout: ${remainingMinutes} ${noun} remaining. Take a break, then come back.`;
            }
        }
        this.hud?.appendLog?.(`Screen time lockout (${source} blocked): ${remainingMinutes} ${noun} remaining.`);
        if (this.running && !this.manualTick) {
            this.pause();
        }
        if (!this.optionsOverlayActive && !this.menuActive && !this.waveScorecardActive) {
            this.openOptionsOverlay();
        }
        else if (this.optionsOverlayActive) {
            this.updateOptionsOverlayState();
        }
    }
    setScreenTimeGoalMinutes(minutes) {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        const nowMs = Date.now();
        this.screenTimeLastTickWallMs = nowMs;
        this.screenTimeSettings = writeScreenTimeSettings(storage, { goalMinutes: minutes });
        this.screenTimeUsage = readScreenTimeUsage(storage, nowMs);
        this.screenTimeWarned = false;
        this.screenTimeGoalReached = false;
        this.screenTimeLockoutStarted = false;
        const goalMinutes = Math.max(0, Math.floor(this.screenTimeSettings.goalMinutes ?? 0));
        const goalMs = goalMinutes > 0 ? goalMinutes * 60_000 : 0;
        const reached = goalMs > 0 && this.screenTimeUsage.totalMs >= goalMs;
        const mode = this.screenTimeSettings.lockoutMode ?? "off";
        if (goalMinutes <= 0 || mode === "off") {
            if (this.screenTimeUsage.lockoutUntilMs !== null) {
                this.screenTimeUsage.lockoutUntilMs = null;
                writeScreenTimeUsage(storage, this.screenTimeUsage);
            }
        }
        else if (reached) {
            const until = computeLockoutUntilMs(mode, nowMs);
            this.screenTimeUsage.lockoutUntilMs = until;
            writeScreenTimeUsage(storage, this.screenTimeUsage);
        }
        else if (this.screenTimeUsage.lockoutUntilMs !== null) {
            this.screenTimeUsage.lockoutUntilMs = null;
            writeScreenTimeUsage(storage, this.screenTimeUsage);
        }
        if (goalMinutes > 0) {
            this.hud?.appendLog?.(`Daily screen-time goal set to ${goalMinutes} minutes.`);
        }
        else {
            this.hud?.appendLog?.("Daily screen-time goal disabled.");
        }
        this.syncScreenTimeUi(nowMs, { force: true });
    }
    setScreenTimeLockoutMode(mode) {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        const nowMs = Date.now();
        this.screenTimeLastTickWallMs = nowMs;
        this.screenTimeSettings = writeScreenTimeSettings(storage, { lockoutMode: mode });
        this.screenTimeUsage = readScreenTimeUsage(storage, nowMs);
        this.screenTimeWarned = false;
        this.screenTimeGoalReached = false;
        this.screenTimeLockoutStarted = false;
        const goalMinutes = Math.max(0, Math.floor(this.screenTimeSettings.goalMinutes ?? 0));
        const goalMs = goalMinutes > 0 ? goalMinutes * 60_000 : 0;
        const reached = goalMs > 0 && this.screenTimeUsage.totalMs >= goalMs;
        const resolvedMode = this.screenTimeSettings.lockoutMode ?? "off";
        if (resolvedMode === "off" || goalMinutes <= 0) {
            if (this.screenTimeUsage.lockoutUntilMs !== null) {
                this.screenTimeUsage.lockoutUntilMs = null;
                writeScreenTimeUsage(storage, this.screenTimeUsage);
            }
        }
        else if (reached) {
            const until = computeLockoutUntilMs(resolvedMode, nowMs);
            this.screenTimeUsage.lockoutUntilMs = until;
            writeScreenTimeUsage(storage, this.screenTimeUsage);
        }
        else if (this.screenTimeUsage.lockoutUntilMs !== null) {
            this.screenTimeUsage.lockoutUntilMs = null;
            writeScreenTimeUsage(storage, this.screenTimeUsage);
        }
        const label = resolvedMode === "off"
            ? "off"
            : resolvedMode === "today"
                ? "until tomorrow"
                : resolvedMode.replace("rest-", "rest ");
        this.hud?.appendLog?.(`Screen time lockout set to ${label}.`);
        this.syncScreenTimeUi(nowMs, { force: true });
    }
    resetScreenTimeForToday() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        const nowMs = Date.now();
        const day = getLocalDayKey(nowMs);
        this.screenTimeUsage = { day, totalMs: 0, lockoutUntilMs: null };
        this.screenTimeLastTickWallMs = nowMs;
        this.screenTimeNextPersistAtMs = 0;
        this.screenTimeLastTotalMs = 0;
        this.screenTimeWarned = false;
        this.screenTimeGoalReached = false;
        this.screenTimeLockoutStarted = false;
        writeScreenTimeUsage(storage, this.screenTimeUsage);
        this.hud?.appendLog?.("Screen time reset for today.");
        this.syncScreenTimeUi(nowMs, { force: true });
    }
    updateSessionWellness() {
        const now = typeof performance !== "undefined" ? performance.now() : Date.now();
        const elapsed = Math.max(0, now - this.sessionStartMs);
        if (this.sessionWellness) {
            this.sessionWellness.setElapsed(elapsed);
            if (!this.sessionReminderActive && elapsed >= this.sessionNextReminderMs) {
                this.showBreakReminder(elapsed);
            }
        }
        this.tickScreenTimeGoals();
    }
    showBreakReminder(elapsedMs) {
        if (!Number.isFinite(this.breakReminderIntervalMinutes) || this.breakReminderIntervalMinutes <= 0) {
            this.sessionReminderActive = false;
            this.sessionNextReminderMs = Number.POSITIVE_INFINITY;
            this.sessionWellness?.hideReminder?.();
            return;
        }
        this.sessionReminderActive = true;
        this.sessionNextReminderMs = elapsedMs + this.breakReminderIntervalMinutes * 60 * 1000;
        this.sessionWellness?.showReminder(elapsedMs);
        this.hud?.appendLog?.("Break reminder: stretch, breathe, and rest your hands.");
    }
    handleBreakReminderSnooze() {
        const now = typeof performance !== "undefined" ? performance.now() : Date.now();
        const elapsed = Math.max(0, now - this.sessionStartMs);
        this.fatigueDetectorState = snoozeFatigueDetector(this.fatigueDetectorState ?? createFatigueDetectorState(), elapsed, BREAK_REMINDER_SNOOZE_MS);
        this.sessionNextReminderMs = elapsed + BREAK_REMINDER_SNOOZE_MS;
        this.sessionReminderActive = false;
        this.sessionWellness?.hideReminder();
        this.hud?.appendLog?.("Break reminder snoozed for 10 minutes.");
    }
    handleBreakReset() {
        this.sessionStartMs = typeof performance !== "undefined" ? performance.now() : Date.now();
        this.sessionNextReminderMs =
            this.breakReminderIntervalMinutes > 0
                ? this.breakReminderIntervalMinutes * 60 * 1000
                : Number.POSITIVE_INFINITY;
        this.fatigueDetectorState = createFatigueDetectorState();
        this.fatigueWaveTimingSamples = [];
        this.sessionReminderActive = false;
        this.sessionWellness?.hideReminder();
        this.hud?.appendLog?.("Session timer reset after a break.");
    }
    applyHudZoomSetting(scale) {
        if (this.hud?.setHudZoom) {
            this.hud.setHudZoom(scale);
        }
    }
    applyHudLayoutSetting(side) {
        if (this.hud?.setHudLayoutSide) {
            this.hud.setHudLayoutSide(side);
        }
        if (typeof document !== "undefined") {
            document.body.dataset.hudLayout = side;
        }
    }
    applyHudFontScaleSetting(scale) {
        this.hud.setHudFontScale(scale);
    }
    applyTextSizeScaleSetting(scale) {
        if (typeof document !== "undefined" && document.documentElement) {
            document.documentElement.style.setProperty("--text-size-scale", scale.toString());
        }
    }
    setTelemetryEnabled(enabled, options = {}) {
        const silent = Boolean(options.silent);
        const persist = options.persist !== false;
        if (!this.telemetryClient) {
            this.telemetryEnabled = Boolean(enabled);
            if (persist) {
                this.persistPlayerSettings({ telemetryEnabled: this.telemetryEnabled });
            }
            if (!silent) {
                this.hud.appendLog("Telemetry unavailable (feature toggle disabled).");
            }
            this.updateOptionsOverlayState();
            return false;
        }
        const next = Boolean(enabled);
        const current = typeof this.telemetryClient.isEnabled === "function"
            ? this.telemetryClient.isEnabled()
            : Boolean(this.telemetryEnabled);
        if (current === next) {
            this.telemetryEnabled = next;
            this.syncTelemetryDebugControls();
            this.updateOptionsOverlayState();
            return false;
        }
        this.telemetryClient.setEnabled(next);
        this.telemetryEnabled = next;
        if (!silent) {
            this.hud.appendLog(`Telemetry ${next ? "enabled" : "disabled"}`);
        }
        if (persist) {
            this.persistPlayerSettings({ telemetryEnabled: next });
        }
        this.syncTelemetryDebugControls();
        this.updateOptionsOverlayState();
        const menuToggle = typeof document !== "undefined"
            ? document.getElementById("main-menu-telemetry-toggle")
            : null;
        if (menuToggle instanceof HTMLInputElement) {
            menuToggle.checked = this.telemetryEnabled;
        }
        const menuWrapper = typeof document !== "undefined"
            ? document.getElementById("main-menu-telemetry-toggle-wrapper")
            : null;
        if (menuWrapper instanceof HTMLElement) {
            menuWrapper.style.display = this.telemetryClient ? "" : "none";
            menuWrapper.setAttribute("aria-hidden", this.telemetryClient ? "false" : "true");
        }
        return true;
    }
    toggleTelemetry(options = {}) {
        return this.setTelemetryEnabled(!this.telemetryEnabled, options);
    }
    setTelemetryEndpoint(endpoint, options = {}) {
        if (!this.telemetryClient) {
            if (!options.silent) {
                this.hud.appendLog("Telemetry unavailable (feature toggle disabled).");
            }
            return;
        }
        const normalized = typeof endpoint === "string" ? endpoint.trim() : "";
        const next = normalized.length > 0 ? normalized : null;
        this.telemetryEndpoint = next;
        this.telemetryClient.setEndpoint(next);
        if (!options.silent) {
            this.hud.appendLog(next ? `Telemetry endpoint set to ${next}` : "Telemetry endpoint cleared");
        }
        this.syncTelemetryDebugControls();
    }
    flushTelemetry(options = {}) {
        if (!this.telemetryClient) {
            if (!options.silent) {
                this.hud.appendLog("Telemetry unavailable (feature toggle disabled).");
            }
            return [];
        }
        const enabled = typeof this.telemetryClient.isEnabled === "function"
            ? this.telemetryClient.isEnabled()
            : Boolean(this.telemetryEnabled);
        if (!enabled) {
            if (!options.silent) {
                const queued = this.telemetryClient.getQueue().length;
                if (queued > 0) {
                    const noun = queued === 1 ? "event" : "events";
                    this.hud.appendLog(`Telemetry disabled; queue holds ${queued} ${noun}. Enable telemetry before flushing.`);
                }
                else {
                    this.hud.appendLog("Telemetry disabled; nothing to flush.");
                }
            }
            this.syncTelemetryDebugControls();
            return [];
        }
        const endpoint = this.telemetryEndpoint ?? this.telemetryClient.getEndpoint?.() ?? null;
        if (!endpoint) {
            if (!options.silent) {
                const queued = this.telemetryClient.getQueue().length;
                if (queued > 0) {
                    const noun = queued === 1 ? "event" : "events";
                    this.hud.appendLog(`Telemetry endpoint not set; queue holds ${queued} ${noun}. Set an endpoint or download the queue instead.`);
                }
                else {
                    this.hud.appendLog("Telemetry endpoint not set; nothing to flush.");
                }
            }
            this.syncTelemetryDebugControls();
            return [];
        }
        const batch = this.telemetryClient.flush();
        if (!options.silent) {
            if (batch.length === 0) {
                this.hud.appendLog("Telemetry queue empty");
            }
            else {
                const noun = batch.length === 1 ? "event" : "events";
                this.hud.appendLog(`Telemetry flushed (${batch.length} ${noun})`);
            }
        }
        this.syncTelemetryDebugControls();
        return batch;
    }
    purgeTelemetryQueue(options = {}) {
        if (!this.telemetryClient) {
            if (!options.silent) {
                this.hud.appendLog("Telemetry unavailable (feature toggle disabled).");
            }
            return 0;
        }
        const purged = typeof this.telemetryClient.purge === "function" ? this.telemetryClient.purge() : 0;
        if (!options.silent) {
            if (purged === 0) {
                this.hud.appendLog("Telemetry queue already empty.");
            }
            else {
                const noun = purged === 1 ? "event" : "events";
                this.hud.appendLog(`Telemetry queue cleared (${purged} ${noun})`);
            }
        }
        this.syncTelemetryDebugControls();
        return purged;
    }
    exportTelemetryQueue(options = {}) {
        if (!this.telemetryClient) {
            if (!options.silent) {
                this.hud.appendLog("Telemetry unavailable (feature toggle disabled).");
            }
            return;
        }
        const telemetryData = this.buildTelemetryExport(true);
        const queue = telemetryData.queue ?? [];
        const count = telemetryData.queueSize ?? queue.length;
        if (count === 0) {
            if (!options.silent) {
                this.hud.appendLog("Telemetry queue empty; nothing to export.");
            }
            return;
        }
        if (typeof document === "undefined" || !document.body || typeof URL === "undefined") {
            console.warn("Telemetry export skipped: document context unavailable.");
            if (!options.silent) {
                this.hud.appendLog("Telemetry export failed (no active document context).");
            }
            return;
        }
        const generatedAt = new Date().toISOString();
        const payload = {
            generatedAt,
            telemetryAvailable: telemetryData.available,
            telemetryEnabled: telemetryData.enabled,
            endpoint: telemetryData.endpoint,
            count,
            events: queue
        };
        const filename = `keyboard-defense-telemetry-${generatedAt.replace(/[:.]/g, "-")}.json`;
        const blob = new Blob([JSON.stringify(payload, null, 2)], {
            type: "application/json"
        });
        const link = document.createElement("a");
        const url = URL.createObjectURL(blob);
        link.href = url;
        link.download = filename;
        document.body.appendChild(link);
        try {
            link.click();
            if (!options.silent) {
                const noun = count === 1 ? "event" : "events";
                this.hud.appendLog(`Telemetry queue exported (${count} ${noun}) to ${filename}`);
            }
            console.info("[telemetry] queue export complete", {
                filename,
                count,
                endpoint: this.telemetryEndpoint ?? null
            });
        }
        finally {
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        }
    }
    getTelemetryQueueSnapshot() {
        if (!this.telemetryClient) {
            return [];
        }
        return [...this.telemetryClient.getQueue()];
    }
    getTelemetryEndpoint() {
        return this.telemetryEndpoint ?? null;
    }
    syncTelemetryDebugControls() {
        if (!this.telemetryDebugControls) {
            return;
        }
        const controls = this.telemetryDebugControls;
        const container = controls.container;
        const client = this.telemetryClient ?? null;
        if (!client) {
            if (container) {
                container.style.display = "none";
                container.setAttribute("aria-hidden", "true");
                container.dataset.visible = "false";
            }
            if (controls.toggleButton) {
                controls.toggleButton.disabled = true;
                controls.toggleButton.textContent = "Telemetry unavailable";
                controls.toggleButton.setAttribute("aria-hidden", "true");
                controls.toggleButton.setAttribute("aria-pressed", "false");
                controls.toggleButton.setAttribute("aria-disabled", "true");
            }
            if (controls.flushButton) {
                controls.flushButton.disabled = true;
                controls.flushButton.textContent = "Flush Telemetry (0)";
                controls.flushButton.setAttribute("aria-hidden", "true");
                controls.flushButton.setAttribute("aria-disabled", "true");
            }
            if (controls.downloadButton) {
                controls.downloadButton.disabled = true;
                controls.downloadButton.textContent = "Download Telemetry (0)";
                controls.downloadButton.setAttribute("aria-hidden", "true");
                controls.downloadButton.setAttribute("aria-disabled", "true");
            }
            if (controls.endpointInput) {
                controls.endpointInput.value = "";
                controls.endpointInput.disabled = true;
            }
            if (controls.endpointApply) {
                controls.endpointApply.disabled = true;
            }
            return;
        }
        const enabled = typeof client.isEnabled === "function" ? client.isEnabled() : Boolean(this.telemetryEnabled);
        this.telemetryEnabled = enabled;
        const queueLength = client.getQueue().length;
        const endpoint = this.telemetryEndpoint ?? client.getEndpoint?.() ?? null;
        this.telemetryEndpoint = endpoint;
        const hasEndpoint = Boolean(endpoint && endpoint.trim().length > 0);
        if (container) {
            container.style.display = "";
            container.setAttribute("aria-hidden", "false");
            container.dataset.visible = "true";
        }
        if (controls.toggleButton) {
            controls.toggleButton.disabled = false;
            controls.toggleButton.textContent = enabled ? "Disable Telemetry" : "Enable Telemetry";
            controls.toggleButton.setAttribute("aria-hidden", "false");
            controls.toggleButton.setAttribute("aria-pressed", enabled ? "true" : "false");
            controls.toggleButton.setAttribute("aria-disabled", "false");
        }
        if (controls.flushButton) {
            controls.flushButton.disabled = !enabled || queueLength === 0 || !hasEndpoint;
            controls.flushButton.textContent = `Flush Telemetry (${queueLength})`;
            controls.flushButton.title = hasEndpoint
                ? ""
                : "Set a telemetry endpoint before flushing queued events.";
            controls.flushButton.setAttribute("aria-hidden", "false");
            controls.flushButton.setAttribute("aria-disabled", controls.flushButton.disabled ? "true" : "false");
        }
        if (controls.downloadButton) {
            controls.downloadButton.disabled = queueLength === 0;
            controls.downloadButton.textContent = `Download Telemetry (${queueLength})`;
            controls.downloadButton.setAttribute("aria-hidden", "false");
            controls.downloadButton.setAttribute("aria-disabled", controls.downloadButton.disabled ? "true" : "false");
            controls.downloadButton.setAttribute("aria-label", queueLength === 1
                ? "Download telemetry queue (1 event)"
                : `Download telemetry queue (${queueLength} events)`);
        }
        if (controls.endpointInput) {
            controls.endpointInput.disabled = false;
            controls.endpointInput.value = this.telemetryEndpoint ?? "";
        }
        if (controls.endpointApply) {
            controls.endpointApply.disabled = false;
        }
    }
    syncSoundDebugControls() {
        const controls = this.soundDebugControls;
        if (!controls) {
            return;
        }
        const slider = controls.slider;
        const valueLabel = controls.valueLabel;
        const intensitySlider = controls.intensitySlider;
        const intensityValueLabel = controls.intensityValueLabel;
        const percent = Math.round(this.soundVolume * 100);
        const intensityPercent = Math.round(this.audioIntensity * 100);
        const muted = !this.soundEnabled;
        if (slider) {
            const nextValue = this.soundVolume.toFixed(2);
            if (slider.value !== nextValue) {
                slider.value = nextValue;
            }
            slider.disabled = muted;
            slider.setAttribute("aria-disabled", muted ? "true" : "false");
            slider.setAttribute("aria-valuenow", nextValue);
            slider.setAttribute("aria-valuetext", muted ? `Muted (${percent}%)` : `${percent}%`);
        }
        if (valueLabel) {
            if (muted) {
                valueLabel.textContent = `Muted (${percent}%)`;
                valueLabel.dataset.state = "muted";
            }
            else {
                valueLabel.textContent = `${percent}%`;
                valueLabel.dataset.state = "enabled";
            }
        }
        if (intensitySlider) {
            const nextIntensityValue = this.audioIntensity.toFixed(2);
            if (intensitySlider.value !== nextIntensityValue) {
                intensitySlider.value = nextIntensityValue;
            }
            intensitySlider.disabled = muted;
            intensitySlider.setAttribute("aria-disabled", muted ? "true" : "false");
            intensitySlider.setAttribute("aria-valuenow", nextIntensityValue);
            intensitySlider.setAttribute("aria-valuetext", muted ? `Muted (${intensityPercent}%)` : `${intensityPercent}%`);
        }
        if (intensityValueLabel) {
            if (muted) {
                intensityValueLabel.textContent = `Muted (${intensityPercent}%)`;
                intensityValueLabel.dataset.state = "muted";
            }
            else {
                intensityValueLabel.textContent = `${intensityPercent}%`;
                intensityValueLabel.dataset.state = "enabled";
            }
        }
    }
    toggleSound() {
        this.setSoundEnabled(!this.soundEnabled);
    }
    openOptionsOverlay() {
        if (this.typingDrillsOverlayActive) {
            return;
        }
        if (this.optionsOverlayActive || this.menuActive || this.waveScorecardActive) {
            return;
        }
        this.soundManager?.playUi?.("ui-open");
        this.updateOptionsOverlayState();
        this.hud.showOptionsOverlay();
        if (!this.hud.isOptionsOverlayVisible()) {
            this.resumeAfterOptions = false;
            return;
        }
        this.optionsOverlayActive = true;
        if (this.manualTick) {
            this.resumeAfterOptions = false;
            return;
        }
        if (this.running) {
            this.pause();
            this.resumeAfterOptions = true;
        }
        else {
            this.resumeAfterOptions = false;
        }
    }
    closeOptionsOverlay(options = {}) {
        if (!this.optionsOverlayActive) {
            return;
        }
        this.optionsOverlayActive = false;
        this.soundManager?.playUi?.("ui-back");
        this.hud.hideOptionsOverlay();
        const shouldResume = options.resume !== false &&
            this.resumeAfterOptions &&
            !this.manualTick &&
            !this.menuActive &&
            !this.tutorialHoldLoop &&
            !this.waveScorecardActive;
        this.resumeAfterOptions = false;
        if (shouldResume) {
            this.resume();
        }
    }
    openTypingDrills(source = "cta", options) {
        if (!this.typingDrills)
            return;
        if (this.isScreenTimeLockoutActive()) {
            this.handleScreenTimeLockoutAttempt("typing-drills");
            return;
        }
        this.syncTypingDrillUnlocksToOverlay();
        this.syncErrorClustersToOverlay();
        if (this.typingDrillsOverlayActive && this.typingDrills.isVisible()) {
            this.typingDrills.reset(options?.mode);
            return;
        }
        const fromOptions = this.optionsOverlayActive;
        if (fromOptions) {
            this.closeOptionsOverlay({ resume: false });
            this.reopenOptionsAfterDrills = true;
        }
        else {
            this.reopenOptionsAfterDrills = false;
        }
        const wasRunning = this.running && !this.manualTick;
        if (wasRunning) {
            this.pause();
        }
        const recommendation = options?.mode && options?.reason
            ? { mode: options.mode, reason: options.reason }
            : this.buildTypingDrillRecommendation();
        this.setTypingDrillCtaRecommendation(recommendation);
        this.setTypingDrillMenuRecommendation(recommendation);
        if (recommendation) {
            this.typingDrills.setRecommendation(recommendation.mode, recommendation.reason);
        }
        else {
            this.typingDrills.showNoRecommendation("No recommendation available.", options?.autoStart && options.mode ? options.mode : null);
        }
        this.shouldResumeAfterDrills =
            wasRunning && !this.menuActive && !this.waveScorecardActive && !fromOptions;
        this.typingDrillsOverlayActive = true;
        this.typingDrills.open(options?.mode, source, options?.toastMessage);
        if (options?.autoStart && options.mode) {
            this.typingDrills.start(options.mode);
        }
    }
    closeTypingDrills() {
        if (!this.typingDrillsOverlayActive || !this.typingDrills) {
            return;
        }
        this.typingDrills.close();
    }
    handleTypingDrillsClosed() {
        this.typingDrillsOverlayActive = false;
        if (this.isScreenTimeLockoutActive()) {
            this.reopenOptionsAfterDrills = false;
            this.reopenWaveScorecardAfterDrills = false;
            this.shouldResumeAfterDrills = false;
            this.openOptionsOverlay();
            this.resumeAfterOptions = false;
            return;
        }
        const shouldReopenOptions = this.reopenOptionsAfterDrills;
        this.reopenOptionsAfterDrills = false;
        if (shouldReopenOptions) {
            this.openOptionsOverlay();
            this.resumeAfterOptions = false;
            return;
        }
        const shouldReopenWaveScorecard = this.reopenWaveScorecardAfterDrills;
        this.reopenWaveScorecardAfterDrills = false;
        if (shouldReopenWaveScorecard && this.waveScorecardActive && this.lastWaveScorecardData) {
            this.hud.showWaveScorecard(this.lastWaveScorecardData);
            return;
        }
        const shouldResume = this.shouldResumeAfterDrills &&
            !this.menuActive &&
            !this.waveScorecardActive &&
            !this.optionsOverlayActive &&
            !this.manualTick;
        this.shouldResumeAfterDrills = false;
        if (shouldResume) {
            this.resume();
        }
        else if (!this.menuActive) {
            this.hud.focusTypingInput();
        }
    }
    recordTypingDrillSummary(summary) {
        try {
            const { patterns, ...entrySummary } = summary;
            const storage = typeof window !== "undefined" ? window.localStorage : null;
            if (patterns && storage) {
                this.spacedRepetition = recordSpacedRepetitionObservedStats(this.spacedRepetition ?? readSpacedRepetitionState(storage), patterns, { nowMs: Date.now() });
                this.spacedRepetition = writeSpacedRepetitionState(storage, this.spacedRepetition);
                this.syncErrorClustersToOverlay();
            }
            if (summary.mode === "focus" ||
                summary.mode === "warmup" ||
                summary.mode === "reaction" ||
                summary.mode === "combo" ||
                summary.mode === "reading") {
                const drillLabel = this.getTypingDrillModeLabel(summary.mode);
                const percent = Math.round(Math.max(0, Math.min(100, (summary.accuracy ?? 0) * 100)));
                const metricLabel = summary.mode === "reading" ? "score" : "acc";
                let detail = `${summary.words} words`;
                if (summary.mode === "reaction") {
                    detail = `${summary.words} hits`;
                }
                else if (summary.mode === "reading") {
                    const attempted = summary.words + summary.errors;
                    detail = attempted > 0 ? `${summary.words}/${attempted} correct` : "0 answered";
                }
                this.hud.appendLog(`Practice (${drillLabel}) ${percent}% ${metricLabel}, ${detail}, best combo x${summary.bestCombo}`);
                if (this.shouldResumeAfterDrills &&
                    (summary.mode === "warmup" || summary.mode === "focus" || summary.mode === "combo") &&
                    typeof this.engine.recoverCombo === "function") {
                    const bestCombo = typeof summary.bestCombo === "number" && Number.isFinite(summary.bestCombo)
                        ? Math.max(0, summary.bestCombo)
                        : 0;
                    const accuracy = typeof summary.accuracy === "number" && Number.isFinite(summary.accuracy)
                        ? Math.max(0, Math.min(1, summary.accuracy))
                        : 0;
                    const carryover = Math.min(12, Math.floor(bestCombo * 0.4));
                    const currentCombo = Math.max(0, Math.floor(this.currentState?.typing?.combo ?? 0));
                    if (carryover > currentCombo && accuracy >= 0.85) {
                        this.engine.recoverCombo(carryover);
                        this.hud.appendLog(`Practice boost: combo seeded to x${carryover}.`);
                        this.currentState = this.engine.getState();
                        this.render();
                    }
                }
                this.syncTypingDrillUnlocksToOverlay();
                this.setTypingDrillCtaRecommendation(this.buildTypingDrillRecommendation());
                return;
            }
            const entry = this.engine.recordTypingDrill(entrySummary);
            const drillLabel = this.getTypingDrillModeLabel(entry.mode);
            const percent = Math.round(Math.max(0, Math.min(100, entry.accuracy * 100)));
            this.hud.appendLog(`Drill (${drillLabel}) ${percent}% acc, ${entry.words} words, best combo x${entry.bestCombo}`);
            this.trackTypingDrillCompleted(entry);
            this.handleLessonCompletion(entry);
            this.syncTypingDrillUnlocksToOverlay();
            this.setTypingDrillCtaRecommendation(this.buildTypingDrillRecommendation());
        }
        catch (error) {
            console.warn("[analytics] failed to record typing drill", error);
        }
    }
    isAdvancedSymbolsUnlocked() {
        if (!this.lessonMedalProgress)
            return false;
        const viewState = buildLessonMedalViewState(this.lessonMedalProgress);
        const symbolsBest = viewState.bestByMode?.symbols ?? null;
        if (!symbolsBest)
            return false;
        return (symbolsBest.tier === "silver" || symbolsBest.tier === "gold" || symbolsBest.tier === "platinum");
    }
    syncTypingDrillUnlocksToOverlay() {
        if (!this.typingDrills)
            return;
        this.typingDrills.setAdvancedSymbolsUnlocked(this.isAdvancedSymbolsUnlocked());
    }
    syncErrorClustersToOverlay() {
        if (!this.typingDrills)
            return;
        const storage = typeof window !== "undefined" ? window.localStorage : null;
        this.errorClusterProgress =
            this.errorClusterProgress ?? readErrorClusterProgress(storage);
        const nowMs = Date.now();
        this.spacedRepetition =
            this.spacedRepetition ?? readSpacedRepetitionState(storage);
        const duePatterns = listDueSpacedRepetitionPatterns(this.spacedRepetition, {
            nowMs: nowMs + 1000 * 60 * 15,
            limit: 4
        });
        const focusKeys = getTopExpectedKeys(this.errorClusterProgress, {
            nowMs,
            windowMs: 1000 * 60 * 10,
            limit: 3
        }).map((entry) => entry.key);
        const warmupKeys = getTopExpectedKeys(this.errorClusterProgress, {
            nowMs,
            windowMs: 1000 * 60 * 60 * 24,
            limit: 3
        }).map((entry) => entry.key);
        const merge = (primary, secondary) => {
            const seen = new Set();
            const merged = [];
            for (const value of [...primary, ...secondary]) {
                if (typeof value !== "string")
                    continue;
                const normalized = value.trim().toLowerCase();
                if (!normalized)
                    continue;
                if (seen.has(normalized))
                    continue;
                seen.add(normalized);
                merged.push(normalized);
                if (merged.length >= 3)
                    break;
            }
            return merged;
        };
        this.typingDrills.setFocusKeys(merge(duePatterns, focusKeys));
        this.typingDrills.setWarmupKeys(merge(duePatterns, warmupKeys));
    }
    handleTypingDrillStarted(mode, source) {
        if (!this.telemetryClient?.track)
            return;
        try {
            this.telemetryClient.track("typing-drill.started", {
                mode,
                source: source ?? "cta",
                timestamp: Date.now(),
                telemetryEnabled: Boolean(this.telemetryEnabled),
                menu: this.menuActive,
                optionsOverlay: this.optionsOverlayActive,
                waveScorecard: this.waveScorecardActive
            });
        }
        catch (error) {
            console.warn("[telemetry] failed to track typing drill start", error);
        }
    }
    trackTypingDrillCompleted(entry) {
        if (!this.telemetryClient?.track)
            return;
        try {
            this.telemetryClient.track("typing-drill.completed", {
                mode: entry.mode,
                source: entry.source,
                elapsedMs: entry.elapsedMs,
                accuracy: entry.accuracy,
                bestCombo: entry.bestCombo,
                words: entry.words,
                errors: entry.errors,
                wpm: entry.wpm,
                timestamp: entry.timestamp ?? Date.now(),
                telemetryEnabled: Boolean(this.telemetryEnabled)
            });
        }
        catch (error) {
            console.warn("[telemetry] failed to track typing drill completion", error);
        }
    }
    getTypingDrillModeLabel(mode) {
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
            case "burst":
            default:
                return "Burst Warmup";
        }
    }
    setTypingDrillCtaRecommendation(recommendation) {
        const container = this.typingDrillCta instanceof HTMLElement ? this.typingDrillCta : null;
        if (!container) {
            this.typingDrillCtaLastRecommendation = recommendation ? { ...recommendation } : null;
            return;
        }
        const labelEl = this.typingDrillCtaMode instanceof HTMLElement
            ? this.typingDrillCtaMode
            : container.querySelector?.(".typing-drills-cta-reco-mode");
        if (!recommendation) {
            container.dataset.visible = "false";
            container.setAttribute("aria-hidden", "true");
            container.removeAttribute("aria-label");
            container.removeAttribute("title");
            if (labelEl) {
                labelEl.textContent = "";
            }
            this.typingDrillCtaLastRecommendation = null;
            return;
        }
        const normalized = {
            mode: recommendation.mode,
            reason: recommendation.reason ?? ""
        };
        const unchanged = this.typingDrillCtaLastRecommendation?.mode === normalized.mode &&
            this.typingDrillCtaLastRecommendation?.reason === normalized.reason &&
            container.dataset.visible === "true";
        if (unchanged) {
            return;
        }
        const label = this.getTypingDrillModeLabel(recommendation.mode);
        if (labelEl) {
            labelEl.textContent = label;
        }
        container.dataset.visible = "true";
        container.setAttribute("aria-hidden", "false");
        container.setAttribute("aria-label", `Recommended drill: ${label}`);
        if (normalized.reason) {
            container.setAttribute("title", normalized.reason);
        }
        else {
            container.removeAttribute("title");
        }
        this.typingDrillCtaLastRecommendation = normalized;
    }
    setTypingDrillMenuRecommendation(recommendation) {
        const container = this.typingDrillMenuReco instanceof HTMLElement ? this.typingDrillMenuReco : null;
        const runButton = this.typingDrillMenuRunButton instanceof HTMLButtonElement
            ? this.typingDrillMenuRunButton
            : null;
        if (!container) {
            this.typingDrillMenuRecoLastRecommendation = recommendation ? { ...recommendation } : null;
            if (runButton) {
                runButton.disabled = !recommendation;
                runButton.setAttribute("aria-disabled", runButton.disabled ? "true" : "false");
            }
            return;
        }
        const labelEl = this.typingDrillMenuRecoMode instanceof HTMLElement
            ? this.typingDrillMenuRecoMode
            : container.querySelector?.(".main-menu-typing-drill-reco-mode");
        if (!recommendation) {
            const fallbackText = "You're in the groove - pick any drill.";
            container.dataset.visible = "true";
            container.setAttribute("aria-hidden", "false");
            container.setAttribute("aria-label", fallbackText);
            if (labelEl) {
                labelEl.textContent = fallbackText;
            }
            if (runButton) {
                runButton.disabled = false;
                runButton.setAttribute("aria-disabled", "false");
                runButton.textContent = "Run Burst Warmup";
                runButton.setAttribute("aria-label", "Run Burst Warmup (fallback)");
            }
            this.typingDrillMenuRecoLastRecommendation = null;
            return;
        }
        const normalized = {
            mode: recommendation.mode,
            reason: recommendation.reason ?? ""
        };
        const unchanged = this.typingDrillMenuRecoLastRecommendation?.mode === normalized.mode &&
            this.typingDrillMenuRecoLastRecommendation?.reason === normalized.reason &&
            container.dataset.visible === "true";
        if (unchanged) {
            if (runButton) {
                runButton.disabled = false;
                runButton.setAttribute("aria-disabled", "false");
                runButton.setAttribute("aria-label", `Run recommended drill: ${labelEl?.textContent ?? label}`);
            }
            return;
        }
        const label = this.getTypingDrillModeLabel(recommendation.mode);
        if (labelEl) {
            labelEl.textContent = label;
        }
        container.dataset.visible = "true";
        container.setAttribute("aria-hidden", "false");
        container.setAttribute("aria-label", `Recommended drill: ${label}`);
        if (runButton) {
            runButton.disabled = false;
            runButton.setAttribute("aria-disabled", "false");
            runButton.textContent = "Run Recommended Drill";
            runButton.setAttribute("aria-label", `Run recommended drill: ${label}`);
        }
        this.typingDrillMenuRecoLastRecommendation = normalized;
    }
    trackMenuDrillQuickstart(recommendation, hadRecommendation) {
        if (!this.telemetryClient?.track)
            return;
        try {
            this.telemetryClient.track("ui.typingDrill.menuQuickstart", {
                mode: recommendation.mode,
                hadRecommendation,
                reason: recommendation.reason ?? null,
                timestamp: Date.now()
            });
        }
        catch (error) {
            console.warn("[telemetry] failed to track menu drill quickstart", error);
        }
    }
    buildTypingDrillRecommendation(state = this.engine.getState()) {
        if (!state) {
            return null;
        }
        const accuracy = typeof state.typing?.accuracy === "number" ? state.typing.accuracy : 1;
        const combo = typeof state.typing?.combo === "number" ? state.typing.combo : 0;
        const warnings = state.analytics?.comboWarning?.count ?? 0;
        const lastDrill = state.analytics?.typingDrills?.at?.(-1) ?? null;
        const nowMs = Date.now();
        const storage = typeof window !== "undefined" ? window.localStorage : null;
        this.errorClusterProgress =
            this.errorClusterProgress ?? readErrorClusterProgress(storage);
        this.spacedRepetition =
            this.spacedRepetition ?? readSpacedRepetitionState(storage);
        const duePatterns = listDueSpacedRepetitionPatterns(this.spacedRepetition, {
            nowMs: nowMs + 1000 * 60 * 15,
            limit: 3
        });
        const focusWindowMs = 1000 * 60 * 8;
        const focusCutoff = nowMs - focusWindowMs;
        const recentErrorCount = (this.errorClusterProgress.history ?? []).filter((entry) => (entry?.timestamp ?? 0) >= focusCutoff).length;
        const focusKeys = getTopExpectedKeys(this.errorClusterProgress, {
            nowMs,
            windowMs: focusWindowMs,
            limit: 3
        });
        if (accuracy < 0.9 || warnings > 1) {
            return { mode: "precision", reason: "Tighten accuracy after recent drops." };
        }
        if (duePatterns.length >= 3) {
            const label = duePatterns.map((pattern) => pattern.toUpperCase()).join(", ");
            return { mode: "warmup", reason: `Spaced repetition: ${label} are due. Run a warm-up plan.` };
        }
        if (recentErrorCount >= 6 && (focusKeys[0]?.count ?? 0) >= 3) {
            const keyLabel = focusKeys.map((entry) => entry.key.toUpperCase()).join(", ");
            return { mode: "focus", reason: `Micro-drill your trouble keys: ${keyLabel}.` };
        }
        if (duePatterns.length > 0) {
            const label = duePatterns.map((pattern) => pattern.toUpperCase()).join(", ");
            return { mode: "focus", reason: `Spaced repetition: review ${label}.` };
        }
        if (combo >= 6 && accuracy >= 0.97) {
            return { mode: "endurance", reason: "Hold cadence and combo for longer strings." };
        }
        if (lastDrill?.mode === "precision" && lastDrill.accuracy >= 0.97) {
            return { mode: "burst", reason: "Reset rhythm with a quick burst between waves." };
        }
        return { mode: "burst", reason: "Warm up with five quick clears before rejoining." };
    }
    buildWaveCoachSummary(scorecard) {
        const accuracyRaw = typeof scorecard?.accuracy === "number" ? scorecard.accuracy : 0;
        const accuracyPct = Math.max(0, Math.min(100, Math.round(accuracyRaw * 1000) / 10));
        const breaches = Math.max(0, Math.floor(scorecard?.breaches ?? 0));
        const bestCombo = Math.max(0, Math.floor(scorecard?.bestCombo ?? 0));
        const perfectWords = Math.max(0, Math.floor(scorecard?.perfectWords ?? 0));
        const enemiesDefeated = Math.max(0, Math.floor(scorecard?.enemiesDefeated ?? 0));
        const averageReaction = typeof scorecard?.averageReaction === "number" ? scorecard.averageReaction : 0;
        let win = "Steady wave. Keep going.";
        if (breaches === 0) {
            win = "Zero breaches. You held the wall.";
        }
        else if (accuracyPct >= 97) {
            win = `${accuracyPct.toFixed(1)}% accuracy. Super clean typing.`;
        }
        else if (bestCombo >= 10) {
            win = `Wave combo hit x${bestCombo}.`;
        }
        else if (perfectWords >= 6) {
            win = `${perfectWords} perfect words.`;
        }
        else if (enemiesDefeated >= 20) {
            win = `${enemiesDefeated} enemies defeated.`;
        }
        let gap = "Aim for fewer mistakes next wave.";
        if (breaches > 0) {
            gap = `${breaches} breach${breaches === 1 ? "" : "es"}. Try typing the closest enemy first.`;
        }
        else if (accuracyPct < 93) {
            gap = `${accuracyPct.toFixed(1)}% accuracy. Slow down for clean hits.`;
        }
        else if (averageReaction > 1.6) {
            gap = `Avg reaction ${averageReaction.toFixed(2)}s. Lock in the first letter sooner.`;
        }
        else if (bestCombo < 6) {
            gap = "Push your combo past x6 without mistakes.";
        }
        const recommendation = this.buildTypingDrillRecommendation();
        const drill = recommendation
            ? {
                mode: recommendation.mode,
                label: this.getTypingDrillModeLabel(recommendation.mode),
                reason: recommendation.reason
            }
            : null;
        return {
            win,
            gap,
            drill
        };
    }
    presentWaveScorecard(summary, options = {}) {
        if (this.menuActive)
            return;
        if (this.tutorialManager?.getState().active)
            return;
        if (this.waveScorecardActive)
            return;
        if (this.optionsOverlayActive) {
            this.closeOptionsOverlay({ resume: false });
        }
        const totalWaves = Array.isArray(this.engine.config?.waves)
            ? this.engine.config.waves.length
            : 0;
        const tipOverride = typeof options?.tipOverride === "string" && options.tipOverride.trim().length > 0
            ? options.tipOverride.trim()
            : null;
        const data = {
            waveIndex: summary.index ?? 0,
            waveTotal: totalWaves,
            mode: summary.mode ?? this.engine.getMode(),
            accuracy: summary.accuracy ?? 0,
            enemiesDefeated: summary.enemiesDefeated ?? 0,
            breaches: summary.breaches ?? 0,
            perfectWords: summary.perfectWords ?? 0,
            averageReaction: summary.averageReaction ?? 0,
            dps: summary.dps ?? 0,
            turretDps: summary.turretDps ?? 0,
            typingDps: summary.typingDps ?? 0,
            turretDamage: summary.turretDamage ?? 0,
            typingDamage: summary.typingDamage ?? 0,
            shieldBreaks: summary.shieldBreaks ?? 0,
            repairsUsed: summary.repairsUsed ?? 0,
            repairHealth: summary.repairHealth ?? 0,
            repairGold: summary.repairGold ?? 0,
            goldEarned: summary.goldEarned ?? 0,
            bonusGold: summary.bonusGold ?? 0,
            castleBonusGold: summary.castleBonusGold ?? 0,
            bestCombo: summary.maxCombo ?? 0,
            sessionBestCombo: summary.sessionBestCombo ?? this.bestCombo,
            microTip: tipOverride ?? this.getNextWaveMicroTip()
        };
        data.coach = this.buildWaveCoachSummary(data);
        this.lastWaveScorecardData = data;
        this.hud.showWaveScorecard(data);
        this.waveScorecardActive = true;
        if (this.manualTick) {
            this.resumeAfterWaveScorecard = false;
            return;
        }
        this.resumeAfterWaveScorecard = this.running;
        if (this.running) {
            this.pause();
        }
    }
    debugShowWaveScorecard(summary = {}) {
        const state = this.engine.getState();
        const defaultSummary = state.analytics?.waveSummaries?.at(-1) ??
            state.analytics?.waveHistory?.at(-1) ?? {
            index: state.wave?.index ?? 0,
            mode: state.mode ?? "campaign",
            accuracy: state.typing?.accuracy ?? 0,
            enemiesDefeated: 0,
            breaches: state.analytics?.sessionBreaches ?? 0,
            perfectWords: 0,
            averageReaction: 0,
            dps: 0,
            turretDps: 0,
            typingDps: 0,
            turretDamage: 0,
            typingDamage: 0,
            shieldBreaks: 0,
            repairsUsed: 0,
            repairHealth: 0,
            repairGold: 0,
            goldEarned: state.resources?.gold ?? 0,
            bonusGold: 0,
            castleBonusGold: 0,
            maxCombo: this.bestCombo,
            sessionBestCombo: this.bestCombo
        };
        const payload = {
            waveIndex: summary.waveIndex ?? summary.index ?? defaultSummary.index ?? 0,
            waveTotal: Array.isArray(this.engine.config?.waves)
                ? this.engine.config.waves.length
                : 0,
            mode: summary.mode ?? defaultSummary.mode ?? this.engine.getMode(),
            accuracy: summary.accuracy ?? defaultSummary.accuracy ?? 0,
            enemiesDefeated: summary.enemiesDefeated ?? defaultSummary.enemiesDefeated ?? 0,
            breaches: summary.breaches ?? defaultSummary.breaches ?? 0,
            perfectWords: summary.perfectWords ?? defaultSummary.perfectWords ?? 0,
            averageReaction: summary.averageReaction ?? defaultSummary.averageReaction ?? 0,
            dps: summary.dps ?? defaultSummary.dps ?? 0,
            turretDps: summary.turretDps ?? defaultSummary.turretDps ?? 0,
            typingDps: summary.typingDps ?? defaultSummary.typingDps ?? 0,
            turretDamage: summary.turretDamage ?? defaultSummary.turretDamage ?? 0,
            typingDamage: summary.typingDamage ?? defaultSummary.typingDamage ?? 0,
            shieldBreaks: summary.shieldBreaks ?? defaultSummary.shieldBreaks ?? 0,
            repairsUsed: summary.repairsUsed ?? defaultSummary.repairsUsed ?? 0,
            repairHealth: summary.repairHealth ?? defaultSummary.repairHealth ?? 0,
            repairGold: summary.repairGold ?? defaultSummary.repairGold ?? 0,
            goldEarned: summary.goldEarned ?? defaultSummary.goldEarned ?? 0,
            bonusGold: summary.bonusGold ?? defaultSummary.bonusGold ?? 0,
            castleBonusGold: summary.castleBonusGold ?? defaultSummary.castleBonusGold ?? 0,
            bestCombo: summary.bestCombo ?? summary.maxCombo ?? defaultSummary.maxCombo ?? 0,
            sessionBestCombo: summary.sessionBestCombo ?? defaultSummary.sessionBestCombo ?? this.bestCombo,
            microTip: this.getNextWaveMicroTip()
        };
        const scorecardData = {
            waveIndex: payload.waveIndex ?? 0,
            waveTotal: payload.waveTotal ?? 0,
            mode: payload.mode ?? this.engine.getMode(),
            accuracy: payload.accuracy ?? 0,
            enemiesDefeated: payload.enemiesDefeated ?? 0,
            breaches: payload.breaches ?? 0,
            perfectWords: payload.perfectWords ?? 0,
            averageReaction: payload.averageReaction ?? 0,
            dps: payload.dps ?? 0,
            turretDps: payload.turretDps ?? 0,
            typingDps: payload.typingDps ?? 0,
            turretDamage: payload.turretDamage ?? 0,
            typingDamage: payload.typingDamage ?? 0,
            shieldBreaks: payload.shieldBreaks ?? 0,
            repairsUsed: payload.repairsUsed ?? 0,
            repairHealth: payload.repairHealth ?? 0,
            repairGold: payload.repairGold ?? 0,
            goldEarned: payload.goldEarned ?? 0,
            bonusGold: payload.bonusGold ?? 0,
            castleBonusGold: payload.castleBonusGold ?? 0,
            bestCombo: payload.bestCombo ?? 0,
            sessionBestCombo: payload.sessionBestCombo ?? this.bestCombo,
            microTip: payload.microTip ?? null
        };
        scorecardData.coach = this.buildWaveCoachSummary(scorecardData);
        this.lastWaveScorecardData = scorecardData;
        this.hud.showWaveScorecard(scorecardData);
    }
    debugHideWaveScorecard() {
        this.hud.hideWaveScorecard();
    }
    handleWaveScorecardSuggestedDrill(drill) {
        if (!drill || !drill.mode || !this.typingDrills) {
            return;
        }
        if (this.isScreenTimeLockoutActive()) {
            this.handleScreenTimeLockoutAttempt("typing-drills");
            return;
        }
        this.reopenWaveScorecardAfterDrills = true;
        this.hud.hideWaveScorecard();
        this.openTypingDrills("wave-scorecard", {
            mode: drill.mode,
            autoStart: true,
            reason: drill.reason,
            toastMessage: `Coach drill: ${drill.label}`
        });
    }
    handleWaveScorecardContinue() {
        this.closeWaveScorecard({ resume: true });
    }
    closeWaveScorecard(options = {}) {
        if (!this.waveScorecardActive) {
            this.resumeAfterWaveScorecard = false;
            return;
        }
        this.waveScorecardActive = false;
        this.reopenWaveScorecardAfterDrills = false;
        this.lastWaveScorecardData = null;
        this.hud.hideWaveScorecard();
        const shouldResume = options.resume !== false &&
            this.resumeAfterWaveScorecard &&
            !this.manualTick &&
            !this.menuActive &&
            !this.optionsOverlayActive &&
            !this.tutorialHoldLoop;
        this.resumeAfterWaveScorecard = false;
        if (this.weeklyTrialReturnPending) {
            this.completeWeeklyTrialReturn();
            return;
        }
        if (shouldResume) {
            this.resume();
        }
    }
    persistPlayerSettings(patch) {
        const soundUnchanged = patch.soundEnabled === undefined || patch.soundEnabled === this.playerSettings.soundEnabled;
        const musicEnabledUnchanged = patch.musicEnabled === undefined || patch.musicEnabled === this.playerSettings.musicEnabled;
        const musicLevelUnchanged = patch.musicLevel === undefined ||
            Math.abs(this.normalizeMusicLevel(patch.musicLevel) - this.playerSettings.musicLevel) <=
                0.001;
        const soundVolumeUnchanged = patch.soundVolume === undefined ||
            Math.abs(this.normalizeSoundVolume(patch.soundVolume) - this.playerSettings.soundVolume) <=
                0.001;
        const latencySparklineUnchanged = patch.latencySparklineEnabled === undefined ||
            patch.latencySparklineEnabled === this.playerSettings.latencySparklineEnabled;
        const soundIntensityUnchanged = patch.audioIntensity === undefined ||
            Math.abs(this.normalizeAudioIntensity(patch.audioIntensity) - this.playerSettings.audioIntensity) <= 0.001;
        const screenShakeEnabledUnchanged = patch.screenShakeEnabled === undefined ||
            patch.screenShakeEnabled === this.playerSettings.screenShakeEnabled;
        const screenShakeIntensityUnchanged = patch.screenShakeIntensity === undefined ||
            Math.abs(this.normalizeScreenShakeIntensity(patch.screenShakeIntensity) -
                this.playerSettings.screenShakeIntensity) <= 0.001;
        const diagnosticsUnchanged = patch.diagnosticsVisible === undefined ||
            patch.diagnosticsVisible === this.playerSettings.diagnosticsVisible;
        const reducedMotionUnchanged = patch.reducedMotionEnabled === undefined ||
            patch.reducedMotionEnabled === this.playerSettings.reducedMotionEnabled;
        const virtualKeyboardUnchanged = patch.virtualKeyboardEnabled === undefined ||
            patch.virtualKeyboardEnabled === this.playerSettings.virtualKeyboardEnabled;
        const virtualKeyboardLayoutUnchanged = patch.virtualKeyboardLayout === undefined ||
            this.normalizeVirtualKeyboardLayout(patch.virtualKeyboardLayout) ===
                this.normalizeVirtualKeyboardLayout(this.playerSettings.virtualKeyboardLayout ?? DEFAULT_VIRTUAL_KEYBOARD_LAYOUT);
        const lowGraphicsUnchanged = patch.lowGraphicsEnabled === undefined ||
            patch.lowGraphicsEnabled === this.playerSettings.lowGraphicsEnabled;
        const checkeredUnchanged = patch.checkeredBackgroundEnabled === undefined ||
            patch.checkeredBackgroundEnabled === this.playerSettings.checkeredBackgroundEnabled;
        const readableFontUnchanged = patch.readableFontEnabled === undefined ||
            patch.readableFontEnabled === this.playerSettings.readableFontEnabled;
        const dyslexiaFontUnchanged = patch.dyslexiaFontEnabled === undefined ||
            patch.dyslexiaFontEnabled === this.playerSettings.dyslexiaFontEnabled;
        const cognitiveLoadUnchanged = patch.reducedCognitiveLoadEnabled === undefined ||
            patch.reducedCognitiveLoadEnabled === this.playerSettings.reducedCognitiveLoadEnabled;
        const colorblindUnchanged = patch.colorblindPaletteEnabled === undefined ||
            patch.colorblindPaletteEnabled === this.playerSettings.colorblindPaletteEnabled;
        const previousFocusOutline = this.playerSettings.focusOutlinePreset ?? FOCUS_OUTLINE_DEFAULT;
        const focusOutlineUnchanged = patch.focusOutlinePreset === undefined ||
            normalizeFocusOutlinePreset(patch.focusOutlinePreset) ===
                normalizeFocusOutlinePreset(previousFocusOutline);
        const audioNarrationUnchanged = patch.audioNarrationEnabled === undefined ||
            patch.audioNarrationEnabled === this.audioNarrationEnabled;
        const voicePackUnchanged = patch.voicePackId === undefined || this.normalizeVoicePack(patch.voicePackId) === this.voicePackId;
        const accessibilityPresetUnchanged = patch.accessibilityPresetEnabled === undefined ||
            patch.accessibilityPresetEnabled === this.accessibilityPresetEnabled;
        const tutorialPacingUnchanged = patch.tutorialPacing === undefined ||
            Math.abs(this.normalizeTutorialPacing(patch.tutorialPacing) -
                this.normalizeTutorialPacing(this.playerSettings.tutorialPacing ?? 1)) <= 0.001;
        const largeSubtitlesUnchanged = patch.largeSubtitlesEnabled === undefined ||
            patch.largeSubtitlesEnabled === this.largeSubtitlesEnabled;
        const textSizeUnchanged = patch.textSizeScale === undefined ||
            Math.abs(this.normalizeTextSizeScale(patch.textSizeScale) - this.playerSettings.textSizeScale) <=
                0.001;
        const hapticsUnchanged = patch.hapticsEnabled === undefined ||
            patch.hapticsEnabled === this.playerSettings.hapticsEnabled;
        const defeatAnimationModeUnchanged = patch.defeatAnimationMode === undefined ||
            patch.defeatAnimationMode === this.playerSettings.defeatAnimationMode;
        const hudZoomUnchanged = patch.hudZoom === undefined ||
            Math.abs(this.normalizeHudZoom(patch.hudZoom) - (this.playerSettings.hudZoom ?? HUD_ZOOM_DEFAULT)) <=
                0.001;
        const castleSkinUnchanged = patch.castleSkin === undefined ||
            this.normalizeCastleSkin(patch.castleSkin) ===
                this.normalizeCastleSkin(this.playerSettings.castleSkin ?? "classic");
        const fontScaleUnchanged = patch.hudFontScale === undefined ||
            Math.abs(this.normalizeHudFontScale(patch.hudFontScale) - this.playerSettings.hudFontScale) <=
                0.001;
        const hudLayoutUnchanged = patch.hudLayout === undefined || this.normalizeHudLayout(patch.hudLayout) === this.hudLayout;
        const targetingUnchanged = patch.turretTargeting === undefined ||
            this.areTargetingMapsEqual(this.playerSettings.turretTargeting, patch.turretTargeting);
        const presetsUnchanged = patch.turretLoadoutPresets === undefined ||
            this.areTurretPresetMapsEqual(this.playerSettings.turretLoadoutPresets, patch.turretLoadoutPresets);
        const telemetryUnchanged = patch.telemetryEnabled === undefined ||
            patch.telemetryEnabled === this.playerSettings.telemetryEnabled;
        const currentSelfTest = this.playerSettings.accessibilitySelfTest ?? ACCESSIBILITY_SELF_TEST_DEFAULT;
        const nextSelfTestSnapshot = patch.accessibilitySelfTest === undefined
            ? currentSelfTest
            : {
                ...currentSelfTest,
                ...patch.accessibilitySelfTest,
                lastRunAt: patch.accessibilitySelfTest.lastRunAt === undefined
                    ? currentSelfTest.lastRunAt
                    : patch.accessibilitySelfTest.lastRunAt
            };
        const selfTestUnchanged = this.areAccessibilitySelfTestsEqual(currentSelfTest, nextSelfTestSnapshot);
        const diagnosticsSectionsUnchanged = patch.diagnosticsSections === undefined ||
            this.areDiagnosticsSectionsEqual(this.playerSettings.diagnosticsSections, patch.diagnosticsSections);
        const diagnosticsSectionsUpdatedAtUnchanged = patch.diagnosticsSectionsUpdatedAt === undefined ||
            patch.diagnosticsSectionsUpdatedAt ===
                this.playerSettings.diagnosticsSectionsUpdatedAt;
        const dprPreferenceUnchanged = patch.lastDevicePixelRatio === undefined ||
            patch.lastDevicePixelRatio === this.playerSettings.lastDevicePixelRatio;
        const hudLayoutPreferenceUnchanged = patch.lastHudLayout === undefined || patch.lastHudLayout === this.playerSettings.lastHudLayout;
        if (soundUnchanged &&
            soundVolumeUnchanged &&
            musicEnabledUnchanged &&
            musicLevelUnchanged &&
            soundIntensityUnchanged &&
            diagnosticsUnchanged &&
            reducedMotionUnchanged &&
            checkeredUnchanged &&
            readableFontUnchanged &&
            dyslexiaFontUnchanged &&
            cognitiveLoadUnchanged &&
            colorblindUnchanged &&
            audioNarrationUnchanged &&
            voicePackUnchanged &&
            accessibilityPresetUnchanged &&
            tutorialPacingUnchanged &&
            largeSubtitlesUnchanged &&
            focusOutlineUnchanged &&
            textSizeUnchanged &&
            hapticsUnchanged &&
            screenShakeEnabledUnchanged &&
            screenShakeIntensityUnchanged &&
            latencySparklineUnchanged &&
            virtualKeyboardUnchanged &&
            virtualKeyboardLayoutUnchanged &&
            lowGraphicsUnchanged &&
            defeatAnimationModeUnchanged &&
            hudZoomUnchanged &&
            hudLayoutUnchanged &&
            castleSkinUnchanged &&
            fontScaleUnchanged &&
            targetingUnchanged &&
            presetsUnchanged &&
            telemetryUnchanged &&
            diagnosticsSectionsUnchanged &&
            diagnosticsSectionsUpdatedAtUnchanged &&
            selfTestUnchanged &&
            dprPreferenceUnchanged &&
            hudLayoutPreferenceUnchanged) {
            return;
        }
        const next = withPatchedPlayerSettings(this.playerSettings, patch);
        this.playerSettings = next;
        this.accessibilitySelfTest =
            next.accessibilitySelfTest ?? { ...ACCESSIBILITY_SELF_TEST_DEFAULT };
        if (patch.turretLoadoutPresets !== undefined) {
            this.turretLoadoutPresets = this.cloneTurretPresetMap(next.turretLoadoutPresets);
        }
        if (typeof window !== "undefined") {
            writePlayerSettings(window.localStorage, next);
        }
    }
    persistTurretTargetingPreference(slotId, priority) {
        const currentMap = this.playerSettings.turretTargeting ?? {};
        const nextMap = { ...currentMap };
        if (priority === "first") {
            delete nextMap[slotId];
        }
        else {
            nextMap[slotId] = priority;
        }
        this.persistPlayerSettings({ turretTargeting: nextMap });
    }
    areTargetingMapsEqual(current = {}, next = {}) {
        const currentKeys = Object.keys(current);
        const nextKeys = Object.keys(next);
        if (currentKeys.length !== nextKeys.length) {
            return false;
        }
        for (const key of currentKeys) {
            if (current[key] !== next[key]) {
                return false;
            }
        }
        return true;
    }
    areTurretPresetMapsEqual(current = {}, next = {}) {
        const currentKeys = Object.keys(current);
        const nextKeys = Object.keys(next);
        if (currentKeys.length !== nextKeys.length) {
            return false;
        }
        for (const key of currentKeys) {
            const currentPreset = current[key];
            const nextPreset = next[key];
            if (!currentPreset && !nextPreset)
                continue;
            if (!currentPreset || !nextPreset)
                return false;
            if (currentPreset.id !== nextPreset.id || currentPreset.savedAt !== nextPreset.savedAt) {
                return false;
            }
            if (!this.areTurretPresetSlotsEqual(currentPreset.slots, nextPreset.slots)) {
                return false;
            }
        }
        return true;
    }
    areTurretPresetSlotsEqual(currentSlots = {}, nextSlots = {}) {
        const currentKeys = Object.keys(currentSlots);
        const nextKeys = Object.keys(nextSlots);
        if (currentKeys.length !== nextKeys.length) {
            return false;
        }
        for (const key of currentKeys) {
            const currentSlot = currentSlots[key];
            const nextSlot = nextSlots[key];
            if (!currentSlot && !nextSlot)
                continue;
            if (!currentSlot || !nextSlot)
                return false;
            if (currentSlot.typeId !== nextSlot.typeId ||
                currentSlot.level !== nextSlot.level ||
                (currentSlot.priority ?? "first") !== (nextSlot.priority ?? "first")) {
                return false;
            }
        }
        return true;
    }
    areDiagnosticsSectionsEqual(current = {}, next = {}) {
        const ids = [
            "gold-events",
            "castle-passives",
            "turret-dps"
        ];
        for (const id of ids) {
            if ((current?.[id] ?? undefined) !== (next?.[id] ?? undefined)) {
                return false;
            }
        }
        return true;
    }
    areAccessibilitySelfTestsEqual(current, next) {
        const a = current ?? ACCESSIBILITY_SELF_TEST_DEFAULT;
        const b = next ?? ACCESSIBILITY_SELF_TEST_DEFAULT;
        return ((a.lastRunAt ?? null) === (b.lastRunAt ?? null) &&
            Boolean(a.soundConfirmed) === Boolean(b.soundConfirmed) &&
            Boolean(a.visualConfirmed) === Boolean(b.visualConfirmed) &&
            Boolean(a.motionConfirmed) === Boolean(b.motionConfirmed));
    }
    cloneTurretPresetMap(source = {}) {
        const clone = Object.create(null);
        for (const [key, preset] of Object.entries(source)) {
            if (!preset)
                continue;
            clone[key] = {
                id: preset.id,
                savedAt: preset.savedAt,
                slots: this.cloneTurretPresetSlots(preset.slots)
            };
        }
        return clone;
    }
    cloneTurretPresetSlots(slots = {}) {
        const clone = Object.create(null);
        for (const [slotId, slot] of Object.entries(slots)) {
            if (!slot)
                continue;
            clone[slotId] = {
                typeId: slot.typeId,
                level: slot.level,
                ...(slot.priority ? { priority: slot.priority } : {})
            };
        }
        return clone;
    }
    isValidPresetId(presetId) {
        return TURRET_PRESET_IDS.includes(presetId);
    }
    captureTurretBlueprintFromState(state) {
        const source = state ?? this.engine.getState();
        const blueprint = Object.create(null);
        for (const slot of source.turrets) {
            if (!slot.turret)
                continue;
            blueprint[slot.id] = {
                typeId: slot.turret.typeId,
                level: slot.turret.level,
                ...(slot.targetingPriority && slot.targetingPriority !== "first"
                    ? { priority: slot.targetingPriority }
                    : {})
            };
        }
        return blueprint;
    }
    syncTargetingPreferencesFromState(state) {
        const nextMap = Object.create(null);
        for (const slot of state.turrets) {
            const priority = slot.targetingPriority ?? "first";
            if (priority !== "first") {
                nextMap[slot.id] = priority;
            }
        }
        this.persistPlayerSettings({ turretTargeting: nextMap });
    }
    syncTurretPresetsToHud(state) {
        if (!this.hud)
            return;
        const sourceState = state ?? this.currentState ?? this.engine.getState();
        const viewModels = TURRET_PRESET_IDS.map((presetId) => this.buildTurretPresetViewModel(presetId, this.turretLoadoutPresets?.[presetId] ?? null, sourceState));
        this.hud.updateTurretPresets(viewModels);
    }
    buildTurretPresetViewModel(presetId, preset, state) {
        const label = this.formatPresetLabel(presetId);
        if (!preset) {
            return {
                id: presetId,
                label,
                hasPreset: false,
                active: false,
                applyCost: null,
                applyDisabled: true,
                applyMessage: `Save ${label} to enable quick swaps.`,
                savedAtLabel: "Not saved",
                statusLabel: "Save your current layout to this preset.",
                slots: []
            };
        }
        const blueprint = this.cloneTurretPresetSlots(preset.slots);
        const preview = this.engine.applyTurretBlueprint(blueprint, { preview: true });
        const active = this.isPresetMatch(preset, state);
        let applyDisabled = false;
        let applyMessage = preview.message ?? `Apply ${label}`;
        let applyCost = preview.success ? preview.cost : null;
        const savedAtLabel = this.formatPresetSavedAt(preset.savedAt);
        let statusLabel = null;
        const disabledTypes = Array.from(new Set(Object.values(blueprint)
            .filter((slotConfig) => slotConfig && !this.isTurretTypeEnabled(slotConfig.typeId))
            .map((slotConfig) => this.getTurretArchetypeLabel(slotConfig.typeId))));
        if (disabledTypes.length > 0) {
            applyDisabled = true;
            statusLabel = `${disabledTypes.join(", ")} disabled via feature toggle.`;
            applyMessage = `Enable ${disabledTypes.join(", ")} to apply ${label}.`;
            applyCost = preview.cost;
        }
        else if (!preview.success) {
            if (preview.reason === "insufficient-gold") {
                applyDisabled = false;
                const required = preview.requiredGold ?? preview.cost ?? 0;
                const available = preview.availableGold ?? state.resources.gold;
                statusLabel = `Requires ${required}g (have ${available}g)`;
                applyCost = preview.cost ?? required;
                applyMessage = preview.message ?? `Requires ${required}g`;
            }
            else {
                applyDisabled = true;
                statusLabel = preview.message ?? null;
            }
        }
        else if (preview.cost > 0) {
            applyMessage = `Apply ${label} (-${preview.cost}g)`;
            statusLabel = `Cost ${preview.cost}g`;
        }
        return {
            id: presetId,
            label,
            hasPreset: true,
            active,
            applyCost,
            applyDisabled,
            applyMessage,
            savedAtLabel,
            statusLabel,
            slots: this.buildPresetSlotsForView(preset.slots)
        };
    }
    buildPresetSlotsForView(slots = {}) {
        return Object.entries(slots)
            .map(([slotId, slot]) => ({
            slotId,
            typeId: slot.typeId,
            level: slot.level,
            priority: slot.priority ?? "first"
        }))
            .sort((a, b) => a.slotId.localeCompare(b.slotId, undefined, { numeric: true, sensitivity: "base" }));
    }
    formatPresetLabel(presetId) {
        const index = TURRET_PRESET_IDS.indexOf(presetId);
        if (index >= 0) {
            return `Preset ${String.fromCharCode(65 + index)}`;
        }
        return presetId;
    }
    formatPresetSavedAt(savedAt) {
        if (!savedAt) {
            return "Saved";
        }
        const date = new Date(savedAt);
        if (Number.isNaN(date.getTime())) {
            return "Saved";
        }
        try {
            const formatter = new Intl.DateTimeFormat(undefined, {
                hour: "2-digit",
                minute: "2-digit"
            });
            return `Saved ${formatter.format(date)}`;
        }
        catch {
            return `Saved ${date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
        }
    }
    isPresetMatch(preset, state) {
        if (!preset) {
            return false;
        }
        const slots = preset.slots ?? {};
        for (const slot of state.turrets) {
            const blueprintSlot = slots[slot.id];
            const turret = slot.turret;
            if (!turret && blueprintSlot) {
                return false;
            }
            if (turret && !blueprintSlot) {
                return false;
            }
            if (turret && blueprintSlot) {
                if (turret.typeId !== blueprintSlot.typeId || turret.level !== blueprintSlot.level) {
                    return false;
                }
                const desiredPriority = blueprintSlot.priority ?? "first";
                const actualPriority = slot.targetingPriority ?? "first";
                if (desiredPriority !== actualPriority) {
                    return false;
                }
            }
        }
        // Ensure preset does not contain slots absent from state (e.g., future unlocks).
        for (const slotId of Object.keys(slots)) {
            if (!state.turrets.find((entry) => entry.id === slotId)) {
                return false;
            }
        }
        return true;
    }
    computeTurretSignature(state) {
        if (!state) {
            return "";
        }
        return state.turrets
            .map((slot) => {
            const turret = slot.turret;
            const turretPart = turret ? `${turret.typeId}:${turret.level}` : "empty";
            const priority = slot.targetingPriority ?? "first";
            return `${slot.id}:${slot.unlocked ? "1" : "0"}:${turretPart}:${priority}`;
        })
            .join("|");
    }
    collectUiCondensedSnapshot() {
        const hudState = this.hud?.getCondensedState?.() ?? null;
        const diagnosticsState = this.diagnostics?.getCondensedState?.() ?? null;
        const diagnosticsSectionPrefs = this.playerSettings?.diagnosticsSections &&
            Object.keys(this.playerSettings.diagnosticsSections).length > 0
            ? { ...this.playerSettings.diagnosticsSections }
            : null;
        const diagnosticsSectionsUpdatedAt = this.playerSettings?.diagnosticsSectionsUpdatedAt ?? null;
        const storedDevicePixelRatio = typeof this.playerSettings?.lastDevicePixelRatio === "number"
            ? this.playerSettings.lastDevicePixelRatio
            : null;
        const storedHudLayout = this.playerSettings?.lastHudLayout === "stacked" ||
            this.playerSettings?.lastHudLayout === "condensed"
            ? this.playerSettings.lastHudLayout
            : null;
        const preferences = {
            hudPassivesCollapsed: typeof this.playerSettings?.hudPassivesCollapsed === "boolean"
                ? this.playerSettings.hudPassivesCollapsed
                : null,
            hudGoldEventsCollapsed: typeof this.playerSettings?.hudGoldEventsCollapsed === "boolean"
                ? this.playerSettings.hudGoldEventsCollapsed
                : null,
            optionsPassivesCollapsed: typeof this.playerSettings?.optionsPassivesCollapsed === "boolean"
                ? this.playerSettings.optionsPassivesCollapsed
                : null,
            diagnosticsSections: diagnosticsSectionPrefs,
            diagnosticsSectionsUpdatedAt,
            devicePixelRatio: storedDevicePixelRatio,
            hudLayout: storedHudLayout
        };
        const hudLayoutState = typeof hudState?.prefersCondensedLists === "boolean"
            ? hudState.prefersCondensedLists
                ? "condensed"
                : "stacked"
            : null;
        const resolutionSnapshot = this.canvasResolution
            ? {
                cssWidth: this.canvasResolution.cssWidth,
                cssHeight: this.canvasResolution.cssHeight,
                renderWidth: this.canvasResolution.renderWidth,
                renderHeight: this.canvasResolution.renderHeight,
                devicePixelRatio: typeof this.currentDevicePixelRatio === "number"
                    ? this.currentDevicePixelRatio
                    : null,
                hudLayout: hudLayoutState,
                lastResizeCause: this.renderer?.getLastResizeCause?.() ?? null
            }
            : null;
        const resolutionChanges = this.canvasResolutionEvents.map((entry) => ({ ...entry }));
        const assetIntegrity = this.assetIntegritySummary
            ? {
                status: this.assetIntegritySummary.status ?? "pending",
                strictMode: this.assetIntegritySummary.strictMode ?? false,
                checked: this.assetIntegritySummary.checked ?? 0,
                missing: this.assetIntegritySummary.missingHash ?? 0,
                failed: this.assetIntegritySummary.failed ?? 0,
                total: this.assetIntegritySummary.totalImages ?? 0,
                scenario: this.assetIntegritySummary.scenario ?? null,
                manifest: this.assetIntegritySummary.manifest ?? null,
                firstFailure: this.assetIntegritySummary.firstFailure ?? null
            }
            : null;
        const diagnosticsCollapsedSections = diagnosticsState?.collapsedSections &&
            Object.keys(diagnosticsState.collapsedSections).length > 0
            ? { ...diagnosticsState.collapsedSections }
            : null;
        return {
            compactHeight: hudState?.compactHeight ?? null,
            tutorialBanner: {
                condensed: hudState?.tutorialBannerCondensed ?? false,
                expanded: hudState?.tutorialBannerExpanded ?? false
            },
            hud: {
                passivesCollapsed: hudState?.hudCastlePassivesCollapsed ?? null,
                goldEventsCollapsed: hudState?.hudGoldEventsCollapsed ?? null,
                prefersCondensedLists: hudState?.prefersCondensedLists ?? null,
                layout: hudLayoutState
            },
            options: {
                passivesCollapsed: hudState?.optionsPassivesCollapsed ?? null
            },
            diagnostics: {
                condensed: diagnosticsState?.condensed ?? null,
                sectionsCollapsed: diagnosticsState?.sectionsCollapsed ?? null,
                collapsedSections: diagnosticsCollapsedSections,
                lastUpdatedAt: diagnosticsSectionsUpdatedAt
            },
            preferences,
            resolution: resolutionSnapshot,
            resolutionChanges,
            assetIntegrity
        };
    }
    resetAnalytics() {
        this.engine.resetAnalytics();
        this.currentState = this.engine.getState();
        this.impactEffects = [];
        this.screenShakeBursts = [];
        this.bestCombo = this.currentState.typing.combo;
        this.hud.appendLog("Analytics reset");
        this.render();
    }
    exportAnalytics() {
        if (!this.analyticsExportEnabled) {
            this.hud.appendLog("Analytics export unavailable (feature toggle disabled).");
            console.info("[analytics] export blocked: feature toggle disabled");
            return;
        }
        const snapshot = this.engine.getAnalyticsSnapshot();
        const uiSnapshot = this.collectUiCondensedSnapshot();
        if (typeof document === "undefined" || !document.body) {
            console.warn("Analytics export skipped: document context unavailable.");
            this.hud.appendLog("Analytics export failed (no active document context).");
            return;
        }
        const telemetryExport = this.buildTelemetryExport(true);
        const exportPayload = {
            ...snapshot,
            ui: uiSnapshot,
            settings: {
                soundEnabled: this.soundEnabled,
                soundVolume: this.soundVolume,
                soundIntensity: this.audioIntensity
            },
            exportVersion: 2,
            telemetry: telemetryExport
        };
        const filename = `keyboard-defense-analytics-${snapshot.capturedAt.replace(/[:.]/g, "-")}.json`;
        const blob = new Blob([JSON.stringify(exportPayload, null, 2)], {
            type: "application/json"
        });
        const link = document.createElement("a");
        const url = URL.createObjectURL(blob);
        link.href = url;
        link.download = filename;
        document.body.appendChild(link);
        try {
            link.click();
            this.hud.appendLog(`Analytics exported to ${filename}`);
            console.info("[analytics] export complete", { filename });
        }
        finally {
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        }
    }
    exportSessionTimeline() {
        const snapshot = this.engine.getAnalyticsSnapshot();
        const waveHistory = snapshot.analytics?.waveHistory;
        const waveSummaries = snapshot.analytics?.waveSummaries;
        const waves = Array.isArray(waveHistory)
            ? waveHistory
            : Array.isArray(waveSummaries)
                ? waveSummaries
                : [];
        if (waves.length === 0) {
            this.hud.appendLog("Session timeline export unavailable (no completed waves yet).");
            return;
        }
        if (typeof document === "undefined" || !document.body) {
            console.warn("Session timeline export skipped: document context unavailable.");
            this.hud.appendLog("Session timeline export failed (no active document context).");
            return;
        }
        const filename = `keyboard-defense-session-timeline-${snapshot.capturedAt.replace(/[:.]/g, "-")}.csv`;
        const blob = new Blob([buildSessionTimelineCsv(waves)], {
            type: "text/csv"
        });
        const link = document.createElement("a");
        const url = URL.createObjectURL(blob);
        link.href = url;
        link.download = filename;
        document.body.appendChild(link);
        try {
            link.click();
            const noun = waves.length === 1 ? "wave" : "waves";
            this.hud.appendLog(`Session timeline exported (${waves.length} ${noun}) to ${filename}`);
        }
        finally {
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        }
    }
    exportKeystrokeTiming() {
        const samples = Array.isArray(this.keystrokeTimingSamples)
            ? this.keystrokeTimingSamples.slice()
            : [];
        if (samples.length === 0) {
            this.hud.appendLog("Keystroke timing export unavailable (no samples yet).");
            return;
        }
        if (typeof document === "undefined" || !document.body) {
            console.warn("Keystroke timing export skipped: document context unavailable.");
            this.hud.appendLog("Keystroke timing export failed (no active document context).");
            return;
        }
        const snapshot = this.engine.getAnalyticsSnapshot();
        const filename = `keyboard-defense-keystroke-timing-${snapshot.capturedAt.replace(/[:.]/g, "-")}.csv`;
        const blob = new Blob([buildKeystrokeTimingHistogramCsv(samples)], {
            type: "text/csv"
        });
        const link = document.createElement("a");
        const url = URL.createObjectURL(blob);
        link.href = url;
        link.download = filename;
        document.body.appendChild(link);
        try {
            link.click();
            const summary = summarizeKeystrokeTimings(samples);
            const medianNote = typeof summary.p50Ms === "number" ? `, median ${Math.round(summary.p50Ms)}ms` : "";
            const p90Note = typeof summary.p90Ms === "number" ? `, p90 ${Math.round(summary.p90Ms)}ms` : "";
            this.hud.appendLog(`Keystroke timing exported (${samples.length} samples${medianNote}${p90Note}) to ${filename}`);
        }
        finally {
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        }
    }
    exportProgress() {
        if (typeof window === "undefined" || !window.localStorage) {
            this.hud.appendLog("Progress export unavailable (local storage missing).");
            return;
        }
        const payload = exportProgressTransferPayload(window.localStorage);
        const keyCount = Object.keys(payload.entries ?? {}).length;
        if (typeof document === "undefined" || !document.body) {
            console.warn("Progress export skipped: document context unavailable.");
            this.hud.appendLog("Progress export failed (no active document context).");
            return;
        }
        const filename = `keyboard-defense-progress-${payload.exportedAt.replace(/[:.]/g, "-")}.json`;
        const blob = new Blob([JSON.stringify(payload, null, 2)], {
            type: "application/json"
        });
        const link = document.createElement("a");
        const url = URL.createObjectURL(blob);
        link.href = url;
        link.download = filename;
        document.body.appendChild(link);
        try {
            link.click();
            this.hud.appendLog(keyCount === 1 ? `Progress exported (1 key) to ${filename}` : `Progress exported (${keyCount} keys) to ${filename}`);
        }
        finally {
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        }
    }
    importProgress() {
        if (typeof window === "undefined" || !window.localStorage) {
            this.hud.appendLog("Progress import unavailable (local storage missing).");
            return;
        }
        if (typeof document === "undefined" || !document.body) {
            console.warn("Progress import skipped: document context unavailable.");
            this.hud.appendLog("Progress import failed (no active document context).");
            return;
        }
        const input = document.createElement("input");
        input.type = "file";
        input.accept = "application/json";
        input.style.position = "fixed";
        input.style.left = "-9999px";
        input.style.width = "1px";
        input.style.height = "1px";
        document.body.appendChild(input);
        const cleanup = () => {
            input.value = "";
            document.body.removeChild(input);
        };
        input.addEventListener("change", () => {
            const file = input.files?.[0] ?? null;
            if (!file) {
                cleanup();
                return;
            }
            file
                .text()
                .then((raw) => {
                let parsed;
                try {
                    parsed = JSON.parse(raw);
                }
                catch (error) {
                    this.hud.appendLog("Progress import failed (invalid JSON).");
                    console.warn("[progress] import failed: invalid JSON", error);
                    return;
                }
                const shouldApply = typeof window.confirm === "function"
                    ? window.confirm("Import progress will overwrite your current local data and reload the game. Continue?")
                    : true;
                if (!shouldApply) {
                    this.hud.appendLog("Progress import cancelled.");
                    return;
                }
                const result = importProgressTransferPayload(window.localStorage, parsed);
                if (result.errors.length > 0) {
                    this.hud.appendLog(`Progress import failed: ${result.errors[0]}`);
                    console.warn("[progress] import failed", result.errors);
                    return;
                }
                const noun = result.applied === 1 ? "key" : "keys";
                const removedLabel = result.removed > 0 ? `, removed ${result.removed}` : "";
                this.hud.appendLog(`Progress imported (${result.applied} ${noun}${removedLabel}). Reloading...`);
                window.location?.reload?.();
            })
                .finally(() => {
                cleanup();
            });
        });
        input.click();
    }
    handleDropoffReasonSelected(reasonId) {
        const reason = typeof reasonId === "string" ? reasonId.trim() : "";
        if (typeof window === "undefined") {
            return;
        }
        if (!window.localStorage) {
            this.hud.appendLog("Drop-off prompt unavailable (local storage missing). Reloading...");
            window.location?.reload?.();
            return;
        }
        const snapshot = this.engine.getAnalyticsSnapshot();
        try {
            recordDropoffReason(window.localStorage, {
                capturedAt: snapshot.capturedAt,
                reasonId: reason || "skip",
                mode: snapshot.mode,
                waveIndex: snapshot.wave?.index ?? 0,
                wavesCompleted: snapshot.analytics?.waveSummaries?.length ?? 0,
                breaches: snapshot.analytics?.sessionBreaches ?? 0,
                accuracy: snapshot.typing?.accuracy ?? 0,
                wpm: snapshot.typing?.wpm ?? 0
            });
        }
        catch (error) {
            console.warn("[dropoff] failed to record drop-off reason", error);
        }
        this.hud.appendLog("Ending session... Reloading.");
        window.location?.reload?.();
    }
    async copyAnalyticsRecap() {
        const clipboard = typeof navigator !== "undefined" ? navigator.clipboard : undefined;
        if (!clipboard || typeof clipboard.writeText !== "function") {
            this.hud.appendLog("Clipboard unavailable; try exporting instead.");
            return;
        }
        const snapshot = this.engine.getAnalyticsSnapshot();
        const accuracyPct = Math.round(Math.max(0, Math.min(1, snapshot.typing?.accuracy ?? 0)) * 100);
        const wpm = Math.round(Math.max(0, snapshot.typing?.wpm ?? 0));
        const waves = snapshot.waveSummaries?.length ?? 0;
        const breaches = snapshot.breaches ?? 0;
        const recap = [
            "Keyboard Defense analytics recap",
            `Captured: ${snapshot.capturedAt}`,
            `Waves: ${waves}`,
            `Accuracy: ${accuracyPct}%`,
            `WPM: ${wpm}`,
            `Breaches: ${breaches}`
        ].join("\n");
        try {
            await clipboard.writeText(recap);
            this.hud.appendLog("Analytics recap copied to clipboard.");
        }
        catch (error) {
            console.warn("[analytics] clipboard copy failed", error);
            this.hud.appendLog("Copy failed; try full export instead.");
        }
    }
    pauseForTutorial() {
        if (this.manualTick)
            return;
        this.tutorialHoldLoop = true;
        if (this.running) {
            this.pause();
        }
    }
    resumeFromTutorial() {
        if (this.manualTick)
            return;
        const wasHolding = this.tutorialHoldLoop;
        this.tutorialHoldLoop = false;
        if (!this.running && wasHolding) {
            this.start();
        }
    }
    tick(timestamp) {
        if (!this.running)
            return;
        if (this.lastTimestamp === null) {
            this.lastTimestamp = timestamp;
        }
        const rawDeltaSeconds = (timestamp - this.lastTimestamp) / 1000;
        if (typeof this.sessionWallTimeSeconds !== "number" || !Number.isFinite(this.sessionWallTimeSeconds)) {
            this.sessionWallTimeSeconds = 0;
        }
        if (Number.isFinite(rawDeltaSeconds) && rawDeltaSeconds > 0) {
            this.sessionWallTimeSeconds += rawDeltaSeconds;
        }
        const uiScale = typeof this.uiTimeScaleMultiplier === "number" && Number.isFinite(this.uiTimeScaleMultiplier)
            ? this.uiTimeScaleMultiplier
            : 1;
        const deltaSeconds = rawDeltaSeconds * this.speedMultiplier * uiScale;
        this.lastTimestamp = timestamp;
        this.updateKeystrokeTimingGate(timestamp);
        this.tutorialManager?.update(deltaSeconds);
        this.engine.update(deltaSeconds);
        this.render();
        this.rafId = requestAnimationFrame((time) => this.tick(time));
    }
    updateKeystrokeTimingGate(nowMs) {
        const now = typeof nowMs === "number" && Number.isFinite(nowMs) ? nowMs : performance.now();
        if (!Number.isFinite(now))
            return;
        if (now < (this.keystrokeTimingGateNextUpdateAt ?? 0)) {
            return;
        }
        this.keystrokeTimingGateNextUpdateAt = now + KEYSTROKE_TIMING_GATE_UPDATE_MS;
        const samples = Array.isArray(this.keystrokeTimingSamples)
            ? this.keystrokeTimingSamples.slice(-KEYSTROKE_TIMING_GATE_WINDOW_SAMPLES)
            : [];
        const gate = buildKeystrokeTimingGate({ samples, profile: this.keystrokeTimingProfile });
        const previous = typeof this.keystrokeTimingGateMultiplier === "number" &&
            Number.isFinite(this.keystrokeTimingGateMultiplier)
            ? this.keystrokeTimingGateMultiplier
            : 1;
        const blended = previous * (1 - KEYSTROKE_TIMING_GATE_SMOOTHING_ALPHA) +
            gate.multiplier * KEYSTROKE_TIMING_GATE_SMOOTHING_ALPHA;
        const clamped = Math.max(0.85, Math.min(1, blended));
        this.keystrokeTimingGateMultiplier = clamped;
        this.keystrokeTimingGateSnapshot = { ...gate, multiplier: clamped };
        this.engine.setSpawnSpeedGateMultiplier(clamped);
    }
    replayTutorial() {
        this.replayTutorialFromDebug();
    }
    skipTutorial() {
        this.hud.hideTutorialSummary();
        this.pendingTutorialSummary = null;
        this.engine.recordTutorialSkip();
        this.markTutorialComplete();
        this.tutorialCompleted = true;
        this.tutorialManager?.skip();
        this.resumeFromTutorial();
        this.hud.setTutorialMessage(null);
    }
    getTutorialAnalyticsSummary() {
        return structuredClone(this.engine.getState().analytics.tutorial);
    }
    getAssetIntegritySummary() {
        if (!this.assetIntegritySummary) {
            return null;
        }
        return { ...this.assetIntegritySummary };
    }
    enqueueScreenShake(kind, options = {}) {
        if (this.reducedMotionEnabled)
            return;
        const allow = options.force || this.screenShakeEnabled;
        if (!allow)
            return;
        const now = this.currentState?.time ?? this.engine.getState().time ?? 0;
        const base = SCREEN_SHAKE_BASE[kind] ?? SCREEN_SHAKE_BASE.hit;
        const duration = SCREEN_SHAKE_DURATION[kind] ?? SCREEN_SHAKE_DURATION.hit;
        const intensity = this.normalizeScreenShakeIntensity(options.intensityOverride ?? this.screenShakeIntensity);
        const magnitude = base * intensity * 2;
        this.screenShakeBursts.push({ createdAt: now, duration, magnitude });
        if (this.screenShakeBursts.length > 12) {
            this.screenShakeBursts = this.screenShakeBursts.slice(-12);
        }
    }
    getScreenShakeOffset() {
        if (this.reducedMotionEnabled)
            return null;
        const now = this.currentState?.time ?? this.engine.getState().time ?? 0;
        this.screenShakeBursts = this.screenShakeBursts.filter((entry) => now - entry.createdAt <= entry.duration);
        if (this.screenShakeBursts.length === 0)
            return null;
        let magnitude = 0;
        for (const entry of this.screenShakeBursts) {
            const age = Math.max(0, now - entry.createdAt);
            const progress = entry.duration > 0 ? Math.min(1, age / entry.duration) : 1;
            magnitude += entry.magnitude * Math.max(0, 1 - progress);
        }
        if (magnitude <= 0)
            return null;
        const clamped = Math.min(SCREEN_SHAKE_MAX_OFFSET, magnitude);
        const offsetX = (Math.random() * 2 - 1) * clamped;
        const offsetY = (Math.random() * 2 - 1) * clamped;
        return { x: offsetX, y: offsetY };
    }
    render() {
        this.currentState = this.engine.getState();
        this.tickTypoRecoveryChallenge();
        const turretSignature = this.computeTurretSignature(this.currentState);
        if (turretSignature !== this.lastTurretSignature) {
            this.lastTurretSignature = turretSignature;
            this.syncTurretPresetsToHud(this.currentState);
        }
        const impactRenders = this.collectImpactEffects();
        const turretRange = this.buildTurretRangeRenderOptions();
        let starfieldState = this.starfieldEnabled
            ? deriveStarfieldState(this.currentState, {
                config: this.starfieldConfig,
                reducedMotion: this.reducedMotionEnabled
            })
            : null;
        starfieldState = this.applyStarfieldOverride(starfieldState);
        this.starfieldState = starfieldState;
        const starfieldAnalytics = this.buildStarfieldAnalyticsSummary(starfieldState);
        this.engine.setStarfieldAnalytics(starfieldAnalytics);
        this.handleStarfieldStateChange(starfieldAnalytics);
        const challengeSelection = this.getChallengeModifiersSelection();
        const challengeActive = this.currentState.mode === "practice" &&
            Boolean(challengeSelection.enabled) &&
            (Boolean(challengeSelection.fog) ||
                Boolean(challengeSelection.fastSpawns) ||
                Boolean(challengeSelection.limitedMistakes));
        const fogOfWar = challengeActive && Boolean(challengeSelection.fog);
        this.renderer.render(this.currentState, impactRenders, {
            reducedMotion: this.reducedMotionEnabled,
            checkeredBackground: this.checkeredBackgroundEnabled,
            turretRange,
            starfield: starfieldState,
            screenShake: this.getScreenShakeOffset(),
            challengeFog: fogOfWar
        });
        this.updateAmbientTrack(this.currentState);
        this.handleGameStatusAudio(this.currentState.status);
        this.syncCanvasResizeCause();
        const upcoming = fogOfWar ? [] : this.engine.getUpcomingSpawns();
        this.hud.update(this.currentState, upcoming, {
            colorBlindFriendly: this.isColorblindPaletteActive() || this.checkeredBackgroundEnabled,
            tutorialCompleted: this.tutorialCompleted,
            loreUnlocked: this.unlockedLore?.size ?? 0,
            lessonsCompleted: this.lessonProgress?.lessonsCompleted ?? 0,
            wallTimeSeconds: this.sessionWallTimeSeconds ?? 0,
            wavePreviewEmptyMessage: fogOfWar ? "Fog of war: intel hidden." : undefined
        });
        const sessionGoalsFinalized = this.maybeFinalizeSessionGoals(this.currentState);
        this.syncSessionGoalsToHud(this.currentState, { force: sessionGoalsFinalized });
        this.maybeFinalizeKeystrokeTimingProfile(this.currentState);
        const typingDrillRecommendation = this.buildTypingDrillRecommendation(this.currentState);
        this.setTypingDrillCtaRecommendation(typingDrillRecommendation);
        this.setTypingDrillMenuRecommendation(typingDrillRecommendation);
        if (this.typingDrills?.isVisible?.()) {
            if (typingDrillRecommendation) {
                this.typingDrills.setRecommendation(typingDrillRecommendation.mode, typingDrillRecommendation.reason);
            }
            else {
                this.typingDrills.showNoRecommendation("No recommendation available.");
            }
        }
        const shieldForecast = this.hud.getShieldForecast();
        this.bestCombo = Math.max(this.bestCombo, this.currentState.typing.combo);
        const analytics = this.currentState.analytics;
        const summaries = analytics.waveHistory && analytics.waveHistory.length > 0
            ? analytics.waveHistory
            : analytics.waveSummaries;
        const runtimeMetrics = this.engine.getRuntimeMetrics();
        runtimeMetrics.memory = this.sampleMemoryUsage();
        this.diagnostics.update(runtimeMetrics, {
            bestCombo: this.bestCombo,
            breaches: analytics.sessionBreaches,
            soundEnabled: this.soundEnabled,
            soundVolume: this.soundVolume,
            soundIntensity: this.audioIntensity,
            hudFontScale: this.hudFontScale,
            summaryCount: summaries.length,
            totalTurretDamage: analytics.totalTurretDamage,
            totalTypingDamage: analytics.totalTypingDamage,
            totalRepairs: analytics.totalCastleRepairs,
            totalRepairHealth: analytics.totalRepairHealth,
            totalRepairGold: analytics.totalRepairGold,
            totalReactionTime: analytics.totalReactionTime,
            reactionSamples: analytics.reactionSamples,
            timeToFirstTurretSeconds: analytics.timeToFirstTurret,
            shieldedNow: shieldForecast.current,
            shieldedNext: shieldForecast.next,
            lastSummary: summaries.length > 0 ? summaries[summaries.length - 1] : undefined,
            assetIntegrity: this.assetIntegritySummary ?? undefined,
            lastCanvasResizeCause: this.renderer?.getLastResizeCause?.() ?? null,
            starfield: starfieldState ?? undefined,
            keystrokeTimingGate: this.keystrokeTimingGateSnapshot ?? undefined
        });
        this.checkFirstEncounterOverlay();
    }
    sampleMemoryUsage() {
        if (typeof performance === "undefined" || !performance.memory) {
            return null;
        }
        const now = performance.now();
        if (now < this.nextMemorySampleAt && this.memorySample) {
            return this.memorySample;
        }
        this.nextMemorySampleAt = now + MEMORY_SAMPLE_INTERVAL_MS;
        const usedMB = performance.memory.usedJSHeapSize / 1024 / 1024;
        const totalMB = performance.memory.totalJSHeapSize
            ? performance.memory.totalJSHeapSize / 1024 / 1024
            : null;
        const limitMB = performance.memory.jsHeapSizeLimit
            ? performance.memory.jsHeapSizeLimit / 1024 / 1024
            : null;
        const warning = typeof limitMB === "number" && limitMB > 0 ? usedMB / limitMB >= MEMORY_WARNING_RATIO : false;
        this.memorySample = {
            usedMB,
            totalMB: totalMB ?? undefined,
            limitMB: limitMB ?? undefined,
            warning
        };
        return this.memorySample;
    }
    buildTurretRangeRenderOptions() {
        if (!this.turretRangeHighlightSlot) {
            return null;
        }
        const slot = this.currentState.turrets.find((s) => s.id === this.turretRangeHighlightSlot);
        if (!slot || !slot.unlocked) {
            this.turretRangeHighlightSlot = null;
            this.turretRangePreviewType = null;
            this.turretRangePreviewLevel = null;
            return null;
        }
        const turret = slot.turret ?? null;
        const typeId = turret?.typeId ?? this.turretRangePreviewType ?? null;
        if (!typeId) {
            this.turretRangeHighlightSlot = null;
            this.turretRangePreviewType = null;
            this.turretRangePreviewLevel = null;
            return null;
        }
        const levelRaw = turret?.level ?? this.turretRangePreviewLevel ?? 1;
        const level = Number.isFinite(levelRaw) && levelRaw > 0 ? Math.floor(levelRaw) : 1;
        return {
            slotId: slot.id,
            typeId,
            level
        };
    }
    scheduleAssetPrewarm() {
        if (this.assetPrewarmScheduled ||
            !this.assetLoader ||
            this.lowGraphicsEnabled ||
            this.reducedMotionEnabled) {
            return;
        }
        this.assetPrewarmScheduled = true;
        const runner = () => {
            void this.prewarmAtlasFrames().catch(() => undefined);
        };
        if (typeof requestIdleCallback === "function") {
            requestIdleCallback(() => runner(), { timeout: ASSET_PREWARM_TIMEOUT_MS });
            return;
        }
        setTimeout(() => runner(), 50);
    }
    async prewarmAtlasFrames() {
        if (!this.assetLoader ||
            typeof this.assetLoader.listAtlasKeys !== "function" ||
            typeof this.assetLoader.resolveAtlasImage !== "function") {
            return;
        }
        const atlasKeys = this.assetLoader.listAtlasKeys();
        if (!atlasKeys || atlasKeys.length === 0) {
            return;
        }
        const pending = [];
        for (const key of atlasKeys.slice(0, ASSET_PREWARM_BATCH)) {
            if (typeof this.assetLoader.getImage === "function" && this.assetLoader.getImage(key)) {
                continue;
            }
            pending.push(this.assetLoader
                .resolveAtlasImage(key)
                .then(() => undefined)
                .catch(() => undefined));
        }
        if (pending.length > 0) {
            await Promise.allSettled(pending);
        }
    }
    handleAssetImageLoaded() {
        if (!this.renderer) {
            return;
        }
        this.render();
    }
    async waitForAssets() {
        await this.assetReadyPromise;
    }
    attachTypingDrillHooks() {
        const overlayRoot = document.getElementById("typing-drills-overlay");
        if (overlayRoot instanceof HTMLElement) {
            this.typingDrills = new TypingDrillsOverlay({
                root: overlayRoot,
                wordBank: defaultWordBank,
                callbacks: {
                    onStart: (mode, source) => this.handleTypingDrillStarted(mode, source),
                    onClose: () => this.handleTypingDrillsClosed(),
                    onSummary: (summary) => this.recordTypingDrillSummary(summary)
                }
            });
            this.syncTypingDrillUnlocksToOverlay();
            this.syncErrorClustersToOverlay();
        }
        const ctaButton = document.getElementById("typing-drills-open");
        if (ctaButton instanceof HTMLButtonElement) {
            ctaButton.addEventListener("click", () => this.openTypingDrills("cta"));
        }
        const optionsButton = document.getElementById("options-typing-drills");
        if (optionsButton instanceof HTMLButtonElement) {
            optionsButton.addEventListener("click", () => this.openTypingDrills("options"));
        }
    }
    attachWeeklyQuestHooks() {
        const trialButton = document.getElementById("weekly-quest-trial-start");
        if (trialButton instanceof HTMLButtonElement) {
            trialButton.addEventListener("click", () => this.startWeeklyTrial());
        }
    }
    attachInputHandlers(typingInput) {
        const syncLockIndicators = (event) => {
            const capsOn = Boolean(event?.getModifierState?.("CapsLock"));
            const numOn = Boolean(event?.getModifierState?.("NumLock"));
            this.hud.setCapsLockWarning(capsOn);
            this.hud.setLockIndicators({ capsOn, numOn });
        };
        const recordKeystrokeTiming = (event) => {
            if (!event || event.repeat)
                return;
            const nowMs = typeof performance !== "undefined" && typeof performance.now === "function"
                ? performance.now()
                : Date.now();
            if (!Number.isFinite(nowMs) || nowMs < 0)
                return;
            const previous = this.lastKeystrokeTimingAt;
            this.lastKeystrokeTimingAt = nowMs;
            if (typeof previous !== "number" || !Number.isFinite(previous)) {
                return;
            }
            const deltaMs = nowMs - previous;
            if (deltaMs < KEYSTROKE_TIMING_MIN_GAP_MS || deltaMs > KEYSTROKE_TIMING_MAX_GAP_MS) {
                return;
            }
            if (!Array.isArray(this.keystrokeTimingSamples)) {
                this.keystrokeTimingSamples = [];
            }
            this.keystrokeTimingSamples.push(Math.round(deltaMs));
            if (this.keystrokeTimingSamples.length > KEYSTROKE_TIMING_MAX_SAMPLES) {
                this.keystrokeTimingSamples.shift();
            }
            if (!Array.isArray(this.fatigueWaveTimingSamples)) {
                this.fatigueWaveTimingSamples = [];
            }
            this.fatigueWaveTimingSamples.push(Math.round(deltaMs));
            if (this.fatigueWaveTimingSamples.length > KEYSTROKE_TIMING_MAX_SAMPLES) {
                this.fatigueWaveTimingSamples.shift();
            }
        };
        const handler = (event) => {
            syncLockIndicators(event);
            if (this.typingDrillsOverlayActive) {
                return;
            }
            if (this.handleTypoRecoveryShortcut(event)) {
                return;
            }
            if (event.key === "Tab" &&
                !event.repeat &&
                !event.ctrlKey &&
                !event.metaKey &&
                !event.altKey &&
                this.running &&
                !this.manualTick &&
                !this.menuActive &&
                !this.optionsOverlayActive &&
                !this.waveScorecardActive &&
                !this.tutorialHoldLoop &&
                !this.tutorialManager?.getState?.().active) {
                event.preventDefault();
                this.hud?.toggleBuildMenu?.();
                return;
            }
            if (event.key === "Enter") {
                this.tutorialManager?.notify({ type: "ui:continue" });
                if (this.tutorialManager?.getState().active) {
                    event.preventDefault();
                }
                return;
            }
            if (event.key === "Backspace" && (event.ctrlKey || event.metaKey)) {
                event.preventDefault();
                const result = this.engine.purgeTypingBuffer();
                if (result.status === "purged") {
                    this.render();
                }
                return;
            }
            if (event.key === "Backspace") {
                const result = this.engine.handleBackspace();
                if (result.status !== "ignored") {
                    event.preventDefault();
                    recordKeystrokeTiming(event);
                    this.render();
                }
                return;
            }
            if (!event.repeat &&
                !event.ctrlKey &&
                !event.metaKey &&
                !event.altKey &&
                event.key.length === 1 &&
                /^[1-5]$/.test(event.key) &&
                this.running &&
                !this.manualTick &&
                !this.menuActive &&
                !this.optionsOverlayActive &&
                !this.waveScorecardActive &&
                !this.tutorialHoldLoop &&
                !this.tutorialManager?.getState?.().active) {
                const lane = Math.max(0, Number(event.key) - 1);
                const lanes = new Set((this.engine?.config?.turretSlots ?? []).map((slot) => slot.lane));
                if (!lanes.has(lane)) {
                    event.preventDefault();
                    return;
                }
                const storage = typeof window !== "undefined" ? window.localStorage : null;
                const medalProgress = this.lessonMedalProgress ?? readLessonMedalProgress(storage);
                const bestSupport = buildLessonMedalViewState(medalProgress).bestByMode?.support ?? null;
                const tier = bestSupport?.tier ?? null;
                const configByTier = tier === "platinum"
                    ? { multiplier: 1.2, duration: 4.5, cooldown: 14, label: "Platinum" }
                    : tier === "gold"
                        ? { multiplier: 1.16, duration: 4.0, cooldown: 16, label: "Gold" }
                        : tier === "silver"
                            ? { multiplier: 1.12, duration: 3.5, cooldown: 18, label: "Silver" }
                            : tier === "bronze"
                                ? { multiplier: 1.08, duration: 3.0, cooldown: 20, label: "Bronze" }
                                : { multiplier: 1.06, duration: 2.5, cooldown: 22, label: "Unranked" };
                const applied = this.engine.activateSupportBoost(lane, configByTier);
                event.preventDefault();
                recordKeystrokeTiming(event);
                this.currentState = this.engine.getState();
                const support = this.currentState.supportBoost ?? null;
                const laneLabel = ["A", "B", "C", "D", "E"][lane] ?? `${lane + 1}`;
                if (applied) {
                    this.hud?.appendLog?.(`Support surge (${configByTier.label}): lane ${laneLabel} x${configByTier.multiplier.toFixed(2)} for ${configByTier.duration.toFixed(1)}s.`);
                    this.hud?.showCastleMessage?.(`Support surge: lane ${laneLabel}.`);
                    this.render();
                    return;
                }
                const cooldown = Math.max(0, support?.cooldownRemaining ?? 0);
                if (cooldown > 0.05) {
                    this.hud?.showCastleMessage?.(`Support surge cooling down (${cooldown.toFixed(1)}s).`);
                    return;
                }
                this.hud?.showCastleMessage?.("Support surge unavailable right now.");
                return;
            }
            if (event.key.length === 1 && /^[a-zA-Z]$/.test(event.key)) {
                const comboBefore = this.currentState?.typing?.combo ?? 0;
                this.lastTypingInputContext = { comboBefore };
                let result;
                try {
                    result = this.engine.inputCharacter(event.key);
                }
                finally {
                    this.lastTypingInputContext = null;
                }
                if (result.status !== "ignored") {
                    event.preventDefault();
                    recordKeystrokeTiming(event);
                    this.render();
                    if (result.status === "completed") {
                        this.tutorialManager?.notify({
                            type: "typing:word-complete",
                            payload: { enemyId: result.enemyId ?? null }
                        });
                    }
                }
            }
        };
        typingInput.addEventListener("keydown", handler);
        typingInput.addEventListener("keyup", syncLockIndicators);
        typingInput.addEventListener("focus", () => {
            typingInput.select();
            this.lastKeystrokeTimingAt = null;
            this.hud.setCapsLockWarning(false);
            this.hud.setLockIndicators({ capsOn: false, numOn: false });
        });
        typingInput.addEventListener("blur", () => {
            this.lastKeystrokeTimingAt = null;
            this.hud.setCapsLockWarning(false);
            this.hud.setLockIndicators({ capsOn: false, numOn: false });
        });
        this.hud.focusTypingInput();
    }
    attachFullscreenListeners() {
        if (typeof document === "undefined")
            return;
        const handler = () => this.syncFullscreenStateFromDocument();
        document.addEventListener("fullscreenchange", handler);
        this.fullscreenChangeHandler = handler;
        this.syncFullscreenStateFromDocument();
    }
    syncFullscreenStateFromDocument() {
        if (!this.fullscreenSupported) {
            this.hud.setFullscreenActive(false);
            return;
        }
        const active = Boolean(document.fullscreenElement);
        this.isFullscreen = active;
        this.hud.setFullscreenActive(active);
    }
    toggleFullscreen(nextActive) {
        if (!this.fullscreenSupported || typeof document === "undefined")
            return;
        if (nextActive) {
            if (document.fullscreenElement) {
                this.syncFullscreenStateFromDocument();
                return;
            }
            const target = document.documentElement ?? document.body ?? (this.canvas?.ownerDocument?.documentElement ?? null);
            target
                ?.requestFullscreen?.()
                .then(() => {
                this.syncFullscreenStateFromDocument();
            })
                .catch((error) => {
                console.warn("Fullscreen request failed:", error);
                this.syncFullscreenStateFromDocument();
            });
        }
        else {
            if (!document.fullscreenElement) {
                this.syncFullscreenStateFromDocument();
                return;
            }
            document
                .exitFullscreen?.()
                .catch((error) => {
                console.warn("Fullscreen exit failed:", error);
            })
                .finally(() => {
                this.syncFullscreenStateFromDocument();
            });
        }
    }
    attachGlobalShortcuts() {
        if (typeof window === "undefined")
            return;
        const handler = (event) => {
            if (this.typingDrills?.isVisible?.()) {
                if (event.key === "Escape") {
                    event.preventDefault();
                    this.closeTypingDrills();
                }
                return;
            }
            const optionsVisible = this.hud.isOptionsOverlayVisible();
            const roadmapVisible = this.hud.isRoadmapOverlayVisible?.() ?? false;
            if (this.hud.isWaveScorecardVisible()) {
                if (event.key === "Escape" || event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    this.handleWaveScorecardContinue();
                }
                return;
            }
            if (event.key === "Escape") {
                const shortcutVisible = this.hud.isShortcutOverlayVisible();
                if (roadmapVisible) {
                    event.preventDefault();
                    this.hud.hideRoadmapOverlay();
                    return;
                }
                if (optionsVisible) {
                    event.preventDefault();
                    this.closeOptionsOverlay();
                    return;
                }
                if (shortcutVisible) {
                    event.preventDefault();
                    this.hud.hideShortcutOverlay();
                    return;
                }
                event.preventDefault();
                this.togglePause();
                return;
            }
            if (optionsVisible) {
                const direction = this.getHudFontScaleShortcutDelta(event);
                if (direction !== 0) {
                    event.preventDefault();
                    this.cycleHudFontScale(direction);
                }
                return;
            }
            if (roadmapVisible) {
                return;
            }
            if (this.isHotkeyMatch(event, this.hotkeys.shortcuts)) {
                event.preventDefault();
                this.hud.toggleShortcutOverlay();
                return;
            }
            if (this.hud.isShortcutOverlayVisible()) {
                return;
            }
            const target = event.target;
            const isEditable = target instanceof HTMLInputElement ||
                target instanceof HTMLTextAreaElement ||
                (target !== null && target.isContentEditable);
            if (isEditable) {
                return;
            }
            const key = event.key.toLowerCase();
            if (event.shiftKey && key === "r") {
                event.preventDefault();
                const recommendation = this.buildTypingDrillRecommendation();
                if (recommendation) {
                    this.openTypingDrills("shortcut", {
                        mode: recommendation.mode,
                        autoStart: true,
                        reason: recommendation.reason
                    });
                }
                return;
            }
            if (this.isHotkeyMatch(event, this.hotkeys.pause)) {
                event.preventDefault();
                this.togglePause();
                return;
            }
            if (key === "d") {
                event.preventDefault();
                this.toggleDiagnostics();
                return;
            }
            if (key === "m") {
                event.preventDefault();
                this.toggleSound();
            }
        };
        window.addEventListener("keydown", handler);
    }
    isHotkeyMatch(event, hotkey) {
        if (!hotkey || typeof hotkey !== "string")
            return false;
        const key = event.key?.toLowerCase?.() ?? "";
        const normalized = hotkey.toLowerCase();
        if (normalized === "?") {
            return key === "?" || (key === "/" && event.shiftKey);
        }
        if (normalized === "slash") {
            return key === "/";
        }
        if (normalized === "space") {
            return key === " " || key === "spacebar" || key === "space";
        }
        if (normalized === "escape" || normalized === "esc") {
            return key === "escape" || key === "esc";
        }
        return key === normalized;
    }
    attachFocusTrap() {
        if (typeof window === "undefined")
            return;
        const handler = (event) => {
            const target = event.target;
            const interactive = target instanceof HTMLInputElement ||
                target instanceof HTMLTextAreaElement ||
                target instanceof HTMLSelectElement ||
                target instanceof HTMLButtonElement ||
                target instanceof HTMLAnchorElement ||
                (target !== null && target.isContentEditable);
            if (interactive) {
                return;
            }
            const modalOpen = this.hud.isOptionsOverlayVisible() ||
                (this.hud.isRoadmapOverlayVisible?.() ?? false) ||
                this.hud.isShortcutOverlayVisible() ||
                this.hud.isWaveScorecardVisible() ||
                Boolean(this.typingDrills?.isVisible?.());
            if (modalOpen) {
                return;
            }
            this.hud.focusTypingInput();
        };
        window.addEventListener("pointerdown", handler);
    }
    getHudFontScaleShortcutDelta(event) {
        if (!event || event.metaKey || event.ctrlKey || event.altKey) {
            return 0;
        }
        if (event.key === "[")
            return -1;
        if (event.key === "]")
            return 1;
        return 0;
    }
    initializePlayerSettings() {
        if (typeof window === "undefined") {
            this.playerSettings = createDefaultPlayerSettings();
            return;
        }
        const stored = loadPlayerSettingsFromStorage(window.localStorage);
        this.playerSettings = stored;
        this.accessibilitySelfTest =
            stored.accessibilitySelfTest ?? { ...ACCESSIBILITY_SELF_TEST_DEFAULT };
        this.colorblindPaletteMode = this.loadColorblindMode();
        if (this.colorblindPaletteMode !== "off") {
            this.lastColorblindMode = this.colorblindPaletteMode;
        }
        this.setCrystalPulseEnabled(stored.crystalPulseEnabled ?? false, {
            persist: false,
            silent: true
        });
        this.setEliteAffixesEnabled(stored.eliteAffixesEnabled ?? this.featureToggles.eliteAffixes ?? false, {
            persist: false,
            silent: true,
            force: true
        });
        this.setSoundEnabled(stored.soundEnabled, { silent: true, persist: false, render: false });
        this.setSoundVolume(stored.soundVolume ?? SOUND_VOLUME_DEFAULT, {
            silent: true,
            persist: false
        });
        this.setAudioIntensity(stored.audioIntensity ?? AUDIO_INTENSITY_DEFAULT, {
            silent: true,
            persist: false
        });
        this.setVoicePack(stored.voicePackId ?? "mentor-classic", {
            silent: true,
            persist: false,
            render: false
        });
        this.setMusicEnabled(stored.musicEnabled ?? true, {
            silent: true,
            persist: false,
            render: false
        });
        this.setMusicLevel(stored.musicLevel ?? MUSIC_LEVEL_DEFAULT, {
            silent: true,
            persist: false
        });
        this.setTutorialPacing(stored.tutorialPacing ?? 1, {
            silent: true,
            persist: false,
            render: false
        });
        this.setDiagnosticsVisible(stored.diagnosticsVisible, {
            silent: true,
            persist: false,
            render: false
        });
        this.setReducedMotionEnabled(stored.reducedMotionEnabled, {
            silent: true,
            persist: false,
            render: false
        });
        this.setAudioNarrationEnabled(stored.audioNarrationEnabled ?? false, {
            silent: true,
            persist: false,
            render: false
        });
        this.setLargeSubtitlesEnabled(stored.largeSubtitlesEnabled ?? false, {
            silent: true,
            persist: false,
            render: false
        });
        const legacySparkline = this.loadLatencySparklineEnabled();
        const storedSparkline = typeof stored.latencySparklineEnabled === "boolean"
            ? stored.latencySparklineEnabled
            : legacySparkline;
        this.setLatencySparklineEnabled(storedSparkline, {
            silent: true,
            persist: typeof stored.latencySparklineEnabled === "boolean" ? false : true,
            force: true
        });
        this.setScreenShakeIntensity(stored.screenShakeIntensity ?? SCREEN_SHAKE_INTENSITY_DEFAULT, {
            silent: true,
            persist: false
        });
        this.setScreenShakeEnabled(stored.screenShakeEnabled ?? false, {
            silent: true,
            persist: false,
            render: false
        });
        this.setTextSizeScale(stored.textSizeScale ?? 1, {
            silent: true,
            persist: false,
            render: false
        });
        this.setCheckeredBackgroundEnabled(stored.checkeredBackgroundEnabled, {
            silent: true,
            persist: false,
            render: false
        });
        this.setVirtualKeyboardEnabled(stored.virtualKeyboardEnabled ?? false, {
            silent: true,
            persist: false,
            render: false
        });
        this.setVirtualKeyboardLayout(stored.virtualKeyboardLayout ?? DEFAULT_VIRTUAL_KEYBOARD_LAYOUT, { silent: true, persist: false, render: false });
        this.setHapticsEnabled(stored.hapticsEnabled ?? false, {
            silent: true,
            persist: false,
            render: false
        });
        this.setLowGraphicsEnabled(stored.lowGraphicsEnabled ?? false, {
            silent: true,
            persist: false,
            render: false,
            force: true
        });
        const initialColorblindMode = stored.colorblindPaletteEnabled === false
            ? "off"
            : this.colorblindPaletteMode !== "off"
                ? this.colorblindPaletteMode
                : this.lastColorblindMode ?? "deuteran";
        this.setColorblindPaletteMode(initialColorblindMode, {
            silent: true,
            persist: false,
            render: false
        });
        this.setFocusOutlinePreset(stored.focusOutlinePreset ?? FOCUS_OUTLINE_DEFAULT, {
            persist: false,
            silent: true,
            render: false
        });
        this.setDefeatAnimationMode(stored.defeatAnimationMode ?? "auto", {
            silent: true,
            persist: false
        });
        this.setReadableFontEnabled(stored.readableFontEnabled ?? false, {
            silent: true,
            persist: false,
            render: false
        });
        this.setDyslexiaFontEnabled(stored.dyslexiaFontEnabled ?? false, {
            silent: true,
            persist: false,
            render: false
        });
        this.setDyslexiaSpacingEnabled(stored.dyslexiaSpacingEnabled ?? false, {
            silent: true,
            persist: false,
            render: false
        });
        this.setReducedCognitiveLoadEnabled(stored.reducedCognitiveLoadEnabled ?? false, {
            silent: true,
            persist: false,
            render: false
        });
        this.setAccessibilityPresetEnabled(stored.accessibilityPresetEnabled ?? false, {
            silent: true,
            persist: false,
            render: false,
            applyPreset: false
        });
        this.setAudioNarrationEnabled(stored.audioNarrationEnabled ?? false, {
            silent: true,
            persist: false,
            render: false
        });
        this.setBackgroundBrightness(stored.backgroundBrightness ?? BG_BRIGHTNESS_DEFAULT, {
            silent: true,
            persist: false
        });
        this.setHudZoom(stored.hudZoom ?? HUD_ZOOM_DEFAULT, {
            silent: true,
            persist: false,
            render: false
        });
        this.setHudLayoutSide(stored.hudLayout ?? HUD_LAYOUT_DEFAULT, {
            silent: true,
            persist: false,
            render: false
        });
        this.setCastleSkin(stored.castleSkin ?? "classic", {
            persist: false,
            updateOptions: false
        });
        this.setHudFontScale(stored.hudFontScale ?? 1, {
            silent: true,
            persist: false,
            render: false
        });
        const storedTelemetry = typeof stored.telemetryEnabled === "boolean" ? stored.telemetryEnabled : false;
        this.setTelemetryEnabled(storedTelemetry, {
            silent: true,
            persist: false
        });
        const targeting = stored.turretTargeting ?? {};
        for (const [slotId, priority] of Object.entries(targeting)) {
            this.setTurretTargetingPriority(slotId, priority, {
                silent: true,
                persist: false,
                render: false
            });
        }
        this.turretLoadoutPresets = this.cloneTurretPresetMap(stored.turretLoadoutPresets ?? {});
        this.syncTurretPresetsToHud(this.currentState);
        this.hud.applyCollapsePreferences({
            hudCastlePassivesCollapsed: stored.hudPassivesCollapsed ?? null,
            hudGoldEventsCollapsed: stored.hudGoldEventsCollapsed ?? null,
            optionsPassivesCollapsed: stored.optionsPassivesCollapsed ?? null
        }, { silent: true, fallbackToPreferred: true });
        if (this.diagnostics) {
            this.diagnostics.applySectionPreferences(stored.diagnosticsSections ?? {}, { silent: true });
        }
        this.updateOptionsOverlayState();
    }
    attachDebugButtons() {
        const pause = document.getElementById("debug-pause");
        const resume = document.getElementById("debug-resume");
        const step = document.getElementById("debug-step");
        const gold = document.getElementById("debug-gold");
        const diagnostics = document.getElementById("debug-diagnostics");
        const sound = document.getElementById("debug-sound");
        const soundVolumeSlider = document.getElementById("debug-sound-volume");
        const soundVolumeValue = document.getElementById("debug-sound-volume-value");
        const soundIntensitySlider = document.getElementById("debug-sound-intensity");
        const soundIntensityValue = document.getElementById("debug-sound-intensity-value");
        const resetAnalytics = document.getElementById("debug-analytics-reset");
        const exportAnalytics = document.getElementById("debug-analytics-export");
        const copyAnalytics = document.getElementById("debug-analytics-copy-link");
        const analyticsViewerToggle = document.getElementById("debug-analytics-viewer-toggle");
        const tutorialReplay = document.getElementById("debug-tutorial-replay");
        const telemetryControlsContainer = document.getElementById("debug-telemetry-controls");
        const telemetryToggle = document.getElementById("debug-telemetry-toggle");
        const telemetryFlush = document.getElementById("debug-telemetry-flush");
        const telemetryDownload = document.getElementById("debug-telemetry-download");
        const telemetryEndpointInput = document.getElementById("debug-telemetry-endpoint");
        const telemetryEndpointApply = document.getElementById("debug-telemetry-endpoint-apply");
        const crystalToggleButton = document.getElementById("debug-crystal-toggle");
        const eliteToggleButton = document.getElementById("debug-elite-toggle");
        const downgradeToggleButton = document.getElementById("debug-turret-downgrade");
        const spawnDummyButton = document.getElementById("debug-spawn-dummy");
        const clearDummiesButton = document.getElementById("debug-clear-dummies");
        const wavePreviewButton = document.getElementById("debug-wave-preview");
        const wavePreviewUrlInput = document.getElementById("debug-wave-preview-url");
        const wavePreviewSaveButton = document.getElementById("debug-wave-preview-save");
        const candidateTelemetryControls = {
            container: telemetryControlsContainer instanceof HTMLElement ? telemetryControlsContainer : null,
            toggleButton: telemetryToggle instanceof HTMLButtonElement ? telemetryToggle : null,
            flushButton: telemetryFlush instanceof HTMLButtonElement ? telemetryFlush : null,
            downloadButton: telemetryDownload instanceof HTMLButtonElement ? telemetryDownload : null,
            endpointInput: telemetryEndpointInput instanceof HTMLInputElement ? telemetryEndpointInput : null,
            endpointApply: telemetryEndpointApply instanceof HTMLButtonElement ? telemetryEndpointApply : null
        };
        this.telemetryDebugControls =
            candidateTelemetryControls.container ||
                candidateTelemetryControls.toggleButton ||
                candidateTelemetryControls.flushButton ||
                candidateTelemetryControls.downloadButton ||
                candidateTelemetryControls.endpointInput ||
                candidateTelemetryControls.endpointApply
                ? candidateTelemetryControls
                : null;
        if (crystalToggleButton instanceof HTMLButtonElement) {
            this.debugCrystalToggle = crystalToggleButton;
            crystalToggleButton.addEventListener("click", () => this.setCrystalPulseEnabled(!this.featureToggles.crystalPulse));
        }
        else {
            this.debugCrystalToggle = null;
        }
        if (eliteToggleButton instanceof HTMLButtonElement) {
            this.debugEliteToggle = eliteToggleButton;
            eliteToggleButton.addEventListener("click", () => this.setEliteAffixesEnabled(!this.featureToggles.eliteAffixes));
        }
        else {
            this.debugEliteToggle = null;
        }
        if (downgradeToggleButton instanceof HTMLButtonElement) {
            this.debugDowngradeToggle = downgradeToggleButton;
            downgradeToggleButton.addEventListener("click", () => this.setTurretDowngradeEnabled(!this.featureToggles.turretDowngrade));
        }
        else {
            this.debugDowngradeToggle = null;
        }
        if (spawnDummyButton instanceof HTMLButtonElement) {
            spawnDummyButton.addEventListener("click", () => this.spawnPracticeDummy(1));
        }
        if (clearDummiesButton instanceof HTMLButtonElement) {
            clearDummiesButton.addEventListener("click", () => this.clearPracticeDummies());
        }
        const readWavePreviewUrlFromStorage = () => {
            try {
                return window.localStorage?.getItem("wavePreviewUrl") ?? "";
            }
            catch {
                return "";
            }
        };
        const writeWavePreviewUrlToStorage = (url) => {
            try {
                window.localStorage?.setItem("wavePreviewUrl", url);
            }
            catch {
                // ignore
            }
        };
        const resolveWavePreviewUrl = () => {
            const storedUrl = readWavePreviewUrlFromStorage().trim();
            const inputUrl = wavePreviewUrlInput instanceof HTMLInputElement ? wavePreviewUrlInput.value.trim() : "";
            const candidate = inputUrl || storedUrl;
            return candidate && candidate.startsWith("http") ? candidate : "http://localhost:4179/";
        };
        if (wavePreviewUrlInput instanceof HTMLInputElement) {
            const storedUrl = readWavePreviewUrlFromStorage();
            if (storedUrl && storedUrl.startsWith("http")) {
                wavePreviewUrlInput.value = storedUrl;
            }
        }
        if (wavePreviewSaveButton instanceof HTMLButtonElement && wavePreviewUrlInput) {
            wavePreviewSaveButton.addEventListener("click", () => {
                const url = resolveWavePreviewUrl();
                writeWavePreviewUrlToStorage(url);
            });
        }
        if (wavePreviewButton instanceof HTMLButtonElement) {
            wavePreviewButton.addEventListener("click", () => {
                const url = resolveWavePreviewUrl();
                writeWavePreviewUrlToStorage(url);
                try {
                    window.open(url, "_blank", "noopener,noreferrer");
                }
                catch {
                    // best-effort open
                    window.open(url, "_blank");
                }
            });
        }
        pause?.addEventListener("click", () => this.pause());
        resume?.addEventListener("click", () => this.resume());
        step?.addEventListener("click", () => this.step());
        gold?.addEventListener("click", () => this.grantGold(100));
        diagnostics?.addEventListener("click", () => this.toggleDiagnostics());
        sound?.addEventListener("click", () => this.toggleSound());
        if (soundVolumeSlider instanceof HTMLInputElement) {
            this.soundDebugControls = {
                slider: soundVolumeSlider,
                valueLabel: soundVolumeValue instanceof HTMLElement ? soundVolumeValue : undefined,
                intensitySlider: soundIntensitySlider instanceof HTMLInputElement ? soundIntensitySlider : undefined,
                intensityValueLabel: soundIntensityValue instanceof HTMLElement ? soundIntensityValue : undefined
            };
            soundVolumeSlider.addEventListener("input", () => {
                const value = Number.parseFloat(soundVolumeSlider.value);
                if (!Number.isFinite(value))
                    return;
                this.setSoundVolume(value);
            });
            if (this.soundDebugControls.intensitySlider) {
                this.soundDebugControls.intensitySlider.addEventListener("input", () => {
                    const value = Number.parseFloat(this.soundDebugControls.intensitySlider.value);
                    if (!Number.isFinite(value))
                        return;
                    this.setAudioIntensity(value);
                });
            }
        }
        else {
            this.soundDebugControls = null;
        }
        resetAnalytics?.addEventListener("click", () => this.resetAnalytics());
        if (exportAnalytics) {
            if (!this.analyticsExportEnabled) {
                exportAnalytics.style.display = "none";
                exportAnalytics.setAttribute("aria-hidden", "true");
                exportAnalytics.tabIndex = -1;
                if (exportAnalytics instanceof HTMLButtonElement) {
                    exportAnalytics.disabled = true;
                }
            }
            else {
                exportAnalytics.style.display = "";
                exportAnalytics.setAttribute("aria-hidden", "false");
                exportAnalytics.tabIndex = 0;
                if (exportAnalytics instanceof HTMLButtonElement) {
                    exportAnalytics.disabled = false;
                }
                exportAnalytics.addEventListener("click", () => this.exportAnalytics());
            }
        }
        if (copyAnalytics instanceof HTMLButtonElement) {
            copyAnalytics.addEventListener("click", () => {
                void this.copyAnalyticsRecap();
            });
        }
        if (analyticsViewerToggle instanceof HTMLButtonElement) {
            if (!this.hud.hasAnalyticsViewer()) {
                analyticsViewerToggle.style.display = "none";
            }
            else {
                const syncToggleState = () => {
                    const visible = this.hud.isAnalyticsViewerVisible();
                    analyticsViewerToggle.textContent = visible
                        ? "Hide Analytics Viewer"
                        : "Show Analytics Viewer";
                    analyticsViewerToggle.setAttribute("aria-expanded", visible ? "true" : "false");
                };
                syncToggleState();
                analyticsViewerToggle.addEventListener("click", () => {
                    this.hud.toggleAnalyticsViewer();
                    syncToggleState();
                });
            }
        }
        if (tutorialReplay) {
            if (!this.tutorialManager) {
                tutorialReplay.style.display = "none";
            }
            else {
                tutorialReplay.addEventListener("click", () => this.replayTutorialFromDebug());
            }
        }
        if (this.telemetryDebugControls) {
            const controls = this.telemetryDebugControls;
            if (controls.toggleButton && this.telemetryClient) {
                controls.toggleButton.addEventListener("click", () => this.toggleTelemetry());
            }
            if (controls.flushButton && this.telemetryClient) {
                controls.flushButton.addEventListener("click", () => this.flushTelemetry());
            }
            if (controls.downloadButton && this.telemetryClient) {
                controls.downloadButton.addEventListener("click", () => this.exportTelemetryQueue());
            }
            if (controls.endpointApply && this.telemetryClient) {
                controls.endpointApply.addEventListener("click", () => {
                    const value = controls.endpointInput?.value ?? "";
                    this.setTelemetryEndpoint(value);
                });
            }
            if (controls.endpointInput) {
                controls.endpointInput.value = this.telemetryEndpoint ?? "";
                if (this.telemetryClient) {
                    controls.endpointInput.addEventListener("keydown", (event) => {
                        if (event.key === "Enter") {
                            event.preventDefault();
                            this.setTelemetryEndpoint(controls.endpointInput?.value ?? "");
                        }
                    });
                }
            }
        }
        this.syncTelemetryDebugControls();
        this.syncSoundDebugControls();
        this.syncTurretDowngradeControls();
        this.syncCrystalPulseControls();
        this.syncEliteAffixControls();
    }
    handleCastleUpgrade() {
        this.upgradeCastle();
    }
    handleCastleRepair() {
        this.repairCastle();
    }
    handlePlaceTurret(slotId, typeId) {
        this.placeTurret(slotId, typeId);
        const state = this.engine.getState();
        const slot = state.turrets.find((s) => s.id === slotId);
        if (slot?.turret) {
            this.tutorialManager?.notify({
                type: "turret:placed",
                payload: { slotId, typeId: slot.turret.typeId }
            });
        }
    }
    handleUpgradeTurret(slotId) {
        this.upgradeTurret(slotId);
        const state = this.engine.getState();
        const slot = state.turrets.find((s) => s.id === slotId);
        const level = slot?.turret?.level ?? null;
        this.tutorialManager?.notify({ type: "turret:upgraded", payload: { slotId, level } });
    }
    handleDowngradeTurret(slotId) {
        this.downgradeTurret(slotId);
    }
    handleTurretPriorityChange(slotId, priority) {
        const changed = this.setTurretTargetingPriority(slotId, priority);
        if (changed) {
            this.tutorialManager?.notify({
                type: "turret:targeting",
                payload: { slotId, priority }
            });
        }
    }
    handleBuildMenuToggle(open) {
        const active = Boolean(open);
        this.uiTimeScaleMultiplier = active ? BUILD_MENU_TIME_SCALE : 1;
        if (active) {
            const pct = Math.round(BUILD_MENU_TIME_SCALE * 100);
            this.hud?.showCastleMessage?.(`Build menu open: slow-mo ${pct}%.`);
        }
    }
    handleTurretPresetSave(presetId) {
        if (!this.isValidPresetId(presetId)) {
            this.hud.showCastleMessage(`Unknown preset "${presetId}".`);
            return;
        }
        const snapshot = this.captureTurretBlueprintFromState(this.currentState ?? this.engine.getState());
        const nextPreset = {
            id: presetId,
            savedAt: new Date().toISOString(),
            slots: snapshot
        };
        const nextMap = this.cloneTurretPresetMap(this.turretLoadoutPresets);
        nextMap[presetId] = nextPreset;
        this.turretLoadoutPresets = nextMap;
        this.persistPlayerSettings({ turretLoadoutPresets: nextMap });
        const label = this.formatPresetLabel(presetId);
        const slotCount = Object.keys(snapshot).length;
        const detail = slotCount > 0 ? `${slotCount} slot${slotCount === 1 ? "" : "s"}` : "empty";
        this.hud.showCastleMessage(`Saved ${label} (${detail}).`);
        this.syncTurretPresetsToHud(this.currentState ?? this.engine.getState());
    }
    handleTurretPresetApply(presetId) {
        if (!this.isValidPresetId(presetId)) {
            this.hud.showCastleMessage(`Unknown preset "${presetId}".`);
            return;
        }
        const preset = this.turretLoadoutPresets?.[presetId];
        if (!preset) {
            this.hud.showCastleMessage(`No layout saved in ${this.formatPresetLabel(presetId)}.`);
            return;
        }
        const blueprint = this.cloneTurretPresetSlots(preset.slots);
        for (const slotConfig of Object.values(blueprint)) {
            if (slotConfig && !this.isTurretTypeEnabled(slotConfig.typeId)) {
                const label = this.getTurretArchetypeLabel(slotConfig.typeId);
                this.hud.showCastleMessage(`${label} is disabled and cannot be applied right now.`);
                return;
            }
        }
        const preview = this.engine.applyTurretBlueprint(blueprint, { preview: true });
        if (!preview.success) {
            this.hud.showCastleMessage(preview.message ?? `Unable to apply ${this.formatPresetLabel(presetId)}.`);
            return;
        }
        const result = this.engine.applyTurretBlueprint(blueprint);
        if (!result.success) {
            this.hud.showCastleMessage(result.message ?? `Unable to apply ${this.formatPresetLabel(presetId)}.`);
            return;
        }
        const state = this.engine.getState();
        this.syncTargetingPreferencesFromState(state);
        this.activeTurretPresetId = presetId;
        const label = this.formatPresetLabel(presetId);
        const message = result.cost > 0 ? `${label} applied (-${result.cost}g).` : `${label} applied.`;
        this.hud.showCastleMessage(message);
        this.currentState = state;
        this.render();
        this.syncTurretPresetsToHud(this.currentState);
        if (this.telemetryClient && typeof this.telemetryClient.track === "function") {
            this.telemetryClient.track("turret-preset-applied", {
                presetId,
                cost: result.cost,
                slots: Object.keys(blueprint).length
            });
        }
    }
    handleTurretPresetClear(presetId) {
        if (!this.isValidPresetId(presetId)) {
            this.hud.showCastleMessage(`Unknown preset "${presetId}".`);
            return;
        }
        if (!this.turretLoadoutPresets?.[presetId]) {
            this.hud.showCastleMessage(`${this.formatPresetLabel(presetId)} is already empty.`);
            return;
        }
        const nextMap = this.cloneTurretPresetMap(this.turretLoadoutPresets);
        delete nextMap[presetId];
        this.turretLoadoutPresets = nextMap;
        this.persistPlayerSettings({ turretLoadoutPresets: nextMap });
        if (this.activeTurretPresetId === presetId) {
            this.activeTurretPresetId = null;
        }
        this.hud.showCastleMessage(`Cleared ${this.formatPresetLabel(presetId)}.`);
        this.syncTurretPresetsToHud(this.currentState ?? this.engine.getState());
    }
    handleTurretHover(slotId, context = {}) {
        const nextSlot = slotId ?? null;
        const nextType = nextSlot ? (context?.typeId ?? null) : null;
        const nextLevel = nextSlot ? (context?.level ?? null) : null;
        const unchanged = this.turretRangeHighlightSlot === nextSlot &&
            this.turretRangePreviewType === nextType &&
            this.turretRangePreviewLevel === nextLevel;
        if (unchanged) {
            return;
        }
        this.turretRangeHighlightSlot = nextSlot;
        this.turretRangePreviewType = nextType;
        this.turretRangePreviewLevel = typeof nextLevel === "number" ? nextLevel : null;
        this.render();
    }
    handleHudCollapsePreferenceChange(preferences) {
        const patch = {};
        if (Object.prototype.hasOwnProperty.call(preferences, "hudCastlePassivesCollapsed")) {
            patch.hudPassivesCollapsed = preferences.hudCastlePassivesCollapsed;
        }
        if (Object.prototype.hasOwnProperty.call(preferences, "hudGoldEventsCollapsed")) {
            patch.hudGoldEventsCollapsed = preferences.hudGoldEventsCollapsed;
        }
        if (Object.prototype.hasOwnProperty.call(preferences, "optionsPassivesCollapsed")) {
            patch.optionsPassivesCollapsed = preferences.optionsPassivesCollapsed;
        }
        if (Object.keys(patch).length > 0) {
            this.persistPlayerSettings(patch);
        }
    }
    handleDiagnosticsSectionPreferenceChange(preferences) {
        if (!preferences || typeof preferences !== "object") {
            return;
        }
        this.persistPlayerSettings({
            diagnosticsSections: { ...preferences },
            diagnosticsSectionsUpdatedAt: new Date().toISOString()
        });
    }
    presentTutorialSummary(summary) {
        this.pauseForTutorial();
        const normalizedSummary = {
            accuracy: summary.accuracy,
            bestCombo: summary.bestCombo ?? Math.max(this.bestCombo, 0),
            breaches: summary.breaches,
            gold: summary.gold
        };
        this.pendingTutorialSummary = normalizedSummary;
        const hudSummary = {
            accuracy: normalizedSummary.accuracy,
            bestCombo: normalizedSummary.bestCombo,
            breaches: normalizedSummary.breaches,
            gold: normalizedSummary.gold
        };
        this.hud.showTutorialSummary(hudSummary, {
            onContinue: () => this.handleTutorialContinue(),
            onReplay: () => this.handleTutorialReplay()
        });
    }
    debugShowTutorialSummary(summary = {}) {
        const state = this.engine.getState();
        const normalized = {
            accuracy: typeof summary.accuracy === "number"
                ? summary.accuracy
                : state.typing?.accuracy ?? 0,
            bestCombo: typeof summary.bestCombo === "number"
                ? summary.bestCombo
                : Math.max(this.bestCombo, state.typing?.combo ?? 0),
            breaches: typeof summary.breaches === "number"
                ? summary.breaches
                : state.analytics?.sessionBreaches ?? 0,
            gold: typeof summary.gold === "number"
                ? summary.gold
                : Math.round(state.resources?.gold ?? 0)
        };
        this.hud.showTutorialSummary(normalized, {
            onContinue: () => { },
            onReplay: () => { }
        });
    }
    debugHideTutorialSummary() {
        this.hud.hideTutorialSummary();
    }
    collectTutorialSummary() {
        const state = this.engine.getState();
        return {
            accuracy: state.typing.accuracy,
            bestCombo: Math.max(this.bestCombo, state.typing.combo),
            breaches: state.analytics.sessionBreaches,
            gold: state.resources.gold
        };
    }
    handleTutorialContinue() {
        this.hud.hideTutorialSummary();
        if (this.pendingTutorialSummary) {
            this.engine.recordTutorialSummary(this.pendingTutorialSummary, { replayed: false });
            this.pendingTutorialSummary = null;
        }
        this.markTutorialComplete();
        this.tutorialManager?.notify({ type: "summary:dismissed" });
        this.resumeFromTutorial();
        this.hud.setTutorialMessage(null);
    }
    handleTutorialReplay() {
        this.hud.hideTutorialSummary();
        if (this.pendingTutorialSummary) {
            this.engine.recordTutorialSummary(this.pendingTutorialSummary, { replayed: true });
            this.pendingTutorialSummary = null;
        }
        this.tutorialManager?.notify({ type: "summary:dismissed" });
        this.clearTutorialProgress();
        this.startTutorial(true);
    }
    startTutorial(forceReplay = false) {
        if (!this.tutorialManager)
            return;
        this.closeOptionsOverlay({ resume: false });
        this.closeWaveScorecard({ resume: false });
        this.pause();
        this.setPracticeMode(false);
        this.pendingTutorialSummary = null;
        this.tutorialHoldLoop = false;
        this.tutorialManager.reset();
        if (forceReplay) {
            this.engine.reset();
            this.sessionWallTimeSeconds = 0;
            this.bestCombo = 0;
            this.impactEffects = [];
            this.screenShakeBursts = [];
        }
        this.tutorialCompleted = false;
        this.render();
        this.tutorialManager.start();
    }
    setPracticeMode(enabled) {
        this.practiceMode = enabled;
        this.engine.setLoopWaves(Boolean(enabled));
        this.engine.setMode(enabled ? "practice" : "campaign");
    }
    applyChallengeModifiersToEngine() {
        if (!this.engine || typeof this.engine.setChallengeModifiers !== "function") {
            return null;
        }
        const selection = this.getChallengeModifiersSelection();
        const anyEnabled = Boolean(selection.enabled) &&
            (Boolean(selection.fog) || Boolean(selection.fastSpawns) || Boolean(selection.limitedMistakes));
        if (!anyEnabled) {
            this.engine.setChallengeModifiers(null);
            return null;
        }
        const view = buildChallengeModifiersViewState({
            version: CHALLENGE_MODIFIERS_VERSION,
            selection,
            updatedAt: new Date().toISOString()
        });
        this.engine.setChallengeModifiers({
            fog: Boolean(selection.fog),
            fastSpawns: Boolean(selection.fastSpawns),
            limitedMistakes: Boolean(selection.limitedMistakes),
            mistakeBudget: selection.mistakeBudget,
            scoreMultiplier: view.scoreMultiplier
        });
        return view;
    }
    getTypoRecoveryNowMs() {
        return typeof performance !== "undefined" && typeof performance.now === "function"
            ? performance.now()
            : Date.now();
    }
    cancelTypoRecoveryChallenge() {
        this.typoRecoveryActive = false;
        this.typoRecoveryStep = 0;
        this.typoRecoveryDeadlineAtMs = 0;
        this.typoRecoveryComboBeforeError = 0;
    }
    tickTypoRecoveryChallenge(nowMs) {
        if (!this.typoRecoveryActive) {
            return;
        }
        const now = typeof nowMs === "number" && Number.isFinite(nowMs) ? nowMs : this.getTypoRecoveryNowMs();
        const state = this.currentState ?? this.engine.getState();
        if (!state || state.status !== "running" || state.wave?.inCountdown) {
            this.cancelTypoRecoveryChallenge();
            return;
        }
        const deadline = typeof this.typoRecoveryDeadlineAtMs === "number" ? this.typoRecoveryDeadlineAtMs : 0;
        if (deadline && now > deadline) {
            this.cancelTypoRecoveryChallenge();
        }
    }
    maybeStartTypoRecoveryChallenge(options = {}) {
        if (this.typoRecoveryActive) {
            return false;
        }
        if (this.tutorialManager?.getState?.().active) {
            return false;
        }
        const state = this.engine.getState();
        if (!state || state.status !== "running" || state.wave?.inCountdown) {
            return false;
        }
        const now = this.getTypoRecoveryNowMs();
        if (now < (this.typoRecoveryCooldownUntilMs ?? 0)) {
            return false;
        }
        const waveIndex = typeof state.wave?.index === "number" ? state.wave.index : null;
        if (typeof waveIndex === "number" && this.typoRecoveryWaveIndex === waveIndex) {
            return false;
        }
        const comboBefore = typeof options.comboBefore === "number" && Number.isFinite(options.comboBefore)
            ? Math.max(0, Math.floor(options.comboBefore))
            : 0;
        if (comboBefore < 3) {
            return false;
        }
        this.typoRecoveryActive = true;
        this.typoRecoveryStep = 0;
        this.typoRecoveryWaveIndex = waveIndex;
        this.typoRecoveryComboBeforeError = comboBefore;
        this.typoRecoveryDeadlineAtMs = now + 5200;
        const displayed = this.hud?.announceEnemyTaunt?.("Typo recovery: Ctrl/Cmd + Z (Undo)", {
            durationMs: 5200
        });
        if (!displayed) {
            this.hud?.showCastleMessage?.("Typo recovery: Ctrl/Cmd + Z (Undo)");
        }
        this.hud?.appendLog?.("Typo recovery prompt: Ctrl/Cmd+Z then redo to restore combo.");
        return true;
    }
    matchesShortcutChord(chord, event) {
        if (!chord || !event) {
            return false;
        }
        const expectedKey = typeof chord.key === "string" && chord.key.length === 1 ? chord.key.toLowerCase() : chord.key;
        const actualKey = event.key.length === 1 ? event.key.toLowerCase() : event.key;
        if (actualKey !== expectedKey) {
            return false;
        }
        const primary = Boolean(event.ctrlKey || event.metaKey);
        if (typeof chord.primary === "boolean" && chord.primary !== primary) {
            return false;
        }
        if (typeof chord.shift === "boolean" && chord.shift !== Boolean(event.shiftKey)) {
            return false;
        }
        if (typeof chord.alt === "boolean" && chord.alt !== Boolean(event.altKey)) {
            return false;
        }
        return true;
    }
    handleTypoRecoveryShortcut(event) {
        if (!event || event.repeat) {
            return false;
        }
        const primary = Boolean(event.ctrlKey || event.metaKey);
        if (!primary) {
            return false;
        }
        const key = event.key.length === 1 ? event.key.toLowerCase() : event.key;
        if (key !== "z" && key !== "y") {
            return false;
        }
        event.preventDefault();
        event.stopPropagation?.();
        event.stopImmediatePropagation?.();
        if (!this.typoRecoveryActive) {
            return true;
        }
        const now = this.getTypoRecoveryNowMs();
        const deadline = typeof this.typoRecoveryDeadlineAtMs === "number" ? this.typoRecoveryDeadlineAtMs : 0;
        if (deadline && now > deadline) {
            this.cancelTypoRecoveryChallenge();
            return true;
        }
        const step = typeof this.typoRecoveryStep === "number" ? this.typoRecoveryStep : 0;
        if (step <= 0) {
            const matched = this.matchesShortcutChord({ key: "z", primary: true, shift: false }, event);
            if (!matched) {
                this.hud?.showCastleMessage?.("Recovery: press Ctrl/Cmd + Z.");
                return true;
            }
            this.typoRecoveryStep = 1;
            this.typoRecoveryDeadlineAtMs = now + 5200;
            this.hud?.announceEnemyTaunt?.("Typo recovery: Ctrl/Cmd + Y (Redo) or Ctrl/Cmd + Shift + Z", { durationMs: 5200 });
            return true;
        }
        const redoMatched = this.matchesShortcutChord({ key: "y", primary: true, shift: false }, event) ||
            this.matchesShortcutChord({ key: "z", primary: true, shift: true }, event);
        if (!redoMatched) {
            this.hud?.showCastleMessage?.("Recovery: press Ctrl/Cmd + Y.");
            return true;
        }
        this.completeTypoRecoveryChallenge();
        return true;
    }
    completeTypoRecoveryChallenge() {
        const combo = typeof this.typoRecoveryComboBeforeError === "number" && Number.isFinite(this.typoRecoveryComboBeforeError)
            ? Math.max(0, Math.floor(this.typoRecoveryComboBeforeError))
            : 0;
        this.cancelTypoRecoveryChallenge();
        this.typoRecoveryCooldownUntilMs = this.getTypoRecoveryNowMs() + 15000;
        if (combo > 0 && typeof this.engine.recoverCombo === "function") {
            this.engine.recoverCombo(combo);
        }
        this.hud?.appendLog?.("Typo recovery complete: combo restored.");
        this.hud?.showCastleMessage?.("Recovery complete: combo restored.");
        this.hud?.announceEnemyTaunt?.("Recovery complete: combo restored.", { durationMs: 1400 });
        this.render();
    }
    startPracticeMode() {
        if (this.isScreenTimeLockoutActive()) {
            this.handleScreenTimeLockoutAttempt("practice-mode");
            return;
        }
        this.setPracticeMode(true);
        const challenge = this.applyChallengeModifiersToEngine();
        this.closeOptionsOverlay({ resume: false });
        this.closeWaveScorecard({ resume: false });
        this.pause();
        this.menuActive = false;
        this.pendingTutorialSummary = null;
        this.tutorialHoldLoop = false;
        this.tutorialManager?.reset();
        this.tutorialCompleted = true;
        this.hud.setTutorialMessage(null);
        this.engine.reset();
        this.sessionWallTimeSeconds = 0;
        this.bestCombo = 0;
        this.impactEffects = [];
        this.screenShakeBursts = [];
        this.currentState = this.engine.getState();
        const focusLane = this.engine.getLaneFocus();
        const laneLabel = typeof focusLane === "number"
            ? `Lane ${["A", "B", "C", "D", "E"][focusLane] ?? focusLane + 1}`
            : "All lanes";
        this.hud.appendLog(`Practice mode engaged: waves now loop endlessly. Focus lane: ${laneLabel}.`);
        if (challenge?.active?.length) {
            this.hud.appendLog(`Challenge modifiers active: ${challenge.summary}`);
        }
        this.render();
        this.start();
    }
    startWeeklyTrial() {
        if (this.isScreenTimeLockoutActive()) {
            this.handleScreenTimeLockoutAttempt("weekly-trial");
            return;
        }
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.weeklyQuestBoard = this.weeklyQuestBoard ?? readWeeklyQuestBoard(storage);
        const view = buildWeeklyQuestBoardView(this.weeklyQuestBoard);
        if (view.trial.status !== "ready") {
            const message = view.trial.status === "completed"
                ? "Weekly Trial already completed this week."
                : "Weekly Trial locked: complete the weekly quests first.";
            this.hud.appendLog(message, "quest");
            this.syncWeeklyQuestBoardToHud();
            return;
        }
        if (!this.weeklyTrialBackup) {
            this.weeklyTrialBackup = {
                waves: this.engine.config.waves,
                prepCountdownSeconds: this.engine.config.prepCountdownSeconds,
                dynamicSpawns: Boolean(this.engine.config.featureToggles?.dynamicSpawns),
                evacuationEvents: Boolean(this.engine.config.featureToggles?.evacuationEvents),
                loopWaves: this.engine.isLoopingWaves(),
                mode: this.engine.getMode(),
                laneFocus: this.engine.getLaneFocus()
            };
        }
        this.weeklyTrialActive = true;
        this.weeklyTrialFinalized = false;
        this.weeklyTrialReturnPending = false;
        const trialWave = buildWeeklyTrialWaveConfig(this.weeklyQuestBoard.week);
        this.engine.config.waves = [trialWave];
        this.engine.config.prepCountdownSeconds = 0;
        if (this.engine.config.featureToggles) {
            this.engine.config.featureToggles.dynamicSpawns = false;
            this.engine.config.featureToggles.evacuationEvents = false;
        }
        this.engine.setLaneFocus(null);
        this.engine.setLoopWaves(false);
        this.engine.reset();
        this.sessionWallTimeSeconds = 0;
        this.engine.setMode("practice");
        const challenge = this.applyChallengeModifiersToEngine();
        this.closeOptionsOverlay({ resume: false });
        this.closeWaveScorecard({ resume: false });
        this.pause();
        this.menuActive = false;
        this.pendingTutorialSummary = null;
        this.tutorialHoldLoop = false;
        this.bestCombo = 0;
        this.impactEffects = [];
        this.screenShakeBursts = [];
        this.currentState = this.engine.getState();
        this.hud.appendLog("Weekly Trial started: defend through the bespoke challenge wave.", "quest");
        if (challenge?.active?.length) {
            this.hud.appendLog(`Challenge modifiers active: ${challenge.summary}`);
        }
        this.render();
        this.start();
    }
    restoreWeeklyTrialConfig() {
        const backup = this.weeklyTrialBackup;
        if (!backup)
            return;
        this.engine.config.waves = backup.waves;
        this.engine.config.prepCountdownSeconds = backup.prepCountdownSeconds;
        if (this.engine.config.featureToggles) {
            this.engine.config.featureToggles.dynamicSpawns = backup.dynamicSpawns;
            this.engine.config.featureToggles.evacuationEvents = backup.evacuationEvents;
        }
        this.engine.setLaneFocus(backup.laneFocus);
        this.engine.setLoopWaves(backup.loopWaves);
        this.engine.setMode(backup.mode);
    }
    completeWeeklyTrialReturn() {
        if (!this.weeklyTrialReturnPending) {
            return false;
        }
        this.weeklyTrialReturnPending = false;
        const backup = this.weeklyTrialBackup;
        if (!backup) {
            return false;
        }
        this.restoreWeeklyTrialConfig();
        this.weeklyTrialBackup = null;
        const returnToPractice = Boolean(backup.loopWaves || backup.mode === "practice");
        if (returnToPractice) {
            this.startPracticeMode();
            return true;
        }
        if (this.isScreenTimeLockoutActive()) {
            this.handleScreenTimeLockoutAttempt("campaign");
            return false;
        }
        this.setPracticeMode(false);
        this.closeOptionsOverlay({ resume: false });
        this.pause();
        this.menuActive = false;
        this.pendingTutorialSummary = null;
        this.tutorialHoldLoop = false;
        this.engine.reset();
        this.sessionWallTimeSeconds = 0;
        this.bestCombo = 0;
        this.impactEffects = [];
        this.screenShakeBursts = [];
        this.currentState = this.engine.getState();
        this.hud.appendLog("Returning to Campaign...");
        this.render();
        this.start();
        return true;
    }
    initializeLessonProgress() {
        if (typeof window === "undefined" || !window.localStorage) {
            this.lessonProgress = { lessonsCompleted: 0, unlockedScrolls: new Set() };
            return;
        }
        const stored = readLessonProgress(window.localStorage);
        this.lessonProgress = {
            lessonsCompleted: Math.max(0, stored.lessonsCompleted ?? 0),
            unlockedScrolls: new Set(stored.unlockedScrolls ?? [])
        };
    }
    initializeLessonMedals() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.lessonMedalProgress = readLessonMedalProgress(storage);
    }
    initializeWpmLadder() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.wpmLadderProgress = readWpmLadderProgress(storage);
    }
    initializeSessionGoals() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.sessionGoals = readSessionGoals(storage);
        const placement = readPlacementTestResult(storage);
        this.sessionGoals = seedSessionGoalsFromPlacement(this.sessionGoals, placement);
        this.sessionGoals = writeSessionGoals(storage, this.sessionGoals);
        this.sessionGoalsFinalized = false;
        this.sessionGoalsNextUpdateAt = 0;
    }
    initializeKeystrokeTimingProfile() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.keystrokeTimingProfile = readKeystrokeTimingProfile(storage);
        this.keystrokeTimingProfile = writeKeystrokeTimingProfile(storage, this.keystrokeTimingProfile);
        this.keystrokeTimingProfileFinalized = false;
        this.keystrokeTimingGateMultiplier = 1;
        this.keystrokeTimingGateNextUpdateAt = 0;
        this.keystrokeTimingGateSnapshot = buildKeystrokeTimingGate({
            samples: [],
            profile: this.keystrokeTimingProfile
        });
        this.keystrokeTimingGateMultiplier =
            this.keystrokeTimingGateSnapshot?.multiplier ?? this.keystrokeTimingGateMultiplier;
        this.engine.setSpawnSpeedGateMultiplier(this.keystrokeTimingGateMultiplier);
    }
    initializeSpacedRepetition() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.spacedRepetition = readSpacedRepetitionState(storage);
        this.spacedRepetition = writeSpacedRepetitionState(storage, this.spacedRepetition);
        this.spacedRepetitionLastSavedAt = 0;
        this.spacedRepetitionWaveStats = { keys: {}, digraphs: {} };
        this.spacedRepetitionLastProgress = { enemyId: null, buffer: "" };
    }
    initializeSfxLibrary() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.sfxLibrary = readSfxLibraryState(storage);
    }
    initializeUiSoundScheme() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.uiSoundScheme = readUiSchemeState(storage);
    }
    initializeMusicStems() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.musicStems = readMusicStemState(storage);
    }
    initializeBiomeGallery() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.biomeGallery = readBiomeGallery(storage);
    }
    initializeDayNightTheme() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        const theme = readDayNightTheme(storage);
        this.dayNightTheme = theme.mode ?? "night";
    }
    initializeParallaxScene() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.parallaxScene = readParallaxScene(storage);
    }
    initializeTrainingCalendar() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.trainingCalendar = readTrainingCalendar(storage);
    }
    initializeDailyQuestBoard() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.dailyQuestBoard = readDailyQuestBoard(storage);
    }
    initializeWeeklyQuestBoard() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.weeklyQuestBoard = readWeeklyQuestBoard(storage);
    }
    initializePracticeLaneFocus() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        const lane = readPracticeLaneFocus(storage);
        this.practiceLaneFocusLane = writePracticeLaneFocus(storage, lane);
        this.engine.setLaneFocus(this.practiceLaneFocusLane);
    }
    initializeChallengeModifiers() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.challengeModifiers = readChallengeModifiers(storage);
        if (storage) {
            this.challengeModifiers = writeChallengeModifiers(storage, this.challengeModifiers);
        }
    }
    getChallengeModifiersSelection() {
        const current = this.challengeModifiers?.selection ?? getDefaultChallengeModifiersSelection();
        return normalizeChallengeModifiersSelection(current);
    }
    persistChallengeModifiersSelection(patch = {}) {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        const current = this.getChallengeModifiersSelection();
        const nextSelection = normalizeChallengeModifiersSelection({ ...current, ...patch });
        const nextState = {
            ...(this.challengeModifiers ?? {
                version: CHALLENGE_MODIFIERS_VERSION,
                selection: nextSelection,
                updatedAt: new Date().toISOString()
            }),
            version: CHALLENGE_MODIFIERS_VERSION,
            selection: nextSelection,
            updatedAt: new Date().toISOString()
        };
        this.challengeModifiers = writeChallengeModifiers(storage, nextState);
        this.syncChallengeModifiersMainMenu();
        return nextSelection;
    }
    syncChallengeModifiersMainMenu() {
        const enabledToggle = document.getElementById("main-menu-challenge-enabled");
        const fogToggle = document.getElementById("main-menu-challenge-fog");
        const fastSpawnsToggle = document.getElementById("main-menu-challenge-fast-spawns");
        const limitedMistakesToggle = document.getElementById("main-menu-challenge-limited-mistakes");
        const mistakeBudgetSelect = document.getElementById("main-menu-challenge-mistake-budget");
        const multiplierPill = document.getElementById("main-menu-challenge-multiplier");
        const summary = document.getElementById("main-menu-challenge-summary");
        const grid = document.getElementById("main-menu-challenge-grid");
        const selection = this.getChallengeModifiersSelection();
        const view = buildChallengeModifiersViewState(this.challengeModifiers ?? {
            version: CHALLENGE_MODIFIERS_VERSION,
            selection,
            updatedAt: new Date().toISOString()
        });
        if (enabledToggle instanceof HTMLInputElement) {
            enabledToggle.checked = Boolean(selection.enabled);
        }
        if (fogToggle instanceof HTMLInputElement) {
            fogToggle.checked = Boolean(selection.fog);
            fogToggle.disabled = !selection.enabled;
        }
        if (fastSpawnsToggle instanceof HTMLInputElement) {
            fastSpawnsToggle.checked = Boolean(selection.fastSpawns);
            fastSpawnsToggle.disabled = !selection.enabled;
        }
        if (limitedMistakesToggle instanceof HTMLInputElement) {
            limitedMistakesToggle.checked = Boolean(selection.limitedMistakes);
            limitedMistakesToggle.disabled = !selection.enabled;
        }
        if (mistakeBudgetSelect instanceof HTMLSelectElement) {
            mistakeBudgetSelect.value = String(selection.mistakeBudget);
            mistakeBudgetSelect.disabled = !selection.enabled;
        }
        if (grid instanceof HTMLElement) {
            grid.dataset.disabled = selection.enabled ? "false" : "true";
        }
        if (multiplierPill instanceof HTMLElement) {
            multiplierPill.textContent = `Score x${view.scoreMultiplier.toFixed(2)}`;
        }
        if (summary instanceof HTMLElement) {
            summary.textContent = view.summary;
        }
    }
    initializeStreakTokens() {
        const storage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.streakTokens = readStreakTokens(storage);
    }
    initializeLoreProgress() {
        if (typeof window === "undefined" || !window.localStorage)
            return;
        const progress = readLoreProgress(window.localStorage, LORE_VERSION);
        this.unlockedLore = new Set(progress.unlocked ?? []);
    }
    unlockLoreForWave(waveNumber) {
        if (typeof window === "undefined" || !window.localStorage)
            return;
        const newEntries = listNewLoreForWave(waveNumber, this.unlockedLore ?? new Set());
        if (!newEntries.length)
            return;
        for (const entry of newEntries) {
            this.unlockedLore.add(entry.id);
            this.hud?.appendLog?.(`Codex unlocked: ${entry.title}`);
        }
        writeLoreProgress(window.localStorage, this.unlockedLore, LORE_VERSION);
    }
    buildLoreScrollViewState() {
        const summary = buildLoreScrollProgress(this.lessonProgress?.lessonsCompleted ?? 0, this.lessonProgress?.unlockedScrolls ?? []);
        return {
            lessonsCompleted: summary.lessonsCompleted,
            total: summary.total,
            unlocked: summary.unlocked,
            next: summary.next,
            entries: summary.entries.map((entry) => ({
                id: entry.scroll.id,
                title: entry.scroll.title,
                summary: entry.scroll.summary,
                body: entry.scroll.body ?? "",
                requiredLessons: entry.scroll.requiredLessons,
                unlocked: entry.unlocked,
                progress: entry.progress,
                remaining: entry.remaining
            }))
        };
    }
    buildSeasonTrackViewState() {
        const lessons = this.lessonProgress?.lessonsCompleted ?? 0;
        return buildSeasonTrackProgress(lessons, this.seasonTrackRewards ?? listSeasonTrack());
    }
    syncSeasonTrackToHud() {
        if (!this.hud)
            return;
        this.hud.setSeasonTrackProgress(this.buildSeasonTrackViewState());
    }
    syncDailyQuestBoardToHud() {
        if (!this.hud || !this.dailyQuestBoard)
            return;
        this.hud.setDailyQuestBoard(buildDailyQuestBoardView(this.dailyQuestBoard));
    }
    syncWeeklyQuestBoardToHud() {
        if (!this.hud || !this.weeklyQuestBoard)
            return;
        this.hud.setWeeklyQuestBoard(buildWeeklyQuestBoardView(this.weeklyQuestBoard));
    }
    syncLessonMedalsToHud(nextTarget, options = {}) {
        if (!this.hud || !this.lessonMedalProgress)
            return;
        const state = buildLessonMedalViewState(this.lessonMedalProgress);
        if (nextTarget) {
            state.nextTarget = nextTarget;
        }
        this.hud.setLessonMedalProgress(state, options);
    }
    syncWpmLadderToHud() {
        if (!this.hud || !this.wpmLadderProgress)
            return;
        this.hud.setWpmLadder(buildWpmLadderView(this.wpmLadderProgress));
    }
    maybeFinalizeSessionGoals(state) {
        if (!state || !this.sessionGoals)
            return false;
        const ended = state.status === "victory" || state.status === "defeat";
        if (!ended) {
            this.sessionGoalsFinalized = false;
            return false;
        }
        if (this.sessionGoalsFinalized) {
            return false;
        }
        this.sessionGoalsFinalized = true;
        const history = state.analytics?.waveHistory && state.analytics.waveHistory.length > 0
            ? state.analytics.waveHistory
            : state.analytics?.waveSummaries ?? [];
        const metrics = buildSessionGoalsMetrics({
            mode: state.mode ?? "campaign",
            status: state.status,
            elapsedSeconds: state.time ?? 0,
            correctInputs: state.typing?.correctInputs ?? 0,
            accuracy: state.typing?.accuracy ?? 0,
            waveSummaries: history
        });
        const capturedAt = new Date().toISOString();
        const outcome = state.status === "victory" ? "victory" : "defeat";
        this.sessionGoals = recordSessionGoalsRun(this.sessionGoals, {
            capturedAt,
            mode: state.mode ?? "campaign",
            outcome,
            metrics,
            status: state.status
        });
        if (typeof window !== "undefined" && window.localStorage) {
            this.sessionGoals = writeSessionGoals(window.localStorage, this.sessionGoals);
        }
        if (state.mode !== "practice") {
            const questStorage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
            this.dailyQuestBoard = this.dailyQuestBoard ?? readDailyQuestBoard(questStorage);
            this.dailyQuestBoard = recordDailyQuestCampaignRun(this.dailyQuestBoard, {
                wavesCompleted: metrics.wavesCompleted,
                accuracyPct: metrics.accuracyPct
            });
            if (questStorage) {
                this.dailyQuestBoard = writeDailyQuestBoard(questStorage, this.dailyQuestBoard);
            }
            this.syncDailyQuestBoardToHud();
            const weeklyWasUnlocked = Boolean(this.weeklyQuestBoard?.trial?.unlockedAt);
            this.weeklyQuestBoard = this.weeklyQuestBoard ?? readWeeklyQuestBoard(questStorage);
            this.weeklyQuestBoard = recordWeeklyQuestCampaignRun(this.weeklyQuestBoard, {
                wavesCompleted: metrics.wavesCompleted,
                accuracyPct: metrics.accuracyPct
            });
            if (questStorage) {
                this.weeklyQuestBoard = writeWeeklyQuestBoard(questStorage, this.weeklyQuestBoard);
            }
            if (!weeklyWasUnlocked && this.weeklyQuestBoard?.trial?.unlockedAt) {
                this.hud?.appendLog?.("Weekly Trial unlocked! Open Mission Control to start it.", "quest");
            }
            this.syncWeeklyQuestBoardToHud();
        }
        if (this.weeklyTrialActive && !this.weeklyTrialFinalized) {
            this.weeklyTrialFinalized = true;
            const trialOutcome = outcome === "victory" ? "victory" : "defeat";
            const questStorage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
            const wasCompleted = Boolean(this.weeklyQuestBoard?.trial?.completedAt);
            this.weeklyQuestBoard = this.weeklyQuestBoard ?? readWeeklyQuestBoard(questStorage);
            this.weeklyQuestBoard = recordWeeklyQuestTrialAttempt(this.weeklyQuestBoard, trialOutcome);
            if (questStorage) {
                this.weeklyQuestBoard = writeWeeklyQuestBoard(questStorage, this.weeklyQuestBoard);
            }
            this.syncWeeklyQuestBoardToHud();
            if (!wasCompleted && this.weeklyQuestBoard?.trial?.completedAt) {
                this.hud?.appendLog?.("Weekly Trial complete! Great defense.", "quest");
            }
            else if (trialOutcome === "victory") {
                this.hud?.appendLog?.("Weekly Trial victory recorded.", "quest");
            }
            else {
                this.hud?.appendLog?.("Weekly Trial attempt recorded. You can try again anytime.", "quest");
            }
            this.restoreWeeklyTrialConfig();
            this.weeklyTrialActive = false;
            this.weeklyTrialReturnPending = true;
            if (!this.waveScorecardActive) {
                this.completeWeeklyTrialReturn();
            }
        }
        const met = this.sessionGoals.lastRun
            ? Object.values(this.sessionGoals.lastRun.results).filter((entry) => entry === "met").length
            : 0;
        const total = this.sessionGoals.lastRun
            ? Object.values(this.sessionGoals.lastRun.results).filter((entry) => entry !== "pending").length
            : 0;
        const totalLabel = total > 0 ? total : 3;
        this.hud?.appendLog?.(`Session goals updated: ${met}/${totalLabel} goals met.`, "quest");
        return true;
    }
    maybeFinalizeKeystrokeTimingProfile(state) {
        if (!state || !this.keystrokeTimingProfile)
            return false;
        const ended = state.status === "victory" || state.status === "defeat";
        if (!ended) {
            this.keystrokeTimingProfileFinalized = false;
            return false;
        }
        if (this.keystrokeTimingProfileFinalized) {
            return false;
        }
        this.keystrokeTimingProfileFinalized = true;
        const samples = Array.isArray(this.keystrokeTimingSamples)
            ? this.keystrokeTimingSamples.slice(-600)
            : [];
        const capturedAt = new Date().toISOString();
        const outcome = state.status === "victory" ? "victory" : "defeat";
        this.keystrokeTimingProfile = recordKeystrokeTimingProfileRun(this.keystrokeTimingProfile, {
            capturedAt,
            outcome,
            samples
        });
        if (typeof window !== "undefined" && window.localStorage) {
            this.keystrokeTimingProfile = writeKeystrokeTimingProfile(window.localStorage, this.keystrokeTimingProfile);
        }
        const last = this.keystrokeTimingProfile.lastRun;
        if (last &&
            last.sampleCount >= 30 &&
            typeof last.tempoWpm === "number" &&
            typeof last.jitterMs === "number") {
            const bandNote = last.band ? ` (${last.band})` : "";
            this.hud?.appendLog?.(`Keystroke timing profile updated: ${Math.round(last.tempoWpm)} WPM${bandNote}, jitter ${Math.round(last.jitterMs)}ms.`);
        }
        else if (last) {
            this.hud?.appendLog?.(`Keystroke timing profile captured (${last.sampleCount} samples).`);
        }
        this.keystrokeTimingGateNextUpdateAt = 0;
        this.updateKeystrokeTimingGate(typeof performance !== "undefined" ? performance.now() : Date.now());
        return true;
    }
    syncSessionGoalsToHud(state, options = {}) {
        if (!this.hud || !state || !this.sessionGoals)
            return;
        const now = typeof performance !== "undefined" ? performance.now() : Date.now();
        const force = options.force === true;
        if (!force && now < (this.sessionGoalsNextUpdateAt ?? 0)) {
            return;
        }
        this.sessionGoalsNextUpdateAt = now + 900;
        const history = state.analytics?.waveHistory && state.analytics.waveHistory.length > 0
            ? state.analytics.waveHistory
            : state.analytics?.waveSummaries ?? [];
        const metrics = buildSessionGoalsMetrics({
            mode: state.mode ?? "campaign",
            status: state.status,
            elapsedSeconds: state.time ?? 0,
            correctInputs: state.typing?.correctInputs ?? 0,
            accuracy: state.typing?.accuracy ?? 0,
            waveSummaries: history
        });
        this.hud.setSessionGoals(buildSessionGoalsView(this.sessionGoals, metrics, state.status));
    }
    syncBiomeGalleryToHud() {
        if (!this.hud || !this.biomeGallery)
            return;
        this.hud.setBiomeGallery(buildBiomeGalleryView(this.biomeGallery));
    }
    syncDayNightThemeToHud() {
        if (!this.hud)
            return;
        const mode = this.dayNightTheme ?? "night";
        this.hud.setDayNightTheme(mode);
    }
    syncParallaxSceneToHud() {
        if (!this.hud)
            return;
        const selection = this.parallaxScene ?? "auto";
        const resolved = resolveParallaxScene(selection, this.dayNightTheme ?? "night");
        this.hud.setParallaxScene(selection, resolved);
    }
    syncSfxLibraryToHud() {
        if (!this.hud || !this.sfxLibrary)
            return;
        this.hud.setSfxLibrary(buildSfxLibraryView(this.sfxLibrary));
    }
    syncUiSoundSchemeToHud() {
        if (!this.hud || !this.uiSoundScheme)
            return;
        this.hud.setUiSoundScheme(buildUiSchemeView(this.uiSoundScheme));
    }
    syncMusicStemsToHud() {
        if (!this.hud || !this.musicStems)
            return;
        this.hud.setMusicStems(buildMusicStemView(this.musicStems));
    }
    syncParallaxMotionPause() {
        if (typeof this.hud?.setParallaxMotionPaused === "function") {
            const paused = Boolean(this.reducedMotionEnabled || this.lowGraphicsEnabled);
            this.hud.setParallaxMotionPaused(paused);
        }
    }
    syncTrainingCalendarToHud() {
        if (!this.hud || !this.trainingCalendar)
            return;
        this.hud.setTrainingCalendar(buildTrainingCalendarView(this.trainingCalendar));
    }
    syncStreakTokensToHud() {
        if (!this.hud || !this.trainingCalendar || !this.streakTokens)
            return;
        const calendarView = buildTrainingCalendarView(this.trainingCalendar);
        const streak = computeCurrentStreak(calendarView);
        this.hud.setStreakTokens({
            tokens: this.streakTokens.tokens ?? 0,
            streak,
            lastAwarded: this.streakTokens.lastAwardedDate ?? null
        });
    }
    syncLoreScrollsToHud() {
        if (!this.hud || !this.lessonProgress)
            return;
        this.hud.setLoreScrollProgress(this.buildLoreScrollViewState());
    }
    handleLessonCompletion(summary) {
        const words = Math.max(0, summary?.words ?? 0);
        if (words <= 0)
            return;
        const previousLessons = this.lessonProgress?.lessonsCompleted ?? 0;
        const previousUnlocked = new Set(this.lessonProgress?.unlockedScrolls ?? []);
        const nextLessons = previousLessons + 1;
        const newlyUnlocked = listNewLoreScrollsForLessons(nextLessons, previousUnlocked);
        const unlocked = new Set(previousUnlocked);
        for (const scroll of newlyUnlocked) {
            unlocked.add(scroll.id);
            this.hud?.appendLog?.(`Lore scroll unlocked: ${scroll.title}`);
        }
        this.lessonProgress = {
            lessonsCompleted: nextLessons,
            unlockedScrolls: unlocked
        };
        if (typeof window !== "undefined" && window.localStorage) {
            writeLessonProgress(window.localStorage, {
                version: LESSON_PROGRESS_VERSION,
                lessonsCompleted: nextLessons,
                unlockedScrolls: Array.from(unlocked),
                updatedAt: new Date().toISOString()
            });
        }
        const medalBase = this.lessonMedalProgress ?? readLessonMedalProgress(null);
        const medalResult = recordLessonMedal(medalBase, summary);
        this.lessonMedalProgress = medalResult.progress;
        const medalLabel = medalResult.record.tier.charAt(0).toUpperCase() + medalResult.record.tier.slice(1);
        const modeLabel = this.getTypingDrillModeLabel(medalResult.record.mode);
        this.hud?.appendLog?.(`${medalLabel} medal earned in ${modeLabel}.`, "medal");
        if (typeof window !== "undefined" && window.localStorage) {
            writeLessonMedalProgress(window.localStorage, medalResult.progress);
        }
        const questStorage = typeof window !== "undefined" && window.localStorage ? window.localStorage : null;
        this.dailyQuestBoard = this.dailyQuestBoard ?? readDailyQuestBoard(questStorage);
        this.dailyQuestBoard = recordDailyQuestDrill(this.dailyQuestBoard, {
            medalTier: medalResult.record.tier
        });
        if (questStorage) {
            this.dailyQuestBoard = writeDailyQuestBoard(questStorage, this.dailyQuestBoard);
        }
        this.syncDailyQuestBoardToHud();
        const weeklyWasUnlocked = Boolean(this.weeklyQuestBoard?.trial?.unlockedAt);
        this.weeklyQuestBoard = this.weeklyQuestBoard ?? readWeeklyQuestBoard(questStorage);
        this.weeklyQuestBoard = recordWeeklyQuestDrill(this.weeklyQuestBoard, {
            medalTier: medalResult.record.tier
        });
        if (questStorage) {
            this.weeklyQuestBoard = writeWeeklyQuestBoard(questStorage, this.weeklyQuestBoard);
        }
        if (!weeklyWasUnlocked && this.weeklyQuestBoard?.trial?.unlockedAt) {
            this.hud?.appendLog?.("Weekly Trial unlocked! Open Mission Control to start it.");
        }
        this.syncWeeklyQuestBoardToHud();
        const calendarDelta = drillSummaryToCalendarDelta(summary);
        this.recordWpmLadderEntry(summary);
        this.recordTrainingCalendarEntry(summary, calendarDelta);
        this.recordBiomeEntry(summary, calendarDelta);
        this.syncStreakTokensToHud();
        this.syncLoreScrollsToHud();
        this.syncSeasonTrackToHud();
        this.syncLessonMedalsToHud(medalResult.nextTarget);
    }
    recordWpmLadderEntry(summary) {
        const base = this.wpmLadderProgress ?? readWpmLadderProgress(null);
        const result = recordWpmLadderRun(base, summary);
        this.wpmLadderProgress = result.progress;
        if (typeof window !== "undefined" && window.localStorage) {
            writeWpmLadderProgress(window.localStorage, result.progress);
        }
        this.hud?.setWpmLadder(buildWpmLadderView(result.progress));
    }
    recordTrainingCalendarEntry(summary, calendarDelta) {
        const base = this.trainingCalendar ?? readTrainingCalendar(null);
        const deltas = calendarDelta ?? drillSummaryToCalendarDelta(summary);
        const next = recordTrainingDay(base, deltas);
        this.trainingCalendar = next;
        const calendarView = buildTrainingCalendarView(next);
        const tokens = this.streakTokens ?? readStreakTokens(null);
        const tokenResult = maybeAwardStreakToken({
            calendar: calendarView,
            state: tokens
        });
        this.streakTokens = tokenResult.state;
        if (tokenResult.awarded) {
            this.hud?.appendLog?.("Streak-freeze token earned for your daily streak.");
        }
        if (typeof window !== "undefined" && window.localStorage) {
            writeTrainingCalendar(window.localStorage, next);
            writeStreakTokens(window.localStorage, this.streakTokens);
        }
        this.hud?.setTrainingCalendar(calendarView);
        this.hud?.setStreakTokens({
            tokens: this.streakTokens.tokens ?? 0,
            streak: computeCurrentStreak(calendarView),
            lastAwarded: this.streakTokens.lastAwardedDate ?? null
        });
    }
    recordBiomeEntry(summary, calendarDelta) {
        const delta = calendarDelta ?? drillSummaryToCalendarDelta(summary);
        const result = recordBiomeRun(this.biomeGallery, summary, delta);
        this.biomeGallery = result.progress;
        if (typeof window !== "undefined" && window.localStorage) {
            writeBiomeGallery(window.localStorage, this.biomeGallery);
        }
        this.syncBiomeGalleryToHud();
    }
    setActiveBiomeSelection(biomeId) {
        this.biomeGallery = setActiveBiome(this.biomeGallery, biomeId);
        if (typeof window !== "undefined" && window.localStorage) {
            writeBiomeGallery(window.localStorage, this.biomeGallery);
        }
        const view = buildBiomeGalleryView(this.biomeGallery);
        const match = view.cards.find((card) => card.id === biomeId);
        if (match) {
            this.hud?.appendLog?.(`Biome set to ${match.name} (${match.focus}).`);
        }
        this.hud?.setBiomeGallery(view);
    }
    setDayNightTheme(mode) {
        const nextMode = mode === "day" ? "day" : "night";
        this.dayNightTheme = nextMode;
        if (typeof window !== "undefined" && window.localStorage) {
            writeDayNightTheme(window.localStorage, {
                mode: nextMode,
                updatedAt: new Date().toISOString()
            });
        }
        this.syncDayNightThemeToHud();
        this.syncParallaxSceneToHud();
    }
    setParallaxScene(scene, options = {}) {
        const nextScene = scene === "day" || scene === "night" || scene === "storm" ? scene : "auto";
        const changed = this.parallaxScene !== nextScene;
        this.parallaxScene = nextScene;
        if (!options.silent && changed) {
            const label = nextScene === "auto"
                ? "Auto (match day/night)"
                : nextScene === "storm"
                    ? "Storm"
                    : nextScene === "day"
                        ? "Day"
                        : "Night";
            this.hud.appendLog?.(`Parallax scene set to ${label}.`);
        }
        if (typeof window !== "undefined" && window.localStorage && options.persist !== false) {
            writeParallaxScene(window.localStorage, nextScene);
        }
        this.syncParallaxSceneToHud();
        return changed;
    }
    shouldSkipTutorial() {
        if (typeof window === "undefined") {
            return false;
        }
        return readTutorialCompletion(window.localStorage, TUTORIAL_VERSION);
    }
    markTutorialComplete() {
        this.tutorialCompleted = true;
        if (typeof window === "undefined") {
            return;
        }
        writeTutorialCompletion(window.localStorage, TUTORIAL_VERSION);
    }
    clearTutorialProgress() {
        this.tutorialCompleted = false;
        if (typeof window === "undefined") {
            return;
        }
        clearTutorialCompletion(window.localStorage);
    }
    replayTutorialFromDebug() {
        if (!this.tutorialManager)
            return;
        this.clearTutorialProgress();
        this.startTutorial(true);
    }
    registerHudListeners() {
        const toGold = (value) => `${value > 0 ? "+" : ""}${value}g`;
        this.engine.events.on("enemy:spawned", (enemy) => {
            if (!enemy?.taunt) {
                return;
            }
            this.recordTauntAnalytics(enemy);
            const laneLabel = this.describeLane(enemy.lane);
            const enemyName = this.describeEnemyTier(enemy.tierId);
            this.hud.appendLog(`Taunt (${enemyName} - ${laneLabel}): ${enemy.taunt}`);
            const displayed = this.hud.announceEnemyTaunt(`${enemyName} • ${laneLabel}: ${enemy.taunt}`);
            if (!displayed) {
                this.hud.showCastleMessage(enemy.taunt);
            }
        });
        this.engine.events.on("hazard:started", ({ lane, kind, remaining, fireRateMultiplier }) => {
            const hazardName = typeof kind === "string" && kind.length > 0 ? this.describeEnemyTier(kind) : "Hazard";
            const laneLabel = this.describeLane(lane);
            const durationLabel = typeof remaining === "number" && Number.isFinite(remaining)
                ? `${remaining <= 9.95 ? remaining.toFixed(1) : Math.round(remaining)}s`
                : null;
            const fireRateEffect = typeof fireRateMultiplier === "number" &&
                Number.isFinite(fireRateMultiplier) &&
                fireRateMultiplier > 0
                ? (() => {
                    const deltaPercent = Math.round((fireRateMultiplier - 1) * 100);
                    if (deltaPercent === 0) {
                        return null;
                    }
                    const sign = deltaPercent > 0 ? "+" : "";
                    return `${sign}${deltaPercent}% turret fire rate`;
                })()
                : null;
            const detailParts = [durationLabel, fireRateEffect].filter((value) => value);
            const detail = detailParts.length > 0 ? ` (${detailParts.join(", ")})` : "";
            const message = `${hazardName} in ${laneLabel}${detail}`;
            this.hud.appendLog(message);
            this.hud.showCastleMessage(message);
        });
        this.engine.events.on("hazard:ended", ({ lane, kind }) => {
            const hazardName = typeof kind === "string" && kind.length > 0 ? this.describeEnemyTier(kind) : "Hazard";
            const laneLabel = this.describeLane(lane);
            this.hud.appendLog(`${hazardName} cleared from ${laneLabel}`);
        });
        this.engine.events.on("challenge:mistake-limit", ({ limit, errors }) => {
            const limitLabel = typeof limit === "number" && Number.isFinite(limit) ? limit : null;
            const errorsLabel = typeof errors === "number" && Number.isFinite(errors) ? errors : null;
            const detail = typeof errorsLabel === "number" && typeof limitLabel === "number"
                ? ` (${errorsLabel}/${limitLabel})`
                : "";
            const message = `Mistake limit reached${detail}!`;
            this.hud.appendLog(message);
            this.hud.showCastleMessage(message);
        });
        this.engine.events.on("enemy:defeated", ({ enemy, by, reward }) => {
            const source = by === "typing" ? "typed" : "turret";
            this.hud.appendLog(`Defeated ${enemy.word} (${source}) ${toGold(reward)}`);
            this.playSound(by === "typing" ? "impact-hit" : "projectile-arrow");
            this.triggerHaptics(by === "typing" ? [6, 10] : [8]);
            if (this.tutorialManager?.getState().active) {
                this.tutorialManager.notify({
                    type: "enemy:defeated",
                    payload: { enemyId: enemy.id }
                });
            }
        });
        this.engine.events.on("enemy:shield-broken", ({ enemy }) => {
            this.hud.appendLog(`Shield broken on ${enemy.word}!`);
            this.playSound("impact-hit", 60);
            if (this.tutorialManager?.getState().active) {
                this.tutorialManager.notify({
                    type: "enemy:shield-broken",
                    payload: { enemyId: enemy.id }
                });
            }
        });
        this.engine.events.on("enemy:escaped", ({ enemy }) => {
            this.hud.appendLog(`Enemy breached gates! -${enemy.damage} HP`, "breach");
            this.playSound("impact-breach");
            this.addImpactEffect(enemy.lane, 1, "breach");
            this.tutorialManager?.notify({ type: "castle:breach" });
        });
        this.engine.events.on("castle:damaged", ({ amount, health }) => {
            this.hud.appendLog(`Castle hit for ${amount} (HP ${Math.ceil(health)})`, "breach");
            this.triggerHaptics([0, 30]);
        });
        this.engine.events.on("castle:upgraded", ({ level }) => {
            this.hud.appendLog(`Castle upgraded to level ${level}`, "upgrade");
            this.playSound("upgrade");
        });
        this.engine.events.on("castle:passive-unlocked", ({ passive }) => {
            const description = this.describeCastlePassive(passive);
            this.hud.appendLog(`Passive unlocked: ${description}`, "upgrade");
            this.hud.showCastleMessage(description);
            this.playSound("upgrade", 48);
            this.tutorialManager?.notify({
                type: "castle:passive-unlocked",
                payload: { passive }
            });
        });
        this.engine.events.on("castle:repaired", ({ amount, health, cost }) => {
            const healed = Math.max(0, Math.round(amount ?? 0));
            const remaining = Math.max(0, Math.round(health ?? 0));
            const logPieces = [];
            if (healed > 0) {
                logPieces.push(`+${healed} HP`);
            }
            if (typeof cost === "number") {
                logPieces.push(toGold(-cost));
            }
            if (typeof health === "number") {
                logPieces.push(`HP ${remaining}`);
            }
            const detail = logPieces.length > 0 ? ` ${logPieces.join(" ")}` : "";
            this.hud.appendLog(`Castle repaired${detail}`, "upgrade");
            this.playSound("upgrade", 24);
        });
        this.engine.events.on("turret:placed", (slot) => {
            this.hud.appendLog(`Turret deployed in ${slot.id.toUpperCase()} (${slot.turret?.typeId ?? "unknown"})`, "upgrade");
            this.playSound("upgrade", 80);
        });
        this.engine.events.on("turret:upgraded", (slot) => {
            const turret = slot.turret;
            if (turret) {
                this.hud.appendLog(`Turret ${slot.id.toUpperCase()} -> Lv.${turret.level}`, "upgrade");
                this.playSound("upgrade", 120);
            }
        });
        this.engine.events.on("evac:start", ({ lane, word, duration }) => {
            const laneLabel = this.describeLane(lane);
            const label = word ? `"${word}"` : "transport";
            this.hud.appendLog(`Evacuation started in ${laneLabel} (${label})`);
            this.hud.showCastleMessage(`Evac in ${laneLabel} — ${Math.round(duration)}s`);
        });
        this.engine.events.on("evac:complete", ({ lane, word }) => {
            const laneLabel = this.describeLane(lane);
            const label = word ? `"${word}"` : "transport";
            this.hud.appendLog(`Evac secured in ${laneLabel} (${label}) +reward`);
            this.hud.showCastleMessage("Evacuation secured!");
            this.playSound("upgrade", 100);
        });
        this.engine.events.on("evac:fail", ({ lane, word }) => {
            const laneLabel = this.describeLane(lane);
            const label = word ? `"${word}"` : "transport";
            this.hud.appendLog(`Evac failed in ${laneLabel} (${label}) -penalty`);
            this.hud.showCastleMessage("Evacuation failed!");
            this.playSound("impact-breach", 90);
        });
        this.engine.events.on("projectile:impact", ({ projectile, enemyId }) => {
            if (enemyId) {
                this.hud.appendLog(`Hit confirmed from ${projectile.sourceSlotId.toUpperCase()}`);
                this.playSound("impact-hit");
                this.addImpactEffect(projectile.lane, projectile.position, "hit");
            }
            else {
                this.addImpactEffect(projectile.lane, projectile.position, "breach");
            }
        });
        this.engine.events.on("projectile:fired", (projectile) => {
            const key = `projectile-${projectile.kind}`;
            const detune = (Math.random() - 0.5) * 80;
            this.playSound(key, detune);
            if (projectile.sourceSlotId) {
                const state = this.engine.getState();
                const slot = state.turrets.find((entry) => entry.id === projectile.sourceSlotId);
                if (slot) {
                    const turretType = slot.turret?.typeId ?? null;
                    this.addImpactEffect(slot.lane, slot.position.x, "muzzle", {
                        slotId: slot.id,
                        turretType
                    });
                }
            }
        });
        this.engine.events.on("typing:progress", ({ enemyId, buffer }) => {
            const text = typeof buffer === "string" ? buffer.toLowerCase() : "";
            this.spacedRepetitionLastProgress = { enemyId: enemyId ?? null, buffer: text };
            if (!text)
                return;
            const lastChar = text.slice(-1);
            if (/^[a-z]$/.test(lastChar)) {
                const current = this.spacedRepetitionWaveStats?.keys?.[lastChar] ?? { attempts: 0, errors: 0 };
                current.attempts += 1;
                this.spacedRepetitionWaveStats.keys[lastChar] = current;
            }
            if (text.length >= 2) {
                const digraph = text.slice(-2);
                if (/^[a-z]{2}$/.test(digraph)) {
                    const current = this.spacedRepetitionWaveStats?.digraphs?.[digraph] ?? { attempts: 0, errors: 0 };
                    current.attempts += 1;
                    this.spacedRepetitionWaveStats.digraphs[digraph] = current;
                }
            }
        });
        this.engine.events.on("typing:perfect-word", ({ word }) => {
            this.hud.appendLog(`Perfect word: ${word.toUpperCase()}!`, "perfect");
        });
        this.engine.events.on("wave:bonus", ({ waveIndex, count, gold }) => {
            const bonusMessage = `Wave ${waveIndex + 1} bonus: ${count} perfect words (+${gold}g)`;
            this.hud.appendLog(bonusMessage);
            this.hud.showCastleMessage(`Bonus +${gold}g for ${count} perfect words!`);
        });
        this.engine.events.on("analytics:wave-summary", (summary) => {
            if (typeof window !== "undefined" && window.localStorage) {
                this.spacedRepetition = recordSpacedRepetitionObservedStats(this.spacedRepetition ?? readSpacedRepetitionState(window.localStorage), this.spacedRepetitionWaveStats ?? {}, { nowMs: Date.now() });
                this.spacedRepetition = writeSpacedRepetitionState(window.localStorage, this.spacedRepetition);
                this.spacedRepetitionWaveStats = { keys: {}, digraphs: {} };
                this.spacedRepetitionLastProgress = { enemyId: null, buffer: "" };
                this.syncErrorClustersToOverlay();
            }
            const nowMs = typeof performance !== "undefined" ? performance.now() : Date.now();
            const elapsedMs = Math.max(0, nowMs - this.sessionStartMs);
            const waveTimingSamples = Array.isArray(this.fatigueWaveTimingSamples)
                ? this.fatigueWaveTimingSamples.slice()
                : [];
            const waveTimingSummary = summarizeKeystrokeTimings(waveTimingSamples);
            const fatigueUpdate = updateFatigueDetector(this.fatigueDetectorState ?? createFatigueDetectorState(), {
                waveIndex: summary.index ?? 0,
                capturedAtMs: elapsedMs,
                accuracy: summary.accuracy,
                p50Ms: waveTimingSummary.p50Ms,
                p90Ms: waveTimingSummary.p90Ms
            });
            this.fatigueDetectorState = fatigueUpdate.state;
            this.fatigueWaveTimingSamples = [];
            const fatigueTip = fatigueUpdate.prompt?.message ?? null;
            const comboNote = `combo x${Math.max(0, summary.maxCombo ?? 0)}`;
            const goldNote = `${summary.goldEarned >= 0 ? "+" : ""}${Math.round(summary.goldEarned ?? 0)}g`;
            const turretDamage = Math.round(summary.turretDamage ?? 0);
            const typingDamage = Math.round(summary.typingDamage ?? 0);
            const damageNote = `dmg T/T ${turretDamage}/${typingDamage}`;
            const shieldNote = `shields ${Math.max(0, summary.shieldBreaks ?? 0)}`;
            const castleBonus = summary.castleBonusGold && summary.castleBonusGold > 0
                ? `castle +${Math.round(summary.castleBonusGold)}g`
                : null;
            const notes = [comboNote, goldNote, damageNote, shieldNote];
            if (castleBonus) {
                notes.push(castleBonus);
            }
            this.hud.appendLog(`Wave ${summary.index + 1} summary: ${summary.enemiesDefeated} defeats, ${(summary.accuracy * 100).toFixed(1)}% accuracy, ${summary.breaches} breaches, ${notes.join(", ")}`);
            this.render();
            this.presentWaveScorecard(summary, { tipOverride: fatigueTip });
            this.unlockLoreForWave(summary.index + 1);
        });
        this.engine.events.on("typing:error", ({ enemyId, expected, received, totalErrors }) => {
            this.hud.showTypingErrorHint({
                enemyId: enemyId ?? null,
                expected: expected ?? null,
                received: received ?? null
            });
            const expectedLetter = typeof expected === "string" && expected.length === 1 ? expected.toLowerCase() : null;
            if (expectedLetter && /^[a-z]$/.test(expectedLetter)) {
                const current = this.spacedRepetitionWaveStats?.keys?.[expectedLetter] ?? { attempts: 0, errors: 0 };
                current.attempts += 1;
                current.errors += 1;
                this.spacedRepetitionWaveStats.keys[expectedLetter] = current;
                const lastProgress = this.spacedRepetitionLastProgress ?? null;
                const lastBuffer = lastProgress && lastProgress.enemyId === enemyId && typeof lastProgress.buffer === "string"
                    ? lastProgress.buffer
                    : "";
                const prevChar = lastBuffer.length > 0 ? lastBuffer.slice(-1) : "";
                if (/^[a-z]$/.test(prevChar)) {
                    const digraph = `${prevChar}${expectedLetter}`;
                    const currentDigraph = this.spacedRepetitionWaveStats?.digraphs?.[digraph] ?? { attempts: 0, errors: 0 };
                    currentDigraph.attempts += 1;
                    currentDigraph.errors += 1;
                    this.spacedRepetitionWaveStats.digraphs[digraph] = currentDigraph;
                }
            }
            const errorClusterStorage = typeof window !== "undefined" ? window.localStorage : null;
            this.errorClusterProgress =
                this.errorClusterProgress ?? readErrorClusterProgress(errorClusterStorage);
            this.errorClusterProgress = recordErrorClusterEntry(this.errorClusterProgress, {
                expected,
                received,
                timestamp: Date.now()
            });
            const nowWallMs = Date.now();
            const lastSavedAt = typeof this.errorClusterLastSavedAt === "number" ? this.errorClusterLastSavedAt : 0;
            if (!lastSavedAt || nowWallMs - lastSavedAt > 1250) {
                writeErrorClusterProgress(errorClusterStorage, this.errorClusterProgress);
                this.errorClusterLastSavedAt = nowWallMs;
            }
            this.syncErrorClustersToOverlay();
            this.stuckKeyDetector = this.stuckKeyDetector ?? createStuckKeyDetectorState();
            const nowMs = typeof performance !== "undefined" ? performance.now() : Date.now();
            const anomaly = updateStuckKeyDetector(this.stuckKeyDetector, { expected, received }, nowMs);
            this.stuckKeyDetector = anomaly.state;
            if (anomaly.warning?.kind === "stuck-key") {
                const keyLabel = anomaly.warning.key === " "
                    ? "Space"
                    : anomaly.warning.key.length === 1
                        ? anomaly.warning.key.toUpperCase()
                        : anomaly.warning.key;
                const message = `Seeing lots of "${keyLabel}" presses. If a key is stuck, try tapping it once or using a different keyboard.`;
                this.hud.appendLog(message);
                this.hud.showCastleMessage(message);
            }
            if (this.tutorialManager?.getState().active) {
                this.tutorialManager.notify({
                    type: "typing:error",
                    payload: { enemyId: enemyId ?? null, expected: expected ?? null, received, totalErrors }
                });
            }
            const context = this.lastTypingInputContext;
            const comboBefore = context && typeof context.comboBefore === "number" && Number.isFinite(context.comboBefore)
                ? context.comboBefore
                : 0;
            this.maybeStartTypoRecoveryChallenge({ comboBefore });
        });
    }
    describeCastlePassive(passive) {
        if (!passive) {
            return "Castle passive unlocked";
        }
        switch (passive.id) {
            case "regen":
                return `Regen ${passive.total.toFixed(1)} HP/s`;
            case "armor":
                return `+${passive.total.toFixed(0)} armor`;
            case "gold":
                return `+${Math.round(passive.total * 100)}% gold from rewards`;
            default:
                return "Castle passive unlocked";
        }
    }
    describeLane(lane) {
        const token = this.getLaneLabelToken(lane);
        return `Lane ${token}`;
    }
    getLaneLabelToken(lane) {
        if (Number.isInteger(lane) && lane >= 0 && lane < LANE_LABELS.length) {
            return LANE_LABELS[lane];
        }
        if (Number.isFinite(lane)) {
            return String(lane + 1);
        }
        return "?";
    }
    describeEnemyTier(tierId) {
        if (!tierId) {
            return "Enemy";
        }
        return tierId
            .split(/[-_]/g)
            .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
            .join(" ");
    }
    playSound(key, detune = 0) {
        if (!this.soundManager)
            return;
        void this.soundManager.ensureInitialized().then(() => {
            this.soundManager?.play(key, detune);
        });
    }
    triggerHaptics(pattern) {
        if (!this.hapticsEnabled)
            return;
        try {
            if (typeof navigator !== "undefined" && typeof navigator.vibrate === "function") {
                navigator.vibrate(pattern);
            }
        }
        catch {
            // ignore unsupported vibration calls
        }
    }
    collectImpactEffects() {
        if (!this.currentState)
            return [];
        const now = this.currentState.time;
        const MAX_LIFETIME = 0.45;
        this.impactEffects = this.impactEffects.filter((effect) => now - effect.createdAt <= MAX_LIFETIME);
        return this.impactEffects.map((effect) => ({
            lane: effect.lane ?? null,
            position: effect.position,
            kind: effect.kind,
            slotId: effect.slotId ?? null,
            turretType: effect.turretType ?? null,
            age: Math.min(1, Math.max(0, (now - effect.createdAt) / MAX_LIFETIME))
        }));
    }
    addImpactEffect(lane, position, kind, extras = {}) {
        if (this.reducedMotionEnabled) {
            return;
        }
        this.enqueueScreenShake(kind);
        const createdAt = this.currentState?.time ?? this.engine.getState().time ?? 0;
        this.impactEffects.push({
            lane,
            position,
            kind,
            slotId: extras.slotId ?? null,
            turretType: extras.turretType ?? null,
            createdAt
        });
    }
    attachCanvasResizeObserver() {
        if (typeof window === "undefined" || !this.canvas) {
            return;
        }
        const target = this.canvas.parentElement ?? this.canvas;
        if (typeof ResizeObserver !== "undefined") {
            this.canvasResizeObserver = new ResizeObserver(() => this.updateCanvasResolution(false, "resize-observer"));
            this.canvasResizeObserver.observe(target);
        }
        else {
            this.viewportResizeHandler = () => this.updateCanvasResolution(false, "viewport");
            window.addEventListener("resize", this.viewportResizeHandler);
        }
    }
    attachDevicePixelRatioListener() {
        if (typeof window === "undefined") {
            return;
        }
        this.detachDevicePixelRatioListener();
        const handle = createDprListener({
            getCurrent: () => this.readWindowDevicePixelRatio(),
            onChange: (event) => this.handleDevicePixelRatioChange(event)
        });
        this.dprListener = handle;
        handle.start();
        this.currentDevicePixelRatio = handle.getCurrent();
    }
    detachDevicePixelRatioListener() {
        if (this.dprListener) {
            try {
                this.dprListener.stop();
            }
            catch {
                // ignore cleanup failures
            }
            this.dprListener = null;
        }
    }
    handleDevicePixelRatioChange(event) {
        this.currentDevicePixelRatio = event.next;
        const cause = event.cause === "manual"
            ? "device-pixel-ratio-manual"
            : event.cause === "simulate"
                ? "device-pixel-ratio-simulated"
                : "device-pixel-ratio";
        this.updateCanvasResolution(true, cause);
    }
    updateCanvasResolution(force = false, cause = "auto") {
        if (!this.canvas)
            return;
        const resolution = this.computeCanvasResolution();
        if (!resolution)
            return;
        const changed = force ||
            !this.canvasResolution ||
            this.canvasResolution.renderWidth !== resolution.renderWidth ||
            this.canvasResolution.renderHeight !== resolution.renderHeight;
        if (!changed) {
            return;
        }
        const shouldAnimate = !this.reducedMotionEnabled && Boolean(this.canvasResolution);
        const bounds = shouldAnimate && typeof this.canvas.getBoundingClientRect === "function"
            ? this.canvas.getBoundingClientRect()
            : null;
        if (shouldAnimate) {
            this.resolutionTransitionController?.trigger(bounds);
        }
        this.canvasResolution = resolution;
        this.canvas.width = resolution.renderWidth;
        this.canvas.height = resolution.renderHeight;
        this.canvas.style.width = `${resolution.cssWidth}px`;
        this.canvas.style.height = `${resolution.cssHeight}px`;
        this.renderer?.resize(resolution.renderWidth, resolution.renderHeight, { cause });
        this.triggerCanvasResizeFade();
        const transitionDuration = shouldAnimate
            ? this.resolutionTransitionController?.getDuration() ?? CANVAS_RESIZE_FADE_MS
            : 0;
        this.recordCanvasResolutionChange(resolution, cause, transitionDuration);
    }
    computeCanvasResolution() {
        const availableWidth = this.measureCanvasAvailableWidth();
        const availableHeight = this.measureCanvasAvailableHeight();
        if (!availableWidth || !Number.isFinite(availableWidth)) {
            return {
                cssWidth: CANVAS_BASE_WIDTH,
                cssHeight: CANVAS_BASE_HEIGHT,
                renderWidth: CANVAS_BASE_WIDTH,
                renderHeight: CANVAS_BASE_HEIGHT
            };
        }
        const devicePixelRatio = this.dprListener?.getCurrent?.() ?? this.readWindowDevicePixelRatio();
        return calculateCanvasResolution({
            baseWidth: CANVAS_BASE_WIDTH,
            baseHeight: CANVAS_BASE_HEIGHT,
            availableWidth,
            availableHeight,
            devicePixelRatio
        });
    }
    getDevicePixelRatio() {
        if (this.dprListener && typeof this.dprListener.getCurrent === "function") {
            const ratio = this.dprListener.getCurrent();
            if (Number.isFinite(ratio) && ratio > 0) {
                return ratio;
            }
        }
        return this.readWindowDevicePixelRatio();
    }
    readWindowDevicePixelRatio() {
        if (typeof window === "undefined" || typeof window.devicePixelRatio !== "number") {
            return 1;
        }
        const ratio = Number(window.devicePixelRatio);
        if (!Number.isFinite(ratio) || ratio <= 0) {
            return 1;
        }
        return Math.round(ratio * 100) / 100;
    }
    recordCanvasResolutionChange(resolution, cause = "auto", transitionMs = CANVAS_RESIZE_FADE_MS) {
        if (typeof window === "undefined" || !resolution) {
            return;
        }
        const nextDpr = this.getDevicePixelRatio();
        const hudState = this.hud?.getCondensedState?.() ?? null;
        const prefersCondensed = typeof hudState?.prefersCondensedLists === "boolean"
            ? hudState.prefersCondensedLists
            : null;
        const hudLayout = prefersCondensed === null ? null : prefersCondensed ? "condensed" : "stacked";
        const entry = buildResolutionChangeEntry({
            resolution,
            cause,
            previousDpr: typeof this.currentDevicePixelRatio === "number"
                ? this.currentDevicePixelRatio
                : nextDpr,
            nextDpr,
            transitionMs,
            prefersCondensedHud: prefersCondensed,
            hudLayout
        });
        this.canvasResolutionEvents.push(entry);
        if (this.canvasResolutionEvents.length > MAX_CANVAS_RESOLUTION_EVENTS) {
            this.canvasResolutionEvents.splice(0, this.canvasResolutionEvents.length - MAX_CANVAS_RESOLUTION_EVENTS);
        }
        this.currentDevicePixelRatio = nextDpr;
        this.persistResolutionPreferences(nextDpr, hudLayout);
        if (this.telemetryClient && typeof this.telemetryClient.track === "function") {
            this.telemetryClient.track("ui.canvasResolutionChanged", { ...entry });
        }
    }
    persistResolutionPreferences(devicePixelRatio, hudLayout) {
        if (!this.playerSettings) {
            return;
        }
        const patch = {};
        let changed = false;
        if (Number.isFinite(devicePixelRatio) && devicePixelRatio > 0) {
            const normalized = Math.round(devicePixelRatio * 100) / 100;
            if (this.playerSettings.lastDevicePixelRatio !== normalized) {
                patch.lastDevicePixelRatio = normalized;
                changed = true;
            }
        }
        if (hudLayout === "stacked" || hudLayout === "condensed") {
            if (this.playerSettings.lastHudLayout !== hudLayout) {
                patch.lastHudLayout = hudLayout;
                changed = true;
            }
        }
        if (changed) {
            this.persistPlayerSettings(patch);
        }
    }
    handleCanvasTransitionStateChange(state) {
        if (typeof document !== "undefined" && document.body) {
            document.body.dataset.canvasTransition = state;
        }
        this.hud?.setCanvasTransitionState?.(state);
        this.diagnostics?.setCanvasTransitionState?.(state);
    }
    measureCanvasAvailableWidth() {
        if (!this.canvas) {
            return CANVAS_BASE_WIDTH;
        }
        const parent = this.canvas.parentElement;
        if (parent) {
            const parentWidth = parent.clientWidth;
            if (parentWidth > 0) {
                return parentWidth;
            }
            const rect = parent.getBoundingClientRect?.();
            if (rect && rect.width > 0) {
                return rect.width;
            }
        }
        const canvasRect = this.canvas.getBoundingClientRect?.();
        if (canvasRect && canvasRect.width > 0) {
            return canvasRect.width;
        }
        if (typeof window !== "undefined" && window.innerWidth > 0) {
            return Math.min(window.innerWidth - 32, CANVAS_BASE_WIDTH);
        }
        if (typeof document !== "undefined") {
            const docWidth = document.documentElement?.clientWidth ?? 0;
            if (docWidth > 0) {
                return Math.min(docWidth - 32, CANVAS_BASE_WIDTH);
            }
        }
        return CANVAS_BASE_WIDTH;
    }
    measureCanvasAvailableHeight() {
        if (typeof document === "undefined") {
            return CANVAS_BASE_HEIGHT;
        }
        const shell = document.getElementById("playfield-shell");
        if (!shell) {
            if (typeof window !== "undefined" && window.innerHeight > 0) {
                return Math.max(1, Math.min(window.innerHeight - 200, CANVAS_BASE_HEIGHT));
            }
            return CANVAS_BASE_HEIGHT;
        }
        const shellHeight = shell.clientHeight > 0 ? shell.clientHeight : shell.getBoundingClientRect?.().height ?? 0;
        if (!Number.isFinite(shellHeight) || shellHeight <= 0) {
            return CANVAS_BASE_HEIGHT;
        }
        const topbar = shell.querySelector(".playfield-topbar");
        const footer = shell.querySelector(".playfield-footer");
        const topbarHeight = topbar instanceof HTMLElement ? topbar.offsetHeight : 0;
        const footerHeight = footer instanceof HTMLElement ? footer.offsetHeight : 0;
        let rowGap = 0;
        if (typeof window !== "undefined" && typeof window.getComputedStyle === "function") {
            try {
                const styles = window.getComputedStyle(shell);
                const raw = styles.rowGap || styles.gap;
                const parsed = typeof raw === "string" ? Number.parseFloat(raw) : 0;
                rowGap = Number.isFinite(parsed) ? parsed : 0;
            }
            catch {
                rowGap = 0;
            }
        }
        const reserved = topbarHeight + footerHeight + rowGap * 2;
        const available = Math.max(1, Math.floor(shellHeight - reserved));
        return available;
    }
    triggerCanvasResizeFade() {
        if (typeof window === "undefined" || !this.canvas || this.reducedMotionEnabled) {
            return;
        }
        this.canvas.dataset.resizing = "true";
        if (this.canvasResizeTimeout) {
            window.clearTimeout(this.canvasResizeTimeout);
        }
        this.canvasResizeTimeout = window.setTimeout(() => {
            if (this.canvas) {
                delete this.canvas.dataset.resizing;
            }
            this.canvasResizeTimeout = null;
        }, CANVAS_RESIZE_FADE_MS);
    }
    attachLatencyIndicator() {
        if (typeof document === "undefined")
            return;
        const container = document.getElementById("latency-indicator");
        const value = document.getElementById("latency-value");
        const sparkline = document.getElementById("latency-sparkline-path");
        const sparklineSvg = document.getElementById("latency-sparkline");
        if (!(container instanceof HTMLElement) || !(value instanceof HTMLElement)) {
            return;
        }
        this.latencyIndicator = {
            container,
            value,
            sparkline: sparkline instanceof SVGPolylineElement ? sparkline : null,
            sparklineWrapper: sparklineSvg instanceof SVGSVGElement ? sparklineSvg : null
        };
        this.latencySamples = [];
        this.updateLatencyIndicator(0);
        this.startLatencyMonitor();
    }
    startLatencyMonitor() {
        if (!this.latencyIndicator || this.latencyMonitorTimeout || typeof window === "undefined") {
            return;
        }
        const interval = INPUT_LATENCY_SAMPLE_MS;
        let expected = (typeof performance !== "undefined" ? performance.now() : Date.now()) + interval;
        const sample = () => {
            const now = typeof performance !== "undefined" ? performance.now() : Date.now();
            const drift = Math.max(0, now - expected);
            expected = now + interval;
            this.recordLatencySample(drift);
            this.latencyMonitorTimeout = window.setTimeout(sample, interval);
        };
        this.latencyMonitorTimeout = window.setTimeout(sample, interval);
    }
    recordLatencySample(value) {
        if (!Array.isArray(this.latencySamples)) {
            this.latencySamples = [];
        }
        this.latencySamples.push(value);
        if (this.latencySamples.length > INPUT_LATENCY_WINDOW) {
            this.latencySamples.shift();
        }
        const sum = this.latencySamples.reduce((acc, entry) => acc + entry, 0);
        const avg = this.latencySamples.length > 0 ? sum / this.latencySamples.length : value;
        this.updateLatencyIndicator(avg);
    }
    updateLatencyIndicator(averageMs) {
        if (!this.latencyIndicator)
            return;
        const severity = averageMs >= INPUT_LATENCY_BAD_MS
            ? "bad"
            : averageMs >= INPUT_LATENCY_WARN_MS
                ? "warn"
                : "good";
        this.latencyIndicator.container.dataset.state = severity;
        const rounded = Math.max(0, Math.round(averageMs));
        this.latencyIndicator.value.textContent = `${rounded}ms`;
        this.latencyIndicator.container.setAttribute("aria-label", `Input latency ${rounded} milliseconds, ${severity}`);
        this.updateLatencySparklineVisibility();
    }
    updateLatencySparkline() {
        if (!this.latencyIndicator?.sparkline || !this.isLatencySparklineVisible())
            return;
        const samples = Array.isArray(this.latencySamples) ? this.latencySamples.slice(-INPUT_LATENCY_WINDOW) : [];
        const width = INPUT_LATENCY_SPARKLINE_WIDTH;
        const height = INPUT_LATENCY_SPARKLINE_HEIGHT;
        if (!samples.length) {
            this.latencyIndicator.sparkline.setAttribute("points", `0,${height} ${width},${height}`);
            return;
        }
        const maxSamples = Math.max(1, samples.length - 1);
        const points = samples.map((value, index) => {
            const x = maxSamples === 0 ? width : (index / maxSamples) * width;
            const clamped = Math.min(INPUT_LATENCY_SPARKLINE_CAP_MS, Math.max(0, value));
            const y = height - (clamped / INPUT_LATENCY_SPARKLINE_CAP_MS) * height;
            return `${x.toFixed(1)},${y.toFixed(1)}`;
        });
        if (points.length === 1) {
            points.unshift(`0,${height}`);
        }
        this.latencyIndicator.sparkline.setAttribute("points", points.join(" "));
    }
    updateLatencySparklineVisibility() {
        if (!this.latencyIndicator?.sparklineWrapper) {
            this.updateLatencySparkline();
            return;
        }
        const visible = this.isLatencySparklineVisible();
        this.latencyIndicator.sparklineWrapper.style.display = visible ? "" : "none";
        this.latencyIndicator.sparklineWrapper.setAttribute("aria-hidden", visible ? "false" : "true");
        if (visible) {
            this.updateLatencySparkline();
        }
        else if (this.latencyIndicator.sparkline) {
            const height = INPUT_LATENCY_SPARKLINE_HEIGHT;
            const width = INPUT_LATENCY_SPARKLINE_WIDTH;
            this.latencyIndicator.sparkline.setAttribute("points", `0,${height} ${width},${height}`);
        }
    }
    isLatencySparklineVisible() {
        const compact = typeof document !== "undefined" &&
            typeof document.body !== "undefined" &&
            document.body.dataset.compactHeight === "true";
        return this.latencySparklineEnabled && !this.reducedMotionEnabled && !compact;
    }
    loadLatencySparklineEnabled() {
        if (typeof window === "undefined" || !window.localStorage)
            return true;
        try {
            const raw = window.localStorage.getItem(LATENCY_SPARKLINE_KEY);
            if (raw === "false")
                return false;
            if (raw === "true")
                return true;
            return true;
        }
        catch {
            return true;
        }
    }
    persistLatencySparklineEnabled(enabled) {
        this.persistPlayerSettings({ latencySparklineEnabled: enabled });
        this.persistLegacyLatencySparklineEnabled(enabled);
    }
    persistLegacyLatencySparklineEnabled(enabled) {
        if (typeof window === "undefined" || !window.localStorage)
            return;
        try {
            window.localStorage.setItem(LATENCY_SPARKLINE_KEY, enabled ? "true" : "false");
        }
        catch {
            // ignore storage failures
        }
    }
    setLatencySparklineEnabled(enabled, options = {}) {
        const next = Boolean(enabled);
        if (this.latencySparklineEnabled === next && options.force !== true) {
            return;
        }
        this.latencySparklineEnabled = next;
        if (this.playerSettings) {
            this.playerSettings.latencySparklineEnabled = next;
        }
        this.updateLatencySparklineVisibility();
        this.updateOptionsOverlayState();
        if (!options.silent) {
            this.hud?.appendLog?.(`Latency sparkline ${next ? "shown" : "hidden"}.`);
        }
        if (options.persist !== false) {
            this.persistLatencySparklineEnabled(next);
        }
    }
    loadHudVisibilityPrefs() {
        const defaults = { metrics: true, battleLog: true, wavePreview: true };
        if (typeof window === "undefined" || !window.localStorage) {
            return defaults;
        }
        try {
            const raw = window.localStorage.getItem(HUD_VISIBILITY_KEY);
            if (!raw)
                return defaults;
            const parsed = JSON.parse(raw);
            return {
                metrics: parsed?.metrics !== false,
                battleLog: parsed?.battleLog !== false,
                wavePreview: parsed?.wavePreview !== false
            };
        }
        catch {
            return defaults;
        }
    }
    persistHudVisibilityPrefs(prefs) {
        this.hudVisibility = {
            metrics: prefs.metrics !== false,
            battleLog: prefs.battleLog !== false,
            wavePreview: prefs.wavePreview !== false
        };
        if (typeof window === "undefined" || !window.localStorage) {
            return;
        }
        try {
            window.localStorage.setItem(HUD_VISIBILITY_KEY, JSON.stringify(this.hudVisibility));
        }
        catch {
            // best effort
        }
    }
    loadWavePreviewThreatIndicatorsEnabled() {
        if (typeof window === "undefined" || !window.localStorage) {
            return false;
        }
        try {
            const raw = window.localStorage.getItem(WAVE_PREVIEW_THREAT_KEY);
            if (!raw)
                return false;
            return raw === "true" || raw === "1" || raw === "enabled";
        }
        catch {
            return false;
        }
    }
    persistWavePreviewThreatIndicatorsEnabled(enabled) {
        if (typeof window === "undefined" || !window.localStorage) {
            return;
        }
        try {
            window.localStorage.setItem(WAVE_PREVIEW_THREAT_KEY, enabled ? "true" : "false");
        }
        catch {
            // best effort
        }
    }
    setWavePreviewThreatIndicatorsEnabled(enabled, options = {}) {
        const next = Boolean(enabled);
        if (this.wavePreviewThreatIndicatorsEnabled === next && options.force !== true) {
            return;
        }
        this.wavePreviewThreatIndicatorsEnabled = next;
        if (typeof this.hud?.setWavePreviewThreatIndicatorsEnabled === "function") {
            this.hud.setWavePreviewThreatIndicatorsEnabled(next);
        }
        this.syncHudVisibilityToggles();
        if (!options.silent) {
            this.hud?.appendLog?.(`Wave preview threat indicators ${next ? "enabled" : "disabled"}.`);
        }
        if (options.persist !== false) {
            this.persistWavePreviewThreatIndicatorsEnabled(next);
        }
    }
    attachHudVisibilityToggles() {
        if (typeof document === "undefined")
            return;
        const metricsToggle = document.getElementById("options-toggle-metrics");
        const wavePreviewToggle = document.getElementById("options-toggle-wave-preview");
        const wavePreviewThreatToggle = document.getElementById("options-toggle-wave-preview-threat");
        const battleLogToggle = document.getElementById("options-toggle-battle-log");
        const applyState = () => {
            this.applyHudVisibility();
            this.syncHudVisibilityToggles();
            this.persistHudVisibilityPrefs(this.hudVisibility ?? { metrics: true, battleLog: true, wavePreview: true });
        };
        if (metricsToggle instanceof HTMLInputElement) {
            metricsToggle.checked = this.hudVisibility.metrics;
            metricsToggle.addEventListener("change", () => {
                this.hudVisibility.metrics = Boolean(metricsToggle.checked);
                applyState();
            });
        }
        if (wavePreviewToggle instanceof HTMLInputElement) {
            wavePreviewToggle.checked = this.hudVisibility.wavePreview;
            wavePreviewToggle.addEventListener("change", () => {
                this.hudVisibility.wavePreview = Boolean(wavePreviewToggle.checked);
                applyState();
            });
        }
        if (battleLogToggle instanceof HTMLInputElement) {
            battleLogToggle.checked = this.hudVisibility.battleLog;
            battleLogToggle.addEventListener("change", () => {
                this.hudVisibility.battleLog = Boolean(battleLogToggle.checked);
                applyState();
            });
        }
        if (wavePreviewThreatToggle instanceof HTMLInputElement) {
            wavePreviewThreatToggle.checked = this.wavePreviewThreatIndicatorsEnabled;
            wavePreviewThreatToggle.addEventListener("change", () => {
                this.setWavePreviewThreatIndicatorsEnabled(Boolean(wavePreviewThreatToggle.checked));
            });
        }
        this.applyHudVisibility();
        this.syncHudVisibilityToggles();
        if (typeof this.hud?.setWavePreviewThreatIndicatorsEnabled === "function") {
            this.hud.setWavePreviewThreatIndicatorsEnabled(this.wavePreviewThreatIndicatorsEnabled);
        }
    }
    syncHudVisibilityToggles() {
        if (typeof document === "undefined")
            return;
        const metricsToggle = document.getElementById("options-toggle-metrics");
        const wavePreviewToggle = document.getElementById("options-toggle-wave-preview");
        const wavePreviewThreatToggle = document.getElementById("options-toggle-wave-preview-threat");
        const battleLogToggle = document.getElementById("options-toggle-battle-log");
        const reduced = this.reducedCognitiveLoadEnabled;
        const prefs = this.hudVisibility ?? { metrics: true, battleLog: true, wavePreview: true };
        const disabledTitle = reduced
            ? "Disabled while Reduced Cognitive Load is on"
            : "";
        if (metricsToggle instanceof HTMLInputElement) {
            metricsToggle.checked = reduced ? false : prefs.metrics;
            metricsToggle.disabled = reduced;
            metricsToggle.setAttribute("aria-disabled", reduced ? "true" : "false");
            metricsToggle.title = disabledTitle;
        }
        if (wavePreviewToggle instanceof HTMLInputElement) {
            wavePreviewToggle.checked = reduced ? false : prefs.wavePreview;
            wavePreviewToggle.disabled = reduced;
            wavePreviewToggle.setAttribute("aria-disabled", reduced ? "true" : "false");
            wavePreviewToggle.title = disabledTitle;
        }
        if (wavePreviewThreatToggle instanceof HTMLInputElement) {
            wavePreviewThreatToggle.checked = reduced ? false : this.wavePreviewThreatIndicatorsEnabled;
            wavePreviewThreatToggle.disabled = reduced;
            wavePreviewThreatToggle.setAttribute("aria-disabled", reduced ? "true" : "false");
            wavePreviewThreatToggle.title = disabledTitle;
        }
        if (battleLogToggle instanceof HTMLInputElement) {
            battleLogToggle.checked = reduced ? false : prefs.battleLog;
            battleLogToggle.disabled = reduced;
            battleLogToggle.setAttribute("aria-disabled", reduced ? "true" : "false");
            battleLogToggle.title = disabledTitle;
        }
    }
    applyHudVisibility() {
        if (typeof document === "undefined")
            return;
        const metrics = document.getElementById("typing-metrics");
        const wavePreview = document.querySelector(".wave-preview");
        const battleLog = document.querySelector(".events");
        const prefs = this.hudVisibility ?? { metrics: true, battleLog: true, wavePreview: true };
        const reduced = this.reducedCognitiveLoadEnabled;
        const effectivePrefs = {
            metrics: !reduced && prefs.metrics,
            wavePreview: !reduced && prefs.wavePreview,
            battleLog: !reduced && prefs.battleLog
        };
        if (metrics instanceof HTMLElement) {
            metrics.dataset.hidden = effectivePrefs.metrics ? "false" : "true";
            metrics.setAttribute("aria-hidden", effectivePrefs.metrics ? "false" : "true");
        }
        if (wavePreview instanceof HTMLElement) {
            wavePreview.dataset.hidden = effectivePrefs.wavePreview ? "false" : "true";
            wavePreview.setAttribute("aria-hidden", effectivePrefs.wavePreview ? "false" : "true");
        }
        if (battleLog instanceof HTMLElement) {
            battleLog.dataset.hidden = effectivePrefs.battleLog ? "false" : "true";
            battleLog.setAttribute("aria-hidden", effectivePrefs.battleLog ? "false" : "true");
        }
    }
    loadHotkeys() {
        const defaults = { pause: "p", shortcuts: "?" };
        if (typeof window === "undefined" || !window.localStorage)
            return defaults;
        try {
            const raw = window.localStorage.getItem(HOTKEY_STORAGE_KEY);
            if (!raw)
                return defaults;
            const parsed = JSON.parse(raw);
            const pause = typeof parsed.pause === "string" ? parsed.pause.toLowerCase() : defaults.pause;
            const shortcuts = typeof parsed.shortcuts === "string" ? parsed.shortcuts.toLowerCase() : defaults.shortcuts;
            return { pause, shortcuts };
        }
        catch {
            return defaults;
        }
    }
    persistHotkeys(hotkeys) {
        this.hotkeys = {
            pause: typeof hotkeys.pause === "string" ? hotkeys.pause.toLowerCase() : "p",
            shortcuts: typeof hotkeys.shortcuts === "string" ? hotkeys.shortcuts.toLowerCase() : "?"
        };
        if (typeof window === "undefined" || !window.localStorage)
            return;
        try {
            window.localStorage.setItem(HOTKEY_STORAGE_KEY, JSON.stringify(this.hotkeys));
        }
        catch {
            // best effort
        }
    }
    attachHotkeyControls() {
        if (typeof document === "undefined")
            return;
        const pauseSelect = document.getElementById("options-hotkey-pause");
        const shortcutsSelect = document.getElementById("options-hotkey-shortcuts");
        const apply = () => {
            const pauseValue = pauseSelect instanceof HTMLSelectElement ? pauseSelect.value.toLowerCase() : "p";
            const shortcutsValue = shortcutsSelect instanceof HTMLSelectElement ? shortcutsSelect.value.toLowerCase() : "?";
            this.persistHotkeys({ pause: pauseValue, shortcuts: shortcutsValue });
            this.syncHotkeyControls();
        };
        if (pauseSelect instanceof HTMLSelectElement) {
            pauseSelect.value = this.hotkeys.pause;
            pauseSelect.addEventListener("change", apply);
        }
        if (shortcutsSelect instanceof HTMLSelectElement) {
            shortcutsSelect.value = this.hotkeys.shortcuts;
            shortcutsSelect.addEventListener("change", apply);
        }
    }
    syncHotkeyControls() {
        if (typeof document === "undefined")
            return;
        const pauseSelect = document.getElementById("options-hotkey-pause");
        const shortcutsSelect = document.getElementById("options-hotkey-shortcuts");
        if (pauseSelect instanceof HTMLSelectElement) {
            pauseSelect.value = this.hotkeys.pause;
        }
        if (shortcutsSelect instanceof HTMLSelectElement) {
            shortcutsSelect.value = this.hotkeys.shortcuts;
        }
    }
    loadColorblindMode() {
        if (typeof window === "undefined" || !window.localStorage) {
            return "off";
        }
        try {
            const raw = window.localStorage.getItem(COLORBLIND_MODE_KEY);
            if (!raw)
                return "off";
            return this.normalizeColorblindMode(raw);
        }
        catch {
            return "off";
        }
    }
    persistColorblindMode(mode) {
        if (typeof window === "undefined" || !window.localStorage) {
            return;
        }
        try {
            window.localStorage.setItem(COLORBLIND_MODE_KEY, mode);
        }
        catch {
            // best effort
        }
    }
    loadContextualHintsSeen() {
        if (typeof window === "undefined" || !window.localStorage) {
            return new Set();
        }
        try {
            const raw = window.localStorage.getItem(CONTEXTUAL_HINTS_KEY);
            if (!raw)
                return new Set();
            const parsed = JSON.parse(raw);
            if (Array.isArray(parsed)) {
                return new Set(parsed.filter((id) => typeof id === "string" && id.length > 0));
            }
            return new Set();
        }
        catch {
            return new Set();
        }
    }
    persistContextualHintsSeen() {
        if (typeof window === "undefined" || !window.localStorage) {
            return;
        }
        try {
            window.localStorage.setItem(CONTEXTUAL_HINTS_KEY, JSON.stringify(Array.from(this.contextualHintsSeen)));
        }
        catch {
            // best effort
        }
    }
    attachContextualHints() {
        if (typeof document === "undefined")
            return;
        const hintIds = [
            { id: "hint-typing-drills", key: "typing-drills" },
            { id: "hint-wave-preview", key: "wave-preview" },
            { id: "hint-battle-log", key: "battle-log" }
        ];
        for (const hint of hintIds) {
            const el = document.getElementById(hint.id);
            const closeBtn = el?.querySelector?.(".contextual-hint-close");
            if (!(el instanceof HTMLElement) || !(closeBtn instanceof HTMLButtonElement)) {
                continue;
            }
            const dismiss = () => {
                el.dataset.visible = "false";
                el.setAttribute("aria-hidden", "true");
                this.contextualHintsSeen.add(hint.key);
                this.persistContextualHintsSeen();
            };
            closeBtn.addEventListener("click", dismiss);
            el.addEventListener("click", (event) => {
                if (event.target === el)
                    dismiss();
            });
            if (!this.contextualHintsSeen.has(hint.key)) {
                el.dataset.visible = "true";
                el.setAttribute("aria-hidden", "false");
            }
            else {
                el.dataset.visible = "false";
                el.setAttribute("aria-hidden", "true");
            }
        }
    }
    loadAccessibilitySeen() {
        if (typeof window === "undefined" || !window.localStorage) {
            return false;
        }
        try {
            return window.localStorage.getItem(ACCESSIBILITY_ONBOARDING_KEY) === "seen";
        }
        catch {
            return false;
        }
    }
    persistAccessibilitySeen() {
        this.accessibilityOnboardingSeen = true;
        if (typeof window === "undefined" || !window.localStorage) {
            return;
        }
        try {
            window.localStorage.setItem(ACCESSIBILITY_ONBOARDING_KEY, "seen");
        }
        catch {
            // best effort
        }
    }
    attachAccessibilityOnboarding() {
        if (typeof document === "undefined")
            return;
        const container = document.getElementById("accessibility-onboarding");
        const closeButton = document.getElementById("accessibility-onboarding-close");
        const skipButton = document.getElementById("accessibility-skip");
        const applyButton = document.getElementById("accessibility-apply");
        const reducedMotionToggle = document.getElementById("accessibility-reduced-motion");
        const dyslexiaSpacingToggle = document.getElementById("accessibility-dyslexia-spacing");
        const colorblindToggle = document.getElementById("accessibility-colorblind");
        const virtualKeyboardToggle = document.getElementById("accessibility-virtual-keyboard");
        const virtualKeyboardLayoutSelect = document.getElementById("accessibility-virtual-keyboard-layout");
        const brightnessSlider = document.getElementById("accessibility-bg-brightness");
        const brightnessValue = document.getElementById("accessibility-bg-brightness-value");
        const dyslexiaPresetButton = document.getElementById("accessibility-dyslexia-preset");
        if (!container ||
            !(closeButton instanceof HTMLButtonElement) ||
            !(skipButton instanceof HTMLButtonElement) ||
            !(applyButton instanceof HTMLButtonElement) ||
            !(reducedMotionToggle instanceof HTMLInputElement) ||
            !(dyslexiaSpacingToggle instanceof HTMLInputElement) ||
            !(colorblindToggle instanceof HTMLInputElement) ||
            !(brightnessSlider instanceof HTMLInputElement) ||
            !brightnessValue) {
            return;
        }
        const virtualKeyboardToggleEl = virtualKeyboardToggle instanceof HTMLInputElement ? virtualKeyboardToggle : null;
        const virtualKeyboardLayoutSelectEl = virtualKeyboardLayoutSelect instanceof HTMLSelectElement ? virtualKeyboardLayoutSelect : null;
        const getSelectValue = (select) => {
            const direct = select.value;
            if (typeof direct === "string" && direct !== "") {
                return direct;
            }
            return select.getAttribute("value") ?? "";
        };
        const syncVirtualKeyboardLayoutDisabled = () => {
            if (!virtualKeyboardLayoutSelectEl)
                return;
            const enabled = virtualKeyboardToggleEl ? Boolean(virtualKeyboardToggleEl.checked) : true;
            virtualKeyboardLayoutSelectEl.disabled = !enabled;
            virtualKeyboardLayoutSelectEl.setAttribute("aria-disabled", enabled ? "false" : "true");
            virtualKeyboardLayoutSelectEl.tabIndex = enabled ? 0 : -1;
        };
        const syncBrightnessLabel = () => {
            const normalized = this.normalizeBackgroundBrightness(Number(brightnessSlider.value));
            brightnessSlider.value = String(normalized);
            brightnessValue.textContent = `${Math.round(normalized * 100)}%`;
        };
        brightnessSlider.addEventListener("input", syncBrightnessLabel);
        if (virtualKeyboardToggleEl) {
            virtualKeyboardToggleEl.addEventListener("change", syncVirtualKeyboardLayoutDisabled);
        }
        const applyPreferences = () => {
            this.setReducedMotionEnabled(Boolean(reducedMotionToggle.checked));
            this.setDyslexiaSpacingEnabled(Boolean(dyslexiaSpacingToggle.checked));
            this.setColorblindPaletteEnabled(Boolean(colorblindToggle.checked));
            if (virtualKeyboardToggleEl) {
                this.setVirtualKeyboardEnabled(Boolean(virtualKeyboardToggleEl.checked));
            }
            if (virtualKeyboardLayoutSelectEl) {
                const rawLayout = getSelectValue(virtualKeyboardLayoutSelectEl);
                this.setVirtualKeyboardLayout(rawLayout);
            }
            const brightness = this.normalizeBackgroundBrightness(Number(brightnessSlider.value));
            this.setBackgroundBrightness(brightness);
            this.persistAccessibilitySeen();
            this.hideAccessibilityOnboarding();
        };
        const skipOnboarding = () => {
            this.persistAccessibilitySeen();
            this.hideAccessibilityOnboarding();
        };
        closeButton.addEventListener("click", skipOnboarding);
        skipButton.addEventListener("click", skipOnboarding);
        applyButton.addEventListener("click", applyPreferences);
        if (dyslexiaPresetButton instanceof HTMLButtonElement) {
            dyslexiaPresetButton.addEventListener("click", () => {
                dyslexiaSpacingToggle.checked = true;
                this.setDyslexiaSpacingEnabled(true);
                this.setDyslexiaFontEnabled(true);
                this.persistAccessibilitySeen();
                this.hideAccessibilityOnboarding();
            });
        }
        container.addEventListener("click", (event) => {
            if (event.target === container) {
                skipOnboarding();
            }
        });
        this.accessibilityOverlay = {
            container,
            closeButton,
            skipButton,
            applyButton,
            reducedMotionToggle,
            dyslexiaSpacingToggle,
            colorblindToggle,
            brightnessSlider,
            brightnessValue,
            virtualKeyboardToggle: virtualKeyboardToggleEl ?? undefined,
            virtualKeyboardLayoutSelect: virtualKeyboardLayoutSelectEl ?? undefined,
            visible: false
        };
        this.syncAccessibilityOverlay();
        syncVirtualKeyboardLayoutDisabled();
    }
    syncAccessibilityOverlay() {
        if (!this.accessibilityOverlay)
            return;
        this.accessibilityOverlay.reducedMotionToggle.checked = Boolean(this.reducedMotionEnabled);
        this.accessibilityOverlay.dyslexiaSpacingToggle.checked = Boolean(this.dyslexiaSpacingEnabled);
        this.accessibilityOverlay.colorblindToggle.checked = Boolean(this.colorblindPaletteEnabled);
        if (this.accessibilityOverlay.virtualKeyboardToggle) {
            this.accessibilityOverlay.virtualKeyboardToggle.checked = Boolean(this.virtualKeyboardEnabled);
        }
        if (this.accessibilityOverlay.virtualKeyboardLayoutSelect) {
            const normalized = this.normalizeVirtualKeyboardLayout(this.virtualKeyboardLayout ?? DEFAULT_VIRTUAL_KEYBOARD_LAYOUT);
            try {
                this.accessibilityOverlay.virtualKeyboardLayoutSelect.value = normalized;
            }
            catch {
                this.accessibilityOverlay.virtualKeyboardLayoutSelect.setAttribute("value", normalized);
            }
            const enabled = this.accessibilityOverlay.virtualKeyboardToggle
                ? Boolean(this.accessibilityOverlay.virtualKeyboardToggle.checked)
                : true;
            this.accessibilityOverlay.virtualKeyboardLayoutSelect.disabled = !enabled;
            this.accessibilityOverlay.virtualKeyboardLayoutSelect.setAttribute("aria-disabled", enabled ? "false" : "true");
            this.accessibilityOverlay.virtualKeyboardLayoutSelect.tabIndex = enabled ? 0 : -1;
        }
        const normalized = this.normalizeBackgroundBrightness(this.backgroundBrightness);
        this.accessibilityOverlay.brightnessSlider.value = String(normalized);
        this.accessibilityOverlay.brightnessValue.textContent = `${Math.round(normalized * 100)}%`;
    }
    maybeShowAccessibilityOnboarding() {
        if (this.accessibilityOnboardingSeen ||
            !this.accessibilityOverlay ||
            this.accessibilityOverlay.visible) {
            return;
        }
        const blocked = this.optionsOverlayActive ||
            this.typingDrillsOverlayActive ||
            this.waveScorecardActive ||
            this.enemyIntroOverlay?.visible;
        if (blocked) {
            if (typeof window !== "undefined") {
                window.setTimeout(() => this.maybeShowAccessibilityOnboarding(), 800);
            }
            return;
        }
        this.syncAccessibilityOverlay();
        const overlay = this.accessibilityOverlay;
        overlay.container.dataset.visible = "true";
        overlay.container.setAttribute("aria-hidden", "false");
        overlay.visible = true;
        this.resumeAfterAccessibility = this.running && !this.optionsOverlayActive;
        if (this.resumeAfterAccessibility) {
            this.pause();
        }
        window.setTimeout(() => overlay.applyButton.focus(), 0);
    }
    hideAccessibilityOnboarding() {
        if (!this.accessibilityOverlay || !this.accessibilityOverlay.visible)
            return;
        const overlay = this.accessibilityOverlay;
        overlay.container.dataset.visible = "false";
        overlay.container.setAttribute("aria-hidden", "true");
        overlay.visible = false;
        const shouldResume = this.resumeAfterAccessibility &&
            !this.running &&
            !this.optionsOverlayActive &&
            !this.typingDrillsOverlayActive &&
            !this.menuActive &&
            !this.waveScorecardActive;
        this.resumeAfterAccessibility = false;
        if (shouldResume) {
            this.start();
        }
    }
    loadFirstEncounterSeen() {
        if (typeof window === "undefined" || !window.localStorage) {
            return new Set();
        }
        try {
            const raw = window.localStorage.getItem(FIRST_ENCOUNTER_STORAGE_KEY);
            if (!raw)
                return new Set();
            const parsed = JSON.parse(raw);
            if (!Array.isArray(parsed))
                return new Set();
            return new Set(parsed.filter((id) => typeof id === "string" && id.length > 0));
        }
        catch {
            return new Set();
        }
    }
    persistFirstEncounterSeen() {
        if (typeof window === "undefined" || !window.localStorage) {
            return;
        }
        const payload = Array.from(this.firstEncounterSeen);
        try {
            window.localStorage.setItem(FIRST_ENCOUNTER_STORAGE_KEY, JSON.stringify(payload));
        }
        catch {
            // best effort
        }
    }
    attachEnemyIntroOverlay() {
        if (typeof document === "undefined")
            return;
        const container = document.getElementById("enemy-intro-overlay");
        const title = document.getElementById("enemy-intro-title");
        const role = document.getElementById("enemy-intro-role");
        const description = document.getElementById("enemy-intro-description");
        const tips = document.getElementById("enemy-intro-tips");
        const closeButton = document.getElementById("enemy-intro-close");
        const dismissButton = document.getElementById("enemy-intro-dismiss");
        if (!container ||
            !title ||
            !role ||
            !description ||
            !tips ||
            !(closeButton instanceof HTMLButtonElement) ||
            !(dismissButton instanceof HTMLButtonElement)) {
            return;
        }
        const hide = () => this.hideEnemyIntroOverlay();
        closeButton.addEventListener("click", hide);
        dismissButton.addEventListener("click", hide);
        container.addEventListener("click", (event) => {
            if (event.target === container) {
                hide();
            }
        });
        this.enemyIntroOverlay = {
            container,
            title,
            role,
            description,
            tips,
            closeButton,
            dismissButton,
            visible: false
        };
    }
    showEnemyIntroOverlay(tierId, bio) {
        if (!this.enemyIntroOverlay)
            return;
        const overlay = this.enemyIntroOverlay;
        overlay.title.textContent = bio.name || tierId;
        overlay.role.textContent = bio.danger ? `${bio.role} • ${bio.danger}` : bio.role ?? "";
        overlay.description.textContent = bio.description ?? "";
        overlay.tips.replaceChildren();
        const tipList = Array.isArray(bio.tips) && bio.tips.length > 0
            ? bio.tips
            : ["Stay calm and type clean hits to break through."];
        for (const tip of tipList.slice(0, 3)) {
            const li = document.createElement("li");
            li.textContent = tip;
            overlay.tips.appendChild(li);
        }
        overlay.container.dataset.visible = "true";
        overlay.container.setAttribute("aria-hidden", "false");
        overlay.visible = true;
        this.enemyIntroActiveTier = tierId;
        this.resumeAfterEnemyIntro = this.running && !this.optionsOverlayActive;
        if (this.resumeAfterEnemyIntro) {
            this.pause();
        }
        window.setTimeout(() => overlay.dismissButton.focus(), 0);
    }
    hideEnemyIntroOverlay() {
        if (!this.enemyIntroOverlay || !this.enemyIntroOverlay.visible)
            return;
        const overlay = this.enemyIntroOverlay;
        overlay.container.dataset.visible = "false";
        overlay.container.setAttribute("aria-hidden", "true");
        overlay.visible = false;
        if (this.enemyIntroActiveTier) {
            this.firstEncounterSeen.add(this.enemyIntroActiveTier);
            this.persistFirstEncounterSeen();
        }
        this.enemyIntroActiveTier = null;
        const shouldResume = this.resumeAfterEnemyIntro &&
            !this.running &&
            !this.optionsOverlayActive &&
            !this.typingDrillsOverlayActive;
        this.resumeAfterEnemyIntro = false;
        if (shouldResume) {
            this.start();
        }
    }
    checkFirstEncounterOverlay() {
        if (!this.enemyIntroOverlay || this.enemyIntroOverlay.visible)
            return;
        if (this.optionsOverlayActive || this.typingDrillsOverlayActive || this.menuActive)
            return;
        if (!this.currentState?.enemies || this.currentState.enemies.length === 0)
            return;
        for (const enemy of this.currentState.enemies) {
            const tierId = enemy?.tierId;
            if (!tierId || tierId === "dummy" || this.firstEncounterSeen.has(tierId)) {
                continue;
            }
            const configTier = this.engine.config.enemyTiers?.[tierId];
            const bio = getEnemyBiography(tierId, configTier);
            this.showEnemyIntroOverlay(tierId, bio);
            break;
        }
    }
    syncAssetIntegrityFlags() {
        if (typeof document === "undefined" || !document.body) {
            return;
        }
        if (!this.assetIntegritySummary) {
            delete document.body.dataset.assetIntegrityStatus;
            delete document.body.dataset.assetIntegrityStrict;
            return;
        }
        document.body.dataset.assetIntegrityStatus = this.assetIntegritySummary.status ?? "pending";
        document.body.dataset.assetIntegrityStrict = this.assetIntegritySummary.strictMode
            ? "true"
            : "false";
    }
    syncCanvasResizeCause() {
        if (typeof document === "undefined" || !document.body) {
            return;
        }
        const cause = this.renderer?.getLastResizeCause?.();
        if (typeof cause !== "string" || !cause) {
            delete document.body.dataset.canvasResizeCause;
            return;
        }
        document.body.dataset.canvasResizeCause = cause;
    }
}
