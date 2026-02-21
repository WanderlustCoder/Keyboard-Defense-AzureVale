using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Data;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Dialogue box for NPC conversations and tutorial messages.
/// Supports sequential lines, speaker labels, portraits, and StoryManager integration.
/// Ported from game/dialogue_box.gd.
/// </summary>
public class DialogueBox : BasePanel
{
    private readonly Panel _portraitPanel;
    private readonly Label _speakerLabel;
    private readonly Label _messageLabel;
    private readonly Label _counterLabel;
    private readonly Button _nextButton;
    private readonly Queue<DialogueLine> _queue = new();
    private DialogueLine? _currentLine;
    private int _totalLines;
    private int _currentIndex;

    public event Action? DialogueComplete;
    public bool IsActive => Visible && _queue.Count > 0 || _currentLine != null;

    public DialogueBox() : base("Dialogue")
    {
        RootWidget.Width = 600;
        RootWidget.Height = 200;
        RootWidget.VerticalAlignment = VerticalAlignment.Bottom;

        // Main horizontal layout: [portrait | text column]
        var mainRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

        // Portrait area (64x64 colored rect, later swappable for real portraits)
        _portraitPanel = new Panel
        {
            Width = 64,
            Height = 64,
            Background = new Myra.Graphics2D.Brushes.SolidBrush(ThemeColors.BgCard),
        };
        mainRow.Widgets.Add(_portraitPanel);

        // Text column
        var textColumn = new VerticalStackPanel { Spacing = DesignSystem.SpaceXs };

        _speakerLabel = new Label
        {
            Text = "",
            TextColor = ThemeColors.AccentCyan,
        };
        textColumn.Widgets.Add(_speakerLabel);

        _messageLabel = new Label
        {
            Text = "",
            TextColor = ThemeColors.Text,
            Wrap = true,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        textColumn.Widgets.Add(_messageLabel);

        mainRow.Widgets.Add(textColumn);
        AddWidget(mainRow);

        AddWidget(new Panel { Height = DesignSystem.SpaceSm });

        // Bottom row: counter + button
        var bottomRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        _counterLabel = new Label { Text = "", TextColor = ThemeColors.TextDim };
        bottomRow.Widgets.Add(_counterLabel);
        bottomRow.Widgets.Add(new Panel { HorizontalAlignment = HorizontalAlignment.Stretch });

        _nextButton = ButtonFactory.Primary("Continue", Advance);
        _nextButton.Width = 120;
        bottomRow.Widgets.Add(_nextButton);
        AddWidget(bottomRow);
    }

    /// <summary>Set portrait color based on NPC type.</summary>
    public void SetSpeakerPortrait(string npcType)
    {
        var color = npcType switch
        {
            "trainer" => ThemeColors.Success,           // green
            "merchant" => ThemeColors.GoldAccent,       // gold
            "quest_giver" => ThemeColors.RarityEpic,    // purple
            _ => ThemeColors.AccentBlue,
        };
        _portraitPanel.Background = new Myra.Graphics2D.Brushes.SolidBrush(color);
    }

    public void StartDialogue(List<DialogueLine> lines)
    {
        _queue.Clear();
        _totalLines = lines.Count;
        _currentIndex = 0;
        foreach (var line in lines)
            _queue.Enqueue(line);
        Advance();
        Open();
    }

    public void StartDialogue(string speaker, string message)
    {
        StartDialogue(new List<DialogueLine> { new(speaker, message) });
    }

    /// <summary>
    /// Start dialogue from StoryManager dialogue context (e.g., "game_start", "day_start").
    /// </summary>
    public void StartFromContext(string context, Dictionary<string, string>? vars = null)
    {
        var story = StoryManager.Instance;
        string speaker = story.GetDialogueSpeaker(context);
        var lines = story.GetDialogueLines(context, vars);
        if (lines.Count == 0) return;
        StartDialogue(lines.ConvertAll(msg => new DialogueLine(speaker, msg)));
    }

    /// <summary>
    /// Start dialogue from a story act's intro text.
    /// </summary>
    public void StartActIntro(StoryAct act)
    {
        var lines = new List<DialogueLine>
        {
            new(act.MentorName, act.IntroText),
        };
        // Add lesson context if available
        foreach (string lessonId in act.Lessons)
        {
            var intro = StoryManager.Instance.GetLessonIntro(lessonId);
            if (intro != null)
            {
                foreach (string line in intro.Lines)
                    lines.Add(new DialogueLine(intro.Speaker, line));
                break; // Just first lesson intro to avoid overload
            }
        }
        StartDialogue(lines);
    }

    /// <summary>
    /// Start boss encounter dialogue.
    /// </summary>
    public void StartBossIntro(StoryAct act)
    {
        var lines = new List<DialogueLine>
        {
            new("Narrator", act.BossIntro),
            new(act.BossName, act.BossTaunt),
            new(act.MentorName, "Be careful! Focus your keystrokes!"),
        };
        StartDialogue(lines);
    }

    /// <summary>
    /// Show boss defeat dialogue.
    /// </summary>
    public void StartBossDefeat(StoryAct act)
    {
        var lines = new List<DialogueLine>
        {
            new(act.BossName, act.BossDefeat),
            new(act.MentorName, act.CompletionText),
        };
        if (!string.IsNullOrEmpty(act.Reward))
            lines.Add(new DialogueLine("System", $"Reward: {act.Reward}"));
        StartDialogue(lines);
    }

    private void Advance()
    {
        if (_queue.Count > 0)
        {
            _currentLine = _queue.Dequeue();
            _currentIndex++;
            _speakerLabel.Text = _currentLine.Speaker;
            _messageLabel.Text = _currentLine.Message;
            _counterLabel.Text = _totalLines > 1 ? $"{_currentIndex}/{_totalLines}" : "";
            _nextButton.Content = new Label
            {
                Text = _queue.Count > 0 ? "Next" : "Close",
            };
        }
        else
        {
            _currentLine = null;
            Close();
            DialogueComplete?.Invoke();
        }
    }
}

public record DialogueLine(string Speaker, string Message);
