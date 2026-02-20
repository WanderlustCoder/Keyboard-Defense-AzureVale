using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI.HUD;

/// <summary>
/// HUD threat gauge with color-coded progress bar.
/// Ported from ui/components/threat_bar.gd.
/// </summary>
public class ThreatGauge
{
    public VerticalStackPanel RootWidget { get; }

    private readonly Label _threatLabel;
    private readonly HorizontalProgressBar _progressBar;
    private readonly Label _castleLabel;
    private int _maxThreat = 100;

    public ThreatGauge()
    {
        RootWidget = new VerticalStackPanel { Spacing = 2 };

        _threatLabel = new Label
        {
            Text = "Threat: 0",
            TextColor = ThemeColors.Threat,
        };
        RootWidget.Widgets.Add(_threatLabel);

        _progressBar = new HorizontalProgressBar
        {
            Minimum = 0,
            Maximum = 100,
            Value = 0,
            Width = 200,
            Height = 16,
        };
        RootWidget.Widgets.Add(_progressBar);

        _castleLabel = new Label
        {
            Text = "Castle: 10 / 10",
            TextColor = ThemeColors.Success,
        };
        RootWidget.Widgets.Add(_castleLabel);
    }

    public void SetThreat(int value)
    {
        _progressBar.Value = value;
        _threatLabel.Text = $"Threat: {value}";

        // Color by severity
        if (value >= 80)
            _threatLabel.TextColor = ThemeColors.Error;
        else if (value >= 50)
            _threatLabel.TextColor = ThemeColors.Warning;
        else
            _threatLabel.TextColor = ThemeColors.Threat;
    }

    public void SetMaxThreat(int value)
    {
        _maxThreat = value;
        _progressBar.Maximum = value;
    }

    public void SetCastleHealth(int current, int max)
    {
        _castleLabel.Text = $"Castle: {current} / {max}";

        if (current <= 0)
            _castleLabel.TextColor = ThemeColors.Error;
        else if (current <= max / 4)
            _castleLabel.TextColor = ThemeColors.Error;
        else if (current <= max / 2)
            _castleLabel.TextColor = ThemeColors.Warning;
        else
            _castleLabel.TextColor = ThemeColors.Success;
    }
}
