using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Statistics panel showing gameplay metrics and typing performance.
/// Enriched with tabs, accuracy trends, and WPM history.
/// </summary>
public class StatsPanel : BasePanel
{
    private readonly VerticalStackPanel _statsList;
    private readonly HorizontalStackPanel _tabBar;
    private string _activeTab = "Combat";

    // WPM history tracking (last 5 sessions)
    private readonly List<float> _wpmHistory = new();
    private readonly List<float> _accuracyHistory = new();

    public StatsPanel() : base(Locale.Tr("ui.stats"))
    {
        RootWidget.Width = 500;
        RootWidget.Height = 500;

        // Tab bar
        _tabBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };
        foreach (string tab in new[] { "Combat", "Typing", "Progression", "Economy" })
        {
            string t = tab;
            var btn = ButtonFactory.Ghost(tab, () => SwitchTab(t));
            btn.Width = 90;
            btn.Height = DesignSystem.SizeButtonSm;
            _tabBar.Widgets.Add(btn);
        }
        AddWidget(_tabBar);
        AddWidget(new HorizontalSeparator());

        _statsList = new VerticalStackPanel { Spacing = 4 };
        var scroll = new ScrollViewer
        {
            Content = _statsList,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        AddWidget(scroll);
    }

    private GameState? _lastState;

    public void Refresh(GameState state)
    {
        _lastState = state;
        ShowTab(_activeTab, state);
    }

    private void SwitchTab(string tab)
    {
        _activeTab = tab;
        if (_lastState != null)
            ShowTab(tab, _lastState);
    }

    private void ShowTab(string tab, GameState state)
    {
        _statsList.Widgets.Clear();

        switch (tab)
        {
            case "Combat":
                ShowCombatTab(state);
                break;
            case "Typing":
                ShowTypingTab(state);
                break;
            case "Progression":
                ShowProgressionTab(state);
                break;
            case "Economy":
                ShowEconomyTab(state);
                break;
        }
    }

    private void ShowCombatTab(GameState state)
    {
        AddSection("Combat Overview");
        AddStat("Day", state.Day.ToString());
        AddStat("Phase", state.Phase);
        AddStat("Enemies Defeated", state.EnemiesDefeated.ToString(), ThemeColors.DamageRed);
        AddStat("Bosses Defeated", state.BossesDefeated.Count.ToString(), ThemeColors.Error);
        AddStat("Max Combo", state.MaxComboEver.ToString(), ThemeColors.ComboOrange);
        AddStat("Perfect Kills", state.PerfectKills.ToString(), ThemeColors.GoldAccent);

        AddSection("Skills");
        AddStat("Skill Points", state.SkillPoints.ToString(), ThemeColors.AccentBlue);
        AddStat("Skills Unlocked", state.UnlockedSkills.Count.ToString());

        AddSection("Buildings");
        foreach (var (building, count) in state.Buildings)
        {
            if (count > 0)
                AddStat($"  {Capitalize(building)}", count.ToString());
        }
    }

    private void ShowTypingTab(GameState state)
    {
        var metrics = state.TypingMetrics;

        AddSection("Typing Performance");
        AddStat("Words Typed", GetMetric(metrics, "battle_words_typed"), ThemeColors.AccentCyan);
        AddStat("Chars Typed", GetMetric(metrics, "battle_chars_typed"), ThemeColors.AccentCyan);
        AddStat("Errors", GetMetric(metrics, "battle_errors"), ThemeColors.Error);
        AddStat("Perfect Streak", GetMetric(metrics, "perfect_word_streak"), ThemeColors.GoldAccent);

        // Calculate accuracy
        int chars = ParseInt(metrics, "battle_chars_typed");
        int errors = ParseInt(metrics, "battle_errors");
        float accuracy = chars > 0 ? (float)(chars - errors) / chars * 100f : 0f;
        AddStat("Accuracy", $"{accuracy:F1}%", GetAccuracyColor(accuracy));

        // Accuracy trend
        if (_accuracyHistory.Count >= 2)
        {
            float prev = _accuracyHistory[^2];
            float curr = _accuracyHistory[^1];
            string trend = curr > prev + 1f ? "^ Improving" : curr < prev - 1f ? "v Declining" : "= Stable";
            Color trendColor = curr > prev + 1f ? ThemeColors.Success : curr < prev - 1f ? ThemeColors.Error : ThemeColors.TextDim;
            AddStat("Trend", trend, trendColor);
        }

        AddSection("WPM History (Last 5)");
        if (_wpmHistory.Count > 0)
        {
            for (int i = Math.Max(0, _wpmHistory.Count - 5); i < _wpmHistory.Count; i++)
            {
                AddStat($"  Session {i + 1}", $"{_wpmHistory[i]:F0} WPM");
            }
        }
        else
        {
            AddStat("  No sessions", "recorded yet", ThemeColors.TextDim);
        }

        AddSection("Session Details");
        AddStat("Current Session Words", GetMetric(metrics, "battle_words_typed"));
        AddStat("Current Session Chars", GetMetric(metrics, "battle_chars_typed"));
        AddStat("Current Session Errors", GetMetric(metrics, "battle_errors"), ThemeColors.Error);
    }

    private void ShowProgressionTab(GameState state)
    {
        AddSection("Game Progress");
        AddStat("Current Act", state.CurrentAct.ToString());
        AddStat("Quests Completed", state.CompletedQuests.Count.ToString(), ThemeColors.AccentCyan);
        AddStat("Milestones", state.Milestones.Count.ToString(), ThemeColors.GoldAccent);

        AddSection("Research");
        AddStat("Active Research", string.IsNullOrEmpty(state.ActiveResearch) ? "None" : Capitalize(state.ActiveResearch));
        AddStat("Progress", state.ResearchProgress.ToString());
        AddStat("Completed", state.CompletedResearch.Count.ToString());

        AddSection("Titles & Badges");
        AddStat("Equipped Title", string.IsNullOrEmpty(state.EquippedTitle) ? "None" : state.EquippedTitle);
        AddStat("Titles Unlocked", state.UnlockedTitles.Count.ToString());
        AddStat("Badges Earned", state.UnlockedBadges.Count.ToString());

        AddSection("Exploration");
        AddStat("Tiles Discovered", state.Discovered.Count.ToString());
        AddStat("Map Size", $"{state.MapW}x{state.MapH}");
    }

    private void ShowEconomyTab(GameState state)
    {
        AddSection("Economy");
        AddStat("Gold", state.Gold.ToString(), ThemeColors.GoldAccent);
        AddStat("Peak Gold", state.PeakGold.ToString(), ThemeColors.GoldAccent);

        AddSection("Resources");
        foreach (var (res, amount) in state.Resources)
        {
            Color color = ThemeColors.GetResourceColor(res);
            AddStat($"  {Capitalize(res)}", amount.ToString(), color);
        }

        AddSection("Workers");
        AddStat("Workers", $"{state.WorkerCount} / {state.MaxWorkers}");
        AddStat("Total Workers", state.TotalWorkers.ToString());
        AddStat("Upkeep", state.WorkerUpkeep.ToString());

        AddSection("Trade Rates");
        foreach (var (rate, value) in state.TradeRates)
        {
            AddStat($"  {FormatTradeRate(rate)}", $"{value:F2}x");
        }
    }

    public void RecordSession(float wpm, float accuracy)
    {
        _wpmHistory.Add(wpm);
        _accuracyHistory.Add(accuracy);
        // Keep last 10
        while (_wpmHistory.Count > 10) _wpmHistory.RemoveAt(0);
        while (_accuracyHistory.Count > 10) _accuracyHistory.RemoveAt(0);
    }

    private void AddSection(string title)
    {
        _statsList.Widgets.Add(new Panel { Height = DesignSystem.SpaceXs });
        _statsList.Widgets.Add(new Label
        {
            Text = title,
            TextColor = ThemeColors.Accent,
        });
        _statsList.Widgets.Add(new HorizontalSeparator());
    }

    private void AddStat(string label, string value, Color? valueColor = null)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        row.Widgets.Add(new Label
        {
            Text = label,
            TextColor = ThemeColors.TextDim,
            Width = 200,
        });
        row.Widgets.Add(new Label
        {
            Text = value,
            TextColor = valueColor ?? ThemeColors.Text,
        });
        _statsList.Widgets.Add(row);
    }

    private static string GetMetric(Dictionary<string, object> metrics, string key)
        => metrics.GetValueOrDefault(key)?.ToString() ?? "0";

    private static int ParseInt(Dictionary<string, object> metrics, string key)
    {
        var val = metrics.GetValueOrDefault(key);
        return val != null ? Convert.ToInt32(val) : 0;
    }

    private static string Capitalize(string s)
        => string.IsNullOrEmpty(s) ? s : char.ToUpper(s[0]) + s[1..];

    private static string FormatTradeRate(string key)
        => key.Replace("_to_", " -> ").Replace("_", " ");

    private static Color GetAccuracyColor(float accuracy)
    {
        if (accuracy >= 95f) return ThemeColors.Success;
        if (accuracy >= 80f) return ThemeColors.Warning;
        return ThemeColors.Error;
    }
}
