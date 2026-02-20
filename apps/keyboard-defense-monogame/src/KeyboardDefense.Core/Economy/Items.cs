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
    public enum Rarity { Common, Uncommon, Rare, Epic, Legendary }
    public enum SlotType { Weapon, Armor, Helmet, Boots, Ring, Amulet, Shield, Cape }

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

    public static readonly Dictionary<string, ConsumableDef> Consumables = new()
    {
        ["health_potion"] = new("Health Potion", "heal", 20, "Restores 20 HP."),
        ["mana_potion"] = new("Mana Potion", "restore_ap", 3, "Restores 3 AP."),
        ["fire_scroll"] = new("Fire Scroll", "aoe_damage", 30, "Deals 30 fire damage to all enemies."),
        ["speed_elixir"] = new("Speed Elixir", "buff_speed", 5, "Boosts tower attack speed for 5 turns."),
    };

    public static ItemDef? GetEquipment(string itemId) => Equipment.GetValueOrDefault(itemId);
    public static ConsumableDef? GetConsumable(string itemId) => Consumables.GetValueOrDefault(itemId);

    public static bool Equip(GameState state, string itemId)
    {
        if (!Equipment.TryGetValue(itemId, out var item)) return false;
        string slot = item.Slot.ToString().ToLowerInvariant();
        state.EquippedItems[slot] = itemId;
        return true;
    }

    public static bool Unequip(GameState state, string slot)
    {
        return state.EquippedItems.Remove(slot);
    }

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

public record ItemDef(string Name, Items.Rarity Rarity, Items.SlotType Slot, Dictionary<string, int> Stats);
public record ConsumableDef(string Name, string Effect, int Value, string Description);
