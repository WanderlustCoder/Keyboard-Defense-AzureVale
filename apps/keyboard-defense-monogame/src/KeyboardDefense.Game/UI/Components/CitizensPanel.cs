using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Citizens panel showing citizen roster, professions, morale, and skill levels.
/// Wires to Core/Economy/Citizens.cs.
/// </summary>
public class CitizensPanel : BasePanel
{
    private readonly VerticalStackPanel _content;

    public CitizensPanel() : base(Locale.Tr("panels.citizens"))
    {
        RootWidget.Width = 550;
        RootWidget.Height = 500;

        _content = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        var scroll = new ScrollViewer
        {
            Content = _content,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        AddWidget(scroll);
    }

    public void Refresh(GameState state)
    {
        _content.Widgets.Clear();

        var citizens = Citizens.GetCitizens(state);

        // Summary
        var summary = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        summary.Widgets.Add(new Label
        {
            Text = $"Citizens: {citizens.Count}",
            TextColor = ThemeColors.AccentCyan,
        });

        // Count by profession
        var profCounts = new Dictionary<string, int>();
        int totalMorale = 0;
        foreach (var citizen in citizens)
        {
            string prof = citizen.GetValueOrDefault("profession", "").ToString() ?? "unknown";
            profCounts[prof] = profCounts.GetValueOrDefault(prof, 0) + 1;
            totalMorale += Convert.ToInt32(citizen.GetValueOrDefault("morale", 50));
        }
        double avgMorale = citizens.Count > 0 ? (double)totalMorale / citizens.Count : 0;
        summary.Widgets.Add(new Label
        {
            Text = $"Avg Morale: {avgMorale:F0}",
            TextColor = GetMoraleColor((int)avgMorale),
        });
        _content.Widgets.Add(summary);

        // Profession breakdown
        if (profCounts.Count > 0)
        {
            var profRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
            foreach (var (prof, count) in profCounts)
            {
                profRow.Widgets.Add(new Label
                {
                    Text = $"{prof}: {count}",
                    TextColor = GetProfessionColor(prof),
                });
            }
            _content.Widgets.Add(profRow);
        }

        _content.Widgets.Add(new HorizontalSeparator());

        // Citizen list
        if (citizens.Count == 0)
        {
            _content.Widgets.Add(new Label
            {
                Text = "No citizens yet. Hire workers to gain citizens.",
                TextColor = ThemeColors.TextDim,
            });
            return;
        }

        // Header row
        var header = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        header.Widgets.Add(new Label { Text = "Name", TextColor = ThemeColors.TextDim, Width = 140 });
        header.Widgets.Add(new Label { Text = "Profession", TextColor = ThemeColors.TextDim, Width = 100 });
        header.Widgets.Add(new Label { Text = "Level", TextColor = ThemeColors.TextDim, Width = 50 });
        header.Widgets.Add(new Label { Text = "XP", TextColor = ThemeColors.TextDim, Width = 60 });
        header.Widgets.Add(new Label { Text = "Morale", TextColor = ThemeColors.TextDim, Width = 60 });
        header.Widgets.Add(new Label { Text = "Bonus", TextColor = ThemeColors.TextDim, Width = 60 });
        _content.Widgets.Add(header);

        foreach (var citizen in citizens)
        {
            string name = citizen.GetValueOrDefault("name", "").ToString() ?? "Unknown";
            string prof = citizen.GetValueOrDefault("profession", "").ToString() ?? "unknown";
            int level = Convert.ToInt32(citizen.GetValueOrDefault("skill_level", 1));
            int xp = Convert.ToInt32(citizen.GetValueOrDefault("skill_xp", 0));
            int morale = Convert.ToInt32(citizen.GetValueOrDefault("morale", 50));
            double bonus = Citizens.GetProductionBonus(citizen);
            int assignedTo = Convert.ToInt32(citizen.GetValueOrDefault("assigned_to", -1));

            var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
            row.Widgets.Add(new Label { Text = name, TextColor = ThemeColors.Text, Width = 140 });
            row.Widgets.Add(new Label
            {
                Text = prof,
                TextColor = GetProfessionColor(prof),
                Width = 100,
            });
            row.Widgets.Add(new Label
            {
                Text = $"Lv{level}",
                TextColor = level >= 3 ? ThemeColors.Accent : ThemeColors.TextDim,
                Width = 50,
            });
            row.Widgets.Add(new Label
            {
                Text = $"{xp}/{level * 5}",
                TextColor = ThemeColors.TextDim,
                Width = 60,
            });
            row.Widgets.Add(new Label
            {
                Text = $"{morale}",
                TextColor = GetMoraleColor(morale),
                Width = 60,
            });
            row.Widgets.Add(new Label
            {
                Text = $"x{bonus:F2}",
                TextColor = bonus > 1.0 ? ThemeColors.Success : bonus < 1.0 ? ThemeColors.Error : ThemeColors.TextDim,
                Width = 60,
            });

            _content.Widgets.Add(row);
        }
    }

    private static Color GetMoraleColor(int morale)
    {
        if (morale >= 75) return ThemeColors.Success;
        if (morale >= 50) return ThemeColors.Info;
        if (morale >= 25) return ThemeColors.Warning;
        return ThemeColors.Error;
    }

    private static Color GetProfessionColor(string profession) => profession switch
    {
        "farmer" => ThemeColors.ResourceFood,
        "woodcutter" => ThemeColors.ResourceWood,
        "miner" => ThemeColors.ResourceStone,
        "builder" => ThemeColors.Info,
        "scholar" => ThemeColors.AccentCyan,
        "merchant" => ThemeColors.GoldAccent,
        "guard" => ThemeColors.Error,
        "artisan" => ThemeColors.RarityRare,
        _ => ThemeColors.TextDim,
    };
}
