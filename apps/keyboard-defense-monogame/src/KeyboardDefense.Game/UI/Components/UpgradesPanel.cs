using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Panel showing kingdom and unit upgrades available for purchase.
/// Ported from Godot's upgrade system UI.
/// </summary>
public class UpgradesPanel : BasePanel
{
    private readonly Label _goldLabel;
    private readonly VerticalStackPanel _kingdomList;
    private readonly VerticalStackPanel _unitList;
    private readonly Label _detailLabel;

    private string _activeTab = "kingdom";

    public UpgradesPanel() : base(Locale.Tr("panels.upgrades"))
    {
        RootWidget.Width = 600;
        RootWidget.Height = 500;

        _goldLabel = new Label
        {
            Text = "Gold: 0",
            TextColor = ThemeColors.GoldAccent,
        };
        AddWidget(_goldLabel);

        // Tab buttons
        var tabBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        var kingdomTab = ButtonFactory.Primary("Kingdom", () => SwitchTab("kingdom"));
        kingdomTab.Width = 120;
        var unitTab = ButtonFactory.Secondary("Units", () => SwitchTab("unit"));
        unitTab.Width = 120;
        tabBar.Widgets.Add(kingdomTab);
        tabBar.Widgets.Add(unitTab);
        AddWidget(tabBar);

        AddWidget(new HorizontalSeparator());

        var split = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

        // Upgrade lists
        _kingdomList = new VerticalStackPanel { Spacing = 4 };
        _unitList = new VerticalStackPanel { Spacing = 4 };
        _unitList.Visible = false;

        var listPanel = new Panel();
        var listScroll = new ScrollViewer
        {
            Width = 260,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        var listContainer = new VerticalStackPanel { Spacing = 4 };
        listContainer.Widgets.Add(_kingdomList);
        listContainer.Widgets.Add(_unitList);
        listScroll.Content = listContainer;
        split.Widgets.Add(listScroll);

        // Detail panel
        _detailLabel = new Label
        {
            Text = "Select an upgrade to view details.",
            TextColor = ThemeColors.Text,
            Wrap = true,
        };
        var detailScroll = new ScrollViewer
        {
            Content = _detailLabel,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(detailScroll);

        AddWidget(split);
    }

    public void Refresh(GameState state)
    {
        _goldLabel.Text = $"Gold: {state.Gold}";
        BuildUpgradeList(_kingdomList, Upgrades.GetKingdomUpgrades(), state, "kingdom");
        BuildUpgradeList(_unitList, Upgrades.GetUnitUpgrades(), state, "unit");
    }

    private void SwitchTab(string tab)
    {
        _activeTab = tab;
        _kingdomList.Visible = tab == "kingdom";
        _unitList.Visible = tab == "unit";
    }

    private void BuildUpgradeList(VerticalStackPanel list, List<Dictionary<string, object>> upgrades,
        GameState state, string category)
    {
        list.Widgets.Clear();

        if (upgrades.Count == 0)
        {
            list.Widgets.Add(new Label
            {
                Text = "No upgrades available.",
                TextColor = ThemeColors.TextDim,
            });
            return;
        }

        var purchased = category == "kingdom" ? state.PurchasedKingdomUpgrades : state.PurchasedUnitUpgrades;

        foreach (var upgrade in upgrades)
        {
            string id = upgrade.GetValueOrDefault("id")?.ToString() ?? "";
            string name = upgrade.GetValueOrDefault("name")?.ToString() ?? id;
            int cost = Convert.ToInt32(upgrade.GetValueOrDefault("gold_cost", 0));
            bool owned = purchased.Contains(id);

            var check = Upgrades.CanPurchase(state, id, category);
            bool canBuy = check.GetValueOrDefault("ok") is true;

            Color textColor = owned ? ThemeColors.Success : canBuy ? ThemeColors.Text : ThemeColors.TextDisabled;
            string prefix = owned ? "[+] " : "";

            string upgradeId = id;
            string upgradeName = name;
            string cat = category;
            var btn = new Button
            {
                Content = new Label
                {
                    Text = $"{prefix}{name} ({cost}g)",
                    TextColor = textColor,
                },
                Height = 28,
                HorizontalAlignment = HorizontalAlignment.Stretch,
                Enabled = !owned,
            };
            btn.Click += (_, _) =>
            {
                ShowDetail(upgrade, state, cat);
                if (canBuy && !owned)
                {
                    Upgrades.Purchase(state, upgradeId, cat);
                    Refresh(state);
                }
            };
            list.Widgets.Add(btn);
        }
    }

    private void ShowDetail(Dictionary<string, object> upgrade, GameState state, string category)
    {
        string name = upgrade.GetValueOrDefault("name")?.ToString() ?? "";
        string desc = upgrade.GetValueOrDefault("description")?.ToString() ?? "No description.";
        int cost = Convert.ToInt32(upgrade.GetValueOrDefault("gold_cost", 0));
        string requires = upgrade.GetValueOrDefault("requires")?.ToString() ?? "";

        var purchased = category == "kingdom" ? state.PurchasedKingdomUpgrades : state.PurchasedUnitUpgrades;
        bool owned = purchased.Contains(upgrade.GetValueOrDefault("id")?.ToString() ?? "");

        _detailLabel.Text = $"{name}\n\nCost: {cost} gold\n{desc}" +
            (string.IsNullOrEmpty(requires) ? "" : $"\nRequires: {requires}") +
            $"\nStatus: {(owned ? "PURCHASED" : "Available")}";
        _detailLabel.TextColor = owned ? ThemeColors.Success : ThemeColors.Text;
    }
}
