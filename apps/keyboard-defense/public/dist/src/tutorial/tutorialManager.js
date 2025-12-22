const DEFAULT_STEPS = [
    { id: "intro", description: "Season intro overlay" },
    { id: "typing-basic", description: "Teach typing combat basics" },
    { id: "combo-diagnostics", description: "Explain combos and diagnostics toggle" },
    { id: "shielded-enemy", description: "Demonstrate turret-assisted shield removal" },
    { id: "turret-placement", description: "Guide turret placement" },
    { id: "turret-upgrade", description: "Upgrade placed turret" },
    { id: "castle-health", description: "Demonstrate breaches and castle health" },
    { id: "castle-passives", description: "Introduce castle passive buffs" },
    { id: "wrap-up", description: "Show summary and exit path" }
];
const STEP_ANCHORS = {
    intro: "left",
    "typing-basic": "left",
    "combo-diagnostics": "right",
    "shielded-enemy": "right",
    "turret-placement": "right",
    "turret-upgrade": "right",
    "castle-health": "left",
    "castle-passives": "left",
    "wrap-up": "left"
};
const WAVE_PREVIEW_MESSAGES = {
    combo: "Upcoming enemies queue here—watch the lanes to keep your combo alive.",
    placement: "Use the preview to place a turret where enemies are about to strike.",
    upgrade: "Check the preview to reinforce lanes before the next wave hits."
};
export class TutorialManager {
    constructor(options) {
        this.options = options;
        this.state = {
            active: false,
            currentStepIndex: 0,
            completedSteps: [],
            stepStartedAt: 0
        };
        this.pacingMultiplier = 1;
        this.timeInStep = 0;
        this.typingEnemyId = null;
        this.comboWords = ["focus", "flow"];
        this.comboWordIndex = 0;
        this.comboCompleted = false;
        this.errorsInStep = 0;
        this.assistHintShown = false;
        this.assistThreshold = 5;
        this.placementTurretType = "arrow";
        this.castleBreachTimer = null;
        this.shieldTurretType = "arcane";
        this.shieldTurretSlotId = null;
        this.shieldStepEnemyId = null;
        this.shieldStepShieldBroken = false;
        this.shieldStepTypingSuccess = false;
        this.shieldLessonPhase = "demo";
        this.passiveAnnouncementTimer = null;
        this.lastPassiveUnlocked = null;
        this.steps = DEFAULT_STEPS;
        this.handlers = this.createHandlers();
        this.placementSlotId = this.resolvePrimarySlotId();
        this.pacingMultiplier =
            typeof options?.pacing === "number" ? this.normalizePacing(options.pacing) : 1;
    }
    start() {
        if (this.state.active)
            return;
        this.state.active = true;
        this.state.currentStepIndex = 0;
        this.state.completedSteps = [];
        this.state.stepStartedAt = performance.now() / 1000;
        this.timeInStep = 0;
        this.resetShieldLessonState();
        this.clearPassiveAnnouncementTimer();
        const step = this.activeStep();
        this.applyStep(step);
        this.logTransition("start", step?.id);
    }
    skip() {
        if (!this.state.active)
            return;
        const current = this.activeStep();
        if (current) {
            this.handlers[current.id]?.onExit?.();
        }
        this.clearCastleBreachTimer();
        this.resetShieldLessonState();
        this.clearPassiveAnnouncementTimer();
        this.state.active = false;
        this.state.currentStepIndex = this.steps.length;
        this.options.onComplete?.();
        this.options.hud.setTutorialMessage(null);
        this.options.hud.setWavePreviewHighlight(false);
        this.logTransition("skip");
    }
    reset() {
        if (this.state.active) {
            const current = this.activeStep();
            if (current) {
                this.handlers[current.id]?.onExit?.();
            }
        }
        this.clearCastleBreachTimer();
        this.clearPassiveAnnouncementTimer();
        this.errorsInStep = 0;
        this.assistHintShown = false;
        this.state.active = false;
        this.state.currentStepIndex = 0;
        this.state.completedSteps = [];
        this.state.stepStartedAt = 0;
        this.timeInStep = 0;
        this.resetShieldLessonState();
        this.options.hud.setTutorialMessage(null);
        this.options.hud.setWavePreviewHighlight(false);
        this.logTransition("reset");
    }
    replayStep(stepId) {
        if (!stepId)
            return;
        const targetIndex = this.steps.findIndex((step) => step.id === stepId);
        if (targetIndex < 0)
            return;
        if (this.state.active) {
            const current = this.activeStep();
            if (current) {
                this.handlers[current.id]?.onExit?.();
            }
        }
        this.clearCastleBreachTimer();
        this.clearPassiveAnnouncementTimer();
        this.errorsInStep = 0;
        this.assistHintShown = false;
        this.state.active = true;
        this.state.currentStepIndex = targetIndex;
        this.state.completedSteps = this.steps.slice(0, targetIndex).map((step) => step.id);
        this.state.stepStartedAt = performance.now() / 1000;
        this.timeInStep = 0;
        this.resetShieldLessonState();
        const step = this.activeStep();
        this.applyStep(step);
        this.logTransition("replay", step?.id);
    }
    completeStep(stepId) {
        if (!this.state.active)
            return;
        const current = this.activeStep();
        if (!current || current.id !== stepId)
            return;
        if (current.id === "castle-health") {
            this.clearCastleBreachTimer();
        }
        this.handlers[current.id]?.onExit?.();
        this.state.completedSteps.push(current.id);
        this.state.currentStepIndex += 1;
        this.state.stepStartedAt = performance.now() / 1000;
        this.timeInStep = 0;
        if (this.state.currentStepIndex >= this.steps.length) {
            this.state.active = false;
            this.options.onComplete?.();
            this.options.hud.setTutorialMessage(null);
            this.options.hud.setWavePreviewHighlight(false);
            this.logTransition("complete");
            return;
        }
        const nextStep = this.activeStep();
        this.applyStep(nextStep);
        this.logTransition("advance", nextStep?.id);
    }
    getState() {
        return structuredClone(this.state);
    }
    getCurrentStepId() {
        const current = this.activeStep();
        return current ? current.id : null;
    }
    getStepProgress() {
        const current = this.activeStep();
        if (!current) {
            return null;
        }
        return {
            index: this.state.currentStepIndex + 1,
            total: this.steps.length,
            label: current.description ?? current.id,
            stepId: current.id,
            anchor: STEP_ANCHORS[current.id] ?? "left"
        };
    }
    getDockState() {
        if (!this.state.active) {
            return null;
        }
        const current = this.activeStep();
        if (!current) {
            return null;
        }
        const completed = new Set(this.state.completedSteps);
        const steps = this.steps.map((step, index) => ({
            id: step.id,
            label: step.description ?? step.id,
            status: completed.has(step.id)
                ? "done"
                : index === this.state.currentStepIndex
                    ? "active"
                    : "pending"
        }));
        return {
            active: true,
            currentStepId: current.id,
            steps
        };
    }
    update(deltaSeconds) {
        if (!this.state.active)
            return;
        const pacedDelta = deltaSeconds * this.pacingMultiplier;
        this.timeInStep += pacedDelta;
        const current = this.activeStep();
        if (!current)
            return;
        this.handlers[current.id]?.update?.(pacedDelta);
    }
    notify(event) {
        if (!this.state.active)
            return;
        const current = this.activeStep();
        if (!current)
            return;
        if (event.type === "castle:passive-unlocked") {
            this.lastPassiveUnlocked = event.payload?.passive ?? null;
        }
        const handled = this.handleEventSideEffects(current.id, event);
        if (this.shouldAdvance(current.id, event)) {
            this.completeStep(current.id);
        }
        else {
            if (!handled) {
                this.reinforceStep(current.id, event);
            }
        }
        this.logTransition(`event:${event.type}`, current.id);
    }
    activeStep() {
        return this.steps[this.state.currentStepIndex];
    }
    applyStep(step) {
        if (!step) {
            this.options.hud.setTutorialMessage(null);
            return;
        }
        this.timeInStep = 0;
        this.errorsInStep = 0;
        this.assistHintShown = false;
        this.handlers[step.id]?.onEnter?.();
        const message = this.describe(step.id);
        this.options.hud.setTutorialMessage(message, true);
    }
    shouldAdvance(stepId, event) {
        switch (stepId) {
            case "intro":
                return event.type === "ui:continue";
            case "typing-basic":
                return event.type === "typing:word-complete";
            case "combo-diagnostics":
                return event.type === "diagnostics:toggled" && this.comboCompleted;
            case "shielded-enemy": {
                if (event.type !== "typing:word-complete" || !this.shieldStepShieldBroken) {
                    return false;
                }
                const payloadEnemyId = event.payload?.enemyId ?? null;
                return payloadEnemyId === this.shieldStepEnemyId || payloadEnemyId === null;
            }
            case "turret-placement":
                return (event.type === "turret:placed" &&
                    event.payload.slotId === this.placementSlotId &&
                    event.payload.typeId === this.placementTurretType);
            case "turret-upgrade":
                return (event.type === "turret:upgraded" &&
                    event.payload.slotId === this.placementSlotId &&
                    (event.payload.level ?? 0) >= 2);
            case "castle-health":
                return event.type === "castle:breach";
            case "castle-passives":
                return event.type === "ui:continue";
            case "wrap-up":
                return event.type === "summary:dismissed";
            default:
                return false;
        }
    }
    createHandlers() {
        return {
            intro: {
                onEnter: () => {
                    this.options.pauseGame?.();
                },
                onExit: () => {
                    this.options.resumeGame?.();
                }
            },
            "typing-basic": {
                onEnter: () => {
                    console.info("[tutorial] typing-basic:onEnter (spawn scripted enemy)");
                    this.spawnTypedLessonEnemy({
                        tierId: "grunt",
                        lane: 1,
                        word: "valor",
                        waveIndex: 0
                    });
                },
                update: () => {
                    // Reserved for future timing cues.
                },
                onExit: () => {
                    this.typingEnemyId = null;
                }
            },
            "combo-diagnostics": {
                onEnter: () => {
                    console.info("[tutorial] combo-diagnostics:onEnter (spawn combo lesson enemies)");
                    this.comboWordIndex = 0;
                    this.comboCompleted = false;
                    this.spawnComboEnemy();
                    this.options.hud.setWavePreviewHighlight(true, WAVE_PREVIEW_MESSAGES.combo);
                },
                onExit: () => {
                    this.options.hud.setWavePreviewHighlight(false);
                },
                update: () => { }
            },
            "shielded-enemy": {
                onEnter: () => {
                    this.beginShieldLesson();
                },
                onExit: () => {
                    this.endShieldLesson();
                },
                update: () => { }
            },
            "turret-placement": {
                onEnter: () => {
                    const requiredGold = this.getPlacementCost();
                    this.ensureGold(requiredGold);
                    this.options.hud.setWavePreviewHighlight(true, WAVE_PREVIEW_MESSAGES.placement);
                    this.options.hud.setSlotTutorialLock({
                        slotId: this.placementSlotId,
                        mode: "placement",
                        forcedType: this.placementTurretType
                    });
                    this.options.hud.showSlotMessage(this.placementSlotId, "Place an Arrow turret here");
                },
                onExit: () => {
                    this.options.hud.clearSlotTutorialLock();
                    this.options.hud.setWavePreviewHighlight(false);
                },
                update: () => { }
            },
            "turret-upgrade": {
                onEnter: () => {
                    const upgradeCost = this.getUpgradeCost();
                    this.ensureGold(upgradeCost);
                    this.options.hud.setWavePreviewHighlight(true, WAVE_PREVIEW_MESSAGES.upgrade);
                    this.options.hud.setSlotTutorialLock({
                        slotId: this.placementSlotId,
                        mode: "upgrade",
                        forcedType: this.placementTurretType
                    });
                    this.options.hud.showSlotMessage(this.placementSlotId, "Upgrade the highlighted turret");
                },
                onExit: () => {
                    this.options.hud.clearSlotTutorialLock();
                    this.options.hud.setWavePreviewHighlight(false);
                },
                update: () => { }
            },
            "castle-health": {
                onEnter: () => {
                    this.scheduleCastleBreach();
                    this.options.hud.setTutorialMessage("If enemies slip past your defenses the castle will take damage. Watch the health bar!", true);
                },
                onExit: () => {
                    this.clearCastleBreachTimer();
                },
                update: () => { }
            },
            "castle-passives": {
                onEnter: () => {
                    const passive = this.consumeLatestPassiveForAnnouncement();
                    if (passive) {
                        const description = this.formatPassiveAnnouncement(passive);
                        this.options.hud.setTutorialMessage(`Passive unlocked: ${description}`, true);
                        this.options.hud.setPassiveHighlight?.(passive.id ?? "generic", {
                            autoExpand: true,
                            scrollIntoView: true
                        });
                        this.options.engine.recordTutorialEvent("castle-passives", "announced", this.timeInStep, {
                            passiveId: passive.id ?? null,
                            total: passive.total ?? null,
                            delta: passive.delta ?? null
                        });
                    }
                    else {
                        this.options.hud.setTutorialMessage("Castle upgrades unlock passive buffs for regen, armor, and gold. Watch the passive list when the keep ranks up.", true);
                        this.options.engine.recordTutorialEvent("castle-passives", "announced", this.timeInStep, {
                            passiveId: null,
                            total: null,
                            delta: null
                        });
                    }
                    this.schedulePassiveAnnouncementAdvance();
                },
                onExit: () => {
                    this.clearPassiveAnnouncementTimer();
                    this.options.hud.setPassiveHighlight?.(null);
                },
                update: () => { }
            },
            "wrap-up": {
                onEnter: () => {
                    const summary = this.options.collectSummaryMetrics?.() ?? this.collectWrapUpSummary();
                    this.options.onRequestWrapUp?.(summary);
                    this.options.hud.setTutorialMessage("Tutorial complete! Review your performance and continue the campaign.", true);
                },
                update: () => { }
            }
        };
    }
    consumeLatestPassiveForAnnouncement() {
        const fromEvent = this.lastPassiveUnlocked;
        if (fromEvent) {
            this.lastPassiveUnlocked = null;
            return fromEvent;
        }
        const state = this.options.engine.getState();
        const passives = state?.castle?.passives ?? [];
        if (!Array.isArray(passives) || passives.length === 0) {
            return null;
        }
        return passives[passives.length - 1];
    }
    formatPassiveAnnouncement(passive) {
        if (!passive)
            return "Castle upgrades unlock passive buffs for regen, armor, and gold.";
        switch (passive.id) {
            case "regen": {
                const total = passive.total?.toFixed?.(1) ?? passive.total;
                const delta = passive.delta?.toFixed?.(1) ?? passive.delta;
                return `Castle regen increased to ${total} HP/s (+${delta})`;
            }
            case "armor": {
                const total = Math.round(passive.total ?? 0);
                const delta = Math.round(passive.delta ?? 0);
                return `Castle armor increased to +${total}${delta > 0 ? ` (+${delta})` : ""}`;
            }
            case "gold": {
                const total = Math.round((passive.total ?? 0) * 100);
                const delta = Math.round((passive.delta ?? 0) * 100);
                return `Bonus gold on kills is now +${total}% (+${delta}%)`;
            }
            default:
                return "Castle passive upgraded.";
        }
    }
    schedulePassiveAnnouncementAdvance() {
        this.clearPassiveAnnouncementTimer();
        this.passiveAnnouncementTimer = setTimeout(() => {
            if (!this.state.active)
                return;
            const current = this.activeStep();
            if (current?.id === "castle-passives") {
                this.completeStep("castle-passives");
            }
        }, this.getPacedMs(6000));
    }
    clearPassiveAnnouncementTimer() {
        if (this.passiveAnnouncementTimer) {
            clearTimeout(this.passiveAnnouncementTimer);
            this.passiveAnnouncementTimer = null;
        }
    }
    spawnTypedLessonEnemy(request) {
        const beforeCount = this.options.engine.getState().enemies.length;
        this.options.engine.spawnEnemy(request);
        const enemies = this.options.engine.getState().enemies;
        if (enemies.length > beforeCount) {
            this.typingEnemyId = enemies[enemies.length - 1].id;
        }
        else {
            console.warn("[tutorial] failed to spawn scripted enemy", request);
        }
    }
    spawnComboEnemy() {
        if (this.comboWordIndex >= this.comboWords.length) {
            return;
        }
        const word = this.comboWords[this.comboWordIndex];
        this.spawnTypedLessonEnemy({
            tierId: "runner",
            lane: 2,
            word,
            waveIndex: 0
        });
    }
    beginShieldLesson() {
        this.resetShieldLessonState();
        this.shieldLessonPhase = "demo";
        if (!this.shieldTurretSlotId) {
            this.shieldTurretSlotId = this.resolveShieldSlotId();
        }
        this.prepareShieldDemoTurret();
        this.setShieldTurretFiring(true);
        if (this.shieldTurretSlotId) {
            this.options.hud.showSlotMessage(this.shieldTurretSlotId, "Watch this turret strip the enemy shield.");
        }
        this.spawnShieldLessonEnemy();
    }
    endShieldLesson() {
        this.typingEnemyId = null;
        this.setShieldTurretFiring(true);
        this.resetShieldLessonState();
    }
    resetShieldLessonState() {
        this.shieldStepEnemyId = null;
        this.shieldStepShieldBroken = false;
        this.shieldStepTypingSuccess = false;
        this.shieldLessonPhase = "demo";
    }
    resolveShieldSlotId() {
        const state = this.options.engine.getState();
        const unlocked = state.turrets.filter((slot) => slot.unlocked);
        const alternate = unlocked.find((slot) => slot.id !== this.placementSlotId);
        if (alternate) {
            return alternate.id;
        }
        const configSlots = this.options.engine.config.turretSlots;
        const fallback = configSlots.find((slot) => slot.id !== this.placementSlotId);
        if (fallback) {
            return fallback.id;
        }
        return unlocked[0]?.id ?? this.placementSlotId;
    }
    prepareShieldDemoTurret() {
        if (!this.shieldTurretSlotId) {
            return;
        }
        const preState = this.options.engine.getState();
        const slot = preState.turrets.find((s) => s.id === this.shieldTurretSlotId);
        if (!slot) {
            return;
        }
        if (slot.turret) {
            return;
        }
        const goldBefore = preState.resources.gold;
        const cost = this.options.engine.config.turretArchetypes[this.shieldTurretType]?.levels[0]?.cost ?? 0;
        if (cost > 0) {
            this.ensureGold(cost);
        }
        const result = this.options.engine.placeTurret(this.shieldTurretSlotId, this.shieldTurretType);
        if (!result.success) {
            const current = this.options.engine.getState().resources.gold;
            if (current !== goldBefore) {
                this.options.engine.grantGold(goldBefore - current);
            }
            console.warn("[tutorial] failed to place shield demo turret:", result.message ?? "unknown");
            return;
        }
        const afterState = this.options.engine.getState();
        if (afterState.resources.gold < goldBefore) {
            this.options.engine.grantGold(goldBefore - afterState.resources.gold);
        }
    }
    spawnShieldLessonEnemy() {
        const slotId = this.shieldTurretSlotId ?? this.placementSlotId;
        const demoPhase = this.shieldLessonPhase === "demo";
        if (demoPhase) {
            this.setShieldTurretFiring(true);
        }
        else {
            this.setShieldTurretFiring(false);
        }
        const state = this.options.engine.getState();
        const slot = state.turrets.find((s) => s.id === slotId);
        const lane = slot?.lane ?? 0;
        const word = "bulwark";
        const beforeIds = new Set(state.enemies.map((enemy) => enemy.id));
        this.options.engine.spawnEnemy({
            tierId: "witch",
            lane,
            word,
            waveIndex: 0,
            shield: demoPhase ? { health: 40 } : undefined
        });
        const updatedEnemies = this.options.engine.getState().enemies;
        const spawned = updatedEnemies.find((enemy) => !beforeIds.has(enemy.id));
        if (!spawned) {
            console.warn("[tutorial] shield lesson failed to spawn enemy.");
            return;
        }
        this.typingEnemyId = spawned.id;
        this.shieldStepEnemyId = spawned.id;
        this.shieldStepShieldBroken = !demoPhase;
        this.shieldStepTypingSuccess = false;
        this.options.engine.recordTutorialEvent("shielded-enemy", "spawned", this.timeInStep);
        if (!demoPhase) {
            this.options.engine.recordTutorialEvent("shielded-enemy", "typing-ready", this.timeInStep);
            this.options.hud.setTutorialMessage("Shield shattered! Now finish the foe by typing the word.", true);
        }
    }
    setShieldTurretFiring(enabled) {
        if (!this.shieldTurretSlotId) {
            return;
        }
        if (typeof this.options.engine.setTurretFiringEnabled !== "function") {
            return;
        }
        this.options.engine.setTurretFiringEnabled(this.shieldTurretSlotId, enabled);
    }
    handleEventSideEffects(stepId, event) {
        if (event.type === "castle:passive-unlocked") {
            return true;
        }
        if (stepId === "shielded-enemy") {
            if (event.type === "enemy:shield-broken") {
                if (event.payload.enemyId === this.shieldStepEnemyId) {
                    this.options.engine.recordTutorialEvent("shielded-enemy", "shield-broken", this.timeInStep);
                    if (this.shieldLessonPhase === "demo") {
                        this.setShieldTurretFiring(false);
                        this.shieldLessonPhase = "typing";
                        this.spawnShieldLessonEnemy();
                    }
                    else {
                        this.shieldStepShieldBroken = true;
                        this.options.hud.setTutorialMessage("Shield shattered! Now finish the foe by typing the word.", true);
                        this.setShieldTurretFiring(false);
                    }
                    return true;
                }
            }
            if (event.type === "typing:word-complete") {
                const enemyId = event.payload?.enemyId ?? null;
                if ((enemyId === this.shieldStepEnemyId || enemyId === null) &&
                    this.shieldLessonPhase === "typing") {
                    if (!this.shieldStepShieldBroken) {
                        this.options.hud.setTutorialMessage("Hold for the turret: wait until the shield collapses, then strike.", true);
                        return true;
                    }
                    this.shieldStepTypingSuccess = true;
                    this.options.engine.recordTutorialEvent("shielded-enemy", "typed-finish", this.timeInStep);
                    return false;
                }
            }
            if (event.type === "enemy:defeated") {
                const defeatedId = event.payload?.enemyId ?? null;
                if (defeatedId === this.shieldStepEnemyId && !this.shieldStepTypingSuccess) {
                    if (this.shieldLessonPhase === "demo") {
                        return true;
                    }
                    this.options.engine.recordTutorialEvent("shielded-enemy", "retry", this.timeInStep);
                    this.shieldLessonPhase = "typing";
                    this.setShieldTurretFiring(true);
                    this.spawnShieldLessonEnemy();
                    if (this.shieldTurretSlotId) {
                        this.options.hud.showSlotMessage(this.shieldTurretSlotId, "Let the turret break the shield, then type to finish it.");
                    }
                    this.options.hud.setTutorialMessage("Try again: allow the shield to fall before you type.", true);
                    return true;
                }
            }
        }
        if (event.type === "typing:error") {
            if (stepId === "typing-basic" || stepId === "combo-diagnostics") {
                this.errorsInStep += 1;
                if (!this.assistHintShown && this.errorsInStep >= this.assistThreshold) {
                    this.assistHintShown = true;
                    this.options.engine.recordTutorialAssist();
                    this.options.engine.recordTutorialEvent(stepId, "assist:letter-hint", this.timeInStep);
                    this.options.hud.setTutorialMessage("Hint: Focus on the glowing letters. Press Backspace to clear mistakes and try again.", true);
                    return true;
                }
            }
            return false;
        }
        if (event.type === "typing:word-complete") {
            if (stepId === "combo-diagnostics") {
                this.comboWordIndex += 1;
                if (this.comboWordIndex < this.comboWords.length) {
                    this.spawnComboEnemy();
                    this.options.hud.setTutorialMessage("Great! Keep the combo going with another word.", true);
                    return true;
                }
                else {
                    this.comboCompleted = true;
                    this.options.hud.setTutorialMessage("Great accuracy! Toggle diagnostics with D to continue.", true);
                    return true;
                }
            }
        }
        return false;
    }
    reinforceStep(stepId, event) {
        if (stepId === "shielded-enemy") {
            if (event.type === "typing:word-complete") {
                if (!this.shieldStepShieldBroken) {
                    this.options.hud.setTutorialMessage("Wait for the shield to crack before typing the finishing blow.", true);
                }
                return;
            }
            if (event.type === "enemy:defeated") {
                this.options.hud.setTutorialMessage("Shielded foes need turret support—let it fall, then type to finish.", true);
                return;
            }
        }
        if (stepId === "turret-placement" && event.type === "turret:placed") {
            this.options.hud.showSlotMessage(this.placementSlotId, "Use the glowing slot with the Arrow turret");
        }
        if (stepId === "turret-upgrade" && event.type === "turret:upgraded") {
            this.options.hud.showSlotMessage(this.placementSlotId, "Upgrade the highlighted turret to level 2");
        }
        const message = this.describe(stepId);
        if (!message)
            return;
        const highlight = event.type === "castle:breach";
        this.options.hud.setTutorialMessage(message, highlight);
    }
    describe(stepId) {
        switch (stepId) {
            case "intro":
                return "Archivist Lyra: Welcome defender! Press Enter to begin the reclamation.";
            case "typing-basic":
                return "Type the highlighted word to target the approaching enemy.";
            case "combo-diagnostics":
                return "Chain hits to build your combo and watch the upcoming enemies panel light up. When you are ready, toggle diagnostics with the D key.";
            case "shielded-enemy":
                return "Some foes arrive shrouded in arcane shields. Let your turret break it, then finish the job by typing.";
            case "turret-placement":
                return "Select a glowing slot and place an Arrow turret to guard the lane.";
            case "turret-upgrade":
                return "Upgrade your turret to increase firepower against tougher foes.";
            case "castle-health":
                return "Watch the castle health bar. Letting enemies breach will damage the gate!";
            case "castle-passives":
                return "Castle upgrades unlock passive buffs (regen, armor, gold). Keep an eye on the passive list.";
            case "wrap-up":
                return "Tutorial complete! Review your performance and continue the campaign.";
            default:
                return "";
        }
    }
    getPlacementCost() {
        const archetype = this.options.engine.config.turretArchetypes[this.placementTurretType];
        return archetype?.levels[0]?.cost ?? 0;
    }
    getUpgradeCost() {
        const archetype = this.options.engine.config.turretArchetypes[this.placementTurretType];
        const levelTwo = archetype?.levels.find((level) => level.level === 2);
        return levelTwo?.cost ?? 0;
    }
    ensureGold(required) {
        if (!Number.isFinite(required) || required <= 0)
            return;
        const state = this.options.engine.getState();
        const delta = required - state.resources.gold;
        if (delta > 0) {
            this.options.engine.grantGold(delta);
        }
    }
    resolvePrimarySlotId() {
        const configSlots = this.options.engine.config.turretSlots;
        if (!Array.isArray(configSlots) || configSlots.length === 0) {
            return "slot-1";
        }
        const unlocked = configSlots.filter((slot) => slot.unlockWave === 0);
        const preferred = (unlocked.length > 0 ? unlocked : configSlots).slice().sort((a, b) => {
            if (a.lane === b.lane) {
                return a.id.localeCompare(b.id);
            }
            return a.lane - b.lane;
        });
        return preferred[0]?.id ?? configSlots[0].id;
    }
    logTransition(event, next) {
        console.info(`[tutorial] ${event}`, {
            nextStep: next ?? null,
            completed: [...this.state.completedSteps]
        });
        const active = this.activeStep();
        this.options.engine.recordTutorialEvent(active ? active.id : null, event, this.timeInStep);
        this.options.engine.events.emit("tutorial:event", {
            stepId: active ? active.id : null,
            event,
            timeInStep: this.timeInStep
        });
    }
    scheduleCastleBreach() {
        this.clearCastleBreachTimer();
        this.castleBreachTimer = setTimeout(() => {
            if (!this.state.active)
                return;
            const active = this.activeStep();
            if (!active || active.id !== "castle-health")
                return;
            const state = this.options.engine.getState();
            const damage = Math.max(10, Math.round(state.castle.maxHealth * 0.25));
            this.options.engine.damageCastle(damage);
            this.options.hud.showCastleMessage("Gate struck! Reinforce your defenses.");
            this.options.hud.setTutorialMessage("Breach! Recover quickly and rebuild before the next wave.", true);
            this.options.engine.recordTutorialEvent("castle-health", "scripted-breach", this.timeInStep);
            this.completeStep("castle-health");
        }, this.getPacedMs(1500));
    }
    clearCastleBreachTimer() {
        if (this.castleBreachTimer !== null) {
            clearTimeout(this.castleBreachTimer);
            this.castleBreachTimer = null;
        }
    }
    collectWrapUpSummary() {
        if (this.options.collectSummaryMetrics) {
            return this.options.collectSummaryMetrics();
        }
        const state = this.options.engine.getState();
        return {
            accuracy: state.typing.accuracy,
            bestCombo: state.typing.combo,
            breaches: state.analytics.sessionBreaches,
            gold: state.resources.gold
        };
    }
    setPacingMultiplier(pacing) {
        const next = this.normalizePacing(pacing);
        if (this.pacingMultiplier === next) {
            return this.pacingMultiplier;
        }
        this.pacingMultiplier = next;
        if (this.state.active) {
            const active = this.activeStep();
            if (active?.id === "castle-passives") {
                this.schedulePassiveAnnouncementAdvance();
            }
            if (active?.id === "castle-health") {
                this.scheduleCastleBreach();
            }
        }
        return this.pacingMultiplier;
    }
    normalizePacing(value) {
        const base = Number.isFinite(value) ? value : 1;
        const clamped = Math.min(1.25, Math.max(0.75, base));
        return Math.round(clamped * 100) / 100;
    }
    getPacedMs(ms) {
        const safeMs = Number.isFinite(ms) ? ms : 0;
        return Math.max(50, Math.round(safeMs / this.pacingMultiplier));
    }
}
