using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI.HUD;

/// <summary>
/// HUD phase indicator showing current day/night phase with distinct colors.
/// Ported from ui/hud/phase_indicator.gd.
/// </summary>
public class PhaseIndicator
{
    public HorizontalStackPanel RootWidget { get; }

    private readonly Label _dayLabel;
    private readonly Label _phaseLabel;
    private readonly Label _apLabel;

    private static readonly Dictionary<string, Color> PhaseColors = new()
    {
        ["day"] = ThemeColors.AccentCyan,
        ["night"] = ThemeColors.Accent,
        ["dawn"] = ThemeColors.Warning,
        ["victory"] = ThemeColors.Success,
        ["game_over"] = ThemeColors.Error,
    };

    public PhaseIndicator()
    {
        RootWidget = new HorizontalStackPanel { Spacing = DesignSystem.SpaceLg };

        _dayLabel = new Label
        {
            Text = "Day 1",
            TextColor = ThemeColors.Accent,
        };
        RootWidget.Widgets.Add(_dayLabel);

        _phaseLabel = new Label
        {
            Text = "Phase: day",
            TextColor = ThemeColors.AccentCyan,
        };
        RootWidget.Widgets.Add(_phaseLabel);

        _apLabel = new Label
        {
            Text = "AP: 3/3",
            TextColor = ThemeColors.AccentBlue,
        };
        RootWidget.Widgets.Add(_apLabel);
    }

    public void SetDay(int day)
    {
        _dayLabel.Text = $"Day {day}";
    }

    public void SetPhase(string phase)
    {
        _phaseLabel.Text = $"Phase: {phase}";
        _phaseLabel.TextColor = PhaseColors.GetValueOrDefault(phase, ThemeColors.TextDim);
    }

    public void SetAp(int current, int max)
    {
        _apLabel.Text = $"AP: {current}/{max}";
        _apLabel.TextColor = current > 0 ? ThemeColors.AccentBlue : ThemeColors.TextDisabled;
    }

    public void UpdateFromState(Core.State.GameState state)
    {
        SetDay(state.Day);
        SetPhase(state.Phase);
        SetAp(state.Ap, state.ApMax);
    }
}
