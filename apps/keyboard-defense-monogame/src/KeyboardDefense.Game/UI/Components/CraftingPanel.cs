using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Panel for crafting items from materials.
/// Ported from Godot's crafting UI.
/// </summary>
public class CraftingPanel : BasePanel
{
    private readonly VerticalStackPanel _recipeList;
    private readonly Label _detailLabel;
    private readonly Label _resultLabel;
    private readonly Label _inventoryLabel;

    public CraftingPanel() : base(Locale.Tr("panels.crafting"))
    {
        RootWidget.Width = 600;
        RootWidget.Height = 480;

        _inventoryLabel = new Label
        {
            Text = "Materials: ...",
            TextColor = ThemeColors.Text,
            Wrap = true,
        };
        AddWidget(_inventoryLabel);
        AddWidget(new HorizontalSeparator());

        var split = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

        // Recipe list
        _recipeList = new VerticalStackPanel { Spacing = 4 };
        var listScroll = new ScrollViewer
        {
            Content = _recipeList,
            Width = 250,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(listScroll);

        // Detail + result
        var detailPanel = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        _detailLabel = new Label
        {
            Text = "Select a recipe to view details.",
            TextColor = ThemeColors.Text,
            Wrap = true,
        };
        detailPanel.Widgets.Add(_detailLabel);

        _resultLabel = new Label
        {
            Text = "",
            TextColor = ThemeColors.Success,
            Wrap = true,
        };
        detailPanel.Widgets.Add(_resultLabel);
        split.Widgets.Add(detailPanel);

        AddWidget(split);
    }

    public void Refresh(GameState state)
    {
        // Build inventory summary
        var materials = new List<string>();
        foreach (var (key, val) in state.Inventory)
        {
            int count = Convert.ToInt32(val);
            if (count > 0)
                materials.Add($"{Capitalize(key.Replace('_', ' '))}: {count}");
        }
        _inventoryLabel.Text = materials.Count > 0
            ? "Materials: " + string.Join(", ", materials)
            : "No materials in inventory.";

        // Build recipe list
        _recipeList.Widgets.Clear();

        // Group by category
        var grouped = Crafting.Recipes
            .GroupBy(r => r.Value.Category)
            .OrderBy(g => g.Key);

        foreach (var group in grouped)
        {
            _recipeList.Widgets.Add(new Label
            {
                Text = Capitalize(group.Key),
                TextColor = ThemeColors.AccentCyan,
            });

            foreach (var (id, recipe) in group)
            {
                bool canCraft = Crafting.CanCraft(state, id);
                string recipeId = id;

                var btn = new Button
                {
                    Content = new Label
                    {
                        Text = $"  {recipe.Name} (T{recipe.Tier})",
                        TextColor = canCraft ? ThemeColors.Text : ThemeColors.TextDisabled,
                    },
                    Height = 26,
                    HorizontalAlignment = HorizontalAlignment.Stretch,
                };
                btn.Click += (_, _) =>
                {
                    ShowRecipeDetail(recipeId, state);
                };
                _recipeList.Widgets.Add(btn);
            }
        }
    }

    private void ShowRecipeDetail(string recipeId, GameState state)
    {
        if (!Crafting.Recipes.TryGetValue(recipeId, out var recipe))
        {
            _detailLabel.Text = "Unknown recipe.";
            return;
        }

        bool canCraft = Crafting.CanCraft(state, recipeId);

        var materialLines = recipe.Materials
            .Select(m =>
            {
                int have = 0;
                if (state.Inventory.TryGetValue(m.Key, out var val))
                    have = Convert.ToInt32(val);
                string status = have >= m.Value ? "(OK)" : "(NEED)";
                return $"  {Capitalize(m.Key.Replace('_', ' '))}: {have}/{m.Value} {status}";
            });

        _detailLabel.Text = $"{recipe.Name}\n" +
            $"Category: {Capitalize(recipe.Category)}\n" +
            $"Tier: {recipe.Tier}\n\n" +
            $"Materials:\n{string.Join("\n", materialLines)}\n\n" +
            (canCraft ? "Click Craft to create this item." : "Missing required materials.");
        _detailLabel.TextColor = canCraft ? ThemeColors.Text : ThemeColors.TextDim;

        if (canCraft)
        {
            // Add craft button via executing trade
            var result = Crafting.Craft(state, recipeId);
            string message = result.GetValueOrDefault("message")?.ToString() ?? "Crafted!";
            _resultLabel.Text = message;
            _resultLabel.TextColor = ThemeColors.Success;
            Refresh(state);
        }
        else
        {
            _resultLabel.Text = "";
        }
    }

    private static string Capitalize(string s)
        => string.IsNullOrEmpty(s) ? s : char.ToUpper(s[0]) + s[1..];
}
