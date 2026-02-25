using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Economy;

/// <summary>
/// Material crafting and recipe system.
/// Ported from sim/crafting.gd.
/// </summary>
public static class Crafting
{
    /// <summary>
    /// Crafting recipes indexed by recipe ID.
    /// Recipes: iron_ingot (2 iron_ore), steel_ingot (2 iron_ingot + 1 coal),
    /// health_potion (2 herb + 1 water), mana_potion (1 crystal + 1 water),
    /// iron_sword (3 iron_ingot + 1 wood), steel_armor (4 steel_ingot + 2 leather),
    /// and fire_scroll (1 parchment + 1 fire_essence).
    /// </summary>
    public static readonly Dictionary<string, CraftingRecipe> Recipes = new()
    {
        ["iron_ingot"] = new("Iron Ingot", new() { ["iron_ore"] = 2 }, "material", 1),
        ["steel_ingot"] = new("Steel Ingot", new() { ["iron_ingot"] = 2, ["coal"] = 1 }, "material", 2),
        ["health_potion"] = new("Health Potion", new() { ["herb"] = 2, ["water"] = 1 }, "consumable", 1),
        ["mana_potion"] = new("Mana Potion", new() { ["crystal"] = 1, ["water"] = 1 }, "consumable", 1),
        ["iron_sword"] = new("Iron Sword", new() { ["iron_ingot"] = 3, ["wood"] = 1 }, "equipment", 2),
        ["steel_armor"] = new("Steel Armor", new() { ["steel_ingot"] = 4, ["leather"] = 2 }, "equipment", 3),
        ["fire_scroll"] = new("Fire Scroll", new() { ["parchment"] = 1, ["fire_essence"] = 1 }, "consumable", 2),
    };

    /// <summary>
    /// Checks whether the player inventory contains all materials required by a recipe.
    /// </summary>
    /// <param name="state">The game state containing inventory materials.</param>
    /// <param name="recipeId">The recipe ID to validate.</param>
    /// <returns><c>true</c> when all required materials are available; otherwise, <c>false</c>.</returns>
    public static bool CanCraft(GameState state, string recipeId)
    {
        if (!Recipes.TryGetValue(recipeId, out var recipe)) return false;
        foreach (var (material, needed) in recipe.Materials)
        {
            int have = GetMaterialCount(state, material);
            if (have < needed) return false;
        }
        return true;
    }

    /// <summary>
    /// Crafts an item by consuming recipe materials and adding the crafted item to inventory.
    /// </summary>
    /// <param name="state">The game state to mutate.</param>
    /// <param name="recipeId">The recipe ID to craft.</param>
    /// <returns>
    /// A result dictionary containing <c>success</c> and crafted item metadata on success,
    /// or an <c>error</c> entry when the recipe is unknown or materials are missing.
    /// </returns>
    public static Dictionary<string, object> Craft(GameState state, string recipeId)
    {
        if (!Recipes.TryGetValue(recipeId, out var recipe))
            return new() { ["success"] = false, ["error"] = "Unknown recipe." };

        if (!CanCraft(state, recipeId))
            return new() { ["success"] = false, ["error"] = "Missing materials." };

        // Consume materials
        foreach (var (material, needed) in recipe.Materials)
        {
            RemoveMaterial(state, material, needed);
        }

        // Add crafted item to inventory
        AddToInventory(state, recipeId);

        return new Dictionary<string, object>
        {
            ["success"] = true,
            ["item"] = recipeId,
            ["name"] = recipe.Name,
            ["message"] = $"Crafted {recipe.Name}!"
        };
    }

    /// <summary>
    /// Gets all recipe IDs that are currently craftable with the player's inventory.
    /// </summary>
    /// <param name="state">The game state containing inventory materials.</param>
    /// <returns>A list of recipe IDs that pass <see cref="CanCraft(GameState, string)"/>.</returns>
    public static List<string> GetAvailableRecipes(GameState state)
    {
        return Recipes.Keys.Where(id => CanCraft(state, id)).ToList();
    }

    private static int GetMaterialCount(GameState state, string material)
    {
        if (state.Inventory.TryGetValue(material, out var val))
            return Convert.ToInt32(val);
        return 0;
    }

    private static void RemoveMaterial(GameState state, string material, int amount)
    {
        int current = GetMaterialCount(state, material);
        state.Inventory[material] = Math.Max(0, current - amount);
    }

    private static void AddToInventory(GameState state, string item)
    {
        int current = 0;
        if (state.Inventory.TryGetValue(item, out var val))
            current = Convert.ToInt32(val);
        state.Inventory[item] = current + 1;
    }
}

/// <summary>
/// Defines a crafting recipe, including output metadata and required input materials.
/// </summary>
/// <param name="Name">Display name for the crafted item.</param>
/// <param name="Materials">Required materials and amounts keyed by material ID.</param>
/// <param name="Category">Recipe category such as material, consumable, or equipment.</param>
/// <param name="Tier">Recipe tier used for progression or balancing.</param>
public record CraftingRecipe(string Name, Dictionary<string, int> Materials, string Category, int Tier);
