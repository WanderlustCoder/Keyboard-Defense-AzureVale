using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for Crafting — all recipes, chain crafting, stack overflow,
/// tier/category validation, and inventory edge cases.
/// </summary>
public class CraftingExtendedTests
{
    // =========================================================================
    // Recipe registry — completeness
    // =========================================================================

    [Fact]
    public void Recipes_HasSevenEntries()
    {
        Assert.Equal(7, Crafting.Recipes.Count);
    }

    [Theory]
    [InlineData("iron_ingot", "Iron Ingot", "material", 1)]
    [InlineData("steel_ingot", "Steel Ingot", "material", 2)]
    [InlineData("health_potion", "Health Potion", "consumable", 1)]
    [InlineData("mana_potion", "Mana Potion", "consumable", 1)]
    [InlineData("iron_sword", "Iron Sword", "equipment", 2)]
    [InlineData("steel_armor", "Steel Armor", "equipment", 3)]
    [InlineData("fire_scroll", "Fire Scroll", "consumable", 2)]
    public void Recipes_AllHaveCorrectMetadata(string id, string name, string category, int tier)
    {
        Assert.True(Crafting.Recipes.TryGetValue(id, out var recipe));
        Assert.Equal(name, recipe!.Name);
        Assert.Equal(category, recipe.Category);
        Assert.Equal(tier, recipe.Tier);
    }

    [Fact]
    public void Recipes_AllHaveNonEmptyMaterials()
    {
        foreach (var (id, recipe) in Crafting.Recipes)
        {
            Assert.NotEmpty(recipe.Materials);
            Assert.All(recipe.Materials, kvp =>
            {
                Assert.False(string.IsNullOrEmpty(kvp.Key), $"Recipe '{id}' has empty material key");
                Assert.True(kvp.Value > 0, $"Recipe '{id}' has non-positive material amount for '{kvp.Key}'");
            });
        }
    }

    // =========================================================================
    // CanCraft — specific recipes
    // =========================================================================

    [Fact]
    public void CanCraft_IronIngot_NeedsIronOre()
    {
        var state = CreateState(("iron_ore", 2));
        Assert.True(Crafting.CanCraft(state, "iron_ingot"));
    }

    [Fact]
    public void CanCraft_IronIngot_NotEnoughOre_ReturnsFalse()
    {
        var state = CreateState(("iron_ore", 1));
        Assert.False(Crafting.CanCraft(state, "iron_ingot"));
    }

    [Fact]
    public void CanCraft_SteelIngot_NeedsBothMaterials()
    {
        // Only one material
        var state1 = CreateState(("iron_ingot", 2));
        Assert.False(Crafting.CanCraft(state1, "steel_ingot"));

        // Both materials
        var state2 = CreateState(("iron_ingot", 2), ("coal", 1));
        Assert.True(Crafting.CanCraft(state2, "steel_ingot"));
    }

    [Fact]
    public void CanCraft_HealthPotion_NeedsHerbAndWater()
    {
        var state = CreateState(("herb", 2), ("water", 1));
        Assert.True(Crafting.CanCraft(state, "health_potion"));
    }

    [Fact]
    public void CanCraft_FireScroll_NeedsParchmentAndFireEssence()
    {
        var state = CreateState(("parchment", 1), ("fire_essence", 1));
        Assert.True(Crafting.CanCraft(state, "fire_scroll"));
    }

    [Fact]
    public void CanCraft_SteelArmor_NeedsFourSteelIngotTwoLeather()
    {
        var state = CreateState(("steel_ingot", 4), ("leather", 2));
        Assert.True(Crafting.CanCraft(state, "steel_armor"));

        var incomplete = CreateState(("steel_ingot", 3), ("leather", 2));
        Assert.False(Crafting.CanCraft(incomplete, "steel_armor"));
    }

    [Fact]
    public void CanCraft_ExcessMaterials_StillReturnsTrue()
    {
        var state = CreateState(("iron_ore", 100));
        Assert.True(Crafting.CanCraft(state, "iron_ingot"));
    }

    // =========================================================================
    // Craft — chain crafting (iron_ore → iron_ingot → steel_ingot)
    // =========================================================================

    [Fact]
    public void Craft_ChainCrafting_OreToIngotToSteel()
    {
        var state = CreateState(("iron_ore", 4), ("coal", 1));

        // Craft 2 iron ingots from 4 ore
        Crafting.Craft(state, "iron_ingot");
        Crafting.Craft(state, "iron_ingot");

        Assert.Equal(0, state.Inventory["iron_ore"]);
        Assert.Equal(2, state.Inventory["iron_ingot"]);

        // Now craft steel ingot
        var result = Crafting.Craft(state, "steel_ingot");

        Assert.True((bool)result["success"]);
        Assert.Equal(0, state.Inventory["iron_ingot"]);
        Assert.Equal(0, state.Inventory["coal"]);
        Assert.Equal(1, state.Inventory["steel_ingot"]);
    }

    // =========================================================================
    // Craft — stack overflow protection
    // =========================================================================

    [Fact]
    public void Craft_StackAt998_IncreasesToMaxOf999()
    {
        var state = CreateState(("iron_ore", 2));
        state.Inventory["iron_ingot"] = 998;

        Crafting.Craft(state, "iron_ingot");

        Assert.Equal(999, state.Inventory["iron_ingot"]);
    }

    [Fact]
    public void Craft_StackAt999_DoesNotExceedCap()
    {
        var state = CreateState(("iron_ore", 2));
        state.Inventory["iron_ingot"] = 999;

        Crafting.Craft(state, "iron_ingot");

        // Still capped at 999
        Assert.Equal(999, state.Inventory["iron_ingot"]);
    }

    // =========================================================================
    // Craft — material consumption is exact
    // =========================================================================

    [Fact]
    public void Craft_ConsumesExactMaterialAmounts()
    {
        var state = CreateState(("herb", 10), ("water", 5));

        Crafting.Craft(state, "health_potion");

        Assert.Equal(8, state.Inventory["herb"]); // consumed 2
        Assert.Equal(4, state.Inventory["water"]); // consumed 1
    }

    [Fact]
    public void Craft_MaterialGoesToZero_SetToZero()
    {
        var state = CreateState(("iron_ore", 2));

        Crafting.Craft(state, "iron_ingot");

        Assert.Equal(0, state.Inventory["iron_ore"]);
    }

    // =========================================================================
    // Craft — result payload
    // =========================================================================

    [Theory]
    [InlineData("iron_ingot", "Iron Ingot")]
    [InlineData("health_potion", "Health Potion")]
    [InlineData("fire_scroll", "Fire Scroll")]
    public void Craft_SuccessPayload_HasCorrectFields(string recipeId, string expectedName)
    {
        var state = CreateStateForRecipe(recipeId);

        var result = Crafting.Craft(state, recipeId);

        Assert.True((bool)result["success"]);
        Assert.Equal(recipeId, result["item"]);
        Assert.Equal(expectedName, result["name"]);
        Assert.Equal($"Crafted {expectedName}!", result["message"]);
    }

    // =========================================================================
    // GetAvailableRecipes — comprehensive
    // =========================================================================

    [Fact]
    public void GetAvailableRecipes_EmptyInventory_ReturnsEmpty()
    {
        var state = new GameState();
        Assert.Empty(Crafting.GetAvailableRecipes(state));
    }

    [Fact]
    public void GetAvailableRecipes_AllMaterialsForAll_ReturnsAll()
    {
        var state = new GameState();
        // Provide materials for every recipe
        state.Inventory["iron_ore"] = 100;
        state.Inventory["iron_ingot"] = 100;
        state.Inventory["coal"] = 100;
        state.Inventory["herb"] = 100;
        state.Inventory["water"] = 100;
        state.Inventory["crystal"] = 100;
        state.Inventory["wood"] = 100;
        state.Inventory["steel_ingot"] = 100;
        state.Inventory["leather"] = 100;
        state.Inventory["parchment"] = 100;
        state.Inventory["fire_essence"] = 100;

        var available = Crafting.GetAvailableRecipes(state);

        Assert.Equal(7, available.Count);
    }

    [Fact]
    public void GetAvailableRecipes_ReturnsOnlyCraftable()
    {
        // Only materials for mana_potion
        var state = CreateState(("crystal", 1), ("water", 1));

        var available = Crafting.GetAvailableRecipes(state);

        Assert.Single(available);
        Assert.Equal("mana_potion", available[0]);
    }

    // =========================================================================
    // Craft — double craft depletes materials
    // =========================================================================

    [Fact]
    public void Craft_TwoHealthPotions_ConsumesFourHerbTwoWater()
    {
        var state = CreateState(("herb", 4), ("water", 2));

        Crafting.Craft(state, "health_potion");
        Crafting.Craft(state, "health_potion");

        Assert.Equal(0, state.Inventory["herb"]);
        Assert.Equal(0, state.Inventory["water"]);
        Assert.Equal(2, state.Inventory["health_potion"]);
    }

    [Fact]
    public void Craft_SecondCraftFails_WhenMaterialsInsufficient()
    {
        var state = CreateState(("iron_ore", 3));

        var first = Crafting.Craft(state, "iron_ingot");
        Assert.True((bool)first["success"]);

        var second = Crafting.Craft(state, "iron_ingot");
        Assert.False((bool)second["success"]);
        Assert.Equal("Missing materials.", second["error"]);
    }

    // =========================================================================
    // CraftingRecipe record
    // =========================================================================

    [Fact]
    public void CraftingRecipe_IsRecord_WithExpectedFields()
    {
        var recipe = new CraftingRecipe("Test", new() { ["a"] = 1 }, "test_cat", 5);
        Assert.Equal("Test", recipe.Name);
        Assert.Equal("test_cat", recipe.Category);
        Assert.Equal(5, recipe.Tier);
        Assert.Equal(1, recipe.Materials["a"]);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static GameState CreateState(params (string id, int count)[] items)
    {
        var state = new GameState();
        foreach (var (id, count) in items)
            state.Inventory[id] = count;
        return state;
    }

    /// <summary>
    /// Creates a state with sufficient materials for a given recipe.
    /// </summary>
    private static GameState CreateStateForRecipe(string recipeId)
    {
        var state = new GameState();
        if (Crafting.Recipes.TryGetValue(recipeId, out var recipe))
        {
            foreach (var (material, amount) in recipe.Materials)
                state.Inventory[material] = amount;
        }
        return state;
    }
}
