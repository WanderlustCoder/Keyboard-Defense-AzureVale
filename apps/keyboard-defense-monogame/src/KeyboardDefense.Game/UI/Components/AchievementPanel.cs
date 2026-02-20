using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Achievement panel displaying earned and locked achievements.
/// Ported from ui/components/achievement_panel.gd.
/// </summary>
public class AchievementPanel : BasePanel
{
    private readonly VerticalStackPanel _achievementList;
    private readonly Label _progressLabel;

    private static readonly (string Id, string Name, string Description, string Icon)[] Achievements =
    {
        ("first_blood", "First Blood", "Defeat your first enemy.", "!"),
        ("word_smith", "Word Smith", "Type 100 words in combat.", "W"),
        ("gold_hoarder", "Gold Hoarder", "Accumulate 500 gold.", "G"),
        ("boss_slayer", "Boss Slayer", "Defeat a boss enemy.", "B"),
        ("combo_master", "Combo Master", "Reach a 10-word combo streak.", "C"),
        ("tower_builder", "Tower Builder", "Build 10 towers.", "T"),
        ("explorer", "Explorer", "Discover 50 map tiles.", "E"),
        ("speed_demon", "Speed Demon", "Type over 80 WPM in battle.", "S"),
        ("perfectionist", "Perfectionist", "Complete a wave with zero errors.", "P"),
        ("kingdom_defender", "Kingdom Defender", "Survive 20 nights.", "K"),
        ("loot_collector", "Loot Collector", "Collect 25 unique items.", "L"),
        ("skill_master", "Skill Master", "Unlock 10 skills.", "M"),
    };

    public AchievementPanel() : base(Locale.Tr("ui.achievements"))
    {
        RootWidget.Width = 550;
        RootWidget.Height = 500;

        _progressLabel = new Label
        {
            Text = "Progress: 0 / 12",
            TextColor = ThemeColors.Accent,
        };
        AddWidget(_progressLabel);
        AddWidget(new HorizontalSeparator());

        _achievementList = new VerticalStackPanel { Spacing = 4 };
        var scroll = new ScrollViewer
        {
            Content = _achievementList,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        AddWidget(scroll);
    }

    public void Refresh(GameState state)
    {
        _achievementList.Widgets.Clear();
        int earned = 0;

        var victorySet = new HashSet<string>(state.VictoryAchieved);

        foreach (var (id, name, desc, icon) in Achievements)
        {
            bool unlocked = victorySet.Contains(id)
                || state.Milestones.Contains(id);

            if (unlocked) earned++;

            var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };

            var iconLabel = new Label
            {
                Text = $"[{icon}]",
                TextColor = unlocked ? ThemeColors.Accent : ThemeColors.TextDisabled,
                Width = 40,
            };
            row.Widgets.Add(iconLabel);

            var nameLabel = new Label
            {
                Text = unlocked ? name : "???",
                TextColor = unlocked ? ThemeColors.Text : ThemeColors.TextDisabled,
                Width = 180,
            };
            row.Widgets.Add(nameLabel);

            var descLabel = new Label
            {
                Text = unlocked ? desc : "Keep playing to unlock.",
                TextColor = unlocked ? ThemeColors.TextDim : ThemeColors.TextDisabled,
            };
            row.Widgets.Add(descLabel);

            _achievementList.Widgets.Add(row);
        }

        _progressLabel.Text = $"Progress: {earned} / {Achievements.Length}";
    }
}
