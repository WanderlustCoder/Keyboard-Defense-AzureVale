import { RuntimeMetrics } from "../engine/gameEngine.js";
import { CastlePassive, CastlePassiveUnlock, WaveSummary } from "../core/types.js";

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

export interface DiagnosticsSessionStats {
  bestCombo: number;
  breaches: number;
  soundEnabled: boolean;
  soundVolume: number;
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
}

export class DiagnosticsOverlay {
  private visible = true;

  constructor(private readonly container: HTMLElement) {
    this.setVisible(false);
  }

  update(metrics: RuntimeMetrics, session?: DiagnosticsSessionStats): void {
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
      `Difficulty bias: ${metrics.typing.difficultyBias >= 0 ? "+" : ""}${metrics.typing.difficultyBias.toFixed(2)}`
    ];

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
    goldLineParts.push(`events: ${metrics.goldEventCount}`);
    lines.push(goldLineParts.join(" "));

    const recentGoldEvents = Array.isArray(metrics.recentGoldEvents)
      ? metrics.recentGoldEvents
      : [];
    if (recentGoldEvents.length > 0) {
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
    }

    if (metrics.castlePassives.length > 0) {
      lines.push(
        `Castle passives (${metrics.castlePassives.length} active): ${metrics.castlePassives
          .map(describeCastlePassive)
          .join(" | ")}`
      );
    } else {
      lines.push("Castle passives: none unlocked");
    }

    lines.push(`Passive unlocks tracked: ${metrics.passiveUnlockCount}`);
    if (metrics.lastPassiveUnlock) {
      lines.push(`Last passive unlock: ${describePassiveUnlock(metrics.lastPassiveUnlock)}`);
    }

    lines.push(`Time: ${metrics.time.toFixed(1)}s`);

    if (turretStats.length > 0) {
      lines.push("Turret DPS breakdown:");
      for (const stat of turretStats) {
        const label = stat.turretType
          ? `${stat.turretType.toUpperCase()} L${stat.level ?? 1}`
          : "Empty";
        lines.push(
          `  ${stat.slotId}: ${label} - ${stat.damage.toFixed(1)} dmg | ${stat.dps.toFixed(1)} DPS`
        );
      }
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
        `Sound: ${session.soundEnabled ? "on" : "muted"} (${volumePercent}%)`,
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

    this.container.innerHTML = lines
      .map((line) => `<div class="diagnostics-line">${line}</div>`)
      .join("");
    this.container.dataset.visible = "true";
  }

  toggle(): void {
    this.setVisible(!this.visible);
  }

  setVisible(next: boolean): void {
    this.visible = next;
    this.container.dataset.visible = next ? "true" : "false";
  }

  isVisible(): boolean {
    return this.visible;
  }
}
