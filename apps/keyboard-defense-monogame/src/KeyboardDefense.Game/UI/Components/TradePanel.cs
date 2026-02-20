using System;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Panel for trading resources between types.
/// Ported from Godot's trade UI.
/// </summary>
public class TradePanel : BasePanel
{
    private static readonly string[] Resources = { "wood", "stone", "food" };

    private readonly Label _resourcesLabel;
    private readonly Label _rateLabel;
    private readonly Label _resultLabel;
    private readonly VerticalStackPanel _tradeButtons;

    private string _fromResource = "wood";
    private string _toResource = "stone";

    public TradePanel() : base(Locale.Tr("panels.trade"))
    {
        RootWidget.Width = 500;
        RootWidget.Height = 420;

        _resourcesLabel = new Label
        {
            Text = "Resources: ...",
            TextColor = ThemeColors.Text,
        };
        AddWidget(_resourcesLabel);
        AddWidget(new HorizontalSeparator());

        // From/To selection
        var selectionRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

        var fromPanel = new VerticalStackPanel { Spacing = 4 };
        fromPanel.Widgets.Add(new Label { Text = "Sell:", TextColor = ThemeColors.AccentCyan });
        foreach (string res in Resources)
        {
            string r = res;
            var btn = ButtonFactory.Secondary(Capitalize(res), () => SetFrom(r));
            btn.Width = 100;
            fromPanel.Widgets.Add(btn);
        }
        selectionRow.Widgets.Add(fromPanel);

        selectionRow.Widgets.Add(new Label
        {
            Text = "->",
            TextColor = ThemeColors.Accent,
            VerticalAlignment = VerticalAlignment.Center,
        });

        var toPanel = new VerticalStackPanel { Spacing = 4 };
        toPanel.Widgets.Add(new Label { Text = "Buy:", TextColor = ThemeColors.AccentCyan });
        foreach (string res in Resources)
        {
            string r = res;
            var btn = ButtonFactory.Secondary(Capitalize(res), () => SetTo(r));
            btn.Width = 100;
            toPanel.Widgets.Add(btn);
        }
        selectionRow.Widgets.Add(toPanel);
        AddWidget(selectionRow);

        // Exchange rate display
        _rateLabel = new Label
        {
            Text = "Rate: 1.00",
            TextColor = ThemeColors.Accent,
        };
        AddWidget(_rateLabel);
        AddWidget(new HorizontalSeparator());

        // Trade amount buttons
        _tradeButtons = new VerticalStackPanel { Spacing = 4 };
        var amountRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        foreach (int amount in new[] { 1, 5, 10, 25 })
        {
            int a = amount;
            var btn = ButtonFactory.Primary($"Trade {amount}", () => ExecuteTrade(a));
            btn.Width = 100;
            amountRow.Widgets.Add(btn);
        }
        _tradeButtons.Widgets.Add(amountRow);
        AddWidget(_tradeButtons);

        // Result label
        _resultLabel = new Label
        {
            Text = "",
            TextColor = ThemeColors.Text,
            Wrap = true,
        };
        AddWidget(_resultLabel);

        UpdateRateDisplay();
    }

    public void Refresh(GameState state)
    {
        int wood = state.Resources.TryGetValue("wood", out int w) ? w : 0;
        int stone = state.Resources.TryGetValue("stone", out int s) ? s : 0;
        int food = state.Resources.TryGetValue("food", out int f) ? f : 0;
        _resourcesLabel.Text = $"Wood: {wood}  Stone: {stone}  Food: {food}";
        UpdateRateDisplay();
    }

    private void SetFrom(string resource)
    {
        _fromResource = resource;
        if (_fromResource == _toResource)
        {
            // Swap to avoid same-resource trade
            foreach (string r in Resources)
            {
                if (r != _fromResource) { _toResource = r; break; }
            }
        }
        UpdateRateDisplay();
    }

    private void SetTo(string resource)
    {
        _toResource = resource;
        if (_toResource == _fromResource)
        {
            foreach (string r in Resources)
            {
                if (r != _toResource) { _fromResource = r; break; }
            }
        }
        UpdateRateDisplay();
    }

    private void UpdateRateDisplay()
    {
        double rate = Trade.GetExchangeRate(_fromResource, _toResource);
        _rateLabel.Text = $"Trade: {Capitalize(_fromResource)} -> {Capitalize(_toResource)} (Rate: {rate:F2})";
    }

    private void ExecuteTrade(int amount)
    {
        var state = GameController.Instance.State;
        var result = Trade.ExecuteTrade(state, _fromResource, _toResource, amount);

        bool success = result.TryGetValue("success", out var sObj) && sObj is true;
        string message = (result.TryGetValue("message", out var mObj) ? mObj?.ToString() : null)
                      ?? (result.TryGetValue("error", out var eObj) ? eObj?.ToString() : null)
                      ?? "Trade failed.";

        _resultLabel.Text = message;
        _resultLabel.TextColor = success ? ThemeColors.Success : ThemeColors.Error;
        Refresh(state);
    }

    private static string Capitalize(string s)
        => string.IsNullOrEmpty(s) ? s : char.ToUpper(s[0]) + s[1..];
}
