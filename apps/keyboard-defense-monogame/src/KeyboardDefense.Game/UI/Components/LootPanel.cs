using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Loot panel showing pending loot and inventory items.
/// Ported from ui/components/loot_panel.gd.
/// </summary>
public class LootPanel : BasePanel
{
    private readonly VerticalStackPanel _pendingList;
    private readonly VerticalStackPanel _inventoryList;
    private readonly Label _pendingHeader;

    public event Action<string>? ItemSelected;

    public LootPanel() : base(Locale.Tr("panels.loot"))
    {
        RootWidget.Width = 500;
        RootWidget.Height = 450;

        // Pending loot section
        _pendingHeader = new Label
        {
            Text = "Pending Loot",
            TextColor = ThemeColors.GoldAccent,
        };
        AddWidget(_pendingHeader);

        _pendingList = new VerticalStackPanel { Spacing = 2 };
        var pendingScroll = new ScrollViewer
        {
            Content = _pendingList,
            Height = 120,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        AddWidget(pendingScroll);

        AddWidget(new HorizontalSeparator());

        // Inventory section
        AddWidget(new Label { Text = "Inventory", TextColor = ThemeColors.AccentCyan });

        _inventoryList = new VerticalStackPanel { Spacing = 2 };
        var invScroll = new ScrollViewer
        {
            Content = _inventoryList,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        AddWidget(invScroll);
    }

    public void Refresh(GameState state)
    {
        // Pending loot
        _pendingList.Widgets.Clear();
        if (state.LootPending.Count == 0)
        {
            _pendingList.Widgets.Add(new Label
            {
                Text = "No pending loot.",
                TextColor = ThemeColors.TextDim,
            });
        }
        else
        {
            foreach (var loot in state.LootPending)
            {
                string name = loot.GetValueOrDefault("name")?.ToString() ?? "Unknown Item";
                string rarity = loot.GetValueOrDefault("rarity")?.ToString() ?? "common";
                Color rarityColor = GetRarityColor(rarity);

                var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
                row.Widgets.Add(new Label { Text = "*", TextColor = rarityColor, Width = 20 });
                row.Widgets.Add(new Label { Text = name, TextColor = rarityColor });
                row.Widgets.Add(new Label
                {
                    Text = $"({rarity})",
                    TextColor = ThemeColors.TextDim,
                });
                _pendingList.Widgets.Add(row);
            }
        }

        _pendingHeader.Text = $"Pending Loot ({state.LootPending.Count})";

        // Inventory
        _inventoryList.Widgets.Clear();
        if (state.Inventory.Count == 0)
        {
            _inventoryList.Widgets.Add(new Label
            {
                Text = "Inventory is empty.",
                TextColor = ThemeColors.TextDim,
            });
        }
        else
        {
            foreach (var (itemId, count) in state.Inventory)
            {
                string itemName = itemId.Replace('_', ' ');
                var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
                row.Widgets.Add(new Label { Text = itemName, TextColor = ThemeColors.Text });
                if (count > 1)
                    row.Widgets.Add(new Label
                    {
                        Text = $"x{count}",
                        TextColor = ThemeColors.TextDim,
                    });

                var btn = new Button
                {
                    Content = new Label { Text = itemName + (count > 1 ? $" x{count}" : "") },
                    Height = 26,
                    HorizontalAlignment = HorizontalAlignment.Stretch,
                };
                string id = itemId;
                btn.Click += (_, _) => ItemSelected?.Invoke(id);
                _inventoryList.Widgets.Add(btn);
            }
        }
    }

    private static Color GetRarityColor(string rarity) => rarity switch
    {
        "common" => ThemeColors.Text,
        "uncommon" => ThemeColors.Success,
        "rare" => ThemeColors.AccentBlue,
        "epic" => ThemeColors.Accent,
        "legendary" => ThemeColors.GoldAccent,
        _ => ThemeColors.Text,
    };
}
