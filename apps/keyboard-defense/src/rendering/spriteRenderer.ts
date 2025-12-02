import { type EnemyState, type TurretSlotState, type TurretTypeId } from "../core/types.js";
import { type AssetLoader } from "../assets/assetLoader.js";
import { type EnemyPalette, ENEMY_PALETTES, ENEMY_PALETTES_HIGH_CONTRAST } from "./enemyPalettes.js";

const TURRET_COLORS: Record<TurretTypeId, { base: string; barrel: string }> = {
  arrow: { base: "#38bdf8", barrel: "#0c4a6e" },
  arcane: { base: "#c084fc", barrel: "#581c87" },
  flame: { base: "#fb923c", barrel: "#9a3412" },
  crystal: { base: "#67e8f9", barrel: "#0f766e" }
};

const TURRET_COLORS_HIGH_CONTRAST: Record<TurretTypeId, { base: string; barrel: string }> = {
  arrow: { base: "#0ea5e9", barrel: "#082f49" },
  arcane: { base: "#7c3aed", barrel: "#1e1b4b" },
  flame: { base: "#f97316", barrel: "#7c2d12" },
  crystal: { base: "#22d3ee", barrel: "#134e4a" }
};

export class SpriteRenderer {
  private colorBlindFriendly = false;

  constructor(private readonly assets?: AssetLoader) {}

  setColorBlindFriendly(enabled: boolean): void {
    this.colorBlindFriendly = enabled;
  }

  drawEnemy(
    ctx: CanvasRenderingContext2D,
    enemy: EnemyState,
    x: number,
    y: number,
    radius: number
  ): void {
    const key = `enemy-${enemy.tierId}`;
    if (this.assets?.drawFrame?.(ctx, key, x - radius, y - radius, radius * 2, radius * 2)) {
      return;
    }

    const image = this.assets?.getImage(key);
    if (image) {
      ctx.drawImage(image as CanvasImageSource, x - radius, y - radius, radius * 2, radius * 2);
      return;
    }

    const paletteMap = this.colorBlindFriendly ? ENEMY_PALETTES_HIGH_CONTRAST : ENEMY_PALETTES;
    const palette = paletteMap[enemy.tierId] ?? paletteMap.grunt;

    const gradient = ctx.createRadialGradient(x, y - radius * 0.4, radius * 0.2, x, y, radius);
    gradient.addColorStop(0, palette.highlight);
    gradient.addColorStop(0.6, palette.base);
    gradient.addColorStop(1, "#1e1b4b");
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.arc(x, y, radius, 0, Math.PI * 2);
    ctx.fill();

    // Accent band
    ctx.fillStyle = palette.accent;
    ctx.fillRect(x - radius * 0.8, y - radius * 0.2, radius * 1.6, radius * 0.4);

    // Eyes
    ctx.fillStyle = "#f8fafc";
    const eyeOffset = radius * 0.45;
    ctx.beginPath();
    ctx.arc(x - eyeOffset, y - radius * 0.15, radius * 0.18, 0, Math.PI * 2);
    ctx.arc(x + eyeOffset, y - radius * 0.15, radius * 0.18, 0, Math.PI * 2);
    ctx.fill();
  }

  getEnemyPalette(tierId: string): EnemyPalette {
    const paletteMap = this.colorBlindFriendly ? ENEMY_PALETTES_HIGH_CONTRAST : ENEMY_PALETTES;
    return paletteMap[tierId] ?? paletteMap.grunt;
  }

  drawTurret(
    ctx: CanvasRenderingContext2D,
    slot: TurretSlotState,
    x: number,
    y: number,
    radius: number
  ): void {
    if (!slot.turret) return;
    const paletteMap = this.colorBlindFriendly ? TURRET_COLORS_HIGH_CONTRAST : TURRET_COLORS;
    const palette = paletteMap[slot.turret.typeId];
    if (!palette) return;

    const key = `turret-${slot.turret.typeId}`;
    if (this.assets?.drawFrame?.(ctx, key, x - radius, y - radius, radius * 2, radius * 2)) {
      // drawn from atlas
    } else {
      const image = this.assets?.getImage(key);
      if (image) {
        ctx.drawImage(image as CanvasImageSource, x - radius, y - radius, radius * 2, radius * 2);
      } else {
        ctx.fillStyle = palette.base;
        ctx.beginPath();
        ctx.arc(x, y, radius * 0.6, 0, Math.PI * 2);
        ctx.fill();
      }
    }

    // Barrel
    ctx.strokeStyle = palette.barrel;
    ctx.lineWidth = radius * 0.4;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(x + radius * 1.1, y);
    ctx.stroke();

    ctx.fillStyle = "#0f172a";
    ctx.font = "bold 11px 'Segoe UI'";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(`${slot.turret.level}`, x, y);
  }
}
