using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Research panel showing tech tree, active research progress, and available projects.
/// Wires to Core/Data/ResearchData.cs.
/// </summary>
public class ResearchPanel : BasePanel
{
    private readonly VerticalStackPanel _content;
    private GameState? _state;

    public ResearchPanel() : base(Locale.Tr("panels.research"))
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
        _state = state;
        _content.Widgets.Clear();

        // Active research
        if (!string.IsNullOrEmpty(state.ActiveResearch))
        {
            var def = ResearchData.GetResearch(state.ActiveResearch);
            if (def != null)
            {
                _content.Widgets.Add(new Label
                {
                    Text = "Active Research",
                    TextColor = ThemeColors.AccentCyan,
                });

                var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
                row.Widgets.Add(new Label { Text = def.Name, TextColor = ThemeColors.Accent, Width = 200 });
                row.Widgets.Add(new Label
                {
                    Text = $"Progress: {state.ResearchProgress}/{def.WavesRequired} waves",
                    TextColor = ThemeColors.Info,
                });
                _content.Widgets.Add(row);

                // Progress bar (text-based)
                int filled = (int)(10.0 * state.ResearchProgress / def.WavesRequired);
                string bar = new string('#', filled) + new string('-', 10 - filled);
                _content.Widgets.Add(new Label
                {
                    Text = $"[{bar}]",
                    TextColor = ThemeColors.AccentBlue,
                });
            }
        }
        else
        {
            _content.Widgets.Add(new Label
            {
                Text = "No active research. Choose a project below.",
                TextColor = ThemeColors.TextDim,
            });
        }

        _content.Widgets.Add(new HorizontalSeparator());

        // Completed research
        if (state.CompletedResearch.Count > 0)
        {
            _content.Widgets.Add(new Label
            {
                Text = $"Completed ({state.CompletedResearch.Count})",
                TextColor = ThemeColors.Success,
            });

            foreach (string id in state.CompletedResearch)
            {
                var def = ResearchData.GetResearch(id);
                if (def == null) continue;
                var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
                row.Widgets.Add(new Label { Text = "[+]", TextColor = ThemeColors.Success, Width = 30 });
                row.Widgets.Add(new Label { Text = def.Name, TextColor = ThemeColors.TextDim, Width = 180 });
                row.Widgets.Add(new Label
                {
                    Text = FormatEffects(def.Effects),
                    TextColor = ThemeColors.AccentBlue,
                });
                _content.Widgets.Add(row);
            }
            _content.Widgets.Add(new HorizontalSeparator());
        }

        // Available research
        var available = ResearchData.GetAvailableResearch(state);
        _content.Widgets.Add(new Label
        {
            Text = $"Available Research ({available.Count})",
            TextColor = ThemeColors.Accent,
        });

        _content.Widgets.Add(new Label
        {
            Text = $"Gold: {state.Gold}",
            TextColor = ThemeColors.GoldAccent,
        });

        foreach (string id in available)
        {
            var def = ResearchData.GetResearch(id);
            if (def == null) continue;

            var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
            row.Widgets.Add(new Label { Text = def.Name, TextColor = ThemeColors.Text, Width = 180 });
            row.Widgets.Add(new Label
            {
                Text = $"{def.GoldCost}g",
                TextColor = state.Gold >= def.GoldCost ? ThemeColors.GoldAccent : ThemeColors.Error,
                Width = 50,
            });
            row.Widgets.Add(new Label
            {
                Text = $"{def.WavesRequired}w",
                TextColor = ThemeColors.TextDim,
                Width = 30,
            });
            row.Widgets.Add(new Label
            {
                Text = $"[{def.Category}]",
                TextColor = GetCategoryColor(def.Category),
                Width = 80,
            });

            if (string.IsNullOrEmpty(state.ActiveResearch) && state.Gold >= def.GoldCost)
            {
                var startBtn = ButtonFactory.Primary("Start", () => OnStartResearch(id));
                startBtn.Width = 70;
                startBtn.Height = 26;
                row.Widgets.Add(startBtn);
            }
            _content.Widgets.Add(row);

            // Show effects
            _content.Widgets.Add(new Label
            {
                Text = $"  Effect: {FormatEffects(def.Effects)}",
                TextColor = ThemeColors.TextDim,
            });

            // Show prerequisite
            if (!string.IsNullOrEmpty(def.Prerequisite))
            {
                var prereqDef = ResearchData.GetResearch(def.Prerequisite);
                string prereqName = prereqDef?.Name ?? def.Prerequisite;
                _content.Widgets.Add(new Label
                {
                    Text = $"  Requires: {prereqName}",
                    TextColor = ThemeColors.TextDim,
                });
            }
        }

        // Locked research (prerequisites not met)
        var locked = GetLockedResearch(state);
        if (locked.Count > 0)
        {
            _content.Widgets.Add(new HorizontalSeparator());
            _content.Widgets.Add(new Label
            {
                Text = $"Locked ({locked.Count})",
                TextColor = ThemeColors.TextDisabled,
            });

            foreach (string id in locked)
            {
                var def = ResearchData.GetResearch(id);
                if (def == null) continue;
                var prereqDef = def.Prerequisite != null ? ResearchData.GetResearch(def.Prerequisite) : null;

                var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
                row.Widgets.Add(new Label { Text = "[?]", TextColor = ThemeColors.TextDisabled, Width = 30 });
                row.Widgets.Add(new Label { Text = def.Name, TextColor = ThemeColors.TextDisabled, Width = 180 });
                row.Widgets.Add(new Label
                {
                    Text = $"Needs: {prereqDef?.Name ?? def.Prerequisite}",
                    TextColor = ThemeColors.TextDisabled,
                });
                _content.Widgets.Add(row);
            }
        }
    }

    private static List<string> GetLockedResearch(GameState state)
    {
        var locked = new List<string>();
        foreach (var (id, def) in ResearchData.Registry)
        {
            if (state.CompletedResearch.Contains(id)) continue;
            if (id == state.ActiveResearch) continue;
            if (def.Prerequisite != null && !state.CompletedResearch.Contains(def.Prerequisite))
                locked.Add(id);
        }
        return locked;
    }

    private static string FormatEffects(Dictionary<string, double> effects)
    {
        var parts = new List<string>();
        foreach (var (key, value) in effects)
        {
            string name = key.Replace("_", " ");
            parts.Add(value >= 1 ? $"{name} +{value}" : $"{name} +{value * 100:F0}%");
        }
        return string.Join(", ", parts);
    }

    private static Color GetCategoryColor(string category) => category switch
    {
        "combat" => ThemeColors.Error,
        "defense" => ThemeColors.Info,
        "economy" => ThemeColors.GoldAccent,
        "typing" => ThemeColors.AccentCyan,
        _ => ThemeColors.TextDim,
    };

    private void OnStartResearch(string id)
    {
        if (_state == null) return;
        ResearchData.StartResearch(_state, id);
        Refresh(_state);
    }
}
