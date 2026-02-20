using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Screens;

/// <summary>
/// Defeat screen shown when the player loses a battle.
/// Displays survival stats, retry option, and return to campaign map.
/// </summary>
public class DefeatScreen : GameScreen
{
    private readonly int _nodeIndex;
    private readonly string _nodeName;
    private readonly GameState _finalState;
    private readonly List<string> _newMilestones;
    private Desktop? _desktop;
    private KeyboardState _prevKeyboard;

    public DefeatScreen(
        KeyboardDefenseGame game, ScreenManager screenManager,
        int nodeIndex, string nodeName,
        GameState finalState, List<string> newMilestones)
        : base(game, screenManager)
    {
        _nodeIndex = nodeIndex;
        _nodeName = nodeName;
        _finalState = finalState;
        _newMilestones = newMilestones;
    }

    public override void OnEnter()
    {
        // Record progression (defeat)
        double wpm = TypingMetrics.GetWpm(_finalState);
        double accuracy = TypingMetrics.GetAccuracy(_finalState);
        int wordsTyped = Convert.ToInt32(
            _finalState.TypingMetrics.GetValueOrDefault("battle_words_typed", 0));

        ProgressionState.Instance.RecordGameEnd(
            victory: false,
            day: _finalState.Day,
            enemiesDefeated: _finalState.EnemiesDefeated,
            wordsTyped: wordsTyped,
            wpm: wpm,
            accuracy: accuracy);

        BuildUi(wpm, accuracy, wordsTyped);
    }

    private void BuildUi(double wpm, double accuracy, int wordsTyped)
    {
        var root = new VerticalStackPanel
        {
            Spacing = DesignSystem.SpaceLg,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Width = 500,
        };

        // Title
        root.Widgets.Add(new Label
        {
            Text = "DEFEATED",
            TextColor = ThemeColors.Error,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        root.Widgets.Add(new Label
        {
            Text = _nodeName,
            TextColor = ThemeColors.TextDim,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        root.Widgets.Add(new HorizontalSeparator());

        // Survival stats
        root.Widgets.Add(new Label
        {
            Text = "Battle Summary",
            TextColor = ThemeColors.AccentBlue,
        });

        var statsGrid = new Grid
        {
            ColumnSpacing = DesignSystem.SpaceMd,
            RowSpacing = DesignSystem.SpaceXs,
        };
        statsGrid.ColumnsProportions.Add(new Proportion(ProportionType.Pixels, 200));
        statsGrid.ColumnsProportions.Add(new Proportion(ProportionType.Fill));

        AddStatRow(statsGrid, 0, "Survived to Day", $"{_finalState.Day}");
        AddStatRow(statsGrid, 1, "Enemies Defeated", $"{_finalState.EnemiesDefeated}");
        AddStatRow(statsGrid, 2, "Words Typed", $"{wordsTyped}");
        AddStatRow(statsGrid, 3, "WPM", $"{wpm:F1}");
        AddStatRow(statsGrid, 4, "Accuracy", $"{accuracy * 100:F1}%");
        AddStatRow(statsGrid, 5, "Best Combo", $"{_finalState.MaxComboEver}");

        root.Widgets.Add(statsGrid);

        // Milestones earned (even in defeat)
        if (_newMilestones.Count > 0)
        {
            root.Widgets.Add(new HorizontalSeparator());
            root.Widgets.Add(new Label
            {
                Text = "Milestones Earned",
                TextColor = ThemeColors.GoldAccent,
            });

            foreach (string milestoneId in _newMilestones)
            {
                var def = Milestones.GetMilestone(milestoneId);
                if (def == null) continue;

                var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
                row.Widgets.Add(new Label
                {
                    Text = "*",
                    TextColor = ThemeColors.GoldAccent,
                    Width = 20,
                });
                row.Widgets.Add(new Label
                {
                    Text = def.Name,
                    TextColor = ThemeColors.Accent,
                    Width = 160,
                });
                row.Widgets.Add(new Label
                {
                    Text = def.Description,
                    TextColor = ThemeColors.TextDim,
                });
                root.Widgets.Add(row);
            }
        }

        root.Widgets.Add(new HorizontalSeparator());

        // Encouragement
        root.Widgets.Add(new Label
        {
            Text = "Keep practicing to improve your typing skills!",
            TextColor = ThemeColors.Info,
            HorizontalAlignment = HorizontalAlignment.Center,
            Wrap = true,
        });

        // Buttons
        var buttonRow = new HorizontalStackPanel
        {
            Spacing = DesignSystem.SpaceMd,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var retryBtn = ButtonFactory.Primary("Retry", OnRetry);
        buttonRow.Widgets.Add(retryBtn);

        var mapBtn = ButtonFactory.Secondary("Return to Map", OnReturnToMap);
        buttonRow.Widgets.Add(mapBtn);

        root.Widgets.Add(buttonRow);

        root.Widgets.Add(new Label
        {
            Text = "Press Enter to retry, Escape to return to map",
            TextColor = ThemeColors.TextDim,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        _desktop = new Desktop { Root = root };
    }

    private void AddStatRow(Grid grid, int row, string label, string value)
    {
        grid.RowsProportions.Add(new Proportion(ProportionType.Auto));

        var labelWidget = new Label
        {
            Text = label,
            TextColor = ThemeColors.TextDim,
            GridRow = row,
            GridColumn = 0,
        };
        grid.Widgets.Add(labelWidget);

        var valueWidget = new Label
        {
            Text = value,
            TextColor = ThemeColors.Text,
            GridRow = row,
            GridColumn = 1,
        };
        grid.Widgets.Add(valueWidget);
    }

    private void OnRetry()
    {
        // Pop defeat screen, then battlefield screen, then push a new battlefield
        ScreenManager.Pop(); // Pop defeat screen
        ScreenManager.Pop(); // Pop old battlefield
        var battle = new BattlefieldScreen(Game, ScreenManager, _nodeIndex, _nodeName);
        ScreenManager.Push(battle);
    }

    private void OnReturnToMap()
    {
        // Pop defeat screen — battlefield underneath already has OnExit wired
        ScreenManager.Pop();
        ScreenManager.Pop(); // Pop battlefield too, returning to campaign map
    }

    public override void Update(GameTime gameTime)
    {
        var kb = Keyboard.GetState();

        if (kb.IsKeyDown(Keys.Enter) && !_prevKeyboard.IsKeyDown(Keys.Enter))
            OnRetry();
        else if (kb.IsKeyDown(Keys.Escape) && !_prevKeyboard.IsKeyDown(Keys.Escape))
            OnReturnToMap();

        _prevKeyboard = kb;
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        _desktop?.Render();
    }
}
