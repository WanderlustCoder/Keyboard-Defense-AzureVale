import { WavePreviewPanel } from "./wavePreview.js";
let hudInstanceCounter = 0;
const isElementWithTag = (el, tagName) => {
    return el instanceof HTMLElement && el.tagName.toLowerCase() === tagName.toLowerCase();
};
const DEFAULT_WAVE_PREVIEW_HINT = "Upcoming enemies appear here—use the preview to plan your defenses.";
export class HudView {
    config;
    callbacks;
    healthBar;
    goldLabel;
    goldDelta;
    activeWord;
    typingInput;
    upgradePanel;
    comboLabel;
    comboAccuracyDelta;
    logList;
    tutorialBanner;
    tutorialBannerExpanded = true;
    castleButton;
    castleRepairButton;
    castleStatus;
    castleBenefits;
    castleGoldEvents;
    castlePassives;
    castlePassivesSection;
    castleGoldEventsSection;
    wavePreview;
    slotControls = new Map();
    presetControls = new Map();
    presetContainer = null;
    presetList = null;
    analyticsViewer;
    analyticsViewerVisible = false;
    analyticsViewerSignature = "";
    analyticsViewerFilter = "all";
    analyticsViewerFilterSelect;
    lastShieldTelemetry = { current: false, next: false };
    lastGold = 0;
    maxCombo = 0;
    goldTimeout = null;
    logEntries = [];
    logLimit = 6;
    tutorialSlotLock = null;
    lastState = null;
    availableTurretTypes = {};
    turretDowngradeEnabled = false;
    tutorialSummary;
    tutorialSummaryHandlers = null;
    shortcutLaunchButton;
    shortcutOverlay;
    optionsCastleBonus;
    optionsCastleBenefits;
    optionsCastlePassives;
    optionsPassivesSection;
    optionsPassivesSummary;
    optionsPassivesToggle;
    optionsPassivesBody;
    optionsPassivesCollapsed = false;
    optionsPassivesDefaultCollapsed = false;
    wavePreviewHint;
    wavePreviewHintMessage = DEFAULT_WAVE_PREVIEW_HINT;
    optionsOverlay;
    waveScorecard;
    syncingOptionToggles = false;
    comboBaselineAccuracy = 1;
    lastAccuracy = 1;
    constructor(config, rootIds, callbacks) {
        this.config = config;
        this.callbacks = callbacks;
        this.healthBar = this.getElement(rootIds.healthBar);
        this.goldLabel = this.getElement(rootIds.goldLabel);
        this.goldDelta = this.getElement(rootIds.goldDelta);
        this.activeWord = this.getElement(rootIds.activeWord);
        this.typingInput = this.getElement(rootIds.typingInput);
        this.upgradePanel = this.getElement(rootIds.upgradePanel);
        this.comboLabel = this.getElement(rootIds.comboLabel);
        this.comboAccuracyDelta = this.getElement(rootIds.comboAccuracyDelta);
        this.hideComboAccuracyDelta();
        this.logList = this.getElement(rootIds.eventLog);
        const previewContainer = this.getElement(rootIds.wavePreview);
        this.wavePreview = new WavePreviewPanel(previewContainer, this.config);
        if (rootIds.wavePreviewHint) {
            const hintElement = document.getElementById(rootIds.wavePreviewHint);
            if (hintElement instanceof HTMLElement) {
                this.wavePreviewHint = hintElement;
                this.wavePreviewHint.dataset.visible = this.wavePreviewHint.dataset.visible ?? "false";
                this.wavePreviewHint.setAttribute("aria-hidden", "true");
                this.wavePreviewHint.textContent = "";
            }
            else {
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
        this.availableTurretTypes = Object.fromEntries(Object.keys(this.config.turretArchetypes).map((typeId) => [typeId, true]));
        const tutorialBannerElement = document.getElementById(rootIds.tutorialBanner);
        if (tutorialBannerElement instanceof HTMLElement) {
            const messageElement = tutorialBannerElement.querySelector("[data-role='tutorial-message']");
            const resolvedMessage = messageElement ?? tutorialBannerElement;
            const toggleElement = tutorialBannerElement.querySelector("[data-role='tutorial-toggle']");
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
                message: resolvedMessage,
                toggle: toggleElement ?? undefined
            };
        }
        else {
            this.tutorialBanner = undefined;
        }
        const summaryContainer = document.getElementById(rootIds.tutorialSummary.container) ?? undefined;
        const summaryStats = document.getElementById(rootIds.tutorialSummary.stats);
        const summaryContinue = document.getElementById(rootIds.tutorialSummary.continue);
        const summaryReplay = document.getElementById(rootIds.tutorialSummary.replay);
        if (summaryContainer && summaryStats && summaryContinue && summaryReplay) {
            this.tutorialSummary = {
                container: summaryContainer,
                statsList: summaryStats,
                continueBtn: summaryContinue,
                replayBtn: summaryReplay
            };
        }
        else {
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
            }
            else {
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
            }
            else {
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
            const soundIntensitySlider = document.getElementById(rootIds.optionsOverlay.soundIntensitySlider);
            const soundIntensityValue = document.getElementById(rootIds.optionsOverlay.soundIntensityValue);
            const diagnosticsToggle = document.getElementById(rootIds.optionsOverlay.diagnosticsToggle);
            const reducedMotionToggle = document.getElementById(rootIds.optionsOverlay.reducedMotionToggle);
            const checkeredBackgroundToggle = document.getElementById(rootIds.optionsOverlay.checkeredBackgroundToggle);
            const readableFontToggle = document.getElementById(rootIds.optionsOverlay.readableFontToggle);
            const dyslexiaFontToggle = document.getElementById(rootIds.optionsOverlay.dyslexiaFontToggle);
            const colorblindPaletteToggle = document.getElementById(rootIds.optionsOverlay.colorblindPaletteToggle);
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
            if (optionsContainer instanceof HTMLElement &&
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
                fontScaleSelect instanceof HTMLSelectElement) {
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
                    reducedMotionToggle,
                    checkeredBackgroundToggle,
                    readableFontToggle,
                    dyslexiaFontToggle,
                    colorblindPaletteToggle,
                    fontScaleSelect,
                    telemetryToggle: telemetryToggle instanceof HTMLInputElement ? telemetryToggle : undefined,
                    telemetryWrapper: telemetryToggleWrapper instanceof HTMLElement ? telemetryToggleWrapper : undefined,
                    crystalPulseToggle: crystalPulseToggle instanceof HTMLInputElement ? crystalPulseToggle : undefined,
                    crystalPulseWrapper: crystalPulseToggleWrapper instanceof HTMLElement
                        ? crystalPulseToggleWrapper
                        : undefined,
                    analyticsExportButton: analyticsExportButton instanceof HTMLButtonElement ? analyticsExportButton : undefined
                };
                const castleBonusHint = document.getElementById("options-castle-bonus");
                if (castleBonusHint instanceof HTMLElement) {
                    this.optionsCastleBonus = castleBonusHint;
                    this.optionsCastleBonus.textContent = "";
                }
                else {
                    console.warn("Options castle bonus element missing; bonus hint disabled.");
                }
                const castleBenefitsList = document.getElementById("options-castle-benefits");
                if (isElementWithTag(castleBenefitsList, "ul")) {
                    this.optionsCastleBenefits = castleBenefitsList;
                    this.optionsCastleBenefits.replaceChildren();
                }
                else {
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
                if (isElementWithTag(castlePassivesList, "ul")) {
                    this.optionsCastlePassives = castlePassivesList;
                    this.optionsCastlePassives.replaceChildren();
                    this.updateOptionsPassivesSummary("No passives");
                    this.setOptionsPassivesCollapsed(this.optionsPassivesCollapsed, { silent: true });
                }
                else {
                    console.warn("Options castle passives element missing; passive summary disabled.");
                }
                closeButton.addEventListener("click", () => this.callbacks.onResumeRequested());
                resumeButton.addEventListener("click", () => this.callbacks.onResumeRequested());
                soundToggle.addEventListener("change", () => {
                    if (this.syncingOptionToggles)
                        return;
                    this.callbacks.onSoundToggle(soundToggle.checked);
                });
                soundVolumeSlider.addEventListener("input", () => {
                    if (this.syncingOptionToggles)
                        return;
                    const nextValue = Number.parseFloat(soundVolumeSlider.value);
                    if (!Number.isFinite(nextValue))
                        return;
                    this.updateSoundVolumeDisplay(nextValue);
                    this.callbacks.onSoundVolumeChange(nextValue);
                });
                soundIntensitySlider.addEventListener("input", () => {
                    if (this.syncingOptionToggles)
                        return;
                    const nextValue = Number.parseFloat(soundIntensitySlider.value);
                    if (!Number.isFinite(nextValue))
                        return;
                    this.updateSoundIntensityDisplay(nextValue);
                    this.callbacks.onSoundIntensityChange(nextValue);
                });
                diagnosticsToggle.addEventListener("change", () => {
                    if (this.syncingOptionToggles)
                        return;
                    this.callbacks.onDiagnosticsToggle(diagnosticsToggle.checked);
                });
                reducedMotionToggle.addEventListener("change", () => {
                    if (this.syncingOptionToggles)
                        return;
                    this.callbacks.onReducedMotionToggle(reducedMotionToggle.checked);
                });
                checkeredBackgroundToggle.addEventListener("change", () => {
                    if (this.syncingOptionToggles)
                        return;
                    this.callbacks.onCheckeredBackgroundToggle(checkeredBackgroundToggle.checked);
                });
                readableFontToggle.addEventListener("change", () => {
                    if (this.syncingOptionToggles)
                        return;
                    this.callbacks.onReadableFontToggle(readableFontToggle.checked);
                });
                dyslexiaFontToggle.addEventListener("change", () => {
                    if (this.syncingOptionToggles)
                        return;
                    this.callbacks.onDyslexiaFontToggle(dyslexiaFontToggle.checked);
                });
                colorblindPaletteToggle.addEventListener("change", () => {
                    if (this.syncingOptionToggles)
                        return;
                    this.callbacks.onColorblindPaletteToggle(colorblindPaletteToggle.checked);
                });
                fontScaleSelect.addEventListener("change", () => {
                    if (this.syncingOptionToggles)
                        return;
                    const rawValue = this.getSelectValue(fontScaleSelect);
                    const nextValue = Number.parseFloat(rawValue ?? "");
                    if (!Number.isFinite(nextValue))
                        return;
                    this.callbacks.onHudFontScaleChange(nextValue);
                });
                if (this.optionsOverlay.telemetryToggle) {
                    this.optionsOverlay.telemetryToggle.addEventListener("change", () => {
                        if (this.syncingOptionToggles)
                            return;
                        this.callbacks.onTelemetryToggle?.(this.optionsOverlay.telemetryToggle.checked);
                    });
                }
                if (this.optionsOverlay.crystalPulseToggle) {
                    this.optionsOverlay.crystalPulseToggle.addEventListener("change", () => {
                        if (this.syncingOptionToggles)
                            return;
                        this.callbacks.onCrystalPulseToggle?.(this.optionsOverlay.crystalPulseToggle.checked);
                    });
                }
                if (this.optionsOverlay.analyticsExportButton) {
                    this.optionsOverlay.analyticsExportButton.addEventListener("click", () => {
                        this.callbacks.onAnalyticsExport?.();
                    });
                }
            }
            else {
                console.warn("Options overlay elements missing; pause overlay disabled.");
            }
        }
        if (rootIds.waveScorecard) {
            const scorecardContainer = document.getElementById(rootIds.waveScorecard.container);
            const scorecardStats = document.getElementById(rootIds.waveScorecard.stats);
            const scorecardContinue = document.getElementById(rootIds.waveScorecard.continue);
            if (scorecardContainer instanceof HTMLElement &&
                isElementWithTag(scorecardStats, "ul") &&
                scorecardContinue instanceof HTMLButtonElement) {
                this.waveScorecard = {
                    container: scorecardContainer,
                    statsList: scorecardStats,
                    continueBtn: scorecardContinue
                };
                scorecardContinue.addEventListener("click", () => this.callbacks.onWaveScorecardContinue());
            }
            else {
                console.warn("Wave scorecard elements missing; wave summary overlay disabled.");
            }
        }
        if (rootIds.analyticsViewer) {
            const viewerContainer = document.getElementById(rootIds.analyticsViewer.container);
            const viewerBody = document.getElementById(rootIds.analyticsViewer.tableBody);
            const viewerFilter = rootIds.analyticsViewer.filterSelect
                ? document.getElementById(rootIds.analyticsViewer.filterSelect)
                : null;
            if (viewerContainer instanceof HTMLElement &&
                isElementWithTag(viewerBody, "tbody")) {
                this.analyticsViewer = {
                    container: viewerContainer,
                    tableBody: viewerBody,
                    filterSelect: viewerFilter instanceof HTMLSelectElement ? viewerFilter : undefined
                };
                this.analyticsViewerVisible = viewerContainer.dataset.visible === "true";
                viewerContainer.setAttribute("aria-hidden", this.analyticsViewerVisible ? "false" : "true");
                if (this.analyticsViewer.filterSelect) {
                    this.analyticsViewerFilterSelect = this.analyticsViewer.filterSelect;
                    this.setSelectValue(this.analyticsViewerFilterSelect, this.analyticsViewerFilter);
                    this.analyticsViewerFilterSelect.addEventListener("change", () => {
                        const next = this.normalizeAnalyticsViewerFilter(this.getSelectValue(this.analyticsViewerFilterSelect) ?? "all");
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
                        }
                        else if (this.analyticsViewerFilterSelect) {
                            this.setSelectValue(this.analyticsViewerFilterSelect, this.analyticsViewerFilter);
                        }
                    });
                }
            }
            else {
                console.warn("Analytics viewer elements missing; debug analytics viewer disabled.");
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
        this.castlePassivesSection = this.createCondensedSection({
            title: "Castle passives",
            listClass: "castle-passives",
            ariaLabel: "Active castle passive buffs",
            collapsedByDefault: prefersCondensedLists
        }, "hud-passives");
        this.castlePassives = this.castlePassivesSection.list;
        this.castleGoldEventsSection = this.createCondensedSection({
            title: "Recent gold events",
            listClass: "castle-gold-events",
            ariaLabel: "Recent gold events",
            collapsedByDefault: prefersCondensedLists
        }, "hud-gold-events");
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
        this.createTurretControls();
    }
    focusTypingInput() {
        this.typingInput.focus();
    }
    showShortcutOverlay() {
        this.setShortcutOverlayVisible(true);
    }
    hideShortcutOverlay() {
        this.setShortcutOverlayVisible(false);
    }
    toggleShortcutOverlay() {
        this.setShortcutOverlayVisible(!this.isShortcutOverlayVisible());
    }
    isShortcutOverlayVisible() {
        if (!this.shortcutOverlay)
            return false;
        return this.shortcutOverlay.container.dataset.visible === "true";
    }
    showOptionsOverlay() {
        this.setOptionsOverlayVisible(true);
    }
    hideOptionsOverlay() {
        this.setOptionsOverlayVisible(false);
    }
    isOptionsOverlayVisible() {
        if (!this.optionsOverlay)
            return false;
        return this.optionsOverlay.container.dataset.visible === "true";
    }
    syncOptionsOverlayState(state) {
        if (!this.optionsOverlay)
            return;
        this.syncingOptionToggles = true;
        this.optionsOverlay.soundToggle.checked = state.soundEnabled;
        this.optionsOverlay.soundVolumeSlider.disabled = !state.soundEnabled;
        this.optionsOverlay.soundVolumeSlider.setAttribute("aria-disabled", state.soundEnabled ? "false" : "true");
        this.optionsOverlay.soundVolumeSlider.tabIndex = state.soundEnabled ? 0 : -1;
        this.optionsOverlay.soundVolumeSlider.value = state.soundVolume.toString();
        this.updateSoundVolumeDisplay(state.soundVolume);
        this.optionsOverlay.soundIntensitySlider.disabled = !state.soundEnabled;
        this.optionsOverlay.soundIntensitySlider.setAttribute("aria-disabled", state.soundEnabled ? "false" : "true");
        this.optionsOverlay.soundIntensitySlider.tabIndex = state.soundEnabled ? 0 : -1;
        this.optionsOverlay.soundIntensitySlider.value = state.soundIntensity.toString();
        this.updateSoundIntensityDisplay(state.soundIntensity);
        this.optionsOverlay.diagnosticsToggle.checked = state.diagnosticsVisible;
        this.optionsOverlay.reducedMotionToggle.checked = state.reducedMotionEnabled;
        this.optionsOverlay.checkeredBackgroundToggle.checked = state.checkeredBackgroundEnabled;
        this.optionsOverlay.readableFontToggle.checked = state.readableFontEnabled;
        this.optionsOverlay.dyslexiaFontToggle.checked = state.dyslexiaFontEnabled;
        this.optionsOverlay.colorblindPaletteToggle.checked = state.colorblindPaletteEnabled;
        this.setSelectValue(this.optionsOverlay.fontScaleSelect, state.hudFontScale.toString());
        this.applyTelemetryOptionState(state.telemetry);
        if (this.optionsOverlay.crystalPulseToggle) {
            const toggle = this.optionsOverlay.crystalPulseToggle;
            const wrapper = this.optionsOverlay.crystalPulseWrapper ??
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
    setTurretAvailability(availability) {
        const next = {};
        for (const typeId of Object.keys(this.config.turretArchetypes)) {
            next[typeId] = availability?.[typeId] !== false;
        }
        this.availableTurretTypes = next;
        this.applyTurretAvailabilityToControls();
    }
    setTurretDowngradeEnabled(enabled) {
        if (this.turretDowngradeEnabled === enabled) {
            return;
        }
        this.turretDowngradeEnabled = enabled;
        if (this.lastState) {
            this.updateTurretControls(this.lastState);
        }
        else if (!enabled) {
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
    showWaveScorecard(data) {
        if (!this.waveScorecard)
            return;
        this.renderWaveScorecard(data);
        this.setWaveScorecardVisible(true);
    }
    hideWaveScorecard() {
        this.setWaveScorecardVisible(false);
    }
    isWaveScorecardVisible() {
        if (!this.waveScorecard)
            return false;
        return this.waveScorecard.container.dataset.visible === "true";
    }
    update(state, upcoming, options = {}) {
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
        this.healthBar.style.width = `${hpRatio * 100}%`;
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
            }
            else {
                this.activeWord.innerHTML = segments;
                delete this.activeWord.dataset.shielded;
            }
        }
        else {
            this.activeWord.innerHTML = "";
            delete this.activeWord.dataset.shielded;
        }
        this.wavePreview.setColorBlindFriendly(Boolean(options.colorBlindFriendly));
        this.updateCastleControls(state);
        this.updateTurretControls(state);
        this.updateCombo(state.typing.combo, state.typing.comboWarning, state.typing.comboTimer, state.typing.accuracy);
        this.wavePreview.render(upcoming);
        this.applyTutorialSlotLock(state);
        const history = state.analytics.waveHistory?.length
            ? state.analytics.waveHistory
            : state.analytics.waveSummaries;
        this.refreshAnalyticsViewer(history, {
            timeToFirstTurret: state.analytics.timeToFirstTurret ?? null
        });
    }
    showCastleMessage(message) {
        this.castleStatus.textContent = message;
        this.castleStatus.dataset.messageActive = "true";
        setTimeout(() => {
            this.castleStatus.textContent = "";
            delete this.castleStatus.dataset.messageActive;
        }, 1800);
    }
    showSlotMessage(slotId, message) {
        const slot = this.slotControls.get(slotId);
        if (!slot)
            return;
        slot.status.textContent = message;
        slot.status.dataset.messageActive = "true";
        setTimeout(() => {
            slot.status.textContent = "";
            delete slot.status.dataset.messageActive;
        }, 2000);
    }
    appendLog(message) {
        this.logEntries.unshift(message);
        if (this.logEntries.length > this.logLimit) {
            this.logEntries.length = this.logLimit;
        }
        this.renderLog();
    }
    setTutorialMessage(message, highlight) {
        const banner = this.tutorialBanner;
        if (!banner)
            return;
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
        }
        else {
            delete container.dataset.highlight;
        }
        content.textContent = message;
        if (!wasVisible) {
            this.tutorialBannerExpanded = condensed ? false : true;
        }
        else if (!condensed) {
            this.tutorialBannerExpanded = true;
        }
        this.refreshTutorialBannerLayout();
    }
    updateCastleBonusHint(state) {
        if (!this.optionsCastleBonus)
            return;
        const container = this.optionsCastleBonus;
        const currentLevelConfig = this.config.castleLevels.find((level) => level.level === state.castle.level) ?? null;
        const percent = Math.round(Math.max(0, (state.castle.goldBonusPercent ?? 0) * 100));
        let summary;
        if (percent > 0) {
            summary = `Enemy rewards grant +${percent}% gold thanks to your treasury.`;
        }
        else {
            summary = "Enemy rewards currently receive no bonus—upgrade to unlock extra gold.";
        }
        const nextLevelConfig = this.config.castleLevels.find((level) => level.level === state.castle.level + 1);
        if (nextLevelConfig) {
            const nextPercent = Math.round(Math.max(0, (nextLevelConfig.goldBonusPercent ?? 0) * 100));
            const delta = nextPercent - percent;
            if (delta > 0) {
                summary += ` Upgrade to level ${nextLevelConfig.level} to reach +${nextPercent}% (${delta}% more).`;
            }
            else {
                summary += ` Upgrade to level ${nextLevelConfig.level} for additional defenses.`;
            }
        }
        else {
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
    updateWavePreviewHint(active, message) {
        if (!this.wavePreviewHint)
            return;
        if (active) {
            const trimmed = message?.trim();
            if (trimmed && trimmed.length > 0) {
                this.wavePreviewHintMessage = trimmed;
            }
            this.wavePreviewHint.textContent = this.wavePreviewHintMessage;
            this.wavePreviewHint.dataset.visible = "true";
            this.wavePreviewHint.setAttribute("aria-hidden", "false");
        }
        else {
            this.wavePreviewHint.dataset.visible = "false";
            this.wavePreviewHint.setAttribute("aria-hidden", "true");
            this.wavePreviewHint.textContent = "";
        }
    }
    setWavePreviewHighlight(active, message) {
        this.wavePreview.setTutorialHighlight(active);
        this.updateWavePreviewHint(active, message ?? null);
    }
    setSlotTutorialLock(lock) {
        this.tutorialSlotLock = lock;
        if (this.lastState) {
            this.applyTutorialSlotLock(this.lastState);
        }
    }
    clearSlotTutorialLock() {
        this.tutorialSlotLock = null;
        if (this.lastState) {
            this.updateTurretControls(this.lastState);
            this.applyTutorialSlotLock(this.lastState);
        }
    }
    showTutorialSummary(data, handlers) {
        if (!this.tutorialSummary)
            return;
        this.tutorialSummaryHandlers = handlers;
        const container = this.tutorialSummary.container;
        container.dataset.visible = "true";
        const stats = [
            ["accuracy", `Accuracy: ${(data.accuracy * 100).toFixed(1)}%`],
            ["combo", `Best Combo: x${Math.max(1, Math.floor(data.bestCombo ?? 0))}`],
            ["breaches", `Breaches sustained: ${data.breaches}`],
            ["gold", `Gold remaining: ${Math.max(0, Math.floor(data.gold))}g`]
        ];
        for (const [field, value] of stats) {
            const item = container.querySelector(`[data-field="${field}"]`);
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
    hideTutorialSummary() {
        if (!this.tutorialSummary)
            return;
        this.tutorialSummary.container.dataset.visible = "false";
        this.tutorialSummary.continueBtn.onclick = null;
        this.tutorialSummary.replayBtn.onclick = null;
        this.tutorialSummaryHandlers = null;
    }
    getCastleUpgradeBenefits(currentConfig, nextConfig) {
        if (!currentConfig || !nextConfig) {
            return [];
        }
        const benefits = [];
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
    renderCastlePassives(passives) {
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
    }
    renderCastleGoldEvents(events, currentTime) {
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
            const deltaValue = typeof event.delta === "number" && Number.isFinite(event.delta)
                ? Math.round(event.delta)
                : null;
            const goldValue = typeof event.gold === "number" && Number.isFinite(event.gold)
                ? Math.round(event.gold)
                : null;
            const timestamp = typeof event.timestamp === "number" && Number.isFinite(event.timestamp)
                ? event.timestamp
                : null;
            const age = timestamp !== null && Number.isFinite(currentTime)
                ? Math.max(0, currentTime - timestamp)
                : null;
            if (deltaValue !== null) {
                item.dataset.deltaSign =
                    deltaValue > 0 ? "positive" : deltaValue < 0 ? "negative" : "neutral";
            }
            else {
                item.dataset.deltaSign = "neutral";
            }
            const parts = [];
            if (deltaValue !== null) {
                const prefix = deltaValue >= 0 ? "+" : "";
                parts.push(`${prefix}${deltaValue}g`);
            }
            else {
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
        const latestLabel = typeof latestDelta?.delta === "number" && Number.isFinite(latestDelta.delta)
            ? `${latestDelta.delta > 0 ? "+" : ""}${Math.round(latestDelta.delta)}g`
            : null;
        const summary = latestLabel ? `${descriptor} (last ${latestLabel})` : descriptor;
        this.updateCondensedSectionSummary(this.castleGoldEventsSection, summary);
    }
    renderOptionsCastlePassives(passives) {
        if (!this.optionsCastlePassives)
            return;
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
    }
    formatCastlePassive(passive, options = {}) {
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
    createPassiveListItem(passive, options = {}) {
        const item = document.createElement("li");
        const icon = document.createElement("span");
        const label = document.createElement("span");
        const passiveId = passive.id ?? "generic";
        icon.className = `passive-icon passive-icon--${passiveId}`;
        icon.setAttribute("aria-hidden", "true");
        label.className = "passive-label";
        label.textContent = this.formatCastlePassive(passive, options);
        item.appendChild(icon);
        item.appendChild(label);
        return item;
    }
    updateOptionsPassivesSummary(summary) {
        if (this.optionsPassivesSummary) {
            this.optionsPassivesSummary.textContent = summary;
        }
        this.applyOptionsPassivesToggleLabel();
    }
    applyOptionsPassivesToggleLabel() {
        if (!this.optionsPassivesToggle)
            return;
        const summaryText = this.optionsPassivesSummary?.textContent?.trim();
        if (this.optionsPassivesCollapsed) {
            this.optionsPassivesToggle.textContent = summaryText
                ? `Show Active Passives (${summaryText})`
                : "Show Active Passives";
        }
        else {
            this.optionsPassivesToggle.textContent = "Hide Active Passives";
        }
    }
    setOptionsPassivesCollapsed(collapsed, options = {}) {
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
    createCondensedSection(options, sectionId) {
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
        const section = {
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
    setCondensedSectionCollapsed(section, collapsed, options = {}) {
        section.collapsed = collapsed;
        section.container.dataset.collapsed = collapsed ? "true" : "false";
        section.toggle.setAttribute("aria-expanded", collapsed ? "false" : "true");
        const summaryText = section.summary.textContent?.trim();
        if (collapsed) {
            section.toggle.textContent = summaryText
                ? `Show ${section.title} (${summaryText})`
                : `Show ${section.title}`;
        }
        else {
            section.toggle.textContent = `Hide ${section.title}`;
        }
        if (!options.silent) {
            const patch = {};
            if (options.sectionId === "hud-passives") {
                patch.hudCastlePassivesCollapsed = collapsed;
            }
            else if (options.sectionId === "hud-gold-events") {
                patch.hudGoldEventsCollapsed = collapsed;
            }
            if (Object.keys(patch).length > 0) {
                this.callbacks.onCollapsePreferenceChange?.(patch);
            }
        }
    }
    updateCondensedSectionSummary(section, summary) {
        section.summary.textContent = summary;
        if (section.collapsed) {
            this.setCondensedSectionCollapsed(section, section.collapsed);
        }
    }
    setCondensedSectionVisibility(section, visible) {
        section.container.hidden = !visible;
        if (!visible) {
            section.container.setAttribute("aria-hidden", "true");
        }
        else {
            section.container.removeAttribute("aria-hidden");
        }
        section.list.dataset.visible = visible ? "true" : "false";
        section.list.hidden = !visible;
    }
    applyCollapsePreferences(prefs, options = {}) {
        const shouldFallback = options.fallbackToPreferred ?? false;
        if (this.castlePassivesSection) {
            const value = prefs.hudCastlePassivesCollapsed;
            if (typeof value === "boolean") {
                this.setCondensedSectionCollapsed(this.castlePassivesSection, value, {
                    silent: options.silent,
                    sectionId: "hud-passives"
                });
            }
            else if (shouldFallback) {
                this.setCondensedSectionCollapsed(this.castlePassivesSection, this.prefersCondensedHudLists(), { silent: true, sectionId: "hud-passives" });
            }
        }
        if (this.castleGoldEventsSection) {
            const value = prefs.hudGoldEventsCollapsed;
            if (typeof value === "boolean") {
                this.setCondensedSectionCollapsed(this.castleGoldEventsSection, value, {
                    silent: options.silent,
                    sectionId: "hud-gold-events"
                });
            }
            else if (shouldFallback) {
                this.setCondensedSectionCollapsed(this.castleGoldEventsSection, this.prefersCondensedHudLists(), { silent: true, sectionId: "hud-gold-events" });
            }
        }
        if (this.optionsCastlePassives) {
            const value = prefs.optionsPassivesCollapsed;
            if (typeof value === "boolean") {
                this.setOptionsPassivesCollapsed(value, { silent: options.silent });
            }
            else if (shouldFallback) {
                this.setOptionsPassivesCollapsed(this.optionsPassivesDefaultCollapsed, { silent: true });
            }
        }
    }
    getCondensedState() {
        var _a, _b;
        const compactHeightActive = typeof document !== "undefined" &&
            typeof document.body !== "undefined" &&
            document.body.dataset.compactHeight === "true";
        return {
            tutorialBannerCondensed: this.shouldCondenseTutorialBanner(),
            tutorialBannerExpanded: this.tutorialBannerExpanded,
            hudCastlePassivesCollapsed: ((_a = this.castlePassivesSection) == null ? void 0 : _a.collapsed) ?? null,
            hudGoldEventsCollapsed: ((_b = this.castleGoldEventsSection) == null ? void 0 : _b.collapsed) ?? null,
            optionsPassivesCollapsed: typeof this.optionsPassivesCollapsed === "boolean"
                ? this.optionsPassivesCollapsed
                : null,
            compactHeight: compactHeightActive,
            prefersCondensedLists: this.prefersCondensedHudLists()
        };
    }
    prefersCondensedHudLists() {
        return (this.matchesMediaQuery("(max-width: 768px)") ||
            this.matchesMediaQuery("(max-height: 540px)"));
    }
    initializeViewportListeners() {
        if (typeof window === "undefined") {
            this.refreshTutorialBannerLayout();
            return;
        }
        const handleResize = () => this.refreshTutorialBannerLayout();
        if (typeof window.addEventListener === "function") {
            try {
                window.addEventListener("resize", handleResize, { passive: true });
            }
            catch {
                window.addEventListener("resize", handleResize);
            }
        }
        if (typeof window.matchMedia === "function") {
            try {
                const orientationQuery = window.matchMedia("(orientation: landscape)");
                const handleOrientation = () => this.refreshTutorialBannerLayout();
                if (typeof orientationQuery.addEventListener === "function") {
                    orientationQuery.addEventListener("change", handleOrientation);
                }
                else if (typeof orientationQuery.addListener === "function") {
                    orientationQuery.addListener(handleOrientation);
                }
            }
            catch {
                // ignore
            }
        }
        this.refreshTutorialBannerLayout();
    }
    refreshTutorialBannerLayout() {
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
            toggle.setAttribute("aria-label", expanded ? "Hide full tutorial tip" : "Show full tutorial tip");
        }
    }
    updateCompactHeightDataset() {
        if (typeof document === "undefined" || !document.body) {
            return;
        }
        if (this.shouldCondenseTutorialBanner()) {
            document.body.dataset.compactHeight = "true";
        }
        else {
            delete document.body.dataset.compactHeight;
        }
    }
    shouldCondenseTutorialBanner() {
        return this.matchesMediaQuery("(max-height: 540px)");
    }
    matchesMediaQuery(query) {
        if (typeof window === "undefined" || typeof window.matchMedia !== "function") {
            return false;
        }
        try {
            return window.matchMedia(query).matches;
        }
        catch {
            return false;
        }
    }
    renderOptionsCastleBenefits(benefits, nextConfig) {
        if (!this.optionsCastleBenefits)
            return;
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
    updateCastleControls(state) {
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
        const currentBonusPercent = Math.max(0, Math.round((currentConfig.goldBonusPercent ?? 0) * 100));
        const bonusNote = currentBonusPercent > 0
            ? `Current castle bonus: +${currentBonusPercent}% gold from enemy rewards.`
            : "";
        const appendBonusNote = (text) => bonusNote ? `${text ? `${text.trim()} ` : ""}${bonusNote}`.trim() : text;
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
    updateCastleRepair(state) {
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
        const healPreview = missingHealth > 0
            ? Math.min(missingHealth, repairSettings.healAmount)
            : repairSettings.healAmount;
        const cooledDown = cooldownRemaining <= 0.05;
        const hasGold = state.resources.gold >= repairSettings.cost;
        const canHeal = missingHealth > 0.5;
        const blockers = [];
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
        }
        else {
            delete this.castleRepairButton.dataset.cooldown;
        }
        const baseLabel = `Repair castle for ${repairSettings.cost} gold, restoring up to ${Math.round(healPreview)} health. Cooldown ${repairSettings.cooldownSeconds} seconds.`;
        const finalLabel = blockers.length > 0 ? `${baseLabel} ${blockers.join(". ")}.` : baseLabel;
        this.castleRepairButton.setAttribute("aria-label", finalLabel);
        if (blockers.length > 0) {
            this.castleRepairButton.title = blockers.join(". ");
        }
        else {
            this.castleRepairButton.title = `Restore up to ${Math.round(healPreview)} HP instantly. Cooldown ${repairSettings.cooldownSeconds}s.`;
        }
    }
    updateTurretControls(state) {
        for (const slot of state.turrets) {
            const controls = this.slotControls.get(slot.id);
            if (!controls)
                continue;
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
                let selectedType = this.getSelectValue(controls.select) ?? "arrow";
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
                const hasEnabledTypes = this.hasEnabledTurretTypes();
                controls.select.disabled = !hasEnabledTypes;
                if (typeEnabled) {
                    controls.action.onclick = () => {
                        const next = this.getSelectValue(controls.select) ?? "arrow";
                        this.callbacks.onPlaceTurret(slot.id, next);
                    };
                    const affordable = state.resources.gold >= cost;
                    controls.action.disabled = !affordable;
                    controls.action.textContent = `Place (${cost}g)`;
                }
                else {
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
            }
            else {
                controls.select.style.display = "none";
                this.applyAvailabilityToSelect(controls.select);
                const turret = slot.turret;
                if (!turret)
                    continue;
                const nextConfig = this.config.turretArchetypes[turret.typeId]?.levels.find((level) => level.level === turret.level + 1);
                const priorityDescription = this.describePriority(priority);
                const turretEnabled = this.isTurretTypeEnabled(turret.typeId);
                if (!nextConfig) {
                    controls.action.disabled = true;
                    controls.action.textContent = `${turret.typeId.toUpperCase()} Lv.${turret.level} (Max)`;
                    controls.action.onclick = null;
                }
                else if (!turretEnabled) {
                    controls.action.disabled = true;
                    controls.action.textContent = `${turret.typeId.toUpperCase()} Lv.${turret.level} (Disabled)`;
                    controls.action.onclick = null;
                }
                else {
                    controls.action.disabled = state.resources.gold < nextConfig.cost;
                    controls.action.textContent = `Upgrade (${nextConfig.cost}g)`;
                    controls.action.onclick = () => {
                        this.callbacks.onUpgradeTurret(slot.id);
                    };
                }
                if (controls.downgradeButton) {
                    const canDowngrade = this.turretDowngradeEnabled && Boolean(this.callbacks.onDowngradeTurret);
                    if (canDowngrade) {
                        const archetype = this.config.turretArchetypes[turret.typeId];
                        let refund = 0;
                        if (turret.level > 1) {
                            const currentLevel = archetype?.levels.find((levelConfig) => levelConfig.level === turret.level);
                            refund = currentLevel?.cost ?? 0;
                        }
                        else {
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
                    }
                    else {
                        controls.downgradeButton.style.display = "none";
                        controls.downgradeButton.setAttribute("aria-hidden", "true");
                        controls.downgradeButton.disabled = true;
                        controls.downgradeButton.tabIndex = -1;
                        controls.downgradeButton.onclick = null;
                    }
                }
                if (controls.status.dataset.messageActive !== "true") {
                    const statusParts = [
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
    updateTurretPresets(presets) {
        if (!this.presetList) {
            return;
        }
        const seen = new Set();
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
            control.clearButton.setAttribute("aria-label", canClear ? `Clear ${preset.label}` : `${preset.label} is empty`);
            const canApply = Boolean(this.callbacks.onTurretPresetApply) && preset.hasPreset && !preset.applyDisabled;
            control.applyButton.disabled = !canApply;
            control.applyButton.setAttribute("aria-disabled", canApply ? "false" : "true");
            if (preset.hasPreset && preset.applyCost !== null && preset.applyCost !== undefined) {
                control.applyButton.textContent = `Apply (${Math.max(0, Math.round(preset.applyCost))}g)`;
            }
            else {
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
            }
            else {
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
    ensurePresetControl(preset) {
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
        const control = {
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
    applyTutorialSlotLock(state) {
        const lock = this.tutorialSlotLock;
        for (const slot of state.turrets) {
            const controls = this.slotControls.get(slot.id);
            if (!controls)
                continue;
            if (!lock) {
                delete controls.container.dataset.tutorialHighlight;
                delete controls.container.dataset.tutorialLocked;
                this.resetTutorialSelectOptions(controls.select);
                controls.prioritySelect.disabled = !slot.unlocked;
                if (slot.unlocked) {
                    delete controls.priorityContainer.dataset.disabled;
                }
                else {
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
                    }
                    else {
                        this.resetTutorialSelectOptions(controls.select);
                    }
                }
                else {
                    controls.select.disabled = true;
                    controls.select.style.display = "none";
                    this.resetTutorialSelectOptions(controls.select);
                }
                controls.prioritySelect.disabled = false;
                delete controls.priorityContainer.dataset.disabled;
            }
            else {
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
    applyForcedSelectOption(select, forced) {
        for (const option of this.getSelectOptionNodes(select)) {
            if (typeof option.value === "string") {
                option.disabled = option.value !== forced;
            }
        }
    }
    resetTutorialSelectOptions(select) {
        for (const option of this.getSelectOptionNodes(select)) {
            option.disabled = false;
        }
    }
    notifyTurretHover(slotId) {
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
    buildTurretHoverContext(slotId) {
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
        const selected = this.getSelectValue(controls.select);
        if (selected && this.config.turretArchetypes[selected]) {
            return {
                typeId: selected,
                level: 1
            };
        }
        return null;
    }
    elementContains(container, node) {
        if (!node) {
            return false;
        }
        if (typeof container.contains === "function") {
            try {
                return container.contains(node);
            }
            catch {
                /* fall through to manual traversal */
            }
        }
        let current = node;
        while (current) {
            if (current === container) {
                return true;
            }
            const anyNode = current;
            current = anyNode.parentNode ?? anyNode.parentElement ?? null;
        }
        return false;
    }
    getSelectOptionNodes(select) {
        const withOptions = select.options;
        if (withOptions && typeof withOptions.length === "number") {
            return Array.from(withOptions);
        }
        if (select.children && select.children.length > 0) {
            return Array.from(select.children).map((child) => child);
        }
        return [];
    }
    createTurretControls() {
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
                const related = (isFocusEvent ? event.relatedTarget : null) ?? null;
                if (!this.elementContains(container, related)) {
                    clearHover();
                }
            });
            select.addEventListener("change", () => {
                if (!this.callbacks.onTurretHover)
                    return;
                const isHovered = typeof container.matches === "function" && container.matches(":hover");
                let activeElement = null;
                if (typeof document !== "undefined") {
                    const candidate = document.activeElement;
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
    populatePrioritySelect(select) {
        const options = [
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
    normalizePriority(value) {
        if (value === "first" || value === "strongest" || value === "weakest") {
            return value;
        }
        return null;
    }
    applyTurretAvailabilityToControls() {
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
    applyAvailabilityToSelect(select) {
        const optionCollection = select.options;
        let options = [];
        if (optionCollection && typeof optionCollection.length === "number") {
            options = Array.from(optionCollection);
        }
        else {
            const fallbackChildren = select.children;
            if (Array.isArray(fallbackChildren)) {
                options = [...fallbackChildren];
            }
        }
        for (const option of options) {
            const typeId = option.value;
            if (!typeId)
                continue;
            const existingBaseLabel = option.getAttribute?.("data-base-label") ??
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
    pickFirstEnabledTurretType() {
        for (const typeId of Object.keys(this.config.turretArchetypes)) {
            if (this.isTurretTypeEnabled(typeId)) {
                return typeId;
            }
        }
        return null;
    }
    hasEnabledTurretTypes() {
        return Object.keys(this.config.turretArchetypes).some((typeId) => this.isTurretTypeEnabled(typeId));
    }
    isTurretTypeEnabled(typeId) {
        return this.availableTurretTypes[typeId] !== false;
    }
    getTurretDisplayName(typeId) {
        const archetype = this.config.turretArchetypes[typeId];
        return archetype?.name ?? typeId.toUpperCase();
    }
    describePriority(priority) {
        switch (priority) {
            case "strongest":
                return "Strongest";
            case "weakest":
                return "Weakest";
            default:
                return "First";
        }
    }
    describeAffinity(typeId) {
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
    describeShieldBonus(typeId, level) {
        const archetype = this.config.turretArchetypes[typeId];
        if (!archetype) {
            return null;
        }
        let levelConfig = typeof level === "number"
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
    formatPresetSummary(slots) {
        if (!slots || slots.length === 0) {
            return "No turrets saved.";
        }
        return slots
            .map((slot) => {
            const typeName = this.getTurretDisplayName(slot.typeId);
            const slotLabel = this.formatSlotLabel(slot.slotId);
            const extras = [];
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
    formatSlotLabel(slotId) {
        const match = /^slot-(\d+)$/.exec(slotId);
        if (match) {
            return `S${match[1]}`;
        }
        return slotId;
    }
    formatEnemyTierName(tierId) {
        const tier = this.config.enemyTiers[tierId];
        const source = tier?.id ?? tierId;
        if (!source) {
            return "Unknown";
        }
        return source.charAt(0).toUpperCase() + source.slice(1);
    }
    getElement(id) {
        const el = document.getElementById(id);
        if (!el) {
            throw new Error(`Expected element with id "${id}"`);
        }
        return el;
    }
    handleGoldDelta(currentGold) {
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
    updateCombo(combo, warning, timer, accuracy) {
        const safeAccuracy = typeof accuracy === "number" && Number.isFinite(accuracy)
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
            }
            else {
                delete this.comboLabel.dataset.warning;
                this.comboLabel.textContent = `Combo x${combo} (Best x${this.maxCombo})`;
                this.comboBaselineAccuracy = safeAccuracy ?? this.comboBaselineAccuracy;
                this.hideComboAccuracyDelta();
            }
        }
        else {
            this.comboLabel.dataset.active = "false";
            delete this.comboLabel.dataset.warning;
            this.comboLabel.textContent = `Combo x0 (Best x${this.maxCombo})`;
            this.comboBaselineAccuracy = safeAccuracy ?? this.comboBaselineAccuracy;
            this.hideComboAccuracyDelta();
        }
    }
    showComboAccuracyDelta(currentAccuracy) {
        const baseline = Number.isFinite(this.comboBaselineAccuracy)
            ? this.comboBaselineAccuracy
            : currentAccuracy;
        const delta = (currentAccuracy - baseline) * 100;
        const prefix = delta > 0 ? "+" : "";
        this.comboAccuracyDelta.textContent = `${prefix}${delta.toFixed(1)}% accuracy`;
        this.comboAccuracyDelta.dataset.visible = "true";
        if (delta > 0.05) {
            this.comboAccuracyDelta.dataset.trend = "up";
        }
        else if (delta < -0.05) {
            this.comboAccuracyDelta.dataset.trend = "down";
        }
        else {
            delete this.comboAccuracyDelta.dataset.trend;
        }
    }
    hideComboAccuracyDelta() {
        this.comboAccuracyDelta.dataset.visible = "false";
        delete this.comboAccuracyDelta.dataset.trend;
        this.comboAccuracyDelta.textContent = "";
    }
    renderLog() {
        this.logList.replaceChildren();
        for (const entry of this.logEntries) {
            const item = document.createElement("li");
            item.textContent = entry;
            this.logList.appendChild(item);
        }
    }
    renderWaveScorecard(data) {
        if (!this.waveScorecard)
            return;
        this.waveScorecard.container.dataset.mode = data.mode;
        this.waveScorecard.container.dataset.practice = data.mode === "practice" ? "true" : "false";
        const entries = [
            {
                field: "wave",
                label: "Wave",
                value: `Wave ${Math.max(1, data.waveIndex + 1)} / ${Math.max(data.waveTotal, 1)}${data.mode === "practice" ? " (Practice)" : ""}`
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
    updateShieldTelemetry(entries) {
        const currentShielded = entries.some((entry) => !entry.isNextWave && (entry.shield ?? 0) > 0);
        const nextShielded = entries.some((entry) => entry.isNextWave && (entry.shield ?? 0) > 0);
        this.wavePreview.setShieldForecast(currentShielded, nextShielded);
        if (currentShielded && !this.lastShieldTelemetry.current) {
            this.showCastleMessage("Shielded enemies inbound! Let your turrets shatter the barrier.");
        }
        else if (!currentShielded && nextShielded && !this.lastShieldTelemetry.next) {
            this.showCastleMessage("Next wave includes shielded foes. Prepare turrets to break shields.");
        }
        this.lastShieldTelemetry = { current: currentShielded, next: nextShielded };
    }
    getShieldForecast() {
        return { ...this.lastShieldTelemetry };
    }
    setWaveScorecardField(field, label, value) {
        if (!this.waveScorecard)
            return;
        const items = Array.from(this.waveScorecard.statsList.children);
        const target = items.find((element) => element.dataset.field === field);
        if (!target)
            return;
        const labelSpan = document.createElement("span");
        labelSpan.textContent = label;
        const valueSpan = document.createElement("span");
        valueSpan.textContent = value;
        target.replaceChildren(labelSpan, valueSpan);
    }
    setWaveScorecardVisible(visible) {
        if (!this.waveScorecard)
            return;
        this.waveScorecard.container.dataset.visible = visible ? "true" : "false";
        if (visible) {
            this.waveScorecard.continueBtn.focus();
        }
        else {
            this.focusTypingInput();
        }
    }
    setShortcutOverlayVisible(visible) {
        if (!this.shortcutOverlay)
            return;
        this.shortcutOverlay.container.dataset.visible = visible ? "true" : "false";
        if (visible) {
            this.shortcutOverlay.closeButton.focus();
        }
        else {
            this.focusTypingInput();
        }
    }
    applyTelemetryOptionState(state) {
        if (!this.optionsOverlay?.telemetryToggle)
            return;
        const toggle = this.optionsOverlay.telemetryToggle;
        const wrapper = this.optionsOverlay.telemetryWrapper ??
            (toggle.parentElement instanceof HTMLElement ? toggle.parentElement : undefined);
        const available = Boolean(state?.available);
        if (!available) {
            if (wrapper) {
                wrapper.style.display = "none";
                wrapper.setAttribute("aria-hidden", "true");
            }
            else {
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
        }
        else {
            toggle.style.display = "";
        }
        toggle.setAttribute("aria-hidden", "false");
        toggle.disabled = Boolean(state?.disabled);
        toggle.tabIndex = toggle.disabled ? -1 : 0;
        toggle.checked = Boolean(state?.checked);
    }
    updateSoundVolumeDisplay(volume) {
        if (!this.optionsOverlay?.soundVolumeValue)
            return;
        const percent = Math.round(volume * 100);
        this.optionsOverlay.soundVolumeValue.textContent = `${percent}%`;
    }
    updateSoundIntensityDisplay(intensity) {
        if (!this.optionsOverlay?.soundIntensityValue)
            return;
        const percent = Math.round(intensity * 100);
        this.optionsOverlay.soundIntensityValue.textContent = `${percent}%`;
    }
    setAnalyticsExportEnabled(enabled) {
        const button = this.optionsOverlay?.analyticsExportButton;
        if (!button)
            return;
        if (enabled) {
            button.style.display = "";
            button.disabled = false;
            button.setAttribute("aria-hidden", "false");
            button.tabIndex = 0;
            button.setAttribute("tabindex", "0");
        }
        else {
            button.style.display = "none";
            button.disabled = true;
            button.setAttribute("aria-hidden", "true");
            button.tabIndex = -1;
            button.setAttribute("tabindex", "-1");
        }
    }
    setHudFontScale(scale) {
        if (typeof document === "undefined")
            return;
        document.documentElement.style.setProperty("--hud-font-scale", scale.toString());
    }
    hasAnalyticsViewer() {
        return Boolean(this.analyticsViewer);
    }
    toggleAnalyticsViewer() {
        const next = !this.analyticsViewerVisible;
        return this.setAnalyticsViewerVisible(next);
    }
    normalizeAnalyticsViewerFilter(value) {
        if (value === "last-5" || value === "last-10" || value === "breaches" || value === "shielded") {
            return value;
        }
        return "all";
    }
    describeAnalyticsViewerFilter(filter) {
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
    applyAnalyticsViewerFilter(summaries) {
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
    setSelectValue(select, value) {
        if (!select)
            return;
        try {
            select.value = value;
        }
        catch {
            select.setAttribute("value", value);
        }
    }
    getSelectValue(select) {
        if (!select)
            return undefined;
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
    setAnalyticsViewerVisible(visible) {
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
    isAnalyticsViewerVisible() {
        return this.analyticsViewerVisible;
    }
    refreshAnalyticsViewer(summaries, options = {}) {
        if (!this.analyticsViewer) {
            return;
        }
        const { force = false, timeToFirstTurret = null } = options;
        const fallbackMode = this.lastState?.mode ?? "campaign";
        const filteredSummaries = this.applyAnalyticsViewerFilter(summaries);
        const signatureSource = filteredSummaries.length === 0
            ? "empty"
            : filteredSummaries
                .map((summary) => [
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
            ].join(":"))
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
        const summaryModeLabel = modesInView.size === 0
            ? fallbackMode === "practice"
                ? "Practice"
                : "Campaign"
            : modesInView.size === 1
                ? Array.from(modesInView)[0] === "practice"
                    ? "Practice"
                    : "Campaign"
                : "Mixed";
        const totals = filteredSummaries.reduce((acc, summary) => {
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
        }, {
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
        });
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
            }
            else {
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
    setOptionsOverlayVisible(visible) {
        if (!this.optionsOverlay)
            return;
        this.optionsOverlay.container.dataset.visible = visible ? "true" : "false";
        if (visible) {
            this.optionsOverlay.resumeButton.focus();
        }
        else {
            this.focusTypingInput();
        }
    }
}

