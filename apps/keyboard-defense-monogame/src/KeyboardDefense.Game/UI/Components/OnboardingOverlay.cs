using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Onboarding overlay for Kingdom Defense mode.
/// Shows contextual hints and step-by-step guidance for new players.
/// Ported from game/onboarding_flow.gd.
/// </summary>
public class OnboardingOverlay
{
    private int _currentStep;
    private bool _finished;
    private bool _dismissed;
    private readonly HashSet<string> _completedFlags = new();

    private float _animTimer;
    private bool _visible = true;

    public bool IsActive => !_finished && !_dismissed;

    public event Action? OnboardingComplete;

    public void Start()
    {
        if (ProgressionState.Instance.CompletedAchievements.Contains("onboarding_done"))
        {
            _finished = true;
            return;
        }

        _currentStep = 0;
        _finished = false;
        _dismissed = false;
    }

    /// <summary>
    /// Set a completion flag (e.g., "used_help", "did_gather").
    /// Automatically advances when all flags for current step are met.
    /// </summary>
    public void SetFlag(string flag)
    {
        if (_finished || _dismissed) return;
        _completedFlags.Add(flag);
        CheckStepCompletion();
    }

    /// <summary>
    /// Check game state to auto-detect completion conditions.
    /// </summary>
    public void CheckState(GameState state)
    {
        if (_finished || _dismissed) return;

        // Auto-detect flags from state
        if (state.Phase == "night" && !_completedFlags.Contains("entered_night"))
            SetFlag("entered_night");

        if (state.EnemiesDefeated > 0 && !_completedFlags.Contains("hit_enemy"))
            SetFlag("hit_enemy");

        if (state.Day > 1 && !_completedFlags.Contains("reached_dawn"))
            SetFlag("reached_dawn");

        if (state.Resources.TryGetValue("wood", out int wood) && wood > 0)
            SetFlag("did_gather");

        if (state.Buildings.TryGetValue("farm", out int farms) && farms > 0)
            SetFlag("did_build");
    }

    /// <summary>
    /// Dismiss the onboarding overlay.
    /// </summary>
    public void Dismiss()
    {
        _dismissed = true;
        MarkComplete();
    }

    /// <summary>
    /// Manually acknowledge current step (for steps without auto-detect).
    /// </summary>
    public void Acknowledge()
    {
        if (_finished || _dismissed) return;
        var step = GetCurrentStep();
        if (step == null) return;

        foreach (string flag in step.CompletionFlags)
            _completedFlags.Add(flag);
        CheckStepCompletion();
    }

    public void Update(float deltaTime)
    {
        if (!IsActive) return;
        _animTimer += deltaTime;
    }

    public void Draw(SpriteBatch spriteBatch, SpriteFont? font, int screenWidth, int screenHeight)
    {
        if (!IsActive || !_visible || font == null) return;

        var step = GetCurrentStep();
        if (step == null) return;

        // Draw hint panel in top-left corner
        int panelWidth = Math.Min(400, screenWidth / 3);
        int panelHeight = 120;
        int panelX = 12;
        int panelY = 40;
        int padding = 12;

        // Background with slight pulse
        float pulse = 0.9f + 0.1f * (float)Math.Sin(_animTimer * 2);
        var bgColor = ThemeColors.BgPanel;
        DrawFilledRect(spriteBatch, new Rectangle(panelX, panelY, panelWidth, panelHeight), bgColor);

        // Accent border on left
        DrawFilledRect(spriteBatch, new Rectangle(panelX, panelY, 3, panelHeight), ThemeColors.Accent);

        // Title
        spriteBatch.DrawString(font, step.Title,
            new Vector2(panelX + padding, panelY + padding),
            ThemeColors.Accent);

        // Description
        string desc = WrapText(step.Description, font, panelWidth - padding * 2);
        spriteBatch.DrawString(font, desc,
            new Vector2(panelX + padding, panelY + padding + 22),
            ThemeColors.Text);

        // Hint (pulsing)
        Color hintColor = ThemeColors.AccentCyan * pulse;
        spriteBatch.DrawString(font, step.Hint,
            new Vector2(panelX + padding, panelY + panelHeight - padding - 18),
            hintColor);

        // Step counter
        string stepText = $"Step {_currentStep + 1}/{TutorialData.OnboardingSteps.Count}";
        var stepSize = font.MeasureString(stepText);
        spriteBatch.DrawString(font, stepText,
            new Vector2(panelX + panelWidth - padding - stepSize.X, panelY + padding),
            ThemeColors.TextDim);

        // Progress bar
        int barY = panelY + panelHeight + 4;
        int barWidth = panelWidth;
        float progress = (float)_currentStep / TutorialData.OnboardingSteps.Count;
        DrawFilledRect(spriteBatch, new Rectangle(panelX, barY, barWidth, 3), ThemeColors.BgCard);
        DrawFilledRect(spriteBatch, new Rectangle(panelX, barY, (int)(barWidth * progress), 3), ThemeColors.Accent);

        // Dismiss hint
        spriteBatch.DrawString(font, "[Tab] Dismiss",
            new Vector2(panelX + padding, barY + 6),
            ThemeColors.TextDim);
    }

    private OnboardingStep? GetCurrentStep()
    {
        if (_currentStep >= TutorialData.OnboardingSteps.Count) return null;
        return TutorialData.OnboardingSteps[_currentStep];
    }

    private void CheckStepCompletion()
    {
        var step = GetCurrentStep();
        if (step == null) return;

        bool allComplete = true;
        foreach (string flag in step.CompletionFlags)
        {
            if (!_completedFlags.Contains(flag))
            {
                allComplete = false;
                break;
            }
        }

        if (allComplete)
        {
            _currentStep++;
            if (_currentStep >= TutorialData.OnboardingSteps.Count)
            {
                _finished = true;
                MarkComplete();
            }
        }
    }

    private void MarkComplete()
    {
        ProgressionState.Instance.CompletedAchievements.Add("onboarding_done");
        ProgressionState.Instance.Save();
        OnboardingComplete?.Invoke();
    }

    private static string WrapText(string text, SpriteFont font, int maxWidth)
    {
        if (font.MeasureString(text).X <= maxWidth) return text;

        string[] words = text.Split(' ');
        string result = "";
        string currentLine = "";

        foreach (string word in words)
        {
            string test = string.IsNullOrEmpty(currentLine) ? word : currentLine + " " + word;
            if (font.MeasureString(test).X > maxWidth)
            {
                result += currentLine + "\n";
                currentLine = word;
            }
            else
            {
                currentLine = test;
            }
        }
        return result + currentLine;
    }

    private static void DrawFilledRect(SpriteBatch spriteBatch, Rectangle rect, Color color)
    {
        var pixel = new Texture2D(spriteBatch.GraphicsDevice, 1, 1);
        pixel.SetData(new[] { Color.White });
        spriteBatch.Draw(pixel, rect, color);
    }
}
