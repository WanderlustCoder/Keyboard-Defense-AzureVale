using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class ItemsTests
{
    [Fact]
    public void Equipment_ContainsKnownItems()
    {
        Assert.NotEmpty(Items.Equipment);
        Assert.True(Items.Equipment.ContainsKey("iron_sword"));
        Assert.True(Items.Equipment.ContainsKey("steel_armor"));
        Assert.True(Items.Equipment.ContainsKey("power_ring"));
    }

    [Fact]
    public void Consumables_ContainsKnownItems()
    {
        Assert.NotEmpty(Items.Consumables);
        Assert.True(Items.Consumables.ContainsKey("health_potion"));
        Assert.True(Items.Consumables.ContainsKey("mana_potion"));
    }

    [Fact]
    public void GetEquipment_ValidId_ReturnsDef()
    {
        var sword = Items.GetEquipment("iron_sword");
        Assert.NotNull(sword);
        Assert.Equal("Iron Sword", sword!.Name);
        Assert.Equal(Items.Rarity.Common, sword.Rarity);
        Assert.Equal(Items.SlotType.Weapon, sword.Slot);
        Assert.True(sword.Stats.ContainsKey("damage"));
    }

    [Fact]
    public void GetEquipment_InvalidId_ReturnsNull()
    {
        Assert.Null(Items.GetEquipment("nonexistent"));
    }

    [Fact]
    public void GetConsumable_ValidId_ReturnsDef()
    {
        var potion = Items.GetConsumable("health_potion");
        Assert.NotNull(potion);
        Assert.Equal("Health Potion", potion!.Name);
        Assert.Equal("heal", potion.Effect);
        Assert.True(potion.Value > 0);
    }

    [Fact]
    public void Equip_ValidItem_ReturnsTrue()
    {
        var state = new GameState();
        bool result = Items.Equip(state, "iron_sword");
        Assert.True(result);
        Assert.True(state.EquippedItems.ContainsKey("weapon"));
        Assert.Equal("iron_sword", state.EquippedItems["weapon"]);
    }

    [Fact]
    public void Equip_InvalidItem_ReturnsFalse()
    {
        var state = new GameState();
        Assert.False(Items.Equip(state, "nonexistent"));
    }

    [Fact]
    public void Unequip_EquippedSlot_ReturnsTrue()
    {
        var state = new GameState();
        Items.Equip(state, "iron_sword");
        bool result = Items.Unequip(state, "weapon");
        Assert.True(result);
        Assert.False(state.EquippedItems.ContainsKey("weapon"));
    }

    [Fact]
    public void Unequip_EmptySlot_ReturnsFalse()
    {
        var state = new GameState();
        Assert.False(Items.Unequip(state, "weapon"));
    }

    [Fact]
    public void GetTotalEquipmentStats_SingleItem()
    {
        var state = new GameState();
        Items.Equip(state, "iron_sword");
        var stats = Items.GetTotalEquipmentStats(state);
        Assert.True(stats.ContainsKey("damage"));
        Assert.Equal(3, stats["damage"]);
    }

    [Fact]
    public void GetTotalEquipmentStats_MultipleItems_Stacks()
    {
        var state = new GameState();
        Items.Equip(state, "iron_sword");
        Items.Equip(state, "iron_armor");
        var stats = Items.GetTotalEquipmentStats(state);
        Assert.True(stats.ContainsKey("damage"));
        Assert.True(stats.ContainsKey("armor"));
    }

    [Fact]
    public void GetRarityColor_ReturnsColorForEachRarity()
    {
        Assert.NotEmpty(Items.GetRarityColor(Items.Rarity.Common));
        Assert.NotEmpty(Items.GetRarityColor(Items.Rarity.Legendary));
        Assert.NotEqual(
            Items.GetRarityColor(Items.Rarity.Common),
            Items.GetRarityColor(Items.Rarity.Legendary));
    }
}

public class TradeTests
{
    [Fact]
    public void BaseRates_ContainsCommonResources()
    {
        Assert.True(Trade.BaseRates.ContainsKey("wood"));
        Assert.True(Trade.BaseRates.ContainsKey("stone"));
        Assert.True(Trade.BaseRates.ContainsKey("food"));
    }

    [Fact]
    public void GetExchangeRate_ValidPair_ReturnsPositive()
    {
        double rate = Trade.GetExchangeRate("wood", "stone");
        Assert.True(rate > 0);
    }

    [Fact]
    public void GetExchangeRate_InvalidPair_ReturnsZero()
    {
        Assert.Equal(0, Trade.GetExchangeRate("wood", "nonexistent"));
        Assert.Equal(0, Trade.GetExchangeRate("nonexistent", "wood"));
    }

    [Fact]
    public void ExecuteTrade_ValidTrade_Succeeds()
    {
        var state = new GameState();
        state.Resources["wood"] = 10;
        state.Resources["stone"] = 0;

        var result = Trade.ExecuteTrade(state, "wood", "stone", 5);
        Assert.True((bool)result["success"]);
        Assert.Equal(5, state.Resources["wood"]);
        Assert.True(state.Resources["stone"] > 0);
    }

    [Fact]
    public void ExecuteTrade_InsufficientResources_Fails()
    {
        var state = new GameState();
        state.Resources["wood"] = 2;

        var result = Trade.ExecuteTrade(state, "wood", "stone", 10);
        Assert.False((bool)result["success"]);
        Assert.Equal(2, state.Resources["wood"]); // unchanged
    }

    [Fact]
    public void ExecuteTrade_SameResource_Fails()
    {
        var state = new GameState();
        state.Resources["wood"] = 10;

        var result = Trade.ExecuteTrade(state, "wood", "wood", 5);
        Assert.False((bool)result["success"]);
    }

    [Fact]
    public void ExecuteTrade_ZeroAmount_Fails()
    {
        var state = new GameState();
        state.Resources["wood"] = 10;

        var result = Trade.ExecuteTrade(state, "wood", "stone", 0);
        Assert.False((bool)result["success"]);
    }

    [Fact]
    public void ExecuteTrade_NegativeAmount_Fails()
    {
        var state = new GameState();
        state.Resources["wood"] = 10;

        var result = Trade.ExecuteTrade(state, "wood", "stone", -5);
        Assert.False((bool)result["success"]);
    }
}

public class CraftingTests
{
    [Fact]
    public void Recipes_ContainsKnownRecipes()
    {
        Assert.NotEmpty(Crafting.Recipes);
        Assert.True(Crafting.Recipes.ContainsKey("iron_ingot"));
        Assert.True(Crafting.Recipes.ContainsKey("health_potion"));
    }

    [Fact]
    public void CanCraft_WithMaterials_ReturnsTrue()
    {
        var state = new GameState();
        state.Inventory["iron_ore"] = 5;

        Assert.True(Crafting.CanCraft(state, "iron_ingot"));
    }

    [Fact]
    public void CanCraft_WithoutMaterials_ReturnsFalse()
    {
        var state = new GameState();
        Assert.False(Crafting.CanCraft(state, "iron_ingot"));
    }

    [Fact]
    public void CanCraft_UnknownRecipe_ReturnsFalse()
    {
        var state = new GameState();
        Assert.False(Crafting.CanCraft(state, "nonexistent"));
    }

    [Fact]
    public void Craft_WithMaterials_Succeeds()
    {
        var state = new GameState();
        state.Inventory["iron_ore"] = 5;

        var result = Crafting.Craft(state, "iron_ingot");
        Assert.True((bool)result["success"]);
        Assert.Equal("iron_ingot", result["item"]);
    }

    [Fact]
    public void Craft_ConsumesMaterials()
    {
        var state = new GameState();
        state.Inventory["iron_ore"] = 5;

        Crafting.Craft(state, "iron_ingot");

        // iron_ingot recipe needs 2 iron_ore
        Assert.Equal(3, Convert.ToInt32(state.Inventory["iron_ore"]));
    }

    [Fact]
    public void Craft_AddsToInventory()
    {
        var state = new GameState();
        state.Inventory["iron_ore"] = 5;

        Crafting.Craft(state, "iron_ingot");

        Assert.True(state.Inventory.ContainsKey("iron_ingot"));
        Assert.Equal(1, Convert.ToInt32(state.Inventory["iron_ingot"]));
    }

    [Fact]
    public void Craft_WithoutMaterials_Fails()
    {
        var state = new GameState();
        var result = Crafting.Craft(state, "iron_ingot");
        Assert.False((bool)result["success"]);
    }

    [Fact]
    public void Craft_UnknownRecipe_Fails()
    {
        var state = new GameState();
        var result = Crafting.Craft(state, "nonexistent");
        Assert.False((bool)result["success"]);
    }

    [Fact]
    public void GetAvailableRecipes_NoMaterials_ReturnsEmpty()
    {
        var state = new GameState();
        var available = Crafting.GetAvailableRecipes(state);
        Assert.Empty(available);
    }

    [Fact]
    public void GetAvailableRecipes_WithMaterials_ReturnsMatching()
    {
        var state = new GameState();
        state.Inventory["iron_ore"] = 10;

        var available = Crafting.GetAvailableRecipes(state);
        Assert.Contains("iron_ingot", available);
    }
}
