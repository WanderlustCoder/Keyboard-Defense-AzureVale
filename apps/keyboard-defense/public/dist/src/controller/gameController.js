// @ts-nocheck
import { defaultConfig } from "../core/config.js";
import { GameEngine } from "../engine/gameEngine.js";
import { CanvasRenderer } from "../rendering/canvasRenderer.js";
import { HudView } from "../ui/hud.js";
import { DiagnosticsOverlay } from "../ui/diagnostics.js";
import { DebugApi } from "../debug/debugApi.js";
import { SoundManager } from "../audio/soundManager.js";
import { AssetLoader, toSvgDataUri } from "../assets/assetLoader.js";
import { TutorialManager } from "../tutorial/tutorialManager.js";
import { clearTutorialCompletion, readTutorialCompletion, writeTutorialCompletion } from "../tutorial/tutorialPersistence.js";
import { createDefaultPlayerSettings, readPlayerSettings as loadPlayerSettingsFromStorage, withPatchedPlayerSettings, writePlayerSettings, TURRET_PRESET_IDS } from "../utils/playerSettings.js";
import { TelemetryClient } from "../telemetry/telemetryClient.js";
import { calculateCanvasResolution } from "../utils/canvasResolution.js";
const FRAME_DURATION = 1 / 60;
const TUTORIAL_VERSION = "v2";
const HUD_FONT_SCALE_MIN = 0.85;
const HUD_FONT_SCALE_MAX = 1.3;
const SOUND_VOLUME_MIN = 0;
const SOUND_VOLUME_MAX = 1;
const SOUND_VOLUME_DEFAULT = 0.8;
const AUDIO_INTENSITY_MIN = 0.5;
const AUDIO_INTENSITY_MAX = 1.5;
const AUDIO_INTENSITY_DEFAULT = 1;
const CANVAS_BASE_WIDTH = 960;
const CANVAS_BASE_HEIGHT = 540;
const CANVAS_BASE_WIDTH = 960;
const CANVAS_BASE_HEIGHT = 540;
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
export class GameController {
    constructor(options) {
        this.options = options;
        if (!options.canvas) {
            throw new Error("GameController requires a canvas element.");
        }
        this.canvas = options.canvas;
        this.canvasResolution = null;
        this.canvasResizeObserver = null;
        this.viewportResizeHandler = null;
        this.dprMediaQuery = null;
        this.canvasResizeTimeout = null;
        this.updateCanvasResolution(true);
        this.running = false;
        this.speedMultiplier = 1;
        this.lastTimestamp = null;
        this.rafId = null;
        this.soundEnabled = true;
        this.soundVolume = SOUND_VOLUME_DEFAULT;
        this.audioIntensity = AUDIO_INTENSITY_DEFAULT;
        this.reducedMotionEnabled = false;
        this.checkeredBackgroundEnabled = false;
        this.readableFontEnabled = false;
        this.dyslexiaFontEnabled = false;
        this.colorblindPaletteEnabled = false;
        this.hudFontScale = 1;
        this.impactEffects = [];
        this.turretRangeHighlightSlot = null;
        this.turretRangePreviewType = null;
        this.turretRangePreviewLevel = null;
        this.bestCombo = 0;
        this.playerSettings = createDefaultPlayerSettings();
        this.turretLoadoutPresets = Object.create(null);
        this.activeTurretPresetId = null;
        this.lastTurretSignature = "";
        this.tutorialHoldLoop = false;
        this.waveScorecardActive = false;
        this.resumeAfterWaveScorecard = false;
        this.optionsOverlayActive = false;
        this.resumeAfterOptions = false;
        this.menuActive = false;
        this.tutorialCompleted = false;
        this.pendingTutorialSummary = null;
        this.practiceMode = false;
        this.allTurretArchetypes = Object.create(null);
        this.enabledTurretTypes = new Set();
        this.featureToggles = { ...defaultConfig.featureToggles };
        this.debugCrystalToggle = null;
        this.debugDowngradeToggle = null;
        this.mainMenuCrystalToggle = null;
        const mergedTurretArchetypes = {
            ...defaultConfig.turretArchetypes,
            ...(options.config?.turretArchetypes ?? {})
        };
        const initialFeatureToggles = {
            ...defaultConfig.featureToggles,
            ...(options.config?.featureToggles ?? {})
        };
        this.featureToggles = { ...initialFeatureToggles };
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
        this.assetLoader = new AssetLoader();
        this.assetReady = false;
        this.assetStartPending = false;
        this.assetReadyPromise = Promise.resolve();
        this.assetLoaderUnsubscribe = this.assetLoader.onImageLoaded(() => {
            this.handleAssetImageLoaded();
        });
        const fallbackSprites = {
            "enemy-grunt": svgCircleDataUri("#f87171", "#fca5a5"),
            "enemy-runner": svgCircleDataUri("#34d399", "#6ee7b7"),
            "enemy-brute": svgCircleDataUri("#a78bfa", "#c4b5fd"),
            "enemy-witch": svgCircleDataUri("#fb7185", "#fda4af"),
            "turret-arrow": svgTurretDataUri("#38bdf8", "#0c4a6e"),
            "turret-arcane": svgTurretDataUri("#c084fc", "#581c87"),
            "turret-flame": svgTurretDataUri("#fb923c", "#9a3412"),
            "turret-crystal": svgTurretDataUri("#67e8f9", "#0f766e")
        };
        const manifestPromise = this.assetLoader
            .loadManifest("./assets/manifest.json")
            .then(() => {
            const missing = Object.keys(fallbackSprites).filter((key) => !this.assetLoader.getImage(key));
            if (missing.length > 0) {
                const subset = Object.fromEntries(missing.map((key) => [key, fallbackSprites[key]]));
                return this.assetLoader.loadImages(subset);
            }
            return undefined;
        })
            .catch((error) => {
            console.warn("Asset manifest load failed; using inline sprites.", error);
            return this.assetLoader.loadImages(fallbackSprites);
        });
        this.assetLoadPromise = manifestPromise.then(() => undefined);
        this.assetReadyPromise = manifestPromise
            .catch(() => undefined)
            .then(() => this.assetLoader.whenIdle())
            .then(() => {
            this.assetReady = true;
            if (this.assetLoaderUnsubscribe) {
                this.assetLoaderUnsubscribe();
                this.assetLoaderUnsubscribe = null;
            }
        });
        manifestPromise
            .then(() => this.render())
            .catch((error) => {
            console.warn("Asset load failed, continuing with procedural sprites.", error);
        });
        this.renderer = new CanvasRenderer(options.canvas, this.engine.config, this.assetLoader);
        this.attachCanvasResizeObserver();
        this.attachDevicePixelRatioListener();
        this.hud = new HudView(this.engine.config, {
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
                fontScaleSelect: "options-font-scale",
                telemetryToggle: "options-telemetry-toggle",
                telemetryToggleWrapper: "options-telemetry-toggle-wrapper",
                crystalPulseToggle: "options-crystal-toggle",
                crystalPulseToggleWrapper: "options-crystal-toggle-wrapper",
                analyticsExportButton: "options-analytics-export"
            },
            waveScorecard: {
                container: "wave-scorecard",
                stats: "wave-scorecard-stats",
                continue: "wave-scorecard-continue"
            }
        }, {
            onCastleUpgrade: () => this.handleCastleUpgrade(),
            onCastleRepair: () => this.handleCastleRepair(),
            onPlaceTurret: (slotId, typeId) => this.handlePlaceTurret(slotId, typeId),
            onUpgradeTurret: (slotId) => this.handleUpgradeTurret(slotId),
            onDowngradeTurret: (slotId) => this.handleDowngradeTurret(slotId),
            onTurretPriorityChange: (slotId, priority) => this.handleTurretPriorityChange(slotId, priority),
            onAnalyticsExport: this.analyticsExportEnabled ? () => this.exportAnalytics() : undefined,
            onTelemetryToggle: (enabled) => this.setTelemetryEnabled(enabled),
            onCrystalPulseToggle: (enabled) => this.setCrystalPulseEnabled(enabled),
            onPauseRequested: () => this.openOptionsOverlay(),
            onResumeRequested: () => this.closeOptionsOverlay(),
            onSoundToggle: (enabled) => this.setSoundEnabled(enabled),
            onSoundVolumeChange: (volume) => this.setSoundVolume(volume),
            onSoundIntensityChange: (value) => this.setAudioIntensity(value),
            onDiagnosticsToggle: (visible) => this.setDiagnosticsVisible(visible),
            onWaveScorecardContinue: () => this.handleWaveScorecardContinue(),
            onReducedMotionToggle: (enabled) => this.setReducedMotionEnabled(enabled),
            onCheckeredBackgroundToggle: (enabled) => this.setCheckeredBackgroundEnabled(enabled),
            onReadableFontToggle: (enabled) => this.setReadableFontEnabled(enabled),
            onDyslexiaFontToggle: (enabled) => this.setDyslexiaFontEnabled(enabled),
            onColorblindPaletteToggle: (enabled) => this.setColorblindPaletteEnabled(enabled),
            onHudFontScaleChange: (scale) => this.setHudFontScale(scale),
            onTurretPresetSave: (presetId) => this.handleTurretPresetSave(presetId),
            onTurretPresetApply: (presetId) => this.handleTurretPresetApply(presetId),
            onTurretPresetClear: (presetId) => this.handleTurretPresetClear(presetId),
            onTurretHover: (slotId, context) => this.handleTurretHover(slotId, context)
        });
        this.updateHudTurretAvailability();
        this.hud.setTurretDowngradeEnabled(Boolean(this.featureToggles?.turretDowngrade));
        this.debugApi = new DebugApi(this);
        this.debugApi.expose();
        this.manualTick = Boolean(options.manualTick);
        this.currentState = this.engine.getState();
        const diagnosticsContainer = document.getElementById("diagnostics-overlay");
        if (!diagnosticsContainer) {
            throw new Error("Diagnostics overlay container missing from DOM.");
        }
        this.diagnostics = new DiagnosticsOverlay(diagnosticsContainer);
        if (typeof window !== "undefined" && "AudioContext" in window) {
            this.soundManager = new SoundManager();
            this.soundManager.setVolume(this.soundVolume);
            this.soundManager.setIntensity(this.audioIntensity);
        }
        this.initializePlayerSettings();
        this.hud.setAnalyticsExportEnabled(this.analyticsExportEnabled);
        this.attachInputHandlers(options.typingInput);
        this.attachDebugButtons();
        this.attachGlobalShortcuts();
        this.registerHudListeners();
        if (config.featureToggles.tutorials) {
            const shouldSkipTutorial = this.shouldSkipTutorial();
            this.tutorialCompleted = shouldSkipTutorial;
            this.tutorialManager = new TutorialManager({
                engine: this.engine,
                hud: this.hud,
                pauseGame: () => this.pauseForTutorial(),
                resumeGame: () => this.resumeFromTutorial(),
                collectSummaryMetrics: () => this.collectTutorialSummary(),
                onRequestWrapUp: (summary) => this.presentTutorialSummary(summary),
                onComplete: () => {
                    console.info("[tutorial] Completed");
                }
            });
            this.initializeMainMenu(shouldSkipTutorial);
        }
        else {
            this.tutorialCompleted = true;
        }
        this.render();
    }
    initializeMainMenu(shouldSkipTutorial) {
        const overlay = document.getElementById("main-menu-overlay");
        const copy = document.getElementById("main-menu-copy");
        const startBtn = document.getElementById("main-menu-start-tutorial");
        const skipBtn = document.getElementById("main-menu-skip-tutorial");
        const replayBtn = document.getElementById("main-menu-replay-tutorial");
        const practiceBtn = document.getElementById("main-menu-practice-mode");
        const telemetryWrapper = document.getElementById("main-menu-telemetry-toggle-wrapper");
        const telemetryToggle = document.getElementById("main-menu-telemetry-toggle");
        const crystalWrapper = document.getElementById("main-menu-crystal-toggle-wrapper");
        const crystalToggle = document.getElementById("main-menu-crystal-toggle");
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
        this.pause();
        this.menuActive = true;
        overlay.dataset.visible = "true";
        this.syncCrystalPulseControls();
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
            });
        }
        else {
            this.soundManager?.setEnabled(false);
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
    setReducedMotionEnabled(enabled, options = {}) {
        this.reducedMotionEnabled = enabled;
        this.applyReducedMotionSetting(enabled);
        if (!options.silent) {
            this.hud.appendLog(`Reduced motion ${enabled ? "enabled" : "disabled"}`);
        }
        this.updateOptionsOverlayState();
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
    setColorblindPaletteEnabled(enabled, options = {}) {
        this.colorblindPaletteEnabled = enabled;
        this.applyColorblindPaletteSetting(enabled);
        if (!options.silent) {
            this.hud.appendLog(`Colorblind palette ${enabled ? "enabled" : "disabled"}`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false) {
            this.persistPlayerSettings({ colorblindPaletteEnabled: enabled });
        }
        if (options.render !== false) {
            this.render();
        }
    }
    setHudFontScale(scale, options = {}) {
        const normalized = this.normalizeHudFontScale(scale);
        const changed = Math.abs(normalized - this.hudFontScale) > 0.001;
        this.hudFontScale = normalized;
        this.applyHudFontScaleSetting(normalized);
        if (changed && !options.silent) {
            const percent = Math.round(normalized * 100);
            this.hud.appendLog(`HUD font size set to ${percent}%`);
        }
        this.updateOptionsOverlayState();
        if (options.persist !== false && changed) {
            this.persistPlayerSettings({ hudFontScale: normalized });
        }
        if (options.render !== false && changed) {
            this.render();
        }
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
    normalizeHudFontScale(value) {
        if (!Number.isFinite(value)) {
            return 1;
        }
        const clamped = Math.min(HUD_FONT_SCALE_MAX, Math.max(HUD_FONT_SCALE_MIN, value));
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
    updateOptionsOverlayState() {
        if (!this.diagnostics)
            return;
        this.hud.syncOptionsOverlayState({
            soundEnabled: this.soundEnabled,
            soundVolume: this.soundVolume,
            soundIntensity: this.audioIntensity,
            diagnosticsVisible: this.diagnostics.isVisible(),
            reducedMotionEnabled: this.reducedMotionEnabled,
            checkeredBackgroundEnabled: this.checkeredBackgroundEnabled,
            readableFontEnabled: this.readableFontEnabled,
            dyslexiaFontEnabled: this.dyslexiaFontEnabled,
            colorblindPaletteEnabled: this.colorblindPaletteEnabled,
            hudFontScale: this.hudFontScale,
            telemetry: {
                available: Boolean(this.telemetryClient),
                checked: Boolean(this.telemetryClient ? this.telemetryEnabled : false),
                disabled: !this.telemetryClient
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
        if (typeof document === "undefined")
            return;
        const root = document.documentElement;
        if (root) {
            root.dataset.reducedMotion = enabled ? "true" : "false";
        }
        const body = document.body;
        if (body) {
            body.dataset.reducedMotion = enabled ? "true" : "false";
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
    applyColorblindPaletteSetting(enabled) {
        if (typeof document === "undefined")
            return;
        const root = document.documentElement;
        if (root) {
            root.dataset.colorblindPalette = enabled ? "true" : "false";
        }
        const body = document.body;
        if (body) {
            body.dataset.colorblindPalette = enabled ? "true" : "false";
        }
    }
    applyHudFontScaleSetting(scale) {
        this.hud.setHudFontScale(scale);
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
            controls.flushButton.disabled = !enabled || queueLength === 0;
            controls.flushButton.textContent = `Flush Telemetry (${queueLength})`;
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
        if (this.optionsOverlayActive || this.menuActive || this.waveScorecardActive) {
            return;
        }
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
    presentWaveScorecard(summary) {
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
            sessionBestCombo: summary.sessionBestCombo ?? this.bestCombo
        };
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
            waveTotal: Array.isArray(this.engine.config?.waves) ? this.engine.config.waves.length : 0,
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
            sessionBestCombo: summary.sessionBestCombo ?? defaultSummary.sessionBestCombo ?? this.bestCombo
        };
        this.hud.showWaveScorecard({
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
            sessionBestCombo: payload.sessionBestCombo ?? this.bestCombo
        });
    }
    debugHideWaveScorecard() {
        this.hud.hideWaveScorecard();
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
        this.hud.hideWaveScorecard();
        const shouldResume = options.resume !== false &&
            this.resumeAfterWaveScorecard &&
            !this.manualTick &&
            !this.menuActive &&
            !this.optionsOverlayActive &&
            !this.tutorialHoldLoop;
        this.resumeAfterWaveScorecard = false;
        if (shouldResume) {
            this.resume();
        }
    }
    persistPlayerSettings(patch) {
        const soundUnchanged = patch.soundEnabled === undefined || patch.soundEnabled === this.playerSettings.soundEnabled;
        const soundVolumeUnchanged = patch.soundVolume === undefined ||
            Math.abs(this.normalizeSoundVolume(patch.soundVolume) - this.playerSettings.soundVolume) <=
                0.001;
        const soundIntensityUnchanged = patch.audioIntensity === undefined ||
            Math.abs(this.normalizeAudioIntensity(patch.audioIntensity) - this.playerSettings.audioIntensity) <= 0.001;
        const diagnosticsUnchanged = patch.diagnosticsVisible === undefined ||
            patch.diagnosticsVisible === this.playerSettings.diagnosticsVisible;
        const reducedMotionUnchanged = patch.reducedMotionEnabled === undefined ||
            patch.reducedMotionEnabled === this.playerSettings.reducedMotionEnabled;
        const checkeredUnchanged = patch.checkeredBackgroundEnabled === undefined ||
            patch.checkeredBackgroundEnabled === this.playerSettings.checkeredBackgroundEnabled;
        const readableFontUnchanged = patch.readableFontEnabled === undefined ||
            patch.readableFontEnabled === this.playerSettings.readableFontEnabled;
        const dyslexiaFontUnchanged = patch.dyslexiaFontEnabled === undefined ||
            patch.dyslexiaFontEnabled === this.playerSettings.dyslexiaFontEnabled;
        const colorblindUnchanged = patch.colorblindPaletteEnabled === undefined ||
            patch.colorblindPaletteEnabled === this.playerSettings.colorblindPaletteEnabled;
        const fontScaleUnchanged = patch.hudFontScale === undefined ||
            Math.abs(this.normalizeHudFontScale(patch.hudFontScale) - this.playerSettings.hudFontScale) <=
                0.001;
        const targetingUnchanged = patch.turretTargeting === undefined ||
            this.areTargetingMapsEqual(this.playerSettings.turretTargeting, patch.turretTargeting);
        const presetsUnchanged = patch.turretLoadoutPresets === undefined ||
            this.areTurretPresetMapsEqual(this.playerSettings.turretLoadoutPresets, patch.turretLoadoutPresets);
        const telemetryUnchanged = patch.telemetryEnabled === undefined ||
            patch.telemetryEnabled === this.playerSettings.telemetryEnabled;
        if (soundUnchanged &&
            soundVolumeUnchanged &&
            soundIntensityUnchanged &&
            diagnosticsUnchanged &&
            reducedMotionUnchanged &&
            checkeredUnchanged &&
            readableFontUnchanged &&
            dyslexiaFontUnchanged &&
            colorblindUnchanged &&
            fontScaleUnchanged &&
            targetingUnchanged &&
            presetsUnchanged &&
            telemetryUnchanged) {
            return;
        }
        const next = withPatchedPlayerSettings(this.playerSettings, patch);
        this.playerSettings = next;
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
        var _a, _b, _c;
        const hudState = (_a = this.hud) == null ? void 0 : _a.getCondensedState?.();
        const diagnosticsState = (_b = this.diagnostics) == null ? void 0 : _b.getCondensedState?.();
        const preferences = {
            hudPassivesCollapsed: typeof ((_c = this.playerSettings) == null ? void 0 : _c.hudPassivesCollapsed) === "boolean"
                ? this.playerSettings.hudPassivesCollapsed
                : null,
            hudGoldEventsCollapsed: typeof this.playerSettings?.hudGoldEventsCollapsed === "boolean"
                ? this.playerSettings.hudGoldEventsCollapsed
                : null,
            optionsPassivesCollapsed: typeof this.playerSettings?.optionsPassivesCollapsed === "boolean"
                ? this.playerSettings.optionsPassivesCollapsed
                : null
        };
        return {
            compactHeight: hudState?.compactHeight ?? null,
            tutorialBanner: {
                condensed: hudState?.tutorialBannerCondensed ?? false,
                expanded: hudState?.tutorialBannerExpanded ?? false
            },
            hud: {
                passivesCollapsed: hudState?.hudCastlePassivesCollapsed ?? null,
                goldEventsCollapsed: hudState?.hudGoldEventsCollapsed ?? null,
                prefersCondensedLists: hudState?.prefersCondensedLists ?? null
            },
            options: {
                passivesCollapsed: hudState?.optionsPassivesCollapsed ?? null
            },
            diagnostics: {
                condensed: diagnosticsState?.condensed ?? null,
                sectionsCollapsed: diagnosticsState?.sectionsCollapsed ?? null
            },
            preferences
        };
    }
    resetAnalytics() {
        this.engine.resetAnalytics();
        this.currentState = this.engine.getState();
        this.impactEffects = [];
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
        const deltaSeconds = ((timestamp - this.lastTimestamp) / 1000) * this.speedMultiplier;
        this.lastTimestamp = timestamp;
        this.tutorialManager?.update(deltaSeconds);
        this.engine.update(deltaSeconds);
        this.render();
        this.rafId = requestAnimationFrame((time) => this.tick(time));
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
    render() {
        this.currentState = this.engine.getState();
        const turretSignature = this.computeTurretSignature(this.currentState);
        if (turretSignature !== this.lastTurretSignature) {
            this.lastTurretSignature = turretSignature;
            this.syncTurretPresetsToHud(this.currentState);
        }
        const impactRenders = this.collectImpactEffects();
        const turretRange = this.buildTurretRangeRenderOptions();
        this.renderer.render(this.currentState, impactRenders, {
            reducedMotion: this.reducedMotionEnabled,
            checkeredBackground: this.checkeredBackgroundEnabled,
            turretRange
        });
        const upcoming = this.engine.getUpcomingSpawns();
        this.hud.update(this.currentState, upcoming, {
            colorBlindFriendly: this.colorblindPaletteEnabled || this.checkeredBackgroundEnabled
        });
        const shieldForecast = this.hud.getShieldForecast();
        this.bestCombo = Math.max(this.bestCombo, this.currentState.typing.combo);
        const analytics = this.currentState.analytics;
        const summaries = analytics.waveHistory && analytics.waveHistory.length > 0
            ? analytics.waveHistory
            : analytics.waveSummaries;
        this.diagnostics.update(this.engine.getRuntimeMetrics(), {
            bestCombo: this.bestCombo,
            breaches: analytics.sessionBreaches,
            soundEnabled: this.soundEnabled,
            soundVolume: this.soundVolume,
            soundIntensity: this.audioIntensity,
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
            lastSummary: summaries.length > 0 ? summaries[summaries.length - 1] : undefined
        });
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
    handleAssetImageLoaded() {
        if (!this.renderer) {
            return;
        }
        this.render();
    }
    async waitForAssets() {
        await this.assetReadyPromise;
    }
    attachInputHandlers(typingInput) {
        const handler = (event) => {
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
                    this.render();
                }
                return;
            }
            if (event.key.length === 1 && /^[a-zA-Z]$/.test(event.key)) {
                const result = this.engine.inputCharacter(event.key);
                if (result.status !== "ignored") {
                    event.preventDefault();
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
        typingInput.addEventListener("focus", () => {
            typingInput.select();
        });
        this.hud.focusTypingInput();
    }
    attachGlobalShortcuts() {
        if (typeof window === "undefined")
            return;
        const handler = (event) => {
            if (this.hud.isWaveScorecardVisible()) {
                if (event.key === "Escape" || event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    this.handleWaveScorecardContinue();
                }
                return;
            }
            if (event.key === "Escape") {
                if (this.hud.isOptionsOverlayVisible()) {
                    event.preventDefault();
                    this.closeOptionsOverlay();
                    return;
                }
                if (this.hud.isShortcutOverlayVisible()) {
                    event.preventDefault();
                    this.hud.hideShortcutOverlay();
                }
                return;
            }
            if (this.hud.isOptionsOverlayVisible()) {
                return;
            }
            if (event.key === "?" || (event.key === "/" && event.shiftKey)) {
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
            switch (key) {
                case "d":
                    event.preventDefault();
                    this.toggleDiagnostics();
                    break;
                case "m":
                    event.preventDefault();
                    this.toggleSound();
                    break;
                case "p":
                    event.preventDefault();
                    this.togglePause();
                    break;
                default:
                    break;
            }
        };
        window.addEventListener("keydown", handler);
    }
    initializePlayerSettings() {
        if (typeof window === "undefined") {
            this.playerSettings = createDefaultPlayerSettings();
            return;
        }
        const stored = loadPlayerSettingsFromStorage(window.localStorage);
        this.playerSettings = stored;
        this.setCrystalPulseEnabled(stored.crystalPulseEnabled ?? false, {
            persist: false,
            silent: true
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
        this.setCheckeredBackgroundEnabled(stored.checkeredBackgroundEnabled, {
            silent: true,
            persist: false,
            render: false
        });
        this.setColorblindPaletteEnabled(stored.colorblindPaletteEnabled ?? false, {
            silent: true,
            persist: false,
            render: false
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
        const analyticsViewerToggle = document.getElementById("debug-analytics-viewer-toggle");
        const tutorialReplay = document.getElementById("debug-tutorial-replay");
        const telemetryControlsContainer = document.getElementById("debug-telemetry-controls");
        const telemetryToggle = document.getElementById("debug-telemetry-toggle");
        const telemetryFlush = document.getElementById("debug-telemetry-flush");
        const telemetryDownload = document.getElementById("debug-telemetry-download");
        const telemetryEndpointInput = document.getElementById("debug-telemetry-endpoint");
        const telemetryEndpointApply = document.getElementById("debug-telemetry-endpoint-apply");
        const crystalToggleButton = document.getElementById("debug-crystal-toggle");
        const downgradeToggleButton = document.getElementById("debug-turret-downgrade");
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
        if (downgradeToggleButton instanceof HTMLButtonElement) {
            this.debugDowngradeToggle = downgradeToggleButton;
            downgradeToggleButton.addEventListener("click", () => this.setTurretDowngradeEnabled(!this.featureToggles.turretDowngrade));
        }
        else {
            this.debugDowngradeToggle = null;
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
            accuracy: typeof summary.accuracy === "number" ? summary.accuracy : (state.typing?.accuracy ?? 0),
            bestCombo: typeof summary.bestCombo === "number"
                ? summary.bestCombo
                : Math.max(this.bestCombo, state.typing?.combo ?? 0),
            breaches: typeof summary.breaches === "number"
                ? summary.breaches
                : state.analytics?.sessionBreaches ?? 0,
            gold: typeof summary.gold === "number" ? summary.gold : Math.round(state.resources?.gold ?? 0)
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
            this.bestCombo = 0;
            this.impactEffects = [];
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
    startPracticeMode() {
        this.setPracticeMode(true);
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
        this.bestCombo = 0;
        this.impactEffects = [];
        this.currentState = this.engine.getState();
        this.hud.appendLog("Practice mode engaged: waves now loop endlessly.");
        this.render();
        this.start();
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
        this.engine.events.on("enemy:defeated", ({ enemy, by, reward }) => {
            const source = by === "typing" ? "typed" : "turret";
            this.hud.appendLog(`Defeated ${enemy.word} (${source}) ${toGold(reward)}`);
            this.playSound(by === "typing" ? "impact-hit" : "projectile-arrow");
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
            this.hud.appendLog(`Enemy breached gates! -${enemy.damage} HP`);
            this.playSound("impact-breach");
            this.addImpactEffect(enemy.lane, 1, "breach");
            this.tutorialManager?.notify({ type: "castle:breach" });
        });
        this.engine.events.on("castle:damaged", ({ amount, health }) => {
            this.hud.appendLog(`Castle hit for ${amount} (HP ${Math.ceil(health)})`);
        });
        this.engine.events.on("castle:upgraded", ({ level }) => {
            this.hud.appendLog(`Castle upgraded to level ${level}`);
            this.playSound("upgrade");
        });
        this.engine.events.on("castle:passive-unlocked", ({ passive }) => {
            const description = this.describeCastlePassive(passive);
            this.hud.appendLog(`Passive unlocked: ${description}`);
            this.hud.showCastleMessage(description);
            this.playSound("upgrade", 48);
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
            this.hud.appendLog(`Castle repaired${detail}`);
            this.playSound("upgrade", 24);
        });
        this.engine.events.on("turret:placed", (slot) => {
            this.hud.appendLog(`Turret deployed in ${slot.id.toUpperCase()} (${slot.turret?.typeId ?? "unknown"})`);
            this.playSound("upgrade", 80);
        });
        this.engine.events.on("turret:upgraded", (slot) => {
            const turret = slot.turret;
            if (turret) {
                this.hud.appendLog(`Turret ${slot.id.toUpperCase()} -> Lv.${turret.level}`);
                this.playSound("upgrade", 120);
            }
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
        this.engine.events.on("typing:perfect-word", ({ word }) => {
            this.hud.appendLog(`Perfect word: ${word.toUpperCase()}!`);
        });
        this.engine.events.on("wave:bonus", ({ waveIndex, count, gold }) => {
            const bonusMessage = `Wave ${waveIndex + 1} bonus: ${count} perfect words (+${gold}g)`;
            this.hud.appendLog(bonusMessage);
            this.hud.showCastleMessage(`Bonus +${gold}g for ${count} perfect words!`);
        });
        this.engine.events.on("analytics:wave-summary", (summary) => {
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
            this.presentWaveScorecard(summary);
        });
        this.engine.events.on("typing:error", ({ enemyId, expected, received, totalErrors }) => {
            if (this.tutorialManager?.getState().active) {
                this.tutorialManager.notify({
                    type: "typing:error",
                    payload: { enemyId: enemyId ?? null, expected: expected ?? null, received, totalErrors }
                });
            }
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
    playSound(key, detune = 0) {
        if (!this.soundManager)
            return;
        void this.soundManager.ensureInitialized().then(() => {
            this.soundManager?.play(key, detune);
        });
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
            this.canvasResizeObserver = new ResizeObserver(() => this.updateCanvasResolution());
            this.canvasResizeObserver.observe(target);
        }
        else {
            this.viewportResizeHandler = () => this.updateCanvasResolution();
            window.addEventListener("resize", this.viewportResizeHandler);
        }
    }
    attachDevicePixelRatioListener() {
        if (typeof window === "undefined" || typeof window.matchMedia !== "function") {
            return;
        }
        this.detachDevicePixelRatioListener();
        const ratio = typeof window.devicePixelRatio === "number" && window.devicePixelRatio > 0
            ? window.devicePixelRatio
            : 1;
        let query;
        try {
            query = window.matchMedia(`(resolution: ${ratio}dppx)`);
        }
        catch {
            return;
        }
        const handler = () => {
            this.detachDevicePixelRatioListener();
            this.updateCanvasResolution(true);
            this.attachDevicePixelRatioListener();
        };
        if (typeof query.addEventListener === "function") {
            query.addEventListener("change", handler);
        }
        else if (typeof query.addListener === "function") {
            query.addListener(handler);
        }
        this.dprMediaQuery = { query, handler };
    }
    detachDevicePixelRatioListener() {
        if (!this.dprMediaQuery) {
            return;
        }
        const { query, handler } = this.dprMediaQuery;
        try {
            if (typeof query.removeEventListener === "function") {
                query.removeEventListener("change", handler);
            }
            else if (typeof query.removeListener === "function") {
                query.removeListener(handler);
            }
        }
        catch {
            // ignore
        }
        this.dprMediaQuery = null;
    }
    updateCanvasResolution(force = false) {
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
        this.canvasResolution = resolution;
        this.canvas.width = resolution.renderWidth;
        this.canvas.height = resolution.renderHeight;
        this.canvas.style.width = `${resolution.cssWidth}px`;
        this.canvas.style.height = `${resolution.cssHeight}px`;
        if (this.renderer?.resize) {
            this.renderer.resize(resolution.renderWidth, resolution.renderHeight);
        }
        this.triggerCanvasResizeFade();
    }
    computeCanvasResolution() {
        const availableWidth = this.measureCanvasAvailableWidth();
        if (!availableWidth || !Number.isFinite(availableWidth)) {
            return {
                cssWidth: CANVAS_BASE_WIDTH,
                cssHeight: CANVAS_BASE_HEIGHT,
                renderWidth: CANVAS_BASE_WIDTH,
                renderHeight: CANVAS_BASE_HEIGHT
            };
        }
        const devicePixelRatio = typeof window !== "undefined" && typeof window.devicePixelRatio === "number"
            ? window.devicePixelRatio
            : 1;
        return calculateCanvasResolution({
            baseWidth: CANVAS_BASE_WIDTH,
            baseHeight: CANVAS_BASE_HEIGHT,
            availableWidth,
            devicePixelRatio
        });
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
    triggerCanvasResizeFade() {
        if (typeof window === "undefined" || !this.canvas) {
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
        }, 220);
    }
}
