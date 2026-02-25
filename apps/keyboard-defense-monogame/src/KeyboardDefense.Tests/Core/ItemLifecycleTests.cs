using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class ItemLifecycleTests
{
    private const int ConsumableStackLimit = 99;

    [Fact]
    public void CraftItemFromResources_AddsCraftedItemToInventory()
    {
        var state = CreateState("craft_item");
        state.Inventory["iron_ore"] = 2;

        var result = Crafting.Craft(state, "iron_ingot");

        Assert.True((bool)result["success"]);
        Assert.Equal(0, state.Inventory["iron_ore"]);
        Assert.Equal(1, state.Inventory["iron_ingot"]);
    }

    [Fact]
    public void EquipCraftedItem_AppliesEquipmentStats()
    {
        var state = CreateState("equip_crafted");
        state.Inventory["iron_ingot"] = 3;
        state.Inventory["wood"] = 1;

        var craft = Crafting.Craft(state, "iron_sword");
        bool equipped = Items.Equip(state, "iron_sword");
        Dictionary<string, int> totals = Items.GetTotalEquipmentStats(state);

        Assert.True((bool)craft["success"]);
        Assert.True(equipped);
        Assert.Equal("iron_sword", state.EquippedItems["weapon"]);
        Assert.Equal(3, totals["damage"]);
    }

    [Fact]
    public void UnequipItem_RemovesEquipmentStats()
    {
        var state = CreateState("unequip_item");
        state.Inventory["iron_sword"] = 1;
        Items.Equip(state, "iron_sword");

        var before = Items.GetTotalEquipmentStats(state);
        bool removed = Items.Unequip(state, "weapon");
        var after = Items.GetTotalEquipmentStats(state);

        Assert.Equal(3, before["damage"]);
        Assert.True(removed);
        Assert.Empty(after);
    }

    [Fact]
    public void TradeInventoryItemForResources_ConsumesItemAndAddsResources()
    {
        var state = CreateState("trade_item");
        state.Inventory["iron_sword"] = 1;
        state.Resources["wood"] = 0;

        var result = TradeInventoryItemForResources(state, "iron_sword", "wood", itemAmount: 1, resourcePerItem: 5);

        Assert.True((bool)result["success"]);
        Assert.Equal(0, state.Inventory.GetValueOrDefault("iron_sword", 0));
        Assert.Equal(5, state.Resources["wood"]);
    }

    [Fact]
    public void EquipBetterItemInSameSlot_ReplacesOldItemStats()
    {
        var state = CreateState("better_same_slot");
        state.Inventory["iron_sword"] = 1;
        state.Inventory["steel_sword"] = 1;

        Items.Equip(state, "iron_sword");
        Items.Equip(state, "steel_sword");
        Dictionary<string, int> totals = Items.GetTotalEquipmentStats(state);

        Assert.Equal("steel_sword", state.EquippedItems["weapon"]);
        Assert.Single(state.EquippedItems);
        Assert.Equal(6, totals["damage"]);
    }

    [Fact]
    public void UseConsumable_AppliesEffectAndConsumesOne()
    {
        var state = CreateState("use_consumable");
        state.Ap = 0;
        state.ApMax = 5;
        state.Inventory["mana_potion"] = 1;

        var result = UseConsumable(state, "mana_potion");

        Assert.True((bool)result["success"]);
        Assert.Equal(3, state.Ap);
        Assert.Equal(0, state.Inventory.GetValueOrDefault("mana_potion", 0));
    }

    [Fact]
    public void UseConsumable_WhenMissing_ReturnsErrorAndDoesNotMutate()
    {
        var state = CreateState("use_missing_consumable");
        state.Hp = 6;

        var result = UseConsumable(state, "health_potion");

        Assert.False((bool)result["success"]);
        Assert.Equal("Consumable not in inventory.", result["error"]);
        Assert.Equal(6, state.Hp);
    }

    [Fact]
    public void InventoryPersistsAcrossSaveLoad_WithCraftedAndEquippedItems()
    {
        var state = CreateState("save_load_inventory");
        state.Inventory["herb"] = 2;
        state.Inventory["water"] = 1;
        state.Inventory["iron_ingot"] = 3;
        state.Inventory["wood"] = 1;

        var potionCraft = Crafting.Craft(state, "health_potion");
        var swordCraft = Crafting.Craft(state, "iron_sword");
        Items.Equip(state, "iron_sword");

        var (ok, loaded, error) = SaveManager.StateFromDict(SaveManager.StateToDict(state));

        Assert.True((bool)potionCraft["success"]);
        Assert.True((bool)swordCraft["success"]);
        Assert.True(ok, error);
        Assert.NotNull(loaded);
        Assert.Equal(1, loaded!.Inventory["health_potion"]);
        Assert.Equal(1, loaded.Inventory["iron_sword"]);
        Assert.Equal("iron_sword", loaded.EquippedItems["weapon"]);
    }

    [Fact]
    public void ConsumableStacks_AreCappedAtConfiguredLimit()
    {
        var state = CreateState("consumable_stack_limit");
        state.Inventory["health_potion"] = 98;

        int firstAdded = AddConsumablesWithStackLimit(state, "health_potion", 5, ConsumableStackLimit);
        int secondAdded = AddConsumablesWithStackLimit(state, "health_potion", 1, ConsumableStackLimit);

        Assert.Equal(1, firstAdded);
        Assert.Equal(0, secondAdded);
        Assert.Equal(ConsumableStackLimit, state.Inventory["health_potion"]);
    }

    private static GameState CreateState(string seed)
    {
        return DefaultState.Create($"item_lifecycle_{seed}");
    }

    private static Dictionary<string, object> TradeInventoryItemForResources(
        GameState state,
        string itemId,
        string resourceId,
        int itemAmount,
        int resourcePerItem)
    {
        if (itemAmount <= 0)
            return Error("Item amount must be positive.");

        if (resourcePerItem <= 0)
            return Error("Resource rate must be positive.");

        int current = state.Inventory.GetValueOrDefault(itemId, 0);
        if (current < itemAmount)
            return Error($"Not enough {itemId} (have {current}, need {itemAmount}).");

        int remaining = current - itemAmount;
        if (remaining > 0)
            state.Inventory[itemId] = remaining;
        else
            state.Inventory.Remove(itemId);

        int gained = itemAmount * resourcePerItem;
        state.Resources[resourceId] = state.Resources.GetValueOrDefault(resourceId, 0) + gained;

        return new Dictionary<string, object>
        {
            ["success"] = true,
            ["item"] = itemId,
            ["spent"] = itemAmount,
            ["resource"] = resourceId,
            ["gained"] = gained
        };
    }

    private static Dictionary<string, object> UseConsumable(GameState state, string itemId)
    {
        int current = state.Inventory.GetValueOrDefault(itemId, 0);
        if (current <= 0)
            return Error("Consumable not in inventory.");

        ConsumableDef? consumable = Items.GetConsumable(itemId);
        if (consumable == null)
            return Error("Unknown consumable.");

        switch (consumable.Effect)
        {
            case "heal":
                EventEffects.ApplyEffect(state, new Dictionary<string, object>
                {
                    ["type"] = "heal_castle",
                    ["amount"] = consumable.Value
                });
                break;
            case "restore_ap":
                EventEffects.ApplyEffect(state, new Dictionary<string, object>
                {
                    ["type"] = "ap_add",
                    ["amount"] = consumable.Value
                });
                break;
            case "aoe_damage":
                for (int i = state.Enemies.Count - 1; i >= 0; i--)
                {
                    var enemy = state.Enemies[i];
                    int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", 0));
                    hp -= consumable.Value;
                    if (hp <= 0)
                        state.Enemies.RemoveAt(i);
                    else
                        enemy["hp"] = hp;
                }
                break;
            case "buff_speed":
                Buffs.AddBuff(state, "speed_elixir", consumable.Value, new Dictionary<string, double>
                {
                    ["enemy_speed_multiplier"] = -0.10
                });
                break;
            default:
                return Error($"Unsupported consumable effect: {consumable.Effect}");
        }

        int remaining = current - 1;
        if (remaining > 0)
            state.Inventory[itemId] = remaining;
        else
            state.Inventory.Remove(itemId);

        return new Dictionary<string, object>
        {
            ["success"] = true,
            ["item"] = itemId,
            ["effect"] = consumable.Effect
        };
    }

    private static int AddConsumablesWithStackLimit(GameState state, string itemId, int amount, int maxStack)
    {
        if (amount <= 0 || maxStack <= 0)
            return 0;

        if (Items.GetConsumable(itemId) == null)
            return 0;

        int current = state.Inventory.GetValueOrDefault(itemId, 0);
        int next = Math.Min(maxStack, current + amount);

        if (next > 0)
            state.Inventory[itemId] = next;
        else
            state.Inventory.Remove(itemId);

        return next - current;
    }

    private static Dictionary<string, object> Error(string message)
    {
        return new Dictionary<string, object>
        {
            ["success"] = false,
            ["error"] = message
        };
    }
}
