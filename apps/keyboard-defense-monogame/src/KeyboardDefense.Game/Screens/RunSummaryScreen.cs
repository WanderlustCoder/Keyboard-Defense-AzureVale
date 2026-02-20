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
    private Desktop? _desktop;
    private KeyboardState _prevKeyboard;

    public RunSummaryScreen(KeyboardDefenseGame game, ScreenManager screenManager, bool isVictory)
        : base(game, screenManager)
    {
        _isVictory = isVictory;
    }

    public override void OnEnter()
    {
        var report = SessionAnalytics.Instance.GetReport();
        BuildUi(report);
    }

    private void BuildUi(SessionReport report)
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
            GridRow = row,
            GridColumn = col,
        };
        grid.Widgets.Add(labelWidget);

        var valueWidget = new Label
        {
            Text = value,
            TextColor = ThemeColors.Text,
            GridRow = row,
            GridColumn = col + 1,
        };
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

    private void OnNewGame()
    {
        // Pop summary, pop victory/defeat, pop battlefield — then push fresh main menu
        // Use Switch to clear the entire stack and start fresh
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
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        _desktop?.Render();
    }
}
