import { createEnemyIconDataUri } from "../rendering/enemyIcon.js";
import type { GameConfig } from "../core/config.js";
import type { LaneHazardState, WaveSpawnPreview } from "../core/types.js";

const LANE_LABELS = ["A", "B", "C", "D", "E"];

export interface WavePreviewRenderOptions {
  colorBlindFriendly?: boolean;
  onSelect?: (tierId: string) => void;
  selectedTierId?: string | null;
  showThreatIndicators?: boolean;
  laneHazards?: LaneHazardState[];
  emptyMessage?: string | null;
}

function formatSeconds(value: number): string {
  if (!Number.isFinite(value)) {
    return "-";
  }
  return `${value <= 9.95 ? value.toFixed(1) : Math.round(value)}s`;
}

function formatFireRateEffect(multiplier: number | null | undefined): string | null {
  if (typeof multiplier !== "number" || !Number.isFinite(multiplier) || multiplier <= 0) {
    return null;
  }
  const deltaPercent = Math.round((multiplier - 1) * 100);
  if (deltaPercent === 0) {
    return null;
  }
  const sign = deltaPercent > 0 ? "+" : "";
  return `${sign}${deltaPercent}% turret fire rate`;
}

function toTitle(text: string | null | undefined): string {
  if (!text) return "";
  return text
    .split(/[-_]/g)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

export class WavePreviewPanel {
  private highlighted = false;
  private shieldCurrent = false;
  private shieldNext = false;
  private affixCurrent = false;
  private affixNext = false;
  private colorBlindFriendly = false;
  private iconCache = new Map<string, string>();

  constructor(
    private readonly container: HTMLElement,
    private readonly config: GameConfig
  ) {}

  render(entries: WaveSpawnPreview[], options: WavePreviewRenderOptions = {}): void {
    if (options.colorBlindFriendly !== undefined) {
      this.setColorBlindFriendly(Boolean(options.colorBlindFriendly));
    }
    const hazardEntries = Array.isArray(options.laneHazards) ? options.laneHazards : [];
    const activeHazards = new Map<number, LaneHazardState>();
    for (const hazard of hazardEntries) {
      if (!hazard || !Number.isFinite(hazard.lane) || hazard.remaining <= 0) continue;
      if (!activeHazards.has(hazard.lane)) {
        activeHazards.set(hazard.lane, hazard);
      }
    }
    this.container.replaceChildren();
    if (entries.length === 0) {
      const empty = document.createElement("div");
      empty.className = "wave-preview-empty";
      const message = options.emptyMessage?.trim();
      empty.textContent = message && message.length > 0 ? message : "All clear.";
      this.container.appendChild(empty);
      return;
    }

    const fragment = document.createDocumentFragment();
    let currentShielded = false;
    let nextShielded = false;
    let currentAffixed = false;
    let nextAffixed = false;
    const currentWaveEntries = entries.filter((entry) => !entry.isNextWave);
    if (currentWaveEntries.length > 0) {
      const summary = document.createElement("div");
      summary.className = "wave-preview-summary";
      const laneStats = new Map<number, { count: number; damage: number }>();
      for (const lane of activeHazards.keys()) {
        if (!laneStats.has(lane)) {
          laneStats.set(lane, { count: 0, damage: 0 });
        }
      }
      for (const entry of currentWaveEntries) {
        const stats = laneStats.get(entry.lane) ?? { count: 0, damage: 0 };
        stats.count += 1;
        const tier = this.config.enemyTiers[entry.tierId];
        if (tier) {
          stats.damage += tier.damage;
        }
        laneStats.set(entry.lane, stats);
        if ((entry.shield ?? 0) > 0) {
          currentShielded = true;
        }
      }
      const maxLaneDamage = Math.max(
        0,
        ...Array.from(laneStats.values()).map((stats) => stats.damage)
      );
      const sorted = [...laneStats.entries()].sort((a, b) => a[0] - b[0]);
      for (const [lane, stats] of sorted) {
        const pill = document.createElement("span");
        pill.className = "summary-pill";
        const laneLabel = LANE_LABELS[lane] ?? String(lane + 1);
        if (options.showThreatIndicators) {
          const roundedDamage = Math.round(stats.damage);
          const threatText = roundedDamage > 0 ? ` • ${roundedDamage} dmg` : "";
          pill.textContent = `${laneLabel}: x${stats.count}${threatText}`;
          if (roundedDamage === maxLaneDamage && maxLaneDamage > 0) {
            pill.dataset.priority = "true";
          }
          if (maxLaneDamage > 0) {
            const ratio = stats.damage / maxLaneDamage;
            pill.dataset.threatLevel =
              ratio >= 0.75 ? "high" : ratio >= 0.4 ? "medium" : "low";
          }
          const hazard = activeHazards.get(lane);
          if (hazard) {
            const hazardLabel = toTitle(hazard.kind);
            const remainingLabel = formatSeconds(Math.max(0, hazard.remaining));
            const fireRateEffect = formatFireRateEffect(hazard.fireRateMultiplier);
            const hazardDetail = fireRateEffect
              ? `${hazardLabel} active (${remainingLabel} left, ${fireRateEffect})`
              : `${hazardLabel} active (${remainingLabel} left)`;
            pill.dataset.hazard = hazard.kind;
            const hazardBadge = document.createElement("span");
            hazardBadge.className = "summary-hazard";
            hazardBadge.textContent = hazardLabel;
            hazardBadge.title = hazardDetail;
            pill.appendChild(hazardBadge);
            pill.setAttribute(
              "aria-label",
              `${laneLabel} lane: ${stats.count} enemies, ${roundedDamage} damage, ${hazardDetail}`
            );
          } else {
            pill.setAttribute(
              "aria-label",
              `${laneLabel} lane: ${stats.count} enemies, ${roundedDamage} damage`
            );
          }
        } else {
          pill.textContent = `${laneLabel}: x${stats.count}`;
          const hazard = activeHazards.get(lane);
          if (hazard) {
            const hazardLabel = toTitle(hazard.kind);
            const remainingLabel = formatSeconds(Math.max(0, hazard.remaining));
            const fireRateEffect = formatFireRateEffect(hazard.fireRateMultiplier);
            const hazardDetail = fireRateEffect
              ? `${hazardLabel} active (${remainingLabel} left, ${fireRateEffect})`
              : `${hazardLabel} active (${remainingLabel} left)`;
            pill.dataset.hazard = hazard.kind;
            const hazardBadge = document.createElement("span");
            hazardBadge.className = "summary-hazard";
            hazardBadge.textContent = hazardLabel;
            hazardBadge.title = hazardDetail;
            pill.appendChild(hazardBadge);
          }
        }
        summary.appendChild(pill);
      }
      fragment.appendChild(summary);
    }

    for (const entry of entries) {
      const row = document.createElement("div");
      row.className = "wave-preview-row";
      row.dataset.tierId = entry.tierId;
      const activeHazard = activeHazards.get(entry.lane);
      if (activeHazard) {
        row.dataset.hazard = activeHazard.kind;
      }
      row.tabIndex = 0;
      row.setAttribute("role", "button");
      row.setAttribute("aria-pressed", entry.tierId === options.selectedTierId ? "true" : "false");
      if (entry.tierId === options.selectedTierId) {
        row.dataset.selected = "true";
      }
      if (entry.isNextWave) {
        row.dataset.phase = "next";
        if ((entry.shield ?? 0) > 0) {
          nextShielded = true;
        }
        if (entry.affixes && entry.affixes.length > 0) {
          nextAffixed = true;
        }
      }
      const lane = document.createElement("span");
      lane.className = "preview-lane";
      const laneLabel = LANE_LABELS[entry.lane] ?? String(entry.lane + 1);
      lane.textContent = laneLabel;
      row.appendChild(lane);

      const enemy = document.createElement("span");
      enemy.className = "preview-enemy";
      const tier = this.config.enemyTiers[entry.tierId];
      const enemyLabel = tier ? toTitle(tier.id) : toTitle(entry.tierId);
      enemy.textContent = `${enemyLabel}`;
      const iconHolder = document.createElement("span");
      iconHolder.className = "preview-icon";
      iconHolder.setAttribute("aria-hidden", "true");
      iconHolder.setAttribute("role", "presentation");
      iconHolder.style.backgroundImage = `url("${this.getIconDataUri(entry.tierId)}")`;
      row.appendChild(iconHolder);
      if (entry.shield && entry.shield > 0) {
        row.dataset.shielded = "true";
        const badge = document.createElement("span");
        badge.className = "preview-badge shielded";
        badge.textContent = `Shield ${Math.round(entry.shield)}`;
        badge.title = `Shield ${Math.round(entry.shield)} HP`;
        badge.setAttribute("aria-label", `Shield ${Math.round(entry.shield)} HP`);
        enemy.appendChild(badge);
      }
      if (activeHazard) {
        const badge = document.createElement("span");
        badge.className = "preview-badge hazard";
        badge.dataset.hazard = activeHazard.kind;
        const hazardLabel = toTitle(activeHazard.kind);
        badge.textContent = hazardLabel;
        const remainingLabel = formatSeconds(Math.max(0, activeHazard.remaining));
        const fireRateEffect = formatFireRateEffect(activeHazard.fireRateMultiplier);
        const hazardDetail = fireRateEffect
          ? `${hazardLabel} active (${remainingLabel} left, ${fireRateEffect})`
          : `${hazardLabel} active (${remainingLabel} left)`;
        badge.title = hazardDetail;
        badge.setAttribute("aria-label", hazardDetail);
        enemy.appendChild(badge);
      }
      if (entry.affixes && entry.affixes.length > 0) {
        row.dataset.affixed = "true";
        const affixWrapper = document.createElement("span");
        affixWrapper.className = "preview-affixes";
        for (const affix of entry.affixes) {
          const badge = document.createElement("span");
          badge.className = "preview-badge affix";
          if (affix.id) {
            badge.dataset.affixId = affix.id;
          }
          badge.textContent = affix.label ?? toTitle(affix.id);
          if (affix.description) {
            badge.title = affix.description;
          }
          badge.setAttribute("aria-label", affix.label ?? toTitle(affix.id));
          affixWrapper.appendChild(badge);
        }
        enemy.appendChild(affixWrapper);
        if (!entry.isNextWave) {
          currentAffixed = true;
        }
      }
      row.appendChild(enemy);
      const wave = document.createElement("span");
      wave.className = "preview-wave";
      wave.textContent = `W${entry.waveIndex + 1}`;
      row.appendChild(wave);
      const time = document.createElement("span");
      time.className = "preview-time";
      time.textContent = formatSeconds(Math.max(0, entry.timeUntil));
      row.appendChild(time);

      const handleSelection = () => {
        if (typeof options.onSelect === "function") {
          options.onSelect(entry.tierId);
        }
      };
      row.addEventListener("click", handleSelection);
      row.addEventListener("keydown", (event) => {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          handleSelection();
        }
      });

      fragment.appendChild(row);
    }
    this.setShieldForecast(currentShielded, nextShielded);
    this.setAffixForecast(currentAffixed, nextAffixed);
    this.container.appendChild(fragment);
    this.applyHighlightState();
  }

  setTutorialHighlight(active: boolean): void {
    this.highlighted = active;
    this.applyHighlightState();
  }

  setShieldForecast(current: boolean, next: boolean): void {
    this.shieldCurrent = current;
    this.shieldNext = next;
    this.applyShieldState();
  }

  setColorBlindFriendly(enabled: boolean): void {
    if (this.colorBlindFriendly === enabled) {
      return;
    }
    this.colorBlindFriendly = enabled;
    this.iconCache.clear();
  }

  private applyHighlightState(): void {
    if (this.highlighted) {
      this.container.dataset.tutorialHighlight = "true";
      this.container.setAttribute("aria-live", "polite");
    } else {
      delete this.container.dataset.tutorialHighlight;
      this.container.removeAttribute("aria-live");
    }
  }

  private applyShieldState(): void {
    if (this.shieldCurrent) {
      this.container.dataset.shieldCurrent = "true";
    } else {
      delete this.container.dataset.shieldCurrent;
    }
    if (this.shieldNext) {
      this.container.dataset.shieldNext = "true";
    } else {
      delete this.container.dataset.shieldNext;
    }
  }

  setAffixForecast(current: boolean, next: boolean): void {
    this.affixCurrent = current;
    this.affixNext = next;
    this.applyAffixState();
  }

  private applyAffixState(): void {
    if (this.affixCurrent) {
      this.container.dataset.affixCurrent = "true";
    } else {
      delete this.container.dataset.affixCurrent;
    }
    if (this.affixNext) {
      this.container.dataset.affixNext = "true";
    } else {
      delete this.container.dataset.affixNext;
    }
  }

  private getIconDataUri(tierId: string): string {
    const key = `${this.colorBlindFriendly ? "hc" : "std"}:${tierId}`;
    const cached = this.iconCache.get(key);
    if (cached) {
      return cached;
    }
    const uri = createEnemyIconDataUri(tierId, {
      colorBlindFriendly: this.colorBlindFriendly
    });
    this.iconCache.set(key, uri);
    return uri;
  }
}
