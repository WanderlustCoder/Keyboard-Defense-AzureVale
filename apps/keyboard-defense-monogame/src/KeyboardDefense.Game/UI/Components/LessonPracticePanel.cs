using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Full lesson practice panel with lesson browsing, typing exercises, and results.
/// Three modes: Browse (select a lesson), Practice (type words), Results (star rating and stats).
/// </summary>
public class LessonPracticePanel : BasePanel
{
    private enum PanelMode { Browse, Practice, Results }

    // Browse mode widgets
    private readonly VerticalStackPanel _browseContent;
    private readonly HorizontalStackPanel _pathTabs;
    private readonly VerticalStackPanel _lessonList;
    private readonly VerticalStackPanel _lessonDetail;

    // Practice mode widgets
    private readonly VerticalStackPanel _practiceContent;
    private readonly Label _practiceTitle;
    private readonly Label _progressLabel;
    private readonly Label _promptDisplay;
    private readonly Label _typedDisplay;
    private readonly Label _cursorChar;
    private readonly Label _remainingDisplay;
    private readonly TextBox _inputBox;
    private readonly Label _feedbackLabel;
    private readonly Label _statsLabel;
    private readonly Label _charsetLabel;

    // Results mode widgets
    private readonly VerticalStackPanel _resultsContent;

    // Practice state
    private string _currentLessonId = "";
    private LessonEntry? _currentLesson;
    private string _currentPrompt = "";
    private readonly List<string> _practiceQueue = new();
    private int _promptIndex;
    private int _wordsCompleted;
    private int _totalCharsTyped;
    private int _correctChars;
    private int _totalErrors;
    private readonly Dictionary<char, int> _errorsByKey = new();
    private readonly Stopwatch _sessionTimer = new();
    private readonly Random _rng = new();
    private PanelMode _mode;

    private const int WordsPerSet = 20;

    /// <summary>Raised when a word is submitted during practice.</summary>
    public event Action<string>? WordSubmitted;

    /// <summary>Raised when lesson practice starts (for keyboard overlay integration).</summary>
    public event Action<LessonEntry>? LessonStarted;

    /// <summary>Raised when lesson practice stops.</summary>
    public event Action? LessonStopped;

    public LessonPracticePanel() : base(Locale.Tr("menu.typing_practice"))
    {
        RootWidget.Width = 800;
        RootWidget.Height = 550;

        // ===== Browse Mode =====
        _browseContent = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };

        // Path tabs
        _pathTabs = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };
        _browseContent.Widgets.Add(_pathTabs);
        _browseContent.Widgets.Add(new HorizontalSeparator());

        // Split: lesson list (left) + detail (right)
        var split = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

        _lessonList = new VerticalStackPanel { Spacing = 2 };
        var listScroll = new ScrollViewer
        {
            Content = _lessonList,
            Width = 260,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(listScroll);

        _lessonDetail = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        var detailScroll = new ScrollViewer
        {
            Content = _lessonDetail,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(detailScroll);

        _browseContent.Widgets.Add(split);
        AddWidget(_browseContent);

        // ===== Practice Mode =====
        _practiceContent = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        _practiceContent.Visible = false;

        // Header row
        var headerRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        _practiceTitle = new Label { Text = "Practice", TextColor = ThemeColors.Accent };
        headerRow.Widgets.Add(_practiceTitle);

        headerRow.Widgets.Add(new Panel { Width = 0, HorizontalAlignment = HorizontalAlignment.Stretch });

        var backBtn = ButtonFactory.Ghost("< Back", StopPractice);
        backBtn.Width = 80;
        backBtn.Height = DesignSystem.SizeButtonSm;
        headerRow.Widgets.Add(backBtn);
        _practiceContent.Widgets.Add(headerRow);

        _progressLabel = new Label { Text = "", TextColor = ThemeColors.TextDim };
        _practiceContent.Widgets.Add(_progressLabel);

        _practiceContent.Widgets.Add(new HorizontalSeparator());

        // Charset display
        _charsetLabel = new Label { Text = "", TextColor = ThemeColors.TextDim };
        _practiceContent.Widgets.Add(_charsetLabel);

        // Prompt display area
        _practiceContent.Widgets.Add(new Panel { Height = DesignSystem.SpaceMd });

        var promptLabel = new Label { Text = "Type:", TextColor = ThemeColors.TextDim };
        _practiceContent.Widgets.Add(promptLabel);

        _promptDisplay = new Label
        {
            Text = "",
            TextColor = ThemeColors.AccentCyan,
        };
        _practiceContent.Widgets.Add(_promptDisplay);

        // Typed feedback row
        var typedRow = new HorizontalStackPanel { Spacing = 0 };
        var youLabel = new Label { Text = "You:  ", TextColor = ThemeColors.TextDim };
        typedRow.Widgets.Add(youLabel);
        _typedDisplay = new Label { Text = "", TextColor = ThemeColors.Success };
        typedRow.Widgets.Add(_typedDisplay);
        _cursorChar = new Label { Text = "_", TextColor = ThemeColors.Accent };
        typedRow.Widgets.Add(_cursorChar);
        _remainingDisplay = new Label { Text = "", TextColor = ThemeColors.TextDim };
        typedRow.Widgets.Add(_remainingDisplay);
        _practiceContent.Widgets.Add(typedRow);

        _practiceContent.Widgets.Add(new Panel { Height = DesignSystem.SpaceSm });

        // Input area
        var inputRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        inputRow.Widgets.Add(new Label { Text = "> ", TextColor = ThemeColors.AccentCyan });

        _inputBox = new TextBox { HorizontalAlignment = HorizontalAlignment.Stretch };
        _inputBox.TextChanged += (_, _) => OnInputChanged();
        inputRow.Widgets.Add(_inputBox);

        var submitBtn = ButtonFactory.Primary("Submit", OnSubmit);
        submitBtn.Width = 90;
        inputRow.Widgets.Add(submitBtn);

        var skipBtn = ButtonFactory.Ghost("Skip", SkipWord);
        skipBtn.Width = 60;
        skipBtn.Height = DesignSystem.SizeButtonSm;
        inputRow.Widgets.Add(skipBtn);
        _practiceContent.Widgets.Add(inputRow);

        // Feedback
        _feedbackLabel = new Label
        {
            Text = "",
            TextColor = ThemeColors.Success,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        _practiceContent.Widgets.Add(_feedbackLabel);

        _practiceContent.Widgets.Add(new HorizontalSeparator());

        // Stats
        _statsLabel = new Label
        {
            Text = "Words: 0 | Errors: 0 | Accuracy: --% | WPM: --",
            TextColor = ThemeColors.TextDim,
        };
        _practiceContent.Widgets.Add(_statsLabel);

        AddWidget(_practiceContent);

        // ===== Results Mode =====
        _resultsContent = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        _resultsContent.Visible = false;
        AddWidget(_resultsContent);

        // Initialize browse view
        PopulatePathTabs();
    }

    // ================================================================
    // MODE SWITCHING
    // ================================================================

    private void SetMode(PanelMode mode)
    {
        _mode = mode;
        _browseContent.Visible = mode == PanelMode.Browse;
        _practiceContent.Visible = mode == PanelMode.Practice;
        _resultsContent.Visible = mode == PanelMode.Results;
    }

    // ================================================================
    // BROWSE MODE
    // ================================================================

    private void PopulatePathTabs()
    {
        _pathTabs.Widgets.Clear();
        var paths = LessonsData.GetPaths();

        if (paths.Count == 0)
        {
            var allBtn = ButtonFactory.Secondary("All Lessons", () => ShowAllLessons());
            allBtn.Width = 120;
            allBtn.Height = DesignSystem.SizeButtonSm;
            _pathTabs.Widgets.Add(allBtn);
            ShowAllLessons();
            return;
        }

        foreach (var path in paths)
        {
            var p = path;
            var btn = ButtonFactory.Ghost(path.Name, () => ShowPath(p));
            btn.Width = 120;
            btn.Height = DesignSystem.SizeButtonSm;
            _pathTabs.Widgets.Add(btn);
        }

        ShowPath(paths[0]);
    }

    /// <summary>Refresh the browse view (e.g., after completing a lesson to update stars).</summary>
    public void RefreshBrowse()
    {
        PopulatePathTabs();
    }

    private void ShowPath(GraduationPath path)
    {
        _lessonList.Widgets.Clear();
        _lessonDetail.Widgets.Clear();

        _lessonDetail.Widgets.Add(new Label
        {
            Text = path.Name,
            TextColor = ThemeColors.Accent,
        });
        _lessonDetail.Widgets.Add(new Label
        {
            Text = path.Description,
            TextColor = ThemeColors.TextDim,
            Wrap = true,
        });

        // Show path progress summary
        int totalLessons = path.Stages.Sum(s => s.LessonIds.Count);
        int completedLessons = path.Stages
            .SelectMany(s => s.LessonIds)
            .Count(id => LessonProgress.Instance.IsCompleted(id));
        int totalStars = path.Stages
            .SelectMany(s => s.LessonIds)
            .Sum(id => LessonProgress.Instance.GetStars(id));
        int maxStars = totalLessons * 3;

        _lessonDetail.Widgets.Add(new Label
        {
            Text = $"Progress: {completedLessons}/{totalLessons} lessons | Stars: {totalStars}/{maxStars}",
            TextColor = ThemeColors.TextDim,
        });

        _lessonDetail.Widgets.Add(new Label
        {
            Text = "Select a lesson to see details.",
            TextColor = ThemeColors.TextDim,
        });

        foreach (var stage in path.Stages)
        {
            // Stage header with completion info
            int stageCompleted = stage.LessonIds.Count(id => LessonProgress.Instance.IsCompleted(id));
            string stageStatus = stageCompleted == stage.LessonIds.Count && stage.LessonIds.Count > 0
                ? " [DONE]" : "";
            _lessonList.Widgets.Add(new Label
            {
                Text = $"Stage {stage.Stage}: {stage.Name}{stageStatus}",
                TextColor = ThemeColors.Warning,
            });

            foreach (string lessonId in stage.LessonIds)
            {
                var lesson = LessonsData.GetLesson(lessonId);
                string displayName = lesson?.Name ?? lessonId;
                string lid = lessonId;

                int stars = LessonProgress.Instance.GetStars(lessonId);
                string starStr = LessonProgress.FormatStars(stars);
                Color starColor = stars switch
                {
                    3 => ThemeColors.Warning,
                    2 => ThemeColors.AccentCyan,
                    1 => ThemeColors.TextDim,
                    _ => ThemeColors.TextDim,
                };

                var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };
                row.Widgets.Add(new Label
                {
                    Text = $"[{starStr}]",
                    TextColor = starColor,
                    Width = 42,
                });
                row.Widgets.Add(new Label
                {
                    Text = displayName,
                    TextColor = ThemeColors.Text,
                });

                var btn = new Button
                {
                    Content = row,
                    Height = 26,
                    HorizontalAlignment = HorizontalAlignment.Stretch,
                };
                btn.Click += (_, _) => ShowLessonDetail(lid);
                _lessonList.Widgets.Add(btn);
            }

            _lessonList.Widgets.Add(new Panel { Height = 4 });
        }
    }

    private void ShowAllLessons()
    {
        _lessonList.Widgets.Clear();
        _lessonDetail.Widgets.Clear();

        _lessonDetail.Widgets.Add(new Label
        {
            Text = "Select a lesson to see details.",
            TextColor = ThemeColors.TextDim,
        });

        foreach (string lessonId in LessonsData.LessonIds())
        {
            var lesson = LessonsData.GetLesson(lessonId);
            string displayName = lesson?.Name ?? lessonId;
            string lid = lessonId;

            int stars = LessonProgress.Instance.GetStars(lessonId);
            string starStr = LessonProgress.FormatStars(stars);

            var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };
            row.Widgets.Add(new Label
            {
                Text = $"[{starStr}]",
                TextColor = stars > 0 ? ThemeColors.Warning : ThemeColors.TextDim,
                Width = 42,
            });
            row.Widgets.Add(new Label
            {
                Text = displayName,
                TextColor = ThemeColors.Text,
            });

            var btn = new Button
            {
                Content = row,
                Height = 26,
                HorizontalAlignment = HorizontalAlignment.Stretch,
            };
            btn.Click += (_, _) => ShowLessonDetail(lid);
            _lessonList.Widgets.Add(btn);
        }
    }

    private void ShowLessonDetail(string lessonId)
    {
        var lesson = LessonsData.GetLesson(lessonId);
        if (lesson == null) return;

        _lessonDetail.Widgets.Clear();

        _lessonDetail.Widgets.Add(new Label
        {
            Text = lesson.Name,
            TextColor = ThemeColors.Accent,
        });

        _lessonDetail.Widgets.Add(new Label
        {
            Text = lesson.Description,
            TextColor = ThemeColors.Text,
            Wrap = true,
        });

        _lessonDetail.Widgets.Add(new HorizontalSeparator());

        // Mode info
        string modeText = lesson.Mode switch
        {
            "charset" => "Mode: Character Practice",
            "wordlist" => $"Mode: Word List ({lesson.WordList.Count} words)",
            "sentence" => $"Mode: Sentence Practice ({lesson.Sentences.Count} sentences)",
            _ => $"Mode: {lesson.Mode}",
        };
        _lessonDetail.Widgets.Add(new Label { Text = modeText, TextColor = ThemeColors.TextDim });

        if (lesson.Charset.Count > 0)
        {
            string chars = string.Join(" ", lesson.Charset);
            _lessonDetail.Widgets.Add(new Label
            {
                Text = $"Keys: {chars}",
                TextColor = ThemeColors.AccentCyan,
            });

            // Show finger zones for the charset
            var zones = lesson.Charset
                .Where(c => c.Length == 1)
                .Select(c => TypingProfile.GetFingerZone(c[0]))
                .Where(z => z >= 0)
                .Distinct()
                .OrderBy(z => z)
                .Select(z => FingerZoneName(z));
            string zoneText = string.Join(", ", zones);
            if (!string.IsNullOrEmpty(zoneText))
            {
                _lessonDetail.Widgets.Add(new Label
                {
                    Text = $"Fingers: {zoneText}",
                    TextColor = ThemeColors.TextDim,
                });
            }
        }

        if (lesson.Difficulty > 0)
        {
            string stars = new string('*', Math.Min(lesson.Difficulty, 5));
            _lessonDetail.Widgets.Add(new Label
            {
                Text = $"Difficulty: {stars}",
                TextColor = ThemeColors.Warning,
            });
        }

        // Sample words preview
        if (lesson.Mode == "wordlist" && lesson.WordList.Count > 0)
        {
            var samples = lesson.WordList.Take(8);
            _lessonDetail.Widgets.Add(new Label
            {
                Text = $"Sample: {string.Join(", ", samples)}...",
                TextColor = ThemeColors.TextDim,
                Wrap = true,
            });
        }
        else if (lesson.Mode == "sentence" && lesson.Sentences.Count > 0)
        {
            _lessonDetail.Widgets.Add(new Label
            {
                Text = $"Example: \"{lesson.Sentences[0]}\"",
                TextColor = ThemeColors.TextDim,
                Wrap = true,
            });
        }

        // Personal best stats
        var progress = LessonProgress.Instance;
        if (progress.IsCompleted(lessonId))
        {
            var result = progress.GetResult(lessonId);
            _lessonDetail.Widgets.Add(new HorizontalSeparator());
            _lessonDetail.Widgets.Add(new Label
            {
                Text = $"Best: {LessonProgress.FormatStars(result.Stars)} | WPM: {result.BestWpm:F0} | Acc: {result.BestAccuracy * 100:F0}%",
                TextColor = ThemeColors.Accent,
            });
            _lessonDetail.Widgets.Add(new Label
            {
                Text = $"Attempts: {result.Attempts} | Last played: {result.LastPlayedUtc:yyyy-MM-dd}",
                TextColor = ThemeColors.TextDim,
            });
        }

        _lessonDetail.Widgets.Add(new Panel { Height = DesignSystem.SpaceMd });

        var startBtn = ButtonFactory.Primary("Start Practice", () => StartPractice(lessonId));
        startBtn.Width = 160;
        _lessonDetail.Widgets.Add(startBtn);
    }

    // ================================================================
    // PRACTICE MODE
    // ================================================================

    public void SetLesson(string lessonId)
    {
        StartPractice(lessonId);
    }

    private void StartPractice(string lessonId)
    {
        _currentLessonId = lessonId;
        _currentLesson = LessonsData.GetLesson(lessonId);
        if (_currentLesson == null) return;

        SetMode(PanelMode.Practice);

        _practiceTitle.Text = _currentLesson.Name;
        _wordsCompleted = 0;
        _totalCharsTyped = 0;
        _correctChars = 0;
        _totalErrors = 0;
        _errorsByKey.Clear();
        _promptIndex = 0;
        _feedbackLabel.Text = "";

        // Show charset if applicable
        if (_currentLesson.Charset.Count > 0)
            _charsetLabel.Text = $"Keys: {string.Join(" ", _currentLesson.Charset)}";
        else
            _charsetLabel.Text = "";

        GeneratePracticeQueue();
        _sessionTimer.Restart();
        LessonStarted?.Invoke(_currentLesson);
        NextPrompt();
    }

    private void StopPractice()
    {
        _sessionTimer.Stop();
        LessonStopped?.Invoke();
        SetMode(PanelMode.Browse);
        RefreshBrowse();
    }

    private void GeneratePracticeQueue()
    {
        _practiceQueue.Clear();
        if (_currentLesson == null) return;

        switch (_currentLesson.Mode)
        {
            case "wordlist":
                GenerateWordlistQueue();
                break;
            case "sentence":
                GenerateSentenceQueue();
                break;
            default: // charset
                GenerateCharsetQueue();
                break;
        }
    }

    private void GenerateWordlistQueue()
    {
        if (_currentLesson!.WordList.Count == 0) return;
        var shuffled = _currentLesson.WordList.OrderBy(_ => _rng.Next()).ToList();
        for (int i = 0; i < WordsPerSet && i < shuffled.Count; i++)
            _practiceQueue.Add(shuffled[i]);
        while (_practiceQueue.Count < WordsPerSet && _currentLesson.WordList.Count > 0)
            _practiceQueue.Add(_currentLesson.WordList[_rng.Next(_currentLesson.WordList.Count)]);
    }

    private void GenerateSentenceQueue()
    {
        if (_currentLesson!.Sentences.Count == 0) return;
        var shuffled = _currentLesson.Sentences.OrderBy(_ => _rng.Next()).ToList();
        int count = Math.Min(10, shuffled.Count);
        for (int i = 0; i < count; i++)
            _practiceQueue.Add(shuffled[i]);
    }

    private void GenerateCharsetQueue()
    {
        string charset = string.Join("", _currentLesson!.Charset);
        if (charset.Length == 0) charset = "asdfghjkl";
        for (int i = 0; i < WordsPerSet; i++)
        {
            int length = _rng.Next(3, Math.Min(8, charset.Length + 3));
            var chars = new char[length];
            for (int j = 0; j < length; j++)
                chars[j] = charset[_rng.Next(charset.Length)];
            _practiceQueue.Add(new string(chars));
        }
    }

    private void NextPrompt()
    {
        if (_promptIndex >= _practiceQueue.Count)
        {
            _sessionTimer.Stop();
            ShowResults();
            return;
        }

        _currentPrompt = _practiceQueue[_promptIndex];
        _promptDisplay.Text = _currentPrompt;
        _typedDisplay.Text = "";
        _cursorChar.Text = _currentPrompt.Length > 0 ? _currentPrompt[0].ToString() : "_";
        _remainingDisplay.Text = _currentPrompt.Length > 1 ? _currentPrompt[1..] : "";
        _feedbackLabel.Text = "";
        if (_inputBox != null) _inputBox.Text = "";

        UpdateProgress();
        UpdateStats();
    }

    private void SkipWord()
    {
        _totalErrors++;
        _promptIndex++;
        NextPrompt();
    }

    private void OnInputChanged()
    {
        if (_mode != PanelMode.Practice) return;
        string input = _inputBox?.Text ?? "";
        UpdateTypedDisplay(input);
    }

    private void UpdateTypedDisplay(string input)
    {
        if (string.IsNullOrEmpty(_currentPrompt)) return;

        string correct = "";
        bool hasError = false;
        int matchLen = Math.Min(input.Length, _currentPrompt.Length);

        for (int i = 0; i < matchLen; i++)
        {
            if (input[i] == _currentPrompt[i])
                correct += _currentPrompt[i];
            else
            {
                hasError = true;
                break;
            }
        }

        _typedDisplay.Text = correct;
        _typedDisplay.TextColor = hasError ? ThemeColors.Error : ThemeColors.Success;

        int cursorPos = correct.Length;
        if (cursorPos < _currentPrompt.Length)
        {
            _cursorChar.Text = _currentPrompt[cursorPos].ToString();
            _remainingDisplay.Text = cursorPos + 1 < _currentPrompt.Length
                ? _currentPrompt[(cursorPos + 1)..]
                : "";
        }
        else
        {
            _cursorChar.Text = "";
            _remainingDisplay.Text = "";
        }

        if (hasError)
        {
            _feedbackLabel.Text = "Mismatch! Check your input.";
            _feedbackLabel.TextColor = ThemeColors.Error;
        }
        else if (input.Length > 0 && input.Length < _currentPrompt.Length)
        {
            _feedbackLabel.Text = "";
        }

        if (input == _currentPrompt)
        {
            AcceptWord(input);
        }
    }

    private void OnSubmit()
    {
        string input = _inputBox?.Text?.Trim() ?? "";
        if (string.IsNullOrEmpty(input)) return;

        if (input == _currentPrompt)
        {
            AcceptWord(input);
        }
        else
        {
            var profile = TypingProfile.Instance;
            int errors = 0;
            for (int i = 0; i < Math.Min(input.Length, _currentPrompt.Length); i++)
            {
                if (input[i] != _currentPrompt[i])
                {
                    errors++;
                    profile.RecordError(_currentPrompt[i], input[i]);
                    TrackKeyError(_currentPrompt[i]);
                }
                else
                {
                    profile.RecordCorrectChar(_currentPrompt[i]);
                }
            }
            errors += Math.Abs(input.Length - _currentPrompt.Length);
            _totalErrors += Math.Max(1, errors);
            _totalCharsTyped += input.Length;

            _feedbackLabel.Text = $"Expected: {_currentPrompt}";
            _feedbackLabel.TextColor = ThemeColors.Error;
            if (_inputBox != null) _inputBox.Text = "";
            UpdateStats();
        }
    }

    private void AcceptWord(string input)
    {
        _wordsCompleted++;
        _correctChars += _currentPrompt.Length;
        _totalCharsTyped += _currentPrompt.Length;
        _promptIndex++;

        var profile = TypingProfile.Instance;
        foreach (char c in _currentPrompt)
            profile.RecordCorrectChar(c);

        _feedbackLabel.Text = "Correct!";
        _feedbackLabel.TextColor = ThemeColors.Success;

        WordSubmitted?.Invoke(input);
        if (_inputBox != null) _inputBox.Text = "";

        UpdateStats();
        NextPrompt();
    }

    private void TrackKeyError(char c)
    {
        char key = char.ToLower(c);
        _errorsByKey.TryGetValue(key, out int count);
        _errorsByKey[key] = count + 1;
    }

    // ================================================================
    // RESULTS MODE
    // ================================================================

    private void ShowResults()
    {
        double accuracy = _totalCharsTyped > 0 ? (double)_correctChars / _totalCharsTyped : 1.0;
        float wpm = CalculateWpm();

        // Record in TypingProfile
        TypingProfile.Instance.RecordSession(wpm, accuracy, _wordsCompleted, _totalErrors,
            _sessionTimer.Elapsed.TotalSeconds, _currentLessonId);
        Services.GameController.Instance.SaveTypingProfile();

        // Record in LessonProgress and persist
        int stars = LessonProgress.Instance.RecordAttempt(
            _currentLessonId, wpm, accuracy, _wordsCompleted, _totalErrors);
        LessonProgress.Instance.Save(Services.SaveService.GetSavesDir());

        LessonStopped?.Invoke();

        // Build results screen
        _resultsContent.Widgets.Clear();
        SetMode(PanelMode.Results);

        // Title
        _resultsContent.Widgets.Add(new Label
        {
            Text = "Lesson Complete!",
            TextColor = ThemeColors.Accent,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        _resultsContent.Widgets.Add(new Label
        {
            Text = _currentLesson?.Name ?? _currentLessonId,
            TextColor = ThemeColors.Text,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        _resultsContent.Widgets.Add(new HorizontalSeparator());

        // Star rating display
        string starDisplay = stars switch
        {
            3 => "*** PERFECT ***",
            2 => "**  GREAT  **",
            1 => "*  COMPLETED  *",
            _ => "COMPLETED",
        };
        Color starColor = stars switch
        {
            3 => ThemeColors.Warning,
            2 => ThemeColors.AccentCyan,
            _ => ThemeColors.TextDim,
        };
        _resultsContent.Widgets.Add(new Label
        {
            Text = starDisplay,
            TextColor = starColor,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        // Star criteria
        _resultsContent.Widgets.Add(new Panel { Height = DesignSystem.SpaceXs });
        _resultsContent.Widgets.Add(new Label
        {
            Text = stars >= 3
                ? "Accuracy 95%+ and WPM 30+ achieved!"
                : stars >= 2
                    ? "Accuracy 85%+ achieved! Get 95%+ and 30 WPM for 3 stars."
                    : "Completed! Get 85%+ accuracy for 2 stars.",
            TextColor = ThemeColors.TextDim,
            HorizontalAlignment = HorizontalAlignment.Center,
            Wrap = true,
        });

        _resultsContent.Widgets.Add(new HorizontalSeparator());

        // Stats grid
        float accuracyPct = (float)(accuracy * 100);
        string duration = Locale.FormatDuration(_sessionTimer.Elapsed.TotalSeconds);

        var statsGrid = new VerticalStackPanel { Spacing = DesignSystem.SpaceXs };
        statsGrid.Widgets.Add(MakeStatRow("WPM", $"{wpm:F0}", wpm >= 30 ? ThemeColors.Success : ThemeColors.Text));
        statsGrid.Widgets.Add(MakeStatRow("Accuracy", $"{accuracyPct:F1}%", accuracy >= 0.95 ? ThemeColors.Success : accuracy >= 0.85 ? ThemeColors.AccentCyan : ThemeColors.Error));
        statsGrid.Widgets.Add(MakeStatRow("Words", $"{_wordsCompleted}", ThemeColors.Text));
        statsGrid.Widgets.Add(MakeStatRow("Errors", $"{_totalErrors}", _totalErrors == 0 ? ThemeColors.Success : ThemeColors.Error));
        statsGrid.Widgets.Add(MakeStatRow("Duration", duration, ThemeColors.TextDim));
        _resultsContent.Widgets.Add(statsGrid);

        // Per-key errors (if any)
        if (_errorsByKey.Count > 0)
        {
            _resultsContent.Widgets.Add(new HorizontalSeparator());
            _resultsContent.Widgets.Add(new Label
            {
                Text = "Errors by key:",
                TextColor = ThemeColors.TextDim,
            });

            var errorKeys = _errorsByKey.OrderByDescending(kv => kv.Value).Take(8);
            string errorText = string.Join(", ", errorKeys.Select(kv => $"'{kv.Key}' x{kv.Value}"));
            _resultsContent.Widgets.Add(new Label
            {
                Text = errorText,
                TextColor = ThemeColors.Error,
                Wrap = true,
            });
        }

        // Personal best indicator
        var best = LessonProgress.Instance.GetResult(_currentLessonId);
        if (Math.Abs(wpm - best.BestWpm) < 0.01 && best.Attempts > 1)
        {
            _resultsContent.Widgets.Add(new Label
            {
                Text = "NEW PERSONAL BEST WPM!",
                TextColor = ThemeColors.Warning,
                HorizontalAlignment = HorizontalAlignment.Center,
            });
        }

        _resultsContent.Widgets.Add(new Panel { Height = DesignSystem.SpaceSm });

        // Action buttons
        var buttonRow = new HorizontalStackPanel
        {
            Spacing = DesignSystem.SpaceSm,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var retryBtn = ButtonFactory.Primary("Retry", () => StartPractice(_currentLessonId));
        retryBtn.Width = 120;
        buttonRow.Widgets.Add(retryBtn);

        var browseBtn = ButtonFactory.Secondary("Lessons", () =>
        {
            SetMode(PanelMode.Browse);
            RefreshBrowse();
        });
        browseBtn.Width = 120;
        buttonRow.Widgets.Add(browseBtn);

        _resultsContent.Widgets.Add(buttonRow);
    }

    private static HorizontalStackPanel MakeStatRow(string label, string value, Color valueColor)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        row.Widgets.Add(new Label { Text = $"{label}:", TextColor = ThemeColors.TextDim, Width = 80 });
        row.Widgets.Add(new Label { Text = value, TextColor = valueColor });
        return row;
    }

    // ================================================================
    // STATS
    // ================================================================

    private void UpdateProgress()
    {
        int total = _practiceQueue.Count;
        int done = _promptIndex;
        int barLen = 20;
        int filled = total > 0 ? (int)((float)done / total * barLen) : 0;
        string bar = new string('#', filled) + new string('-', barLen - filled);
        _progressLabel.Text = $"Word {done + 1} of {total}  [{bar}]";
    }

    private void UpdateStats()
    {
        float accuracy = _totalCharsTyped > 0 ? (float)_correctChars / _totalCharsTyped * 100f : 0f;
        float wpm = CalculateWpm();
        string accStr = _totalCharsTyped > 0 ? $"{accuracy:F0}%" : "--%";
        string wpmStr = _sessionTimer.Elapsed.TotalSeconds > 5 ? $"{wpm:F0}" : "--";
        _statsLabel.Text = $"Words: {_wordsCompleted} | Errors: {_totalErrors} | Accuracy: {accStr} | WPM: {wpmStr}";
    }

    private float CalculateWpm()
    {
        double minutes = _sessionTimer.Elapsed.TotalMinutes;
        if (minutes < 0.1) return 0f;
        return (float)(_correctChars / 5.0 / minutes);
    }

    private static string FingerZoneName(int zone) => zone switch
    {
        0 => "Left Pinky",
        1 => "Left Ring",
        2 => "Left Middle",
        3 => "Left Index",
        4 => "Right Index",
        5 => "Right Middle",
        6 => "Right Ring",
        7 => "Right Pinky",
        _ => "Unknown",
    };

    // Public properties for external integration (keyboard display)
    public string CurrentPrompt => _currentPrompt;
    public bool IsPracticing => _mode == PanelMode.Practice;

    /// <summary>Get the active lesson's charset for keyboard overlay highlighting.</summary>
    public IReadOnlyList<string> ActiveCharset =>
        _currentLesson?.Charset ?? (IReadOnlyList<string>)Array.Empty<string>();
}
