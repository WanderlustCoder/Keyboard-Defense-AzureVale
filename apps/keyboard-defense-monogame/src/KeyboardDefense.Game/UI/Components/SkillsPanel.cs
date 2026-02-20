using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Skills panel showing skill tree and unlockable abilities.
/// Ported from ui/components/skills_panel.gd.
/// </summary>
public class SkillsPanel : BasePanel
{
    private readonly Label _pointsLabel;
    private readonly VerticalStackPanel _skillList;
    private readonly Label _detailLabel;

    public event Action<string>? SkillUnlockRequested;

    public SkillsPanel() : base(Locale.Tr("panels.skills"))
    {
        RootWidget.Width = 600;
        RootWidget.Height = 500;

        _pointsLabel = new Label
        {
            Text = "Skill Points: 0",
            TextColor = ThemeColors.Accent,
        };
        AddWidget(_pointsLabel);
        AddWidget(new HorizontalSeparator());

        var split = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

        _skillList = new VerticalStackPanel { Spacing = 4 };
        var listScroll = new ScrollViewer
        {
            Content = _skillList,
            Width = 250,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(listScroll);

        _detailLabel = new Label
        {
            Text = "Select a skill to view details.",
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
        _pointsLabel.Text = $"Skill Points: {state.SkillPoints}";
        _skillList.Widgets.Clear();

        // Group by category
        var groups = new Dictionary<string, List<(string Id, SkillDef Def)>>();
        foreach (var (id, def) in Skills.Registry)
        {
            if (!groups.ContainsKey(def.Category))
                groups[def.Category] = new();
            groups[def.Category].Add((id, def));
        }

        foreach (var (category, skills) in groups)
        {
            _skillList.Widgets.Add(new Label
            {
                Text = Capitalize(category),
                TextColor = ThemeColors.AccentCyan,
            });

            foreach (var (id, def) in skills)
            {
                bool unlocked = state.UnlockedSkills.Contains(id);
                bool canUnlock = Skills.CanUnlock(state, id);

                Color color = unlocked ? ThemeColors.Success : ThemeColors.Text;
                string prefix = unlocked ? "[+] " : $"[T{def.Tier}] ";

                string skillId = id;
                var skillDef = def;
                var btn = new Button
                {
                    Content = new Label
                    {
                        Text = prefix + def.Name,
                        TextColor = color,
                    },
                    Height = 26,
                    HorizontalAlignment = HorizontalAlignment.Stretch,
                    Enabled = unlocked || canUnlock,
                };
                btn.Click += (_, _) =>
                {
                    ShowDetail(skillId, skillDef, state);
                    if (!unlocked && canUnlock)
                        SkillUnlockRequested?.Invoke(skillId);
                };
                _skillList.Widgets.Add(btn);
            }
        }
    }

    private void ShowDetail(string id, SkillDef def, GameState state)
    {
        bool unlocked = state.UnlockedSkills.Contains(id);
        string bonuses = def.Bonuses.Count > 0
            ? string.Join(", ", def.Bonuses.Select(kv => $"{kv.Key}: +{kv.Value:F0}%"))
            : "None";
        string prereq = def.Prerequisite != null ? $"Requires: {def.Prerequisite}" : "No prerequisites";

        _detailLabel.Text = $"{def.Name}\n\n{def.Description}\n\n" +
            $"Tier: {def.Tier}\n" +
            $"Bonuses: {bonuses}\n" +
            $"{prereq}\n" +
            $"Status: {(unlocked ? "UNLOCKED" : "Locked")}";
        _detailLabel.TextColor = unlocked ? ThemeColors.Success : ThemeColors.Text;
    }

    private static string Capitalize(string s)
        => string.IsNullOrEmpty(s) ? s : char.ToUpper(s[0]) + s[1..];
}
