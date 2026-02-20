using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Game.Effects;
using KeyboardDefense.Game.Input;
using KeyboardDefense.Game.Rendering;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;
using KeyboardDefense.Game.UI.Components;

namespace KeyboardDefense.Game.Screens;

/// <summary>
/// Dedicated screen for typing practice with structured lessons, progressive difficulty,
/// keyboard overlay with finger zone highlighting, and per-lesson results.
/// </summary>
public class PracticeScreen : GameScreen
{
    private Desktop? _desktop;
    private LessonPracticePanel? _practicePanel;
    private readonly KeyboardOverlay _keyboardDisplay = new();
    private TypingInput? _typingHandler;
    private KeyboardState _prevKeyboard;

    // Finger zone highlighting state
    private HashSet<char> _highlightedChars = new();

    public PracticeScreen(KeyboardDefenseGame game, ScreenManager screenManager)
        : base(game, screenManager) { }

    public override void OnEnter()
    {
        // Load lesson progress on entry
        LessonProgress.Instance.Load(SaveService.GetSavesDir());

        _keyboardDisplay.Initialize(Game.GraphicsDevice, Game.DefaultFont);

        _practicePanel = new LessonPracticePanel();

        // Wire up lesson lifecycle events for keyboard overlay
        _practicePanel.LessonStarted += OnLessonStarted;
        _practicePanel.LessonStopped += OnLessonStopped;

        var rootPanel = new Panel();

        // Back button in top-left corner
        var topBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        var backBtn = ButtonFactory.Ghost("< Back to Menu", () => ScreenManager.Pop());
        backBtn.Width = 140;
        backBtn.Height = DesignSystem.SizeButtonSm;
        topBar.Widgets.Add(backBtn);
        topBar.VerticalAlignment = VerticalAlignment.Top;
        topBar.HorizontalAlignment = HorizontalAlignment.Left;
        rootPanel.Widgets.Add(topBar);

        // Center the practice panel
        _practicePanel.RootWidget.HorizontalAlignment = HorizontalAlignment.Center;
        _practicePanel.RootWidget.VerticalAlignment = VerticalAlignment.Center;
        _practicePanel.RootWidget.Visible = true;
        rootPanel.Widgets.Add(_practicePanel.RootWidget);

        _desktop = new Desktop { Root = rootPanel };

        // Set up typing input for keyboard display
        _typingHandler = new TypingInput();
        _typingHandler.Attach(Game.Window);
        _typingHandler.CharTyped += c => _keyboardDisplay.FlashKey(c);
    }

    public override void OnExit()
    {
        if (_typingHandler != null)
        {
            _typingHandler.Detach(Game.Window);
        }
        if (_practicePanel != null)
        {
            _practicePanel.LessonStarted -= OnLessonStarted;
            _practicePanel.LessonStopped -= OnLessonStopped;
        }
        _desktop = null;
        _practicePanel = null;
        _highlightedChars.Clear();
    }

    public override void Update(GameTime gameTime)
    {
        _typingHandler?.ProcessInput();
        _keyboardDisplay.Update(gameTime);

        var kbState = Keyboard.GetState();
        if (kbState.IsKeyDown(Keys.Escape) && !_prevKeyboard.IsKeyDown(Keys.Escape))
        {
            ScreenManager.Pop();
        }
        _prevKeyboard = kbState;

        // Update keyboard display with expected key from practice
        if (_practicePanel != null && _practicePanel.IsPracticing)
        {
            string prompt = _practicePanel.CurrentPrompt;
            if (!string.IsNullOrEmpty(prompt))
                _keyboardDisplay.SetExpectedChar(prompt[0]);
        }

        SceneTransition.Instance.Update(gameTime);
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        var vp = Game.GraphicsDevice.Viewport;

        // Draw keyboard display at bottom with finger zone highlighting
        int kbHeight = _keyboardDisplay.TotalHeight;
        float kbY = vp.Height - kbHeight - 20;
        _keyboardDisplay.Draw(spriteBatch, new Vector2(vp.Width * 0.5f - 220, kbY));

        // Draw Myra UI
        _desktop?.Render();

        // Scene transition (manages its own Begin/End)
        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }

    private void OnLessonStarted(LessonEntry lesson)
    {
        _highlightedChars.Clear();
        foreach (string c in lesson.Charset)
        {
            if (c.Length == 1)
                _highlightedChars.Add(char.ToLower(c[0]));
        }
        _keyboardDisplay.SetHighlightedChars(_highlightedChars);
    }

    private void OnLessonStopped()
    {
        _highlightedChars.Clear();
        _keyboardDisplay.ClearHighlightedChars();
    }
}
