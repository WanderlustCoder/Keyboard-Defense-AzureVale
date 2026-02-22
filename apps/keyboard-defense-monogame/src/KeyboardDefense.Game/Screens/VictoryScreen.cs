using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Game.Effects;
using KeyboardDefense.Game.Rendering;
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
    private readonly HudPainter _painter = new();
    private readonly NineSliceFrame _frame = new();
    private string _grade = "";

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
        if (Game.DefaultFont != null)
        {
            _painter.Initialize(Game.GraphicsDevice, Game.DefaultFont);
            _frame.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        }

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
        _grade = Victory.GetGrade(score);

        var rootPanel = new Panel();
        var root = new VerticalStackPanel
        {
            Spacing = DesignSystem.SpaceLg,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Width = 500,
        };

        // Title spacer (drawn via SpriteBatch)
        root.Widgets.Add(new Panel { Height = 60 });

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
            Text = $"Grade: {_grade}",
            TextColor = GetGradeColor(_grade),
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

        rootPanel.Widgets.Add(root);
        _desktop = new Desktop { Root = rootPanel };
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
        SceneTransition.Instance.Update(gameTime);
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        var vp = Game.GraphicsDevice.Viewport;

        spriteBatch.Begin(blendState: BlendState.AlphaBlend, samplerState: SamplerState.PointClamp);

        if (_painter.IsReady)
        {
            // Gradient background
            _painter.DrawGradientV(spriteBatch,
                new Rectangle(0, 0, vp.Width, vp.Height),
                ThemeColors.BgDark, new Color(16, 14, 25), 16);

            // Gold frame around center content
            int frameW = 520;
            int frameH = vp.Height - 80;
            int frameX = (vp.Width - frameW) / 2;
            int frameY = 40;
            if (_frame.IsReady)
                _frame.DrawFrame(spriteBatch, new Rectangle(frameX, frameY, frameW, frameH), FrameStyles.Gold);

            // "VICTORY!" glow title
            string titleText = "VICTORY!";
            var titleSize = _painter.Font!.MeasureString(titleText) * 0.9f;
            float titleX = vp.Width / 2f - titleSize.X / 2f;
            float titleY = frameY + 16;
            _painter.DrawTextGlow(spriteBatch, new Vector2(titleX, titleY),
                titleText, ThemeColors.GoldAccent, ThemeColors.GoldAccent, 0.9f);

            // Grade glow for S/A ranks
            if (_grade is "S" or "A")
            {
                string gradeText = _grade;
                var gradeSize = _painter.Font.MeasureString(gradeText) * 0.8f;
                float gradeX = vp.Width / 2f - gradeSize.X / 2f;
                float gradeY = titleY + titleSize.Y + 8;
                _painter.DrawTextGlow(spriteBatch, new Vector2(gradeX, gradeY),
                    gradeText, GetGradeColor(_grade), GetGradeColor(_grade), 0.8f);
            }
        }

        spriteBatch.End();

        _desktop?.Render();

        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }
}
