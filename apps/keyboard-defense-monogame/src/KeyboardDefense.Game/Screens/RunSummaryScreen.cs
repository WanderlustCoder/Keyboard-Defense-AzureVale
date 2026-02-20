using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Myra.Graphics2D.UI;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Screens;

/// <summary>
/// Run summary screen shown after victory or game_over.
/// Displays session analytics with performance grade.
/// </summary>
public class RunSummaryScreen : GameScreen
{
    private readonly bool _isVictory;
    private readonly int _nodeIndex;
    private readonly string _nodeName;
    private readonly bool _returnToCampaignMapOnSummary;
    private readonly string _verticalSliceProfileId;
    private readonly CampaignProgressionService.CampaignSummaryHandoff _campaignSummaryHandoff;
    private readonly string _campaignNodeId;
    private readonly int _campaignNodeRewardGold;
    private CampaignProgressionService.CampaignOutcome _campaignOutcome =
        CampaignProgressionService.CampaignOutcome.None;
    private Desktop? _desktop;
    private KeyboardState _prevKeyboard;

    public RunSummaryScreen(
        KeyboardDefenseGame game,
        ScreenManager screenManager,
        bool isVictory,
        int nodeIndex = 0,
        string nodeName = "Vertical Slice",
        bool returnToCampaignMapOnSummary = false,
        string verticalSliceProfileId = "vertical_slice_default",
        string campaignNodeId = "",
        int campaignNodeRewardGold = 0,
        CampaignProgressionService.CampaignSummaryHandoff? campaignSummaryHandoff = null)
        : base(game, screenManager)
    {
        _isVictory = isVictory;
        _nodeIndex = nodeIndex;
        _nodeName = nodeName;
        _verticalSliceProfileId = verticalSliceProfileId;
        _campaignSummaryHandoff = campaignSummaryHandoff ??
            CampaignProgressionService.CampaignSummaryHandoff.Create(
                returnToCampaignMapOnSummary,
                campaignNodeId,
                campaignNodeRewardGold);
        _returnToCampaignMapOnSummary = _campaignSummaryHandoff.ReturnToCampaignMapOnSummary;
        _campaignNodeId = _campaignSummaryHandoff.CampaignNodeId;
        _campaignNodeRewardGold = _campaignSummaryHandoff.CampaignNodeRewardGold;
    }

    public override void OnEnter()
    {
        var report = SessionAnalytics.Instance.GetReport();
        var verticalSliceSummary = TryGetVerticalSliceSummary();
        if (verticalSliceSummary != null)
            VerticalSliceProfileService.RecordRun(
                verticalSliceSummary.Result,
                verticalSliceSummary.Score,
                verticalSliceSummary.ElapsedSeconds);
        _campaignOutcome = ApplyCampaignProgression(report, verticalSliceSummary);
        BuildUi(report, verticalSliceSummary);
    }

    private CampaignProgressionService.CampaignOutcome ApplyCampaignProgression(
        SessionReport report,
        VerticalSliceSummary? verticalSliceSummary)
    {
        var state = GameController.Instance.State;
        int wordsTyped = verticalSliceSummary?.WordsTyped ?? report.WordsTyped;
        int enemiesDefeated = verticalSliceSummary?.EnemiesDefeated ?? state.EnemiesDefeated;
        return CampaignProgressionService.ApplySingleWaveOutcome(
            ProgressionState.Instance,
            _campaignSummaryHandoff,
            _isVictory,
            state.Day,
            enemiesDefeated,
            wordsTyped,
            report.WordsPerMinute,
            report.AccuracyRate);
    }

    private void BuildUi(SessionReport report, VerticalSliceSummary? verticalSliceSummary)
    {
        var root = new VerticalStackPanel
        {
            Spacing = DesignSystem.SpaceLg,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Width = 560,
        };

        // Header
        root.Widgets.Add(new Label
        {
            Text = _isVictory ? "VICTORY!" : "DEFEAT",
            TextColor = _isVictory ? ThemeColors.GoldAccent : ThemeColors.Error,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        root.Widgets.Add(new Label
        {
            Text = "Run Summary",
            TextColor = ThemeColors.AccentCyan,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        root.Widgets.Add(new HorizontalSeparator());

        // Two-column stats grid
        var statsGrid = new Grid
        {
            ColumnSpacing = DesignSystem.SpaceXl,
            RowSpacing = DesignSystem.SpaceXs,
        };
        statsGrid.ColumnsProportions.Add(new Proportion(ProportionType.Pixels, 140));
        statsGrid.ColumnsProportions.Add(new Proportion(ProportionType.Pixels, 100));
        statsGrid.ColumnsProportions.Add(new Proportion(ProportionType.Pixels, 140));
        statsGrid.ColumnsProportions.Add(new Proportion(ProportionType.Fill));

        // Left column: Days Survived, Enemies Defeated, Words Typed, Peak Combo
        AddStatCell(statsGrid, 0, 0, "Days Survived", $"{report.DaysCompleted}");
        AddStatCell(statsGrid, 1, 0, "Enemies Defeated", $"{report.EnemiesDefeated}");
        AddStatCell(statsGrid, 2, 0, "Words Typed", $"{report.WordsTyped}");
        AddStatCell(statsGrid, 3, 0, "Peak Combo", $"{report.PeakCombo}");

        // Right column: Accuracy, WPM, Gold Earned, Play Time
        AddStatCell(statsGrid, 0, 2, "Accuracy", $"{report.AccuracyRate * 100:F1}%");
        AddStatCell(statsGrid, 1, 2, "WPM", $"{report.WordsPerMinute:F1}");
        AddStatCell(statsGrid, 2, 2, "Gold Earned", $"{report.GoldEarned}");
        AddStatCell(statsGrid, 3, 2, "Play Time", FormatTime(report.TotalPlayTimeSeconds));

        root.Widgets.Add(statsGrid);

        root.Widgets.Add(new HorizontalSeparator());

        // Performance Grade (centered, large)
        root.Widgets.Add(new Label
        {
            Text = "Performance Grade",
            TextColor = ThemeColors.AccentBlue,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        root.Widgets.Add(new Label
        {
            Text = report.PerformanceGrade,
            TextColor = GetGradeColor(report.PerformanceGrade),
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        if (verticalSliceSummary != null)
        {
            root.Widgets.Add(new HorizontalSeparator());
            root.Widgets.Add(new Label
            {
                Text = "Vertical Slice Result",
                TextColor = ThemeColors.AccentBlue,
                HorizontalAlignment = HorizontalAlignment.Center,
            });

            root.Widgets.Add(new Label
            {
                Text =
                    $"Result: {verticalSliceSummary.Result.ToUpperInvariant()}  " +
                    $"Score: {verticalSliceSummary.Score}  " +
                    $"Time: {FormatTime(verticalSliceSummary.ElapsedSeconds)}",
                TextColor = ThemeColors.Text,
                HorizontalAlignment = HorizontalAlignment.Center,
            });

            root.Widgets.Add(new Label
            {
                Text =
                    $"Enemies: {verticalSliceSummary.EnemiesDefeated}  " +
                    $"Words: {verticalSliceSummary.WordsTyped}  " +
                    $"Misses: {verticalSliceSummary.Misses}  " +
                    $"Damage: {verticalSliceSummary.DamageTaken}",
                TextColor = ThemeColors.TextDim,
                HorizontalAlignment = HorizontalAlignment.Center,
            });
        }

        if (_campaignOutcome.IsCampaignRun)
        {
            root.Widgets.Add(new HorizontalSeparator());
            root.Widgets.Add(new Label
            {
                Text = "Campaign Node",
                TextColor = ThemeColors.AccentBlue,
                HorizontalAlignment = HorizontalAlignment.Center,
            });

            var summaryDisplay = CampaignProgressionService.BuildSummaryDisplay(_campaignOutcome);
            var outcomeColor = summaryDisplay.Tone switch
            {
                CampaignProgressionService.CampaignOutcomeTone.Reward => ThemeColors.GoldAccent,
                CampaignProgressionService.CampaignOutcomeTone.Success => ThemeColors.Accent,
                CampaignProgressionService.CampaignOutcomeTone.Warning => ThemeColors.Warning,
                _ => ThemeColors.TextDim,
            };

            root.Widgets.Add(new Label
            {
                Text = summaryDisplay.Text,
                TextColor = outcomeColor,
                HorizontalAlignment = HorizontalAlignment.Center,
            });
        }

        root.Widgets.Add(new HorizontalSeparator());

        // Buttons
        var buttonRow = new HorizontalStackPanel
        {
            Spacing = DesignSystem.SpaceMd,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var newGameBtn = ButtonFactory.Primary(
            _returnToCampaignMapOnSummary ? "Retry Node" : "New Game",
            OnNewGame);
        buttonRow.Widgets.Add(newGameBtn);

        var mainMenuBtn = ButtonFactory.Secondary(
            _returnToCampaignMapOnSummary ? "Campaign Map" : "Main Menu",
            OnMainMenu);
        buttonRow.Widgets.Add(mainMenuBtn);

        root.Widgets.Add(buttonRow);

        root.Widgets.Add(new Label
        {
            Text = _returnToCampaignMapOnSummary
                ? "Press Enter to retry this node, Escape for campaign map"
                : "Press Enter for New Game, Escape for Main Menu",
            TextColor = ThemeColors.TextDim,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        _desktop = new Desktop { Root = root };
    }

    private void AddStatCell(Grid grid, int row, int col, string label, string value)
    {
        while (grid.RowsProportions.Count <= row)
            grid.RowsProportions.Add(new Proportion(ProportionType.Auto));

        var labelWidget = new Label
        {
            Text = label,
            TextColor = ThemeColors.TextDim,
        };
        Grid.SetRow(labelWidget, row);
        Grid.SetColumn(labelWidget, col);
        grid.Widgets.Add(labelWidget);

        var valueWidget = new Label
        {
            Text = value,
            TextColor = ThemeColors.Text,
        };
        Grid.SetRow(valueWidget, row);
        Grid.SetColumn(valueWidget, col + 1);
        grid.Widgets.Add(valueWidget);
    }

    private static Color GetGradeColor(string grade) => grade switch
    {
        "S" => ThemeColors.RarityLegendary,
        "A" => ThemeColors.RarityEpic,
        "B" => ThemeColors.RarityRare,
        "C" => ThemeColors.RarityUncommon,
        _ => ThemeColors.RarityCommon,
    };

    private static string FormatTime(double totalSeconds)
    {
        int minutes = (int)(totalSeconds / 60);
        int seconds = (int)(totalSeconds % 60);
        return $"{minutes}:{seconds:D2}";
    }

    private static VerticalSliceSummary? TryGetVerticalSliceSummary()
    {
        var state = GameController.Instance.State;
        string result = ReadMetricString(state, "vs_result");
        if (string.IsNullOrWhiteSpace(result))
            return null;

        return new VerticalSliceSummary
        {
            Result = result,
            Score = ReadMetricInt(state, "vs_score"),
            ElapsedSeconds = ReadMetricInt(state, "vs_elapsed_seconds"),
            EnemiesDefeated = ReadMetricInt(state, "enemies_defeated", state.EnemiesDefeated),
            WordsTyped = ReadMetricInt(state, "battle_words_typed"),
            Misses = ReadMetricInt(state, "vs_miss_count"),
            DamageTaken = ReadMetricInt(state, "vs_damage_taken"),
        };
    }

    private static int ReadMetricInt(Core.State.GameState state, string key, int fallback = 0)
    {
        if (!state.TypingMetrics.TryGetValue(key, out object? value) || value == null)
            return fallback;
        if (value is int i)
            return i;
        return int.TryParse(value.ToString(), out int parsed) ? parsed : fallback;
    }

    private static string ReadMetricString(Core.State.GameState state, string key)
    {
        if (!state.TypingMetrics.TryGetValue(key, out object? value) || value == null)
            return string.Empty;
        return value.ToString() ?? string.Empty;
    }

    private sealed class VerticalSliceSummary
    {
        public string Result { get; init; } = "";
        public int Score { get; init; }
        public int ElapsedSeconds { get; init; }
        public int EnemiesDefeated { get; init; }
        public int WordsTyped { get; init; }
        public int Misses { get; init; }
        public int DamageTaken { get; init; }
    }

    private void OnNewGame()
    {
        if (_returnToCampaignMapOnSummary)
        {
            GameController.Instance.NewGame($"campaign_retry_{DateTime.UtcNow.Ticks}");
            ScreenManager.Switch(new BattlefieldScreen(
                Game,
                ScreenManager,
                _nodeIndex,
                _nodeName,
                singleWaveMode: true,
                returnToCampaignMapOnSummary: true,
                verticalSliceProfileId: _verticalSliceProfileId,
                campaignNodeId: _campaignNodeId,
                campaignNodeRewardGold: _campaignNodeRewardGold));
            return;
        }

        ScreenManager.Switch(new MainMenuScreen(Game, ScreenManager));
    }

    private void OnMainMenu()
    {
        if (_returnToCampaignMapOnSummary)
        {
            ScreenManager.Switch(new CampaignMapScreen(Game, ScreenManager));
            return;
        }

        ScreenManager.Switch(new MainMenuScreen(Game, ScreenManager));
    }

    public override void Update(GameTime gameTime)
    {
        var kb = Keyboard.GetState();

        if (kb.IsKeyDown(Keys.Enter) && !_prevKeyboard.IsKeyDown(Keys.Enter))
            OnNewGame();
        else if (kb.IsKeyDown(Keys.Escape) && !_prevKeyboard.IsKeyDown(Keys.Escape))
            OnMainMenu();

        _prevKeyboard = kb;
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        _desktop?.Render();
    }
}
