import { test } from "vitest";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { parseHTML } from "linkedom";
import { HudView } from "../src/ui/hud.ts";
import { defaultConfig } from "../src/core/config.ts";

const htmlSource = readFileSync(new URL("../public/index.html", import.meta.url), "utf8");

const createMatchMediaStub = (state = {}) => {
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
};

const initializeHud = (options = {}) => {
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
    matchMedia:
      typeof options.matchMedia === "function"
        ? options.matchMedia
        : createMatchMediaStub(options.matchMediaState ?? {})
  });

  window.matchMedia =
    typeof options.matchMedia === "function"
      ? options.matchMedia
      : window.matchMedia ?? createMatchMediaStub(options.matchMediaState ?? {});

  const get = (id) => {
    const el = document.getElementById(id);
    if (!el) {
      throw new Error(`Missing element ${id}`);
    }
    return el;
  };

  const findByClass = (root, className) =>
    root?.querySelector(`.${className}`) ?? undefined;

  const hudRoot = get("hud");
  const goldDelta = get("resource-delta");
  const activeWord = get("active-word");
  const upgradePanel = get("upgrade-panel");
  const comboLabel = get("combo-stats");
  const comboAccuracyDelta = get("combo-accuracy-delta");
  const companionPet = get("companion-pet");
  const companionMoodLabel = get("companion-mood-label");
  const companionTip = get("companion-tip");
  const loreScrollPanel = get("lore-scroll-panel");
  const loreScrollsSummary = get("lore-scrolls-summary");
  const loreScrollsProgress = get("lore-scrolls-progress");
  const loreScrollsLessons = get("lore-scrolls-lessons");
  const loreScrollsNext = get("lore-scrolls-next");
  const loreScrollsOpen = get("lore-scrolls-open");
  const masteryCertificatePanel = get("mastery-certificate-panel");
  const masteryCertificateSummary = get("mastery-certificate-summary");
  const masteryCertificateStats = get("mastery-certificate-stats");
  const masteryCertificateDate = get("mastery-certificate-date");
  const masteryCertificateName = get("mastery-certificate-name");
  const masteryCertificateOpen = get("mastery-certificate-open");
  const museumPanel = get("castle-museum-panel");
  const museumSummary = get("castle-museum-summary");
  const museumStats = get("castle-museum-stats");
  const museumOpen = get("castle-museum-open");
  const sideQuestPanel = get("side-quest-panel");
  const sideQuestSummary = get("side-quest-summary");
  const sideQuestStats = get("side-quest-stats");
  const sideQuestOpen = get("side-quest-open");
  const mentorDialogue = get("mentor-dialogue");
  const mentorDialogueText = get("mentor-dialogue-text");
  const mentorDialogueFocus = get("mentor-dialogue-focus");
  const milestoneCelebration = get("milestone-celebration");
  const milestoneCelebrationTitle = get("milestone-celebration-title");
  const milestoneCelebrationDetail = get("milestone-celebration-detail");
  const milestoneCelebrationBadge = get("milestone-celebration-badge");
  const milestoneCelebrationClose = get("milestone-celebration-close");
  const lessonMedalPanel = get("lesson-medal-panel");
  const lessonMedalBadge = get("lesson-medal-badge");
  const lessonMedalSummary = get("lesson-medal-summary");
  const lessonMedalBest = get("lesson-medal-best");
  const lessonMedalNext = get("lesson-medal-next");
  const lessonMedalOpen = get("lesson-medal-open");
  const logList = get("battle-log");
  const wavePreview = get("wave-preview-list");
  const wavePreviewHint = get("wave-preview-hint");
  const tutorialBanner = get("tutorial-banner");
  const tutorialBannerMessage =
    tutorialBanner.querySelector("[data-role='tutorial-message']") ?? tutorialBanner;
  const tutorialBannerToggle = tutorialBanner.querySelector("[data-role='tutorial-toggle']");
  const summaryContainer = get("tutorial-summary");
  const summaryContinue = get("tutorial-summary-continue");
  const summaryReplay = get("tutorial-summary-replay");
  const optionsCastleBonus = get("options-castle-bonus");
  const optionsCastleBenefits = get("options-castle-benefits");
  const optionsCastlePassives = get("options-castle-passives");
  const optionsPassivesSection = get("options-passives-section");
  const optionsPassivesSummary = get("options-passives-summary");
  const optionsPassivesToggle = get("options-passives-toggle");
  const soundToggle = get("options-sound-toggle");
  const soundVolumeSlider = get("options-sound-volume");
  const soundVolumeValue = get("options-sound-volume-value");
  const soundIntensitySlider = get("options-sound-intensity");
  const soundIntensityValue = get("options-sound-intensity-value");
  const screenShakeToggle = get("options-screen-shake-toggle");
  const screenShakeSlider = get("options-screen-shake-intensity");
  const screenShakeValue = get("options-screen-shake-intensity-value");
  const screenShakePreview = get("options-screen-shake-preview");
  const diagnosticsToggle = get("options-diagnostics-toggle");
  const reducedMotionToggle = get("options-reduced-motion-toggle");
  const checkeredBackgroundToggle = get("options-checkered-bg-toggle");
  const readableFontToggle = get("options-readable-font-toggle");
  const dyslexiaFontToggle = get("options-dyslexia-font-toggle");
  const dyslexiaSpacingToggle = get("options-dyslexia-spacing-toggle");
  const cognitiveLoadToggle = get("options-cognitive-load");
  const colorblindPaletteToggle = get("options-colorblind-toggle");
  const telemetryToggle = get("options-telemetry-toggle");
  const telemetryToggleWrapper = get("options-telemetry-toggle-wrapper");
  const hudZoomSelect = get("options-hud-zoom");
  const hudLayoutToggle = get("options-hud-left");
  const fontScaleSelect = get("options-font-scale");
  const castleSkinSelect = get("options-castle-skin");
  const contrastAuditButton = get("options-contrast-audit");
  const stickerBookButton = get("options-sticker-book");
  const optionsSeasonTrackButton = get("options-season-track");
  const optionsSideQuestButton = get("options-side-quests");
  const optionsMasteryCertificateButton = get("options-mastery-certificate");
  const optionsLessonMedalsButton = get("options-lesson-medals");
  const optionsParentSummaryButton = get("options-parent-summary");
  const optionsLoreScrollsButton = get("options-lore-scrolls");
  const contrastOverlay = get("contrast-overlay");
  const contrastOverlayList = get("contrast-overlay-list");
  const contrastOverlaySummary = get("contrast-overlay-summary");
  const contrastOverlayClose = get("contrast-overlay-close");
  const contrastOverlayMarkers = get("contrast-overlay-markers");
  const optionsQuickNav = get("options-quick-nav");
  const stickerOverlay = get("sticker-overlay");
  const stickerOverlayList = get("sticker-overlay-list");
  const stickerOverlaySummary = get("sticker-overlay-summary");
  const stickerOverlayClose = get("sticker-overlay-close");
  const scrollOverlay = get("scrolls-overlay");
  const scrollOverlayList = get("scrolls-overlay-list");
  const scrollOverlaySummary = get("scrolls-overlay-summary");
  const scrollOverlayProgress = get("scrolls-overlay-progress");
  const scrollOverlayClose = get("scrolls-overlay-close");
  const seasonTrackOverlay = get("season-track-overlay");
  const seasonTrackList = get("season-track-list");
  const seasonTrackProgress = get("season-track-overlay-progress");
  const seasonTrackLessons = get("season-track-overlay-lessons");
  const seasonTrackNext = get("season-track-overlay-next");
  const seasonTrackClose = get("season-track-close");
  const sideQuestOverlay = get("side-quest-overlay");
  const sideQuestList = get("side-quest-list");
  const sideQuestSubtitle = get("side-quest-overlay-subtitle");
  const sideQuestClose = get("side-quest-close");
  const masteryCertificateOverlay = get("mastery-certificate-overlay");
  const masteryCertificateStatsList = get("mastery-certificate-stats-list");
  const masteryCertificateDownload = get("mastery-certificate-download");
  const masteryCertificateOverlaySummary = get("mastery-certificate-overlay-summary");
  const masteryCertificateOverlayDate = get("mastery-certificate-date");
  const masteryCertificateOverlayClose = get("mastery-certificate-close");
  const lessonMedalOverlay = get("lesson-medal-overlay");
  const lessonMedalList = get("lesson-medal-best-list");
  const lessonMedalHistory = get("lesson-medal-history-list");
  const lessonMedalReplay = get("lesson-medal-replay");
  const lessonMedalOverlayBadge = get("lesson-medal-overlay-badge");
  const lessonMedalOverlayLast = get("lesson-medal-overlay-last");
  const lessonMedalOverlayNext = get("lesson-medal-overlay-next");
  const lessonMedalClose = get("lesson-medal-close");
  const museumOverlay = get("museum-overlay");
  const museumList = get("museum-list");
  const museumSubtitle = get("museum-overlay-subtitle");
  const parentSummaryOverlay = get("parent-summary-overlay");
  const parentSummaryClose = get("parent-summary-close");
  const parentSummaryProgress = get("parent-summary-progress");
  const parentSummaryAccuracy = get("parent-summary-accuracy");
  const parentSummaryDownload = get("parent-summary-download");
  const selfTestContainer = get("options-self-test");
  const selfTestRun = get("options-self-test-run");
  const selfTestStatus = get("options-self-test-status");
  const selfTestSoundToggle = get("options-self-test-sound");
  const selfTestVisualToggle = get("options-self-test-visual");
  const selfTestMotionToggle = get("options-self-test-motion");
  const selfTestSoundIndicator = get("options-self-test-sound-indicator");
  const selfTestVisualIndicator = get("options-self-test-visual-indicator");
  const selfTestMotionIndicator = get("options-self-test-motion-indicator");
  const optionsOverlay = get("options-overlay");
  const optionsResume = get("options-resume-button");
  const analyticsExportButton = get("options-analytics-export");
  const analyticsViewerContainer = get("debug-analytics-viewer");
  const analyticsViewerBody = get("debug-analytics-viewer-body");
  const analyticsFilterSelect = get("debug-analytics-viewer-filter");
  const waveScorecard = get("wave-scorecard");
  const waveScorecardStats = get("wave-scorecard-stats");
  const waveScorecardContinue = get("wave-scorecard-continue");

  let scorecardContinues = 0;
  const reducedMotionToggleEvents = [];
  const analyticsExportEvents = [];
  const checkeredBackgroundToggleEvents = [];
  const readableFontToggleEvents = [];
  const dyslexiaFontToggleEvents = [];
  const cognitiveLoadToggleEvents = [];
  const colorblindToggleEvents = [];
  const castleSkinEvents = [];
  const contrastAuditEvents = [];
  const telemetryToggleEvents = [];
  const soundVolumeEvents = [];
  const soundIntensityEvents = [];
  const screenShakeToggleEvents = [];
  const screenShakeIntensityEvents = [];
  const screenShakePreviewEvents = [];
  const selfTestRunEvents = [];
  const selfTestConfirmEvents = [];
  const hudZoomChangeEvents = [];
  const hudLayoutEvents = [];
  const fontScaleChangeEvents = [];
  const priorityChangeEvents = [];
  const turretHoverEvents = [];
  const turretPresetSaveEvents = [];
  const turretPresetApplyEvents = [];
  const turretPresetClearEvents = [];
  const collapseEvents = [];

  const hud = new HudView(
    defaultConfig,
    {
      healthBar: "castle-health-bar",
      goldLabel: "resource-gold",
      goldDelta: "resource-delta",
      activeWord: "active-word",
      typingInput: "typing-input",
      companionPet: "companion-pet",
      companionMoodLabel: "companion-mood-label",
      companionTip: "companion-tip",
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
      optionsOverlay: {
        container: "options-overlay",
        closeButton: "options-overlay-close",
        resumeButton: "options-resume-button",
        soundToggle: "options-sound-toggle",
        soundVolumeSlider: "options-sound-volume",
        soundVolumeValue: "options-sound-volume-value",
        soundIntensitySlider: "options-sound-intensity",
        soundIntensityValue: "options-sound-intensity-value",
        screenShakeToggle: "options-screen-shake-toggle",
        screenShakeSlider: "options-screen-shake-intensity",
        screenShakeValue: "options-screen-shake-intensity-value",
        screenShakePreview: "options-screen-shake-preview",
        screenShakeDemo: "options-screen-shake-demo",
        contrastAuditButton: "options-contrast-audit",
        stickerBookButton: "options-sticker-book",
        parentSummaryButton: "options-parent-summary",
        loreScrollsButton: "options-lore-scrolls",
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
        reducedMotionToggle: "options-reduced-motion-toggle",
        checkeredBackgroundToggle: "options-checkered-bg-toggle",
        readableFontToggle: "options-readable-font-toggle",
        dyslexiaFontToggle: "options-dyslexia-font-toggle",
        dyslexiaSpacingToggle: "options-dyslexia-spacing-toggle",
        cognitiveLoadToggle: "options-cognitive-load",
        colorblindPaletteToggle: "options-colorblind-toggle",
        castleSkinSelect: "options-castle-skin",
        defeatAnimationSelect: "options-defeat-animation",
        telemetryToggle: "options-telemetry-toggle",
        telemetryToggleWrapper: "options-telemetry-toggle-wrapper",
        hudZoomSelect: "options-hud-zoom",
        hudLayoutToggle: "options-hud-left",
        fontScaleSelect: "options-font-scale",
        analyticsExportButton: "options-analytics-export",
        seasonTrackButton: "options-season-track",
        sideQuestButton: "options-side-quests",
        museumButton: "options-museum",
        masteryCertificateButton: "options-mastery-certificate",
        lessonMedalButton: "options-lesson-medals"
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
      },
      contrastOverlay: {
        container: "contrast-overlay",
        list: "contrast-overlay-list",
        summary: "contrast-overlay-summary",
        closeButton: "contrast-overlay-close",
        markers: "contrast-overlay-markers"
      },
      stickerBookOverlay: {
        container: "sticker-overlay",
        list: "sticker-overlay-list",
        summary: "sticker-overlay-summary",
        closeButton: "sticker-overlay-close"
      },
      seasonTrackOverlay: {
        container: "season-track-overlay",
        list: "season-track-list",
        progress: "season-track-overlay-progress",
        lessons: "season-track-overlay-lessons",
        next: "season-track-overlay-next",
        closeButton: "season-track-close"
      },
      sideQuestOverlay: {
        container: "side-quest-overlay",
        closeButton: "side-quest-close",
        list: "side-quest-list",
        subtitle: "side-quest-overlay-subtitle"
      },
      museumOverlay: {
        container: "museum-overlay",
        closeButton: "museum-close",
        list: "museum-list",
        subtitle: "museum-overlay-subtitle"
      },
      masteryCertificateOverlay: {
        container: "mastery-certificate-overlay",
        closeButton: "mastery-certificate-close",
        downloadButton: "mastery-certificate-download",
        nameInput: "mastery-certificate-name",
        summary: "mastery-certificate-overlay-summary",
        statsList: "mastery-certificate-stats-list",
        date: "mastery-certificate-date"
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
      loreScrollOverlay: {
        container: "scrolls-overlay",
        list: "scrolls-overlay-list",
        summary: "scrolls-overlay-summary",
        progress: "scrolls-overlay-progress",
        closeButton: "scrolls-overlay-close"
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
      onSoundIntensityChange: (value) => soundIntensityEvents.push(value),
      onScreenShakeToggle: (value) => screenShakeToggleEvents.push(value),
      onScreenShakeIntensityChange: (value) => screenShakeIntensityEvents.push(value),
      onScreenShakePreview: () => screenShakePreviewEvents.push(true),
      onCastleSkinChange: (skin) => castleSkinEvents.push(skin),
      onContrastAuditRequested: () => contrastAuditEvents.push(true),
      onAccessibilitySelfTestRun: () => selfTestRunEvents.push(true),
      onAccessibilitySelfTestConfirm: (kind, confirmed) =>
        selfTestConfirmEvents.push({ kind, confirmed }),
      onDiagnosticsToggle: () => {},
      onWaveScorecardContinue: () => scorecardContinues++,
      onReducedMotionToggle: (enabled) => reducedMotionToggleEvents.push(enabled),
      onCheckeredBackgroundToggle: (enabled) => checkeredBackgroundToggleEvents.push(enabled),
      onReadableFontToggle: (enabled) => readableFontToggleEvents.push(enabled),
      onDyslexiaFontToggle: (enabled) => dyslexiaFontToggleEvents.push(enabled),
      onCognitiveLoadToggle: (enabled) => cognitiveLoadToggleEvents.push(enabled),
      onColorblindPaletteToggle: (enabled) => colorblindToggleEvents.push(enabled),
      onTelemetryToggle: (enabled) => telemetryToggleEvents.push(enabled),
      onAnalyticsExport: () => analyticsExportEvents.push(true),
      onHudZoomChange: (scale) => hudZoomChangeEvents.push(scale),
      onHudLayoutToggle: (left) => hudLayoutEvents.push(left),
      onHudFontScaleChange: (scale) => fontScaleChangeEvents.push(scale),
      onCollapsePreferenceChange: (prefs) => collapseEvents.push({ ...prefs })
    }
  );

  const comboAccuracyDeltaRef = hud.comboAccuracyDelta ?? comboAccuracyDelta;
  const castleGoldEventsRef =
    hud.castleGoldEvents ??
    findByClass(upgradePanel, "castle-gold-events") ??
    document.createElement("ul");
  const optionsCastlePassivesRef = hud.optionsCastlePassives ?? optionsCastlePassives;

  const castleStatus =
    findByClass(upgradePanel, "castle-status") ?? document.createElement("span");
  const castlePassivesList =
    findByClass(upgradePanel, "castle-passives") ?? document.createElement("ul");

  const cleanup = () => {
    Object.assign(global, originalGlobals);
  };

  return {
    hud,
    cleanup,
    elements: {
      activeWord,
      wavePreview,
      wavePreviewHint,
      comboLabel,
      comboAccuracyDelta: comboAccuracyDeltaRef,
      goldDelta,
      logList,
      companionPet,
      companionMoodLabel,
      companionTip,
      loreScrollPanel,
      loreScrollsSummary,
      loreScrollsProgress,
      loreScrollsLessons,
      loreScrollsNext,
      loreScrollsOpen,
      masteryCertificatePanel,
      masteryCertificateSummary,
      masteryCertificateStats,
      masteryCertificateDate,
      masteryCertificateName,
      masteryCertificateOpen,
      museumPanel,
      museumSummary,
      museumStats,
      museumOpen,
      sideQuestPanel,
      sideQuestSummary,
      sideQuestStats,
      sideQuestOpen,
      museumOverlay,
      museumList,
      museumSubtitle,
      mentorDialogue,
      mentorDialogueText,
      mentorDialogueFocus,
      lessonMedalPanel,
      lessonMedalBadge,
      lessonMedalSummary,
      lessonMedalBest,
      lessonMedalNext,
      lessonMedalOpen,
      milestoneCelebration,
      milestoneCelebrationTitle,
      milestoneCelebrationDetail,
      milestoneCelebrationBadge,
      milestoneCelebrationClose,
      tutorialBanner,
      tutorialBannerMessage,
      tutorialBannerToggle,
      summaryContainer,
      summaryContinue,
      summaryReplay,
      optionsOverlay,
      optionsResume,
      analyticsExportButton,
      soundToggle,
      soundVolumeSlider,
      soundVolumeValue,
      soundIntensitySlider,
      soundIntensityValue,
      screenShakeToggle,
      screenShakeSlider,
      screenShakeValue,
      screenShakePreview,
      contrastAuditButton,
      stickerBookButton,
      optionsSeasonTrackButton,
      optionsSideQuestButton,
      optionsMasteryCertificateButton,
      optionsLessonMedalsButton,
      optionsParentSummaryButton,
      optionsLoreScrollsButton,
      contrastOverlay,
      contrastOverlayList,
      contrastOverlaySummary,
      contrastOverlayClose,
      contrastOverlayMarkers,
      optionsQuickNav,
      stickerOverlay,
      stickerOverlayList,
      stickerOverlaySummary,
      stickerOverlayClose,
      seasonTrackOverlay,
      seasonTrackList,
      seasonTrackProgress,
      seasonTrackLessons,
      seasonTrackNext,
      seasonTrackClose,
      sideQuestOverlay,
      sideQuestList,
      sideQuestSubtitle,
      sideQuestClose,
      masteryCertificateOverlay,
      masteryCertificateStatsList,
      masteryCertificateDownload,
      masteryCertificateOverlaySummary,
      masteryCertificateOverlayDate,
      masteryCertificateClose: masteryCertificateOverlayClose,
      lessonMedalOverlay,
      lessonMedalList,
      lessonMedalHistory,
      lessonMedalReplay,
      lessonMedalOverlayBadge,
      lessonMedalOverlayLast,
      lessonMedalOverlayNext,
      lessonMedalClose,
      parentSummaryOverlay,
      parentSummaryClose,
      parentSummaryProgress,
      parentSummaryAccuracy,
      parentSummaryDownload,
      scrollOverlay,
      scrollOverlayList,
      scrollOverlaySummary,
      scrollOverlayProgress,
      scrollOverlayClose,
      selfTestContainer,
      selfTestRun,
      selfTestStatus,
      selfTestSoundToggle,
      selfTestVisualToggle,
      selfTestMotionToggle,
      selfTestSoundIndicator,
      selfTestVisualIndicator,
      selfTestMotionIndicator,
      diagnosticsToggle,
      reducedMotionToggle,
      checkeredBackgroundToggle,
      readableFontToggle,
      dyslexiaFontToggle,
      dyslexiaSpacingToggle,
      cognitiveLoadToggle,
      colorblindPaletteToggle,
      telemetryToggle,
      telemetryToggleWrapper,
      hudZoomSelect,
      hudLayoutToggle,
      fontScaleSelect,
      castleSkinSelect,
      optionsCastleBonus,
      optionsCastleBenefits,
      optionsCastlePassives: optionsCastlePassivesRef,
      optionsPassivesSection,
      optionsPassivesSummary,
      optionsPassivesToggle,
      castleStatus,
      castlePassivesList,
      castleGoldEvents: castleGoldEventsRef,
      waveScorecard,
      waveScorecardStats,
      waveScorecardContinue,
      analyticsViewerContainer,
      analyticsViewerBody,
      analyticsFilterSelect,
      hudRoot,
      body: document.body,
      getScorecardContinueCount: () => scorecardContinues,
      getReducedMotionToggleEvents: () => [...reducedMotionToggleEvents],
      upgradePanel,
      getCheckeredBackgroundToggleEvents: () => [...checkeredBackgroundToggleEvents],
      getReadableFontToggleEvents: () => [...readableFontToggleEvents],
      getDyslexiaFontToggleEvents: () => [...dyslexiaFontToggleEvents],
      getCognitiveLoadToggleEvents: () => [...cognitiveLoadToggleEvents],
      getColorblindToggleEvents: () => [...colorblindToggleEvents],
      getCastleSkinEvents: () => [...castleSkinEvents],
      getSoundVolumeEvents: () => [...soundVolumeEvents],
      getSoundIntensityEvents: () => [...soundIntensityEvents],
      getScreenShakeToggleEvents: () => [...screenShakeToggleEvents],
      getScreenShakeIntensityEvents: () => [...screenShakeIntensityEvents],
      getScreenShakePreviewEvents: () => [...screenShakePreviewEvents],
      getContrastAuditEvents: () => [...contrastAuditEvents],
      getSelfTestRunEvents: () => [...selfTestRunEvents],
      getSelfTestConfirmEvents: () => [...selfTestConfirmEvents],
      getOptionsSectionToggles: () =>
        Array.from(document.querySelectorAll(".options-section-toggle")),
      getTelemetryToggleEvents: () => [...telemetryToggleEvents],
      getHudZoomEvents: () => [...hudZoomChangeEvents],
      getHudLayoutEvents: () => [...hudLayoutEvents],
      getFontScaleEvents: () => [...fontScaleChangeEvents],
      getPriorityEvents: () => [...priorityChangeEvents],
      getTurretHoverEvents: () => [...turretHoverEvents],
      getTurretPresetSaveEvents: () => [...turretPresetSaveEvents],
      getTurretPresetApplyEvents: () => [...turretPresetApplyEvents],
      getTurretPresetClearEvents: () => [...turretPresetClearEvents],
      getCollapseEvents: () => [...collapseEvents]
    },
    getAnalyticsExportEvents: () => [...analyticsExportEvents],
    getCollapseEvents: () => [...collapseEvents]
  };
};

const findDescendantByClass = (root, className) => {
  if (!root?.querySelector) return null;
  return root.querySelector(`.${className}`);
};

const dispatchDomEvent = (node, type) => {
  if (!node) return;
  const EventCtor = node.ownerDocument?.defaultView?.Event ?? global.window?.Event;
  if (!EventCtor) return;
  node.dispatchEvent(new EventCtor(type, { bubbles: true }));
};

const setSelectValueForElement = (select, value) => {
  if (!select) return;
  const options = Array.from(select.options ?? []);
  let matched = false;
  for (const option of options) {
    const isMatch = option.value === value;
    option.selected = isMatch;
    if (isMatch) {
      matched = true;
    }
  }
  try {
    select.value = value;
  } catch {
    select.setAttribute?.("value", value);
  }
  if (!matched && options.length === 0) {
    select.setAttribute?.("value", value);
  }
};

const readSelectValue = (select) => {
  if (!select) return undefined;
  const options = Array.from(select.options ?? []);
  const selected = options.find((option) => option.selected);
  if (selected) return selected.value;
  return select.getAttribute?.("value") ?? select.value;
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
      repairCooldownRemaining: 0,
      goldBonusPercent: 0,
      passives: []
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
      comboTimer: 0,
      comboWarning: false,
      errors: 0,
      totalInputs: 0,
      correctInputs: 0,
      accuracy: 1,
      recentInputs: [],
      recentCorrectInputs: 0,
      recentAccuracy: 1,
      dynamicDifficultyBias: 0
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
      },
      goldEvents: []
    }
  };
};

test("HudView highlights combos and accuracy delta during warnings", () => {
  const { hud, cleanup, elements } = initializeHud();
  const {
    wavePreview,
    comboLabel,
  comboAccuracyDelta,
  goldDelta,
  logList,
  tutorialBanner,
  tutorialBannerMessage
} = elements;

  const baseState = buildInitialState();
  baseState.typing.accuracy = 0.96;
  hud.update(baseState, []);
  assert.equal(wavePreview.children.length, 1);
  assert.equal(wavePreview.children[0].textContent, "All clear.");
  assert.equal(comboLabel.dataset.active, "false");
  assert.equal(comboAccuracyDelta.dataset.visible, "false");

  const nextState = structuredClone(baseState);
  nextState.resources.gold = 260;
  nextState.typing.combo = 4;
  nextState.typing.comboWarning = false;
  nextState.typing.comboTimer = 2;
  nextState.typing.accuracy = 0.91;
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
  assert.equal(comboAccuracyDelta.dataset.visible, "false");
  assert.equal(goldDelta.dataset.visible, "true");
  assert.equal(goldDelta.textContent, "+60g");

  const warningState = structuredClone(nextState);
  warningState.typing.comboWarning = true;
  warningState.typing.comboTimer = 0.8;
  warningState.typing.accuracy = 0.82;
  hud.update(warningState, upcoming);
  assert.equal(comboAccuracyDelta.dataset.visible, "true");
  assert.equal(comboAccuracyDelta.dataset.trend, "down");
  assert.ok(comboAccuracyDelta.textContent?.includes("% accuracy"));

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
  assert.ok(hud.tutorialBanner, "tutorial banner reference missing");
  assert.equal(hud.tutorialBanner.message, tutorialBannerMessage);
  assert.equal(tutorialBanner.dataset.visible, "true");
  assert.equal(tutorialBanner.dataset.highlight, "true");
  assert.equal(tutorialBannerMessage.textContent, "Practice typing");
  hud.setTutorialMessage(null);
  assert.equal(tutorialBanner.dataset.visible, "false");

  cleanup();
});

test("HudView condenses tutorial banner on compact heights", () => {
  const matchMediaState = { "(max-height: 540px)": true };
  const { hud, cleanup, elements } = initializeHud({ matchMediaState });
  const { tutorialBanner, tutorialBannerMessage, tutorialBannerToggle } = elements;

  hud.setTutorialMessage(
    "Hold position and keep typing-perfect words trigger turret bursts even on mobile."
  );
  assert.equal(tutorialBanner.dataset.visible, "true");
  assert.equal(tutorialBanner.dataset.condensed, "true");
  assert.equal(tutorialBanner.dataset.expanded, "false");
  assert.equal(document.body.dataset.compactHeight, "true");
  assert.ok(tutorialBannerToggle);
  assert.equal(tutorialBannerToggle.hidden, false);
  tutorialBannerToggle.click();
  assert.equal(tutorialBanner.dataset.expanded, "true");

  matchMediaState["(max-height: 540px)"] = false;
  hud.setTutorialMessage("Aim for steady accuracy bursts.");
  assert.equal(tutorialBanner.dataset.condensed, "false");
  assert.equal(tutorialBanner.dataset.expanded, "true");
  assert.equal(document.body.dataset.compactHeight, undefined);
  assert.equal(tutorialBannerToggle.hidden, true);
  assert.equal(tutorialBannerMessage.textContent, "Aim for steady accuracy bursts.");

  cleanup();
});

test("HudView renders recent gold events list", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { castleGoldEvents } = elements;

  const baseState = buildInitialState();
  hud.update(baseState, []);
  assert.equal(castleGoldEvents.dataset.visible, "false");

  const stateWithEvents = structuredClone(baseState);
  stateWithEvents.time = 60;
  stateWithEvents.analytics.goldEvents = [
    { gold: 210, delta: 10, timestamp: 10 },
    { gold: 260, delta: 50, timestamp: 25 },
    { gold: 300, delta: 40, timestamp: 40 },
    { gold: 330, delta: 30, timestamp: 55 }
  ];
  hud.update(stateWithEvents, []);

  assert.equal(castleGoldEvents.dataset.visible, "true");
  assert.equal(castleGoldEvents.children.length, 3);
  assert.ok(castleGoldEvents.children[0].textContent.includes("+30g"));
  assert.ok(castleGoldEvents.children[2].textContent.includes("+50g"));
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

  const castleSection = findDescendantByClass(elements.upgradePanel, "castle-upgrade");
  assert.ok(castleSection, "expected castle upgrade container");
  const castleButtons = Array.from(castleSection.querySelectorAll("button"));
  const castleButton = castleButtons.find((child) => !child.classList.contains("castle-repair"));
  const repairButton = castleButtons.find((child) => child.classList.contains("castle-repair"));
  assert.ok(castleButton, "expected castle upgrade button");
  assert.ok(repairButton, "expected castle repair button");
  const benefitsList = findDescendantByClass(castleSection, "castle-benefits");
  assert.ok(benefitsList, "expected castle benefits list");
  assert.equal(benefitsList.dataset.visible, "true");
  assert.equal(benefitsList.hidden, false);
  const benefitTexts = Array.from(benefitsList.children).map((child) => child.textContent ?? "");
  assert.ok(
    benefitTexts.some((text) => text.includes("HP")),
    "expected HP benefit"
  );
  const optionsBenefits = elements.optionsCastleBenefits;
  assert.ok(optionsBenefits, "expected options overlay benefits list");
  const optionBenefits = Array.from(optionsBenefits.children);
  assert.equal(optionBenefits.length, benefitTexts.length);
  for (const line of benefitTexts) {
    assert.ok(
      optionBenefits.some((child) => (child.textContent ?? "").includes(line)),
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
  const maxOptionLines = Array.from(optionsBenefits.children);
  assert.ok(
    (maxOptionLines[0]?.textContent ?? "").toLowerCase().includes("maximum level"),
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

  const slotElements = Array.from(upgradePanel.querySelectorAll(".turret-slot"));
  const [firstSlot, secondSlot, thirdSlot] = slotElements;

  const firstPrioritySelect = firstSlot?.querySelector(".slot-priority-select");
  const secondPrioritySelect = secondSlot?.querySelector(".slot-priority-select");
  const thirdPriorityContainer = findDescendantByClass(thirdSlot, "slot-priority");
  const thirdPrioritySelect = thirdSlot?.querySelector(".slot-priority-select");

  assert.ok(firstPrioritySelect instanceof window.HTMLSelectElement, "expected priority select for first slot");
  assert.equal(readSelectValue(firstPrioritySelect), "weakest");
  const firstStatus = findDescendantByClass(firstSlot, "slot-status");
  assert.ok(firstStatus?.textContent.includes("Weakest"));

  assert.ok(secondPrioritySelect instanceof window.HTMLSelectElement, "expected priority select for second slot");
  assert.equal(readSelectValue(secondPrioritySelect), "strongest");

  assert.ok(thirdPriorityContainer?.dataset.disabled === "true");
  assert.equal(thirdPrioritySelect instanceof window.HTMLSelectElement ? thirdPrioritySelect.disabled : true, true);

  setSelectValueForElement(firstPrioritySelect, "strongest");
  dispatchDomEvent(firstPrioritySelect, "change");

  assert.deepEqual(getPriorityEvents(), [{ slotId: "slot-1", priority: "strongest" }]);

  cleanup();
});

test("HudView surfaces turret flavor text on slot controls", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { upgradePanel } = elements;
  const baseState = buildInitialState();

  hud.update(baseState, []);

  const firstSlot = upgradePanel.querySelector(".turret-slot");
  const firstSelect = firstSlot?.querySelector(".slot-select");
  assert.ok(firstSelect instanceof window.HTMLSelectElement, "expected turret select");
  const firstAction = firstSlot?.querySelector(".slot-action");
  assert.ok(firstAction instanceof window.HTMLButtonElement, "expected turret action button");
  assert.ok(
    firstSelect.title.toLowerCase().includes("reliable fletching tower"),
    "expected arrow turret flavor on select title"
  );
  assert.ok(
    firstAction.title.toLowerCase().includes("reliable fletching tower"),
    "expected arrow turret flavor on action title"
  );

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

    const presetContainer = findDescendantByClass(upgradePanel, "turret-presets");
    assert.ok(presetContainer, "expected presets container");
    const presetList = findDescendantByClass(presetContainer, "turret-presets-list");
    assert.ok(presetList, "expected presets list container");
    const presetItems = Array.from(presetList.querySelectorAll(".turret-preset"));
    const presetById = Object.fromEntries(
      presetItems
        .filter((item) => item.dataset?.presetId)
        .map((item) => [item.dataset.presetId, item])
    );

    const firstPreset = presetById["preset-a"];
    const secondPreset = presetById["preset-b"];
    assert.ok(firstPreset, "expected Preset A entry");
    assert.ok(secondPreset, "expected Preset B entry");
    const firstSummary = findDescendantByClass(firstPreset, "turret-preset-summary");
    const firstStatus = findDescendantByClass(firstPreset, "turret-preset-status");
    const firstApply = findDescendantByClass(firstPreset, "turret-preset-apply");
    const firstClear = findDescendantByClass(firstPreset, "turret-preset-clear");
    assert.ok(firstSummary);
    assert.equal(firstSummary.textContent, "S1 Arcane Focus Lv2 (Weakest) • S2 Flame Thrower Lv1");
    assert.equal(firstStatus?.textContent, "Cost 500g");
    assert.equal(firstPreset.dataset.active, "true");
    assert.equal(firstPreset.dataset.saved, "true");
    assert.equal(firstApply?.disabled, false);
    dispatchDomEvent(firstApply, "click");
    assert.deepEqual(getTurretPresetApplyEvents(), ["preset-a"]);
    dispatchDomEvent(firstClear, "click");
    assert.deepEqual(getTurretPresetClearEvents(), ["preset-a"]);

    const secondSummary = findDescendantByClass(secondPreset, "turret-preset-summary");
    const secondApply = findDescendantByClass(secondPreset, "turret-preset-apply");
    const secondSave = findDescendantByClass(secondPreset, "turret-preset-save");
    assert.equal(secondSummary?.dataset.empty, "true");
    assert.equal(secondApply?.disabled, true);
    dispatchDomEvent(secondSave, "click");
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

    const firstSlot = elements.upgradePanel.querySelector(".turret-slot");
    assert.ok(firstSlot, "expected first slot element");

    dispatchDomEvent(firstSlot, "mouseenter");
    const hoverEvents = elements.getTurretHoverEvents();
    assert.ok(hoverEvents.length > 0, "hover event should be recorded");
    const { slotId, context } = hoverEvents[hoverEvents.length - 1];
    assert.equal(slotId, "slot-1");
    assert.equal(context?.typeId, "arrow");
    assert.equal(context?.level, 2);

    dispatchDomEvent(firstSlot, "mouseleave");
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

test("announceEnemyTaunt surfaces taunts when hint is free and falls back when pinned", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { wavePreviewHint } = elements;
  try {
    const shown = hud.announceEnemyTaunt("Brutes roar down lane A!");
    assert.equal(shown, true);
    assert.equal(wavePreviewHint.dataset.visible, "true");
    assert.equal(wavePreviewHint.getAttribute("aria-hidden"), "false");
    assert.equal(wavePreviewHint.textContent, "Brutes roar down lane A!");

    hud.setWavePreviewHighlight(true, "Tutorial owns this hint.");
    const suppressed = hud.announceEnemyTaunt("Should be ignored");
    assert.equal(suppressed, false);
    assert.equal(wavePreviewHint.textContent, "Tutorial owns this hint.");
  } finally {
    cleanup();
  }
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

test("options overlay lists active castle passives", () => {
  const { hud, cleanup, elements } = initializeHud();
  try {
    const state = buildInitialState();
    state.castle.passives = [
      { id: "regen", total: 2.2, delta: 0.7 },
      { id: "armor", total: 1, delta: 1 },
      { id: "gold", total: 0.05, delta: 0.05 }
    ];
    hud.update(state, []);
    const optionList = elements.optionsCastlePassives;
    assert.equal(optionList.children.length, 3);
    const [regenItem, armorItem, goldItem] = optionList.children;
    assert.ok(regenItem?.children?.length >= 2, "regen passive entry should render icon + label");
    const regenLabel = regenItem?.children?.at?.(1)?.textContent ?? regenItem?.textContent ?? "";
    assert.match(regenLabel, /Regen 2\.2/, "regen passive text should include totals");
    const regenIcon = regenItem?.children?.at?.(0);
    const regenIconClass = regenIcon?.className ?? "";
    assert.match(regenIconClass, /passive-icon--regen/, "regen icon should be present");
    assert.equal(regenIcon?.getAttribute("role"), "img", "passive icons should expose img role");
    assert.equal(
      regenIcon?.getAttribute("aria-label"),
      "Regen passive icon",
      "passive icons should set accessible labels"
    );
    const goldLabel = goldItem?.children?.at?.(1)?.textContent ?? goldItem?.textContent ?? "";
    assert.match(goldLabel, /\+5% gold/i, "gold passive text should include percent bonus");
    const armorLabel = armorItem?.children?.at?.(1)?.textContent ?? "";
    assert.match(armorLabel, /\+1 armor/i, "armor passive text should include armor bonus");
    assert.equal(elements.optionsPassivesSummary?.textContent, "3 passives");
  } finally {
    cleanup();
  }
});

test("setPassiveHighlight accents HUD and options passive entries", () => {
  const { hud, cleanup, elements } = initializeHud();
  try {
    const state = buildInitialState();
    state.castle.passives = [
      { id: "regen", total: 1.6, delta: 0.4 },
      { id: "gold", total: 0.05, delta: 0.02 }
    ];
    hud.update(state, []);
    hud.setPassiveHighlight("regen", { autoExpand: true });
    const highlighted = elements.castlePassivesList.querySelector('[data-passive-id="regen"]');
    assert.ok(highlighted, "should locate HUD passive entry for regen");
    assert.equal(
      highlighted?.classList.contains("passive-item--highlight"),
      true,
      "highlight class should be applied"
    );
    hud.setPassiveHighlight(null);
    assert.equal(
      highlighted?.classList.contains("passive-item--highlight"),
      false,
      "highlight class should clear when disabled"
    );
  } finally {
    cleanup();
  }
});

test("options passive card collapses and notifies listeners", () => {
  const { hud, cleanup, elements } = initializeHud();
  try {
    const state = buildInitialState();
    state.castle.passives = [{ id: "regen", total: 1.2, delta: 0.4 }];
    hud.update(state, []);
    const toggle = elements.optionsPassivesToggle;
    assert.ok(toggle, "options passive toggle should exist");
    assert.equal(elements.optionsCastlePassives.dataset.visible, "true");
    dispatchDomEvent(toggle, "click");
    assert.equal(elements.optionsCastlePassives.dataset.visible, "false");
    assert.deepEqual(elements.getCollapseEvents().at(-1), { optionsPassivesCollapsed: true });
    dispatchDomEvent(toggle, "click");
    assert.equal(elements.optionsCastlePassives.dataset.visible, "true");
  } finally {
    cleanup();
  }
});

test("HUD condensed cards emit collapse preferences", () => {
  const { hud, cleanup, elements } = initializeHud();
  try {
    const state = buildInitialState();
    state.castle.passives = [{ id: "regen", total: 1.1, delta: 0.6 }];
    state.analytics.goldEvents = [
      { gold: 210, delta: 10, timestamp: 5 },
      { gold: 250, delta: 40, timestamp: 15 }
    ];
    state.time = 20;
    hud.update(state, []);
    const toggles = elements.upgradePanel.querySelectorAll(".hud-condensed-toggle");
    assert.ok(toggles.length >= 2, "expected condensed toggles for HUD cards");
    dispatchDomEvent(toggles[0], "click");
    assert.deepEqual(elements.getCollapseEvents().at(-1), { hudCastlePassivesCollapsed: true });
    dispatchDomEvent(toggles[1], "click");
    assert.deepEqual(elements.getCollapseEvents().at(-1), { hudGoldEventsCollapsed: true });
  } finally {
    cleanup();
  }
});

test("HudView exposes condensed snapshot for analytics", () => {
  const matchMediaState = {
    "(max-width: 768px)": false,
    "(max-height: 540px)": true,
    default: false
  };
  const { hud, cleanup } = initializeHud({ matchMediaState });
  try {
    hud.applyCollapsePreferences(
      {
        hudCastlePassivesCollapsed: true,
        hudGoldEventsCollapsed: false,
        optionsPassivesCollapsed: true
      },
      { silent: true }
    );
    hud.setTutorialMessage("Condensed tip incoming");
    const snapshot = hud.getCondensedState();
    assert.equal(snapshot.tutorialBannerCondensed, true);
    assert.equal(snapshot.tutorialBannerExpanded, false);
    assert.equal(snapshot.hudCastlePassivesCollapsed, true);
    assert.equal(snapshot.hudGoldEventsCollapsed, false);
    assert.equal(snapshot.optionsPassivesCollapsed, true);
    assert.equal(snapshot.compactHeight, true);
    assert.equal(snapshot.prefersCondensedLists, true);
  } finally {
    cleanup();
  }
});

test("HudView applyCollapsePreferences respects stored values", () => {
  const { hud, cleanup, elements } = initializeHud();
  try {
    const state = buildInitialState();
    state.castle.passives = [{ id: "regen", total: 1.2, delta: 0.4 }];
    state.analytics.goldEvents = [{ gold: 210, delta: 10, timestamp: 5 }];
    state.time = 12;
    hud.update(state, []);
    hud.applyCollapsePreferences(
      { hudCastlePassivesCollapsed: true, hudGoldEventsCollapsed: true, optionsPassivesCollapsed: true },
      { silent: true }
    );
    assert.equal(elements.optionsCastlePassives.dataset.visible, "false");
    const condensedContainers = elements.upgradePanel.querySelectorAll(".hud-condensed-section");
    assert.equal(condensedContainers[0]?.dataset.collapsed, "true");
    assert.equal(condensedContainers[1]?.dataset.collapsed, "true");
    hud.applyCollapsePreferences(
      { hudCastlePassivesCollapsed: false, optionsPassivesCollapsed: false },
      { silent: true }
    );
    assert.equal(condensedContainers[0]?.dataset.collapsed, "false");
    assert.equal(elements.optionsCastlePassives.dataset.visible, "true");
  } finally {
    cleanup();
  }
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
    soundIntensitySlider,
    soundIntensityValue,
    diagnosticsToggle,
    reducedMotionToggle,
    checkeredBackgroundToggle,
    readableFontToggle,
    dyslexiaFontToggle,
    dyslexiaSpacingToggle,
    cognitiveLoadToggle,
    colorblindPaletteToggle,
    telemetryToggle,
    telemetryToggleWrapper,
    hudLayoutToggle,
    hudZoomSelect,
    fontScaleSelect,
    castleSkinSelect,
    getReducedMotionToggleEvents,
    getCheckeredBackgroundToggleEvents,
    getReadableFontToggleEvents,
    getDyslexiaFontToggleEvents,
    getCognitiveLoadToggleEvents,
    getColorblindToggleEvents,
    getCastleSkinEvents,
    getSoundVolumeEvents,
    getSoundIntensityEvents,
    getTelemetryToggleEvents,
    getHudZoomEvents,
    getHudLayoutEvents,
    getFontScaleEvents
  } = elements;
  assert.ok(hud.optionsOverlay?.fontScaleSelect, "font scale select is wired");
  assert.equal(typeof hud.callbacks.onHudFontScaleChange, "function");
  const recordedFontScaleCallbacks = [];
  const originalFontScaleCallback = hud.callbacks.onHudFontScaleChange;
  hud.callbacks.onHudFontScaleChange = (value) => {
    recordedFontScaleCallbacks.push(value);
    originalFontScaleCallback?.(value);
  };
  const fontScaleChangeLogs = [];
  fontScaleSelect.addEventListener("change", () => {
    fontScaleChangeLogs.push(readSelectValue(fontScaleSelect) ?? "");
  });
  const hudZoomChangeLogs = [];
  hudZoomSelect.addEventListener("change", () => {
    hudZoomChangeLogs.push(readSelectValue(hudZoomSelect) ?? "");
  });
  const hudLayoutChangeLogs = [];
  hudLayoutToggle.addEventListener("change", () => {
    hudLayoutChangeLogs.push(hudLayoutToggle.checked);
  });

  hud.syncOptionsOverlayState({
    soundEnabled: false,
    soundVolume: 0.8,
    soundIntensity: 1,
    screenShakeEnabled: false,
    screenShakeIntensity: 0.65,
    diagnosticsVisible: false,
    reducedMotionEnabled: true,
    checkeredBackgroundEnabled: false,
    readableFontEnabled: false,
    dyslexiaFontEnabled: false,
    dyslexiaSpacingEnabled: false,
    reducedCognitiveLoadEnabled: false,
    colorblindPaletteEnabled: false,
    castleSkin: "aurora",
    hudLayout: "right",
    hudZoom: 1,
    hudFontScale: 1,
    telemetry: { available: false, checked: false, disabled: true }
  });
  assert.equal(soundToggle.checked, false);
  assert.equal(soundVolumeSlider.value, "0.8");
  assert.equal(soundVolumeValue.textContent, "80%");
  assert.equal(soundVolumeSlider.disabled, true);
  assert.equal(soundVolumeSlider.getAttribute("aria-disabled"), "true");
  assert.equal(soundIntensitySlider.value, "1");
  assert.equal(soundIntensityValue.textContent, "100%");
  assert.equal(soundIntensitySlider.disabled, true);
  assert.equal(soundIntensitySlider.getAttribute("aria-disabled"), "true");
  assert.equal(elements.screenShakeToggle.disabled, true);
  assert.equal(elements.screenShakeSlider.disabled, true);
  assert.equal(elements.screenShakePreview.dataset.disabled, "true");
  assert.ok(elements.screenShakeValue.textContent.includes("65"));
  assert.equal(diagnosticsToggle.checked, false);
  assert.equal(reducedMotionToggle.checked, true);
  assert.equal(checkeredBackgroundToggle.checked, false);
  assert.equal(readableFontToggle.checked, false);
  assert.equal(dyslexiaFontToggle.checked, false);
  assert.equal(dyslexiaSpacingToggle.checked, false);
  assert.equal(cognitiveLoadToggle.checked, false);
  assert.equal(colorblindPaletteToggle.checked, false);
  assert.equal(telemetryToggle.checked, false);
  assert.equal(telemetryToggle.disabled, true);
  assert.equal(telemetryToggleWrapper.style.display, "none");
  assert.equal(readSelectValue(hudZoomSelect), "1");
  assert.equal(hudLayoutToggle.checked, false);
  assert.equal(readSelectValue(fontScaleSelect), "1");
  assert.equal(readSelectValue(castleSkinSelect), "aurora");
  assert.equal(document.body.dataset.castleSkin, "aurora");
  assert.equal(hud.isOptionsOverlayVisible(), false);

  hud.syncOptionsOverlayState({
    soundEnabled: true,
    soundVolume: 0.8,
    soundIntensity: 1,
    screenShakeEnabled: true,
    screenShakeIntensity: 0.7,
    diagnosticsVisible: false,
    reducedMotionEnabled: true,
    checkeredBackgroundEnabled: false,
    readableFontEnabled: false,
    dyslexiaFontEnabled: false,
    dyslexiaSpacingEnabled: false,
    reducedCognitiveLoadEnabled: false,
    colorblindPaletteEnabled: false,
    castleSkin: "aurora",
    hudLayout: "right",
    hudZoom: 1,
    hudFontScale: 1,
    telemetry: { available: false, checked: false, disabled: true }
  });
  assert.equal(soundToggle.checked, true);
  assert.equal(soundVolumeSlider.disabled, false);
  assert.equal(soundVolumeSlider.getAttribute("aria-disabled"), "false");
  assert.equal(soundIntensitySlider.disabled, false);
  assert.equal(soundIntensitySlider.getAttribute("aria-disabled"), "false");
  assert.equal(elements.screenShakeToggle.disabled, true);
  assert.equal(elements.screenShakeSlider.disabled, true);

  hud.syncOptionsOverlayState({
    soundEnabled: true,
    soundVolume: 0.55,
    soundIntensity: 1.25,
    screenShakeEnabled: true,
    screenShakeIntensity: 1.1,
    diagnosticsVisible: false,
    reducedMotionEnabled: true,
    checkeredBackgroundEnabled: false,
    readableFontEnabled: false,
    dyslexiaFontEnabled: true,
    dyslexiaSpacingEnabled: true,
    reducedCognitiveLoadEnabled: true,
    colorblindPaletteEnabled: true,
    castleSkin: "aurora",
    hudLayout: "left",
    hudZoom: 1.1,
    hudFontScale: 1.15,
    telemetry: { available: true, checked: true, disabled: false }
  });
  assert.equal(soundVolumeSlider.value, "0.55");
  assert.equal(soundVolumeValue.textContent, "55%");
  assert.equal(soundIntensitySlider.value, "1.25");
  assert.equal(soundIntensityValue.textContent, "125%");
  assert.equal(elements.screenShakeSlider.value, "1.1");
  assert.ok(elements.screenShakeValue.textContent.includes("110"));
  assert.equal(colorblindPaletteToggle.checked, true);
  assert.equal(telemetryToggleWrapper.style.display, "");
  assert.equal(telemetryToggle.disabled, false);
  assert.equal(telemetryToggle.checked, true);
  assert.equal(dyslexiaSpacingToggle.checked, true);
  assert.equal(cognitiveLoadToggle.checked, true);
  assert.equal(readSelectValue(hudZoomSelect), "1.1");
  assert.equal(hudLayoutToggle.checked, true);

  hud.showOptionsOverlay();
  assert.equal(optionsOverlay.dataset.visible, "true");
  assert.equal(hud.isOptionsOverlayVisible(), true);

  reducedMotionToggle.checked = false;
  dispatchDomEvent(reducedMotionToggle, "change");
  assert.deepEqual(getReducedMotionToggleEvents(), [false]);
  hud.syncOptionsOverlayState({
    soundEnabled: true,
    soundVolume: 0.55,
    soundIntensity: 1.1,
    screenShakeEnabled: true,
    screenShakeIntensity: 0.8,
    diagnosticsVisible: false,
    reducedMotionEnabled: false,
    checkeredBackgroundEnabled: false,
    readableFontEnabled: false,
    dyslexiaFontEnabled: true,
    dyslexiaSpacingEnabled: true,
    reducedCognitiveLoadEnabled: true,
    colorblindPaletteEnabled: true,
    hudLayout: "left",
    hudZoom: 1.1,
    hudFontScale: 1.15,
    telemetry: { available: true, checked: true, disabled: false }
  });
  assert.equal(elements.screenShakeToggle.disabled, false);
  assert.equal(elements.screenShakeSlider.disabled, false);
  assert.equal(elements.screenShakeToggle.checked, true);
  assert.equal(elements.screenShakeSlider.value, "0.8");

  checkeredBackgroundToggle.checked = true;
  dispatchDomEvent(checkeredBackgroundToggle, "change");
  assert.deepEqual(getCheckeredBackgroundToggleEvents(), [true]);

  readableFontToggle.checked = true;
  dispatchDomEvent(readableFontToggle, "change");
  assert.deepEqual(getReadableFontToggleEvents(), [true]);

  assert.equal(dyslexiaFontToggle.checked, true);
  dyslexiaFontToggle.checked = false;
  dispatchDomEvent(dyslexiaFontToggle, "change");
  assert.deepEqual(getDyslexiaFontToggleEvents(), [false]);

  cognitiveLoadToggle.checked = false;
  dispatchDomEvent(cognitiveLoadToggle, "change");
  assert.deepEqual(getCognitiveLoadToggleEvents(), [false]);

  soundVolumeSlider.value = "0.6";
  dispatchDomEvent(soundVolumeSlider, "input");
  assert.deepEqual(getSoundVolumeEvents(), [0.6]);
  assert.equal(soundVolumeValue.textContent, "60%");

  soundIntensitySlider.value = "1.3";
  dispatchDomEvent(soundIntensitySlider, "input");
  assert.deepEqual(getSoundIntensityEvents(), [1.3]);
  assert.equal(soundIntensityValue.textContent, "130%");

  colorblindPaletteToggle.checked = true;
  dispatchDomEvent(colorblindPaletteToggle, "change");
  assert.deepEqual(getColorblindToggleEvents(), [true]);

  telemetryToggle.checked = false;
  dispatchDomEvent(telemetryToggle, "change");
  assert.deepEqual(getTelemetryToggleEvents(), [false]);

  setSelectValueForElement(castleSkinSelect, "dusk");
  dispatchDomEvent(castleSkinSelect, "change");
  assert.deepEqual(getCastleSkinEvents(), ["dusk"]);
  assert.equal(document.body.dataset.castleSkin, "dusk");

  setSelectValueForElement(fontScaleSelect, "1.2");
  assert.equal(readSelectValue(fontScaleSelect), "1.2");
  dispatchDomEvent(fontScaleSelect, "change");
  assert.deepEqual(fontScaleChangeLogs, ["1.2"]);
  assert.deepEqual(recordedFontScaleCallbacks, [1.2]);
  assert.deepEqual(getFontScaleEvents(), [1.2]);

  setSelectValueForElement(hudZoomSelect, "1.2");
  assert.equal(readSelectValue(hudZoomSelect), "1.2");
  dispatchDomEvent(hudZoomSelect, "change");
  assert.deepEqual(hudZoomChangeLogs, ["1.2"]);
  assert.deepEqual(getHudZoomEvents(), [1.2]);

  hudLayoutToggle.checked = false;
  dispatchDomEvent(hudLayoutToggle, "change");
  assert.deepEqual(hudLayoutChangeLogs, [false]);
  assert.deepEqual(getHudLayoutEvents(), [false]);

  hud.hideOptionsOverlay();
  assert.equal(optionsOverlay.dataset.visible, "false");
  assert.equal(hud.isOptionsOverlayVisible(), false);

  cleanup();
});

test("Companion pet reflects performance mood cues", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { companionPet, companionMoodLabel } = elements;

  const baseState = buildInitialState();
  hud.update(baseState, []);
  assert.equal(companionPet.dataset.mood, "calm");
  assert.equal(companionMoodLabel.textContent, "Calm");

  const hypeState = structuredClone(baseState);
  hypeState.typing.accuracy = 0.97;
  hypeState.typing.combo = 30;
  hypeState.analytics.sessionBestCombo = 30;
  hud.update(hypeState, []);
  assert.equal(companionPet.dataset.mood, "cheer");
  assert.ok((companionMoodLabel.textContent ?? "").toLowerCase().includes("cheer"));

  const sadState = structuredClone(baseState);
  sadState.castle.health = sadState.castle.maxHealth * 0.2;
  sadState.analytics.sessionBreaches = 1;
  hud.update(sadState, []);
  assert.equal(companionPet.dataset.mood, "sad");
  assert.ok((companionMoodLabel.textContent ?? "").toLowerCase().includes("concern"));

  cleanup();
});

test("HudView screen shake controls emit events and preview animation", () => {
  const { cleanup, elements } = initializeHud();
  const { screenShakeToggle, screenShakeSlider, screenShakePreview, screenShakeValue } = elements;

  screenShakeToggle.checked = true;
  dispatchDomEvent(screenShakeToggle, "change");
  screenShakeSlider.value = "0.9";
  dispatchDomEvent(screenShakeSlider, "input");
  screenShakePreview.click();

  assert.deepEqual(elements.getScreenShakeToggleEvents(), [true]);
  assert.equal(elements.getScreenShakeIntensityEvents().at(-1), 0.9);
  assert.equal(elements.getScreenShakePreviewEvents().length, 1);
  assert.ok(screenShakeValue.textContent.includes("90"));

  cleanup();
});

test("HudView accessibility self-test respects availability states", () => {
  const { hud, cleanup, elements } = initializeHud();
  const baseState = {
    soundEnabled: false,
    soundVolume: 0.8,
    soundIntensity: 1,
    screenShakeEnabled: false,
    screenShakeIntensity: 0.65,
    selfTest: {
      lastRunAt: null,
      soundConfirmed: true,
      visualConfirmed: true,
      motionConfirmed: true
    },
    diagnosticsVisible: false,
    lowGraphicsEnabled: false,
    virtualKeyboardEnabled: false,
    hapticsEnabled: false,
    textSizeScale: 1,
    reducedMotionEnabled: true,
    checkeredBackgroundEnabled: false,
    readableFontEnabled: false,
    dyslexiaFontEnabled: false,
    dyslexiaSpacingEnabled: false,
    reducedCognitiveLoadEnabled: false,
    backgroundBrightness: 1,
    colorblindPaletteEnabled: false,
    colorblindPaletteMode: "off",
    hudZoom: 1,
    hudLayout: "right",
    hudFontScale: 1,
    defeatAnimationMode: "auto",
    telemetry: { available: false, checked: false, disabled: true }
  };

  hud.syncOptionsOverlayState(baseState);
  assert.equal(elements.selfTestSoundToggle.disabled, true);
  assert.equal(elements.selfTestMotionToggle.disabled, true);
  assert.equal(elements.selfTestVisualToggle.disabled, false);
  assert.equal(elements.selfTestStatus.textContent, "Not run yet");

  hud.syncOptionsOverlayState({
    ...baseState,
    soundEnabled: true,
    reducedMotionEnabled: false,
    selfTest: {
      lastRunAt: "2025-12-14T10:15:00.000Z",
      soundConfirmed: true,
      visualConfirmed: true,
      motionConfirmed: true
    }
  });
  assert.equal(elements.selfTestSoundToggle.disabled, false);
  assert.equal(elements.selfTestMotionToggle.disabled, false);
  assert.equal(elements.selfTestSoundToggle.checked, true);
  assert.equal(elements.selfTestMotionToggle.checked, true);
  assert.ok(elements.selfTestStatus.textContent.includes("2025-12-14"));

  cleanup();
});

test("HudView accessibility self-test emits callbacks and plays cues", () => {
  const { hud, cleanup, elements } = initializeHud();
  const baseState = {
    soundEnabled: true,
    soundVolume: 0.8,
    soundIntensity: 1,
    screenShakeEnabled: true,
    screenShakeIntensity: 0.8,
    selfTest: {
      lastRunAt: null,
      soundConfirmed: false,
      visualConfirmed: false,
      motionConfirmed: false
    },
    diagnosticsVisible: false,
    lowGraphicsEnabled: false,
    virtualKeyboardEnabled: false,
    hapticsEnabled: false,
    textSizeScale: 1,
    reducedMotionEnabled: false,
    checkeredBackgroundEnabled: false,
    readableFontEnabled: false,
    dyslexiaFontEnabled: false,
    dyslexiaSpacingEnabled: false,
    reducedCognitiveLoadEnabled: false,
    backgroundBrightness: 1,
    colorblindPaletteEnabled: false,
    colorblindPaletteMode: "off",
    hudZoom: 1,
    hudLayout: "right",
    hudFontScale: 1,
    defeatAnimationMode: "auto",
    telemetry: { available: false, checked: false, disabled: true }
  };

  hud.syncOptionsOverlayState(baseState);
  elements.selfTestRun.click();
  elements.selfTestSoundToggle.checked = true;
  dispatchDomEvent(elements.selfTestSoundToggle, "change");
  elements.selfTestVisualToggle.checked = true;
  dispatchDomEvent(elements.selfTestVisualToggle, "change");
  elements.selfTestMotionToggle.checked = true;
  dispatchDomEvent(elements.selfTestMotionToggle, "change");
  hud.playAccessibilitySelfTestCues({ includeMotion: true, soundEnabled: true });

  assert.equal(elements.getSelfTestRunEvents().length, 1);
  assert.deepEqual(elements.getSelfTestConfirmEvents(), [
    { kind: "sound", confirmed: true },
    { kind: "visual", confirmed: true },
    { kind: "motion", confirmed: true }
  ]);
  assert.equal(elements.selfTestSoundIndicator.dataset.active, "true");
  assert.equal(elements.selfTestMotionIndicator.dataset.active, "true");

  cleanup();
});

test("HudView contrast audit overlay toggles and lists results", () => {
  const { hud, cleanup, elements } = initializeHud();
  assert.equal(elements.contrastOverlay.dataset.visible, "false");
  elements.contrastAuditButton.click();
  assert.equal(elements.getContrastAuditEvents().length, 1);

  hud.presentContrastAudit([
    { label: "Option toggle", ratio: 3.2, status: "warn", rect: { x: 0, y: 0, width: 50, height: 20 } },
    { label: "Battle log", ratio: 2.4, status: "fail", rect: { x: 10, y: 10, width: 30, height: 15 } }
  ]);

  assert.equal(elements.contrastOverlay.dataset.visible, "true");
  assert.equal(elements.contrastOverlayList.children.length, 2);
  assert.ok(elements.contrastOverlaySummary.textContent.includes("2"));
  assert.equal(elements.contrastOverlayMarkers.children.length, 2);

  hud.hideContrastOverlay();
  assert.equal(elements.contrastOverlay.dataset.visible, "false");
  assert.equal(elements.contrastOverlayList.children.length, 0);
  cleanup();
});

test("HudView sticker book overlay renders entries and toggles visibility", () => {
  const { hud, cleanup, elements } = initializeHud();
  hud.setStickerBookEntries([
    {
      id: "combo-cub",
      title: "Combo Cub",
      description: "Reach a 3x combo in any wave.",
      icon: "combo",
      status: "unlocked",
      progress: 3,
      goal: 3
    },
    {
      id: "gold-glider",
      title: "Gold Glider",
      description: "Hold 200 gold in your purse.",
      icon: "treasure",
      status: "in-progress",
      progress: 1,
      goal: 3
    }
  ]);

  assert.equal(elements.stickerOverlay.dataset.visible, "false");
  elements.stickerBookButton.click();
  assert.equal(elements.stickerOverlay.dataset.visible, "true");
  assert.equal(elements.stickerOverlayList.children.length, 2);
  assert.ok(elements.stickerOverlaySummary.textContent.includes("2"));

  const firstSticker = elements.stickerOverlayList.children[0];
  assert.equal(firstSticker.dataset.status, "unlocked");

  hud.hideStickerBookOverlay();
  assert.equal(elements.stickerOverlay.dataset.visible, "false");
  cleanup();
});

test("HudView lore scroll overlay renders progress and entries", () => {
  const { hud, cleanup, elements } = initializeHud();
  hud.setLoreScrollProgress({
    lessonsCompleted: 3,
    total: 5,
    unlocked: 2,
    next: { requiredLessons: 5, remaining: 2, title: "Signal Flares" },
    entries: [
      {
        id: "scroll-one",
        title: "First Scroll",
        summary: "Quick recap",
        body: "Unlocked snippet text.",
        requiredLessons: 1,
        unlocked: true,
        progress: 3,
        remaining: 0
      },
      {
        id: "scroll-two",
        title: "Second Scroll",
        summary: "Needs more lessons",
        body: "Locked snippet text.",
        requiredLessons: 5,
        unlocked: false,
        progress: 3,
        remaining: 2
      }
    ]
  });

  assert.equal(elements.loreScrollsProgress.textContent, "2 / 5 scrolls");
  assert.equal(elements.loreScrollsLessons.textContent, "3 lessons completed");
  assert.ok(elements.loreScrollsNext.textContent.includes("2 more"));

  assert.equal(elements.scrollOverlay.dataset.visible, "false");
  elements.optionsLoreScrollsButton.click();
  assert.equal(elements.scrollOverlay.dataset.visible, "true");
  assert.equal(elements.scrollOverlayList.children.length, 2);
  const firstScroll = elements.scrollOverlayList.children[0];
  assert.equal(firstScroll.dataset.status, "unlocked");

  hud.hideLoreScrollOverlay();
  assert.equal(elements.scrollOverlay.dataset.visible, "false");
  cleanup();
});

test("HudView season track overlay renders rewards and toggles visibility", () => {
  const { hud, cleanup, elements } = initializeHud();
  hud.setSeasonTrackProgress({
    lessonsCompleted: 6,
    total: 10,
    unlocked: 3,
    next: { requiredLessons: 7, remaining: 1, title: "Castle Accent" },
    entries: [
      {
        id: "tier-01",
        title: "Welcome Bundle",
        description: "Castle banner + gold.",
        requiredLessons: 1,
        unlocked: true,
        progress: 1,
        remaining: 0
      },
      {
        id: "tier-02",
        title: "Sticker Pack",
        description: "Unlocks stickers.",
        requiredLessons: 3,
        unlocked: true,
        progress: 3,
        remaining: 0
      },
      {
        id: "tier-03",
        title: "Trail Particles",
        description: "Arrow embers.",
        requiredLessons: 5,
        unlocked: true,
        progress: 5,
        remaining: 0
      },
      {
        id: "tier-04",
        title: "Castle Accent",
        description: "New accent skin.",
        requiredLessons: 7,
        unlocked: false,
        progress: 6,
        remaining: 1
      }
    ]
  });

  assert.equal(elements.seasonTrackProgress.textContent, "3 / 10 unlocked");
  assert.ok(elements.seasonTrackLessons.textContent.includes("lessons completed"));
  assert.equal(elements.seasonTrackOverlay.dataset.visible, "false");
  elements.optionsSeasonTrackButton.click();
  assert.equal(elements.seasonTrackOverlay.dataset.visible, "true");
  assert.equal(elements.seasonTrackList.children.length, 4);
  hud.hideSeasonTrackOverlay();
  assert.equal(elements.seasonTrackOverlay.dataset.visible, "false");
  cleanup();
});

test("HudView mastery certificate overlay renders stats and toggles visibility", () => {
  const { hud, cleanup, elements } = initializeHud();
  hud.setMasteryCertificate({
    lessonsCompleted: 7,
    accuracyPct: 96,
    wpm: 54,
    bestCombo: 12,
    drillsCompleted: 3,
    timeMinutes: 42,
    recordedAt: new Date("2025-12-21T00:00:00Z").toISOString()
  });
  assert.ok(elements.masteryCertificateSummary.textContent.includes("Learner"));
  assert.ok(elements.masteryCertificateStats.textContent.includes("lessons"));
  elements.optionsMasteryCertificateButton.click();
  assert.equal(elements.masteryCertificateOverlay.dataset.visible, "true");
  assert.ok(elements.masteryCertificateOverlaySummary.textContent.includes("accuracy"));
  assert.ok(elements.masteryCertificateOverlayDate.textContent.length > 0);
  assert.ok(elements.masteryCertificateStatsList.children.length > 0);
  hud.hideMasteryCertificateOverlay();
  assert.equal(elements.masteryCertificateOverlay.dataset.visible, "false");
  cleanup();
});

test("HudView milestone celebration fires for gold medals and lesson milestones", () => {
  const { hud, cleanup, elements } = initializeHud();
  hud.setLessonMedalProgress({
    last: {
      id: "medal-10",
      tier: "gold",
      mode: "precision",
      accuracy: 0.975,
      wpm: 58,
      bestCombo: 9,
      errors: 0,
      words: 10,
      elapsedMs: 24000,
      timestamp: 10
    },
    recent: [],
    bestByMode: { burst: null, endurance: null, precision: null },
    totals: { bronze: 0, silver: 0, gold: 1, platinum: 0 },
    nextTarget: null
  });
  assert.equal(elements.milestoneCelebration.dataset.visible, "true");
  assert.ok(elements.milestoneCelebrationTitle.textContent.includes("Gold"));
  hud.hideMilestoneCelebration();
  assert.equal(elements.milestoneCelebration.dataset.visible, "false");

  const state = buildInitialState();
  hud.update(state, [], { lessonsCompleted: 5 });
  assert.equal(elements.milestoneCelebration.dataset.visible, "true");
  assert.ok(elements.milestoneCelebrationBadge.textContent.length > 0);
  cleanup();
});

test("Options quick nav updates aria-current and keeps sections reachable", () => {
  const { cleanup, elements } = initializeHud();
  const navButtons = elements.optionsQuickNav.querySelectorAll("button");
  assert.ok(navButtons.length >= 3);
  navButtons[1].click();
  assert.equal(navButtons[1].getAttribute("aria-current"), "true");
  assert.equal(navButtons[0].getAttribute("aria-current"), "false");
  cleanup();
});

test("Options sections can be collapsed and expanded", () => {
  const { cleanup, elements } = initializeHud();
  const toggles = elements.getOptionsSectionToggles();
  assert.ok(toggles.length >= 2);
  const section = toggles[0].closest(".options-section");
  assert.ok(section);
  assert.equal(section.dataset.collapsed, "false");
  toggles[0].click();
  assert.equal(section.dataset.collapsed, "true");
  toggles[0].click();
  assert.equal(section.dataset.collapsed, "false");
  cleanup();
});

test("HudView mentor dialogue adapts focus between accuracy and speed", () => {
  const { hud, cleanup, elements } = initializeHud();
  const accuracyState = buildInitialState();
  accuracyState.time = 60;
  accuracyState.typing.totalInputs = 50;
  accuracyState.typing.correctInputs = 40;
  accuracyState.typing.accuracy = 0.8;
  hud.update(accuracyState, []);
  assert.equal(elements.mentorDialogue.dataset.focus, "accuracy");
  assert.ok(elements.mentorDialogueText.textContent.toLowerCase().includes("accuracy"));

  const speedState = structuredClone(accuracyState);
  speedState.time = 180;
  speedState.typing.totalInputs = 82;
  speedState.typing.correctInputs = 80;
  speedState.typing.accuracy = 0.98;
  hud.update(speedState, []);
  assert.equal(elements.mentorDialogue.dataset.focus, "speed");
  assert.ok(elements.mentorDialogueText.textContent.toLowerCase().includes("speed"));
  cleanup();
});

test("HudView museum overlay renders entries and toggles visibility", () => {
  const { hud, cleanup, elements } = initializeHud();
  hud.setSeasonTrackProgress({
    lessonsCompleted: 6,
    total: 10,
    unlocked: 3,
    next: { requiredLessons: 7, remaining: 1, title: "Castle Accent" },
    entries: []
  });
  hud.setLessonMedalProgress({
    last: {
      id: "medal-10",
      tier: "gold",
      mode: "precision",
      accuracy: 0.975,
      wpm: 58,
      bestCombo: 9,
      errors: 0,
      words: 10,
      elapsedMs: 24000,
      timestamp: 10
    },
    recent: [],
    bestByMode: { burst: null, endurance: null, precision: null },
    totals: { bronze: 0, silver: 0, gold: 1, platinum: 0 },
    nextTarget: null
  });
  hud.setLoreScrollProgress({
    lessonsCompleted: 6,
    total: 5,
    unlocked: 2,
    next: { requiredLessons: 7, remaining: 1, title: "Archive Log" },
    entries: []
  });
  hud.setMasteryCertificate({
    lessonsCompleted: 7,
    accuracyPct: 96,
    wpm: 54,
    bestCombo: 12,
    drillsCompleted: 3,
    timeMinutes: 42,
    recordedAt: new Date("2025-12-21T00:00:00Z").toISOString()
  });
  elements.museumOpen.click();
  assert.equal(elements.museumOverlay.dataset.visible, "true");
  assert.ok(elements.museumList.children.length >= 5);
  hud.hideMuseumOverlay();
  assert.equal(elements.museumOverlay.dataset.visible, "false");
  cleanup();
});

test("HudView museum overlay filters locked and unlocked entries", () => {
  const { hud, cleanup, elements } = initializeHud();
  hud.setLoreScrollProgress({
    lessonsCompleted: 0,
    total: 6,
    unlocked: 0,
    next: { requiredLessons: 5, remaining: 5, title: "Library Ledger" },
    entries: []
  });
  hud.setLessonMedalProgress({
    last: null,
    recent: [],
    bestByMode: { burst: null, endurance: null, precision: null },
    totals: { bronze: 0, silver: 0, gold: 0, platinum: 0 },
    nextTarget: null
  });
  const state = buildInitialState();
  hud.update(state, [], { lessonsCompleted: 0 });
  elements.museumOpen.click();
  const filterButtons = Array.from(document.querySelectorAll(".museum-filter"));
  const allCount = elements.museumList.children.length;
  const unlockedBtn = filterButtons.find((btn) => btn.dataset.museumFilter === "unlocked");
  unlockedBtn?.click();
  const unlockedCount = elements.museumList.children.length;
  assert.ok(allCount >= unlockedCount);
  cleanup();
});

test("HudView side quest overlay renders quests and toggles visibility", () => {
  const { hud, cleanup, elements } = initializeHud();
  hud.setLoreScrollProgress({
    lessonsCompleted: 4,
    total: 6,
    unlocked: 2,
    next: { requiredLessons: 5, remaining: 1, title: "Library Ledger" },
    entries: []
  });
  hud.setLessonMedalProgress({
    last: {
      id: "medal-quest",
      tier: "gold",
      mode: "burst",
      accuracy: 0.97,
      wpm: 55,
      bestCombo: 8,
      errors: 0,
      words: 10,
      elapsedMs: 23000,
      timestamp: 456
    },
    recent: [
      {
        id: "recent-1",
        tier: "silver",
        mode: "burst",
        accuracy: 0.94,
        wpm: 42,
        bestCombo: 5,
        errors: 1,
        words: 9,
        elapsedMs: 25000,
        timestamp: 300
      },
      {
        id: "recent-2",
        tier: "bronze",
        mode: "endurance",
        accuracy: 0.9,
        wpm: 35,
        bestCombo: 4,
        errors: 3,
        words: 12,
        elapsedMs: 31000,
        timestamp: 301
      },
      {
        id: "recent-3",
        tier: "gold",
        mode: "precision",
        accuracy: 0.96,
        wpm: 48,
        bestCombo: 6,
        errors: 1,
        words: 11,
        elapsedMs: 28000,
        timestamp: 302
      },
      {
        id: "recent-4",
        tier: "silver",
        mode: "burst",
        accuracy: 0.92,
        wpm: 40,
        bestCombo: 4,
        errors: 2,
        words: 10,
        elapsedMs: 26000,
        timestamp: 303
      },
      {
        id: "recent-5",
        tier: "silver",
        mode: "burst",
        accuracy: 0.93,
        wpm: 41,
        bestCombo: 4,
        errors: 2,
        words: 10,
        elapsedMs: 25500,
        timestamp: 304
      }
    ],
    bestByMode: { burst: null, endurance: null, precision: null },
    totals: { bronze: 1, silver: 2, gold: 1, platinum: 0 },
    nextTarget: null
  });
  const state = buildInitialState();
  hud.update(state, [], { lessonsCompleted: 5 });
  elements.optionsSideQuestButton.click();
  assert.equal(elements.sideQuestOverlay.dataset.visible, "true");
  assert.ok(elements.sideQuestList.children.length >= 4);
  assert.ok(elements.sideQuestSubtitle.textContent.includes("quests completed"));
  elements.sideQuestClose.click();
  assert.equal(elements.sideQuestOverlay.dataset.visible, "false");
  cleanup();
});

test("Side quest overlay filters between active and completed quests", () => {
  const { hud, cleanup, elements } = initializeHud();
  hud.setLoreScrollProgress({
    lessonsCompleted: 4,
    total: 6,
    unlocked: 2,
    next: { requiredLessons: 5, remaining: 1, title: "Library Ledger" },
    entries: []
  });
  hud.setLessonMedalProgress({
    last: {
      id: "medal-quest",
      tier: "gold",
      mode: "burst",
      accuracy: 0.97,
      wpm: 55,
      bestCombo: 8,
      errors: 0,
      words: 10,
      elapsedMs: 23000,
      timestamp: 456
    },
    recent: [],
    bestByMode: { burst: null, endurance: null, precision: null },
    totals: { bronze: 0, silver: 0, gold: 1, platinum: 0 },
    nextTarget: null
  });
  const state = buildInitialState();
  hud.update(state, [], { lessonsCompleted: 5 });
  elements.optionsSideQuestButton.click();
  const filters = Array.from(document.querySelectorAll(".quest-filter"));
  const allCount = elements.sideQuestList.children.length;
  const activeBtn = filters.find((btn) => btn.dataset.questFilter === "active");
  const completedBtn = filters.find((btn) => btn.dataset.questFilter === "completed");
  assert.ok(allCount >= 1);
  activeBtn?.click();
  const activeCount = elements.sideQuestList.children.length;
  completedBtn?.click();
  const completedCount = elements.sideQuestList.children.length;
  assert.ok(activeCount < allCount || completedCount < allCount);
  cleanup();
});

test("HudView lesson medals overlay renders and toggles visibility", () => {
  const { hud, cleanup, elements } = initializeHud();
  hud.setLessonMedalProgress({
    last: {
      id: "medal-1",
      tier: "gold",
      mode: "precision",
      accuracy: 0.965,
      wpm: 42,
      bestCombo: 7,
      errors: 0,
      words: 8,
      elapsedMs: 25000,
      timestamp: 1234
    },
    recent: [
      {
        id: "medal-2",
        tier: "silver",
        mode: "burst",
        accuracy: 0.92,
        wpm: 32,
        bestCombo: 4,
        errors: 2,
        words: 5,
        elapsedMs: 15000,
        timestamp: 1200
      }
    ],
    bestByMode: {
      burst: {
        id: "medal-2",
        tier: "silver",
        mode: "burst",
        accuracy: 0.92,
        wpm: 32,
        bestCombo: 4,
        errors: 2,
        words: 5,
        elapsedMs: 15000,
        timestamp: 1200
      },
      endurance: null,
      precision: {
        id: "medal-1",
        tier: "gold",
        mode: "precision",
        accuracy: 0.965,
        wpm: 42,
        bestCombo: 7,
        errors: 0,
        words: 8,
        elapsedMs: 25000,
        timestamp: 1234
      }
    },
    totals: { bronze: 0, silver: 1, gold: 1, platinum: 0 },
    nextTarget: { tier: "platinum", hint: "Replay for Platinum: hold 98% accuracy and combo x7." }
  });

  assert.equal(elements.lessonMedalBadge.dataset.tier, "gold");
  assert.ok(elements.lessonMedalSummary.textContent.includes("Gold"));
  assert.ok(elements.lessonMedalBest.textContent.includes("Burst"));
  assert.equal(elements.lessonMedalOverlay.dataset.visible, "false");
  elements.optionsLessonMedalsButton.click();
  assert.equal(elements.lessonMedalOverlay.dataset.visible, "true");
  assert.ok(elements.lessonMedalOverlayLast.textContent.includes("Shield Breaker"));
  assert.ok(elements.lessonMedalOverlayNext.textContent.includes("Platinum"));
  assert.equal(elements.lessonMedalList.children.length, 3);
  assert.ok(elements.lessonMedalHistory.children.length >= 1);
  hud.hideLessonMedalOverlay();
  assert.equal(elements.lessonMedalOverlay.dataset.visible, "false");
  cleanup();
});

test("HudView parent summary overlay renders session stats and toggles visibility", () => {
  const { hud, cleanup, elements } = initializeHud();
  hud.update(
    {
      time: 600,
      mode: "campaign",
      wave: { index: 2, total: 5, inCountdown: false, timeInWave: 0, countdownRemaining: 0 },
      castle: { level: 1, health: 100, maxHealth: 100 },
      typing: { accuracy: 0.9, correctInputs: 150, totalInputs: 160, combo: 4, buffer: "", activeEnemyId: null },
      enemies: [],
      turrets: [],
      resources: { gold: 50 },
      projectiles: [],
      analytics: {
        sessionBreaches: 1,
        totalPerfectWords: 7,
        wavePerfectWords: 0,
        waveHistory: [],
        waveSummaries: [],
        sessionBestCombo: 12,
        waveMaxCombo: 0,
        totalCastleRepairs: 2,
        typingDrills: [
          {
            mode: "burst",
            accuracy: 0.8,
            bestCombo: 3,
            words: 5,
            errors: 1,
            elapsedMs: 20000,
            timestamp: Date.now(),
            wpm: 30,
            source: "cta"
          }
        ]
      }
    },
    []
  );

  assert.equal(elements.parentSummaryOverlay.dataset.visible, "false");
  elements.optionsParentSummaryButton.click();
  assert.equal(elements.parentSummaryOverlay.dataset.visible, "true");
  assert.ok(elements.parentSummaryProgress.textContent.includes("accuracy"));
  assert.equal(elements.parentSummaryAccuracy.textContent, "90%");

  hud.hideParentSummary();
  assert.equal(elements.parentSummaryOverlay.dataset.visible, "false");
  cleanup();
});

test("HudView toggles canvas transition dataset and classes", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { hudRoot } = elements;
  assert.ok(hudRoot, "hud root is available");
  try {
    hud.setCanvasTransitionState("running");
    assert.equal(hudRoot.dataset.canvasTransition, "running");
    assert.ok(hudRoot.classList.contains("hud--canvas-transition"));
    hud.setCanvasTransitionState("idle");
    assert.equal(hudRoot.dataset.canvasTransition, "idle");
    assert.equal(hudRoot.classList.contains("hud--canvas-transition"), false);
  } finally {
    cleanup();
  }
});

test("HudView updates reduced-motion dataset when preference changes", () => {
  const { hud, cleanup, elements } = initializeHud();
  const { hudRoot } = elements;
  assert.ok(hudRoot, "hud root is available");
  try {
    hud.setReducedMotionEnabled(true);
    assert.equal(document.body.dataset.reducedMotion, "true");
    assert.equal(document.documentElement.dataset.reducedMotion, "true");
    assert.equal(hudRoot.dataset.reducedMotion, "true");
    hud.setReducedMotionEnabled(false);
    assert.equal(document.body.dataset.reducedMotion, "false");
    assert.equal(document.documentElement.dataset.reducedMotion, "false");
    assert.equal(hudRoot.dataset.reducedMotion, "false");
  } finally {
    cleanup();
  }
});

test("HudView toggles analytics export availability", () => {
  const { hud, cleanup, elements, getAnalyticsExportEvents } = initializeHud();
  const { analyticsExportButton } = elements;

  hud.setAnalyticsExportEnabled(false);
  assert.equal(analyticsExportButton.style.display, "none");
  assert.equal(analyticsExportButton.disabled, true);
  assert.equal(analyticsExportButton.getAttribute("aria-hidden"), "true");
  assert.equal(analyticsExportButton.getAttribute("tabindex"), "-1");

  hud.setAnalyticsExportEnabled(true);
  assert.equal(analyticsExportButton.style.display, "");
  assert.equal(analyticsExportButton.disabled, false);
  assert.equal(analyticsExportButton.getAttribute("aria-hidden"), "false");
  assert.equal(analyticsExportButton.getAttribute("tabindex"), "0");

  dispatchDomEvent(analyticsExportButton, "click");
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

  setSelectValueForElement(analyticsFilterSelect, "last-5");
  dispatchDomEvent(analyticsFilterSelect, "change");
  assert.equal(analyticsViewerBody.children.length, 6);

  setSelectValueForElement(analyticsFilterSelect, "all");
  dispatchDomEvent(analyticsFilterSelect, "change");
  assert.equal(analyticsViewerBody.children.length, 7);

  setSelectValueForElement(analyticsFilterSelect, "breaches");
  dispatchDomEvent(analyticsFilterSelect, "change");
  assert.equal(analyticsViewerBody.children.length, 4);

  setSelectValueForElement(analyticsFilterSelect, "shielded");
  dispatchDomEvent(analyticsFilterSelect, "change");
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
  const statRows = Array.from(waveScorecardStats.children);
  const accuracyRow = statRows.find((child) => child.dataset.field === "accuracy");
  assert.ok(accuracyRow, "expected accuracy row to exist");
  assert.equal(accuracyRow.children[0].textContent, "Accuracy");
  assert.equal(accuracyRow.children[1].textContent, "92.5%");
  const turretDpsRow = statRows.find((child) => child.dataset.field === "dps-turret");
  assert.ok(turretDpsRow, "expected turret DPS row to exist");
  assert.equal(turretDpsRow.children[1].textContent, "28.3");
  const typingDamageRow = statRows.find((child) => child.dataset.field === "damage-typing");
  assert.ok(typingDamageRow, "expected typing damage row to exist");
  assert.equal(typingDamageRow.children[1].textContent, "156");
  const shieldBreakRow = statRows.find((child) => child.dataset.field === "shield-breaks");
  assert.ok(shieldBreakRow, "expected shield break row to exist");
  assert.equal(shieldBreakRow.children[1].textContent, "3");
  const perfectWordsRow = statRows.find((child) => child.dataset.field === "perfect-words");
  assert.ok(perfectWordsRow, "expected perfect words row to exist");
  assert.equal(perfectWordsRow.children[1].textContent, "5");
  const reactionRow = statRows.find((child) => child.dataset.field === "reaction");
  assert.ok(reactionRow, "expected reaction row to exist");
  assert.equal(reactionRow.children[1].textContent, "1.23s");
  const repairCountRow = statRows.find((child) => child.dataset.field === "repairs");
  assert.ok(repairCountRow, "expected repairs row to exist");
  assert.equal(repairCountRow.children[1].textContent, "2");
  const repairHealingRow = statRows.find((child) => child.dataset.field === "repair-health");
  assert.ok(repairHealingRow, "expected repair health row to exist");
  assert.equal(repairHealingRow.children[1].textContent, "180");
  const repairGoldRow = statRows.find((child) => child.dataset.field === "repair-gold");
  assert.ok(repairGoldRow, "expected repair gold row to exist");
  assert.equal(repairGoldRow.children[1].textContent, "150g");
  const bonusGoldRow = statRows.find((child) => child.dataset.field === "bonus-gold");
  assert.ok(bonusGoldRow, "expected bonus gold row to exist");
  assert.equal(bonusGoldRow.children[1].textContent, "+45g");
  const castleBonusRow = statRows.find((child) => child.dataset.field === "castle-bonus");
  assert.ok(castleBonusRow, "expected castle bonus row to exist");
  assert.equal(castleBonusRow.children[1].textContent, "+12g");
  const comboRow = statRows.find((child) => child.dataset.field === "combo");
  assert.ok(comboRow, "expected combo row to exist");
  assert.equal(comboRow.children[1].textContent, "x6");
  const sessionComboRow = statRows.find((child) => child.dataset.field === "session-combo");
  assert.ok(sessionComboRow, "expected session combo row to exist");
  assert.equal(sessionComboRow.children[1].textContent, "x9");

  dispatchDomEvent(waveScorecardContinue, "click");
  assert.equal(getScorecardContinueCount(), 1);

  hud.hideWaveScorecard();
  assert.equal(waveScorecard.dataset.visible, "false");
  cleanup();
});
