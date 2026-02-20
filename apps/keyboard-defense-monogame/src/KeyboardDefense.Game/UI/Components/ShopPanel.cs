using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Shop panel for buying and selling items.
/// Ported from ui/components/shop_panel.gd.
/// </summary>
public class ShopPanel : BasePanel
{
    private readonly Label _goldLabel;
    private readonly VerticalStackPanel _shopList;
    private readonly Label _detailLabel;

    private static readonly (string Id, string Name, int Cost, string Description)[] ShopItems =
    {
        ("health_potion", "Health Potion", 25, "Restores 5 HP."),
        ("speed_scroll", "Speed Scroll", 40, "Increases typing speed bonus for 1 night."),
        ("shield_ward", "Shield Ward", 60, "Blocks the next 3 damage."),
        ("damage_rune", "Damage Rune", 80, "Increases tower damage by 20% for 1 night."),
        ("worker_contract", "Worker Contract", 100, "Hire an additional worker."),
        ("map_fragment", "Map Fragment", 50, "Reveals a 5x5 area on the map."),
        ("lucky_charm", "Lucky Charm", 120, "Improves loot quality for 3 nights."),
        ("training_manual", "Training Manual", 150, "Grants 2 skill points."),
    };

    public ShopPanel() : base(Locale.Tr("panels.shop"))
    {
        RootWidget.Width = 550;
        RootWidget.Height = 450;

        _goldLabel = new Label
        {
            Text = "Gold: 0",
            TextColor = ThemeColors.GoldAccent,
        };
        AddWidget(_goldLabel);
        AddWidget(new HorizontalSeparator());

        var split = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

        // Item list
        _shopList = new VerticalStackPanel { Spacing = 4 };
        var listScroll = new ScrollViewer
        {
            Content = _shopList,
            Width = 250,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(listScroll);

        // Detail + buy button
        var detailPanel = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        _detailLabel = new Label
        {
            Text = "Select an item to view details.",
            TextColor = ThemeColors.Text,
            Wrap = true,
        };
        detailPanel.Widgets.Add(_detailLabel);
        split.Widgets.Add(detailPanel);

        AddWidget(split);
    }

    public void Refresh(GameState state)
    {
        _goldLabel.Text = $"Gold: {state.Gold}";
        _shopList.Widgets.Clear();

        foreach (var (id, name, cost, desc) in ShopItems)
        {
            bool canAfford = state.Gold >= cost;
            Color textColor = canAfford ? ThemeColors.Text : ThemeColors.TextDisabled;

            var btn = new Button
            {
                Content = new Label
                {
                    Text = $"{name} ({cost}g)",
                    TextColor = textColor,
                },
                Height = 30,
                HorizontalAlignment = HorizontalAlignment.Stretch,
                Enabled = canAfford,
            };

            string itemId = id;
            string itemDesc = desc;
            int itemCost = cost;
            string itemName = name;

            btn.Click += (_, _) =>
            {
                _detailLabel.Text = $"{itemName}\nCost: {itemCost} gold\n\n{itemDesc}";
                _detailLabel.TextColor = ThemeColors.Text;

                // Buy via command
                GameController.Instance.ApplyCommand($"buy {itemId}");
                Refresh(GameController.Instance.State);
            };
            _shopList.Widgets.Add(btn);
        }
    }
}
