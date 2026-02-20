using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.State;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Workers panel showing worker allocation, building assignments, and production rates.
/// Wires to Core/Economy/Workers.cs.
/// </summary>
public class WorkersPanel : BasePanel
{
    private readonly VerticalStackPanel _content;
    private GameState? _state;

    public WorkersPanel() : base(Locale.Tr("panels.workers"))
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

        int available = Workers.GetAvailableWorkers(state);
        int totalAssigned = state.WorkerCount - available;

        // Summary
        var summary = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        summary.Widgets.Add(new Label
        {
            Text = $"Workers: {state.WorkerCount}",
            TextColor = ThemeColors.AccentCyan,
        });
        summary.Widgets.Add(new Label
        {
            Text = $"Assigned: {totalAssigned}",
            TextColor = ThemeColors.Info,
        });
        summary.Widgets.Add(new Label
        {
            Text = $"Available: {available}",
            TextColor = available > 0 ? ThemeColors.Success : ThemeColors.Warning,
        });
        _content.Widgets.Add(summary);

        if (state.WorkerUpkeep > 0)
        {
            _content.Widgets.Add(new Label
            {
                Text = $"Daily Upkeep: {state.WorkerUpkeep}g",
                TextColor = ThemeColors.GoldAccent,
            });
        }

        _content.Widgets.Add(new HorizontalSeparator());

        // Building assignments
        if (state.Structures.Count == 0)
        {
            _content.Widgets.Add(new Label
            {
                Text = "No structures built. Build structures to assign workers.",
                TextColor = ThemeColors.TextDim,
            });
            return;
        }

        _content.Widgets.Add(new Label
        {
            Text = "Structure Assignments",
            TextColor = ThemeColors.Accent,
        });

        // Header
        var header = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        header.Widgets.Add(new Label { Text = "Structure", TextColor = ThemeColors.TextDim, Width = 150 });
        header.Widgets.Add(new Label { Text = "Workers", TextColor = ThemeColors.TextDim, Width = 70 });
        header.Widgets.Add(new Label { Text = "Bonus", TextColor = ThemeColors.TextDim, Width = 60 });
        header.Widgets.Add(new Label { Text = "", TextColor = ThemeColors.TextDim, Width = 140 });
        _content.Widgets.Add(header);

        foreach (var (structIndex, structType) in state.Structures)
        {
            int workersHere = Workers.WorkersAt(state, structIndex);
            double bonus = Workers.WorkerBonus(state, structIndex);

            var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
            row.Widgets.Add(new Label
            {
                Text = FormatStructureName(structType),
                TextColor = ThemeColors.Text,
                Width = 150,
            });
            row.Widgets.Add(new Label
            {
                Text = $"{workersHere}",
                TextColor = workersHere > 0 ? ThemeColors.Info : ThemeColors.TextDim,
                Width = 70,
            });
            row.Widgets.Add(new Label
            {
                Text = $"x{bonus:F2}",
                TextColor = bonus > 1.0 ? ThemeColors.Success : ThemeColors.TextDim,
                Width = 60,
            });

            // Assign/unassign buttons
            var btnRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };
            int idx = structIndex; // Capture for lambda

            if (available > 0)
            {
                var addBtn = ButtonFactory.Secondary("+", () => OnAssign(idx));
                addBtn.Width = 32;
                addBtn.Height = 26;
                btnRow.Widgets.Add(addBtn);
            }

            if (workersHere > 0)
            {
                var removeBtn = ButtonFactory.Ghost("-", () => OnUnassign(idx));
                removeBtn.Width = 32;
                removeBtn.Height = 26;
                btnRow.Widgets.Add(removeBtn);
            }

            row.Widgets.Add(btnRow);
            _content.Widgets.Add(row);
        }

        // Worker bonus explanation
        _content.Widgets.Add(new HorizontalSeparator());
        _content.Widgets.Add(new Label
        {
            Text = $"Each worker adds +{Workers.BaseWorkerBonus * 100:F0}% production to their structure.",
            TextColor = ThemeColors.TextDim,
        });
    }

    private static string FormatStructureName(string type)
    {
        return type.Replace("_", " ");
    }

    private void OnAssign(int structIndex)
    {
        if (_state == null) return;
        Workers.AssignWorker(_state, structIndex);
        Refresh(_state);
    }

    private void OnUnassign(int structIndex)
    {
        if (_state == null) return;
        Workers.UnassignWorker(_state, structIndex);
        Refresh(_state);
    }
}
