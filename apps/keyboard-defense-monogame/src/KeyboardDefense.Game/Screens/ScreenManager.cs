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

    public GameScreen? ActiveScreen => _screens.Count > 0 ? _screens.Peek() : null;
    public bool CanPop => _screens.Count > 1;

    public ScreenManager(KeyboardDefenseGame game)
    {
        _game = game;
    }

    public void Push(GameScreen screen)
    {
        ActiveScreen?.OnPause();
        _screens.Push(screen);
        screen.OnEnter();
    }

    public void Pop()
    {
        if (_screens.Count == 0) return;
        var old = _screens.Pop();
        old.OnExit();
        ActiveScreen?.OnResume();
    }

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

    public void Update(GameTime gameTime)
    {
        ActiveScreen?.Update(gameTime);
    }

    public void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        ActiveScreen?.Draw(gameTime, spriteBatch);
    }
}
