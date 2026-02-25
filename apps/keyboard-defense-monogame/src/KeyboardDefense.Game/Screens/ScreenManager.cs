using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace KeyboardDefense.Game.Screens;

/// <summary>
/// Manages a stack of game screens with push/pop/switch transitions.
/// </summary>
public class ScreenManager
{
    private readonly Stack<GameScreen> _screens = new();
    private readonly KeyboardDefenseGame _game;

    /// <summary>
    /// Gets the currently active screen at the top of the stack.
    /// </summary>
    /// <value>
    /// The top-most <see cref="GameScreen"/> instance, or <see langword="null"/> when no screens are present.
    /// </value>
    public GameScreen? ActiveScreen => _screens.Count > 0 ? _screens.Peek() : null;
    /// <summary>
    /// Gets a value indicating whether popping is allowed without emptying the stack.
    /// </summary>
    /// <value>
    /// <see langword="true"/> when more than one screen is in the stack; otherwise, <see langword="false"/>.
    /// </value>
    public bool CanPop => _screens.Count > 1;

    /// <summary>
    /// Initializes a new instance of the <see cref="ScreenManager"/> class.
    /// </summary>
    /// <param name="game">The owning game instance that hosts this manager.</param>
    public ScreenManager(KeyboardDefenseGame game)
    {
        _game = game;
    }

    /// <summary>
    /// Pushes a new screen onto the stack and activates it.
    /// </summary>
    /// <param name="screen">The screen to add and enter.</param>
    /// <remarks>
    /// The current active screen is paused before the new screen is pushed, then <see cref="GameScreen.OnEnter"/> is called on the new screen.
    /// </remarks>
    public void Push(GameScreen screen)
    {
        ActiveScreen?.OnPause();
        _screens.Push(screen);
        screen.OnEnter();
    }

    /// <summary>
    /// Removes the active screen from the stack.
    /// </summary>
    /// <remarks>
    /// If a screen is removed, <see cref="GameScreen.OnExit"/> is called on it and the new active screen is resumed.
    /// If the stack is already empty, this method does nothing.
    /// </remarks>
    public void Pop()
    {
        if (_screens.Count == 0) return;
        var old = _screens.Pop();
        old.OnExit();
        ActiveScreen?.OnResume();
    }

    /// <summary>
    /// Replaces the current screen stack with a single new screen.
    /// </summary>
    /// <param name="screen">The screen to activate after clearing existing screens.</param>
    /// <remarks>
    /// Every existing screen is exited in top-down order before the new screen is pushed and entered.
    /// </remarks>
    public void Switch(GameScreen screen)
    {
        while (_screens.Count > 0)
        {
            var old = _screens.Pop();
            old.OnExit();
        }
        _screens.Push(screen);
        screen.OnEnter();
    }

    /// <summary>
    /// Updates the active screen for the current frame.
    /// </summary>
    /// <param name="gameTime">Timing values for the current update tick.</param>
    public void Update(GameTime gameTime)
    {
        ActiveScreen?.Update(gameTime);
    }

    /// <summary>
    /// Draws the active screen for the current frame.
    /// </summary>
    /// <param name="gameTime">Timing values for the current draw tick.</param>
    /// <param name="spriteBatch">The sprite batch used for rendering.</param>
    public void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        ActiveScreen?.Draw(gameTime, spriteBatch);
    }
}
