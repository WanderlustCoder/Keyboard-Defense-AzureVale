using System;
using System.IO;
using KeyboardDefense.Core.Data;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Myra.Graphics2D.UI;
using KeyboardDefense.Game.Effects;
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

    public MainMenuScreen(KeyboardDefenseGame game, ScreenManager screenManager)
        : base(game, screenManager) { }

    public override void OnEnter()
    {
        // Load Lyra portrait from Content/Textures/portraits/
        _portrait = AssetLoader.Instance.GetPortrait("lyra_v12_neutral");

        var rootPanel = new Panel();

        var vbox = new VerticalStackPanel
        {
            Spacing = DesignSystem.SpaceLg,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        // Title with accent styling
        var title = new Label
        {
            Text = Locale.Tr("menu.title"),
            TextColor = ThemeColors.Accent,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        vbox.Widgets.Add(title);

        // Subtitle
        var subtitle = new Label
        {
            Text = Locale.Tr("menu.subtitle"),
            TextColor = ThemeColors.AccentCyan,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        vbox.Widgets.Add(subtitle);

        // Spacer
        vbox.Widgets.Add(new Panel { Height = DesignSystem.SpaceMd });

        // Continue button (only if a save exists)
        if (GameController.HasAnySave())
        {
            var continueButton = CreateMenuButton(Locale.Tr("ui.continue"));
            continueButton.Click += (_, _) =>
            {
                if (GameController.Instance.LoadGame())
                {
                    SceneTransition.Instance.BattleTransition(() =>
                        ScreenManager.Push(new BattlefieldScreen(Game, ScreenManager, 0, "Loaded Game")));
                }
            };
            vbox.Widgets.Add(continueButton);
        }

        var campaignButton = CreateMenuButton(Locale.Tr("menu.campaign"));
        campaignButton.Click += (_, _) =>
        {
            SceneTransition.Instance.BattleTransition(() =>
                ScreenManager.Push(new CampaignMapScreen(Game, ScreenManager)));
        };
        vbox.Widgets.Add(campaignButton);

        var kingdomButton = CreateMenuButton(Locale.Tr("menu.kingdom_defense"));
        kingdomButton.Click += (_, _) =>
        {
            SceneTransition.Instance.BattleTransition(() =>
                ScreenManager.Push(new KingdomDefenseScreen(Game, ScreenManager)));
        };
        vbox.Widgets.Add(kingdomButton);

        var openWorldButton = CreateMenuButton(Locale.Tr("menu.open_world"));
        openWorldButton.Click += (_, _) =>
        {
            SceneTransition.Instance.BattleTransition(() =>
                ScreenManager.Push(new OpenWorldScreen(Game, ScreenManager)));
        };
        vbox.Widgets.Add(openWorldButton);

        var practiceButton = CreateMenuButton(Locale.Tr("menu.typing_practice"));
        practiceButton.Click += (_, _) =>
        {
            SceneTransition.Instance.BattleTransition(() =>
                ScreenManager.Push(new PracticeScreen(Game, ScreenManager)));
        };
        vbox.Widgets.Add(practiceButton);

        var endlessButton = CreateMenuButton("Endless Mode");
        endlessButton.Click += (_, _) =>
        {
            SceneTransition.Instance.BattleTransition(() =>
                ScreenManager.Push(new EndlessModeScreen(Game, ScreenManager)));
        };
        vbox.Widgets.Add(endlessButton);

        var profileButton = CreateMenuButton(Locale.Tr("menu.typing_profile"));
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

        var dailyChallengesButton = CreateMenuButton(Locale.Tr("panels.daily_challenges"));
        dailyChallengesButton.Click += (_, _) =>
        {
            _dailyChallengesPanel ??= new DailyChallengesPanel();
            if (_dailyChallengesPanel.Visible)
                _dailyChallengesPanel.Close();
            else
            {
                if (!rootPanel.Widgets.Contains(_dailyChallengesPanel.RootWidget))
                    rootPanel.Widgets.Add(_dailyChallengesPanel.RootWidget);
                // Refresh with current state if available, otherwise use default state
                var state = GameController.HasAnySave() ? GameController.Instance.State : new Core.State.GameState();
                _dailyChallengesPanel.Refresh(state);
                _dailyChallengesPanel.Open();
            }
        };
        vbox.Widgets.Add(dailyChallengesButton);

        var settingsButton = CreateMenuButton(Locale.Tr("ui.settings"));
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

        var quitButton = CreateMenuButton(Locale.Tr("ui.quit"));
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

        // Draw portrait on the left side if available
        if (_portrait != null)
        {
            spriteBatch.Begin(blendState: BlendState.AlphaBlend, samplerState: SamplerState.PointClamp);

            // Scale portrait to display at 3x (pixel art upscale)
            int scale = 3;
            int drawW = _portrait.Width * scale;
            int drawH = _portrait.Height * scale;
            int drawX = 60;
            int drawY = vp.Height / 2 - drawH / 2;

            // Subtle pulse
            float pulse = 1f + MathF.Sin(_totalTime * 1.5f) * 0.02f;
            drawW = (int)(drawW * pulse);
            drawH = (int)(drawH * pulse);

            spriteBatch.Draw(_portrait,
                new Rectangle(drawX, drawY, drawW, drawH),
                Color.White);

            // Portrait label
            var font = Game.DefaultFont;
            string name = "Lyra";
            var nameSize = font.MeasureString(name);
            spriteBatch.DrawString(font, name,
                new Vector2(drawX + (drawW - nameSize.X) * 0.5f, drawY + drawH + 8),
                ThemeColors.AccentCyan);

            spriteBatch.End();
        }

        // Draw Myra UI on top
        _desktop?.Render();

        // Draw transition overlay
        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }

    private static Button CreateMenuButton(string text)
    {
        return new Button
        {
            Content = new Label { Text = text, HorizontalAlignment = HorizontalAlignment.Center },
            Width = 300,
            Height = DesignSystem.SizeButtonLg,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
    }

    private static string LoadVersion()
    {
        // Try to read version from a version file
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

        return "v0.2.0 - MonoGame Port";
    }
}
