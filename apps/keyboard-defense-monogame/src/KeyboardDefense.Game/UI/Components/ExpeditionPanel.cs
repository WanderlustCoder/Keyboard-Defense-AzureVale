using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Expedition panel showing available expedition types, active expeditions, and history.
/// Wires to Core/World/Expeditions.cs.
/// </summary>
public class ExpeditionPanel : BasePanel
{
    private readonly VerticalStackPanel _content;
    private GameState? _state;

    public ExpeditionPanel() : base(Locale.Tr("panels.expeditions"))
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

        // Active expeditions
        _content.Widgets.Add(new Label
        {
            Text = $"Active Expeditions ({state.ActiveExpeditions.Count})",
            TextColor = ThemeColors.AccentCyan,
        });

        if (state.ActiveExpeditions.Count == 0)
        {
            _content.Widgets.Add(new Label
            {
                Text = "No active expeditions.",
                TextColor = ThemeColors.TextDim,
            });
        }
        else
        {
            foreach (var exp in state.ActiveExpeditions)
            {
                string type = exp.GetValueOrDefault("type", "").ToString() ?? "";
                int workers = Convert.ToInt32(exp.GetValueOrDefault("workers", 0));
                int progress = Convert.ToInt32(exp.GetValueOrDefault("progress", 0));
                int duration = Convert.ToInt32(exp.GetValueOrDefault("duration", 1));
                var def = Expeditions.Types.GetValueOrDefault(type);
                string name = def?.Name ?? type;

                var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
                row.Widgets.Add(new Label { Text = name, TextColor = ThemeColors.Text, Width = 180 });
                row.Widgets.Add(new Label { Text = $"{workers}w", TextColor = ThemeColors.TextDim, Width = 40 });
                row.Widgets.Add(new Label
                {
                    Text = $"{progress}/{duration}",
                    TextColor = progress >= duration ? ThemeColors.Success : ThemeColors.Warning,
                    Width = 60,
                });
                _content.Widgets.Add(row);
            }
        }

        _content.Widgets.Add(new HorizontalSeparator());

        // Available expedition types
        _content.Widgets.Add(new Label
        {
            Text = "Start New Expedition",
            TextColor = ThemeColors.Accent,
        });

        int availableWorkers = state.WorkerCount;
        foreach (var assigned in state.WorkerAssignments.Values)
            availableWorkers -= assigned;
        // Also subtract workers on expeditions
        foreach (var exp in state.ActiveExpeditions)
            availableWorkers -= Convert.ToInt32(exp.GetValueOrDefault("workers", 0));

        _content.Widgets.Add(new Label
        {
            Text = $"Available Workers: {Math.Max(0, availableWorkers)}",
            TextColor = availableWorkers > 0 ? ThemeColors.Success : ThemeColors.Error,
        });

        foreach (var (typeId, def) in Expeditions.Types)
        {
            var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
            row.Widgets.Add(new Label { Text = def.Name, TextColor = ThemeColors.Text, Width = 180 });
            row.Widgets.Add(new Label
            {
                Text = $"+{def.BaseYield} {def.Resource}",
                TextColor = ThemeColors.GetResourceColor(def.Resource),
                Width = 100,
            });
            row.Widgets.Add(new Label { Text = $"{def.Duration}d", TextColor = ThemeColors.TextDim, Width = 40 });
            row.Widgets.Add(new Label
            {
                Text = $"Risk: {def.RiskChance * 100:F0}%",
                TextColor = def.RiskChance > 0.15 ? ThemeColors.Warning : ThemeColors.TextDim,
                Width = 80,
            });

            var sendBtn = ButtonFactory.Secondary("Send 1", () => OnSendExpedition(typeId, 1));
            sendBtn.Width = 80;
            sendBtn.Height = 28;
            row.Widgets.Add(sendBtn);

            _content.Widgets.Add(row);
        }
    }

    private void OnSendExpedition(string type, int workers)
    {
        if (_state == null) return;
        var result = Expeditions.StartExpedition(_state, type, workers);
        bool ok = Convert.ToBoolean(result.GetValueOrDefault("ok", false));
        if (!ok) return;
        Refresh(_state);
    }
}
