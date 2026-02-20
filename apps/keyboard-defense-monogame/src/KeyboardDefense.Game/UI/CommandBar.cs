using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI;

/// <summary>
/// Command input bar with history, autocomplete, and error feedback.
/// Ported from ui/command_bar.gd (353 lines).
/// </summary>
public class CommandBar
{
    private static readonly string[] KnownCommands =
    {
        "help", "status", "gather", "build", "explore", "end", "defend",
        "wait", "save", "load", "restart", "new", "cursor", "inspect",
        "map", "enemies", "lesson", "demolish", "upgrade", "buy",
        "research", "trade", "hero", "locale", "titles", "badges",
        "loot", "expeditions", "harvest", "nodes", "interact", "skip",
    };

    private readonly TextBox _input;
    private readonly Label _historyLabel;
    private readonly List<string> _history = new();
    private int _historyIndex = -1;
    private bool _errorFlashing;
    private float _errorTimer;

    public event Action<string>? CommandSubmitted;
    public event Action<string>? InputChanged;

    public Panel RootWidget { get; }

    public CommandBar()
    {
        RootWidget = new Panel
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Height = 80,
            VerticalAlignment = VerticalAlignment.Bottom,
        };

        var layout = new VerticalStackPanel();

        _historyLabel = new Label
        {
            Text = "",
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Wrap = true,
        };
        layout.Widgets.Add(_historyLabel);

        var inputRow = new HorizontalStackPanel { Spacing = DesignSystem.SpacingSm };

        var prompt = new Label { Text = "> " };
        inputRow.Widgets.Add(prompt);

        _input = new TextBox
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        inputRow.Widgets.Add(_input);

        layout.Widgets.Add(inputRow);
        RootWidget.Widgets.Add(layout);
    }

    public string Text
    {
        get => _input.Text ?? "";
        set => _input.Text = value;
    }

    public void Focus()
    {
        // Myra doesn't have direct Focus() but we can try
    }

    public void Submit()
    {
        string text = Text.Trim();
        if (string.IsNullOrEmpty(text)) return;

        _history.Insert(0, text);
        if (_history.Count > 50) _history.RemoveAt(_history.Count - 1);
        _historyIndex = -1;

        Text = "";
        CommandSubmitted?.Invoke(text);
    }

    public void ShowHistory(string entry)
    {
        _historyLabel.Text = entry;
    }

    public void ShowError()
    {
        _errorFlashing = true;
        _errorTimer = 0.3f;
    }

    public void HistoryUp()
    {
        if (_history.Count == 0) return;
        _historyIndex = Math.Min(_historyIndex + 1, _history.Count - 1);
        Text = _history[_historyIndex];
    }

    public void HistoryDown()
    {
        if (_historyIndex <= 0)
        {
            _historyIndex = -1;
            Text = "";
            return;
        }
        _historyIndex--;
        Text = _history[_historyIndex];
    }

    public void Update(GameTime gameTime)
    {
        if (_errorFlashing)
        {
            _errorTimer -= (float)gameTime.ElapsedGameTime.TotalSeconds;
            if (_errorTimer <= 0)
                _errorFlashing = false;
        }
    }

    /// <summary>
    /// Try to autocomplete the current input.
    /// </summary>
    public void Autocomplete()
    {
        string text = Text.ToLowerInvariant().Trim();
        if (string.IsNullOrEmpty(text)) return;

        foreach (string cmd in KnownCommands)
        {
            if (cmd.StartsWith(text) && cmd != text)
            {
                Text = cmd;
                return;
            }
        }
    }
}
