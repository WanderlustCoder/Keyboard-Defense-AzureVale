using System.Collections.Generic;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class ItemsCoreTests
{
    [Fact]
    public void EquipmentRegistry_HasEightItems()
    {
        Assert.Equal(8, Items.Equipment.Count);
    }

    [Fact]
    public void EquipmentRegistry_EntriesHaveNamesAndStats()
    {
        foreach (var (itemId, item) in Items.Equipment)
        {
            Assert.False(string.IsNullOrWhiteSpace(itemId));
            Assert.False(string.IsNullOrWhiteSpace(item.Name));
            Assert.NotEmpty(item.Stats);
        }
    }

    [Fact]
    public void ConsumablesRegistry_HasFourItems()
    {
        Assert.Equal(4, Items.Consumables.Count);
    }

    [Fact]
    public void ConsumablesRegistry_EntriesHaveRequiredFields()
    {
        foreach (var (itemId, item) in Items.Consumables)
        {
            Assert.False(string.IsNullOrWhiteSpace(itemId));
            Assert.False(string.IsNullOrWhiteSpace(item.Name));
            Assert.False(string.IsNullOrWhiteSpace(item.Effect));
            Assert.False(string.IsNullOrWhiteSpace(item.Description));
        }
    }

    [Fact]
    public void GetEquipment_KnownId_ReturnsItem()
    {
        var item = Items.GetEquipment("power_ring");

        Assert.NotNull(item);
        Assert.Equal("Ring of Power", item.Name);
        Assert.Equal(Items.Rarity.Rare, item.Rarity);
        Assert.Equal(Items.SlotType.Ring, item.Slot);
    }

    [Fact]
    public void GetEquipment_UnknownId_ReturnsNull()
    {
        var item = Items.GetEquipment("missing_item");

        Assert.Null(item);
    }

    [Fact]
    public void GetConsumable_KnownId_ReturnsConsumable()
    {
        var item = Items.GetConsumable("fire_scroll");

        Assert.NotNull(item);
        Assert.Equal("Fire Scroll", item.Name);
        Assert.Equal("aoe_damage", item.Effect);
        Assert.Equal(30, item.Value);
    }

    [Fact]
    public void GetConsumable_UnknownId_ReturnsNull()
    {
        var item = Items.GetConsumable("missing_consumable");

        Assert.Null(item);
    }

    [Fact]
    public void Equip_ValidItem_ReturnsTrue()
    {
        var state = CreateState();

        var equipped = Items.Equip(state, "steel_armor");

        Assert.True(equipped);
    }

    [Fact]
    public void Equip_ValidItem_SetsExpectedSlot()
    {
        var state = CreateState();

        Items.Equip(state, "steel_armor");

        Assert.Equal("steel_armor", state.EquippedItems["armor"]);
    }

    [Fact]
    public void Equip_UnknownItem_ReturnsFalse()
    {
        var state = CreateState();

        var equipped = Items.Equip(state, "unknown");

        Assert.False(equipped);
    }

    [Fact]
    public void Equip_UnknownItem_DoesNotModifyEquippedItems()
    {
        var state = CreateState();
        Items.Equip(state, "iron_sword");

        var equipped = Items.Equip(state, "unknown");

        Assert.False(equipped);
        Assert.Single(state.EquippedItems);
        Assert.Equal("iron_sword", state.EquippedItems["weapon"]);
    }

    [Fact]
    public void Equip_ReplacesExistingItemInSameSlot()
    {
        var state = CreateState();
        Items.Equip(state, "iron_sword");

        var equipped = Items.Equip(state, "steel_sword");

        Assert.True(equipped);
        Assert.Single(state.EquippedItems);
        Assert.Equal("steel_sword", state.EquippedItems["weapon"]);
    }

    [Fact]
    public void Unequip_ExistingSlot_ReturnsTrue()
    {
        var state = CreateState();
        Items.Equip(state, "swift_boots");

        var removed = Items.Unequip(state, "boots");

        Assert.True(removed);
    }

    [Fact]
    public void Unequip_ExistingSlot_RemovesItem()
    {
        var state = CreateState();
        Items.Equip(state, "swift_boots");

        Items.Unequip(state, "boots");

        Assert.Empty(state.EquippedItems);
    }

    [Fact]
    public void Unequip_EmptySlot_ReturnsFalse()
    {
        var state = CreateState();

        var removed = Items.Unequip(state, "helmet");

        Assert.False(removed);
    }

    [Fact]
    public void GetTotalEquipmentStats_WithNoItems_ReturnsEmpty()
    {
        var state = CreateState();

        var totals = Items.GetTotalEquipmentStats(state);

        Assert.Empty(totals);
    }

    [Fact]
    public void GetTotalEquipmentStats_WithMultipleItems_StacksStats()
    {
        var state = CreateState();
        Items.Equip(state, "steel_sword");
        Items.Equip(state, "power_ring");
        Items.Equip(state, "steel_armor");
        Items.Equip(state, "guardian_shield");
        Items.Equip(state, "arcane_amulet");

        var totals = Items.GetTotalEquipmentStats(state);

        Assert.Equal(5, totals.Count);
        Assert.Equal(18, totals["damage"]);
        Assert.Equal(5, totals["accuracy_bonus"]);
        Assert.Equal(11, totals["armor"]);
        Assert.Equal(10, totals["hp_bonus"]);
        Assert.Equal(10, totals["spell_power"]);
    }

    [Fact]
    public void GetRarityColor_ReturnsExpectedHexForAllRarities()
    {
        Assert.Equal("#FFFFFF", Items.GetRarityColor(Items.Rarity.Common));
        Assert.Equal("#00FF00", Items.GetRarityColor(Items.Rarity.Uncommon));
        Assert.Equal("#0088FF", Items.GetRarityColor(Items.Rarity.Rare));
        Assert.Equal("#AA00FF", Items.GetRarityColor(Items.Rarity.Epic));
        Assert.Equal("#FFD700", Items.GetRarityColor(Items.Rarity.Legendary));
    }

    [Fact]
    public void ItemDef_Properties_AreSet()
    {
        var stats = new Dictionary<string, int>
        {
            ["damage"] = 42,
            ["crit"] = 7,
        };
        var item = new ItemDef("Test Blade", Items.Rarity.Legendary, Items.SlotType.Weapon, stats);

        Assert.Equal("Test Blade", item.Name);
        Assert.Equal(Items.Rarity.Legendary, item.Rarity);
        Assert.Equal(Items.SlotType.Weapon, item.Slot);
        Assert.Equal(2, item.Stats.Count);
        Assert.Equal(42, item.Stats["damage"]);
        Assert.Equal(7, item.Stats["crit"]);
    }

    private static GameState CreateState()
    {
        var state = new GameState();
        state.EquippedItems.Clear();
        return state;
    }
}
