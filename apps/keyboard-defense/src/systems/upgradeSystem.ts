import { CastleLevelConfig, GameConfig } from "../core/config.js";
import { EventBus } from "../core/eventBus.js";
import { GameEvents } from "../core/events.js";
import { CastlePassive, GameState, TurretTypeId } from "../core/types.js";
import { deriveCastlePassives } from "../utils/castlePassives.js";
import { TurretSystem } from "./turretSystem.js";

export interface UpgradeResult {
  success: boolean;
  cost?: number;
  refund?: number;
  removed?: boolean;
  message?: string;
}

export interface RepairResult extends UpgradeResult {
  healed?: number;
  cooldown?: number;
}

export class UpgradeSystem {
  constructor(
    private readonly config: GameConfig,
    private readonly events: EventBus<GameEvents>,
    private readonly turrets: TurretSystem
  ) {
    this.baseCastleConfig = this.config.castleLevels[0];
  }

  private readonly baseCastleConfig: CastleLevelConfig;
  private static readonly EPSILON = 0.0001;

  upgradeCastle(state: GameState): UpgradeResult {
    const currentLevelConfig = this.config.castleLevels.find((c) => c.level === state.castle.level);
    if (!currentLevelConfig) {
      return { success: false, message: "Invalid castle level." };
    }
    if (currentLevelConfig.upgradeCost === null) {
      return { success: false, message: "Castle is at maximum level." };
    }
    if (state.resources.gold < currentLevelConfig.upgradeCost) {
      return { success: false, message: "Not enough gold." };
    }

    const nextLevelConfig = this.config.castleLevels.find(
      (c) => c.level === state.castle.level + 1
    );
    if (!nextLevelConfig) {
      return { success: false, message: "Castle is at maximum level." };
    }

    state.resources.gold -= currentLevelConfig.upgradeCost;
    state.castle.level = nextLevelConfig.level;
    state.castle.maxHealth = nextLevelConfig.maxHealth;
    state.castle.health = Math.min(
      state.castle.health + nextLevelConfig.maxHealth * 0.25,
      nextLevelConfig.maxHealth
    );
    state.castle.armor = nextLevelConfig.armor;
    state.castle.regenPerSecond = nextLevelConfig.regenPerSecond;
    state.castle.nextUpgradeCost = nextLevelConfig.upgradeCost;
    state.castle.goldBonusPercent = nextLevelConfig.goldBonusPercent ?? 0;

    const previousPassives = state.castle.passives ?? [];
    const updatedPassives = this.updateCastlePassives(state, nextLevelConfig);
    this.emitPassiveUnlocks(previousPassives, updatedPassives);

    this.events.emit("castle:upgraded", { level: state.castle.level });

    this.turrets.unlockSlotsByWave(state, state.wave.index);
    this.unlockSlotsByCastleLevel(state, nextLevelConfig.unlockSlots);

    return { success: true, cost: currentLevelConfig.upgradeCost };
  }

  placeTurret(state: GameState, slotId: string, typeId: TurretTypeId): UpgradeResult {
    const archetype = this.config.turretArchetypes[typeId];
    if (!archetype) {
      return { success: false, message: "Unknown turret type." };
    }
    const cost = archetype.levels[0]?.cost ?? 0;
    if (state.resources.gold < cost) {
      return { success: false, message: "Not enough gold." };
    }
    const result = this.turrets.placeTurret(state, slotId, typeId);
    if (!result) {
      return { success: false, message: "Unable to place turret." };
    }
    state.resources.gold -= cost;
    this.events.emit("resources:gold", {
      gold: state.resources.gold,
      delta: -cost,
      timestamp: state.time
    });
    return { success: true, cost };
  }

  upgradeTurret(state: GameState, slotId: string): UpgradeResult {
    const slot = state.turrets.find((s) => s.id === slotId);
    if (!slot || !slot.turret) {
      return { success: false, message: "No turret in slot." };
    }
    const next = this.turrets.getLevelConfig(slot.turret.typeId, slot.turret.level + 1);
    if (!next) {
      return { success: false, message: "Turret is at max level." };
    }
    if (state.resources.gold < next.cost) {
      return { success: false, message: "Not enough gold." };
    }
    const result = this.turrets.upgradeTurret(state, slotId);
    if (!result) {
      return { success: false, message: "Upgrade failed." };
    }
    state.resources.gold -= next.cost;
    this.events.emit("resources:gold", {
      gold: state.resources.gold,
      delta: -next.cost,
      timestamp: state.time
    });
    return { success: true, cost: next.cost };
  }

  downgradeTurret(state: GameState, slotId: string): UpgradeResult {
    if (!this.config.featureToggles?.turretDowngrade) {
      return { success: false, message: "Turret downgrade disabled." };
    }
    const slot = state.turrets.find((s) => s.id === slotId);
    if (!slot || !slot.turret) {
      return { success: false, message: "No turret in slot." };
    }

    const archetype = this.config.turretArchetypes[slot.turret.typeId];
    if (!archetype) {
      return { success: false, message: "Unknown turret archetype." };
    }

    let refund = 0;
    if (slot.turret.level > 1) {
      const currentConfig = this.turrets.getLevelConfig(slot.turret.typeId, slot.turret.level);
      if (!currentConfig) {
        return { success: false, message: "Invalid turret level." };
      }
      refund = currentConfig.cost ?? 0;
    } else {
      refund = archetype.levels[0]?.cost ?? 0;
    }

    const result = this.turrets.downgradeTurret(state, slotId);
    if (!result) {
      return { success: false, message: "Unable to downgrade turret." };
    }

    if (refund > 0) {
      state.resources.gold += refund;
      this.events.emit("resources:gold", {
        gold: state.resources.gold,
        delta: refund,
        timestamp: state.time
      });
    }

    return { success: true, refund, removed: result.removed };
  }

  repairCastle(state: GameState): RepairResult {
    const settings = this.config.castleRepair;
    if (!settings) {
      return { success: false, message: "Castle repair unavailable." };
    }

    if (state.castle.health <= 0) {
      return { success: false, message: "Castle is destroyed and cannot be repaired." };
    }

    if (state.castle.health >= state.castle.maxHealth) {
      return { success: false, message: "Castle is already at full health." };
    }

    const cooldownRemaining = Math.max(0, state.castle.repairCooldownRemaining ?? 0);
    if (cooldownRemaining > 0.05) {
      return {
        success: false,
        message: `Repair ability cooling down (${cooldownRemaining.toFixed(1)}s remaining).`
      };
    }

    if (state.resources.gold < settings.cost) {
      return { success: false, message: "Not enough gold to repair the castle." };
    }

    const missingHealth = Math.max(0, state.castle.maxHealth - state.castle.health);
    if (missingHealth <= 0) {
      return { success: false, message: "Castle is already at full health." };
    }

    const healAmount = Math.min(settings.healAmount, missingHealth);
    if (healAmount <= 0) {
      return { success: false, message: "Repair would have no effect." };
    }

    state.resources.gold -= settings.cost;
    state.castle.health = Math.min(state.castle.maxHealth, state.castle.health + healAmount);
    state.castle.repairCooldownRemaining = settings.cooldownSeconds;
    this.events.emit("resources:gold", {
      gold: state.resources.gold,
      delta: -settings.cost,
      timestamp: state.time
    });
    this.events.emit("castle:repaired", {
      amount: healAmount,
      health: state.castle.health,
      cost: settings.cost
    });

    return {
      success: true,
      cost: settings.cost,
      healed: healAmount,
      cooldown: settings.cooldownSeconds
    };
  }

  private unlockSlotsByCastleLevel(state: GameState, unlockedCount: number): void {
    for (let i = 0; i < state.turrets.length; i++) {
      state.turrets[i].unlocked = i < unlockedCount;
    }
  }

  private updateCastlePassives(state: GameState, levelConfig: CastleLevelConfig): CastlePassive[] {
    const passives = deriveCastlePassives(this.baseCastleConfig, levelConfig);
    state.castle.passives = passives;
    return passives;
  }

  private emitPassiveUnlocks(previous: CastlePassive[], current: CastlePassive[]): void {
    const previousMap = new Map(previous.map((passive) => [passive.id, passive]));
    for (const passive of current) {
      const prior = previousMap.get(passive.id);
      if (
        !prior ||
        passive.total - prior.total > UpgradeSystem.EPSILON ||
        passive.delta - prior.delta > UpgradeSystem.EPSILON
      ) {
        this.events.emit("castle:passive-unlocked", { passive });
      }
    }
  }
}
