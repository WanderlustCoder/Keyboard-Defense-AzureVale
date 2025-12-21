import { defaultWordBank } from "../core/wordBank.js";
import { buildLessonPathViewState, listLessonWordlists, listTypingLessons } from "../data/lessons.js";
import { evaluateLessonMedal } from "../utils/lessonMedals.js";
import { readLessonProgress } from "../utils/lessonProgress.js";
import { createPlacementTestResult, writePlacementTestResult } from "../utils/placementTest.js";
import { readPlayerSettings } from "../utils/playerSettings.js";
const TYPING_DRILL_GHOST_STORAGE_KEY = "keyboard-defense:typing-drill-ghosts";
const SPRINT_GHOST_TIMER_MS = 60000;
const READING_PASSAGES = [
    {
        title: "The Lantern Note",
        text: "Mira found a lantern on the library steps with a note tied to it.\n\nThe note said: \"Please bring this to the garden at sunset.\" Mira packed a small snack and walked carefully so the lantern would not tip over.",
        questions: [
            {
                prompt: "Where did Mira find the lantern?",
                options: [
                    { key: "a", text: "On the library steps" },
                    { key: "b", text: "At the garden gate" },
                    { key: "c", text: "By the river dock" }
                ],
                correct: "a",
                explanation: "The passage says the lantern was on the library steps."
            },
            {
                prompt: "When was Mira asked to go to the garden?",
                options: [
                    { key: "a", text: "At noon" },
                    { key: "b", text: "At sunset" },
                    { key: "c", text: "At midnight" }
                ],
                correct: "b",
                explanation: "The note said to bring it to the garden at sunset."
            }
        ]
    },
    {
        title: "The Quiet Bridge",
        text: "Noah crossed the small bridge every morning to feed the ducks.\n\nOne day, the bridge was covered with leaves. Noah walked slowly, held the railing, and kept his bucket steady.",
        questions: [
            {
                prompt: "Why did Noah cross the bridge each morning?",
                options: [
                    { key: "a", text: "To feed the ducks" },
                    { key: "b", text: "To buy bread" },
                    { key: "c", text: "To visit a shop" }
                ],
                correct: "a",
                explanation: "The passage says he crossed to feed the ducks."
            },
            {
                prompt: "What covered the bridge on the unusual day?",
                options: [
                    { key: "a", text: "Snow" },
                    { key: "b", text: "Water" },
                    { key: "c", text: "Leaves" }
                ],
                correct: "c",
                explanation: "It says the bridge was covered with leaves."
            }
        ]
    },
    {
        title: "Team Plan",
        text: "Zara and Leon were building a tiny kite for the park.\n\nZara cut the paper while Leon tied the string. They tested it once, fixed a loose knot, and tried again.",
        questions: [
            {
                prompt: "What did Zara do?",
                options: [
                    { key: "a", text: "Tied the string" },
                    { key: "b", text: "Cut the paper" },
                    { key: "c", text: "Drew the map" }
                ],
                correct: "b",
                explanation: "Zara cut the paper."
            },
            {
                prompt: "Why did they stop after the first test?",
                options: [
                    { key: "a", text: "A knot was loose" },
                    { key: "b", text: "The wind stopped" },
                    { key: "c", text: "They ran out of paper" }
                ],
                correct: "a",
                explanation: "They fixed a loose knot."
            }
        ]
    }
];
const HAND_ISOLATION_WORDS = {
    left: [
        "rest",
        "tree",
        "east",
        "vast",
        "craft",
        "brave",
        "grave",
        "zest",
        "wrest",
        "caves",
        "weaver",
        "sweater",
        "stare",
        "reset",
        "treat",
        "tease",
        "water",
        "wear",
        "sear",
        "rate",
        "tear",
        "rare",
        "weave",
        "stew",
        "steward",
        "faster",
        "after",
        "easter",
        "sewage",
        "cafe",
        "caste",
        "waste",
        "save",
        "safe",
        "star",
        "sweat",
        "trace",
        "crater",
        "crates",
        "staves",
        "seafarer"
    ],
    right: [
        "lion",
        "milk",
        "join",
        "mono",
        "pink",
        "holy",
        "yummy",
        "kilo",
        "poll",
        "noon",
        "null",
        "look",
        "hook",
        "mop",
        "mom",
        "my",
        "huh",
        "pup",
        "lull",
        "yolk",
        "jolly",
        "only",
        "pony",
        "loom",
        "moon",
        "mini",
        "hulk",
        "plum",
        "jumpy",
        "jimmy",
        "hilly",
        "lily",
        "milky",
        "monk",
        "kim",
        "pin",
        "hip",
        "hop",
        "pop",
        "honk",
        "kiln",
        "imply"
    ]
};
const DRILL_CONFIGS = {
    burst: {
        label: "Burst Warmup",
        description: "Clear five snappy words to warm up before battle.",
        wordCount: 5,
        difficulties: ["easy", "easy", "medium", "medium", "hard"]
    },
    lesson: {
        label: "Lesson",
        description: "Follow the curriculum with focused word lists.",
        wordCount: 12
    },
    warmup: {
        label: "5-Min Warm-up",
        description: "A five-minute warm-up plan built from your recent mistakes.",
        timerMs: 300000
    },
    endurance: {
        label: "Endurance",
        description: "Stay consistent for thirty seconds; cadence matters more than speed.",
        timerMs: 30000,
        difficulties: ["easy", "medium", "medium", "hard"]
    },
    sprint: {
        label: "Time Attack",
        description: "A 60-second sprint. Chase speed while keeping accuracy high.",
        timerMs: 60000,
        difficulties: ["easy", "easy", "medium", "medium", "hard"]
    },
    sentences: {
        label: "Sentence Builder",
        description: "Practice punctuation and flow with full sentences.",
        timerMs: 45000,
        targets: [
            "ready, set, defend!",
            "slow is smooth; smooth is fast.",
            "keep your eyes up, then type clean.",
            "when the gate shakes, stay calm.",
            "i can type this, one key at a time.",
            "the scout said, \"hold the line.\"",
            "breathe in, breathe out, keep typing.",
            "if you miss a key, reset and try again.",
            "tap, tap, tap, then pause.",
            "watch the lane, then strike fast!",
            "today i practice commas, quotes, and calm.",
            "can you keep rhythm, even when it is hard?",
            "after wave 3, take a short break.",
            "we're ready; we're steady.",
            "don't rush; hit the right key.",
            "type the whole sentence, not just one word.",
            "left hand, right hand, keep it even.",
            "a clean run beats a fast miss."
        ]
    },
    reading: {
        label: "Reading Quiz",
        description: "Read a short passage, then answer quick questions (type A/B/C).",
        timerMs: 90000
    },
    rhythm: {
        label: "Rhythm Drill",
        description: "Alternate hands to a steady beat. Smooth rhythm beats rushed speed.",
        timerMs: 30000,
        metronomeBpm: 84,
        metronomeAccentEvery: 4,
        targets: [
            "fjfjfjfjfj",
            "jfjfjfjfjf",
            "dkdkdkdkdk",
            "kdkdkdkdkd",
            "slslslslsl",
            "lslslslsls",
            "gugugugugu",
            "ugugugugug",
            "hehehehehe",
            "eheheheheh",
            "f j f j f j",
            "d k d k d k",
            "a p a p a p",
            "q p q p q p",
            "1 6 1 6 1 6"
        ]
    },
    reaction: {
        label: "Reaction Challenge",
        description: "Wait for the cue, then hit the key fast. False starts count as errors.",
        timerMs: 30000,
        targets: ["a", "s", "d", "f", "j", "k", "l", ";"]
    },
    combo: {
        label: "Combo Preservation",
        description: "Keep your combo alive across segments. Each segment grants limited mistakes.",
        timerMs: 45000
    },
    precision: {
        label: "Shield Breaker",
        description: "Eight tougher strings. Errors reset the current word to mimic shield pressure.",
        wordCount: 8,
        difficulties: ["medium", "medium", "hard", "hard"],
        penalizeErrors: true
    },
    symbols: {
        label: "Numbers & Symbols",
        description: "Quick strings with digits, punctuation, and number-row symbols. Earn a silver medal to unlock advanced symbols.",
        wordCount: 10,
        targets: [
            "1-2-3",
            "3.14",
            "10/10",
            "a,b,c",
            "x/y",
            "go!",
            "why?",
            "we're",
            "can't",
            "semi;colon",
            "mix:1/2",
            "under_score"
        ],
        advancedTargets: [
            "email@me",
            "bug#42",
            "cost$5",
            "save%20",
            "x^2",
            "rock&roll",
            "*star*",
            "(paren)"
        ]
    },
    placement: {
        label: "Placement Test",
        description: "A short diagnostic that checks left/right hand accuracy and recommends a tutorial pace.",
        timerMs: 45000,
        segments: [
            {
                label: "Left Hand",
                durationMs: 15000,
                targets: [
                    "rest",
                    "tree",
                    "east",
                    "vast",
                    "craft",
                    "brave",
                    "grave",
                    "zest",
                    "wrest",
                    "caves",
                    "sweater",
                    "weaver"
                ]
            },
            {
                label: "Right Hand",
                durationMs: 15000,
                targets: [
                    "lion",
                    "milk",
                    "join",
                    "mono",
                    "pink",
                    "holy",
                    "yummy",
                    "kilo",
                    "poll",
                    "noon",
                    "null",
                    "hollow"
                ]
            },
            {
                label: "Mixed",
                durationMs: 15000,
                targets: [
                    "sail",
                    "gold",
                    "storm",
                    "guard",
                    "castle",
                    "tower",
                    "arrow",
                    "shield",
                    "flame",
                    "stone",
                    "river",
                    "march"
                ]
            }
        ]
    },
    hand: {
        label: "Hand Isolation",
        description: "Practice one hand at a time using single-hand word pools.",
        timerMs: 45000
    },
    support: {
        label: "Lane Support",
        description: "Press 1/2/3 to route support to the correct lane.",
        timerMs: 45000
    },
    shortcuts: {
        label: "Shortcut Practice",
        description: "Practice helpful shortcuts like copy, paste, and undo (Ctrl/Cmd).",
        timerMs: 45000,
        shortcutSteps: [
            {
                label: "Select All",
                comboLabel: "Ctrl/Cmd + A",
                chords: [{ key: "a", primary: true }]
            },
            {
                label: "Copy",
                comboLabel: "Ctrl/Cmd + C",
                chords: [{ key: "c", primary: true }]
            },
            {
                label: "Cut",
                comboLabel: "Ctrl/Cmd + X",
                chords: [{ key: "x", primary: true }]
            },
            {
                label: "Paste",
                comboLabel: "Ctrl/Cmd + V",
                chords: [{ key: "v", primary: true }]
            },
            {
                label: "Undo",
                comboLabel: "Ctrl/Cmd + Z",
                chords: [{ key: "z", primary: true, shift: false }]
            },
            {
                label: "Redo",
                comboLabel: "Ctrl/Cmd + Y (or Ctrl/Cmd + Shift + Z)",
                chords: [
                    { key: "y", primary: true, shift: false },
                    { key: "z", primary: true, shift: true }
                ]
            }
        ]
    },
    shift: {
        label: "Shift Timing",
        description: "Capital letters on cue: hold Shift, tap the letter, and release. Toggle slow-mo for extra time and clearer hold vs tap cues.",
        timerMs: 45000,
        shiftSteps: [
            { label: "Capital A", key: "a" },
            { label: "Capital L", key: "l" },
            { label: "Capital Q", key: "q" },
            { label: "Capital P", key: "p" },
            { label: "Capital T", key: "t" },
            { label: "Capital Y", key: "y" },
            { label: "Capital V", key: "v" },
            { label: "Capital M", key: "m" }
        ]
    },
    focus: {
        label: "Focus Drill",
        description: "Auto-built micro-drills from your recent mistakes. Each segment spotlights a trouble key.",
        timerMs: 30000
    }
};
export class TypingDrillsOverlay {
    root;
    wordBank;
    callbacks;
    modeButtons = [];
    body;
    statusLabel;
    progressLabel;
    timerLabel;
    targetEl;
    input;
    startBtn;
    resetBtn;
    slowMoBtn;
    metronomeBtn;
    handBtn;
    accuracyEl;
    comboEl;
    wpmEl;
    wordsEl;
    summaryEl;
    summaryTime;
    summaryAccuracy;
    summaryCombo;
    summaryWords;
    summaryErrors;
    summaryLeft;
    summaryRight;
    summaryPacing;
    summaryTip;
    summaryMedal;
    summaryMedalLabel;
    summaryMedalHint;
    summaryReplay;
    fallbackEl;
    toastEl;
    recommendationEl;
    recommendationBadge;
    recommendationReason;
    recommendationRun;
    lessonPicker;
    lessonSelect;
    lessonDescription;
    resizeHandler;
    layoutPulseTimeout;
    isCondensedLayout = false;
    cleanupTimer;
    recommendationMode = null;
    advancedSymbolsUnlocked = false;
    toastTimeout;
    lessonCatalog = [];
    lessonId = null;
    lessonWords = [];
    lessonSelectionTouched = false;
    shiftTutorSlowMo = true;
    metronomeEnabled = true;
    handIsolationSide = "left";
    metronomeSoundLevel = 0;
    metronomeHapticsAllowed = false;
    metronomeBeatTimeout;
    metronomeLoopTimeout;
    metronomeNextBeatAt = null;
    metronomeBeatIndex = 0;
    metronomeAudio = null;
    reactionPromptTimeout;
    reactionPromptAt = null;
    reactionPromptKey = null;
    reactionLatenciesMs = [];
    reactionLastLatencyMs = null;
    supportPromptLane = null;
    supportPromptAction = null;
    supportPromptAt = null;
    supportLatenciesMs = [];
    supportLastLatencyMs = null;
    supportPreviousLane = null;
    sprintGhostRun = null;
    sprintGhostWordsBySecond = null;
    sprintGhostRecordingWordsBySecond = [];
    sprintGhostLastSecondRecorded = -1;
    readingQueue = [];
    readingPassageIndex = 0;
    readingQuestionIndex = 0;
    readingStage = "passage";
    readingTotalQuestions = 0;
    focusKeys = [];
    focusSegments = [];
    warmupKeys = [];
    warmupSegments = [];
    comboSegments = [];
    comboMistakeBudget = 0;
    comboMistakesRemaining = 0;
    comboUnshieldedErrorsThisWord = 0;
    patternStats = {
        keys: new Map(),
        digraphs: new Map()
    };
    state = {
        mode: "lesson",
        active: false,
        startSource: "cta",
        buffer: "",
        target: "",
        correctInputs: 0,
        totalInputs: 0,
        errors: 0,
        leftCorrectInputs: 0,
        leftTotalInputs: 0,
        rightCorrectInputs: 0,
        rightTotalInputs: 0,
        wordsCompleted: 0,
        combo: 0,
        bestCombo: 0,
        wordErrors: 0,
        startTime: 0,
        elapsedMs: 0,
        timerEndsAt: null,
        segmentIndex: 0,
        shortcutStepIndex: 0,
        shiftStepIndex: 0,
        shiftHeld: false,
        shiftLastDownAt: null
    };
    constructor(options) {
        this.root = options.root;
        this.wordBank = options.wordBank ?? defaultWordBank;
        this.callbacks = options.callbacks ?? {};
        this.body = this.root.querySelector(".typing-drills-body");
        this.statusLabel = document.getElementById("typing-drill-status-label");
        this.progressLabel = document.getElementById("typing-drill-progress");
        this.timerLabel = document.getElementById("typing-drill-timer");
        this.targetEl = document.getElementById("typing-drill-target");
        this.input = document.getElementById("typing-drill-input");
        this.startBtn = document.getElementById("typing-drill-start");
        this.resetBtn = document.getElementById("typing-drill-reset");
        this.slowMoBtn = document.getElementById("typing-drill-slowmo");
        this.metronomeBtn = document.getElementById("typing-drill-metronome");
        this.handBtn = document.getElementById("typing-drill-hand");
        this.accuracyEl = document.getElementById("typing-drill-accuracy");
        this.comboEl = document.getElementById("typing-drill-combo");
        this.wpmEl = document.getElementById("typing-drill-wpm");
        this.wordsEl = document.getElementById("typing-drill-words");
        this.summaryEl = document.getElementById("typing-drill-summary");
        this.summaryTime = document.getElementById("typing-drill-summary-time");
        this.summaryAccuracy = document.getElementById("typing-drill-summary-accuracy");
        this.summaryCombo = document.getElementById("typing-drill-summary-combo");
        this.summaryWords = document.getElementById("typing-drill-summary-words");
        this.summaryErrors = document.getElementById("typing-drill-summary-errors");
        this.summaryLeft = document.getElementById("typing-drill-summary-left");
        this.summaryRight = document.getElementById("typing-drill-summary-right");
        this.summaryPacing = document.getElementById("typing-drill-summary-pacing");
        this.summaryTip = document.getElementById("typing-drill-summary-tip");
        this.summaryMedal = document.getElementById("typing-drill-summary-medal");
        this.summaryMedalLabel = document.getElementById("typing-drill-summary-medal-label");
        this.summaryMedalHint = document.getElementById("typing-drill-summary-medal-hint");
        this.summaryReplay = document.getElementById("typing-drill-summary-replay");
        this.fallbackEl = document.getElementById("typing-drill-fallback");
        this.toastEl = document.getElementById("typing-drill-toast");
        this.recommendationEl = document.getElementById("typing-drill-recommendation");
        this.recommendationBadge = document.getElementById("typing-drill-recommendation-badge");
        this.recommendationReason = document.getElementById("typing-drill-recommendation-reason");
        this.recommendationRun = document.getElementById("typing-drill-recommendation-run");
        this.lessonPicker = document.getElementById("typing-drill-lesson-picker");
        this.lessonSelect = document.getElementById("typing-drill-lesson-select");
        this.lessonDescription = document.getElementById("typing-drill-lesson-description");
        const modeButtons = Array.from(this.root.querySelectorAll(".typing-drill-mode"));
        this.modeButtons.push(...modeButtons);
        this.initializeLessonPicker();
        this.attachEvents();
        this.updateLayoutMode();
        if (typeof window !== "undefined") {
            this.resizeHandler = () => this.updateLayoutMode();
            window.addEventListener("resize", this.resizeHandler);
        }
        this.updateMode(this.state.mode, { silent: true });
        this.updateTarget();
        this.updateMetrics();
        this.updateTimer();
    }
    open(mode, source, toastMessage) {
        this.root.dataset.visible = "true";
        this.state.startSource = source ?? this.state.startSource ?? "cta";
        this.lessonSelectionTouched = false;
        this.reset(mode);
        this.input?.focus();
        if (toastMessage) {
            this.showToast(toastMessage);
        }
    }
    close() {
        this.cleanupTimer?.();
        this.cleanupTimer = undefined;
        this.stopMetronome();
        this.stopReactionPrompt();
        this.stopSupport();
        this.stopReading();
        if (this.toastEl) {
            this.toastEl.dataset.visible = "false";
            this.toastEl.textContent = "";
        }
        if (this.toastTimeout) {
            window.clearTimeout(this.toastTimeout);
            this.toastTimeout = null;
        }
        this.state.active = false;
        this.state.buffer = "";
        this.state.target = "";
        this.root.dataset.visible = "false";
        this.summaryEl?.setAttribute("data-visible", "false");
        this.callbacks.onClose?.();
    }
    isVisible() {
        return this.root.dataset.visible === "true";
    }
    isActive() {
        return this.state.active;
    }
    getLessonId() {
        return typeof this.lessonId === "string" && this.lessonId.length > 0 ? this.lessonId : null;
    }
    start(mode) {
        const nextMode = mode ?? this.state.mode;
        this.stopMetronome();
        this.stopReactionPrompt();
        this.stopSupport();
        this.stopReading();
        this.state = {
            ...this.state,
            mode: nextMode,
            active: true,
            startSource: this.state.startSource,
            buffer: "",
            target: "",
            correctInputs: 0,
            totalInputs: 0,
            errors: 0,
            leftCorrectInputs: 0,
            leftTotalInputs: 0,
            rightCorrectInputs: 0,
            rightTotalInputs: 0,
            wordsCompleted: 0,
            combo: 0,
            bestCombo: 0,
            wordErrors: 0,
            startTime: performance.now(),
            elapsedMs: 0,
            timerEndsAt: null,
            segmentIndex: 0,
            shortcutStepIndex: 0,
            shiftStepIndex: 0,
            shiftHeld: false,
            shiftLastDownAt: null
        };
        this.reactionLatenciesMs = [];
        this.reactionLastLatencyMs = null;
        this.supportLatenciesMs = [];
        this.supportLastLatencyMs = null;
        this.supportPreviousLane = null;
        this.stopSupport();
        this.resetPatternStats();
        this.prepareSprintGhost(nextMode);
        if (nextMode === "focus") {
            this.ensureFocusSegments();
        }
        if (nextMode === "warmup") {
            this.ensureWarmupSegments();
        }
        if (nextMode === "combo") {
            this.ensureComboSegments();
            this.resetComboSegmentBudget(0);
        }
        this.summaryEl?.setAttribute("data-visible", "false");
        this.updateMode(nextMode);
        this.state.target = this.pickWord(nextMode);
        const config = DRILL_CONFIGS[nextMode];
        if (typeof config.timerMs === "number" && config.timerMs > 0) {
            let timerMs = config.timerMs;
            if (nextMode === "shift" && this.shiftTutorSlowMo) {
                timerMs = config.timerMs * 1.75;
            }
            if (nextMode === "focus") {
                const totalMs = this.focusSegments.reduce((sum, segment) => sum + Math.max(0, segment?.durationMs ?? 0), 0);
                if (totalMs > 0) {
                    timerMs = totalMs;
                }
            }
            if (nextMode === "warmup") {
                const totalMs = this.warmupSegments.reduce((sum, segment) => sum + Math.max(0, segment?.durationMs ?? 0), 0);
                if (totalMs > 0) {
                    timerMs = totalMs;
                }
            }
            if (nextMode === "combo") {
                this.ensureComboSegments();
                const totalMs = this.comboSegments.reduce((sum, segment) => sum + Math.max(0, segment?.durationMs ?? 0), 0);
                if (totalMs > 0) {
                    timerMs = totalMs;
                }
            }
            const endsAt = this.state.startTime + timerMs;
            this.state.timerEndsAt = endsAt;
            this.cleanupTimer = this.startTimer(endsAt);
        }
        this.updateTarget();
        this.updateMetrics();
        this.updateTimer();
        this.startMetronome(nextMode);
        this.startReaction(nextMode);
        this.startSupport(nextMode);
        this.startReading(nextMode);
        this.callbacks.onStart?.(nextMode, this.state.startSource);
        if (this.statusLabel) {
            if (nextMode === "shift" && this.shiftTutorSlowMo) {
                this.statusLabel.textContent = `${config.label} (Slow)`;
            }
            else if (nextMode === "rhythm" && typeof config.metronomeBpm === "number" && config.metronomeBpm > 0) {
                this.statusLabel.textContent = `${config.label} (${Math.round(config.metronomeBpm)} BPM)`;
            }
            else if (nextMode === "reaction") {
                this.statusLabel.textContent = `${config.label} (30s)`;
            }
            else if (nextMode === "hand") {
                this.statusLabel.textContent = `${config.label} (${this.handIsolationSide === "left" ? "Left" : "Right"})`;
            }
            else if (nextMode === "lesson") {
                this.statusLabel.textContent = this.getLessonLabel() ?? config.label;
            }
            else if (nextMode === "focus" && this.focusKeys.length > 0) {
                this.statusLabel.textContent = `${config.label} (${this.focusKeys
                    .map((key) => key.toUpperCase())
                    .join(", ")})`;
            }
            else if (nextMode === "warmup" && this.warmupKeys.length > 0) {
                this.statusLabel.textContent = `${config.label} (${this.warmupKeys
                    .map((key) => key.toUpperCase())
                    .join(", ")})`;
            }
            else {
                this.statusLabel.textContent = config.label;
            }
        }
        if (this.startBtn) {
            this.startBtn.textContent = nextMode === "lesson" ? "Restart Lesson" : "Restart";
        }
    }
    reset(mode) {
        const nextMode = mode ?? this.state.mode;
        this.stopMetronome();
        this.stopReactionPrompt();
        this.stopSupport();
        this.stopReading();
        this.cleanupTimer?.();
        this.cleanupTimer = undefined;
        const startSource = this.state.startSource;
        if (nextMode === "focus") {
            this.ensureFocusSegments();
        }
        if (nextMode === "warmup") {
            this.ensureWarmupSegments();
        }
        if (nextMode === "combo") {
            this.ensureComboSegments();
            this.resetComboSegmentBudget(0);
        }
        this.state = {
            mode: nextMode,
            active: false,
            startSource,
            buffer: "",
            target: "",
            correctInputs: 0,
            totalInputs: 0,
            errors: 0,
            leftCorrectInputs: 0,
            leftTotalInputs: 0,
            rightCorrectInputs: 0,
            rightTotalInputs: 0,
            wordsCompleted: 0,
            combo: 0,
            bestCombo: 0,
            wordErrors: 0,
            startTime: 0,
            elapsedMs: 0,
            timerEndsAt: null,
            segmentIndex: 0,
            shortcutStepIndex: 0,
            shiftStepIndex: 0,
            shiftHeld: false,
            shiftLastDownAt: null
        };
        this.reactionLatenciesMs = [];
        this.reactionLastLatencyMs = null;
        this.supportLatenciesMs = [];
        this.supportLastLatencyMs = null;
        this.supportPreviousLane = null;
        this.stopSupport();
        this.resetPatternStats();
        this.updateMode(nextMode);
        this.updateTarget();
        this.updateMetrics();
        this.updateTimer();
        this.summaryEl?.setAttribute("data-visible", "false");
        if (this.fallbackEl) {
            this.fallbackEl.dataset.visible = "false";
        }
        if (this.statusLabel) {
            this.statusLabel.textContent = "Ready";
        }
        if (this.startBtn) {
            this.startBtn.textContent = nextMode === "lesson" ? "Start Lesson" : "Start Drill";
        }
    }
    setAdvancedSymbolsUnlocked(unlocked) {
        this.advancedSymbolsUnlocked = Boolean(unlocked);
    }
    setFocusKeys(keys) {
        const normalized = [];
        const seen = new Set();
        for (const raw of keys ?? []) {
            if (typeof raw !== "string")
                continue;
            const value = raw.trim().toLowerCase();
            if (!(value.length === 1 || value.length === 2) || !/^[a-z]+$/.test(value))
                continue;
            if (seen.has(value))
                continue;
            seen.add(value);
            normalized.push(value);
            if (normalized.length >= 3)
                break;
        }
        const nextKeys = normalized.length > 0 ? normalized : ["a", "s", "l"];
        this.focusKeys = nextKeys;
        const segmentMs = 10000;
        this.focusSegments = nextKeys.map((key) => {
            const label = key.length === 2 ? `Digraph ${key.toUpperCase()}` : `Key ${key.toUpperCase()}`;
            return {
                label,
                durationMs: segmentMs,
                targets: this.buildFocusTargetsForKey(key)
            };
        });
        if (this.state.mode === "focus" && !this.state.active) {
            this.state.segmentIndex = 0;
            this.state.target = this.pickWord("focus");
            this.updateTarget();
            this.updateMetrics();
        }
    }
    ensureFocusSegments() {
        if (this.focusSegments.length > 0)
            return;
        this.setFocusKeys([]);
    }
    setWarmupKeys(keys) {
        const normalized = [];
        const seen = new Set();
        for (const raw of keys ?? []) {
            if (typeof raw !== "string")
                continue;
            const value = raw.trim().toLowerCase();
            if (!(value.length === 1 || value.length === 2) || !/^[a-z]+$/.test(value))
                continue;
            if (seen.has(value))
                continue;
            seen.add(value);
            normalized.push(value);
            if (normalized.length >= 3)
                break;
        }
        const fallbackCandidates = [
            ...(this.focusKeys ?? []),
            "a",
            "s",
            "l",
            "e",
            "t",
            "n",
            "r",
            "i",
            "o"
        ];
        for (const candidate of fallbackCandidates) {
            if (normalized.length >= 3)
                break;
            if (!candidate || !(candidate.length === 1 || candidate.length === 2))
                continue;
            const value = candidate.toLowerCase();
            if (!/^[a-z]+$/.test(value))
                continue;
            if (seen.has(value))
                continue;
            seen.add(value);
            normalized.push(value);
        }
        this.warmupKeys = normalized.length > 0 ? normalized.slice(0, 3) : ["a", "s", "l"];
        if (this.state.mode === "warmup" && this.state.active) {
            return;
        }
        const segmentMs = 60000;
        this.warmupSegments = [
            {
                label: "Accuracy Reset",
                durationMs: segmentMs,
                targets: this.buildWarmupBaselineTargets()
            },
            ...this.warmupKeys.map((key) => {
                const label = key.length === 2 ? `Digraph ${key.toUpperCase()}` : `Key ${key.toUpperCase()}`;
                return {
                    label,
                    durationMs: segmentMs,
                    targets: this.buildFocusTargetsForKey(key)
                };
            }),
            {
                label: "Cadence Push",
                durationMs: segmentMs,
                targets: this.buildWarmupCadenceTargets()
            }
        ];
        if (this.state.mode === "warmup" && !this.state.active) {
            this.state.segmentIndex = 0;
            this.state.target = this.pickWord("warmup");
            this.updateTarget();
            this.updateMetrics();
        }
    }
    ensureWarmupSegments() {
        if (this.warmupSegments.length > 0)
            return;
        this.setWarmupKeys([]);
    }
    ensureComboSegments() {
        if (this.comboSegments.length > 0)
            return;
        const segmentMs = 15000;
        this.comboSegments = [
            {
                label: "Shield x3",
                durationMs: segmentMs,
                mistakesAllowed: 3,
                targets: this.sampleWordBank(["easy"], 24)
            },
            {
                label: "Shield x2",
                durationMs: segmentMs,
                mistakesAllowed: 2,
                targets: this.sampleWordBank(["medium"], 24)
            },
            {
                label: "Shield x1",
                durationMs: segmentMs,
                mistakesAllowed: 1,
                targets: this.sampleWordBank(["hard"], 24)
            }
        ];
    }
    resetComboSegmentBudget(index) {
        this.ensureComboSegments();
        const segments = this.comboSegments;
        if (segments.length === 0) {
            this.comboMistakeBudget = 0;
            this.comboMistakesRemaining = 0;
            this.comboUnshieldedErrorsThisWord = 0;
            return;
        }
        const safeIndex = Math.max(0, Math.min(segments.length - 1, index));
        const segment = segments[safeIndex] ?? null;
        const budget = typeof segment?.mistakesAllowed === "number"
            ? Math.max(0, Math.floor(segment.mistakesAllowed))
            : 0;
        this.comboMistakeBudget = budget;
        this.comboMistakesRemaining = budget;
        this.comboUnshieldedErrorsThisWord = 0;
    }
    buildWarmupBaselineTargets() {
        const targets = [];
        targets.push(...this.sampleWordBank(["easy"], 14));
        targets.push(...this.sampleWordBank(["medium"], 8));
        targets.push(...this.sampleWordBank(["hard"], 4));
        return targets;
    }
    buildWarmupCadenceTargets() {
        const targets = [];
        targets.push(...this.sampleWordBank(["medium"], 12));
        targets.push(...this.sampleWordBank(["hard"], 8));
        return targets;
    }
    sampleWordBank(difficulties, limit) {
        const results = [];
        const seen = new Set();
        const sources = this.wordBank ?? defaultWordBank;
        for (const difficulty of difficulties) {
            const pool = sources[difficulty] ?? defaultWordBank[difficulty];
            if (!Array.isArray(pool))
                continue;
            for (const raw of pool) {
                if (typeof raw !== "string")
                    continue;
                const value = raw.trim().toLowerCase();
                if (!value)
                    continue;
                if (value.length < 3 || value.length > 14)
                    continue;
                if (!/^[a-z]+$/.test(value))
                    continue;
                if (seen.has(value))
                    continue;
                seen.add(value);
                results.push(value);
                if (results.length >= limit) {
                    return results;
                }
            }
        }
        return results;
    }
    buildFocusTargetsForKey(key) {
        const normalized = key.trim().toLowerCase();
        if (normalized.length === 2 && /^[a-z]{2}$/.test(normalized)) {
            const digraph = normalized;
            const targets = [];
            targets.push(`${digraph} ${digraph} ${digraph} ${digraph}`);
            targets.push(`${digraph}${digraph}${digraph}`);
            const vowels = ["a", "e", "i", "o", "u"];
            targets.push(vowels.map((vowel) => `${digraph}${vowel}`).join(" "));
            targets.push(vowels.map((vowel) => `${vowel}${digraph}`).join(" "));
            const candidateWords = [];
            const pools = [this.wordBank.easy, this.wordBank.medium, this.wordBank.hard];
            for (const pool of pools) {
                if (!Array.isArray(pool))
                    continue;
                for (const word of pool) {
                    if (typeof word !== "string" || word.length < 3 || word.length > 12)
                        continue;
                    const lower = word.toLowerCase();
                    if (!/^[a-z]+$/.test(lower))
                        continue;
                    if (!lower.includes(digraph))
                        continue;
                    candidateWords.push(lower);
                }
            }
            const uniqueWords = Array.from(new Set(candidateWords));
            targets.push(...uniqueWords.slice(0, 10));
            const uniqueTargets = [];
            const seenTargets = new Set();
            for (const target of targets) {
                const value = typeof target === "string" ? target.trim() : "";
                if (!value)
                    continue;
                if (seenTargets.has(value))
                    continue;
                seenTargets.add(value);
                uniqueTargets.push(value);
            }
            return uniqueTargets;
        }
        const letter = normalized.length === 1 ? normalized : "a";
        const targets = [];
        targets.push(letter.repeat(5));
        targets.push(Array.from({ length: 5 }, () => letter).join(" "));
        const vowels = ["a", "e", "i", "o", "u"];
        targets.push(vowels.map((vowel) => `${letter}${vowel}`).join(" "));
        targets.push(vowels.map((vowel) => `${vowel}${letter}`).join(" "));
        const candidateWords = [];
        const pools = [this.wordBank.easy, this.wordBank.medium, this.wordBank.hard];
        for (const pool of pools) {
            if (!Array.isArray(pool))
                continue;
            for (const word of pool) {
                if (typeof word !== "string" || word.length < 3 || word.length > 10)
                    continue;
                const lower = word.toLowerCase();
                if (!/^[a-z]+$/.test(lower))
                    continue;
                if (!lower.includes(letter))
                    continue;
                candidateWords.push(lower);
            }
        }
        const uniqueWords = Array.from(new Set(candidateWords));
        targets.push(...uniqueWords.slice(0, 8));
        if (targets.length <= 4) {
            targets.push(`${letter}a${letter}`, `${letter}e${letter}`, `${letter}o${letter}`);
        }
        const uniqueTargets = [];
        const seenTargets = new Set();
        for (const target of targets) {
            const value = typeof target === "string" ? target.trim() : "";
            if (!value)
                continue;
            if (seenTargets.has(value))
                continue;
            seenTargets.add(value);
            uniqueTargets.push(value);
        }
        return uniqueTargets;
    }
    resetPatternStats() {
        this.patternStats.keys.clear();
        this.patternStats.digraphs.clear();
    }
    recordPatternAttempt(kind, pattern, isError) {
        const normalized = pattern.trim().toLowerCase();
        if (kind === "key") {
            if (normalized.length !== 1 || !/^[a-z]$/.test(normalized))
                return;
            const entry = this.patternStats.keys.get(normalized) ?? { attempts: 0, errors: 0 };
            entry.attempts += 1;
            if (isError)
                entry.errors += 1;
            this.patternStats.keys.set(normalized, entry);
            return;
        }
        if (normalized.length !== 2 || !/^[a-z]{2}$/.test(normalized))
            return;
        const entry = this.patternStats.digraphs.get(normalized) ?? { attempts: 0, errors: 0 };
        entry.attempts += 1;
        if (isError)
            entry.errors += 1;
        this.patternStats.digraphs.set(normalized, entry);
    }
    buildPatternStatsPayload() {
        const keys = {};
        for (const [pattern, entry] of this.patternStats.keys.entries()) {
            if (entry.attempts < 3 && entry.errors === 0)
                continue;
            keys[pattern] = { attempts: entry.attempts, errors: entry.errors };
        }
        const digraphs = {};
        for (const [pattern, entry] of this.patternStats.digraphs.entries()) {
            if (entry.attempts < 2 && entry.errors === 0)
                continue;
            digraphs[pattern] = { attempts: entry.attempts, errors: entry.errors };
        }
        if (Object.keys(keys).length === 0 && Object.keys(digraphs).length === 0) {
            return undefined;
        }
        return {
            keys: Object.keys(keys).length > 0 ? keys : undefined,
            digraphs: Object.keys(digraphs).length > 0 ? digraphs : undefined
        };
    }
    updateLayoutMode() {
        const body = this.body;
        if (!body)
            return;
        if (typeof window === "undefined") {
            body.dataset.condensed = "false";
            this.isCondensedLayout = false;
            return;
        }
        const height = window.innerHeight;
        const width = window.innerWidth;
        const condensed = height < 760 || width < 960;
        const nextCondensed = condensed ? "true" : "false";
        const changed = body.dataset.condensed !== nextCondensed;
        body.dataset.condensed = nextCondensed;
        this.isCondensedLayout = condensed;
        if (changed) {
            body.classList.remove("typing-drills-layout-pulse");
            if (this.layoutPulseTimeout) {
                window.clearTimeout(this.layoutPulseTimeout);
            }
            void body.offsetWidth;
            body.classList.add("typing-drills-layout-pulse");
            this.layoutPulseTimeout = window.setTimeout(() => {
                body.classList.remove("typing-drills-layout-pulse");
                this.layoutPulseTimeout = null;
            }, 650);
        }
    }
    attachEvents() {
        if (this.input) {
            this.input.addEventListener("keydown", (event) => this.handleKey(event));
        }
        if (this.startBtn) {
            this.startBtn.addEventListener("click", () => {
                if (!this.state.active) {
                    this.start();
                }
                else {
                    this.reset();
                    this.start();
                }
            });
        }
        if (this.resetBtn) {
            this.resetBtn.addEventListener("click", () => this.reset());
        }
        if (this.slowMoBtn) {
            this.slowMoBtn.addEventListener("click", () => {
                if (this.state.active)
                    return;
                this.shiftTutorSlowMo = !this.shiftTutorSlowMo;
                this.updateShiftTutorControls();
                if (this.state.mode === "shift") {
                    this.updateTarget();
                    this.updateMetrics();
                }
            });
        }
        if (this.metronomeBtn) {
            this.metronomeBtn.addEventListener("click", () => {
                this.metronomeEnabled = !this.metronomeEnabled;
                this.updateMetronomeControls();
                if (this.state.active && this.state.mode === "rhythm") {
                    if (this.metronomeEnabled) {
                        this.startMetronome("rhythm");
                    }
                    else {
                        this.stopMetronome();
                    }
                }
            });
        }
        if (this.handBtn) {
            this.handBtn.addEventListener("click", () => {
                if (this.state.active)
                    return;
                this.handIsolationSide = this.handIsolationSide === "left" ? "right" : "left";
                this.updateHandIsolationControls();
                if (this.state.mode === "hand") {
                    this.state.buffer = "";
                    this.state.target = this.pickWord("hand");
                    this.updateTarget();
                    this.updateMetrics();
                }
            });
        }
        this.modeButtons.forEach((btn) => btn.addEventListener("click", () => {
            const mode = btn.dataset.mode;
            if (!mode)
                return;
            this.reset(mode);
            if (this.state.active) {
                this.start(mode);
            }
        }));
        const closeBtn = document.getElementById("typing-drills-close");
        closeBtn?.addEventListener("click", () => this.close());
        if (this.recommendationRun) {
            this.recommendationRun.addEventListener("click", () => {
                if (this.recommendationMode) {
                    this.reset(this.recommendationMode);
                    this.start(this.recommendationMode);
                }
            });
        }
        if (this.summaryReplay) {
            this.summaryReplay.addEventListener("click", () => {
                this.reset(this.state.mode);
                this.start(this.state.mode);
            });
        }
    }
    initializeLessonPicker() {
        this.lessonCatalog = listTypingLessons();
        const fallback = this.lessonCatalog[0] ?? null;
        if (!this.lessonId && fallback) {
            this.lessonId = fallback.id;
        }
        if (this.lessonSelect) {
            this.lessonSelect.replaceChildren();
            for (const lesson of this.lessonCatalog) {
                const option = document.createElement("option");
                option.value = lesson.id;
                option.textContent = `Lesson ${lesson.order}: ${lesson.label}`;
                this.lessonSelect.appendChild(option);
            }
            if (this.lessonId) {
                this.applyLessonSelection(this.lessonId);
            }
            this.lessonSelect.addEventListener("change", () => {
                this.lessonSelectionTouched = true;
                this.setLessonId(this.lessonSelect?.value ?? "");
            });
        }
        if (this.lessonId) {
            this.setLessonId(this.lessonId);
        }
    }
    syncLessonSelectionFromProgress() {
        if (this.lessonSelectionTouched)
            return;
        if (typeof window === "undefined" || !window.localStorage)
            return;
        const progress = readLessonProgress(window.localStorage);
        const pathState = buildLessonPathViewState(progress.lessonCompletions ?? {});
        const nextLessonId = pathState.next?.id ?? null;
        if (nextLessonId && nextLessonId !== this.lessonId) {
            this.setLessonId(nextLessonId);
        }
    }
    setLessonId(lessonId) {
        const lesson = this.lessonCatalog.find((entry) => entry.id === lessonId) ?? this.lessonCatalog[0] ?? null;
        this.lessonId = lesson?.id ?? null;
        if (this.lessonSelect && lesson) {
            this.applyLessonSelection(lesson.id);
        }
        const wordlists = lesson ? listLessonWordlists(lesson.id) : [];
        const pool = new Set();
        for (const list of wordlists) {
            for (const word of list.words ?? []) {
                if (typeof word === "string" && word.length > 0) {
                    pool.add(word);
                }
            }
        }
        this.lessonWords = Array.from(pool);
        if (this.lessonDescription) {
            if (!lesson) {
                this.lessonDescription.textContent = "Select a lesson to load a word list.";
            }
            else {
                const listCount = wordlists.length;
                const wordCount = this.lessonWords.length;
                const listLabel = listCount === 1 ? "list" : "lists";
                const wordLabel = wordCount === 1 ? "word" : "words";
                this.lessonDescription.textContent = `${lesson.description} (${listCount} ${listLabel}, ${wordCount} ${wordLabel}).`;
            }
        }
        if (this.state.mode === "lesson" && !this.state.active) {
            this.state.target = this.pickWord("lesson");
            this.updateTarget();
            this.updateMetrics();
        }
    }
    applyLessonSelection(value) {
        if (!this.lessonSelect)
            return;
        try {
            this.lessonSelect.value = value;
            return;
        }
        catch {
            // Some DOM shims expose read-only select values; fall back to option selection.
        }
        const options = this.lessonSelect.options
            ? Array.from(this.lessonSelect.options)
            : Array.from(this.lessonSelect.querySelectorAll("option"));
        for (const option of options) {
            option.selected = option.value === value;
        }
    }
    handleKey(event) {
        if (event.key === "Escape") {
            event.preventDefault();
            this.close();
            return;
        }
        if (!this.state.active) {
            if (event.key === "Enter") {
                event.preventDefault();
                this.start();
            }
            return;
        }
        if (this.state.mode === "shortcuts") {
            this.handleShortcutKey(event);
            return;
        }
        if (this.state.mode === "shift") {
            this.handleShiftTutorKey(event);
            return;
        }
        if (this.state.mode === "reaction") {
            this.handleReactionKey(event);
            return;
        }
        if (this.state.mode === "support") {
            this.handleSupportKey(event);
            return;
        }
        if (this.state.mode === "reading") {
            this.handleReadingKey(event);
            return;
        }
        if (event.key === "Backspace") {
            event.preventDefault();
            this.state.buffer = this.state.buffer.slice(0, -1);
            this.updateTarget();
            return;
        }
        if (event.key === "Enter") {
            event.preventDefault();
            this.commitWord(true);
            return;
        }
        if (event.key.length === 1 && /^[a-zA-Z0-9\-;',./!?:"_@#$%^&*() ]$/.test(event.key)) {
            event.preventDefault();
            const char = event.key.toLowerCase();
            const cursor = this.state.buffer.length;
            const expected = this.state.target[cursor] ?? "";
            const expectedLower = expected.toLowerCase();
            const isExpectedLetter = expectedLower.length === 1 && /^[a-z]$/.test(expectedLower);
            const isError = char !== expectedLower;
            if (isExpectedLetter) {
                this.recordPatternAttempt("key", expectedLower, isError);
                if (cursor > 0) {
                    const prevTyped = this.state.buffer[cursor - 1]?.toLowerCase?.() ?? "";
                    const prevExpected = this.state.target[cursor - 1]?.toLowerCase?.() ?? "";
                    const prevMatches = prevTyped.length === 1 && prevTyped === prevExpected && /^[a-z]$/.test(prevTyped);
                    if (prevMatches) {
                        this.recordPatternAttempt("digraph", `${prevExpected}${expectedLower}`, isError);
                    }
                }
            }
            this.state.buffer += char;
            this.state.totalInputs += 1;
            if (char === expected) {
                this.state.correctInputs += 1;
            }
            else {
                this.state.errors += 1;
                this.state.wordErrors += 1;
                if (this.state.mode === "combo") {
                    if (this.comboMistakesRemaining > 0) {
                        this.comboMistakesRemaining = Math.max(0, this.comboMistakesRemaining - 1);
                        if (this.comboMistakesRemaining === 0) {
                            this.showToast("No mistakes left — next miss breaks combo.");
                        }
                    }
                    else {
                        if (this.comboUnshieldedErrorsThisWord === 0 && this.state.combo > 0) {
                            this.state.combo = 0;
                            this.showToast("Combo broken.");
                        }
                        this.comboUnshieldedErrorsThisWord += 1;
                    }
                }
                if (DRILL_CONFIGS[this.state.mode].penalizeErrors) {
                    this.state.combo = 0;
                    this.state.buffer = "";
                }
            }
            if (this.state.mode === "placement") {
                const hand = this.classifyHand(expected);
                if (hand === "left") {
                    this.state.leftTotalInputs += 1;
                    if (char === expected) {
                        this.state.leftCorrectInputs += 1;
                    }
                }
                else if (hand === "right") {
                    this.state.rightTotalInputs += 1;
                    if (char === expected) {
                        this.state.rightCorrectInputs += 1;
                    }
                }
            }
            this.updateTarget();
            this.updateMetrics();
            this.evaluateCompletion();
        }
    }
    handleShortcutKey(event) {
        event.preventDefault();
        event.stopPropagation?.();
        event.stopImmediatePropagation?.();
        const config = DRILL_CONFIGS.shortcuts;
        const steps = Array.isArray(config.shortcutSteps) ? config.shortcutSteps : [];
        const step = steps[this.state.shortcutStepIndex] ?? null;
        if (!step) {
            this.finish("complete");
            return;
        }
        if (event.repeat) {
            return;
        }
        if (event.key === "Enter") {
            this.state.totalInputs += 1;
            this.state.errors += 1;
            this.state.combo = 0;
            this.state.shortcutStepIndex += 1;
            const next = steps[this.state.shortcutStepIndex] ?? null;
            if (!next) {
                this.finish("complete");
                return;
            }
            this.state.target = this.pickWord("shortcuts");
            this.showToast(`Skipped. Next: ${next.label}`);
            this.updateTarget();
            this.updateMetrics();
            return;
        }
        if (event.key === "Control" || event.key === "Shift" || event.key === "Alt" || event.key === "Meta") {
            return;
        }
        this.state.totalInputs += 1;
        const matched = step.chords.some((chord) => this.matchesShortcutChord(chord, event));
        if (!matched) {
            this.state.errors += 1;
            this.state.combo = 0;
            this.showToast(`Try: ${step.comboLabel}`);
            this.updateTarget();
            this.updateMetrics();
            return;
        }
        this.state.correctInputs += 1;
        this.state.wordsCompleted += 1;
        this.state.combo += 1;
        this.state.bestCombo = Math.max(this.state.bestCombo, this.state.combo);
        this.state.shortcutStepIndex += 1;
        const next = steps[this.state.shortcutStepIndex] ?? null;
        if (!next) {
            this.finish("complete");
            return;
        }
        this.state.target = this.pickWord("shortcuts");
        this.showToast(`${step.label} cleared. Next: ${next.label}`);
        this.updateTarget();
        this.updateMetrics();
    }
    handleShiftTutorKey(event) {
        event.preventDefault();
        event.stopPropagation?.();
        event.stopImmediatePropagation?.();
        const config = DRILL_CONFIGS.shift;
        const steps = Array.isArray(config.shiftSteps) ? config.shiftSteps : [];
        const step = steps[this.state.shiftStepIndex] ?? null;
        if (!step) {
            this.finish("complete");
            return;
        }
        if (event.repeat) {
            return;
        }
        if (event.key === "Enter") {
            this.state.totalInputs += 1;
            this.state.errors += 1;
            this.state.combo = 0;
            this.state.shiftStepIndex += 1;
            this.state.shiftHeld = false;
            this.state.shiftLastDownAt = null;
            const next = steps[this.state.shiftStepIndex] ?? null;
            if (!next) {
                this.finish("complete");
                return;
            }
            this.state.target = this.pickWord("shift");
            this.showToast(`Skipped. Next: ${next.label}`);
            this.updateTarget();
            this.updateMetrics();
            return;
        }
        if (event.key === "Shift") {
            this.state.shiftHeld = true;
            this.state.shiftLastDownAt = performance.now();
            this.updateTarget();
            return;
        }
        if (event.key === "Control" || event.key === "Alt" || event.key === "Meta") {
            return;
        }
        if (event.key.length !== 1 || !/^[a-zA-Z]$/.test(event.key)) {
            return;
        }
        const expectedKey = step.key.toLowerCase();
        const actualKey = event.key.toLowerCase();
        this.state.totalInputs += 1;
        this.state.shiftHeld = Boolean(event.shiftKey);
        if (actualKey !== expectedKey) {
            this.state.errors += 1;
            this.state.combo = 0;
            this.showToast(`Target: Shift + ${expectedKey.toUpperCase()}`);
            this.updateTarget();
            this.updateMetrics();
            return;
        }
        if (!event.shiftKey) {
            this.state.errors += 1;
            this.state.combo = 0;
            const recentlyShifted = typeof this.state.shiftLastDownAt === "number" &&
                performance.now() - this.state.shiftLastDownAt < 900;
            this.showToast(recentlyShifted
                ? "Hold Shift down - don't tap and release before the letter."
                : `Hold Shift while tapping ${expectedKey.toUpperCase()}.`);
            this.state.shiftHeld = false;
            this.state.shiftLastDownAt = null;
            this.updateTarget();
            this.updateMetrics();
            return;
        }
        this.state.correctInputs += 1;
        this.state.wordsCompleted += 1;
        this.state.combo += 1;
        this.state.bestCombo = Math.max(this.state.bestCombo, this.state.combo);
        this.state.shiftStepIndex += 1;
        this.state.shiftLastDownAt = null;
        const next = steps[this.state.shiftStepIndex] ?? null;
        if (!next) {
            this.finish("complete");
            return;
        }
        this.state.target = this.pickWord("shift");
        this.showToast(`${step.label} cleared. Next: ${next.label}`);
        this.updateTarget();
        this.updateMetrics();
    }
    handleReactionKey(event) {
        if (event.key === "Tab") {
            return;
        }
        event.preventDefault();
        event.stopPropagation?.();
        event.stopImmediatePropagation?.();
        if (event.repeat) {
            return;
        }
        if (event.key === "Control" || event.key === "Alt" || event.key === "Meta" || event.key === "Shift") {
            return;
        }
        if (event.key === "Backspace" || event.key === "Enter") {
            return;
        }
        if (event.key.length !== 1) {
            return;
        }
        const pressed = event.key.toLowerCase();
        const now = performance.now();
        this.state.elapsedMs =
            this.state.startTime > 0 ? Math.max(0, now - this.state.startTime) : this.state.elapsedMs;
        if (!this.reactionPromptKey) {
            this.state.totalInputs += 1;
            this.state.errors += 1;
            this.state.combo = 0;
            this.showToast("Too soon — wait for the cue.");
            this.updateTarget();
            this.updateMetrics();
            this.queueReactionPrompt({ penalty: true });
            return;
        }
        const expected = this.reactionPromptKey.toLowerCase();
        const isError = pressed !== expected;
        this.state.totalInputs += 1;
        if (expected.length === 1 && /^[a-z]$/.test(expected)) {
            this.recordPatternAttempt("key", expected, isError);
        }
        if (!isError) {
            this.state.correctInputs += 1;
            this.state.wordsCompleted += 1;
            this.state.combo += 1;
            this.state.bestCombo = Math.max(this.state.bestCombo, this.state.combo);
            const latencyMs = typeof this.reactionPromptAt === "number" ? Math.max(0, now - this.reactionPromptAt) : 0;
            this.reactionLatenciesMs.push(latencyMs);
            this.reactionLastLatencyMs = latencyMs;
            this.showToast(`Hit! ${Math.round(latencyMs)}ms`);
        }
        else {
            this.state.errors += 1;
            this.state.combo = 0;
            this.showToast(`Miss. Target: ${this.formatReactionKey(this.reactionPromptKey)}`);
        }
        this.reactionPromptKey = null;
        this.reactionPromptAt = null;
        this.state.buffer = "";
        this.state.target = "";
        this.updateTarget();
        this.updateMetrics();
        this.queueReactionPrompt();
    }
    handleSupportKey(event) {
        if (event.key === "Tab") {
            return;
        }
        event.preventDefault();
        event.stopPropagation?.();
        event.stopImmediatePropagation?.();
        if (event.repeat) {
            return;
        }
        if (event.key === "Control" || event.key === "Alt" || event.key === "Meta" || event.key === "Shift") {
            return;
        }
        if (event.key === "Backspace") {
            return;
        }
        const now = performance.now();
        this.state.elapsedMs =
            this.state.startTime > 0 ? Math.max(0, now - this.state.startTime) : this.state.elapsedMs;
        if (event.key === "Enter") {
            this.state.totalInputs += 1;
            this.state.errors += 1;
            this.state.combo = 0;
            this.showToast("Skipped. Next route.");
            this.setNextSupportPrompt();
            return;
        }
        if (event.key.length !== 1) {
            return;
        }
        const pressed = event.key.toLowerCase();
        if (pressed !== "a" &&
            pressed !== "b" &&
            pressed !== "c" &&
            pressed !== "1" &&
            pressed !== "2" &&
            pressed !== "3") {
            return;
        }
        if (this.supportPromptLane === null) {
            this.setNextSupportPrompt();
        }
        const lane = typeof this.supportPromptLane === "number"
            ? Math.max(0, Math.min(2, Math.floor(this.supportPromptLane)))
            : 0;
        const expectedLetter = this.supportLaneLetter(lane);
        const expectedNumber = this.supportLaneNumber(lane);
        const isError = pressed !== expectedLetter && pressed !== expectedNumber;
        this.state.totalInputs += 1;
        this.recordPatternAttempt("key", expectedLetter, isError);
        if (!isError) {
            this.state.correctInputs += 1;
            this.state.wordsCompleted += 1;
            this.state.combo += 1;
            this.state.bestCombo = Math.max(this.state.bestCombo, this.state.combo);
            const latencyMs = typeof this.supportPromptAt === "number" ? Math.max(0, now - this.supportPromptAt) : 0;
            this.supportLatenciesMs.push(latencyMs);
            this.supportLastLatencyMs = latencyMs;
            const action = this.supportPromptAction ? `${this.supportPromptAction} ` : "";
            this.showToast(`${action}routed to ${this.formatSupportLane(lane)} (${Math.round(latencyMs)}ms).`);
        }
        else {
            this.state.errors += 1;
            this.state.combo = 0;
            this.showToast(`Miss. Target: ${this.formatSupportLane(lane)}.`);
        }
        this.state.buffer = "";
        this.state.target = "";
        this.setNextSupportPrompt();
    }
    handleReadingKey(event) {
        if (event.key === "Tab") {
            return;
        }
        event.preventDefault();
        event.stopPropagation?.();
        event.stopImmediatePropagation?.();
        if (event.repeat) {
            return;
        }
        if (this.readingQueue.length === 0) {
            this.startReading("reading");
        }
        const passageCount = this.readingQueue.length;
        const passage = this.readingQueue[this.readingPassageIndex] ?? null;
        if (!passage || passageCount === 0) {
            this.finish("complete");
            return;
        }
        if (this.readingStage === "passage") {
            if (event.key === "Enter") {
                this.readingStage = "question";
                this.readingQuestionIndex = 0;
                this.state.buffer = "";
                this.state.target = "";
                this.showToast("Quiz time: type A, B, or C.");
                this.updateTarget();
                this.updateMetrics();
            }
            return;
        }
        if (event.key.length !== 1) {
            return;
        }
        const answer = event.key.toLowerCase();
        if (!/^[a-z]$/.test(answer)) {
            return;
        }
        const question = passage.questions?.[this.readingQuestionIndex] ?? null;
        if (!question) {
            this.finish("complete");
            return;
        }
        const optionKeys = new Set((question.options ?? []).map((opt) => (typeof opt.key === "string" ? opt.key.toLowerCase() : "")));
        if (optionKeys.size > 0 && !optionKeys.has(answer)) {
            this.showToast("Type A, B, or C.");
            return;
        }
        this.state.totalInputs += 1;
        const correctKey = (question.correct ?? "").toLowerCase();
        const correct = answer === correctKey;
        if (correct) {
            this.state.correctInputs += 1;
            this.state.wordsCompleted += 1;
            this.state.combo += 1;
            this.state.bestCombo = Math.max(this.state.bestCombo, this.state.combo);
            this.showToast("Correct!");
        }
        else {
            this.state.errors += 1;
            this.state.combo = 0;
            const correctLabel = correctKey ? correctKey.toUpperCase() : "?";
            const explanation = typeof question.explanation === "string" ? question.explanation.trim() : "";
            this.showToast(explanation ? `Not quite. ${correctLabel}. ${explanation}` : `Not quite. Correct: ${correctLabel}.`);
        }
        this.state.buffer = "";
        this.state.target = "";
        const hasNextQuestion = this.readingQuestionIndex + 1 < (passage.questions?.length ?? 0);
        if (hasNextQuestion) {
            this.readingQuestionIndex += 1;
            this.updateTarget();
            this.updateMetrics();
            return;
        }
        const hasNextPassage = this.readingPassageIndex + 1 < passageCount;
        if (hasNextPassage) {
            this.readingPassageIndex += 1;
            this.readingStage = "passage";
            this.readingQuestionIndex = 0;
            this.showToast("Next passage. Press Enter when ready.");
            this.updateTarget();
            this.updateMetrics();
            return;
        }
        this.finish("complete");
    }
    matchesShortcutChord(chord, event) {
        const expectedKey = chord.key.length === 1 ? chord.key.toLowerCase() : chord.key;
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
    classifyHand(char) {
        const normalized = char.toLowerCase();
        if ("qwertasdfgzxcvb12345".includes(normalized))
            return "left";
        if ("yuiophjklnm67890".includes(normalized))
            return "right";
        return "neutral";
    }
    evaluateCompletion() {
        if (!this.state.target || this.state.buffer.length === 0) {
            return;
        }
        if (this.state.buffer === this.state.target) {
            this.commitWord(false);
        }
    }
    commitWord(skipped) {
        const config = DRILL_CONFIGS[this.state.mode];
        const flawless = this.state.wordErrors === 0 && !skipped;
        if (this.state.mode === "combo") {
            if (skipped) {
                this.state.combo = Math.max(0, this.state.combo - 1);
                this.state.errors += 1;
            }
            else if (flawless) {
                this.state.combo += 1;
            }
            else if (this.comboUnshieldedErrorsThisWord === 0) {
                // Mistakes happened, but the segment shield protected the combo.
            }
            else {
                this.state.combo = 0;
            }
            this.comboUnshieldedErrorsThisWord = 0;
        }
        else if (flawless) {
            this.state.combo += 1;
        }
        else if (!skipped) {
            this.state.combo = Math.max(0, Math.floor(this.state.combo * 0.5));
        }
        else {
            this.state.combo = Math.max(0, this.state.combo - 1);
            this.state.errors += 1;
        }
        this.state.bestCombo = Math.max(this.state.bestCombo, this.state.combo);
        this.state.wordsCompleted += skipped ? 0 : 1;
        this.state.wordErrors = 0;
        this.state.buffer = "";
        this.updateMetrics();
        const now = performance.now();
        this.state.elapsedMs = this.state.startTime > 0 ? now - this.state.startTime : 0;
        const reachedWordGoal = typeof config.wordCount === "number" && this.state.wordsCompleted >= config.wordCount;
        if (reachedWordGoal) {
            this.finish("complete");
            return;
        }
        this.state.target = this.pickWord(this.state.mode);
        this.updateTarget();
    }
    finish(reason) {
        this.cleanupTimer?.();
        this.cleanupTimer = undefined;
        this.stopMetronome();
        this.stopReactionPrompt();
        this.stopSupport();
        const now = performance.now();
        this.state.active = false;
        this.state.elapsedMs =
            this.state.startTime > 0 && now > this.state.startTime ? now - this.state.startTime : 0;
        this.state.buffer = "";
        this.updateTarget();
        this.updateMetrics();
        this.updateLessonControls();
        if (this.statusLabel) {
            this.statusLabel.textContent = reason === "timeout" ? "Time" : "Complete";
        }
        const summary = this.buildSummary();
        this.maybeUpdateSprintGhost(summary);
        const analyticsSummary = this.toAnalyticsSummary(summary);
        this.renderSummary(summary, analyticsSummary);
        if (summary.placementResult) {
            const storage = typeof window !== "undefined" ? window.localStorage : null;
            writePlacementTestResult(storage, summary.placementResult);
        }
        if (analyticsSummary.mode !== "placement" &&
            analyticsSummary.mode !== "shortcuts" &&
            analyticsSummary.mode !== "shift") {
            this.callbacks.onSummary?.(analyticsSummary);
        }
        if (this.startBtn) {
            this.startBtn.textContent = this.state.mode === "lesson" ? "Repeat Lesson" : "Run again";
        }
    }
    buildSummary() {
        const elapsedMs = this.state.elapsedMs > 0 ? this.state.elapsedMs : 1;
        let accuracy = this.state.totalInputs > 0 ? this.state.correctInputs / this.state.totalInputs : 1;
        if (this.state.mode === "reading") {
            const totalQuestions = this.readingTotalQuestions > 0 ? this.readingTotalQuestions : this.state.totalInputs;
            accuracy = totalQuestions > 0 ? this.state.correctInputs / totalQuestions : 0;
        }
        const minutes = elapsedMs / 60000;
        const wpmUnit = this.state.mode === "shortcuts" || this.state.mode === "shift" || this.state.mode === "support"
            ? 1
            : 5;
        const wpm = minutes > 0 ? (this.state.correctInputs / wpmUnit) / minutes : 0;
        const lessonId = this.state.mode === "lesson" && typeof this.lessonId === "string" && this.lessonId.length > 0
            ? this.lessonId
            : undefined;
        let placementResult = null;
        if (this.state.mode === "placement") {
            placementResult = createPlacementTestResult({
                elapsedMs,
                accuracy,
                wpm,
                leftCorrect: this.state.leftCorrectInputs,
                leftTotal: this.state.leftTotalInputs,
                rightCorrect: this.state.rightCorrectInputs,
                rightTotal: this.state.rightTotalInputs
            });
        }
        const tip = placementResult?.recommendation?.note?.length > 0
            ? placementResult.recommendation.note
            : this.buildTip(accuracy, wpm);
        return {
            mode: this.state.mode,
            source: this.state.startSource ?? "cta",
            timestamp: Date.now(),
            lessonId,
            elapsedMs,
            accuracy,
            bestCombo: this.state.bestCombo,
            words: this.state.wordsCompleted,
            errors: this.state.errors,
            wpm,
            tip,
            placementResult
        };
    }
    toAnalyticsSummary(summary) {
        const patterns = this.buildPatternStatsPayload();
        return {
            mode: summary.mode,
            source: summary.source,
            lessonId: summary.lessonId,
            elapsedMs: summary.elapsedMs,
            accuracy: summary.accuracy,
            bestCombo: summary.bestCombo,
            words: summary.words,
            errors: summary.errors,
            wpm: summary.wpm,
            patterns,
            timestamp: summary.timestamp
        };
    }
    buildTip(accuracy, wpm) {
        if (this.state.mode === "hand") {
            const sideLabel = this.handIsolationSide === "left" ? "left" : "right";
            if (accuracy < 0.85) {
                return `Slow down and focus on clean hits with your ${sideLabel} hand.`;
            }
            if (wpm >= 55) {
                return `Great pace. Swap hands and see if you can match ${Math.round(wpm)} WPM with the other side.`;
            }
            return `Nice work. Keep the non-typing hand relaxed while your ${sideLabel} hand stays steady.`;
        }
        if (this.state.mode === "support") {
            const routes = this.state.wordsCompleted;
            if (routes <= 0) {
                return "Press 1/2/3 to route support to the highlighted lane. In combat, press 1-3 for Support Surge.";
            }
            const average = this.getSupportAverageMs();
            const best = this.getSupportBestMs();
            const averageLabel = typeof average === "number" ? `${Math.round(average)}ms` : "-";
            const bestLabel = typeof best === "number" ? `${Math.round(best)}ms` : "-";
            if (accuracy < 0.85) {
                return `Aim for clean lane calls. Average ${averageLabel}. In combat, press 1-3 for Support Surge.`;
            }
            return `Average route ${averageLabel} (best ${bestLabel}). Keep your eyes on the lane, then tap the number. In combat, press 1-3 for Support Surge.`;
        }
        if (this.state.mode === "reaction") {
            const hitCount = this.reactionLatenciesMs.length;
            if (hitCount === 0) {
                return "Wait for the cue, then tap the key. False starts cost accuracy.";
            }
            const average = this.getReactionAverageMs();
            const best = this.getReactionBestMs();
            const averageLabel = typeof average === "number" ? `${Math.round(average)}ms` : "—";
            const bestLabel = typeof best === "number" ? `${Math.round(best)}ms` : "—";
            return `Average reaction ${averageLabel} (best ${bestLabel}). Stay relaxed and watch the cue.`;
        }
        if (this.state.mode === "combo") {
            if (accuracy < 0.85) {
                return "Slow down and protect your mistake pool; once it's empty, the next miss breaks combo.";
            }
            if (this.state.bestCombo >= 8) {
                return "Great streak. Try the next run with fewer than three mistakes total.";
            }
            return "Stay smooth. Fix errors quickly and keep enough mistakes for the harder segments.";
        }
        if (this.state.mode === "reading") {
            const total = this.readingTotalQuestions;
            const score = this.state.correctInputs;
            if (total > 0 && score >= total) {
                return `Perfect score ${score}/${total}. Great job staying focused.`;
            }
            if (total > 0 && this.state.totalInputs === 0) {
                return `Read the passage, press Enter, then type A/B/C. Score ${score}/${total}.`;
            }
            if (total > 0) {
                return `Score ${score}/${total}. Best streak x${this.state.bestCombo}. Replay to improve.`;
            }
            return "Read the passage, then type A/B/C to answer the questions.";
        }
        if (this.state.mode === "shortcuts") {
            if (accuracy < 0.85) {
                return "Slow down and find Ctrl/Cmd first, then tap the letter key.";
            }
            if (this.state.bestCombo >= 3) {
                return "Nice streak. Shortcuts save time in docs, email, and code editors.";
            }
            return "Great work. Keep your fingers relaxed and use shortcuts in your next writing session.";
        }
        if (this.state.mode === "shift") {
            if (accuracy < 0.85) {
                return "Hold Shift until the letter lands. Try the opposite Shift key for better reach.";
            }
            if (this.state.bestCombo >= 4) {
                return "Nice timing. Use left Shift for right-hand letters and right Shift for left-hand letters.";
            }
            return "Good work. Keep Shift held lightly and release after each capital letter.";
        }
        if (this.state.mode === "focus") {
            const keyLabel = this.focusKeys.length > 0 ? this.focusKeys.map((key) => key.toUpperCase()).join(", ") : "";
            if (accuracy < 0.85) {
                return keyLabel
                    ? `Slow down on ${keyLabel}. Clean hits first, speed second.`
                    : "Slow down and rebuild accuracy one clean stroke at a time.";
            }
            return keyLabel
                ? `Keep your eyes on the focus keys: ${keyLabel}.`
                : "Great work. Keep your eyes on the focus keys and stay relaxed.";
        }
        if (this.state.mode === "warmup") {
            const keyLabel = this.warmupKeys.length > 0 ? this.warmupKeys.map((key) => key.toUpperCase()).join(", ") : "";
            if (accuracy < 0.85) {
                return keyLabel
                    ? `Slow down on ${keyLabel}. Clean hits first, speed second.`
                    : "Slow down and rebuild accuracy one clean stroke at a time.";
            }
            return keyLabel
                ? `Stay smooth through the warm-up keys: ${keyLabel}.`
                : "Great work. Stay smooth and keep your shoulders relaxed.";
        }
        if (accuracy < 0.85) {
            return "Slow the first three letters and reset on mistakes to rebuild accuracy.";
        }
        if (this.state.mode === "burst" && accuracy >= 0.97) {
            return "Great start. Jump to Shield Breaker to stress accuracy under pressure.";
        }
        if (this.state.mode === "endurance" && wpm >= 55) {
            return "Solid cadence. Try holding 55+ WPM with fewer than two errors next run.";
        }
        if (this.state.mode === "precision" && this.state.bestCombo >= 4) {
            return "You are breaking shields. Add a metronome or try the Burst warmup between waves.";
        }
        return "Use drills between waves to keep combo decay comfortable before rejoining the siege.";
    }
    renderSummary(summary, analyticsSummary) {
        if (!this.summaryEl)
            return;
        this.summaryEl.setAttribute("data-visible", "true");
        if (this.summaryTime) {
            this.summaryTime.textContent = `${(summary.elapsedMs / 1000).toFixed(1)}s`;
        }
        if (this.summaryAccuracy) {
            this.summaryAccuracy.textContent = `${Math.round(summary.accuracy * 100)}%`;
        }
        if (this.summaryCombo) {
            this.summaryCombo.textContent = `x${summary.bestCombo}`;
        }
        if (this.summaryWords) {
            this.summaryWords.textContent = `${summary.words}`;
        }
        if (this.summaryErrors) {
            this.summaryErrors.textContent = `${summary.errors}`;
        }
        const showPlacement = summary.mode === "placement" && Boolean(summary.placementResult);
        if (this.summaryLeft) {
            const row = this.summaryLeft.parentElement;
            row?.toggleAttribute("hidden", !showPlacement);
            if (showPlacement && summary.placementResult) {
                const pct = Math.round(summary.placementResult.leftAccuracy * 100);
                this.summaryLeft.textContent = `${pct}% (${summary.placementResult.leftSamples})`;
            }
            else {
                this.summaryLeft.textContent = "";
            }
        }
        if (this.summaryRight) {
            const row = this.summaryRight.parentElement;
            row?.toggleAttribute("hidden", !showPlacement);
            if (showPlacement && summary.placementResult) {
                const pct = Math.round(summary.placementResult.rightAccuracy * 100);
                this.summaryRight.textContent = `${pct}% (${summary.placementResult.rightSamples})`;
            }
            else {
                this.summaryRight.textContent = "";
            }
        }
        if (this.summaryPacing) {
            const row = this.summaryPacing.parentElement;
            row?.toggleAttribute("hidden", !showPlacement);
            if (showPlacement && summary.placementResult) {
                this.summaryPacing.textContent = `${Math.round(summary.placementResult.recommendation.tutorialPacing * 100)}%`;
            }
            else {
                this.summaryPacing.textContent = "";
            }
        }
        if (this.summaryTip) {
            this.summaryTip.textContent = summary.tip;
        }
        const hideMedal = showPlacement ||
            summary.mode === "shortcuts" ||
            summary.mode === "shift" ||
            summary.mode === "focus" ||
            summary.mode === "warmup" ||
            summary.mode === "reaction" ||
            summary.mode === "support" ||
            summary.mode === "combo" ||
            summary.mode === "reading";
        if (this.summaryMedal) {
            this.summaryMedal.toggleAttribute("hidden", hideMedal);
        }
        if (!hideMedal) {
            const medalResult = evaluateLessonMedal(analyticsSummary ?? this.toAnalyticsSummary(summary));
            this.renderMedalResult(medalResult.tier, medalResult.nextTarget);
        }
    }
    renderMedalResult(tier, nextTarget) {
        const label = tier.charAt(0).toUpperCase() + tier.slice(1);
        if (this.summaryMedal) {
            this.summaryMedal.dataset.tier = tier;
        }
        if (this.summaryMedalLabel) {
            this.summaryMedalLabel.textContent = `${label} medal earned`;
        }
        if (this.summaryMedalHint) {
            this.summaryMedalHint.textContent =
                nextTarget?.hint ?? "You reached the top tier. Great work!";
        }
        if (this.summaryReplay) {
            this.summaryReplay.textContent = nextTarget
                ? `Replay for ${nextTarget.tier.charAt(0).toUpperCase() + nextTarget.tier.slice(1)}`
                : "Replay drill";
            this.summaryReplay.dataset.tier = tier;
        }
    }
    updateMode(mode, options = {}) {
        this.state.mode = mode;
        if (!this.state.active) {
            this.prepareSprintGhost(mode);
        }
        for (const btn of this.modeButtons) {
            const selected = btn.dataset.mode === mode;
            btn.setAttribute("aria-selected", selected ? "true" : "false");
        }
        this.updateShiftTutorControls(mode);
        this.updateMetronomeControls(mode);
        this.updateHandIsolationControls(mode);
        this.updateLessonControls(mode);
        if (mode === "lesson" && !this.state.active) {
            this.syncLessonSelectionFromProgress();
        }
        if (!options.silent) {
            this.state.target = this.pickWord(mode);
            this.updateTarget();
        }
    }
    updateShiftTutorControls(mode = this.state.mode) {
        if (!this.slowMoBtn)
            return;
        const visible = mode === "shift";
        this.slowMoBtn.dataset.visible = visible ? "true" : "false";
        this.slowMoBtn.disabled = this.state.active && visible;
        this.slowMoBtn.setAttribute("aria-pressed", this.shiftTutorSlowMo ? "true" : "false");
        this.slowMoBtn.textContent = this.shiftTutorSlowMo ? "Slow-mo: On" : "Slow-mo: Off";
    }
    updateMetronomeControls(mode = this.state.mode) {
        if (!this.metronomeBtn)
            return;
        const visible = mode === "rhythm";
        this.metronomeBtn.dataset.visible = visible ? "true" : "false";
        if (!visible) {
            delete this.metronomeBtn.dataset.beat;
            return;
        }
        this.metronomeBtn.setAttribute("aria-pressed", this.metronomeEnabled ? "true" : "false");
        this.metronomeBtn.textContent = this.metronomeEnabled ? "Metronome: On" : "Metronome: Off";
    }
    updateHandIsolationControls(mode = this.state.mode) {
        if (!this.handBtn)
            return;
        const visible = mode === "hand";
        this.handBtn.dataset.visible = visible ? "true" : "false";
        if (!visible)
            return;
        this.handBtn.disabled = this.state.active;
        const label = this.handIsolationSide === "left" ? "Left" : "Right";
        this.handBtn.textContent = `Hand: ${label}`;
        this.handBtn.setAttribute("aria-pressed", this.handIsolationSide === "left" ? "true" : "false");
    }
    updateLessonControls(mode = this.state.mode) {
        if (!this.lessonPicker)
            return;
        const visible = mode === "lesson";
        this.lessonPicker.dataset.visible = visible ? "true" : "false";
        this.lessonPicker.setAttribute("aria-hidden", visible ? "false" : "true");
        if (this.lessonSelect) {
            this.lessonSelect.disabled = Boolean(this.state.active && visible);
        }
    }
    stopMetronome() {
        if (this.metronomeBeatTimeout) {
            window.clearTimeout(this.metronomeBeatTimeout);
            this.metronomeBeatTimeout = null;
        }
        if (this.metronomeLoopTimeout) {
            window.clearTimeout(this.metronomeLoopTimeout);
            this.metronomeLoopTimeout = null;
        }
        this.metronomeNextBeatAt = null;
        this.metronomeBeatIndex = 0;
        if (this.metronomeBtn) {
            delete this.metronomeBtn.dataset.beat;
        }
    }
    startMetronome(mode = this.state.mode) {
        if (!this.metronomeEnabled)
            return;
        if (!this.state.active)
            return;
        if (mode !== "rhythm")
            return;
        const config = DRILL_CONFIGS[mode];
        const bpm = typeof config.metronomeBpm === "number" ? Math.floor(config.metronomeBpm) : 0;
        if (!Number.isFinite(bpm) || bpm <= 0)
            return;
        const accentEvery = typeof config.metronomeAccentEvery === "number" ? Math.max(0, Math.floor(config.metronomeAccentEvery)) : 0;
        const periodMs = 60000 / Math.max(1, bpm);
        this.stopMetronome();
        const storage = typeof window !== "undefined" ? window.localStorage : null;
        const settings = readPlayerSettings(storage);
        const soundVolume = typeof settings.soundVolume === "number" ? settings.soundVolume : 0;
        const audioIntensity = typeof settings.audioIntensity === "number" ? settings.audioIntensity : 1;
        const soundEnabled = Boolean(settings.soundEnabled) && soundVolume > 0;
        this.metronomeSoundLevel = soundEnabled
            ? Math.max(0, Math.min(1, soundVolume)) * Math.max(0, Math.min(1, audioIntensity))
            : 0;
        this.metronomeHapticsAllowed =
            Boolean(settings.hapticsEnabled) &&
                typeof navigator !== "undefined" &&
                typeof navigator.vibrate === "function";
        this.metronomeNextBeatAt = performance.now() + 200;
        this.metronomeBeatIndex = 0;
        const loop = () => {
            if (!this.state.active || this.state.mode !== "rhythm" || !this.metronomeEnabled) {
                this.stopMetronome();
                return;
            }
            const nextBeatAt = this.metronomeNextBeatAt ?? performance.now();
            const delayMs = Math.max(0, nextBeatAt - performance.now());
            this.metronomeLoopTimeout = window.setTimeout(() => {
                this.metronomeBeatIndex += 1;
                const accent = accentEvery > 0 ? (this.metronomeBeatIndex - 1) % accentEvery === 0 : this.metronomeBeatIndex === 1;
                this.pulseMetronomeIndicator(accent);
                this.playMetronomeClick(accent);
                this.playMetronomeHaptic(accent);
                this.metronomeNextBeatAt = nextBeatAt + periodMs;
                loop();
            }, delayMs);
        };
        loop();
    }
    pulseMetronomeIndicator(accent) {
        if (!this.metronomeBtn)
            return;
        this.metronomeBtn.dataset.beat = accent ? "accent" : "true";
        if (this.metronomeBeatTimeout) {
            window.clearTimeout(this.metronomeBeatTimeout);
        }
        this.metronomeBeatTimeout = window.setTimeout(() => {
            if (this.metronomeBtn) {
                delete this.metronomeBtn.dataset.beat;
            }
            this.metronomeBeatTimeout = null;
        }, 110);
    }
    playMetronomeClick(accent) {
        const volume = this.metronomeSoundLevel;
        if (volume <= 0)
            return;
        if (typeof window === "undefined")
            return;
        try {
            const AudioContextCtor = window
                .AudioContext ??
                window.webkitAudioContext;
            if (!AudioContextCtor)
                return;
            if (!this.metronomeAudio) {
                const ctx = new AudioContextCtor();
                const gain = ctx.createGain();
                gain.gain.value = 0;
                gain.connect(ctx.destination);
                this.metronomeAudio = { ctx, gain };
            }
            const ctx = this.metronomeAudio.ctx;
            void ctx.resume?.();
            const gain = this.metronomeAudio.gain;
            const osc = ctx.createOscillator();
            osc.type = "square";
            osc.frequency.value = accent ? 880 : 660;
            osc.connect(gain);
            const now = ctx.currentTime;
            const clickGain = 0.03 * Math.max(0, Math.min(1, volume)) * (accent ? 1.1 : 0.9);
            gain.gain.cancelScheduledValues(now);
            gain.gain.setValueAtTime(0.0001, now);
            gain.gain.exponentialRampToValueAtTime(clickGain, now + 0.006);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.05);
            osc.start(now);
            osc.stop(now + 0.055);
            osc.onended = () => {
                try {
                    osc.disconnect();
                }
                catch {
                    // ignore disconnect issues
                }
            };
        }
        catch {
            // ignore audio failures
        }
    }
    playMetronomeHaptic(accent) {
        if (!this.metronomeHapticsAllowed)
            return;
        try {
            navigator.vibrate(accent ? 16 : 10);
        }
        catch {
            // ignore haptic failures
        }
    }
    ensureLessonWordPool() {
        if (this.lessonWords.length > 0)
            return;
        const fallback = this.lessonCatalog[0]?.id ?? "";
        this.setLessonId(this.lessonId ?? fallback);
    }
    pickWord(mode) {
        const config = DRILL_CONFIGS[mode];
        if (mode === "reaction") {
            return "";
        }
        if (mode === "reading") {
            return "";
        }
        if (mode === "support") {
            return "";
        }
        if (mode === "lesson") {
            this.ensureLessonWordPool();
            const pool = this.lessonWords;
            if (pool.length > 0) {
                return pool[Math.floor(Math.random() * pool.length)] ?? "lesson";
            }
            const fallback = this.wordBank.easy ?? defaultWordBank.easy;
            return fallback[Math.floor(Math.random() * fallback.length)] ?? "lesson";
        }
        if (mode === "hand") {
            const pool = HAND_ISOLATION_WORDS[this.handIsolationSide] ?? HAND_ISOLATION_WORDS.left;
            return pool[Math.floor(Math.random() * pool.length)] ?? "hand";
        }
        if (mode === "shortcuts") {
            const steps = Array.isArray(config.shortcutSteps) ? config.shortcutSteps : [];
            const step = steps[this.state.shortcutStepIndex] ?? null;
            return step?.label ?? "shortcuts";
        }
        if (mode === "shift") {
            const steps = Array.isArray(config.shiftSteps) ? config.shiftSteps : [];
            const step = steps[this.state.shiftStepIndex] ?? null;
            return step?.label ?? "shift";
        }
        if (mode === "focus") {
            this.ensureFocusSegments();
            const segments = this.focusSegments;
            const index = Math.max(0, Math.min(segments.length - 1, this.state.segmentIndex));
            const segment = segments[index] ?? null;
            const pool = Array.isArray(segment?.targets) ? segment.targets : [];
            if (pool.length > 0) {
                return pool[Math.floor(Math.random() * pool.length)] ?? pool[0] ?? "focus";
            }
            return segment?.label ?? "focus";
        }
        if (mode === "warmup") {
            this.ensureWarmupSegments();
            const segments = this.warmupSegments;
            const index = Math.max(0, Math.min(segments.length - 1, this.state.segmentIndex));
            const segment = segments[index] ?? null;
            const pool = Array.isArray(segment?.targets) ? segment.targets : [];
            if (pool.length > 0) {
                return pool[Math.floor(Math.random() * pool.length)] ?? pool[0] ?? "warmup";
            }
            return segment?.label ?? "warmup";
        }
        if (mode === "combo") {
            this.ensureComboSegments();
            const segments = this.comboSegments;
            const index = Math.max(0, Math.min(segments.length - 1, this.state.segmentIndex));
            const segment = segments[index] ?? null;
            const pool = Array.isArray(segment?.targets) ? segment.targets : [];
            if (pool.length > 0) {
                return pool[Math.floor(Math.random() * pool.length)] ?? pool[0] ?? "combo";
            }
            return segment?.label ?? "combo";
        }
        if (mode === "placement" && Array.isArray(config.segments) && config.segments.length > 0) {
            const segment = config.segments[Math.max(0, Math.min(config.segments.length - 1, this.state.segmentIndex))];
            const pool = Array.isArray(segment?.targets) ? segment.targets : [];
            if (pool.length > 0) {
                return pool[Math.floor(Math.random() * pool.length)] ?? "defend";
            }
        }
        const customPool = config.targets;
        if (Array.isArray(customPool) && customPool.length > 0) {
            const advancedPool = mode === "symbols" && this.advancedSymbolsUnlocked ? config.advancedTargets : null;
            const pool = Array.isArray(advancedPool) && advancedPool.length > 0
                ? [...customPool, ...advancedPool]
                : customPool;
            return pool[Math.floor(Math.random() * pool.length)] ?? "defend";
        }
        const pool = [...(config.difficulties ?? [])];
        const difficulty = pool.length > 0 ? pool[Math.floor(Math.random() * pool.length)] : "easy";
        const source = this.wordBank[difficulty] ?? defaultWordBank[difficulty];
        if (!Array.isArray(source) || source.length === 0) {
            return "defend";
        }
        return source[Math.floor(Math.random() * source.length)] ?? "defend";
    }
    updateTarget() {
        if (!this.targetEl)
            return;
        if (this.state.mode === "support") {
            const container = document.createElement("div");
            container.className = "typing-drill-support";
            const header = document.createElement("p");
            header.className = "typing-drill-support__kicker";
            const title = document.createElement("p");
            title.className = "typing-drill-support__title";
            const body = document.createElement("div");
            body.className = "typing-drill-support__body";
            const hint = document.createElement("p");
            hint.className = "typing-drill-support__hint";
            header.textContent = "Lane Support";
            if (!this.state.active) {
                title.textContent = "Route support fast";
                const desc = document.createElement("p");
                desc.textContent = "Press 1, 2, or 3 to route support to Lane A/B/C on cue.";
                body.appendChild(desc);
                hint.textContent = "Press Start (or Enter) when ready.";
            }
            else {
                const lane = typeof this.supportPromptLane === "number" ? this.supportPromptLane : null;
                const laneLetter = typeof lane === "number" ? String.fromCharCode(65 + lane) : "?";
                const action = this.supportPromptAction ?? "Support";
                title.textContent =
                    typeof lane === "number" ? `Route ${action} to Lane ${laneLetter}` : "Route incoming support";
                const lanes = document.createElement("div");
                lanes.className = "typing-drill-support__lanes";
                for (let index = 0; index < 3; index += 1) {
                    const card = document.createElement("div");
                    card.className = "typing-drill-support__lane";
                    card.dataset.target = lane === index ? "true" : "false";
                    const key = document.createElement("span");
                    key.className = "typing-drill-support__lane-key";
                    key.textContent = String(index + 1);
                    const label = document.createElement("span");
                    label.className = "typing-drill-support__lane-label";
                    label.textContent = `Lane ${String.fromCharCode(65 + index)}`;
                    card.append(key, label);
                    lanes.appendChild(card);
                }
                body.appendChild(lanes);
                hint.textContent = "Press 1, 2, or 3 (Enter skips).";
            }
            container.append(header, title, body, hint);
            this.targetEl.replaceChildren(container);
            return;
        }
        if (this.state.mode === "reading") {
            const container = document.createElement("div");
            container.className = "typing-drill-reading";
            const header = document.createElement("p");
            header.className = "typing-drill-reading__kicker";
            const title = document.createElement("p");
            title.className = "typing-drill-reading__title";
            const body = document.createElement("div");
            body.className = "typing-drill-reading__body";
            const hint = document.createElement("p");
            hint.className = "typing-drill-reading__hint";
            if (!this.state.active) {
                header.textContent = "Reading Quiz";
                title.textContent = "Read, then answer";
                const desc = document.createElement("p");
                desc.textContent = "Press Start, read the passage, then type A/B/C for each question.";
                body.appendChild(desc);
                hint.textContent = "Tip: Press Enter to move from the passage to the quiz.";
            }
            else {
                if (this.readingQueue.length === 0) {
                    header.textContent = "Reading Quiz";
                    title.textContent = "Loading passage...";
                    hint.textContent = "One moment.";
                }
                else {
                    const passageCount = this.readingQueue.length;
                    const passageNumber = Math.max(1, Math.min(passageCount, this.readingPassageIndex + 1));
                    const totalQuestions = this.readingTotalQuestions;
                    const score = this.state.correctInputs;
                    if (this.readingStage === "passage") {
                        const passage = this.readingQueue[this.readingPassageIndex];
                        header.textContent =
                            totalQuestions > 0
                                ? `Passage ${passageNumber}/${passageCount} • Score ${score}/${totalQuestions}`
                                : `Passage ${passageNumber}/${passageCount}`;
                        title.textContent = passage?.title ?? "Passage";
                        const rawText = passage?.text ?? "";
                        const paragraphs = rawText.split(/\n\n+/).map((part) => part.trim()).filter(Boolean);
                        for (const paragraph of paragraphs) {
                            const p = document.createElement("p");
                            p.textContent = paragraph;
                            body.appendChild(p);
                        }
                        hint.textContent = "Press Enter when you're ready for questions.";
                    }
                    else {
                        const passage = this.readingQueue[this.readingPassageIndex];
                        const question = passage?.questions?.[this.readingQuestionIndex] ?? null;
                        const questionNumber = this.getReadingQuestionNumber();
                        header.textContent =
                            totalQuestions > 0
                                ? `Question ${questionNumber}/${totalQuestions} • Score ${score}/${totalQuestions}`
                                : `Question ${questionNumber}`;
                        title.textContent = question?.prompt ?? "Question";
                        const list = document.createElement("ul");
                        list.className = "typing-drill-reading__options";
                        for (const option of question?.options ?? []) {
                            const li = document.createElement("li");
                            const key = typeof option.key === "string" ? option.key.toUpperCase() : "?";
                            li.textContent = `${key}) ${option.text}`;
                            list.appendChild(li);
                        }
                        body.appendChild(list);
                        hint.textContent = "Type A, B, or C.";
                    }
                }
            }
            container.appendChild(header);
            container.appendChild(title);
            container.appendChild(body);
            container.appendChild(hint);
            this.targetEl.replaceChildren(container);
            if (this.input) {
                this.input.value = "";
            }
            return;
        }
        if (this.state.mode === "reaction") {
            const typedSpan = document.createElement("span");
            typedSpan.className = "typed";
            typedSpan.textContent = this.state.active ? (this.reactionPromptKey ? "GO!" : "Wait...") : "Ready";
            const remainingSpan = document.createElement("span");
            remainingSpan.className = "target-remaining";
            if (!this.state.active) {
                remainingSpan.textContent = "Press Start";
            }
            else if (this.reactionPromptKey) {
                const keycaps = document.createElement("span");
                keycaps.className = "typing-drill-keycaps";
                const cap = document.createElement("span");
                cap.className = "typing-drill-keycap typing-drill-keycap--letter";
                cap.textContent = this.formatReactionKey(this.reactionPromptKey);
                keycaps.appendChild(cap);
                remainingSpan.appendChild(keycaps);
            }
            else {
                remainingSpan.textContent = "...";
            }
            this.targetEl.replaceChildren(typedSpan, remainingSpan);
            if (this.input) {
                this.input.value = "";
            }
            return;
        }
        if (this.state.mode === "shortcuts") {
            const config = DRILL_CONFIGS.shortcuts;
            const steps = Array.isArray(config.shortcutSteps) ? config.shortcutSteps : [];
            const step = steps[this.state.shortcutStepIndex] ?? null;
            const typedSpan = document.createElement("span");
            typedSpan.className = "typed";
            typedSpan.textContent = step?.label ?? "Shortcut Practice";
            const remainingSpan = document.createElement("span");
            remainingSpan.className = "target-remaining";
            remainingSpan.textContent = step?.comboLabel ?? " ";
            this.targetEl.replaceChildren(typedSpan, remainingSpan);
            if (this.input) {
                this.input.value = "";
            }
            return;
        }
        if (this.state.mode === "shift") {
            const config = DRILL_CONFIGS.shift;
            const steps = Array.isArray(config.shiftSteps) ? config.shiftSteps : [];
            const step = steps[this.state.shiftStepIndex] ?? null;
            const typedSpan = document.createElement("span");
            typedSpan.className = "typed";
            typedSpan.textContent = step?.label ?? "Shift Timing";
            const remainingSpan = document.createElement("span");
            remainingSpan.className = "target-remaining";
            const keycaps = document.createElement("span");
            keycaps.className = "typing-drill-keycaps";
            keycaps.dataset.slowmo = this.shiftTutorSlowMo ? "true" : "false";
            const shiftCap = document.createElement("span");
            shiftCap.className = "typing-drill-keycap typing-drill-keycap--modifier";
            shiftCap.dataset.active = this.state.shiftHeld ? "true" : "false";
            shiftCap.textContent = "Shift";
            const plus = document.createElement("span");
            plus.className = "typing-drill-keycaps-plus";
            plus.textContent = "+";
            const letterCap = document.createElement("span");
            letterCap.className = "typing-drill-keycap typing-drill-keycap--letter";
            letterCap.textContent = step ? step.key.toUpperCase() : "?";
            keycaps.replaceChildren(shiftCap, plus, letterCap);
            remainingSpan.appendChild(keycaps);
            if (this.shiftTutorSlowMo) {
                const hint = document.createElement("span");
                hint.className = "typing-drill-shift-hint";
                hint.textContent = "Hold vs tap: press and hold Shift, then tap the letter.";
                remainingSpan.appendChild(hint);
            }
            this.targetEl.replaceChildren(typedSpan, remainingSpan);
            if (this.input) {
                this.input.value = "";
            }
            return;
        }
        const typed = this.state.buffer;
        const remaining = (this.state.target ?? "").slice(typed.length);
        const typedSpan = document.createElement("span");
        typedSpan.className = "typed";
        typedSpan.textContent = typed || " ";
        const remainingSpan = document.createElement("span");
        remainingSpan.className = "target-remaining";
        remainingSpan.textContent = remaining || " ";
        this.targetEl.replaceChildren(typedSpan, remainingSpan);
        if (this.input) {
            this.input.value = this.state.buffer;
        }
    }
    getGhostStorage() {
        return typeof window !== "undefined" ? window.localStorage : null;
    }
    readTypingDrillGhostStore(storage) {
        if (!storage)
            return null;
        try {
            const raw = storage.getItem(TYPING_DRILL_GHOST_STORAGE_KEY);
            if (!raw)
                return null;
            const parsed = JSON.parse(raw);
            if (!parsed || parsed.version !== 1)
                return null;
            return parsed;
        }
        catch {
            return null;
        }
    }
    writeTypingDrillGhostStore(storage, store) {
        if (!storage)
            return;
        try {
            storage.setItem(TYPING_DRILL_GHOST_STORAGE_KEY, JSON.stringify(store));
        }
        catch {
            // ignore storage errors
        }
    }
    readSprintGhostRun(storage) {
        const store = this.readTypingDrillGhostStore(storage);
        const run = store?.sprint;
        if (!run)
            return null;
        if (run.mode !== "sprint")
            return null;
        if (typeof run.timerMs !== "number" || !Number.isFinite(run.timerMs) || run.timerMs <= 0)
            return null;
        if (typeof run.words !== "number" || !Number.isFinite(run.words) || run.words < 0)
            return null;
        if (typeof run.accuracy !== "number" ||
            !Number.isFinite(run.accuracy) ||
            run.accuracy < 0 ||
            run.accuracy > 1) {
            return null;
        }
        if (typeof run.bestCombo !== "number" || !Number.isFinite(run.bestCombo) || run.bestCombo < 0)
            return null;
        if (typeof run.wpm !== "number" || !Number.isFinite(run.wpm) || run.wpm < 0)
            return null;
        if (typeof run.createdAt !== "number" || !Number.isFinite(run.createdAt))
            return null;
        if (!Array.isArray(run.timeline))
            return null;
        return run;
    }
    buildSprintGhostWordsBySecond(run) {
        const maxSecond = Math.max(0, Math.round(Math.max(0, run.timerMs) / 1000));
        const wordsBySecond = new Array(maxSecond + 1).fill(0);
        for (const point of run.timeline) {
            if (!point || typeof point !== "object")
                continue;
            const tMs = point.tMs;
            const words = point.words;
            if (typeof tMs !== "number" || !Number.isFinite(tMs) || tMs < 0)
                continue;
            if (typeof words !== "number" || !Number.isFinite(words) || words < 0)
                continue;
            const second = Math.max(0, Math.min(maxSecond, Math.floor(tMs / 1000)));
            wordsBySecond[second] = Math.max(wordsBySecond[second], Math.floor(words));
        }
        for (let i = 1; i < wordsBySecond.length; i += 1) {
            wordsBySecond[i] = Math.max(wordsBySecond[i - 1], wordsBySecond[i]);
        }
        return wordsBySecond;
    }
    prepareSprintGhost(mode) {
        this.sprintGhostRecordingWordsBySecond = [];
        this.sprintGhostLastSecondRecorded = -1;
        if (mode !== "sprint") {
            this.sprintGhostRun = null;
            this.sprintGhostWordsBySecond = null;
            return;
        }
        const storage = this.getGhostStorage();
        const run = this.readSprintGhostRun(storage);
        this.sprintGhostRun = run;
        this.sprintGhostWordsBySecond = run ? this.buildSprintGhostWordsBySecond(run) : null;
    }
    recordSprintGhostProgress() {
        if (this.state.mode !== "sprint")
            return;
        const timerMs = DRILL_CONFIGS.sprint.timerMs ?? SPRINT_GHOST_TIMER_MS;
        if (typeof timerMs !== "number" || !Number.isFinite(timerMs) || timerMs <= 0)
            return;
        const maxSecond = Math.max(0, Math.round(timerMs / 1000));
        const elapsedMs = Math.max(0, Math.min(timerMs, this.state.elapsedMs));
        const second = Math.max(0, Math.min(maxSecond, Math.floor(elapsedMs / 1000)));
        const words = Math.max(0, Math.floor(this.state.wordsCompleted));
        const startSecond = this.sprintGhostLastSecondRecorded + 1;
        if (second < startSecond)
            return;
        for (let s = startSecond; s <= second; s += 1) {
            this.sprintGhostRecordingWordsBySecond[s] = words;
        }
        this.sprintGhostLastSecondRecorded = second;
    }
    getSprintGhostWordsAtSecond(second) {
        const wordsBySecond = this.sprintGhostWordsBySecond;
        if (!wordsBySecond || wordsBySecond.length === 0)
            return null;
        const index = Math.max(0, Math.min(wordsBySecond.length - 1, Math.floor(second)));
        const value = wordsBySecond[index];
        return typeof value === "number" && Number.isFinite(value) ? Math.max(0, Math.floor(value)) : null;
    }
    isBetterSprintGhost(candidate, current) {
        if (!current)
            return true;
        if (candidate.words !== current.words)
            return candidate.words > current.words;
        if (candidate.accuracy !== current.accuracy)
            return candidate.accuracy > current.accuracy;
        if (candidate.wpm !== current.wpm)
            return candidate.wpm > current.wpm;
        return candidate.bestCombo > current.bestCombo;
    }
    maybeUpdateSprintGhost(summary) {
        if (summary.mode !== "sprint")
            return;
        const timerMs = DRILL_CONFIGS.sprint.timerMs ?? SPRINT_GHOST_TIMER_MS;
        if (typeof timerMs !== "number" || !Number.isFinite(timerMs) || timerMs <= 0)
            return;
        const maxSecond = Math.max(0, Math.round(timerMs / 1000));
        this.recordSprintGhostProgress();
        const wordsBySecond = new Array(maxSecond + 1).fill(0);
        let last = 0;
        for (let second = 0; second <= maxSecond; second += 1) {
            const recorded = this.sprintGhostRecordingWordsBySecond[second];
            const value = typeof recorded === "number" && Number.isFinite(recorded) ? Math.max(0, Math.floor(recorded)) : last;
            last = Math.max(last, value);
            wordsBySecond[second] = last;
        }
        wordsBySecond[maxSecond] = Math.max(wordsBySecond[maxSecond], Math.max(0, Math.floor(summary.words)));
        const candidate = {
            mode: "sprint",
            timerMs,
            words: Math.max(0, Math.floor(summary.words)),
            accuracy: Math.max(0, Math.min(1, summary.accuracy)),
            bestCombo: Math.max(0, Math.floor(summary.bestCombo)),
            wpm: Math.max(0, summary.wpm),
            createdAt: summary.timestamp,
            timeline: wordsBySecond.map((words, second) => ({ tMs: second * 1000, words }))
        };
        const current = this.sprintGhostRun;
        if (!this.isBetterSprintGhost(candidate, current))
            return;
        const storage = this.getGhostStorage();
        const store = this.readTypingDrillGhostStore(storage) ?? { version: 1 };
        store.sprint = candidate;
        this.writeTypingDrillGhostStore(storage, store);
        this.sprintGhostRun = candidate;
        this.sprintGhostWordsBySecond = wordsBySecond;
        const deltaWords = current ? candidate.words - current.words : null;
        const note = typeof deltaWords === "number" && Number.isFinite(deltaWords) && deltaWords > 0
            ? `New best ghost: +${deltaWords} words.`
            : "New best ghost saved.";
        summary.tip = summary.tip ? `${summary.tip} ${note}` : note;
    }
    updateMetrics() {
        let accuracy = this.state.totalInputs > 0 ? this.state.correctInputs / this.state.totalInputs : 1;
        if (this.state.mode === "reading") {
            const totalQuestions = this.readingTotalQuestions > 0 ? this.readingTotalQuestions : this.state.totalInputs;
            accuracy = totalQuestions > 0 ? this.state.correctInputs / totalQuestions : 0;
        }
        const minutes = this.state.elapsedMs / 60000;
        const wpmUnit = this.state.mode === "shortcuts" || this.state.mode === "shift" || this.state.mode === "support"
            ? 1
            : 5;
        const wpm = minutes > 0 ? (this.state.correctInputs / wpmUnit) / minutes : 0;
        if (this.accuracyEl) {
            this.accuracyEl.textContent = `${Math.round(accuracy * 100)}%`;
        }
        if (this.comboEl) {
            this.comboEl.textContent = `x${this.state.combo}`;
        }
        if (this.wpmEl) {
            this.wpmEl.textContent = Math.max(0, Math.round(wpm)).toString();
        }
        if (this.wordsEl) {
            this.wordsEl.textContent = `${this.state.wordsCompleted}`;
        }
        if (this.progressLabel) {
            const config = DRILL_CONFIGS[this.state.mode];
            if (this.state.mode === "reading") {
                if (!this.state.active) {
                    this.progressLabel.textContent = "";
                    return;
                }
                const totalQuestions = this.readingTotalQuestions;
                const scoreLabel = totalQuestions > 0 ? `Score ${this.state.correctInputs}/${totalQuestions}` : `Score ${this.state.correctInputs}`;
                const passageCount = this.readingQueue.length > 0 ? this.readingQueue.length : 1;
                const passageNumber = Math.max(1, Math.min(passageCount, this.readingPassageIndex + 1));
                if (this.readingStage === "passage") {
                    this.progressLabel.textContent = `Passage ${passageNumber}/${passageCount} • ${scoreLabel}`;
                    return;
                }
                const questionNumber = this.getReadingQuestionNumber();
                const questionLabel = totalQuestions > 0 ? `Question ${questionNumber}/${totalQuestions}` : `Question ${questionNumber}`;
                this.progressLabel.textContent = `${questionLabel} • ${scoreLabel}`;
                return;
            }
            if (this.state.mode === "reaction") {
                const average = this.getReactionAverageMs();
                const last = this.reactionLastLatencyMs;
                const parts = [`Hits: ${this.state.wordsCompleted}`];
                if (typeof average === "number") {
                    parts.push(`avg ${Math.round(average)}ms`);
                }
                if (typeof last === "number") {
                    parts.push(`last ${Math.round(last)}ms`);
                }
                this.progressLabel.textContent = parts.join(" / ");
                return;
            }
            if (this.state.mode === "support") {
                const average = this.getSupportAverageMs();
                const best = this.getSupportBestMs();
                const last = this.supportLastLatencyMs;
                const parts = [`Routes: ${this.state.wordsCompleted}`];
                if (typeof average === "number") {
                    parts.push(`avg ${Math.round(average)}ms`);
                }
                if (typeof best === "number") {
                    parts.push(`best ${Math.round(best)}ms`);
                }
                if (typeof last === "number") {
                    parts.push(`last ${Math.round(last)}ms`);
                }
                this.progressLabel.textContent = parts.join(" / ");
                return;
            }
            if (this.state.mode === "sprint") {
                if (this.state.active) {
                    this.recordSprintGhostProgress();
                    const elapsedSecond = Math.floor(Math.max(0, this.state.elapsedMs) / 1000);
                    const ghostWords = this.getSprintGhostWordsAtSecond(elapsedSecond);
                    if (typeof ghostWords === "number") {
                        const delta = Math.max(0, Math.floor(this.state.wordsCompleted)) - ghostWords;
                        const deltaLabel = delta > 0 ? `+${delta}` : `${delta}`;
                        this.progressLabel.textContent = `Words: ${this.state.wordsCompleted} / Ghost: ${ghostWords} (${deltaLabel})`;
                        return;
                    }
                    this.progressLabel.textContent = `Words: ${this.state.wordsCompleted}`;
                    return;
                }
                if (this.sprintGhostRun) {
                    this.progressLabel.textContent = `Best: ${this.sprintGhostRun.words} words`;
                    return;
                }
            }
            if (this.state.mode === "placement" && Array.isArray(config.segments) && config.segments.length > 0) {
                const segment = config.segments[this.state.segmentIndex];
                this.progressLabel.textContent = segment
                    ? `${segment.label} (${this.state.segmentIndex + 1}/${config.segments.length})`
                    : "";
            }
            else if (this.state.mode === "focus" && this.focusSegments.length > 0) {
                const total = this.focusSegments.length;
                const segmentNumber = Math.max(1, Math.min(total, this.state.segmentIndex + 1));
                const segment = this.focusSegments[this.state.segmentIndex];
                this.progressLabel.textContent = segment
                    ? `${segment.label} (${segmentNumber}/${total})`
                    : `${total}/${total}`;
            }
            else if (this.state.mode === "warmup" && this.warmupSegments.length > 0) {
                const total = this.warmupSegments.length;
                const segmentNumber = Math.max(1, Math.min(total, this.state.segmentIndex + 1));
                const segment = this.warmupSegments[this.state.segmentIndex];
                this.progressLabel.textContent = segment
                    ? `${segment.label} (${segmentNumber}/${total})`
                    : `${total}/${total}`;
            }
            else if (this.state.mode === "combo" && this.comboSegments.length > 0) {
                const total = this.comboSegments.length;
                const segmentNumber = Math.max(1, Math.min(total, this.state.segmentIndex + 1));
                const segment = this.comboSegments[this.state.segmentIndex];
                const budget = Math.max(0, Math.floor(this.comboMistakeBudget));
                const remaining = Math.max(0, Math.floor(this.comboMistakesRemaining));
                const suffix = budget > 0 ? ` / mistakes ${remaining}/${budget}` : " / no mistakes";
                this.progressLabel.textContent = segment
                    ? `${segment.label} (${segmentNumber}/${total})${suffix}`
                    : `${total}/${total}`;
            }
            else if (this.state.mode === "shortcuts" &&
                Array.isArray(config.shortcutSteps) &&
                config.shortcutSteps.length > 0) {
                const total = config.shortcutSteps.length;
                const stepNumber = Math.max(1, Math.min(total, this.state.shortcutStepIndex + 1));
                const step = config.shortcutSteps[this.state.shortcutStepIndex];
                this.progressLabel.textContent = step ? `${step.label} (${stepNumber}/${total})` : `${total}/${total}`;
            }
            else if (this.state.mode === "shift" &&
                Array.isArray(config.shiftSteps) &&
                config.shiftSteps.length > 0) {
                const total = config.shiftSteps.length;
                const stepNumber = Math.max(1, Math.min(total, this.state.shiftStepIndex + 1));
                const step = config.shiftSteps[this.state.shiftStepIndex];
                const suffix = this.shiftTutorSlowMo ? " slow-mo" : "";
                this.progressLabel.textContent = step
                    ? `${step.label} (${stepNumber}/${total})${suffix}`
                    : `${total}/${total}`;
            }
            else if (typeof config.wordCount === "number") {
                this.progressLabel.textContent = `${this.state.wordsCompleted}/${config.wordCount}`;
            }
            else {
                this.progressLabel.textContent = `Words: ${this.state.wordsCompleted}`;
            }
        }
    }
    updateTimer() {
        const label = this.timerLabel;
        if (!label)
            return;
        if (this.state.timerEndsAt && this.state.active) {
            const remainingMs = Math.max(0, this.state.timerEndsAt - performance.now());
            const minutes = Math.floor(remainingMs / 60000);
            const seconds = Math.floor((remainingMs % 60000) / 1000);
            label.textContent = `${minutes.toString().padStart(2, "0")}:${seconds
                .toString()
                .padStart(2, "0")}`;
            if (remainingMs <= 0) {
                this.finish("timeout");
            }
            return;
        }
        const elapsedSeconds = Math.max(0, this.state.elapsedMs / 1000);
        const minutes = Math.floor(elapsedSeconds / 60);
        const seconds = Math.floor(elapsedSeconds % 60);
        label.textContent = `${minutes.toString().padStart(2, "0")}:${seconds
            .toString()
            .padStart(2, "0")}`;
    }
    startTimer(endsAt) {
        const interval = window.setInterval(() => {
            this.state.elapsedMs =
                this.state.startTime > 0 ? Math.max(0, performance.now() - this.state.startTime) : 0;
            this.updateTimedSegment();
            this.updateMetrics();
            this.updateTimer();
            if (performance.now() >= endsAt) {
                this.finish("timeout");
            }
        }, 120);
        return () => window.clearInterval(interval);
    }
    updateTimedSegment() {
        if (!this.state.active)
            return;
        const mode = this.state.mode;
        if (mode === "focus") {
            this.ensureFocusSegments();
        }
        if (mode === "warmup") {
            this.ensureWarmupSegments();
        }
        if (mode === "combo") {
            this.ensureComboSegments();
        }
        const segments = mode === "placement"
            ? DRILL_CONFIGS.placement.segments
            : mode === "focus"
                ? this.focusSegments
                : mode === "warmup"
                    ? this.warmupSegments
                    : mode === "combo"
                        ? this.comboSegments
                        : null;
        if (!Array.isArray(segments) || segments.length === 0)
            return;
        const startTime = this.state.startTime;
        if (startTime <= 0)
            return;
        const elapsedMs = Math.max(0, performance.now() - startTime);
        let cumulative = 0;
        let nextIndex = 0;
        for (let i = 0; i < segments.length; i += 1) {
            cumulative += Math.max(0, segments[i]?.durationMs ?? 0);
            if (elapsedMs < cumulative) {
                nextIndex = i;
                break;
            }
            nextIndex = i;
        }
        nextIndex = Math.max(0, Math.min(segments.length - 1, nextIndex));
        if (nextIndex !== this.state.segmentIndex) {
            this.state.segmentIndex = nextIndex;
            this.state.buffer = "";
            this.state.wordErrors = 0;
            if (mode === "combo") {
                this.resetComboSegmentBudget(nextIndex);
            }
            this.state.target = this.pickWord(mode);
            this.updateTarget();
            const label = segments[nextIndex]?.label;
            if (label) {
                this.showToast(mode === "focus"
                    ? `Focus: ${label}`
                    : mode === "warmup"
                        ? `Warm-up: ${label}`
                        : mode === "combo"
                            ? `Combo: ${label}`
                            : `Segment: ${label}`);
            }
        }
    }
    setRecommendation(mode, reason) {
        if (this.fallbackEl) {
            this.fallbackEl.dataset.visible = "false";
        }
        this.recommendationMode = mode;
        this.modeButtons.forEach((btn) => {
            const isRecommended = btn.dataset.mode === mode;
            btn.dataset.recommended = isRecommended ? "true" : "false";
        });
        if (this.recommendationEl && this.recommendationBadge && this.recommendationReason) {
            this.recommendationBadge.textContent =
                mode === "lesson"
                    ? "Lesson"
                    : mode === "burst"
                        ? "Warmup"
                        : mode === "warmup"
                            ? "Plan"
                            : mode === "endurance"
                                ? "Cadence"
                                : mode === "sprint"
                                    ? "Sprint"
                                    : mode === "sentences"
                                        ? "Sentences"
                                        : mode === "reading"
                                            ? "Reading"
                                            : mode === "rhythm"
                                                ? "Rhythm"
                                                : mode === "reaction"
                                                    ? "Reaction"
                                                    : mode === "combo"
                                                        ? "Combo"
                                                        : mode === "symbols"
                                                            ? "Symbols"
                                                            : mode === "placement"
                                                                ? "Placement"
                                                                : mode === "shortcuts"
                                                                    ? "Shortcuts"
                                                                    : mode === "shift"
                                                                        ? "Shift"
                                                                        : mode === "focus"
                                                                            ? "Focus"
                                                                            : "Accuracy";
            this.recommendationReason.textContent = reason;
            this.recommendationEl.dataset.visible = "true";
        }
    }
    showNoRecommendation(message, autoStartMode) {
        if (this.recommendationEl) {
            this.recommendationEl.dataset.visible = "false";
        }
        this.recommendationMode = null;
        this.modeButtons.forEach((btn) => {
            btn.dataset.recommended = "false";
        });
        if (this.fallbackEl) {
            this.fallbackEl.dataset.visible = "true";
            const textNode = this.fallbackEl.querySelector(".typing-drill-fallback__text");
            if (textNode) {
                textNode.textContent = autoStartMode
                    ? `${message} Starting ${this.getModeLabel(autoStartMode)}.`
                    : message;
            }
        }
    }
    formatReactionKey(key) {
        if (key === " ")
            return "Space";
        return key.length === 1 ? key.toUpperCase() : key;
    }
    getReactionAverageMs() {
        if (this.reactionLatenciesMs.length === 0)
            return null;
        let sum = 0;
        let count = 0;
        for (const value of this.reactionLatenciesMs) {
            if (typeof value !== "number" || !Number.isFinite(value))
                continue;
            sum += value;
            count += 1;
        }
        if (count === 0)
            return null;
        return sum / count;
    }
    getReactionBestMs() {
        if (this.reactionLatenciesMs.length === 0)
            return null;
        let best = Number.POSITIVE_INFINITY;
        for (const value of this.reactionLatenciesMs) {
            if (typeof value !== "number" || !Number.isFinite(value))
                continue;
            best = Math.min(best, value);
        }
        return Number.isFinite(best) ? best : null;
    }
    supportLaneLetter(lane) {
        return lane === 1 ? "b" : lane === 2 ? "c" : "a";
    }
    supportLaneNumber(lane) {
        return lane === 1 ? "2" : lane === 2 ? "3" : "1";
    }
    formatSupportLane(lane) {
        const normalized = Math.max(0, Math.min(2, Math.floor(lane)));
        return `Lane ${String.fromCharCode(65 + normalized)}`;
    }
    getSupportAverageMs() {
        if (this.supportLatenciesMs.length === 0)
            return null;
        let sum = 0;
        let count = 0;
        for (const value of this.supportLatenciesMs) {
            if (typeof value !== "number" || !Number.isFinite(value))
                continue;
            sum += value;
            count += 1;
        }
        if (count === 0)
            return null;
        return sum / count;
    }
    getSupportBestMs() {
        if (this.supportLatenciesMs.length === 0)
            return null;
        let best = Number.POSITIVE_INFINITY;
        for (const value of this.supportLatenciesMs) {
            if (typeof value !== "number" || !Number.isFinite(value))
                continue;
            best = Math.min(best, value);
        }
        return Number.isFinite(best) ? best : null;
    }
    startSupport(mode = this.state.mode) {
        this.stopSupport();
        if (!this.state.active)
            return;
        if (mode !== "support")
            return;
        this.supportPreviousLane = null;
        this.setNextSupportPrompt();
    }
    stopSupport() {
        this.supportPromptLane = null;
        this.supportPromptAction = null;
        this.supportPromptAt = null;
    }
    setNextSupportPrompt() {
        if (!this.state.active || this.state.mode !== "support") {
            this.stopSupport();
            this.updateTarget();
            this.updateMetrics();
            return;
        }
        const lanes = [0, 1, 2];
        const previousLane = this.supportPreviousLane;
        if (typeof previousLane === "number" && lanes.length > 1) {
            const index = lanes.indexOf(previousLane);
            if (index >= 0) {
                lanes.splice(index, 1);
            }
        }
        const lane = lanes[Math.floor(Math.random() * lanes.length)] ?? 0;
        this.supportPreviousLane = lane;
        const actions = ["Shield", "Repair", "Boost"];
        const action = actions[Math.floor(Math.random() * actions.length)] ?? "Support";
        this.supportPromptLane = lane;
        this.supportPromptAction = action;
        this.supportPromptAt = performance.now();
        this.state.buffer = "";
        this.state.target = "";
        this.updateTarget();
        this.updateMetrics();
    }
    startReaction(mode = this.state.mode) {
        if (!this.state.active)
            return;
        if (mode !== "reaction")
            return;
        this.reactionPromptKey = null;
        this.reactionPromptAt = null;
        this.state.buffer = "";
        this.state.target = "";
        this.queueReactionPrompt();
    }
    stopReactionPrompt() {
        if (this.reactionPromptTimeout) {
            window.clearTimeout(this.reactionPromptTimeout);
            this.reactionPromptTimeout = null;
        }
        this.reactionPromptKey = null;
        this.reactionPromptAt = null;
        if (this.state.mode === "reaction") {
            this.state.buffer = "";
            this.state.target = "";
        }
    }
    queueReactionPrompt(options = {}) {
        this.stopReactionPrompt();
        if (!this.state.active || this.state.mode !== "reaction") {
            return;
        }
        const minMs = 450;
        const maxMs = 1600;
        const jitter = minMs + Math.random() * (maxMs - minMs);
        const delayMs = Math.round(jitter + (options.penalty ? 650 : 0));
        this.reactionPromptTimeout = window.setTimeout(() => {
            this.reactionPromptTimeout = null;
            if (!this.state.active || this.state.mode !== "reaction")
                return;
            const config = DRILL_CONFIGS.reaction;
            const pool = Array.isArray(config.targets)
                ? config.targets.filter((value) => typeof value === "string" && value.length > 0)
                : [];
            const key = pool.length > 0 ? (pool[Math.floor(Math.random() * pool.length)] ?? pool[0]) : "f";
            this.reactionPromptKey = key;
            this.reactionPromptAt = performance.now();
            this.state.target = key;
            this.updateTarget();
        }, Math.max(0, delayMs));
        this.updateTarget();
    }
    stopReading() {
        this.readingQueue = [];
        this.readingPassageIndex = 0;
        this.readingQuestionIndex = 0;
        this.readingStage = "passage";
        this.readingTotalQuestions = 0;
    }
    buildReadingQueue() {
        const pool = [...READING_PASSAGES];
        const selected = [];
        const targetCount = Math.min(2, pool.length);
        for (let i = 0; i < targetCount; i += 1) {
            const index = Math.max(0, Math.min(pool.length - 1, Math.floor(Math.random() * pool.length)));
            const [picked] = pool.splice(index, 1);
            if (picked) {
                selected.push(picked);
            }
        }
        return selected;
    }
    startReading(mode = this.state.mode) {
        this.stopReading();
        if (!this.state.active)
            return;
        if (mode !== "reading")
            return;
        this.readingQueue = this.buildReadingQueue();
        this.readingTotalQuestions = this.readingQueue.reduce((sum, passage) => sum + (Array.isArray(passage.questions) ? passage.questions.length : 0), 0);
        this.readingPassageIndex = 0;
        this.readingQuestionIndex = 0;
        this.readingStage = "passage";
        this.state.buffer = "";
        this.state.target = "";
        this.updateTarget();
        this.updateMetrics();
    }
    getReadingQuestionNumber() {
        let offset = 0;
        for (let i = 0; i < this.readingPassageIndex; i += 1) {
            const passage = this.readingQueue[i];
            offset += Array.isArray(passage?.questions) ? passage.questions.length : 0;
        }
        return offset + this.readingQuestionIndex + 1;
    }
    getLessonLabel() {
        const lesson = this.lessonCatalog.find((entry) => entry.id === this.lessonId) ?? null;
        if (!lesson)
            return null;
        return `Lesson ${lesson.order}: ${lesson.label}`;
    }
    getModeLabel(mode) {
        switch (mode) {
            case "lesson":
                return "Lesson";
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
    showToast(message) {
        if (!this.toastEl)
            return;
        this.toastEl.textContent = message;
        this.toastEl.dataset.visible = "true";
        window.clearTimeout(this.toastTimeout ?? 0);
        this.toastTimeout = window.setTimeout(() => {
            if (this.toastEl) {
                this.toastEl.dataset.visible = "false";
                this.toastEl.textContent = "";
            }
        }, 3200);
    }
}
