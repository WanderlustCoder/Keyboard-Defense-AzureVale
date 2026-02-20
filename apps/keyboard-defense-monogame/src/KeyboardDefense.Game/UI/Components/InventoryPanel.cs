using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Panel showing player inventory contents and equipped items.
/// Combines inventory view with equipment management.
/// </summary>
public class InventoryPanel : BasePanel
{
    private readonly VerticalStackPanel _inventoryList;
    private readonly VerticalStackPanel _equippedList;
    private readonly Label _detailLabel;

    private string _activeTab = "inventory";

    public InventoryPanel() : base(Locale.Tr("panels.inventory"))
    {
        RootWidget.Width = 600;
        RootWidget.Height = 500;

        // Tab buttons
        var tabBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        var invTab = ButtonFactory.Primary("Items", () => SwitchTab("inventory"));
        invTab.Width = 120;
        var eqTab = ButtonFactory.Secondary("Equipped", () => SwitchTab("equipped"));
        eqTab.Width = 120;
        tabBar.Widgets.Add(invTab);
        tabBar.Widgets.Add(eqTab);
        AddWidget(tabBar);
        AddWidget(new HorizontalSeparator());

        var split = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

        // Inventory list (default visible)
        _inventoryList = new VerticalStackPanel { Spacing = 4 };
        _equippedList = new VerticalStackPanel { Spacing = 4 };
        _equippedList.Visible = false;

        var listContainer = new VerticalStackPanel { Spacing = 4 };
        listContainer.Widgets.Add(_inventoryList);
        listContainer.Widgets.Add(_equippedList);

        var listScroll = new ScrollViewer
        {
            Content = listContainer,
            Width = 260,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(listScroll);

        // Detail panel
        _detailLabel = new Label
        {
            Text = "Select an item to view details.",
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
        RefreshInventory(state);
        RefreshEquipped(state);
    }

    private void SwitchTab(string tab)
    {
        _activeTab = tab;
        _inventoryList.Visible = tab == "inventory";
        _equippedList.Visible = tab == "equipped";
    }

    private void RefreshInventory(GameState state)
    {
        _inventoryList.Widgets.Clear();

        var items = state.Inventory
            .Where(kv => Convert.ToInt32(kv.Value) > 0)
            .OrderBy(kv => kv.Key)
            .ToList();

        if (items.Count == 0)
        {
            _inventoryList.Widgets.Add(new Label
            {
                Text = "Inventory is empty.",
                TextColor = ThemeColors.TextDim,
            });
            return;
        }

        // Group: equipment, consumables, materials
        var groups = new Dictionary<string, List<(string Id, int Count)>>
        {
            ["Equipment"] = new(),
            ["Consumables"] = new(),
            ["Materials"] = new(),
        };

        foreach (var (id, countObj) in items)
        {
            int count = Convert.ToInt32(countObj);
            if (Items.GetEquipment(id) != null)
                groups["Equipment"].Add((id, count));
            else if (Items.GetConsumable(id) != null)
                groups["Consumables"].Add((id, count));
            else
                groups["Materials"].Add((id, count));
        }

        foreach (var (category, groupItems) in groups)
        {
            if (groupItems.Count == 0) continue;

            _inventoryList.Widgets.Add(new Label
            {
                Text = category,
                TextColor = ThemeColors.AccentCyan,
            });

            foreach (var (id, count) in groupItems)
            {
                string itemId = id;
                var btn = new Button
                {
                    Content = new Label
                    {
                        Text = $"  {FormatName(id)} x{count}",
                        TextColor = ThemeColors.Text,
                    },
                    Height = 26,
                    HorizontalAlignment = HorizontalAlignment.Stretch,
                };
                btn.Click += (_, _) => ShowItemDetail(itemId, count);
                _inventoryList.Widgets.Add(btn);
            }
        }
    }

    private void RefreshEquipped(GameState state)
    {
        _equippedList.Widgets.Clear();

        string[] slots = { "weapon", "armor", "helm", "boots", "ring", "charm" };

        _equippedList.Widgets.Add(new Label
        {
            Text = "Equipment Slots",
            TextColor = ThemeColors.AccentCyan,
        });

        foreach (string slot in slots)
        {
            bool hasItem = state.EquippedItems.TryGetValue(slot, out string? itemId)
                           && !string.IsNullOrEmpty(itemId);

            var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
            row.Widgets.Add(new Label
            {
                Text = Capitalize(slot) + ":",
                TextColor = ThemeColors.TextDim,
                Width = 80,
            });
            row.Widgets.Add(new Label
            {
                Text = hasItem ? FormatName(itemId!) : "(empty)",
                TextColor = hasItem ? ThemeColors.Text : ThemeColors.TextDisabled,
            });

            _equippedList.Widgets.Add(row);
        }

        // Stats summary
        var stats = Items.GetTotalEquipmentStats(state);
        if (stats.Count > 0)
        {
            _equippedList.Widgets.Add(new HorizontalSeparator());
            _equippedList.Widgets.Add(new Label
            {
                Text = "Bonuses:",
                TextColor = ThemeColors.Accent,
            });
            foreach (var (stat, value) in stats)
            {
                _equippedList.Widgets.Add(new Label
                {
                    Text = $"  {Capitalize(stat)}: +{value}",
                    TextColor = ThemeColors.Success,
                });
            }
        }
    }

    private void ShowItemDetail(string itemId, int count)
    {
        var equip = Items.GetEquipment(itemId);
        if (equip != null)
        {
            var statsLines = equip.Stats.Select(kv => $"  {Capitalize(kv.Key)}: +{kv.Value}");
            _detailLabel.Text = $"{equip.Name}\n" +
                $"Rarity: {equip.Rarity}\n" +
                $"Slot: {equip.Slot}\n" +
                $"Count: {count}\n\n" +
                $"Stats:\n{string.Join("\n", statsLines)}";
            _detailLabel.TextColor = ThemeColors.Text;
            return;
        }

        var consumable = Items.GetConsumable(itemId);
        if (consumable != null)
        {
            _detailLabel.Text = $"{consumable.Name}\n" +
                $"Effect: {consumable.Effect}\n" +
                $"Value: {consumable.Value}\n" +
                $"Count: {count}";
            _detailLabel.TextColor = ThemeColors.Text;
            return;
        }

        _detailLabel.Text = $"{FormatName(itemId)}\nMaterial\nCount: {count}";
        _detailLabel.TextColor = ThemeColors.TextDim;
    }

    private static string FormatName(string id)
        => string.Join(" ", id.Split('_').Select(Capitalize));

    private static string Capitalize(string s)
        => string.IsNullOrEmpty(s) ? s : char.ToUpper(s[0]) + s[1..];
}
