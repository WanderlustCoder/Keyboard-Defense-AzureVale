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
/// Defeat screen shown when the player loses a battle.
/// Displays survival stats, retry option, and return to main menu.
/// </summary>
public class DefeatScreen : GameScreen
{
    private readonly int _nodeIndex;
    private readonly string _nodeName;
    private readonly GameState _finalState;
    private readonly List<string> _newMilestones;
    private Desktop? _desktop;
    private KeyboardState _prevKeyboard;
    private readonly HudPainter _painter = new();
    private readonly NineSliceFrame _frame = new();

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
        if (Game.DefaultFont != null)
        {
            _painter.Initialize(Game.GraphicsDevice, Game.DefaultFont);
            _frame.Initialize(Game.GraphicsDevice, Game.DefaultFont);
            _frame.LoadFrameTextures(AssetLoader.Instance);
        }

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

        var mapBtn = ButtonFactory.Secondary("Main Menu", OnReturnToMap);
        buttonRow.Widgets.Add(mapBtn);

        root.Widgets.Add(buttonRow);

        root.Widgets.Add(new Label
        {
            Text = "Press Enter to retry, Escape for main menu",
            TextColor = ThemeColors.TextDim,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        rootPanel.Widgets.Add(root);
        _desktop = new Desktop { Root = rootPanel };
    }

    private void AddStatRow(Grid grid, int row, string label, string value)
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
            TextColor = ThemeColors.Text,
        };
        Grid.SetRow(valueWidget, row);
        Grid.SetColumn(valueWidget, 1);
        grid.Widgets.Add(valueWidget);
    }

    private void OnRetry()
    {
        ScreenManager.Pop(); // Pop defeat screen
        ScreenManager.Pop(); // Pop old battlefield
        var battle = new BattlefieldScreen(Game, ScreenManager, _nodeIndex, _nodeName);
        ScreenManager.Push(battle);
    }

    private void OnReturnToMap()
    {
        ScreenManager.Pop();
        ScreenManager.Pop();
    }

    public override void Update(GameTime gameTime)
    {
        var kb = Keyboard.GetState();

        if (kb.IsKeyDown(Keys.Enter) && !_prevKeyboard.IsKeyDown(Keys.Enter))
            OnRetry();
        else if (kb.IsKeyDown(Keys.Escape) && !_prevKeyboard.IsKeyDown(Keys.Escape))
            OnReturnToMap();

        _prevKeyboard = kb;
        SceneTransition.Instance.Update(gameTime);
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        var vp = Game.GraphicsDevice.Viewport;

        spriteBatch.Begin(blendState: BlendState.AlphaBlend, samplerState: SamplerState.PointClamp);

        if (_painter.IsReady)
        {
            // Dark gradient background with reddish tint
            _painter.DrawGradientV(spriteBatch,
                new Rectangle(0, 0, vp.Width, vp.Height),
                ThemeColors.BgDark, new Color(25, 10, 10), 16);

            // Combat frame around center content
            int frameW = 520;
            int frameH = vp.Height - 80;
            int frameX = (vp.Width - frameW) / 2;
            int frameY = 40;
            if (_frame.IsReady)
                _frame.DrawFrame(spriteBatch, new Rectangle(frameX, frameY, frameW, frameH), FrameStyles.Combat);

            // "DEFEATED" red glow title
            string titleText = "DEFEATED";
            var titleSize = _painter.Font!.MeasureString(titleText) * 0.9f;
            float titleX = vp.Width / 2f - titleSize.X / 2f;
            float titleY = frameY + 16;
            _painter.DrawTextGlow(spriteBatch, new Vector2(titleX, titleY),
                titleText, ThemeColors.DamageRed, ThemeColors.DamageRed, 0.9f);
        }

        spriteBatch.End();

        _desktop?.Render();

        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }
}
