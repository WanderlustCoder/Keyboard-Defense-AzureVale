using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class CraftingTests
{
    [Fact]
    public void Recipes_KnownRecipe_HasExpectedDefinition()
    {
        Assert.True(Crafting.Recipes.TryGetValue("iron_sword", out var recipe));
        Assert.NotNull(recipe);
        Assert.Equal("Iron Sword", recipe!.Name);
        Assert.Equal("equipment", recipe.Category);
        Assert.Equal(2, recipe.Tier);
        Assert.Equal(3, recipe.Materials["iron_ingot"]);
        Assert.Equal(1, recipe.Materials["wood"]);
    }

    [Fact]
    public void CanCraft_UnknownRecipe_ReturnsFalse()
    {
        var state = new GameState();

        Assert.False(Crafting.CanCraft(state, "unknown_recipe"));
    }

    [Fact]
    public void CanCraft_WhenRequiredMaterialMissing_ReturnsFalse()
    {
        var state = CreateState(("iron_ingot", 2));

        Assert.False(Crafting.CanCraft(state, "steel_ingot"));
    }

    [Fact]
    public void CanCraft_WithExactRequiredMaterials_ReturnsTrue()
    {
        var state = CreateState(("iron_ingot", 2), ("coal", 1));

        Assert.True(Crafting.CanCraft(state, "steel_ingot"));
    }

    [Fact]
    public void Craft_UnknownRecipe_ReturnsError_AndLeavesInventoryUnchanged()
    {
        var state = CreateState(("iron_ore", 3));

        var result = Crafting.Craft(state, "unknown_recipe");

        Assert.False((bool)result["success"]);
        Assert.Equal("Unknown recipe.", result["error"]);
        Assert.Single(state.Inventory);
        Assert.Equal(3, state.Inventory["iron_ore"]);
    }

    [Fact]
    public void Craft_InsufficientMaterials_ReturnsError_AndDoesNotConsumeOrCreateItem()
    {
        var state = CreateState(("herb", 2));

        var result = Crafting.Craft(state, "health_potion");

        Assert.False((bool)result["success"]);
        Assert.Equal("Missing materials.", result["error"]);
        Assert.Equal(2, state.Inventory["herb"]);
        Assert.False(state.Inventory.ContainsKey("health_potion"));
    }

    [Fact]
    public void Craft_Success_ConsumesAllRecipeMaterials()
    {
        var state = CreateState(("iron_ingot", 5), ("coal", 2));

        var result = Crafting.Craft(state, "steel_ingot");

        Assert.True((bool)result["success"]);
        Assert.Equal(3, state.Inventory["iron_ingot"]);
        Assert.Equal(1, state.Inventory["coal"]);
    }

    [Fact]
    public void Craft_Success_CreatesItem_AndReturnsExpectedPayload()
    {
        var state = CreateState(("iron_ore", 2));

        var result = Crafting.Craft(state, "iron_ingot");

        Assert.True((bool)result["success"]);
        Assert.Equal("iron_ingot", result["item"]);
        Assert.Equal("Iron Ingot", result["name"]);
        Assert.Equal("Crafted Iron Ingot!", result["message"]);
        Assert.Equal(1, state.Inventory["iron_ingot"]);
    }

    [Fact]
    public void Craft_Success_WhenOutputAlreadyExists_IncrementsExistingStack()
    {
        var state = CreateState(("iron_ore", 2), ("iron_ingot", 4));

        var result = Crafting.Craft(state, "iron_ingot");

        Assert.True((bool)result["success"]);
        Assert.Equal(0, state.Inventory["iron_ore"]);
        Assert.Equal(5, state.Inventory["iron_ingot"]);
    }

    [Fact]
    public void GetAvailableRecipes_ReturnsOnlyCraftableRecipes()
    {
        var state = CreateState(("iron_ore", 2), ("herb", 2), ("water", 1));

        var available = Crafting.GetAvailableRecipes(state);

        Assert.Contains("iron_ingot", available);
        Assert.Contains("health_potion", available);
        Assert.DoesNotContain("steel_ingot", available);
        Assert.DoesNotContain("fire_scroll", available);
    }

    private static GameState CreateState(params (string id, int count)[] inventoryItems)
    {
        var state = new GameState();
        foreach (var (id, count) in inventoryItems)
            state.Inventory[id] = count;
        return state;
    }
}
