using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Panel for configuring automated tower behavior in Kingdom Defense mode.
/// Allows players to set build, upgrade, and repair preferences so towers
/// manage themselves while the player focuses on typing.
/// Ported from Godot's auto-defense tower system.
/// </summary>
public class AutoTowerPanel : BasePanel
{
    private readonly List<Button> _priorityButtons = new();
    private readonly List<Button> _reserveButtons = new();
    private CheckButton? _autoBuildToggle;
    private CheckButton? _autoUpgradeToggle;
    private CheckButton? _autoRepairToggle;

    private string _selectedPriority;
    private int _selectedReserve;

    public AutoTowerPanel() : base(Locale.Tr("panels.auto_tower"))
    {
        RootWidget.Width = 520;
        RootWidget.Height = 480;

        var state = GameController.Instance.State;
        _selectedPriority = state.AutoTower.BuildPriority;
        _selectedReserve = state.AutoTower.ResourceReservePercent;

        // Auto-Build toggle
        AddWidget(new Label { Text = Locale.Tr("auto_tower.section_build"), TextColor = ThemeColors.Accent });
        AddWidget(CreateToggleRow(
            Locale.Tr("auto_tower.auto_build"),
            state.AutoTower.AutoBuild,
            out _autoBuildToggle));
        AddWidget(new HorizontalSeparator());

        // Build Priority selection
        AddWidget(new Label { Text = Locale.Tr("auto_tower.section_priority"), TextColor = ThemeColors.Accent });
        AddWidget(CreateSelectionRow(
            Locale.Tr("auto_tower.build_priority"),
            AutoTowerSettings.BuildPriorityOptions,
            FormatPriority,
            _selectedPriority,
            _priorityButtons,
            value => { _selectedPriority = value; UpdatePriorityHighlights(); }));
        AddWidget(new HorizontalSeparator());

        // Auto-Upgrade toggle
        AddWidget(new Label { Text = Locale.Tr("auto_tower.section_upgrades"), TextColor = ThemeColors.Accent });
        AddWidget(CreateToggleRow(
            Locale.Tr("auto_tower.auto_upgrade"),
            state.AutoTower.AutoUpgrade,
            out _autoUpgradeToggle));
        AddWidget(new HorizontalSeparator());

        // Auto-Repair toggle
        AddWidget(new Label { Text = Locale.Tr("auto_tower.section_repair"), TextColor = ThemeColors.Accent });
        AddWidget(CreateToggleRow(
            Locale.Tr("auto_tower.auto_repair"),
            state.AutoTower.AutoRepair,
            out _autoRepairToggle));
        AddWidget(new HorizontalSeparator());

        // Resource Reserve selection
        AddWidget(new Label { Text = Locale.Tr("auto_tower.section_reserve"), TextColor = ThemeColors.Accent });
        AddWidget(CreateReserveRow(
            Locale.Tr("auto_tower.resource_reserve"),
            _selectedReserve,
            _reserveButtons,
            value => { _selectedReserve = value; UpdateReserveHighlights(); }));

        // Apply button
        AddWidget(new Panel { Height = DesignSystem.SpaceMd });
        var buttonRow = new HorizontalStackPanel
        {
            Spacing = DesignSystem.SpaceMd,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        buttonRow.Widgets.Add(ButtonFactory.Primary(Locale.Tr("actions.apply"), ApplySettings));
        buttonRow.Widgets.Add(ButtonFactory.Secondary(Locale.Tr("auto_tower.reset"), ResetDefaults));
        AddWidget(buttonRow);
    }

    private void ApplySettings()
    {
        var settings = GameController.Instance.State.AutoTower;
        settings.AutoBuild = _autoBuildToggle?.IsChecked ?? false;
        settings.BuildPriority = _selectedPriority;
        settings.AutoUpgrade = _autoUpgradeToggle?.IsChecked ?? false;
        settings.AutoRepair = _autoRepairToggle?.IsChecked ?? false;
        settings.ResourceReservePercent = _selectedReserve;
        Close();
    }

    private void ResetDefaults()
    {
        var defaults = new AutoTowerSettings();

        if (_autoBuildToggle != null) _autoBuildToggle.IsChecked = defaults.AutoBuild;
        if (_autoUpgradeToggle != null) _autoUpgradeToggle.IsChecked = defaults.AutoUpgrade;
        if (_autoRepairToggle != null) _autoRepairToggle.IsChecked = defaults.AutoRepair;

        _selectedPriority = defaults.BuildPriority;
        UpdatePriorityHighlights();

        _selectedReserve = defaults.ResourceReservePercent;
        UpdateReserveHighlights();
    }

    private void UpdatePriorityHighlights()
    {
        for (int i = 0; i < _priorityButtons.Count && i < AutoTowerSettings.BuildPriorityOptions.Length; i++)
        {
            bool active = AutoTowerSettings.BuildPriorityOptions[i] == _selectedPriority;
            SetButtonHighlight(_priorityButtons[i], active);
        }
    }

    private void UpdateReserveHighlights()
    {
        for (int i = 0; i < _reserveButtons.Count && i < AutoTowerSettings.ReservePercentOptions.Length; i++)
        {
            bool active = AutoTowerSettings.ReservePercentOptions[i] == _selectedReserve;
            SetButtonHighlight(_reserveButtons[i], active);
        }
    }

    private static void SetButtonHighlight(Button btn, bool active)
    {
        if (btn.Content is Label label)
        {
            label.TextColor = active ? ThemeColors.Accent : ThemeColors.TextDim;
        }
    }

    private static string FormatPriority(string priority) => priority switch
    {
        "offense" => Locale.Tr("auto_tower.priority_offense"),
        "defense" => Locale.Tr("auto_tower.priority_defense"),
        "balanced" => Locale.Tr("auto_tower.priority_balanced"),
        _ => priority,
    };

    private static string FormatReserve(int percent) => percent == 0 ? Locale.Tr("auto_tower.reserve_none") : $"{percent}%";

    private static HorizontalStackPanel CreateToggleRow(string label, bool initial, out CheckButton toggle)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        row.Widgets.Add(new Label
        {
            Text = label,
            TextColor = ThemeColors.Text,
            Width = 180,
        });

        toggle = new CheckButton { IsChecked = initial };
        row.Widgets.Add(toggle);
        return row;
    }

    private static HorizontalStackPanel CreateSelectionRow(
        string label, string[] options, Func<string, string> format,
        string current, List<Button> buttons, Action<string> onSelect)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        row.Widgets.Add(new Label
        {
            Text = label,
            TextColor = ThemeColors.Text,
            Width = 180,
        });

        foreach (string option in options)
        {
            bool isActive = option == current;
            string opt = option;
            var btn = new Button
            {
                Content = new Label
                {
                    Text = format(option),
                    TextColor = isActive ? ThemeColors.Accent : ThemeColors.TextDim,
                },
                Width = 90,
                Height = DesignSystem.SizeButtonSm,
            };
            btn.Click += (_, _) => onSelect(opt);
            buttons.Add(btn);
            row.Widgets.Add(btn);
        }

        return row;
    }

    private static HorizontalStackPanel CreateReserveRow(
        string label, int current, List<Button> buttons, Action<int> onSelect)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        row.Widgets.Add(new Label
        {
            Text = label,
            TextColor = ThemeColors.Text,
            Width = 180,
        });

        foreach (int percent in AutoTowerSettings.ReservePercentOptions)
        {
            bool isActive = percent == current;
            int pct = percent;
            var btn = new Button
            {
                Content = new Label
                {
                    Text = FormatReserve(percent),
                    TextColor = isActive ? ThemeColors.Accent : ThemeColors.TextDim,
                },
                Width = 60,
                Height = DesignSystem.SizeButtonSm,
            };
            btn.Click += (_, _) => onSelect(pct);
            buttons.Add(btn);
            row.Widgets.Add(btn);
        }

        return row;
    }
}
