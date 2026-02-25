using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Economy;

/// <summary>
/// Equipment and consumable item system.
/// Ported from sim/items.gd.
/// </summary>
public static class Items
{
    /// <summary>
    /// Rarity tiers used by equipment definitions.
    /// </summary>
    public enum Rarity { Common, Uncommon, Rare, Epic, Legendary }
    /// <summary>
    /// Equipment slots used by equipped item placement.
    /// </summary>
    public enum SlotType { Weapon, Armor, Helmet, Boots, Ring, Amulet, Shield, Cape }

    /// <summary>
    /// Equipment definitions keyed by item ID, including rarity, slot, and stat bonuses.
    /// </summary>
    public static readonly Dictionary<string, ItemDef> Equipment = new()
    {
        ["iron_sword"] = new("Iron Sword", Rarity.Common, SlotType.Weapon,
            new() { ["damage"] = 3 }),
        ["steel_sword"] = new("Steel Sword", Rarity.Uncommon, SlotType.Weapon,
            new() { ["damage"] = 6 }),
        ["iron_armor"] = new("Iron Armor", Rarity.Common, SlotType.Armor,
            new() { ["armor"] = 3 }),
        ["steel_armor"] = new("Steel Armor", Rarity.Uncommon, SlotType.Armor,
            new() { ["armor"] = 6 }),
        ["swift_boots"] = new("Swift Boots", Rarity.Common, SlotType.Boots,
            new() { ["speed"] = 5 }),
        ["power_ring"] = new("Ring of Power", Rarity.Rare, SlotType.Ring,
            new() { ["damage"] = 4, ["accuracy_bonus"] = 5 }),
        ["guardian_shield"] = new("Guardian Shield", Rarity.Rare, SlotType.Shield,
            new() { ["armor"] = 5, ["hp_bonus"] = 10 }),
        ["arcane_amulet"] = new("Arcane Amulet", Rarity.Epic, SlotType.Amulet,
            new() { ["damage"] = 8, ["spell_power"] = 10 }),
    };

    /// <summary>
    /// Consumable definitions keyed by item ID, including effect type and effect value.
    /// </summary>
    public static readonly Dictionary<string, ConsumableDef> Consumables = new()
    {
        ["health_potion"] = new("Health Potion", "heal", 20, "Restores 20 HP."),
        ["mana_potion"] = new("Mana Potion", "restore_ap", 3, "Restores 3 AP."),
        ["fire_scroll"] = new("Fire Scroll", "aoe_damage", 30, "Deals 30 fire damage to all enemies."),
        ["speed_elixir"] = new("Speed Elixir", "buff_speed", 5, "Boosts tower attack speed for 5 turns."),
    };

    /// <summary>
    /// Gets an equipment definition by ID.
    /// </summary>
    /// <param name="itemId">The equipment item ID.</param>
    /// <returns>The matching equipment definition, or <c>null</c> when not found.</returns>
    public static ItemDef? GetEquipment(string itemId) => Equipment.GetValueOrDefault(itemId);
    /// <summary>
    /// Gets a consumable definition by ID.
    /// </summary>
    /// <param name="itemId">The consumable item ID.</param>
    /// <returns>The matching consumable definition, or <c>null</c> when not found.</returns>
    public static ConsumableDef? GetConsumable(string itemId) => Consumables.GetValueOrDefault(itemId);

    /// <summary>
    /// Equips an item into its designated slot.
    /// </summary>
    /// <param name="state">The game state containing equipped items.</param>
    /// <param name="itemId">The equipment item ID to equip.</param>
    /// <returns><c>true</c> if the item exists and was equipped; otherwise, <c>false</c>.</returns>
    public static bool Equip(GameState state, string itemId)
    {
        if (!Equipment.TryGetValue(itemId, out var item)) return false;
        string slot = item.Slot.ToString().ToLowerInvariant();
        state.EquippedItems[slot] = itemId;
        return true;
    }

    /// <summary>
    /// Unequips whatever item is currently assigned to the specified slot key.
    /// </summary>
    /// <param name="state">The game state containing equipped items.</param>
    /// <param name="slot">The lowercase slot key used in the equipped items map.</param>
    /// <returns><c>true</c> if an item was removed; otherwise, <c>false</c>.</returns>
    public static bool Unequip(GameState state, string slot)
    {
        return state.EquippedItems.Remove(slot);
    }

    /// <summary>
    /// Aggregates total stat bonuses from all currently equipped items.
    /// </summary>
    /// <param name="state">The game state containing equipped items.</param>
    /// <returns>
    /// A dictionary of stat totals keyed by stat name, with values summed across all equipped items.
    /// </returns>
    public static Dictionary<string, int> GetTotalEquipmentStats(GameState state)
    {
        var totals = new Dictionary<string, int>();
        foreach (var (_, itemId) in state.EquippedItems)
        {
            if (!Equipment.TryGetValue(itemId, out var item)) continue;
            foreach (var (stat, value) in item.Stats)
            {
                totals[stat] = totals.GetValueOrDefault(stat, 0) + value;
            }
        }
        return totals;
    }

    /// <summary>
    /// Gets the display hex color associated with an equipment rarity tier.
    /// </summary>
    /// <param name="rarity">The rarity tier to translate.</param>
    /// <returns>A hex RGB color string for the provided rarity.</returns>
    public static string GetRarityColor(Rarity rarity) => rarity switch
    {
        Rarity.Common => "#FFFFFF",
        Rarity.Uncommon => "#00FF00",
        Rarity.Rare => "#0088FF",
        Rarity.Epic => "#AA00FF",
        Rarity.Legendary => "#FFD700",
        _ => "#FFFFFF",
    };
}

/// <summary>
/// Defines an equipment item and its stat bonuses.
/// </summary>
/// <param name="Name">Display name of the item.</param>
/// <param name="Rarity">Rarity tier of the item.</param>
/// <param name="Slot">Equipment slot where the item can be equipped.</param>
/// <param name="Stats">Stat bonuses granted by the item, keyed by stat name.</param>
public record ItemDef(string Name, Items.Rarity Rarity, Items.SlotType Slot, Dictionary<string, int> Stats);
/// <summary>
/// Defines a consumable item and its effect payload.
/// </summary>
/// <param name="Name">Display name of the consumable.</param>
/// <param name="Effect">Effect ID used by gameplay systems.</param>
/// <param name="Value">Numeric value applied by the effect.</param>
/// <param name="Description">Player-facing description of the consumable.</param>
public record ConsumableDef(string Name, string Effect, int Value, string Description);
