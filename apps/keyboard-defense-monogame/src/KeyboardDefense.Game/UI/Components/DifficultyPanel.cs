using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Panel for viewing and selecting difficulty modes.
/// Ported from Godot's difficulty selection UI.
/// </summary>
public class DifficultyPanel : BasePanel
{
    private readonly Label _currentModeLabel;
    private readonly VerticalStackPanel _modeList;
    private readonly Label _detailLabel;

    public event Action<string>? ModeSelected;

    public DifficultyPanel() : base(Locale.Tr("panels.difficulty"))
    {
        RootWidget.Width = 600;
        RootWidget.Height = 480;

        _currentModeLabel = new Label
        {
            Text = "Current: Adventure Mode",
            TextColor = ThemeColors.Accent,
        };
        AddWidget(_currentModeLabel);
        AddWidget(new HorizontalSeparator());

        var split = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

        // Mode list
        _modeList = new VerticalStackPanel { Spacing = 4 };
        var listScroll = new ScrollViewer
        {
            Content = _modeList,
            Width = 200,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(listScroll);

        // Detail view
        _detailLabel = new Label
        {
            Text = "Select a difficulty mode to view details.",
            TextColor = ThemeColors.Text,
            Wrap = true,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        var detailScroll = new ScrollViewer
        {
            Content = _detailLabel,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(detailScroll);

        AddWidget(split);
    }

    public void Refresh(GameState state)
    {
        _modeList.Widgets.Clear();

        var badges = new HashSet<string>(state.UnlockedBadges);
        var unlocked = Difficulty.GetUnlockedModes(badges);

        foreach (string modeId in Difficulty.GetAllModeIds())
        {
            var mode = Difficulty.GetMode(modeId);
            bool isUnlocked = unlocked.Contains(modeId);

            Color textColor = isUnlocked ? ThemeColors.Text : ThemeColors.TextDisabled;
            string prefix = isUnlocked ? "" : "[Locked] ";

            string id = modeId;
            var btn = new Button
            {
                Content = new Label
                {
                    Text = prefix + mode.Name,
                    TextColor = textColor,
                },
                Height = 32,
                HorizontalAlignment = HorizontalAlignment.Stretch,
                Enabled = isUnlocked,
            };
            btn.Click += (_, _) =>
            {
                ShowModeDetail(id);
                if (isUnlocked)
                    ModeSelected?.Invoke(id);
            };
            _modeList.Widgets.Add(btn);
        }
    }

    private void ShowModeDetail(string modeId)
    {
        var mode = Difficulty.GetMode(modeId);

        string modifiers = $"Enemy Health: x{mode.EnemyHealth:F1}\n" +
            $"Enemy Damage: x{mode.EnemyDamage:F1}\n" +
            $"Enemy Speed: x{mode.EnemySpeed:F1}\n" +
            $"Wave Size: x{mode.WaveSize:F1}\n" +
            $"Wave Delay: x{mode.WaveDelay:F1}\n" +
            $"Error Penalty: x{mode.ErrorPenalty:F1}\n" +
            $"Gold Earned: x{mode.GoldEarned:F1}\n" +
            $"Typo Forgiveness: {mode.TypoForgiveness}\n" +
            $"Word Preview: {mode.WordPreviewTime:F1}s";

        string unlock = mode.UnlockRequirement != null
            ? $"\nUnlock: {mode.UnlockRequirement}"
            : "";

        _detailLabel.Text = $"{mode.Name}\n\n{mode.Description}\n\n" +
            $"Modifiers:\n{modifiers}{unlock}";
        _detailLabel.TextColor = ThemeColors.Text;

        _currentModeLabel.Text = $"Viewing: {mode.Name}";
    }
}
