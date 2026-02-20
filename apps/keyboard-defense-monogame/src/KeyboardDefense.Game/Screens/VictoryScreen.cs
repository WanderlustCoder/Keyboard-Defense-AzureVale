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
/// Victory screen shown after winning a battle.
/// Displays battle stats, score, grade, milestones earned, and gold.
/// </summary>
public class VictoryScreen : GameScreen
{
    private readonly int _nodeIndex;
    private readonly string _nodeName;
    private readonly GameState _finalState;
    private readonly List<string> _newMilestones;
    private Desktop? _desktop;
    private KeyboardState _prevKeyboard;

    public VictoryScreen(
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
        // Record progression
        double wpm = TypingMetrics.GetWpm(_finalState);
        double accuracy = TypingMetrics.GetAccuracy(_finalState);
        int wordsTyped = Convert.ToInt32(
            _finalState.TypingMetrics.GetValueOrDefault("battle_words_typed", 0));

        ProgressionState.Instance.CompleteNode(_nodeIndex);
        ProgressionState.Instance.RecordGameEnd(
            victory: true,
            day: _finalState.Day,
            enemiesDefeated: _finalState.EnemiesDefeated,
            wordsTyped: wordsTyped,
            wpm: wpm,
            accuracy: accuracy);

        BuildUi(wpm, accuracy, wordsTyped);
    }

    private void BuildUi(double wpm, double accuracy, int wordsTyped)
    {
        int score = Victory.CalculateScore(_finalState);
        string grade = Victory.GetGrade(score);

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
            Text = "VICTORY!",
            TextColor = ThemeColors.GoldAccent,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        root.Widgets.Add(new Label
        {
            Text = _nodeName,
            TextColor = ThemeColors.AccentCyan,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        root.Widgets.Add(new HorizontalSeparator());

        // Grade + Score
        var gradeRow = new HorizontalStackPanel
        {
            Spacing = DesignSystem.SpaceXl,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        gradeRow.Widgets.Add(new Label
        {
            Text = $"Grade: {grade}",
            TextColor = GetGradeColor(grade),
        });
        gradeRow.Widgets.Add(new Label
        {
            Text = $"Score: {score:N0}",
            TextColor = ThemeColors.Accent,
        });
        root.Widgets.Add(gradeRow);

        root.Widgets.Add(new HorizontalSeparator());

        // Battle Stats
        root.Widgets.Add(new Label
        {
            Text = "Battle Stats",
            TextColor = ThemeColors.AccentBlue,
        });

        var statsGrid = new Grid
        {
            ColumnSpacing = DesignSystem.SpaceMd,
            RowSpacing = DesignSystem.SpaceXs,
        };
        statsGrid.ColumnsProportions.Add(new Proportion(ProportionType.Pixels, 200));
        statsGrid.ColumnsProportions.Add(new Proportion(ProportionType.Fill));

        AddStatRow(statsGrid, 0, "WPM", $"{wpm:F1}");
        AddStatRow(statsGrid, 1, "Accuracy", $"{accuracy * 100:F1}%");
        AddStatRow(statsGrid, 2, "Words Typed", $"{wordsTyped}");
        AddStatRow(statsGrid, 3, "Enemies Defeated", $"{_finalState.EnemiesDefeated}");
        AddStatRow(statsGrid, 4, "Best Combo", $"{_finalState.MaxComboEver}");
        AddStatRow(statsGrid, 5, "Day Reached", $"{_finalState.Day}");
        AddStatRow(statsGrid, 6, "Gold", $"{_finalState.Gold}", ThemeColors.GoldAccent);

        root.Widgets.Add(statsGrid);

        // Milestones earned
        if (_newMilestones.Count > 0)
        {
            root.Widgets.Add(new HorizontalSeparator());
            root.Widgets.Add(new Label
            {
                Text = "New Milestones!",
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

        // Continue button
        var continueBtn = ButtonFactory.Primary("Continue", OnContinue);
        continueBtn.HorizontalAlignment = HorizontalAlignment.Center;
        root.Widgets.Add(continueBtn);

        root.Widgets.Add(new Label
        {
            Text = "Press Enter to continue",
            TextColor = ThemeColors.TextDim,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        _desktop = new Desktop { Root = root };
    }

    private void AddStatRow(Grid grid, int row, string label, string value, Color? valueColor = null)
    {
        grid.RowsProportions.Add(new Proportion(ProportionType.Auto));

        var labelWidget = new Label
        {
            Text = label,
            TextColor = ThemeColors.TextDim,
        };
        Grid.SetRow(labelWidget, row);
        Grid.SetColumn(labelWidget, 0);
        grid.Widgets.Add(labelWidget);

        var valueWidget = new Label
        {
            Text = value,
            TextColor = valueColor ?? ThemeColors.Text,
        };
        Grid.SetRow(valueWidget, row);
        Grid.SetColumn(valueWidget, 1);
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

    private void OnContinue()
    {
        ScreenManager.Pop();
    }

    public override void Update(GameTime gameTime)
    {
        var kb = Keyboard.GetState();
        if (kb.IsKeyDown(Keys.Enter) && !_prevKeyboard.IsKeyDown(Keys.Enter))
            OnContinue();
        _prevKeyboard = kb;
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        _desktop?.Render();
    }
}
