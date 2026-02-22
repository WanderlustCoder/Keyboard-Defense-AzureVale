using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Myra.Graphics2D.UI;
using KeyboardDefense.Game.Effects;
using KeyboardDefense.Game.Rendering;
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
    private readonly string _verticalSliceProfileId;
    private Desktop? _desktop;
    private KeyboardState _prevKeyboard;
    private readonly HudPainter _painter = new();
    private readonly NineSliceFrame _frame = new();
    private string _performanceGrade = "";

    public RunSummaryScreen(
        KeyboardDefenseGame game,
        ScreenManager screenManager,
        bool isVictory,
        int nodeIndex = 0,
        string nodeName = "Vertical Slice",
        string verticalSliceProfileId = "vertical_slice_default")
        : base(game, screenManager)
    {
        _isVictory = isVictory;
        _nodeIndex = nodeIndex;
        _nodeName = nodeName;
        _verticalSliceProfileId = verticalSliceProfileId;
    }

    public override void OnEnter()
    {
        if (Game.DefaultFont != null)
        {
            _painter.Initialize(Game.GraphicsDevice, Game.DefaultFont);
            _frame.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        }

        var report = SessionAnalytics.Instance.GetReport();
        var verticalSliceSummary = TryGetVerticalSliceSummary();
        if (verticalSliceSummary != null)
        {
            VerticalSliceProfileService.RecordRun(
                verticalSliceSummary.Result,
                verticalSliceSummary.Score,
                verticalSliceSummary.ElapsedSeconds);
        }

        _performanceGrade = report.PerformanceGrade;
        BuildUi(report, verticalSliceSummary);
    }

    private void BuildUi(SessionReport report, VerticalSliceSummary? verticalSliceSummary)
    {
        var rootPanel = new Panel();
        var root = new VerticalStackPanel
        {
            Spacing = DesignSystem.SpaceLg,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Width = 560,
        };

        // Title spacer (drawn via SpriteBatch)
        root.Widgets.Add(new Panel { Height = 60 });

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

        AddStatCell(statsGrid, 0, 0, "Days Survived", $"{report.DaysCompleted}");
        AddStatCell(statsGrid, 1, 0, "Enemies Defeated", $"{report.EnemiesDefeated}");
        AddStatCell(statsGrid, 2, 0, "Words Typed", $"{report.WordsTyped}");
        AddStatCell(statsGrid, 3, 0, "Peak Combo", $"{report.PeakCombo}");

        AddStatCell(statsGrid, 0, 2, "Accuracy", $"{report.AccuracyRate * 100:F1}%");
        AddStatCell(statsGrid, 1, 2, "WPM", $"{report.WordsPerMinute:F1}");
        AddStatCell(statsGrid, 2, 2, "Gold Earned", $"{report.GoldEarned}");
        AddStatCell(statsGrid, 3, 2, "Play Time", FormatTime(report.TotalPlayTimeSeconds));

        root.Widgets.Add(statsGrid);

        root.Widgets.Add(new HorizontalSeparator());

        // Performance Grade (label only — glow drawn via SpriteBatch)
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

        root.Widgets.Add(new HorizontalSeparator());

        // Buttons
        var buttonRow = new HorizontalStackPanel
        {
            Spacing = DesignSystem.SpaceMd,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var newGameBtn = ButtonFactory.Primary("New Game", OnNewGame);
        buttonRow.Widgets.Add(newGameBtn);

        var mainMenuBtn = ButtonFactory.Secondary("Main Menu", OnMainMenu);
        buttonRow.Widgets.Add(mainMenuBtn);

        root.Widgets.Add(buttonRow);

        root.Widgets.Add(new Label
        {
            Text = "Press Enter for New Game, Escape for Main Menu",
            TextColor = ThemeColors.TextDim,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        rootPanel.Widgets.Add(root);
        _desktop = new Desktop { Root = rootPanel };
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
        ScreenManager.Switch(new MainMenuScreen(Game, ScreenManager));
    }

    private void OnMainMenu()
    {
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
        SceneTransition.Instance.Update(gameTime);
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        var vp = Game.GraphicsDevice.Viewport;

        spriteBatch.Begin(blendState: BlendState.AlphaBlend, samplerState: SamplerState.PointClamp);

        if (_painter.IsReady)
        {
            // Gradient background — tint based on victory/defeat
            Color bgBottom = _isVictory ? new Color(16, 14, 25) : new Color(25, 10, 10);
            _painter.DrawGradientV(spriteBatch,
                new Rectangle(0, 0, vp.Width, vp.Height),
                ThemeColors.BgDark, bgBottom, 16);

            // Frame — Gold for victory, Combat for defeat
            var frameStyle = _isVictory ? FrameStyles.Gold : FrameStyles.Combat;
            int frameW = 580;
            int frameH = vp.Height - 80;
            int frameX = (vp.Width - frameW) / 2;
            int frameY = 40;
            if (_frame.IsReady)
                _frame.DrawFrame(spriteBatch, new Rectangle(frameX, frameY, frameW, frameH), frameStyle);

            // Header glow title
            string titleText = _isVictory ? "VICTORY!" : "DEFEAT";
            Color titleColor = _isVictory ? ThemeColors.GoldAccent : ThemeColors.DamageRed;
            var titleSize = _painter.Font!.MeasureString(titleText) * 0.8f;
            float titleX = vp.Width / 2f - titleSize.X / 2f;
            float titleY = frameY + 16;
            _painter.DrawTextGlow(spriteBatch, new Vector2(titleX, titleY),
                titleText, titleColor, titleColor, 0.8f);

            // Grade glow for S/A
            if (_performanceGrade is "S" or "A")
            {
                var gradeColor = GetGradeColor(_performanceGrade);
                var gradeSize = _painter.Font.MeasureString(_performanceGrade) * 0.7f;
                float gradeX = vp.Width / 2f - gradeSize.X / 2f;
                float gradeY = titleY + titleSize.Y + 4;
                _painter.DrawTextGlow(spriteBatch, new Vector2(gradeX, gradeY),
                    _performanceGrade, gradeColor, gradeColor, 0.7f);
            }
        }

        spriteBatch.End();

        _desktop?.Render();

        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }
}
