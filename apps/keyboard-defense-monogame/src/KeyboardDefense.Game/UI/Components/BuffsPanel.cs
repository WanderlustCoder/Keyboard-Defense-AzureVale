using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Panel showing active buffs and their remaining durations.
/// Ported from Godot's buff display UI.
/// </summary>
public class BuffsPanel : BasePanel
{
    private readonly VerticalStackPanel _buffList;
    private readonly Label _summaryLabel;

    public BuffsPanel() : base(Locale.Tr("panels.buffs"))
    {
        RootWidget.Width = 450;
        RootWidget.Height = 380;

        _summaryLabel = new Label
        {
            Text = "No active buffs.",
            TextColor = ThemeColors.TextDim,
        };
        AddWidget(_summaryLabel);
        AddWidget(new HorizontalSeparator());

        _buffList = new VerticalStackPanel { Spacing = 6 };
        var scroll = new ScrollViewer
        {
            Content = _buffList,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        AddWidget(scroll);

        // Multiplier summary at bottom
        AddWidget(new HorizontalSeparator());
        AddWidget(new Label
        {
            Text = "Active multipliers are applied automatically each turn.",
            TextColor = ThemeColors.TextDim,
        });
    }

    public void Refresh(GameState state)
    {
        _buffList.Widgets.Clear();

        if (state.ActiveBuffs.Count == 0)
        {
            _summaryLabel.Text = "No active buffs.";
            _summaryLabel.TextColor = ThemeColors.TextDim;
            return;
        }

        _summaryLabel.Text = $"{state.ActiveBuffs.Count} active buff{(state.ActiveBuffs.Count != 1 ? "s" : "")}";
        _summaryLabel.TextColor = ThemeColors.BuffActive;

        foreach (var buff in state.ActiveBuffs)
        {
            string buffId = buff.GetValueOrDefault("buff_id")?.ToString() ?? "unknown";
            int remaining = Convert.ToInt32(buff.GetValueOrDefault("remaining_days", 0));

            var buffRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

            // Buff name
            buffRow.Widgets.Add(new Label
            {
                Text = FormatBuffName(buffId),
                TextColor = ThemeColors.BuffActive,
                Width = 180,
            });

            // Duration
            Color durationColor = remaining <= 1 ? ThemeColors.Error : remaining <= 3 ? ThemeColors.Warning : ThemeColors.Text;
            buffRow.Widgets.Add(new Label
            {
                Text = $"{remaining} day{(remaining != 1 ? "s" : "")} left",
                TextColor = durationColor,
                Width = 100,
            });

            // Effects summary
            var effects = new List<string>();
            foreach (var (key, val) in buff)
            {
                if (key == "buff_id" || key == "remaining_days") continue;
                double dVal = Convert.ToDouble(val);
                if (Math.Abs(dVal) > 0.001)
                    effects.Add($"{FormatEffectName(key)}: {FormatEffectValue(dVal)}");
            }

            if (effects.Count > 0)
            {
                buffRow.Widgets.Add(new Label
                {
                    Text = string.Join(", ", effects),
                    TextColor = ThemeColors.AccentCyan,
                });
            }

            _buffList.Widgets.Add(buffRow);
        }

        // Active multiplier summary
        AddMultiplierSummary(state);
    }

    private void AddMultiplierSummary(GameState state)
    {
        double dmg = Buffs.GetDamageMultiplier(state);
        double res = Buffs.GetResourceMultiplier(state);
        double gold = Buffs.GetGoldMultiplier(state);

        if (dmg > 0 || res > 0 || gold > 0)
        {
            var summaryItems = new List<string>();
            if (dmg > 0) summaryItems.Add($"Damage: x{dmg:F1}");
            if (res > 0) summaryItems.Add($"Resources: x{res:F1}");
            if (gold > 0) summaryItems.Add($"Gold: x{gold:F1}");

            _buffList.Widgets.Add(new HorizontalSeparator());
            _buffList.Widgets.Add(new Label
            {
                Text = "Totals: " + string.Join("  ", summaryItems),
                TextColor = ThemeColors.Accent,
            });
        }
    }

    private static string FormatBuffName(string buffId)
        => string.Join(" ", buffId.Split('_')).ToUpper()[0] +
           string.Join(" ", buffId.Split('_'))[1..];

    private static string FormatEffectName(string key)
    {
        return key.Replace("_", " ");
    }

    private static string FormatEffectValue(double val)
    {
        if (val >= 1.0) return $"+{val:F1}";
        if (val > 0) return $"x{val:F2}";
        return $"{val:F2}";
    }
}
