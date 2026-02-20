using System;
using System.Collections.Generic;
using System.Linq;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Panel showing the player's typing profile: per-key accuracy heatmap,
/// WPM trend, weak/strong keys, and recommended lessons.
/// </summary>
public class TypingProfilePanel : BasePanel
{
    private readonly string[] _tabs = { "Overview", "Key Accuracy", "History", "Recommendations" };
    private int _activeTab;

    public TypingProfilePanel() : base(Locale.Tr("menu.typing_profile"))
    {
        RootWidget.Width = 560;
        RootWidget.Height = 480;
        BuildTabBar();
        ShowTab(0);
    }

    private void BuildTabBar()
    {
        var tabBar = new HorizontalStackPanel { Spacing = DesignSystem.SpacingSm };
        for (int i = 0; i < _tabs.Length; i++)
        {
            int tabIndex = i;
            var btn = ButtonFactory.Ghost(_tabs[i], () => ShowTab(tabIndex));
            btn.Width = 120;
            btn.Height = DesignSystem.SizeButtonSm;
            tabBar.Widgets.Add(btn);
        }
        AddWidget(tabBar);
        AddWidget(new HorizontalSeparator());
    }

    private void ShowTab(int index)
    {
        _activeTab = index;
        // Remove everything after tab bar + separator (first 2 widgets)
        while (Content.Widgets.Count > 2)
            Content.Widgets.RemoveAt(Content.Widgets.Count - 1);

        switch (index)
        {
            case 0: BuildOverview(); break;
            case 1: BuildKeyAccuracy(); break;
            case 2: BuildHistory(); break;
            case 3: BuildRecommendations(); break;
        }
    }

    public void Refresh() => ShowTab(_activeTab);

    private void BuildOverview()
    {
        var profile = TypingProfile.Instance;
        var scroll = new ScrollViewer();
        var vbox = new VerticalStackPanel { Spacing = DesignSystem.SpacingSm };

        // Summary stats
        vbox.Widgets.Add(MakeHeader("Summary"));

        double avgWpm = profile.GetAverageWpm();
        double overallAcc = profile.GetOverallAccuracy();
        double wpmTrend = profile.GetWpmTrend();
        double accTrend = profile.GetAccuracyTrend();
        double difficulty = profile.GetDifficultyLevel();

        vbox.Widgets.Add(MakeStat("Average WPM (last 5)", $"{avgWpm:F1} {TrendArrow(wpmTrend)}"));
        vbox.Widgets.Add(MakeStat("Overall Accuracy", $"{overallAcc:P1} {TrendArrow(accTrend)}"));
        vbox.Widgets.Add(MakeStat("Difficulty Level", $"{difficulty:P0}"));
        vbox.Widgets.Add(MakeStat("Total Words Typed", $"{profile.TotalWordsTyped:N0}"));
        vbox.Widgets.Add(MakeStat("Total Chars Typed", $"{profile.TotalCharsTyped:N0}"));
        vbox.Widgets.Add(MakeStat("Total Errors", $"{profile.TotalErrors:N0}"));
        vbox.Widgets.Add(MakeStat("Sessions", $"{profile.Sessions.Count}"));

        double playMins = profile.TotalPlayTimeSeconds / 60.0;
        vbox.Widgets.Add(MakeStat("Play Time", playMins < 60 ? $"{playMins:F0}m" : $"{playMins / 60:F1}h"));

        // Weak/strong keys
        var weak = profile.GetWeakKeys();
        var strong = profile.GetStrongKeys();
        if (weak.Count > 0)
        {
            vbox.Widgets.Add(new Panel { Height = DesignSystem.SpaceSm });
            vbox.Widgets.Add(MakeHeader("Weak Keys"));
            string weakStr = string.Join(", ", weak.Take(10).Select(c => $"{char.ToUpper(c)} ({profile.GetKeyAccuracy(c):P0})"));
            vbox.Widgets.Add(new Label { Text = weakStr, TextColor = ThemeColors.Error });
        }
        if (strong.Count > 0)
        {
            vbox.Widgets.Add(new Panel { Height = DesignSystem.SpaceSm });
            vbox.Widgets.Add(MakeHeader("Strong Keys"));
            string strongStr = string.Join(", ", strong.Take(10).Select(c => $"{char.ToUpper(c)} ({profile.GetKeyAccuracy(c):P0})"));
            vbox.Widgets.Add(new Label { Text = strongStr, TextColor = ThemeColors.Success });
        }

        scroll.Content = vbox;
        AddWidget(scroll);
    }

    private void BuildKeyAccuracy()
    {
        var profile = TypingProfile.Instance;
        var scroll = new ScrollViewer();
        var vbox = new VerticalStackPanel { Spacing = DesignSystem.SpacingSm };

        vbox.Widgets.Add(MakeHeader("Per-Key Accuracy (QWERTY Layout)"));

        // Keyboard rows
        string[] rows = { "QWERTYUIOP", "ASDFGHJKL;", "ZXCVBNM,./" };
        string[] fingerNames = { "L.Pinky", "L.Ring", "L.Mid", "L.Index", "R.Index", "R.Mid", "R.Ring", "R.Pinky" };

        foreach (string row in rows)
        {
            var rowPanel = new HorizontalStackPanel { Spacing = 2 };
            foreach (char c in row)
            {
                char lower = char.ToLower(c);
                double acc = profile.GetKeyAccuracy(lower);
                var stats = profile.KeyStats.GetValueOrDefault(lower);

                string label;
                Microsoft.Xna.Framework.Color color;
                if (acc < 0)
                {
                    label = $" {c} ";
                    color = ThemeColors.TextDisabled;
                }
                else
                {
                    label = $"{c}:{acc:P0}";
                    color = acc >= TypingProfile.StrongKeyThreshold ? ThemeColors.Success
                        : acc >= TypingProfile.WeakKeyThreshold ? ThemeColors.AccentCyan
                        : ThemeColors.Error;
                }

                var keyLabel = new Label
                {
                    Text = label,
                    TextColor = color,
                    Width = 48,
                    HorizontalAlignment = Myra.Graphics2D.UI.HorizontalAlignment.Center,
                };
                rowPanel.Widgets.Add(keyLabel);
            }
            vbox.Widgets.Add(rowPanel);
        }

        // Finger zone breakdown
        vbox.Widgets.Add(new Panel { Height = DesignSystem.SpaceMd });
        vbox.Widgets.Add(MakeHeader("By Finger"));

        for (int zone = 0; zone < 8; zone++)
        {
            var keysInZone = profile.KeyStats
                .Where(kv => TypingProfile.GetFingerZone(kv.Key) == zone && kv.Value.Total >= TypingProfile.MinSamplesForWeakKey)
                .ToList();
            if (keysInZone.Count == 0) continue;

            double zoneAcc = keysInZone.Sum(kv => kv.Value.Correct) / (double)Math.Max(keysInZone.Sum(kv => kv.Value.Total), 1);
            var color = zoneAcc >= TypingProfile.StrongKeyThreshold ? ThemeColors.Success
                : zoneAcc >= TypingProfile.WeakKeyThreshold ? ThemeColors.AccentCyan
                : ThemeColors.Error;
            vbox.Widgets.Add(new Label { Text = $"  {fingerNames[zone]}: {zoneAcc:P1}", TextColor = color });
        }

        scroll.Content = vbox;
        AddWidget(scroll);
    }

    private void BuildHistory()
    {
        var profile = TypingProfile.Instance;
        var scroll = new ScrollViewer();
        var vbox = new VerticalStackPanel { Spacing = DesignSystem.SpacingSm };

        vbox.Widgets.Add(MakeHeader("WPM History"));

        if (profile.Sessions.Count == 0)
        {
            vbox.Widgets.Add(new Label { Text = "No sessions recorded yet.", TextColor = ThemeColors.TextDisabled });
        }
        else
        {
            // WPM sparkline (text-based)
            var wpmValues = profile.Sessions.Select(s => s.Wpm).ToList();
            double maxWpm = wpmValues.Max();
            double minWpm = wpmValues.Min();

            string sparkline = BuildSparkline(wpmValues, minWpm, maxWpm);
            vbox.Widgets.Add(new Label { Text = $"WPM: {sparkline}", TextColor = ThemeColors.AccentCyan });
            vbox.Widgets.Add(new Label
            {
                Text = $"  Range: {minWpm:F0} - {maxWpm:F0}  Avg: {wpmValues.Average():F1}",
                TextColor = ThemeColors.TextDim,
            });

            // Recent sessions
            vbox.Widgets.Add(new Panel { Height = DesignSystem.SpaceMd });
            vbox.Widgets.Add(MakeHeader("Recent Sessions"));

            // Column headers
            vbox.Widgets.Add(new Label
            {
                Text = "  WPM    Acc.   Words  Errors  Lesson",
                TextColor = ThemeColors.TextDisabled,
            });
            vbox.Widgets.Add(new HorizontalSeparator());

            for (int i = profile.Sessions.Count - 1; i >= Math.Max(0, profile.Sessions.Count - 10); i--)
            {
                var s = profile.Sessions[i];
                string line = $"  {s.Wpm,5:F1}  {s.Accuracy,5:P0}  {s.WordsTyped,5}  {s.Errors,6}  {(string.IsNullOrEmpty(s.LessonId) ? "-" : s.LessonId)}";
                vbox.Widgets.Add(new Label { Text = line, TextColor = ThemeColors.Text });
            }
        }

        scroll.Content = vbox;
        AddWidget(scroll);
    }

    private void BuildRecommendations()
    {
        var profile = TypingProfile.Instance;
        var scroll = new ScrollViewer();
        var vbox = new VerticalStackPanel { Spacing = DesignSystem.SpacingSm };

        vbox.Widgets.Add(MakeHeader("Recommended Practice"));

        var weak = profile.GetWeakKeys();
        var recommendations = profile.GetRecommendedLessonIds();

        if (weak.Count == 0)
        {
            vbox.Widgets.Add(new Label { Text = "No weak keys detected. Keep practicing!", TextColor = ThemeColors.Success });
        }
        else
        {
            vbox.Widgets.Add(new Label { Text = "These keys need work:", TextColor = ThemeColors.Warning });
            foreach (char c in weak.Take(8))
            {
                double acc = profile.GetKeyAccuracy(c);
                int zone = TypingProfile.GetFingerZone(c);
                string row = TypingProfile.GetKeyRow(c);
                string finger = zone switch
                {
                    0 => "Left Pinky", 1 => "Left Ring", 2 => "Left Middle", 3 => "Left Index",
                    4 => "Right Index", 5 => "Right Middle", 6 => "Right Ring", 7 => "Right Pinky",
                    _ => "Unknown",
                };
                vbox.Widgets.Add(new Label
                {
                    Text = $"  {char.ToUpper(c)} - {acc:P0} accuracy ({row} row, {finger})",
                    TextColor = ThemeColors.Error,
                });
            }
        }

        if (recommendations.Count > 0)
        {
            vbox.Widgets.Add(new Panel { Height = DesignSystem.SpaceMd });
            vbox.Widgets.Add(MakeHeader("Suggested Lessons"));
            foreach (string lessonId in recommendations)
            {
                string label = Core.Data.LessonsData.LessonLabel(lessonId);
                vbox.Widgets.Add(new Label { Text = $"  - {label} ({lessonId})", TextColor = ThemeColors.AccentCyan });
            }
        }

        // Difficulty assessment
        vbox.Widgets.Add(new Panel { Height = DesignSystem.SpaceMd });
        vbox.Widgets.Add(MakeHeader("Adaptive Difficulty"));
        double diff = profile.GetDifficultyLevel();
        string diffLabel = diff < 0.25 ? "Beginner" : diff < 0.5 ? "Intermediate" : diff < 0.75 ? "Advanced" : "Expert";
        vbox.Widgets.Add(new Label { Text = $"  Current Level: {diffLabel} ({diff:P0})", TextColor = ThemeColors.Accent });
        vbox.Widgets.Add(new Label
        {
            Text = "  Game words adapt based on your weak keys.",
            TextColor = ThemeColors.TextDim,
        });

        scroll.Content = vbox;
        AddWidget(scroll);
    }

    // --- Helpers ---

    private static Label MakeHeader(string text) => new()
    {
        Text = text,
        TextColor = ThemeColors.Accent,
    };

    private static HorizontalStackPanel MakeStat(string label, string value)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        row.Widgets.Add(new Label { Text = $"  {label}:", TextColor = ThemeColors.TextDim, Width = 200 });
        row.Widgets.Add(new Label { Text = value, TextColor = ThemeColors.Text });
        return row;
    }

    private static string TrendArrow(double delta)
    {
        if (delta > 0.01) return "(+)";
        if (delta < -0.01) return "(-)";
        return "(=)";
    }

    private static string BuildSparkline(List<double> values, double min, double max)
    {
        if (values.Count == 0) return "";
        string[] blocks = { "_", ".", "-", "=", "#" };
        double range = Math.Max(max - min, 1);
        var chars = new char[values.Count];
        for (int i = 0; i < values.Count; i++)
        {
            int level = (int)Math.Clamp((values[i] - min) / range * 4, 0, 4);
            chars[i] = blocks[level][0];
        }
        return new string(chars);
    }
}
