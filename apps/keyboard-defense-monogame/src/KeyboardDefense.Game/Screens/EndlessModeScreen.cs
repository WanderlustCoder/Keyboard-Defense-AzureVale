using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Game.Audio;
using KeyboardDefense.Game.Effects;
using KeyboardDefense.Game.Input;
using KeyboardDefense.Game.Rendering;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Screens;

/// <summary>
/// Endless mode screen — infinite wave survival with scaling difficulty
/// and high score tracking. Continuous night phase, no building, pure typing.
/// </summary>
public class EndlessModeScreen : GameScreen
{
    // Scoring constants per enemy tier
    private const int PointsMinion = 10;
    private const int PointsStandard = 25;
    private const int PointsElite = 50;
    private const int PointsBoss = 100;

    private const int StartingHp = 20;
    private const float RestDurationSeconds = 5f;

    // Visual renderers (shared types with BattlefieldScreen)
    private readonly BattleStageRenderer _battleStage = new();
    private readonly KeyboardOverlay _keyboardDisplay = new();

    // Game state — we create a dedicated state for endless mode
    private GameState _state = null!;

    // Endless mode tracking
    private int _wave;
    private int _score;
    private int _enemiesKilled;
    private int _totalCharsTyped;
    private int _totalErrors;
    private int _bestCombo;
    private bool _gameOver;
    private float _restTimer;
    private bool _resting;
    private int _enemiesRemainingInWave;

    // Enemy tracking for visual effects
    private int _prevEnemyCount;
    private List<string> _prevEnemyKinds = new();
    private HashSet<int> _prevEnemyIds = new();
    private int _prevHp;

    // Input
    private TypingInput? _typingHandler;
    private KeyboardState _prevKeyboard;

    // Myra UI
    private Desktop? _desktop;
    private Label? _waveLabel;
    private Label? _scoreLabel;
    private Label? _hpLabel;
    private Label? _enemyLabel;
    private Label? _wpmLabel;
    private Label? _comboLabel;
    private Label? _restLabel;
    private Label? _eventLog;
    private TextBox? _typingInput;

    private float _totalTime;

    public EndlessModeScreen(KeyboardDefenseGame game, ScreenManager screenManager)
        : base(game, screenManager) { }

    public override void OnEnter()
    {
        // Create a fresh game state for endless mode
        _state = new GameState
        {
            Hp = StartingHp,
            Phase = "night",
            Day = 1,
            RngSeed = "endless_" + DateTime.Now.Ticks,
        };
        SimRng.SeedState(_state, _state.RngSeed);
        TypingMetrics.InitBattleMetrics(_state);

        _wave = 0;
        _score = 0;
        _enemiesKilled = 0;
        _bestCombo = 0;
        _gameOver = false;
        _restTimer = 0f;
        _resting = false;
        _prevHp = _state.Hp;

        // Attach typing input
        _typingHandler = new TypingInput();
        _typingHandler.Attach(Game.Window);
        _typingHandler.CharTyped += OnCharTyped;

        // Initialize renderers
        _battleStage.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        _keyboardDisplay.Initialize(Game.GraphicsDevice, Game.DefaultFont);

        BuildUi();

        // Start first wave
        StartNextWave();

        SessionAnalytics.Instance.StartSession();
    }

    public override void OnExit()
    {
        if (_typingHandler != null)
        {
            _typingHandler.CharTyped -= OnCharTyped;
            _typingHandler.Detach(Game.Window);
        }
        _desktop = null;
    }

    public override void Update(GameTime gameTime)
    {
        if (_gameOver) return;

        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        _totalTime += dt;

        // Handle rest period between waves
        if (_resting)
        {
            _restTimer -= dt;
            if (_restLabel != null)
                _restLabel.Text = $"Next wave in {Math.Max(0, (int)Math.Ceiling(_restTimer))}s...";

            if (_restTimer <= 0f)
            {
                _resting = false;
                if (_restLabel != null) _restLabel.Text = "";
                StartNextWave();
            }

            UpdateRenderers(gameTime, dt);
            UpdateEffects(gameTime, dt);
            return;
        }

        // Process typing input
        _typingHandler?.ProcessInput();

        var kbState = Keyboard.GetState();
        if (kbState.IsKeyDown(Keys.Enter) && !_prevKeyboard.IsKeyDown(Keys.Enter))
            SubmitInput();
        if (kbState.IsKeyDown(Keys.Escape) && !_prevKeyboard.IsKeyDown(Keys.Escape))
            OnRetreat();
        _prevKeyboard = kbState;

        // Update expected key for keyboard display
        string prompt = _state.NightPrompt;
        if (!string.IsNullOrEmpty(prompt))
            _keyboardDisplay.SetExpectedChar(prompt[0]);
        else if (_state.Enemies.Count > 0)
        {
            string firstWord = _state.Enemies[0].GetValueOrDefault("word")?.ToString() ?? "";
            if (firstWord.Length > 0)
                _keyboardDisplay.SetExpectedChar(firstWord[0]);
        }

        // Detect enemy kills for visual effects
        DetectEnemyChanges();

        // Check wave complete
        if (_state.NightSpawnRemaining <= 0 && _state.Enemies.Count == 0 && !_resting)
        {
            AudioManager.Instance.PlaySfx(AudioManager.Sfx.WaveComplete);
            AppendLog($"Wave {_wave} cleared!");
            _resting = true;
            _restTimer = RestDurationSeconds;
        }

        UpdateRenderers(gameTime, dt);
        UpdateEffects(gameTime, dt);
        RefreshHud();
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        var vp = Game.GraphicsDevice.Viewport;
        var shakeOffset = ScreenShake.Instance.Offset;

        // Draw battle stage
        _battleStage.Draw(spriteBatch, _state);

        // Draw damage numbers and hit effects
        DamageNumbers.Instance.Draw(spriteBatch, Game.DefaultFont);
        HitEffects.Instance.Draw(spriteBatch);

        // Draw keyboard display
        int kbHeight = _keyboardDisplay.TotalHeight;
        int battleH = vp.Height - 260 - kbHeight;
        float kbY = Math.Max(200, battleH) + 10;
        _keyboardDisplay.Draw(spriteBatch, new Vector2(vp.Width * 0.5f - 220 + shakeOffset.X, kbY + shakeOffset.Y));

        // Draw Myra UI
        _desktop?.Render();

        // Scene transition overlay
        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }

    private void BuildUi()
    {
        var rootPanel = new Panel();
        var mainLayout = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };

        // Top HUD bar
        var hudBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceLg };

        _waveLabel = new Label { Text = "Wave: 1", TextColor = ThemeColors.GoldAccent };
        _scoreLabel = new Label { Text = "Score: 0", TextColor = ThemeColors.Accent };
        _hpLabel = new Label { Text = $"HP: {StartingHp}", TextColor = ThemeColors.Success };
        _enemyLabel = new Label { Text = "Enemies: 0", TextColor = ThemeColors.Error };
        _wpmLabel = new Label { Text = "WPM: 0", TextColor = ThemeColors.AccentCyan };
        _comboLabel = new Label { Text = "", TextColor = ThemeColors.AccentBlue };

        hudBar.Widgets.Add(_waveLabel);
        hudBar.Widgets.Add(_scoreLabel);
        hudBar.Widgets.Add(_hpLabel);
        hudBar.Widgets.Add(_enemyLabel);
        hudBar.Widgets.Add(_wpmLabel);
        hudBar.Widgets.Add(_comboLabel);
        mainLayout.Widgets.Add(hudBar);

        mainLayout.Widgets.Add(new HorizontalSeparator());

        // Rest timer label (hidden when not resting)
        _restLabel = new Label
        {
            Text = "",
            TextColor = ThemeColors.Warning,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        mainLayout.Widgets.Add(_restLabel);

        // Event log
        _eventLog = new Label
        {
            Text = "",
            TextColor = ThemeColors.Text,
            Wrap = true,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };

        var scrollViewer = new ScrollViewer
        {
            Content = _eventLog,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        mainLayout.Widgets.Add(scrollViewer);

        mainLayout.Widgets.Add(new HorizontalSeparator());

        // Input area
        var inputRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        inputRow.Widgets.Add(new Label { Text = "> ", TextColor = ThemeColors.AccentCyan });

        _typingInput = new TextBox
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        inputRow.Widgets.Add(_typingInput);

        var submitBtn = new Button
        {
            Content = new Label { Text = "Submit" },
            Width = 100,
            Height = DesignSystem.SizeButtonMd,
        };
        submitBtn.Click += (_, _) => SubmitInput();
        inputRow.Widgets.Add(submitBtn);

        mainLayout.Widgets.Add(inputRow);

        // Bottom bar
        var bottomBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };

        var retreatBtn = new Button
        {
            Content = new Label { Text = "Retreat (Esc)" },
            Width = 120,
            Height = DesignSystem.SizeButtonSm,
        };
        retreatBtn.Click += (_, _) => OnRetreat();
        bottomBar.Widgets.Add(retreatBtn);

        mainLayout.Widgets.Add(bottomBar);

        rootPanel.Widgets.Add(mainLayout);
        _desktop = new Desktop { Root = rootPanel };
    }

    private void StartNextWave()
    {
        _wave++;
        int waveSize = EndlessMode.CalculateWaveSize(_wave, 0);
        _state.NightSpawnRemaining = waveSize;
        _state.NightWaveTotal = waveSize;
        _enemiesRemainingInWave = waveSize + _state.Enemies.Count;

        // Scale difficulty: every 5 waves, bump the "day" used for HP calculation
        _state.Day = _wave;

        AppendLog($"--- Wave {_wave} --- ({waveSize} enemies)");
        AudioManager.Instance.PlaySfx(AudioManager.Sfx.WaveStart);

        // Spawn first batch of enemies
        for (int i = 0; i < Math.Min(3, _state.NightSpawnRemaining); i++)
            SpawnEnemy();

        RefreshHud();
    }

    private void SpawnEnemy()
    {
        if (_state.NightSpawnRemaining <= 0) return;

        var usedWords = new HashSet<string>();
        foreach (var e in _state.Enemies)
        {
            string w = e.GetValueOrDefault("word")?.ToString() ?? "";
            if (!string.IsNullOrEmpty(w)) usedWords.Add(w);
        }

        string kind = PickEnemyKindForWave(_wave);
        string word = WordPool.WordForEnemy(_state.RngSeed, _wave, kind, _state.EnemyNextId, usedWords, _state.LessonId);

        // Scale HP based on endless wave
        var spawnPos = new GridPoint(_state.BasePos.X + 10, _state.BasePos.Y);
        var enemy = Enemies.MakeEnemy(_state, kind, spawnPos, word, _wave);

        // Apply endless scaling to HP
        int baseHp = Convert.ToInt32(enemy["hp"]);
        int scaledHp = EndlessMode.CalculateEnemyHp(_wave, baseHp);
        enemy["hp"] = scaledHp;
        enemy["max_hp"] = scaledHp;

        // Set distance for movement toward base
        enemy["dist"] = 8 + SimRng.RollRange(_state, 0, 4);
        enemy["damage"] = 1 + _wave / 10;
        enemy["gold"] = GetGoldForKind(kind);

        _state.Enemies.Add(enemy);
        _state.NightSpawnRemaining--;

        // Update NightPrompt to first enemy's word
        if (_state.Enemies.Count > 0)
        {
            string firstWord = _state.Enemies[0].GetValueOrDefault("word")?.ToString() ?? "";
            _state.NightPrompt = firstWord;
        }
    }

    private void SubmitInput()
    {
        if (_gameOver || _resting) return;

        string text = _typingInput?.Text?.Trim() ?? "";
        if (string.IsNullOrEmpty(text)) return;
        if (_typingInput != null) _typingInput.Text = "";

        string normalized = TypingFeedback.NormalizeInput(text);
        if (string.IsNullOrEmpty(normalized)) return;

        int targetIndex = FindEnemyByWord(normalized);
        if (targetIndex >= 0)
        {
            // Hit — attack the enemy
            AttackEnemy(targetIndex, normalized);

            // Fire projectile visual
            if (_state.Enemies.Count > 0 || targetIndex == 0)
            {
                var targetPos = _battleStage.GetEnemyPosition(
                    Math.Min(targetIndex, Math.Max(0, _state.Enemies.Count - 1)),
                    _state.Enemies.Count + 1);
                _battleStage.FireProjectile(_battleStage.CastlePosition, targetPos, ThemeColors.AccentCyan);
                AudioManager.Instance.PlaySfx(AudioManager.Sfx.TowerShot);
            }

            TypingMetrics.RecordWordCompleted(_state);
            SessionAnalytics.Instance.RecordEvent("word_typed");
        }
        else if (_state.Enemies.Count > 0)
        {
            // Miss
            TypingMetrics.RecordError(_state);
            _totalErrors++;
            AppendLog($"Miss! No enemy with word '{text}'.");
            AudioManager.Instance.PlaySfx(AudioManager.Sfx.TypeWrong);
        }

        // Spawn more enemies if available
        if (_state.NightSpawnRemaining > 0 && _state.Enemies.Count < 6)
            SpawnEnemy();

        // Enemy movement step
        EnemyMoveStep();

        // Check game over
        if (_state.Hp <= 0)
        {
            _gameOver = true;
            _state.Phase = "game_over";
            AudioManager.Instance.PlaySfx(AudioManager.Sfx.Defeat);
            AppendLog("GAME OVER!");
            ShowEndlessSummary();
            return;
        }

        // Update NightPrompt
        if (_state.Enemies.Count > 0)
        {
            string firstWord = _state.Enemies[0].GetValueOrDefault("word")?.ToString() ?? "";
            _state.NightPrompt = firstWord;
        }
        else
        {
            _state.NightPrompt = "";
        }

        // Update combo display
        int combo = TypingMetrics.GetComboCount(_state);
        _battleStage.SetCombo(combo);
        if (combo > _bestCombo) _bestCombo = combo;

        RefreshHud();
    }

    private void AttackEnemy(int targetIndex, string hitWord)
    {
        if (targetIndex < 0 || targetIndex >= _state.Enemies.Count) return;

        var enemy = _state.Enemies[targetIndex];
        int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", 1));
        int combo = TypingMetrics.GetComboCount(_state);
        double comboMult = TypingMetrics.GetComboMultiplier(combo);
        int damage = Math.Max(1, (int)(1 * comboMult));

        hp -= damage;
        enemy["hp"] = hp;
        _state.Enemies[targetIndex] = enemy;

        string kind = enemy.GetValueOrDefault("kind")?.ToString() ?? "";

        if (hp <= 0)
        {
            // Enemy killed
            int goldReward = Convert.ToInt32(enemy.GetValueOrDefault("gold", 1));
            int points = GetPointsForKind(kind);
            int comboBonus = (int)(points * (comboMult - 1.0));
            int totalPoints = points + comboBonus;

            _score += totalPoints;
            _enemiesKilled++;
            _state.EnemiesDefeated++;
            _state.Gold += goldReward;
            _state.Enemies.RemoveAt(targetIndex);

            string bonusText = comboBonus > 0 ? $" (+{comboBonus} combo)" : "";
            AppendLog($"Typed '{hitWord}' - {kind} defeated! +{totalPoints} pts{bonusText}");
            AudioManager.Instance.PlaySfx(AudioManager.Sfx.EnemyDeath);

            // Flash enemy ID for visual
            if (enemy.TryGetValue("id", out var idObj))
                _battleStage.FlashEnemy(Convert.ToInt32(idObj));
        }
        else
        {
            AppendLog($"Typed '{hitWord}' - {damage} damage to {kind}. HP: {hp}");
            AudioManager.Instance.PlaySfx(AudioManager.Sfx.EnemyHit);

            if (enemy.TryGetValue("id", out var idObj))
                _battleStage.FlashEnemy(Convert.ToInt32(idObj));
        }
    }

    private void EnemyMoveStep()
    {
        foreach (var enemy in _state.Enemies)
        {
            int dist = Convert.ToInt32(enemy.GetValueOrDefault("dist", 10));
            dist--;
            enemy["dist"] = dist;
            if (dist <= 0)
            {
                int dmg = Convert.ToInt32(enemy.GetValueOrDefault("damage", 1));
                _state.Hp -= dmg;
                AppendLog($"Enemy reached the castle! -{dmg} HP");
                AudioManager.Instance.PlaySfx(AudioManager.Sfx.EnemyReachBase);

                // Screen shake on damage
                if (dmg >= 3)
                    ScreenShake.Instance.ShakeHeavy();
                else
                    ScreenShake.Instance.ShakeMedium();

                DamageNumbers.Instance.SpawnDamage(_battleStage.CastlePosition, dmg);
                _battleStage.FlashCastle();
            }
        }
        _state.Enemies.RemoveAll(e => Convert.ToInt32(e.GetValueOrDefault("dist", 10)) <= 0);
    }

    private void DetectEnemyChanges()
    {
        var currentKinds = new List<string>(_state.Enemies.Count);
        foreach (var enemy in _state.Enemies)
            currentKinds.Add(enemy.GetValueOrDefault("kind")?.ToString() ?? "");

        int currentEnemyCount = _state.Enemies.Count;
        if (currentEnemyCount < _prevEnemyCount && _prevEnemyCount > 0)
        {
            int killed = _prevEnemyCount - currentEnemyCount;
            for (int i = 0; i < killed; i++)
            {
                var pos = _battleStage.GetEnemyPosition(currentEnemyCount + i, _prevEnemyCount);
                _battleStage.EnemyDeath(pos, ThemeColors.DamageRed);
                HitEffects.Instance.SpawnEnemyDeath(pos, ThemeColors.DamageRed);
            }
        }
        _prevEnemyCount = currentEnemyCount;
        _prevEnemyKinds = currentKinds;

        // Detect new spawns
        var currentIds = new HashSet<int>();
        foreach (var enemy in _state.Enemies)
        {
            if (enemy.TryGetValue("id", out var idObj))
            {
                int id = Convert.ToInt32(idObj);
                currentIds.Add(id);
                if (!_prevEnemyIds.Contains(id))
                    _battleStage.SpawnEnemy(id);
            }
        }
        _prevEnemyIds = currentIds;

        // Castle damage detection
        if (_prevHp > 0 && _state.Hp < _prevHp)
        {
            int damage = _prevHp - _state.Hp;
            if (damage >= 3)
                ScreenShake.Instance.ShakeHeavy();
            else
                ScreenShake.Instance.ShakeMedium();

            if (damage >= 5)
                HitPause.Instance.PauseMedium();

            DamageNumbers.Instance.SpawnDamage(_battleStage.CastlePosition, damage);
            HitEffects.Instance.SpawnDamageFlash(_battleStage.CastlePosition);
            _battleStage.FlashCastle();
        }
        _prevHp = _state.Hp;
    }

    private void UpdateRenderers(GameTime gameTime, float dt)
    {
        var vp = Game.GraphicsDevice.Viewport;
        int kbHeight = _keyboardDisplay.TotalHeight;
        int battleH = vp.Height - 260 - kbHeight;
        _battleStage.SetBounds(new Rectangle(0, 0, vp.Width, Math.Max(200, battleH)));
        _battleStage.Update(gameTime);
        _keyboardDisplay.Update(gameTime);
    }

    private void UpdateEffects(GameTime gameTime, float dt)
    {
        ScreenShake.Instance.Update(gameTime);
        HitPause.Instance.Update(gameTime);
        DamageNumbers.Instance.Update(gameTime);
        HitEffects.Instance.Update(gameTime);
        SceneTransition.Instance.Update(gameTime);
        NotificationManager.Instance.Update(dt);
    }

    private void RefreshHud()
    {
        if (_waveLabel != null) _waveLabel.Text = $"Wave: {_wave}";
        if (_scoreLabel != null) _scoreLabel.Text = $"Score: {_score}";
        if (_hpLabel != null)
        {
            _hpLabel.Text = $"HP: {_state.Hp}/{StartingHp}";
            float hpPct = (float)_state.Hp / StartingHp;
            _hpLabel.TextColor = hpPct > 0.5f ? ThemeColors.Success
                : hpPct > 0.25f ? ThemeColors.Warning
                : ThemeColors.Error;
        }
        if (_enemyLabel != null) _enemyLabel.Text = $"Enemies: {_state.Enemies.Count}";
        if (_wpmLabel != null)
        {
            double wpm = TypingMetrics.GetWpm(_state);
            _wpmLabel.Text = $"WPM: {wpm:F0}";
        }
        if (_comboLabel != null)
        {
            int combo = TypingMetrics.GetComboCount(_state);
            _comboLabel.Text = combo > 1 ? $"x{combo} COMBO" : "";
        }
    }

    private void OnRetreat()
    {
        if (!_gameOver)
            ShowEndlessSummary();
        else
            ScreenManager.Pop();
    }

    private void ShowEndlessSummary()
    {
        _gameOver = true;
        double wpm = TypingMetrics.GetWpm(_state);
        double accuracy = TypingMetrics.GetAccuracy(_state);

        // Calculate accuracy bonus
        int accuracyBonus = accuracy >= 0.95 ? (int)(_score * 0.2)
            : accuracy >= 0.9 ? (int)(_score * 0.1)
            : 0;
        int finalScore = _score + accuracyBonus;

        var summary = new EndlessSummaryScreen(
            Game, ScreenManager,
            _wave, finalScore, _enemiesKilled, wpm, accuracy, _bestCombo, accuracyBonus);
        ScreenManager.Push(summary);
    }

    private void OnCharTyped(char c)
    {
        _keyboardDisplay.FlashKey(c);
        TypingMetrics.RecordCharTyped(_state, c);
        _totalCharsTyped++;
        SessionAnalytics.Instance.RecordEvent("char_typed");
    }

    private void AppendLog(string message)
    {
        if (_eventLog == null) return;
        string current = _eventLog.Text ?? "";
        if (!string.IsNullOrEmpty(current))
            current += "\n";
        _eventLog.Text = current + message;
    }

    private int FindEnemyByWord(string input)
    {
        // Exact match
        for (int i = 0; i < _state.Enemies.Count; i++)
        {
            string word = _state.Enemies[i].GetValueOrDefault("word")?.ToString() ?? "";
            if (TypingFeedback.NormalizeInput(word) == input)
                return i;
        }
        // Prefix match fallback
        for (int i = 0; i < _state.Enemies.Count; i++)
        {
            string word = _state.Enemies[i].GetValueOrDefault("word")?.ToString() ?? "";
            if (TypingFeedback.NormalizeInput(word).StartsWith(input))
                return i;
        }
        return -1;
    }

    private string PickEnemyKindForWave(int wave)
    {
        // Progressively introduce tougher enemy types as waves increase
        if (wave <= 3)
        {
            // Early: only basic enemies
            string[] earlyKinds = { "scout", "raider", "swarm" };
            return earlyKinds[SimRng.RollRange(_state, 0, earlyKinds.Length - 1)];
        }
        if (wave <= 7)
        {
            // Mid-early: add armored and berserker
            string[] midKinds = { "scout", "raider", "swarm", "armored", "berserker" };
            return midKinds[SimRng.RollRange(_state, 0, midKinds.Length - 1)];
        }
        if (wave <= 15)
        {
            // Mid: add phantom, healer
            string[] midKinds = { "scout", "raider", "armored", "berserker", "phantom", "healer", "swarm" };
            return midKinds[SimRng.RollRange(_state, 0, midKinds.Length - 1)];
        }
        // Late: all types including elite, champion, tank
        string[] lateKinds = { "raider", "armored", "berserker", "phantom", "healer", "tank", "champion", "elite" };
        return lateKinds[SimRng.RollRange(_state, 0, lateKinds.Length - 1)];
    }

    private static int GetPointsForKind(string kind)
    {
        var def = EnemyTypes.Get(kind);
        if (def == null) return PointsMinion;
        return def.Tier switch
        {
            EnemyTypes.Tier.Minion => PointsMinion,
            EnemyTypes.Tier.Standard => PointsStandard,
            EnemyTypes.Tier.Elite => PointsElite,
            EnemyTypes.Tier.Boss => PointsBoss,
            _ => PointsMinion,
        };
    }

    private static int GetGoldForKind(string kind)
    {
        var def = EnemyTypes.Get(kind);
        return def?.Gold ?? 5;
    }
}

/// <summary>
/// Summary screen displayed after an endless mode run ends.
/// Shows wave reached, final score, enemies killed, WPM, accuracy.
/// </summary>
public class EndlessSummaryScreen : GameScreen
{
    private readonly int _waveReached;
    private readonly int _finalScore;
    private readonly int _enemiesKilled;
    private readonly double _wpm;
    private readonly double _accuracy;
    private readonly int _bestCombo;
    private readonly int _accuracyBonus;
    private Desktop? _desktop;
    private KeyboardState _prevKeyboard;

    public EndlessSummaryScreen(
        KeyboardDefenseGame game, ScreenManager screenManager,
        int waveReached, int finalScore, int enemiesKilled,
        double wpm, double accuracy, int bestCombo, int accuracyBonus)
        : base(game, screenManager)
    {
        _waveReached = waveReached;
        _finalScore = finalScore;
        _enemiesKilled = enemiesKilled;
        _wpm = wpm;
        _accuracy = accuracy;
        _bestCombo = bestCombo;
        _accuracyBonus = accuracyBonus;
    }

    public override void OnEnter()
    {
        BuildUi();
    }

    private void BuildUi()
    {
        var root = new VerticalStackPanel
        {
            Spacing = DesignSystem.SpaceLg,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Width = 500,
        };

        // Title
        root.Widgets.Add(new Label
        {
            Text = "ENDLESS MODE COMPLETE",
            TextColor = ThemeColors.GoldAccent,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        root.Widgets.Add(new HorizontalSeparator());

        // Final score (prominent)
        root.Widgets.Add(new Label
        {
            Text = $"Score: {_finalScore}",
            TextColor = ThemeColors.Accent,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        if (_accuracyBonus > 0)
        {
            root.Widgets.Add(new Label
            {
                Text = $"(includes +{_accuracyBonus} accuracy bonus)",
                TextColor = ThemeColors.AccentCyan,
                HorizontalAlignment = HorizontalAlignment.Center,
            });
        }

        root.Widgets.Add(new HorizontalSeparator());

        // Stats grid
        var statsGrid = new Grid
        {
            ColumnSpacing = DesignSystem.SpaceMd,
            RowSpacing = DesignSystem.SpaceXs,
        };
        statsGrid.ColumnsProportions.Add(new Proportion(ProportionType.Pixels, 200));
        statsGrid.ColumnsProportions.Add(new Proportion(ProportionType.Fill));

        AddStatRow(statsGrid, 0, "Wave Reached", $"{_waveReached}");
        AddStatRow(statsGrid, 1, "Enemies Killed", $"{_enemiesKilled}");
        AddStatRow(statsGrid, 2, "WPM", $"{_wpm:F1}");
        AddStatRow(statsGrid, 3, "Accuracy", $"{_accuracy * 100:F1}%");
        AddStatRow(statsGrid, 4, "Best Combo", $"x{_bestCombo}");

        root.Widgets.Add(statsGrid);

        root.Widgets.Add(new HorizontalSeparator());

        // Performance grade
        string grade = GetEndlessGrade(_finalScore);
        root.Widgets.Add(new Label
        {
            Text = $"Grade: {grade}",
            TextColor = GetGradeColor(grade),
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        root.Widgets.Add(new HorizontalSeparator());

        // Buttons
        var buttonRow = new HorizontalStackPanel
        {
            Spacing = DesignSystem.SpaceMd,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var retryBtn = ButtonFactory.Primary("Try Again", OnRetry);
        buttonRow.Widgets.Add(retryBtn);

        var menuBtn = ButtonFactory.Secondary("Main Menu", OnMainMenu);
        buttonRow.Widgets.Add(menuBtn);

        root.Widgets.Add(buttonRow);

        root.Widgets.Add(new Label
        {
            Text = "Press Enter to retry, Escape for main menu",
            TextColor = ThemeColors.TextDim,
            HorizontalAlignment = HorizontalAlignment.Center,
        });

        _desktop = new Desktop { Root = root };
    }

    private void AddStatRow(Grid grid, int row, string label, string value)
    {
        grid.RowsProportions.Add(new Proportion(ProportionType.Auto));

        grid.Widgets.Add(new Label
        {
            Text = label,
            TextColor = ThemeColors.TextDim,
            GridRow = row,
            GridColumn = 0,
        });

        grid.Widgets.Add(new Label
        {
            Text = value,
            TextColor = ThemeColors.Text,
            GridRow = row,
            GridColumn = 1,
        });
    }

    private static string GetEndlessGrade(int score)
    {
        if (score >= 5000) return "S";
        if (score >= 3000) return "A";
        if (score >= 1500) return "B";
        if (score >= 500) return "C";
        return "D";
    }

    private static Color GetGradeColor(string grade) => grade switch
    {
        "S" => ThemeColors.RarityLegendary,
        "A" => ThemeColors.RarityEpic,
        "B" => ThemeColors.RarityRare,
        "C" => ThemeColors.RarityUncommon,
        _ => ThemeColors.RarityCommon,
    };

    private void OnRetry()
    {
        // Pop summary, pop endless — push fresh endless
        ScreenManager.Pop();
        ScreenManager.Pop();
        ScreenManager.Push(new EndlessModeScreen(Game, ScreenManager));
    }

    private void OnMainMenu()
    {
        ScreenManager.Switch(new MainMenuScreen(Game, ScreenManager));
    }

    public override void Update(GameTime gameTime)
    {
        var kb = Keyboard.GetState();

        if (kb.IsKeyDown(Keys.Enter) && !_prevKeyboard.IsKeyDown(Keys.Enter))
            OnRetry();
        else if (kb.IsKeyDown(Keys.Escape) && !_prevKeyboard.IsKeyDown(Keys.Escape))
            OnMainMenu();

        _prevKeyboard = kb;
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        _desktop?.Render();
    }
}
