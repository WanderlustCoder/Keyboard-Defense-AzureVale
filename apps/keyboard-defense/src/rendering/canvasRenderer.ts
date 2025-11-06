import { GameConfig } from "../core/config.js";
import { GameState, TurretTypeId, EnemyState, EnemyStatus } from "../core/types.js";
import { AssetLoader } from "../assets/assetLoader.js";
import { SpriteRenderer } from "./spriteRenderer.js";
import { resolveLetterColors, WordHighlightPalette } from "./wordHighlighter.js";

const PROJECTILE_COLORS: Record<TurretTypeId, string> = {
  arrow: "#38bdf8",
  arcane: "#a855f7",
  flame: "#fb923c",
  crystal: "#67e8f9"
};

interface TurretRangeRenderOptions {
  slotId: string;
  typeId?: TurretTypeId;
  level?: number;
}

export interface ImpactEffectRender {
  lane: number | null;
  position: number;
  age: number; // 0 -> fresh, 1 -> expired
  kind: "hit" | "breach" | "muzzle";
  slotId?: string | null;
  turretType?: TurretTypeId | null;
}

export class CanvasRenderer {
  private readonly ctx: CanvasRenderingContext2D;
  private readonly width: number;
  private readonly height: number;
  private readonly pathLength: number;
  private readonly laneCount: number;
  private readonly spriteRenderer: SpriteRenderer;
  private static readonly DEFEAT_BURST_DURATION = 0.6;
  private reducedMotion = false;
  private checkeredBackground = false;
  private cachedCheckeredPattern: CanvasPattern | null = null;
  private defeatBursts: DefeatBurst[] = [];
  private lastEnemyStatuses = new Map<string, EnemyStatus>();

  constructor(
    private readonly canvas: HTMLCanvasElement,
    private readonly config: GameConfig,
    assetLoader?: AssetLoader
  ) {
    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("Unable to acquire 2d context.");
    this.ctx = ctx;
    this.width = canvas.width;
    this.height = canvas.height;
    this.pathLength = this.width * 0.7;
    this.laneCount = Math.max(...config.turretSlots.map((s) => s.lane)) + 1;
    this.spriteRenderer = new SpriteRenderer(assetLoader);
  }

  render(
    state: GameState,
    impactEffects: ImpactEffectRender[] = [],
    options?: {
      reducedMotion?: boolean;
      checkeredBackground?: boolean;
      turretRange?: TurretRangeRenderOptions | null;
    }
  ): void {
    this.reducedMotion = Boolean(options?.reducedMotion);
    const nextCheckered = Boolean(options?.checkeredBackground);
    if (nextCheckered !== this.checkeredBackground) {
      this.cachedCheckeredPattern = null;
    }
    this.checkeredBackground = nextCheckered;
    this.spriteRenderer.setColorBlindFriendly(this.checkeredBackground);
    this.updateDefeatBursts(state);
    this.clear();
    this.drawBackground();
    this.drawLanes();
    this.drawTurretRangeHighlight(state, options?.turretRange ?? null);
    this.drawTurretSlots(state);
    this.drawEnemies(state);
    this.drawDefeatBursts(state);
    this.drawProjectiles(state);
    this.drawImpactEffects(state, impactEffects);
    this.drawCastle(state);
    this.drawStatus(state);
  }

  private clear(): void {
    this.ctx.clearRect(0, 0, this.width, this.height);
  }

  private drawBackground(): void {
    if (this.checkeredBackground) {
      const pattern = this.getCheckeredPattern();
      if (pattern) {
        this.ctx.fillStyle = pattern;
        this.ctx.fillRect(0, 0, this.width, this.height);
        return;
      }
    }

    const gradient = this.ctx.createLinearGradient(0, 0, this.width, this.height);
    gradient.addColorStop(0, "#111827");
    gradient.addColorStop(1, "#1f2937");
    this.ctx.fillStyle = gradient;
    this.ctx.fillRect(0, 0, this.width, this.height);
  }

  private getCheckeredPattern(): CanvasPattern | null {
    if (this.cachedCheckeredPattern) {
      return this.cachedCheckeredPattern;
    }

    const size = 32;
    const patternCanvas = document.createElement("canvas");
    patternCanvas.width = size;
    patternCanvas.height = size;
    const pctx = patternCanvas.getContext("2d");
    if (!pctx) {
      return null;
    }

    pctx.fillStyle = "#1e293b";
    pctx.fillRect(0, 0, size, size);

    pctx.fillStyle = "#0f172a";
    pctx.fillRect(0, 0, size / 2, size / 2);
    pctx.fillRect(size / 2, size / 2, size / 2, size / 2);

    pctx.fillStyle = "rgba(226, 232, 240, 0.08)";
    pctx.fillRect(0, size / 2, size / 2, size / 2);
    pctx.fillRect(size / 2, 0, size / 2, size / 2);

    const pattern = this.ctx.createPattern(patternCanvas, "repeat");
    this.cachedCheckeredPattern = pattern;
    return pattern;
  }

  private drawLanes(): void {
    const margin = this.height * 0.15;
    this.ctx.strokeStyle = this.checkeredBackground
      ? "rgba(226, 232, 240, 0.35)"
      : "rgba(148, 163, 184, 0.25)";
    this.ctx.lineWidth = this.checkeredBackground ? 2.5 : 2;
    for (let lane = 0; lane < this.laneCount; lane++) {
      const y = this.laneY(lane, margin);
      this.ctx.beginPath();
      this.ctx.moveTo(this.width * 0.1, y);
      this.ctx.lineTo(this.width * 0.85, y);
      this.ctx.stroke();
    }
  }

  private drawTurretSlots(state: GameState): void {
    const slotSize = 24;
    for (const slot of state.turrets) {
      const x = this.width * slot.position.x;
      const y = this.height * slot.position.y;

      this.ctx.fillStyle = slot.unlocked
        ? this.checkeredBackground
          ? "rgba(226, 232, 240, 0.45)"
          : "rgba(148, 163, 184, 0.4)"
        : this.checkeredBackground
          ? "rgba(30, 41, 59, 0.6)"
          : "rgba(71, 85, 105, 0.3)";
      this.ctx.beginPath();
      this.ctx.arc(x, y, slotSize / 2, 0, Math.PI * 2);
      this.ctx.fill();

      if (slot.turret) {
        this.spriteRenderer.drawTurret(this.ctx, slot, x, y, slotSize / 2);
      }
    }
  }

  private drawTurretRangeHighlight(
    state: GameState,
    highlight: TurretRangeRenderOptions | null
  ): void {
    if (!highlight) {
      return;
    }
    const slot = state.turrets.find((s) => s.id === highlight.slotId);
    if (!slot || !slot.unlocked) {
      return;
    }
    const typeId = highlight.typeId ?? slot.turret?.typeId;
    if (!typeId) {
      return;
    }
    const archetype = this.config.turretArchetypes[typeId];
    if (!archetype) {
      return;
    }
    const level = highlight.level ?? slot.turret?.level ?? 1;
    const levelConfig =
      archetype.levels.find((entry) => entry.level === level) ?? archetype.levels[0];
    if (!levelConfig || typeof levelConfig.range !== "number" || levelConfig.range <= 0) {
      return;
    }
    const range = Math.max(0, Math.min(1, levelConfig.range));
    const minDistance = Math.max(0, 1 - range);
    const baseX = this.width * 0.1;
    const startX = baseX + minDistance * this.pathLength;
    const endX = baseX + this.pathLength;
    if (!(endX > startX)) {
      return;
    }
    const laneY = this.laneY(slot.lane);
    const margin = this.height * 0.15;
    const span = this.height - margin * 2;
    const spacing = this.laneCount > 1 ? span / Math.max(1, this.laneCount - 1) : span;
    const halfHeight = Math.max(18, Math.min(36, spacing * 0.35));
    const rectTop = laneY - halfHeight;
    const rectHeight = halfHeight * 2;
    const color = PROJECTILE_COLORS[typeId] ?? "#60a5fa";
    this.ctx.save();
    this.ctx.fillStyle = this.withAlpha(color, 0.18);
    this.ctx.fillRect(startX, rectTop, endX - startX, rectHeight);
    this.ctx.strokeStyle = this.withAlpha(color, 0.55);
    this.ctx.lineWidth = 2;
    this.ctx.setLineDash([10, 6]);
    this.ctx.strokeRect(startX, rectTop, endX - startX, rectHeight);
    this.ctx.setLineDash([]);
    const turretX = this.width * slot.position.x;
    this.ctx.beginPath();
    this.ctx.strokeStyle = this.withAlpha(color, 0.9);
    this.ctx.lineWidth = 2;
    this.ctx.arc(turretX, laneY, 24, 0, Math.PI * 2);
    this.ctx.stroke();
    this.ctx.restore();
  }

  private withAlpha(hex: string, alpha: number): string {
    const sanitized = hex.replace("#", "");
    const parse = (input: string) => Number.parseInt(input, 16);
    let r: number;
    let g: number;
    let b: number;
    if (sanitized.length === 3) {
      r = parse(sanitized[0] + sanitized[0]);
      g = parse(sanitized[1] + sanitized[1]);
      b = parse(sanitized[2] + sanitized[2]);
    } else {
      r = parse(sanitized.slice(0, 2));
      g = parse(sanitized.slice(2, 4));
      b = parse(sanitized.slice(4, 6));
    }
    const clampedAlpha = Math.max(0, Math.min(1, alpha));
    return `rgba(${r}, ${g}, ${b}, ${clampedAlpha})`;
  }

  private drawEnemies(state: GameState): void {
    const baseX = this.width * 0.1;
    for (const enemy of state.enemies) {
      if (enemy.status !== "alive") continue;
      const laneY = this.laneY(enemy.lane);
      const x = baseX + enemy.distance * this.pathLength;
      const radius = 18;
      const shieldState = enemy.shield && enemy.shield.current > 0 ? enemy.shield : null;

      this.spriteRenderer.drawEnemy(this.ctx, enemy, x, laneY, radius);

      if (shieldState) {
        const maxShield = Math.max(shieldState.max ?? shieldState.current, 1);
        const shieldRatio = Math.max(0, Math.min(1, shieldState.current / maxShield));

        if (!this.reducedMotion) {
          const glow = this.ctx.createRadialGradient(x, laneY, radius, x, laneY, radius + 24);
          glow.addColorStop(0, "rgba(165, 180, 252, 0.28)");
          glow.addColorStop(1, "rgba(165, 180, 252, 0)");
          this.ctx.fillStyle = glow;
          this.ctx.beginPath();
          this.ctx.arc(x, laneY, radius + 24, 0, Math.PI * 2);
          this.ctx.fill();
        }

        this.ctx.strokeStyle = "rgba(165, 180, 252, 0.85)";
        this.ctx.lineWidth = 4;
        this.ctx.setLineDash([6, 4]);
        this.ctx.beginPath();
        this.ctx.arc(x, laneY, radius + 10, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * shieldRatio);
        this.ctx.stroke();
        this.ctx.setLineDash([]);

        this.ctx.fillStyle = "#c7d2fe";
        this.ctx.font = "11px 'Segoe UI'";
        this.ctx.textAlign = "center";
        this.ctx.textBaseline = "bottom";
        const shieldLabel = `Shield ${Math.ceil(shieldState.current)}`;
        this.ctx.fillText(shieldLabel, x, laneY - radius - 14);
      }

      // Health ring
      this.ctx.strokeStyle = "#0ea5e9";
      this.ctx.lineWidth = 3;
      const healthRatio = Math.max(0, enemy.health / enemy.maxHealth);
      this.ctx.beginPath();
      this.ctx.arc(x, laneY, radius + 4, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * healthRatio);
      this.ctx.stroke();

      this.drawEnemyWord(state, enemy, x, laneY - radius - 4);

      const barWidth = radius * 2;
      let barY = laneY + radius + 4;
      if (shieldState) {
        const maxShield = Math.max(shieldState.max ?? shieldState.current, 1);
        const ratio = Math.max(0, Math.min(1, shieldState.current / maxShield));
        this.ctx.fillStyle = "rgba(99, 102, 241, 0.28)";
        this.ctx.fillRect(x - radius, barY, barWidth, 4);
        this.ctx.fillStyle = "rgba(165, 180, 252, 0.9)";
        this.ctx.fillRect(x - radius, barY, barWidth * ratio, 4);
        barY += 7;
      }

      // Typed progress bar
      if (enemy.typed > 0) {
        const ratio = enemy.typed / enemy.word.length;
        this.ctx.fillStyle = "#22d3ee";
        this.ctx.fillRect(x - radius, barY, barWidth * ratio, 4);
        this.ctx.fillStyle = "rgba(148, 163, 184, 0.3)";
        this.ctx.fillRect(x - radius + barWidth * ratio, barY, barWidth * (1 - ratio), 4);
      } else {
        this.ctx.fillStyle = "rgba(148, 163, 184, 0.3)";
        this.ctx.fillRect(x - radius, barY, barWidth, 4);
      }

      // Status effects
      if (!this.reducedMotion) {
        const burn = enemy.effects.find((effect) => effect.kind === "burn");
        if (burn) {
          const glow = this.ctx.createRadialGradient(x, laneY, 0, x, laneY, radius + 18);
          glow.addColorStop(0, "rgba(248, 113, 113, 0.9)");
          glow.addColorStop(1, "rgba(248, 113, 113, 0)");
          this.ctx.fillStyle = glow;
          this.ctx.beginPath();
          this.ctx.arc(x, laneY, radius + 18, 0, Math.PI * 2);
          this.ctx.fill();
        }

        const slow = enemy.effects.find((effect) => effect.kind === "slow");
        if (slow) {
          this.ctx.strokeStyle = "rgba(14, 165, 233, 0.6)";
          this.ctx.lineWidth = 2;
          this.ctx.setLineDash([4, 6]);
          this.ctx.beginPath();
          this.ctx.arc(x, laneY, radius + 12, 0, Math.PI * 2);
          this.ctx.stroke();
          this.ctx.setLineDash([]);
        }
      }
    }
  }

  private drawEnemyWord(
    state: GameState,
    enemy: EnemyState,
    centerX: number,
    baselineY: number
  ): void {
    const word = enemy.word;
    if (!word) {
      return;
    }

    this.ctx.save();
    this.ctx.font = "12px 'Segoe UI'";
    this.ctx.textAlign = "left";
    this.ctx.textBaseline = "bottom";

    const typedCount = Math.max(0, Math.min(enemy.typed, word.length));
    const isActive = state.typing.activeEnemyId === enemy.id;
    const palette = this.getWordPalette();
    const colors = resolveLetterColors(word, typedCount, isActive, palette);

    const letterSpacing = 1.5;
    const widths = Array.from(word).map((letter) => this.ctx.measureText(letter).width);
    const totalWidth =
      widths.reduce((sum, width) => sum + width, 0) + letterSpacing * Math.max(0, word.length - 1);
    let cursorX = centerX - totalWidth / 2;

    for (let index = 0; index < word.length; index += 1) {
      const letter = word[index];
      const width = widths[index];
      this.ctx.fillStyle = colors[index] ?? palette.remaining;
      this.ctx.fillText(letter, cursorX, baselineY);
      cursorX += width + letterSpacing;
    }

    this.ctx.restore();
  }

  private getWordPalette(): WordHighlightPalette {
    if (this.checkeredBackground) {
      return {
        typed: "#4ade80",
        next: "#fde047",
        remaining: "rgba(226, 232, 240, 0.88)",
        inactive: "rgba(148, 163, 184, 0.72)"
      };
    }
    return {
      typed: "#34d399",
      next: "#facc15",
      remaining: "#e2e8f0",
      inactive: "rgba(148, 163, 184, 0.7)"
    };
  }

  private drawProjectiles(state: GameState): void {
    if (state.projectiles.length === 0) return;
    const baseX = this.width * 0.1;
    for (const projectile of state.projectiles) {
      const laneY = this.laneY(projectile.lane);
      const x = baseX + projectile.position * this.pathLength;
      const color = PROJECTILE_COLORS[projectile.kind];

      if (this.reducedMotion) {
        this.ctx.fillStyle = color;
        this.ctx.beginPath();
        this.ctx.arc(x, laneY, 6, 0, Math.PI * 2);
        this.ctx.fill();
        continue;
      }

      if (projectile.kind === "arcane") {
        this.ctx.strokeStyle = color;
        this.ctx.lineWidth = 2;
        this.ctx.globalAlpha = 0.8;
        this.ctx.beginPath();
        this.ctx.moveTo(x - 8, laneY - 12);
        this.ctx.lineTo(x + 8, laneY + 12);
        this.ctx.stroke();
        this.ctx.globalAlpha = 1;
      } else if (projectile.kind === "flame") {
        const gradient = this.ctx.createRadialGradient(x, laneY, 0, x, laneY, 14);
        gradient.addColorStop(0, "rgba(251, 191, 36, 0.85)");
        gradient.addColorStop(1, "rgba(239, 68, 68, 0)");
        this.ctx.fillStyle = gradient;
        this.ctx.beginPath();
        this.ctx.arc(x, laneY, 14, 0, Math.PI * 2);
        this.ctx.fill();
      } else if (projectile.kind === "crystal") {
        const pulse = this.ctx.createRadialGradient(x, laneY, 0, x, laneY, 16);
        pulse.addColorStop(0, "rgba(191, 239, 255, 0.95)");
        pulse.addColorStop(0.45, this.withAlpha(color, 0.85));
        pulse.addColorStop(1, "rgba(103, 232, 249, 0)");
        this.ctx.fillStyle = pulse;
        this.ctx.beginPath();
        this.ctx.arc(x, laneY, 16, 0, Math.PI * 2);
        this.ctx.fill();

        this.ctx.strokeStyle = this.withAlpha("#bef0ff", 0.85);
        this.ctx.lineWidth = 2;
        this.ctx.beginPath();
        this.ctx.moveTo(x, laneY - 10);
        this.ctx.lineTo(x + 8, laneY);
        this.ctx.lineTo(x, laneY + 10);
        this.ctx.lineTo(x - 8, laneY);
        this.ctx.closePath();
        this.ctx.stroke();
      } else {
        this.ctx.fillStyle = color;
        this.ctx.beginPath();
        this.ctx.arc(x, laneY, 6, 0, Math.PI * 2);
        this.ctx.fill();
      }
    }
  }

  private drawImpactEffects(state: GameState, effects: ImpactEffectRender[]): void {
    if (effects.length === 0 || this.reducedMotion) return;
    const baseX = this.width * 0.1;
    for (const effect of effects) {
      if (effect.age >= 1) continue;
      if (effect.kind === "muzzle" && effect.slotId) {
        const slot = state.turrets.find((entry) => entry.id === effect.slotId);
        if (!slot) continue;
        const turretType = effect.turretType ?? slot.turret?.typeId ?? "arrow";
        const color = PROJECTILE_COLORS[turretType] ?? "#facc15";
        const x = this.width * slot.position.x;
        const y = this.height * slot.position.y;
        const intensity = Math.max(0, 1 - effect.age);
        const innerRadius = 14 + 10 * intensity;
        const outerRadius = innerRadius * 1.7;
        const gradient = this.ctx.createRadialGradient(x, y, innerRadius * 0.35, x, y, outerRadius);
        gradient.addColorStop(0, this.withAlpha(color, 0.65 * intensity));
        gradient.addColorStop(0.4, this.withAlpha(color, 0.22 * intensity));
        gradient.addColorStop(1, "rgba(255, 255, 255, 0)");
        this.ctx.fillStyle = gradient;
        this.ctx.beginPath();
        this.ctx.arc(x, y, outerRadius, 0, Math.PI * 2);
        this.ctx.fill();

        this.ctx.strokeStyle = this.withAlpha(color, 0.85 * intensity);
        this.ctx.lineWidth = 2;
        this.ctx.beginPath();
        this.ctx.arc(x, y, innerRadius, 0, Math.PI * 2);
        this.ctx.stroke();
        continue;
      }

      const laneIndex = effect.lane ?? 0;
      const laneY = this.laneY(laneIndex);
      const x = baseX + effect.position * this.pathLength;
      const alpha = Math.max(0, 1 - effect.age);
      const radius =
        effect.kind === "breach" ? 24 + 28 * (1 - effect.age) : 14 + 18 * (1 - effect.age);
      const innerColor =
        effect.kind === "breach" ? `rgba(248, 113, 113, ${alpha})` : `rgba(250, 204, 21, ${alpha})`;
      const outerColor =
        effect.kind === "breach" ? "rgba(248, 113, 113, 0)" : "rgba(250, 204, 21, 0)";
      const gradient = this.ctx.createRadialGradient(x, laneY, 0, x, laneY, radius);
      gradient.addColorStop(0, innerColor);
      gradient.addColorStop(1, outerColor);
      this.ctx.fillStyle = gradient;
      this.ctx.beginPath();
      this.ctx.arc(x, laneY, radius, 0, Math.PI * 2);
      this.ctx.fill();
    }
  }

  private drawCastle(state: GameState): void {
    const castleWidth = this.width * 0.12;
    const castleHeight = this.height * 0.6;
    const x = this.width * 0.85;
    const y = (this.height - castleHeight) / 2;

    this.ctx.fillStyle = "#475569";
    this.ctx.fillRect(x, y, castleWidth, castleHeight);

    const hpRatio = Math.max(0, state.castle.health / state.castle.maxHealth);
    this.ctx.fillStyle = "#22d3ee";
    this.ctx.fillRect(x, y + castleHeight * (1 - hpRatio), castleWidth, castleHeight * hpRatio);

    this.ctx.strokeStyle = "#1f2937";
    this.ctx.lineWidth = 4;
    this.ctx.strokeRect(x, y, castleWidth, castleHeight);
  }

  private drawStatus(state: GameState): void {
    this.ctx.fillStyle = "#e2e8f0";
    this.ctx.font = "16px 'Segoe UI'";
    this.ctx.textAlign = "left";
    this.ctx.textBaseline = "top";
    this.ctx.fillText(`Wave ${state.wave.index + 1}/${state.wave.total}`, 16, 16);
    this.ctx.fillText(`Gold: ${Math.floor(state.resources.gold)}`, 16, 40);

    if (state.wave.inCountdown) {
      this.ctx.font = "32px 'Segoe UI'";
      this.ctx.textAlign = "center";
      this.ctx.textBaseline = "middle";
      this.ctx.fillText(
        `Prepare: ${state.wave.countdownRemaining.toFixed(1)}s`,
        this.width / 2,
        48
      );
    } else if (state.status === "victory") {
      this.ctx.font = "42px 'Segoe UI'";
      this.ctx.textAlign = "center";
      this.ctx.fillText("Victory!", this.width / 2, this.height / 2);
    } else if (state.status === "defeat") {
      this.ctx.font = "42px 'Segoe UI'";
      this.ctx.textAlign = "center";
      this.ctx.fillText("Defeat", this.width / 2, this.height / 2);
    }
  }

  private laneY(lane: number, margin?: number): number {
    const verticalMargin = margin ?? this.height * 0.15;
    const span = this.height - verticalMargin * 2;
    if (this.laneCount <= 1) {
      return this.height / 2;
    }
    return verticalMargin + (span / (this.laneCount - 1)) * lane;
  }

  private updateDefeatBursts(state: GameState): void {
    const now = state.time;
    const seen = new Set<string>();
    for (const enemy of state.enemies) {
      seen.add(enemy.id);
      const previous = this.lastEnemyStatuses.get(enemy.id);
      if (enemy.status === "defeated" && previous !== "defeated") {
        this.defeatBursts.push({
          id: enemy.id,
          lane: enemy.lane,
          position: enemy.distance,
          tierId: enemy.tierId,
          startTime: now,
          duration: CanvasRenderer.DEFEAT_BURST_DURATION
        });
      }
      this.lastEnemyStatuses.set(enemy.id, enemy.status);
    }
    for (const id of [...this.lastEnemyStatuses.keys()]) {
      if (!seen.has(id)) {
        this.lastEnemyStatuses.delete(id);
      }
    }
    this.defeatBursts = this.defeatBursts.filter(
      (burst) => now - burst.startTime <= burst.duration
    );
  }

  private drawDefeatBursts(state: GameState): void {
    if (this.defeatBursts.length === 0) return;
    const baseX = this.width * 0.1;
    const now = state.time;
    for (const burst of this.defeatBursts) {
      const elapsed = now - burst.startTime;
      const progress = Math.min(1, Math.max(0, elapsed / burst.duration));
      const eased = 1 - Math.pow(1 - progress, 2);
      const fade = 1 - progress;
      const x = baseX + burst.position * this.pathLength;
      const y = this.laneY(burst.lane);
      const palette = this.spriteRenderer.getEnemyPalette(burst.tierId);
      const innerRadius = 14 + eased * 8;
      const outerRadius = innerRadius + 18;

      const gradient = this.ctx.createRadialGradient(x, y, innerRadius * 0.2, x, y, outerRadius);
      gradient.addColorStop(0, this.withAlpha(palette.highlight, 0.45 * fade));
      gradient.addColorStop(1, this.withAlpha(palette.base, 0));
      this.ctx.fillStyle = gradient;
      this.ctx.beginPath();
      this.ctx.arc(x, y, outerRadius, 0, Math.PI * 2);
      this.ctx.fill();

      this.ctx.strokeStyle = this.withAlpha(palette.accent, 0.85 * fade);
      this.ctx.lineWidth = 2 + 2 * fade;
      this.ctx.beginPath();
      this.ctx.arc(x, y, innerRadius, 0, Math.PI * 2);
      this.ctx.stroke();

      if (!this.reducedMotion) {
        const spikes = 6;
        const spikeLength = 8 + eased * 6;
        this.ctx.strokeStyle = this.withAlpha(palette.accent, 0.45 * fade);
        this.ctx.lineWidth = 1.5;
        for (let i = 0; i < spikes; i++) {
          const angle = (i / spikes) * Math.PI * 2;
          const startR = innerRadius + 2;
          const sx = x + Math.cos(angle) * startR;
          const sy = y + Math.sin(angle) * startR;
          const ex = x + Math.cos(angle) * (startR + spikeLength);
          const ey = y + Math.sin(angle) * (startR + spikeLength);
          this.ctx.beginPath();
          this.ctx.moveTo(sx, sy);
          this.ctx.lineTo(ex, ey);
          this.ctx.stroke();
        }
      }
    }
  }
}

interface DefeatBurst {
  id: string;
  lane: number;
  position: number;
  tierId: string;
  startTime: number;
  duration: number;
}
