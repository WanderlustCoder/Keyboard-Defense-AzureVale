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
/// Quests panel showing active, completed, and available quests.
/// Ported from ui/components/quests_panel.gd.
/// </summary>
public class QuestsPanel : BasePanel
{
    private readonly VerticalStackPanel _questList;
    private readonly Label _detailLabel;
    private readonly Label _progressLabel;

    public QuestsPanel() : base(Locale.Tr("panels.quests"))
    {
        RootWidget.Width = 600;
        RootWidget.Height = 500;

        _progressLabel = new Label
        {
            Text = "Completed: 0",
            TextColor = ThemeColors.AccentCyan,
        };
        AddWidget(_progressLabel);
        AddWidget(new HorizontalSeparator());

        var split = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

        _questList = new VerticalStackPanel { Spacing = 4 };
        var listScroll = new ScrollViewer
        {
            Content = _questList,
            Width = 250,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(listScroll);

        _detailLabel = new Label
        {
            Text = "Select a quest to view details.",
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
        _questList.Widgets.Clear();
        int completedCount = 0;

        // Active quests
        _questList.Widgets.Add(new Label
        {
            Text = "Active",
            TextColor = ThemeColors.Warning,
        });

        var activeQuests = Quests.GetActiveQuests(state);
        if (activeQuests.Count == 0)
        {
            _questList.Widgets.Add(new Label
            {
                Text = "  No active quests.",
                TextColor = ThemeColors.TextDim,
            });
        }
        foreach (string questId in activeQuests)
        {
            var def = Quests.GetQuest(questId);
            if (def != null)
                AddQuestButton(questId, def, false);
        }

        // Completed quests
        _questList.Widgets.Add(new Panel { Height = DesignSystem.SpaceSm });
        _questList.Widgets.Add(new Label
        {
            Text = "Completed",
            TextColor = ThemeColors.Success,
        });

        foreach (var (questId, def) in Quests.Registry)
        {
            if (state.CompletedQuests.Contains(questId))
            {
                completedCount++;
                AddQuestButton(questId, def, true);
            }
        }

        if (completedCount == 0)
        {
            _questList.Widgets.Add(new Label
            {
                Text = "  None yet.",
                TextColor = ThemeColors.TextDim,
            });
        }

        _progressLabel.Text = $"Completed: {completedCount} / {Quests.Registry.Count}";
    }

    private void AddQuestButton(string questId, QuestDef def, bool completed)
    {
        string prefix = completed ? "[*] " : "[ ] ";
        Color color = completed ? ThemeColors.Success : ThemeColors.Text;

        var btn = new Button
        {
            Content = new Label
            {
                Text = prefix + def.Name,
                TextColor = color,
            },
            Height = 26,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        var d = def;
        bool c = completed;
        btn.Click += (_, _) => ShowDetail(d, c);
        _questList.Widgets.Add(btn);
    }

    private void ShowDetail(QuestDef def, bool completed)
    {
        string rewards = def.Rewards.Count > 0
            ? string.Join(", ", def.Rewards.Select(kv => $"{kv.Key}: {kv.Value}"))
            : "None";

        _detailLabel.Text = $"{def.Name}\n\n{def.Description}\n\n" +
            $"Category: {def.Category}\n" +
            $"Objective: {def.Condition.Type}" +
            (def.Condition.Target != null ? $" ({def.Condition.Target})" : "") +
            $" x{def.Condition.Value}\n" +
            $"Rewards: {rewards}\n" +
            $"Status: {(completed ? "COMPLETED" : "In Progress")}";
        _detailLabel.TextColor = completed ? ThemeColors.Success : ThemeColors.Text;
    }
}
