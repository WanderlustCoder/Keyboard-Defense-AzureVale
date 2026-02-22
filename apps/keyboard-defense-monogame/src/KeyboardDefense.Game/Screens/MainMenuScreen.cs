using System;
using System.IO;
using KeyboardDefense.Core.Data;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Myra.Graphics2D.UI;
using KeyboardDefense.Game.Effects;
using KeyboardDefense.Game.Rendering;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;
using KeyboardDefense.Game.UI.Components;

namespace KeyboardDefense.Game.Screens;

/// <summary>
/// Main menu screen with styled title, character portrait, mode buttons,
/// settings panel, and version label.
/// </summary>
public class MainMenuScreen : GameScreen
{
    private Desktop? _desktop;
    private SettingsPanel? _settingsPanel;
    private TypingProfilePanel? _profilePanel;
    private DailyChallengesPanel? _dailyChallengesPanel;
    private Texture2D? _portrait;
    private float _totalTime;
    private readonly HudPainter _painter = new();
    private readonly NineSliceFrame _frame = new();

    public MainMenuScreen(KeyboardDefenseGame game, ScreenManager screenManager)
        : base(game, screenManager) { }

    public override void OnEnter()
    {
        // Load Lyra portrait from Content/Textures/portraits/
        _portrait = AssetLoader.Instance.GetPortrait("lyra_v12_neutral");

        if (Game.DefaultFont != null)
        {
            _painter.Initialize(Game.GraphicsDevice, Game.DefaultFont);
            _frame.Initialize(Game.GraphicsDevice, Game.DefaultFont);
            _frame.LoadFrameTextures(AssetLoader.Instance);
        }

        var rootPanel = new Panel();

        var vbox = new VerticalStackPanel
        {
            Spacing = DesignSystem.SpaceLg,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        // Title + subtitle are drawn in SpriteBatch — add invisible spacer
        vbox.Widgets.Add(new Panel { Height = 80 });

        // Continue button (only if a save exists)
        if (GameController.HasAnySave())
        {
            var continueButton = ButtonFactory.Primary(Locale.Tr("ui.continue"));
            continueButton.Width = 280;
            continueButton.Height = DesignSystem.SizeButtonLg;
            continueButton.Click += (_, _) =>
            {
                if (GameController.Instance.LoadGame())
                {
                    SceneTransition.Instance.BattleTransition(() =>
                        ScreenManager.Push(new WorldScreen(Game, ScreenManager)));
                }
            };
            vbox.Widgets.Add(continueButton);
        }

        // Play button — launches WorldScreen (open-world mode)
        var playButton = ButtonFactory.Primary("Play");
        playButton.Width = 280;
        playButton.Height = DesignSystem.SizeButtonLg;
        playButton.Click += (_, _) =>
        {
            SceneTransition.Instance.BattleTransition(() =>
            {
                GameController.Instance.NewGame($"world_{DateTime.UtcNow.Ticks}");
                ScreenManager.Push(new WorldScreen(Game, ScreenManager));
            });
        };
        vbox.Widgets.Add(playButton);

        var verticalSliceButton = ButtonFactory.Primary("Start Vertical Slice");
        verticalSliceButton.Width = 280;
        verticalSliceButton.Height = DesignSystem.SizeButtonLg;
        verticalSliceButton.Click += (_, _) =>
        {
            SceneTransition.Instance.BattleTransition(() =>
            {
                GameController.Instance.NewGame($"vertical_slice_{DateTime.UtcNow.Ticks}");
                ScreenManager.Push(new BattlefieldScreen(
                    Game,
                    ScreenManager,
                    nodeIndex: 0,
                    nodeName: "Vertical Slice",
                    singleWaveMode: true));
            });
        };
        vbox.Widgets.Add(verticalSliceButton);
        var verticalSliceProfile = VerticalSliceProfileService.Current;
        vbox.Widgets.Add(new Label
        {
            Text =
                $"Slice Runs: {verticalSliceProfile.RunsPlayed}  " +
                $"Last Score: {verticalSliceProfile.LastScore}  " +
                $"Best: {verticalSliceProfile.BestScore}",
            TextColor = ThemeColors.TextDim,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        // Divider
        vbox.Widgets.Add(new HorizontalSeparator());

        var practiceButton = ButtonFactory.Secondary(Locale.Tr("menu.typing_practice"));
        practiceButton.Width = 280;
        practiceButton.Height = DesignSystem.SizeButtonLg;
        practiceButton.Click += (_, _) =>
        {
            SceneTransition.Instance.BattleTransition(() =>
                ScreenManager.Push(new PracticeScreen(Game, ScreenManager)));
        };
        vbox.Widgets.Add(practiceButton);

        var endlessButton = ButtonFactory.Secondary("Endless Mode");
        endlessButton.Width = 280;
        endlessButton.Height = DesignSystem.SizeButtonLg;
        endlessButton.Click += (_, _) =>
        {
            SceneTransition.Instance.BattleTransition(() =>
                ScreenManager.Push(new EndlessModeScreen(Game, ScreenManager)));
        };
        vbox.Widgets.Add(endlessButton);

        // Divider
        vbox.Widgets.Add(new HorizontalSeparator());

        var profileButton = ButtonFactory.Ghost(Locale.Tr("menu.typing_profile"));
        profileButton.Width = 280;
        profileButton.Height = DesignSystem.SizeButtonLg;
        profileButton.Click += (_, _) =>
        {
            _profilePanel ??= new TypingProfilePanel();
            _profilePanel.Refresh();
            if (_profilePanel.Visible)
                _profilePanel.Close();
            else
            {
                if (!rootPanel.Widgets.Contains(_profilePanel.RootWidget))
                    rootPanel.Widgets.Add(_profilePanel.RootWidget);
                _profilePanel.Open();
            }
        };
        vbox.Widgets.Add(profileButton);

        var dailyChallengesButton = ButtonFactory.Ghost(Locale.Tr("panels.daily_challenges"));
        dailyChallengesButton.Width = 280;
        dailyChallengesButton.Height = DesignSystem.SizeButtonLg;
        dailyChallengesButton.Click += (_, _) =>
        {
            _dailyChallengesPanel ??= new DailyChallengesPanel();
            if (_dailyChallengesPanel.Visible)
                _dailyChallengesPanel.Close();
            else
            {
                if (!rootPanel.Widgets.Contains(_dailyChallengesPanel.RootWidget))
                    rootPanel.Widgets.Add(_dailyChallengesPanel.RootWidget);
                var state = GameController.HasAnySave() ? GameController.Instance.State : new Core.State.GameState();
                _dailyChallengesPanel.Refresh(state);
                _dailyChallengesPanel.Open();
            }
        };
        vbox.Widgets.Add(dailyChallengesButton);

        var settingsButton = ButtonFactory.Ghost(Locale.Tr("ui.settings"));
        settingsButton.Width = 280;
        settingsButton.Height = DesignSystem.SizeButtonLg;
        settingsButton.Click += (_, _) =>
        {
            _settingsPanel ??= new SettingsPanel();
            if (_settingsPanel.Visible)
                _settingsPanel.Close();
            else
            {
                if (!rootPanel.Widgets.Contains(_settingsPanel.RootWidget))
                    rootPanel.Widgets.Add(_settingsPanel.RootWidget);
                _settingsPanel.Open();
            }
        };
        vbox.Widgets.Add(settingsButton);

        var quitButton = ButtonFactory.Danger(Locale.Tr("ui.quit"));
        quitButton.Width = 280;
        quitButton.Height = DesignSystem.SizeButtonLg;
        quitButton.Click += (_, _) => Game.Exit();
        vbox.Widgets.Add(quitButton);

        // Version label
        string version = LoadVersion();
        var versionLabel = new Label
        {
            Text = version,
            TextColor = ThemeColors.TextDisabled,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        vbox.Widgets.Add(new Panel { Height = DesignSystem.SpaceMd });
        vbox.Widgets.Add(versionLabel);

        rootPanel.Widgets.Add(vbox);

        _desktop = new Desktop();
        _desktop.Root = rootPanel;
    }

    public override void OnExit()
    {
        _desktop = null;
    }

    public override void Update(GameTime gameTime)
    {
        _totalTime += (float)gameTime.ElapsedGameTime.TotalSeconds;
        SceneTransition.Instance.Update(gameTime);
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        var vp = Game.GraphicsDevice.Viewport;

        spriteBatch.Begin(blendState: BlendState.AlphaBlend, samplerState: SamplerState.PointClamp);

        // Full-screen vertical gradient background
        if (_painter.IsReady)
        {
            var bgBottom = new Color(16, 14, 25);
            _painter.DrawGradientV(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height),
                ThemeColors.BgDark, bgBottom, 16);

            // Decorative horizontal accent line at ~40% screen height
            int lineY = (int)(vp.Height * 0.4f);
            _painter.DrawRect(spriteBatch, new Rectangle(0, lineY, vp.Width, 1),
                ThemeColors.Border * 0.3f);

            // Vignette — darkened edges for depth
            int vigSize = 80;
            _painter.DrawGradientV(spriteBatch, new Rectangle(0, 0, vp.Width, vigSize),
                Color.Black * 0.3f, Color.Transparent, 4);
            _painter.DrawGradientV(spriteBatch, new Rectangle(0, vp.Height - vigSize, vp.Width, vigSize),
                Color.Transparent, Color.Black * 0.3f, 4);
        }

        // Draw portrait on the left side if available
        if (_portrait != null)
        {
            int scale = 3;
            int drawW = _portrait.Width * scale;
            int drawH = _portrait.Height * scale;
            int drawX = 60;
            int drawY = vp.Height / 2 - drawH / 2;

            float pulse = 1f + MathF.Sin(_totalTime * 1.5f) * 0.02f;
            drawW = (int)(drawW * pulse);
            drawH = (int)(drawH * pulse);

            // Portrait frame
            if (_frame.IsReady)
            {
                var frameRect = new Rectangle(drawX - 6, drawY - 6, drawW + 12, drawH + 12);
                _frame.DrawFrame(spriteBatch, frameRect, FrameStyles.Gold);
            }

            spriteBatch.Draw(_portrait,
                new Rectangle(drawX, drawY, drawW, drawH),
                Color.White);

            // Nameplate below portrait
            var font = Game.DefaultFont;
            if (font != null && _painter.IsReady)
            {
                string name = "Lyra";
                var nameSize = font.MeasureString(name);
                float nameX = drawX + (drawW - nameSize.X * 0.5f) * 0.5f;
                float nameY = drawY + drawH + 8;

                // Small gradient bar behind name
                int barW = drawW;
                _painter.DrawGradientV(spriteBatch,
                    new Rectangle(drawX, (int)nameY - 2, barW, (int)(nameSize.Y * 0.5f) + 4),
                    ThemeColors.BgPanel, Color.Transparent, 4);

                _painter.DrawTextShadowed(spriteBatch, new Vector2(nameX, nameY), name, ThemeColors.AccentCyan, 0.5f);
            }
        }

        // SpriteBatch title + subtitle
        if (_painter.IsReady)
        {
            var font = Game.DefaultFont!;
            string titleText = Locale.Tr("menu.title");
            string subtitleText = Locale.Tr("menu.subtitle");

            var titleSize = font.MeasureString(titleText) * 0.9f;
            float titleX = vp.Width / 2f - titleSize.X / 2f;
            float titleY = vp.Height * 0.08f;

            _painter.DrawTextGlow(spriteBatch, new Vector2(titleX, titleY), titleText,
                ThemeColors.GoldAccent, ThemeColors.Glow, 0.9f);

            var subtitleSize = font.MeasureString(subtitleText) * 0.5f;
            float subX = vp.Width / 2f - subtitleSize.X / 2f;
            float subY = titleY + titleSize.Y + 4;

            _painter.DrawTextShadowed(spriteBatch, new Vector2(subX, subY), subtitleText,
                ThemeColors.AccentCyan, 0.5f);
        }

        spriteBatch.End();

        // Draw Myra UI on top
        _desktop?.Render();

        // Draw transition overlay
        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }

    private static string LoadVersion()
    {
        string[] candidates = new[]
        {
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "version.txt"),
            Path.Combine(Directory.GetCurrentDirectory(), "version.txt"),
        };

        foreach (string path in candidates)
        {
            if (File.Exists(path))
            {
                try { return File.ReadAllText(path).Trim(); }
                catch { /* Fall through */ }
            }
        }

        return "v0.3.0 - Open World";
    }
}
