using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.HUD;

/// <summary>
/// HUD resource bar showing gold and resources with color indicators.
/// Ported from ui/hud/resource_bar.gd.
/// </summary>
public class ResourceBar
{
    public HorizontalStackPanel RootWidget { get; }

    private readonly Label _goldLabel;
    private readonly Dictionary<string, Label> _resourceLabels = new();

    private static readonly Dictionary<string, Color> ResourceColors = new()
    {
        ["gold"] = ThemeColors.GoldAccent,
        ["wood"] = new Color(139, 90, 43),
        ["stone"] = new Color(160, 160, 160),
        ["food"] = new Color(76, 175, 80),
    };

    public ResourceBar()
    {
        RootWidget = new HorizontalStackPanel { Spacing = DesignSystem.SpaceLg };

        _goldLabel = new Label
        {
            Text = "Gold: 0",
            TextColor = ThemeColors.GoldAccent,
        };
        RootWidget.Widgets.Add(_goldLabel);

        foreach (string res in GameState.ResourceKeys)
        {
            var label = new Label
            {
                Text = $"{Capitalize(res)}: 0",
                TextColor = ResourceColors.GetValueOrDefault(res, ThemeColors.Text),
            };
            _resourceLabels[res] = label;
            RootWidget.Widgets.Add(label);
        }
    }

    public void Update(GameState state)
    {
        _goldLabel.Text = $"Gold: {state.Gold}";
        foreach (string res in GameState.ResourceKeys)
        {
            int amount = state.Resources.GetValueOrDefault(res, 0);
            if (_resourceLabels.TryGetValue(res, out var label))
                label.Text = $"{Capitalize(res)}: {amount}";
        }
    }

    private static string Capitalize(string s)
        => string.IsNullOrEmpty(s) ? s : char.ToUpper(s[0]) + s[1..];
}
