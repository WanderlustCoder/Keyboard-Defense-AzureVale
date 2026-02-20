using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Game.Screens;
using KeyboardDefense.Game.UI;
using KeyboardDefense.Game.UI.Components;
using KeyboardDefense.Game.Services;
using Myra;

namespace KeyboardDefense.Game;

/// <summary>
/// Main Game1 subclass - entry point for Keyboard Defense MonoGame.
/// </summary>
public class KeyboardDefenseGame : Microsoft.Xna.Framework.Game
{
    public const int ViewportWidth = 1920;
    public const int ViewportHeight = 1440;
    public const int WindowWidth = 1600;
    public const int WindowHeight = 1200;
    public const string GameTitle = "Keyboard Defense";

    private GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch = null!;
    private SpriteFont _defaultFont = null!;
    private ScreenManager _screenManager = null!;
    private SettingsManager _settingsManager = null!;
    private PerfOverlay _perfOverlay = null!;

    public static KeyboardDefenseGame Instance { get; private set; } = null!;

    public KeyboardDefenseGame()
    {
        Instance = this;
        _graphics = new GraphicsDeviceManager(this)
        {
            PreferredBackBufferWidth = WindowWidth,
            PreferredBackBufferHeight = WindowHeight,
            IsFullScreen = false,
            SynchronizeWithVerticalRetrace = true,
        };
        Content.RootDirectory = "Content";
        IsMouseVisible = true;
        Window.Title = GameTitle;
        Window.AllowUserResizing = true;
    }

    protected override void Initialize()
    {
        _settingsManager = new SettingsManager();
        _settingsManager.LoadSettings();
        KeybindManager.Instance.Load();

        // Load all JSON data files (buildings, lessons, factions, events, POIs, translations)
        DataLoader.LoadAll();

        // Apply saved language preference
        if (_settingsManager.Language != "en")
        {
            Locale.SetLocale(_settingsManager.Language);
            DataLoader.LoadTranslations(DataLoader.DataDirectory, _settingsManager.Language);
        }

        _screenManager = new ScreenManager(this);

        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);
        _defaultFont = Content.Load<SpriteFont>("Fonts/Default");

        // Initialize Myra UI
        MyraEnvironment.Game = this;

        // Initialize singleton renderers/effects that need GraphicsDevice
        Rendering.HitEffects.Instance.Initialize(GraphicsDevice);
        Effects.SceneTransition.Instance.Initialize(GraphicsDevice);
        KeyboardDefense.Game.Services.AssetLoader.Instance.Initialize(GraphicsDevice);

        // Load audio assets
        Audio.AudioLoader.LoadAll();

        // Initialize performance overlay (toggle with F3)
        _perfOverlay = new PerfOverlay(GraphicsDevice, _spriteBatch, _defaultFont);

        // Start with the main menu screen
        _screenManager.Switch(new MainMenuScreen(this, _screenManager));
    }

    protected override void Update(GameTime gameTime)
    {
        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed ||
            Keyboard.GetState().IsKeyDown(Keys.Escape))
        {
            if (_screenManager.CanPop)
                _screenManager.Pop();
        }

        _screenManager.Update(gameTime);
        Audio.AudioManager.Instance.Update(gameTime);
        _perfOverlay.Update(gameTime);

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(new Color(
            ThemeColors.BgDark.R,
            ThemeColors.BgDark.G,
            ThemeColors.BgDark.B));

        _screenManager.Draw(gameTime, _spriteBatch);
        _perfOverlay.Draw();

        base.Draw(gameTime);
    }

    public SpriteBatch SpriteBatch => _spriteBatch;
    public SpriteFont DefaultFont => _defaultFont;
    public ScreenManager ScreenManager => _screenManager;
    public SettingsManager SettingsManager => _settingsManager;
}
