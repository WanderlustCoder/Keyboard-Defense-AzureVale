using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Equipment panel showing equipped items and gear slots.
/// Ported from ui/components/equipment_panel.gd.
/// </summary>
public class EquipmentPanel : BasePanel
{
    private static readonly string[] Slots = { "weapon", "armor", "helm", "boots", "ring", "charm" };

    private readonly Dictionary<string, Label> _slotLabels = new();
    private readonly Label _statsLabel;

    public event Action<string>? SlotClicked;

    public EquipmentPanel() : base(Locale.Tr("panels.equipment"))
    {
        RootWidget.Width = 500;
        RootWidget.Height = 400;

        // Hero info
        AddWidget(new Label { Text = "Equipped Gear", TextColor = ThemeColors.Accent });
        AddWidget(new HorizontalSeparator());

        // Equipment slots
        var grid = new VerticalStackPanel { Spacing = 4 };
        foreach (string slot in Slots)
        {
            var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
            row.Widgets.Add(new Label
            {
                Text = Capitalize(slot) + ":",
                TextColor = ThemeColors.TextDim,
                Width = 80,
            });

            var itemLabel = new Label
            {
                Text = "(empty)",
                TextColor = ThemeColors.TextDisabled,
            };
            _slotLabels[slot] = itemLabel;

            var slotBtn = new Button
            {
                Content = itemLabel,
                Height = 30,
                Width = 300,
                HorizontalAlignment = HorizontalAlignment.Left,
            };
            string s = slot;
            slotBtn.Click += (_, _) => SlotClicked?.Invoke(s);
            row.Widgets.Add(slotBtn);

            grid.Widgets.Add(row);
        }
        AddWidget(grid);

        AddWidget(new HorizontalSeparator());

        // Stats summary
        AddWidget(new Label { Text = "Bonuses", TextColor = ThemeColors.AccentCyan });
        _statsLabel = new Label
        {
            Text = "No equipment bonuses active.",
            TextColor = ThemeColors.TextDim,
            Wrap = true,
        };
        AddWidget(_statsLabel);
    }

    public void Refresh(GameState state)
    {
        foreach (string slot in Slots)
        {
            if (_slotLabels.TryGetValue(slot, out var label))
            {
                if (state.EquippedItems.TryGetValue(slot, out string? itemId) && !string.IsNullOrEmpty(itemId))
                {
                    label.Text = itemId.Replace('_', ' ');
                    label.TextColor = ThemeColors.Text;
                }
                else
                {
                    label.Text = "(empty)";
                    label.TextColor = ThemeColors.TextDisabled;
                }
            }
        }

        // Compute bonuses from equipped items
        int equippedCount = 0;
        foreach (var (_, itemId) in state.EquippedItems)
        {
            if (!string.IsNullOrEmpty(itemId))
                equippedCount++;
        }

        _statsLabel.Text = equippedCount > 0
            ? $"{equippedCount} item{(equippedCount != 1 ? "s" : "")} equipped."
            : "No equipment bonuses active.";
    }

    private static string Capitalize(string s)
        => string.IsNullOrEmpty(s) ? s : char.ToUpper(s[0]) + s[1..];
}
