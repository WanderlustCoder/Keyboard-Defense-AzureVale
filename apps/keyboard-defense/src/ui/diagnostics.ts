import { type RuntimeMetrics } from "../engine/gameEngine.js";
import { type CastlePassive, type CastlePassiveUnlock, type WaveSummary } from "../core/types.js";
import type { ResolutionTransitionState } from "./ResolutionTransitionController.js";
import type { AssetIntegritySummary } from "../types/assetIntegrity.js";
import { type StarfieldParallaxState } from "../utils/starfield.js";
import { formatHudFontScale } from "./fontScale.js";

function formatRegen(passive: CastlePassive): string {
  const total = passive.total.toFixed(1);
  const delta = passive.delta > 0 ? ` (+${passive.delta.toFixed(1)})` : "";
  return `Regen ${total} HP/s${delta}`;
}

function formatArmor(passive: CastlePassive): string {
  const total = Math.round(passive.total);
  const delta = Math.round(passive.delta);
  const deltaNote = delta > 0 ? ` (+${delta})` : "";
  return `+${total} armor${deltaNote}`;
}

function formatGold(passive: CastlePassive): string {
  const total = Math.round(passive.total * 100);
  const delta = Math.round(passive.delta * 100);
  const deltaNote = delta > 0 ? ` (+${delta}%)` : "";
  return `+${total}% gold${deltaNote}`;
}

function describeCastlePassive(passive: CastlePassive): string {
  switch (passive.id) {
    case "regen":
      return formatRegen(passive);
    case "armor":
      return formatArmor(passive);
    case "gold":
      return formatGold(passive);
    default:
      return "Passive unlocked";
  }
}

function describePassiveUnlock(unlock: CastlePassiveUnlock): string {
  const description = describeCastlePassive({
    id: unlock.id,
    total: unlock.total,
    delta: unlock.delta
  });
  return `${description} @ ${unlock.time.toFixed(1)}s (castle L${unlock.level})`;
}

function formatFloat(value: number | null | undefined, digits = 2): string {
  if (typeof value !== "number" || Number.isNaN(value)) {
    return "-";
  }
  return value.toFixed(digits);
}

function formatMemory(memory?: RuntimeMetrics["memory"]): string | null {
  if (!memory || typeof memory.usedMB !== "number") {
    return null;
  }
  const parts = [`Memory: ${memory.usedMB.toFixed(1)} MB`];
  if (typeof memory.totalMB === "number") {
    parts.push(`/ ${memory.totalMB.toFixed(1)} MB`);
  }
  if (typeof memory.limitMB === "number" && memory.limitMB > 0) {
    const pct = (memory.usedMB / memory.limitMB) * 100;
    parts.push(`(cap ${memory.limitMB.toFixed(0)} MB, ${pct.toFixed(1)}%)`);
  }
  if (memory.warning) {
    parts.push("[watch]");
  }
  return parts.join(" ");
}

export interface DiagnosticsSessionStats {
  bestCombo: number;
  breaches: number;
  soundEnabled: boolean;
  soundVolume: number;
  soundIntensity: number;
  hudFontScale?: number;
  summaryCount: number;
  lastSummary?: WaveSummary;
  totalTurretDamage?: number;
  totalTypingDamage?: number;
  shieldedNow?: boolean;
  shieldedNext?: boolean;
  totalRepairs?: number;
  totalRepairHealth?: number;
  totalRepairGold?: number;
  timeToFirstTurretSeconds?: number | null;
  totalReactionTime?: number;
  reactionSamples?: number;
  assetIntegrity?: AssetIntegritySummary | null;
  lastCanvasResizeCause?: string | null;
  starfield?: StarfieldParallaxState | null;
}

const COLLAPSIBLE_SECTIONS = ["gold-events", "castle-passives", "turret-dps"] as const;
type DiagnosticsSectionId = (typeof COLLAPSIBLE_SECTIONS)[number];

const SECTION_LABELS: Record<DiagnosticsSectionId, string> = {
  "gold-events": "Gold events",
  "castle-passives": "Castle passives",
  "turret-dps": "Turret DPS"
};

type DiagnosticsSectionPreferences = Partial<Record<DiagnosticsSectionId, boolean>>;

interface DiagnosticsOverlayOptions {
  sectionPreferences?: DiagnosticsSectionPreferences;
  onPreferencesChange?: (prefs: DiagnosticsSectionPreferences) => void;
}

export class DiagnosticsOverlay {
  private visible = true;
  private condensed = false;
  private sectionsCollapsed = true;
  private collapseToggle?: HTMLButtonElement | null;
  private lastMetrics: RuntimeMetrics | null = null;
  private lastSession?: DiagnosticsSessionStats;
  private sectionCollapsed: DiagnosticsSectionPreferences = {};
  private controlsRoot: HTMLDivElement | null = null;
  private linesRoot: HTMLDivElement | null = null;
  private readonly onPreferencesChange?: (prefs: DiagnosticsSectionPreferences) => void;
  private canvasTransitionState: ResolutionTransitionState = "idle";

  constructor(
    private readonly container: HTMLElement,
    options: DiagnosticsOverlayOptions = {}
  ) {
    this.sectionCollapsed = { ...(options.sectionPreferences ?? {}) };
    this.onPreferencesChange = options.onPreferencesChange;
    this.setVisible(false);
    this.setupRoots();
    this.initializeResponsiveBehavior();
    this.syncCollapseToggle();
    this.renderSectionControls();
    this.updateCollapseButton();
    this.container.dataset.canvasTransition = this.container.dataset.canvasTransition ?? "idle";
  }

  update(metrics: RuntimeMetrics, session?: DiagnosticsSessionStats): void {
    this.lastMetrics = metrics;
    this.lastSession = session;
    if (!this.visible) {
      this.setVisible(false);
      return;
    }

    const difficulty = metrics.difficulty;
    const wave = metrics.wave;
    const waveCountdown = wave.inCountdown ? ` (prep ${wave.countdown.toFixed(1)}s)` : "";
    const modeSuffix = metrics.mode === "practice" ? " (Practice)" : "";

    const easy = (difficulty.wordWeights.easy ?? 0) * 100;
    const medium = (difficulty.wordWeights.medium ?? 0) * 100;
    const hard = (difficulty.wordWeights.hard ?? 0) * 100;

    const turretStats = metrics.turretStats ?? [];
    const goldEventCount = typeof metrics.goldEventCount === "number" ? metrics.goldEventCount : 0;
    const castlePassives = Array.isArray(metrics.castlePassives) ? metrics.castlePassives : [];
    const passiveUnlockCount =
      typeof metrics.passiveUnlockCount === "number" ? metrics.passiveUnlockCount : castlePassives.length;
    const lastPassiveUnlock = metrics.lastPassiveUnlock ?? null;
    const castleVisual = metrics.castleVisual ?? null;
    const memoryLine = formatMemory(metrics.memory);

    const lines = [
      `Wave: ${wave.index + 1}/${wave.total}${modeSuffix}${waveCountdown}`,
      metrics.mode === "practice" ? "Mode: Practice - waves loop endlessly" : "Mode: Campaign",
      `Difficulty band >= wave ${difficulty.fromWave}`,
      `Enemy HP x${difficulty.enemyHealthMultiplier.toFixed(2)} | Speed x${difficulty.enemySpeedMultiplier.toFixed(
        2
      )}`,
      `Reward x${difficulty.rewardMultiplier.toFixed(2)}`,
      `Wave threat rating: ${metrics.difficultyRating}`,
      `Words: easy ${easy.toFixed(0)}% | medium ${medium.toFixed(0)}% | hard ${hard.toFixed(0)}%`,
      `Projectiles: ${metrics.projectiles}`,
      `Enemies alive: ${metrics.enemiesAlive}`,
      castleVisual
        ? `Castle: L${castleVisual.level} sprite ${castleVisual.spriteKey}`
        : "Castle: visual unknown",
      `Combo: x${metrics.combo}`,
      `Wave damage (turret/typing/total): ${metrics.damage.turret.toFixed(1)} / ${metrics.damage.typing.toFixed(
        1
      )} / ${metrics.damage.total.toFixed(1)}`,
      `Typing accuracy: ${(metrics.typing.accuracy * 100).toFixed(1)}% (${
        metrics.typing.correctInputs
      }/${metrics.typing.totalInputs})`,
      `Rolling accuracy (${metrics.typing.recentSampleSize} inputs): ${(
        metrics.typing.recentAccuracy * 100
      ).toFixed(1)}%`,
      `Difficulty bias: ${
        metrics.typing.difficultyBias >= 0 ? "+" : ""
      }${metrics.typing.difficultyBias.toFixed(2)}`
    ];
    if (memoryLine) {
      lines.push(memoryLine);
    }
    const defeatStats = metrics.defeatBursts;
    if (defeatStats) {
      const perMinuteLabel = formatFloat(defeatStats.perMinute, 2);
      const spritePctLabel = formatFloat(defeatStats.spriteUsagePct, 1);
      lines.push(
        `Defeat bursts: ${defeatStats.total} total (${perMinuteLabel}/min, sprite ${spritePctLabel}%)`
      );
      if (
        typeof defeatStats.lastTimestamp === "number" ||
        typeof defeatStats.lastEnemyType === "string"
      ) {
        const laneLabel =
          typeof defeatStats.lastLane === "number"
            ? `lane ${defeatStats.lastLane + 1}`
            : "lane ?";
        const ageLabel =
          typeof defeatStats.lastAgeSeconds === "number"
            ? `${defeatStats.lastAgeSeconds.toFixed(1)}s ago`
            : "n/a";
        const idleAlert =
          typeof defeatStats.lastAgeSeconds === "number" &&
          defeatStats.lastAgeSeconds > 15 &&
          metrics.enemiesAlive > 0
            ? " ⚠️ idle"
            : "";
        lines.push(
          `  Last: ${defeatStats.lastEnemyType ?? "unknown"} @ ${laneLabel} (${defeatStats.lastMode ?? "procedural"}, ${ageLabel})${idleAlert}`
        );
      }
    }
    const starfield = session?.starfield ?? null;
    if (starfield) {
      lines.push(
        `Starfield: drift ${formatFloat(starfield.driftMultiplier, 2)}x | depth ${formatFloat(
          starfield.depth,
          2
        )} | tint ${starfield.tint}${starfield.reducedMotionApplied ? " (reduced motion)" : ""}`
      );
      lines.push(
        `  Wave ${Math.round(starfield.waveProgress * 100)}% · Castle HP ${Math.round(
          starfield.castleHealthRatio * 100
        )}% · Severity ${Math.round((starfield.severity ?? 0) * 100)}%`
      );
      if (Array.isArray(starfield.layers) && starfield.layers.length > 0) {
        const layerNotes = starfield.layers
          .slice(0, 3)
          .map((layer) => {
            const dir = layer.direction === 1 ? "→" : "←";
            return `${layer.id}:${formatFloat(layer.velocity, 3)}${dir}`;
          })
          .join(" | ");
        lines.push(`  Layers: ${layerNotes}`);
      }
    }
    const lastCanvasResizeCause = session?.lastCanvasResizeCause ?? null;
    if (lastCanvasResizeCause) {
      lines.push(`Last canvas resize: ${lastCanvasResizeCause}`);
    }
    const assetIntegrity = session?.assetIntegrity ?? null;
    if (assetIntegrity) {
      const strictLabel = assetIntegrity.strictMode ? "strict" : "soft";
      const statusLabel = (assetIntegrity.status ?? "pending").toUpperCase();
      const totalImages =
        typeof assetIntegrity.totalImages === "number"
          ? assetIntegrity.totalImages
          : assetIntegrity.checked ?? 0;
      const issues: string[] = [];
      if ((assetIntegrity.missingHash ?? 0) > 0) {
        issues.push(`missing ${assetIntegrity.missingHash}`);
      }
      if ((assetIntegrity.failed ?? 0) > 0) {
        issues.push(`failed ${assetIntegrity.failed}`);
      }
      const issueLabel = issues.length > 0 ? ` | ${issues.join(" | ")}` : "";
      lines.unshift(
        `Asset integrity: ${statusLabel} (${strictLabel}) - checked ${assetIntegrity.checked ?? 0}/${totalImages}${issueLabel}`
      );
      if (assetIntegrity.firstFailure) {
        const failure = assetIntegrity.firstFailure;
        const pathLabel =
          failure.path && failure.path !== failure.key ? `${failure.path} (${failure.key})` : failure.key;
        lines.splice(1, 0, `  First issue: ${pathLabel ?? "unknown"} [${failure.type}]`);
      }
    } else {
      lines.unshift(
        "Asset integrity: telemetry unavailable (run npm run assets:integrity -- --check)"
      );
    }

    const roundedGold = Math.round(metrics.gold);
    const goldLineParts = [`Gold: ${roundedGold}`];
    if (typeof metrics.goldDelta === "number" && metrics.goldDelta !== 0) {
      const deltaRounded = Math.round(metrics.goldDelta);
      const goldDeltaLabel = `${deltaRounded > 0 ? "+" : ""}${deltaRounded}g`;
      goldLineParts.push(goldDeltaLabel);
    }
    if (typeof metrics.goldEventTimestamp === "number") {
      goldLineParts.push(`@ ${metrics.goldEventTimestamp.toFixed(1)}s`);
    }
    goldLineParts.push(`events: ${goldEventCount}`);
    lines.push(goldLineParts.join(" "));

    const showGoldEvents = this.shouldShowSection("gold-events");
    const showTurretStats = this.shouldShowSection("turret-dps");
    const showCastlePassives = this.shouldShowSection("castle-passives");
    const recentGoldEvents = Array.isArray(metrics.recentGoldEvents)
      ? metrics.recentGoldEvents
      : [];
    if (recentGoldEvents.length > 0 && showGoldEvents) {
      lines.push("Recent gold events:");
      const orderedEvents = [...recentGoldEvents].sort((a, b) => b.timestamp - a.timestamp);
      for (const event of orderedEvents) {
        const deltaRounded = Math.round(event.delta);
        const deltaLabel = `${deltaRounded >= 0 ? "+" : ""}${deltaRounded}g`;
        const totalGold = Math.round(event.gold);
        const timestamp = typeof event.timestamp === "number" ? event.timestamp : 0;
        const secondsAgo = Math.max(0, metrics.time - timestamp);
        const agoLabel = secondsAgo > 0 ? ` (${secondsAgo.toFixed(1)}s ago)` : "";
        lines.push(`  ${deltaLabel} -> ${totalGold}g @ ${timestamp.toFixed(1)}s${agoLabel}`);
      }
    } else if (recentGoldEvents.length > 0) {
      const latest = recentGoldEvents.at(-1)!;
      const deltaRounded = Math.round(latest.delta);
      const deltaLabel = `${deltaRounded >= 0 ? "+" : ""}${deltaRounded}g`;
      lines.push(
        `Recent gold events: latest ${deltaLabel} -> ${Math.round(
          latest.gold
        )}g (collapsed, tap expand to view)`
      );
    }

    if (castlePassives.length > 0) {
      if (showCastlePassives) {
        lines.push(
          `Castle passives (${castlePassives.length} active): ${castlePassives
            .map(describeCastlePassive)
            .join(" | ")}`
        );
      } else {
        lines.push(
          `Castle passives (${castlePassives.length} active) (collapsed, expand to view details)`
        );
      }
    } else {
      lines.push("Castle passives: none unlocked");
    }

    lines.push(`Passive unlocks tracked: ${passiveUnlockCount}`);
    if (lastPassiveUnlock) {
      lines.push(`Last passive unlock: ${describePassiveUnlock(lastPassiveUnlock)}`);
    }

    lines.push(`Time: ${metrics.time.toFixed(1)}s`);

    if (turretStats.length > 0 && showTurretStats) {
      lines.push("Turret DPS breakdown:");
      for (const stat of turretStats) {
        const label = stat.turretType
          ? `${stat.turretType.toUpperCase()} L${stat.level ?? 1}`
          : "Empty";
        lines.push(
          `  ${stat.slotId}: ${label} - ${stat.damage.toFixed(1)} dmg | ${stat.dps.toFixed(1)} DPS`
        );
      }
    } else if (turretStats.length > 0) {
      const top =
        turretStats.reduce((prev, current) => (current.dps > prev.dps ? current : prev), turretStats[0]) ??
        null;
      const label = top?.turretType ? `${top.turretType.toUpperCase()} L${top.level ?? 1}` : "slot";
      lines.push(
        `Turret DPS: ${turretStats.length} tracked, top ${label} ${top?.dps.toFixed(
          1
        )} DPS (collapsed)`
      );
    }

    if (session) {
      const totalTurret = Math.max(0, Math.round(session.totalTurretDamage ?? 0));
      const totalTyping = Math.max(0, Math.round(session.totalTypingDamage ?? 0));
      const totalRepairs = Math.max(0, Math.floor(session.totalRepairs ?? 0));
      const totalRepairHealth = Math.max(0, Math.round(session.totalRepairHealth ?? 0));
      const totalRepairGold = Math.max(0, Math.round(session.totalRepairGold ?? 0));
      const volumePercent = Math.max(
        0,
        Math.min(100, Math.round((session.soundVolume ?? 0) * 100))
      );
      const intensityPercent = Math.max(
        0,
        Math.min(150, Math.round((session.soundIntensity ?? 0) * 100))
      );
      const fontScaleDescription = formatHudFontScale(session.hudFontScale ?? 1);
      const timeToFirstTurretSeconds =
        typeof session.timeToFirstTurretSeconds === "number"
          ? session.timeToFirstTurretSeconds
          : (session.timeToFirstTurretSeconds ?? null);
      const totalReactionTime = Math.max(0, session.totalReactionTime ?? 0);
      const reactionSamples = Math.max(0, Math.floor(session.reactionSamples ?? 0));
      const averageReaction = reactionSamples > 0 ? totalReactionTime / reactionSamples : null;
      lines.push(
        `Session best combo: x${session.bestCombo}`,
        `Breaches: ${session.breaches}`,
        `Sound: ${session.soundEnabled ? "on" : "muted"} (volume ${volumePercent}%, intensity ${intensityPercent}%)`,
        `HUD font size: ${fontScaleDescription}`,
        `Wave summaries tracked: ${session.summaryCount}`,
        `Shielded enemies: ${session.shieldedNow ? "ACTIVE" : "none"}${
          session.shieldedNext ? " | next wave" : ""
        }`,
        `Session damage (turret/typing): ${totalTurret} / ${totalTyping}`,
        `Castle repairs: ${totalRepairs} | HP restored ${totalRepairHealth} | Gold spent ${totalRepairGold}g`
      );
      if (timeToFirstTurretSeconds !== null) {
        lines.push(`First turret deployed at ${timeToFirstTurretSeconds.toFixed(1)}s`);
      } else {
        lines.push("First turret not yet deployed");
      }
      if (averageReaction !== null) {
        lines.push(`Average reaction: ${averageReaction.toFixed(2)}s (${reactionSamples} samples)`);
      } else {
        lines.push("Average reaction: n/a (0 samples)");
      }
      if (session.lastSummary) {
        const last = session.lastSummary;
        const goldValue = Math.round(last.goldEarned ?? 0);
        const goldNote = `${goldValue >= 0 ? "+" : ""}${goldValue}g`;
        const turretDamage = Math.round(last.turretDamage ?? 0);
        const typingDamage = Math.round(last.typingDamage ?? 0);
        const turretDpsStr = (last.turretDps ?? 0).toFixed(1);
        const typingDpsStr = (last.typingDps ?? 0).toFixed(1);
        const averageReactionNote =
          typeof last.averageReaction === "number" && last.averageReaction > 0
            ? ` | avg reaction ${last.averageReaction.toFixed(2)}s`
            : "";
        lines.push(
          `Last wave ${last.index + 1}: ${last.enemiesDefeated} defeats, ${(
            last.accuracy * 100
          ).toFixed(
            1
          )}% accuracy, ${last.breaches} breaches, DPS ${last.dps.toFixed(1)}, ${goldNote}${averageReactionNote}`
        );
        lines.push(
          `  Damage (turret/typing): ${turretDamage} / ${typingDamage} | DPS T/T: ${turretDpsStr} / ${typingDpsStr}`
        );
      }
    }

    const target = this.linesRoot ?? this.container;
    target.innerHTML = lines
      .map((line) => `<div class="diagnostics-line">${line}</div>`)
      .join("");
    this.container.dataset.visible = "true";
    this.updateCollapseButton();
    this.renderSectionControls();
  }

  setCanvasTransitionState(state: ResolutionTransitionState): void {
    if (this.canvasTransitionState === state) return;
    this.canvasTransitionState = state;
    this.container.dataset.canvasTransition = state;
  }

  getCondensedState(): {
    condensed: boolean;
    sectionsCollapsed: boolean;
    collapsedSections: DiagnosticsSectionPreferences;
  } {
    return {
      condensed: this.condensed,
      sectionsCollapsed: this.sectionsCollapsed,
      collapsedSections: { ...this.sectionCollapsed }
    };
  }

  applySectionPreferences(
    preferences: DiagnosticsSectionPreferences,
    options: { silent?: boolean } = {}
  ): void {
    this.sectionCollapsed = { ...this.sectionCollapsed, ...preferences };
    this.updateSectionsCollapsedFlag();
    if (!options.silent) {
      this.emitSectionPreferences();
    }
    if (this.lastMetrics) {
      this.update(this.lastMetrics, this.lastSession);
    } else {
      this.renderSectionControls();
    }
  }

  toggle(): void {
    this.setVisible(!this.visible);
  }

  private shouldShowSection(sectionId: DiagnosticsSectionId): boolean {
    if (!this.condensed) {
      return true;
    }
    return this.sectionCollapsed[sectionId] !== true;
  }

  private isSectionCollapsed(sectionId: DiagnosticsSectionId): boolean {
    return this.sectionCollapsed[sectionId] !== false;
  }

  private setSectionCollapsed(
    sectionId: DiagnosticsSectionId,
    collapsed: boolean,
    options: { userInitiated?: boolean } = {}
  ): void {
    const next = collapsed ? true : false;
    if (this.sectionCollapsed[sectionId] === next) {
      return;
    }
    this.sectionCollapsed[sectionId] = next;
    this.updateSectionsCollapsedFlag();
    if (options.userInitiated) {
      this.emitSectionPreferences();
    }
    if (this.lastMetrics) {
      this.update(this.lastMetrics, this.lastSession);
    }
  }

  private collapseAllSections(): void {
    for (const sectionId of COLLAPSIBLE_SECTIONS) {
      this.sectionCollapsed[sectionId] = true;
    }
    this.updateSectionsCollapsedFlag();
    this.emitSectionPreferences();
    if (this.lastMetrics) {
      this.update(this.lastMetrics, this.lastSession);
    }
  }

  private expandAllSections(): void {
    for (const sectionId of COLLAPSIBLE_SECTIONS) {
      this.sectionCollapsed[sectionId] = false;
    }
    this.updateSectionsCollapsedFlag();
    this.emitSectionPreferences();
    if (this.lastMetrics) {
      this.update(this.lastMetrics, this.lastSession);
    }
  }

  private areAllSectionsCollapsed(): boolean {
    return COLLAPSIBLE_SECTIONS.every((sectionId) => this.sectionCollapsed[sectionId] !== false);
  }

  private emitSectionPreferences(): void {
    if (typeof this.onPreferencesChange === "function") {
      const clone: DiagnosticsSectionPreferences = {};
      for (const sectionId of COLLAPSIBLE_SECTIONS) {
        if (this.sectionCollapsed[sectionId] !== undefined) {
          clone[sectionId] = this.sectionCollapsed[sectionId];
        }
      }
      this.onPreferencesChange(clone);
    }
    this.renderSectionControls();
  }

  private updateSectionsCollapsedFlag(): void {
    this.sectionsCollapsed = this.areAllSectionsCollapsed();
    this.syncAutomationFlags();
  }

  setVisible(next: boolean): void {
    this.visible = next;
    this.container.dataset.visible = next ? "true" : "false";
  }

  isVisible(): boolean {
    return this.visible;
  }

  private initializeResponsiveBehavior(): void {
    const apply = () => this.applyCondensedState(this.shouldCondense());
    apply();
    if (typeof window === "undefined") {
      return;
    }
    const queries = ["(max-height: 540px)", "(max-width: 720px)"];
    if (typeof window.matchMedia === "function") {
      for (const query of queries) {
        try {
          const matcher = window.matchMedia(query);
          if (typeof matcher.addEventListener === "function") {
            matcher.addEventListener("change", apply);
          } else if (typeof matcher.addListener === "function") {
            matcher.addListener(apply);
          }
        } catch {
          // ignore matchMedia failures
        }
      }
    }
    try {
      window.addEventListener("resize", apply, { passive: true });
    } catch {
      window.addEventListener("resize", apply);
    }
  }

  private applyCondensedState(condensed: boolean): void {
    this.condensed = condensed;
    if (condensed) {
      this.container.dataset.condensed = "true";
      for (const sectionId of COLLAPSIBLE_SECTIONS) {
        if (this.sectionCollapsed[sectionId] === undefined) {
          this.sectionCollapsed[sectionId] = true;
        }
      }
    } else {
      delete this.container.dataset.condensed;
    }
    this.updateSectionsCollapsedFlag();
    this.syncCollapseToggle();
    this.renderSectionControls();
    this.updateCollapseButton();
  }

  private shouldCondense(): boolean {
    return (
      this.matchesMediaQuery("(max-height: 540px)") ||
      this.matchesMediaQuery("(max-width: 720px)")
    );
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

  private syncCollapseToggle(): void {
    if (typeof document === "undefined") return;
    if (!this.condensed) {
      this.removeCollapseToggle();
      return;
    }
    if (!this.collapseToggle) {
      this.collapseToggle = document.createElement("button");
      this.collapseToggle.id = "diagnostics-collapse-toggle";
      this.collapseToggle.type = "button";
      document.body.appendChild(this.collapseToggle);
      this.collapseToggle.addEventListener("click", () => {
        if (this.areAllSectionsCollapsed()) {
          this.expandAllSections();
        } else {
          this.collapseAllSections();
        }
      });
    }
    this.collapseToggle.dataset.visible = "true";
  }

  private removeCollapseToggle(): void {
    if (this.collapseToggle) {
      this.collapseToggle.remove();
      this.collapseToggle = null;
    }
  }

  private updateCollapseButton(): void {
    if (!this.collapseToggle || !this.condensed) {
      this.syncAutomationFlags();
      return;
    }
    const expanded = !this.areAllSectionsCollapsed();
    this.collapseToggle.textContent = expanded
      ? "Collapse diagnostics details"
      : "Expand diagnostics details";
    this.collapseToggle.setAttribute("aria-expanded", expanded ? "true" : "false");
    this.syncAutomationFlags();
  }

  private syncAutomationFlags(): void {
    if (typeof document === "undefined" || !document.body) return;
    if (!this.condensed) {
      delete document.body.dataset.diagnosticsCondensed;
      delete document.body.dataset.diagnosticsSectionsCollapsed;
      return;
    }
    document.body.dataset.diagnosticsCondensed = "true";
    document.body.dataset.diagnosticsSectionsCollapsed = this.areAllSectionsCollapsed()
      ? "true"
      : "false";
  }

  private setupRoots(): void {
    if (typeof document === "undefined") {
      this.controlsRoot = null;
      this.linesRoot = null;
      return;
    }
    this.container.innerHTML = "";
    this.controlsRoot = document.createElement("div");
    this.controlsRoot.id = "diagnostics-section-controls";
    this.controlsRoot.dataset.visible = "false";
    this.controlsRoot.addEventListener("click", (event) => this.handleControlsClick(event));
    this.container.appendChild(this.controlsRoot);

    this.linesRoot = document.createElement("div");
    this.linesRoot.className = "diagnostics-lines";
    this.container.appendChild(this.linesRoot);
  }

  private handleControlsClick(event: Event): void {
    const target = event.target;
    if (!(target instanceof HTMLElement)) {
      return;
    }
    const action = target.dataset.action;
    if (action === "expand-all") {
      this.expandAllSections();
      return;
    }
    if (action === "collapse-all") {
      this.collapseAllSections();
      return;
    }
    const sectionId = target.dataset.section as DiagnosticsSectionId | undefined;
    if (!sectionId) {
      return;
    }
    const currentlyCollapsed = this.isSectionCollapsed(sectionId);
    this.setSectionCollapsed(sectionId, !currentlyCollapsed, { userInitiated: true });
  }

  private renderSectionControls(): void {
    if (!this.controlsRoot) {
      return;
    }
    if (!this.condensed) {
      this.controlsRoot.dataset.visible = "false";
      this.controlsRoot.innerHTML = "";
      return;
    }
    this.controlsRoot.dataset.visible = "true";
    const controls: string[] = [];
    controls.push(
      `<button type="button" data-action="expand-all" class="diagnostics-control-button">Expand all</button>`
    );
    controls.push(
      `<button type="button" data-action="collapse-all" class="diagnostics-control-button">Collapse all</button>`
    );
    for (const sectionId of COLLAPSIBLE_SECTIONS) {
      const collapsed = this.isSectionCollapsed(sectionId);
      const label = SECTION_LABELS[sectionId];
      controls.push(
        `<button type="button" class="diagnostics-control-button" data-section="${sectionId}" aria-pressed="${collapsed ? "false" : "true"}">${
          collapsed ? "Show" : "Hide"
        } ${label}</button>`
      );
    }
    this.controlsRoot.innerHTML = `<div class="diagnostics-controls-inner">${controls.join(
      ""
    )}</div>`;
  }
}
