using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Panel displaying the 3 daily challenges with progress, rewards, and refresh countdown.
/// </summary>
public class DailyChallengesPanel : BasePanel
{
    private readonly VerticalStackPanel _challengeList;
    private readonly Label _refreshLabel;
    private readonly Label _summaryLabel;

    public DailyChallengesPanel() : base(Locale.Tr("panels.daily_challenges"))
    {
        RootWidget.Width = 560;
        RootWidget.Height = 420;

        _summaryLabel = new Label
        {
            Text = "Today's Challenges",
            TextColor = ThemeColors.Accent,
        };
        AddWidget(_summaryLabel);
        AddWidget(new HorizontalSeparator());

        _challengeList = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        var scroll = new ScrollViewer
        {
            Content = _challengeList,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        AddWidget(scroll);

        AddWidget(new HorizontalSeparator());

        _refreshLabel = new Label
        {
            Text = "Refreshes in: --:--",
            TextColor = ThemeColors.TextDim,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        AddWidget(_refreshLabel);
    }

    public void Refresh(GameState state)
    {
        _challengeList.Widgets.Clear();

        var challenges = DailyChallenges.GetTodaysChallenges(state.Day);
        int completedCount = 0;

        foreach (var challenge in challenges)
        {
            bool completed = state.CompletedDailyChallenges.Contains(challenge.Id);
            if (completed) completedCount++;

            var card = BuildChallengeCard(state, challenge, completed);
            _challengeList.Widgets.Add(card);
        }

        _summaryLabel.Text = $"Today's Challenges ({completedCount} / {challenges.Count})";

        // Refresh countdown
        var remaining = DailyChallenges.TimeUntilRefresh();
        _refreshLabel.Text = $"Refreshes in: {remaining.Hours:D2}:{remaining.Minutes:D2}";
    }

    private static Panel BuildChallengeCard(GameState state, ChallengeDef challenge, bool completed)
    {
        var card = new Panel
        {
            Height = 80,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };

        var layout = new VerticalStackPanel { Spacing = 2 };

        // Row 1: status icon + name + reward
        var headerRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };

        var statusIcon = new Label
        {
            Text = completed ? "[*]" : "[ ]",
            TextColor = completed ? ThemeColors.Success : ThemeColors.TextDim,
            Width = 30,
        };
        headerRow.Widgets.Add(statusIcon);

        var nameLabel = new Label
        {
            Text = challenge.Name,
            TextColor = completed ? ThemeColors.Success : ThemeColors.Text,
            Width = 300,
        };
        headerRow.Widgets.Add(nameLabel);

        // Reward: gold icon + amount
        var rewardLabel = new Label
        {
            Text = $"[G] +{challenge.Reward}",
            TextColor = completed ? ThemeColors.TextDim : ThemeColors.ResourceGold,
            HorizontalAlignment = HorizontalAlignment.Right,
        };
        headerRow.Widgets.Add(rewardLabel);
        layout.Widgets.Add(headerRow);

        // Row 2: description
        var descLabel = new Label
        {
            Text = challenge.Description,
            TextColor = completed ? ThemeColors.TextDim : ThemeColors.TextDim,
        };
        layout.Widgets.Add(descLabel);

        // Row 3: progress bar
        var (current, target) = DailyChallenges.GetProgress(state, challenge);
        string progressText = FormatProgress(challenge, current, target, completed);

        var progressRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };

        // Simple text-based progress bar
        float pct = target > 0 ? (float)current / target : 0f;
        if (pct > 1f) pct = 1f;
        int barWidth = 20;
        int filled = (int)(pct * barWidth);
        string bar = "[" + new string('#', filled) + new string('-', barWidth - filled) + "]";

        var barLabel = new Label
        {
            Text = bar,
            TextColor = completed ? ThemeColors.Success : ThemeColors.AccentCyan,
        };
        progressRow.Widgets.Add(barLabel);

        var pctLabel = new Label
        {
            Text = progressText,
            TextColor = completed ? ThemeColors.Success : ThemeColors.Text,
        };
        progressRow.Widgets.Add(pctLabel);

        layout.Widgets.Add(progressRow);

        card.Widgets.Add(layout);
        return card;
    }

    private static string FormatProgress(ChallengeDef challenge, int current, int target, bool completed)
    {
        if (completed) return "Completed!";

        return challenge.Type == ChallengeType.SpeedRun
            ? $"{current}s / {target}s"
            : $"{current} / {target}";
    }
}
