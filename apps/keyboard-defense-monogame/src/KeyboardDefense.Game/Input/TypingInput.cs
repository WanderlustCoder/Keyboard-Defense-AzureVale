using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace KeyboardDefense.Game.Input;

/// <summary>
/// MonoGame keyboard input handler for typing.
/// Captures typed characters via Window.TextInput event.
/// Ported from scripts/TypingSystem.gd (113 lines) + MonoGame input layer.
/// </summary>
public class TypingInput
{
    private readonly Queue<char> _charBuffer = new();
    private readonly Queue<TypingAction> _actionBuffer = new();
    private bool _attached;

    public enum TypingAction { None, Backspace, Enter, Escape, Tab }

    public event Action<char>? CharTyped;
    public event Action<TypingAction>? ActionPressed;

    public void Attach(GameWindow window)
    {
        if (_attached) return;
        window.TextInput += OnTextInput;
        _attached = true;
    }

    public void Detach(GameWindow window)
    {
        if (!_attached) return;
        window.TextInput -= OnTextInput;
        _attached = false;
    }

    private void OnTextInput(object? sender, TextInputEventArgs e)
    {
        char c = e.Character;

        if (c == '\b')
        {
            _actionBuffer.Enqueue(TypingAction.Backspace);
        }
        else if (c == '\r' || c == '\n')
        {
            _actionBuffer.Enqueue(TypingAction.Enter);
        }
        else if (c == 27) // Escape
        {
            _actionBuffer.Enqueue(TypingAction.Escape);
        }
        else if (c == '\t')
        {
            _actionBuffer.Enqueue(TypingAction.Tab);
        }
        else if (!char.IsControl(c))
        {
            _charBuffer.Enqueue(c);
        }
    }

    /// <summary>
    /// Process buffered input. Call once per Update cycle.
    /// Returns typed characters and actions for this frame.
    /// </summary>
    public void ProcessInput()
    {
        while (_charBuffer.Count > 0)
        {
            CharTyped?.Invoke(_charBuffer.Dequeue());
        }
        while (_actionBuffer.Count > 0)
        {
            ActionPressed?.Invoke(_actionBuffer.Dequeue());
        }
    }

    /// <summary>
    /// Drain all chars as a string (for command bar input).
    /// </summary>
    public string DrainChars()
    {
        if (_charBuffer.Count == 0) return "";
        var chars = new char[_charBuffer.Count];
        for (int i = 0; i < chars.Length; i++)
            chars[i] = _charBuffer.Dequeue();
        return new string(chars);
    }

    /// <summary>
    /// Drain all pending actions.
    /// </summary>
    public List<TypingAction> DrainActions()
    {
        var actions = new List<TypingAction>(_actionBuffer.Count);
        while (_actionBuffer.Count > 0)
            actions.Add(_actionBuffer.Dequeue());
        return actions;
    }

    public void ClearBuffers()
    {
        _charBuffer.Clear();
        _actionBuffer.Clear();
    }
}
