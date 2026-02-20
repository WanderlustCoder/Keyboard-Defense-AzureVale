using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Battle tutorial overlay that guides new players through their first combat.
/// Ported from scripts/BattleTutorial.gd.
/// Shows Elder Lyra dialogue with trigger-based step progression.
/// </summary>
public class BattleTutorial
{
    private int _currentStep;
    private bool _waitingForTrigger;
    private bool _finished;
    private bool _skipped;
    private readonly HashSet<string> _firedTriggers = new();

    // Dialogue state
    private bool _dialogueVisible;
    private string _speaker = "";
    private string _line1 = "";
    private string _line2 = "";
    private float _displayTimer;
    private bool _showingLine2;

    // Progress dots
    private int TotalSteps => TutorialData.BattleSteps.Count;

    public bool IsActive => !_finished && !_skipped;
    public bool IsFinished => _finished;

    public event Action? TutorialFinished;

    public BattleTutorial()
    {
        _currentStep = 0;
    }

    /// <summary>
    /// Start the tutorial (called when entering first battle).
    /// </summary>
    public void Start()
    {
        if (ProgressionState.Instance.CompletedAchievements.Contains("battle_tutorial_done"))
        {
            _finished = true;
            return;
        }

        _currentStep = 0;
        _finished = false;
        _skipped = false;
        ShowCurrentStep();
    }

    /// <summary>
    /// Fire a tutorial trigger (e.g., when player types first word).
    /// </summary>
    public void FireTrigger(string trigger)
    {
        if (_finished || _skipped) return;
        _firedTriggers.Add(trigger);

        if (_waitingForTrigger)
        {
            var step = TutorialData.BattleSteps[_currentStep];
            if (step.Trigger != null && _firedTriggers.Contains(step.Trigger))
            {
                _waitingForTrigger = false;
                AdvanceStep();
            }
        }
    }

    /// <summary>
    /// Skip the tutorial entirely.
    /// </summary>
    public void Skip()
    {
        _skipped = true;
        _dialogueVisible = false;
        MarkComplete();
    }

    /// <summary>
    /// Advance dialogue (called on Enter/Space press during tutorial).
    /// </summary>
    public void AdvanceDialogue()
    {
        if (!_dialogueVisible) return;

        if (!_showingLine2 && !string.IsNullOrEmpty(_line2))
        {
            _showingLine2 = true;
            return;
        }

        // Done showing both lines
        var step = TutorialData.BattleSteps[_currentStep];
        if (step.Trigger != null)
        {
            // Wait for trigger before advancing
            _dialogueVisible = false;
            _waitingForTrigger = true;

            if (_firedTriggers.Contains(step.Trigger))
            {
                _waitingForTrigger = false;
                AdvanceStep();
            }
        }
        else
        {
            AdvanceStep();
        }
    }

    public void Update(float deltaTime)
    {
        if (!IsActive) return;
        _displayTimer += deltaTime;
    }

    /// <summary>
    /// Draw the tutorial dialogue box and progress dots.
    /// </summary>
    public void Draw(SpriteBatch spriteBatch, SpriteFont? font, int screenWidth, int screenHeight)
    {
        if (!IsActive || font == null) return;

        // Draw progress dots at top-right
        DrawProgressDots(spriteBatch, screenWidth);

        if (!_dialogueVisible) return;

        // Draw dialogue box at bottom of screen
        DrawDialogueBox(spriteBatch, font, screenWidth, screenHeight);
    }

    private void ShowCurrentStep()
    {
        if (_currentStep >= TotalSteps)
        {
            _finished = true;
            MarkComplete();
            TutorialFinished?.Invoke();
            return;
        }

        var step = TutorialData.BattleSteps[_currentStep];
        _speaker = step.Speaker;
        _line1 = step.Line1;
        _line2 = step.Line2;
        _showingLine2 = false;
        _dialogueVisible = true;
        _displayTimer = 0f;
    }

    private void AdvanceStep()
    {
        _currentStep++;
        ShowCurrentStep();
    }

    private void MarkComplete()
    {
        ProgressionState.Instance.CompletedAchievements.Add("battle_tutorial_done");
        ProgressionState.Instance.Save();
        TutorialFinished?.Invoke();
    }

    private void DrawProgressDots(SpriteBatch spriteBatch, int screenWidth)
    {
        int dotSize = 10;
        int spacing = 6;
        int totalWidth = TotalSteps * dotSize + (TotalSteps - 1) * spacing;
        int startX = screenWidth - totalWidth - 20;
        int y = 12;

        for (int i = 0; i < TotalSteps; i++)
        {
            int x = startX + i * (dotSize + spacing);
            Color dotColor;
            if (i < _currentStep)
                dotColor = ThemeColors.Success; // completed
            else if (i == _currentStep)
                dotColor = ThemeColors.Accent; // current
            else
                dotColor = ThemeColors.TextDim; // pending

            DrawFilledRect(spriteBatch, new Rectangle(x, y, dotSize, dotSize), dotColor);
        }

        // Label
        // (would need font to draw "Tutorial: Step X/Y" but dots are sufficient)
    }

    private void DrawDialogueBox(SpriteBatch spriteBatch, SpriteFont font, int screenWidth, int screenHeight)
    {
        int boxWidth = Math.Min(700, screenWidth - 40);
        int boxHeight = 140;
        int boxX = (screenWidth - boxWidth) / 2;
        int boxY = screenHeight - boxHeight - 20;
        int padding = 16;

        // Background
        DrawFilledRect(spriteBatch, new Rectangle(boxX, boxY, boxWidth, boxHeight), ThemeColors.BgPanel);
        // Border
        DrawBorder(spriteBatch, new Rectangle(boxX, boxY, boxWidth, boxHeight), ThemeColors.Border);

        // Speaker name
        spriteBatch.DrawString(font, _speaker, new Vector2(boxX + padding, boxY + padding), ThemeColors.AccentCyan);

        // Dialogue text
        string text = _showingLine2 ? _line2 : _line1;
        spriteBatch.DrawString(font, text, new Vector2(boxX + padding, boxY + padding + 24), ThemeColors.Text);

        // Continue hint
        string hint = _showingLine2 || string.IsNullOrEmpty(_line2)
            ? "[Enter] Continue" : "[Enter] Next";
        var hintSize = font.MeasureString(hint);
        spriteBatch.DrawString(font, hint, new Vector2(boxX + boxWidth - padding - hintSize.X, boxY + boxHeight - padding - hintSize.Y), ThemeColors.TextDim);

        // Skip hint
        spriteBatch.DrawString(font, "[Esc] Skip Tutorial", new Vector2(boxX + padding, boxY + boxHeight - padding - 16), ThemeColors.TextDim);

        // Step counter
        string stepText = $"Step {_currentStep + 1}/{TotalSteps}";
        var stepSize = font.MeasureString(stepText);
        spriteBatch.DrawString(font, stepText, new Vector2(boxX + boxWidth - padding - stepSize.X, boxY + padding), ThemeColors.Accent);
    }

    private static void DrawFilledRect(SpriteBatch spriteBatch, Rectangle rect, Color color)
    {
        var pixel = new Texture2D(spriteBatch.GraphicsDevice, 1, 1);
        pixel.SetData(new[] { Color.White });
        spriteBatch.Draw(pixel, rect, color);
    }

    private static void DrawBorder(SpriteBatch spriteBatch, Rectangle rect, Color color)
    {
        DrawFilledRect(spriteBatch, new Rectangle(rect.X, rect.Y, rect.Width, 1), color);
        DrawFilledRect(spriteBatch, new Rectangle(rect.X, rect.Bottom - 1, rect.Width, 1), color);
        DrawFilledRect(spriteBatch, new Rectangle(rect.X, rect.Y, 1, rect.Height), color);
        DrawFilledRect(spriteBatch, new Rectangle(rect.Right - 1, rect.Y, 1, rect.Height), color);
    }
}
