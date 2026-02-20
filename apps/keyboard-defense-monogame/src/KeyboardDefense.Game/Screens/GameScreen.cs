using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace KeyboardDefense.Game.Screens;

/// <summary>
/// Base class for all game screens (main menu, battlefield, campaign map, etc).
/// </summary>
public abstract class GameScreen
{
    protected KeyboardDefenseGame Game { get; }
    protected ScreenManager ScreenManager { get; }

    protected GameScreen(KeyboardDefenseGame game, ScreenManager screenManager)
    {
        Game = game;
        ScreenManager = screenManager;
    }

    public virtual void OnEnter() { }
    public virtual void OnExit() { }
    public virtual void OnPause() { }
    public virtual void OnResume() { }
    public abstract void Update(GameTime gameTime);
    public abstract void Draw(GameTime gameTime, SpriteBatch spriteBatch);
}
