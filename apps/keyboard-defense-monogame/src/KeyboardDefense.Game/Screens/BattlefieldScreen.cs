using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Game.Audio;
using KeyboardDefense.Game.Effects;
using KeyboardDefense.Game.Input;
using KeyboardDefense.Game.Rendering;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;
using KeyboardDefense.Game.UI.Components;

namespace KeyboardDefense.Game.Screens;

/// <summary>
/// Main battlefield screen where typing combat happens.
/// Ported from scripts/Battlefield.gd and scripts/BattleStage.gd.
/// </summary>
public class BattlefieldScreen : GameScreen
{
    private readonly int _nodeIndex;
    private readonly string _nodeName;
    private readonly bool _singleWaveMode;
    private readonly bool _returnToCampaignMapOnSummary;
    private readonly string _verticalSliceProfileId;
    private readonly string _campaignNodeId;
    private readonly int _campaignNodeRewardGold;
    private VerticalSliceWaveConfig? _verticalSliceConfig;

    private Desktop? _desktop;
    private Label? _phaseLabel;
    private Label? _hpLabel;
    private Label? _dayLabel;
    private Label? _goldLabel;
    private Label? _enemyLabel;
    private Label? _waveLabel;
    private Label? _promptLabel;
    private Label? _timerLabel;
    private Label? _typingStatsLabel;
    private Label? _eventLog;
    private TextBox? _typingInput;
    private TypingInput? _typingHandler;
    private PanelOverlay? _panelOverlay;

    private BestiaryPanel? _bestiaryPanel;
    private StatsPanel? _statsPanel;
    private SettingsPanel? _settingsPanel;
    private QuestsPanel? _questsPanel;
    private AchievementPanel? _achievementPanel;
    private SaveLoadPanel? _saveLoadPanel;
    private HelpPanel? _helpPanel;
    private UpgradesPanel? _upgradesPanel;
    private TradePanel? _tradePanel;
    private CraftingPanel? _craftingPanel;
    private BuffsPanel? _buffsPanel;
    private InventoryPanel? _inventoryPanel;
    private DifficultyPanel? _difficultyPanel;
    private DamageCalculatorPanel? _damageCalculatorPanel;
    private SpellPanel? _spellPanel;
    private TargetingPanel? _targetingPanel;

    private readonly BattleStageRenderer _battleStage = new();
    private readonly Rendering.KeyboardOverlay _keyboardDisplay = new();
    private BattleTutorial? _battleTutorial;

    private float _totalTime;
    private int _prevEnemyCount;
    private List<string> _prevEnemyKinds = new();
    private bool _gameEnded;
    private bool _singleWaveNightStarted;
    private bool _singleWavePaused;
    private readonly List<string> _earnedMilestones = new();
    private HashSet<int> _prevEnemyIds = new();
    private int _prevHp;
    private KeyboardState _prevKeyboard;

    public BattlefieldScreen(
        KeyboardDefenseGame game,
        ScreenManager screenManager,
        int nodeIndex,
        string nodeName,
        bool singleWaveMode = false,
        bool returnToCampaignMapOnSummary = false,
        string verticalSliceProfileId = "vertical_slice_default",
        string campaignNodeId = "",
        int campaignNodeRewardGold = 0,
        CampaignProgressionService.CampaignSummaryHandoff? campaignSummaryHandoff = null)
        : base(game, screenManager)
    {
        _nodeIndex = nodeIndex;
        _nodeName = nodeName;
        _singleWaveMode = singleWaveMode;
        _verticalSliceProfileId = verticalSliceProfileId;
        var handoff = campaignSummaryHandoff ?? CampaignProgressionService.CampaignSummaryHandoff.Create(
            returnToCampaignMapOnSummary,
            campaignNodeId,
            campaignNodeRewardGold);
        _returnToCampaignMapOnSummary = handoff.ReturnToCampaignMapOnSummary;
        _campaignNodeId = handoff.CampaignNodeId;
        _campaignNodeRewardGold = handoff.CampaignNodeRewardGold;
    }

    public override void OnEnter()
    {
        _typingHandler = new TypingInput();
        _typingHandler.Attach(Game.Window);
        _typingHandler.CharTyped += OnCharTyped;

        // Initialize visual renderers
        _battleStage.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        _keyboardDisplay.Initialize(Game.GraphicsDevice, Game.DefaultFont);

        BuildUi();

        // Start session analytics
        SessionAnalytics.Instance.StartSession();

        // Reset spell cooldowns for this battle
        SpellSystem.Instance.Reset();

        // Start the game in day phase
        var ctrl = GameController.Instance;
        ctrl.StateChanged += OnStateChanged;
        ctrl.EventsEmitted += OnEventsEmitted;

        // Initial state refresh
        OnStateChanged(ctrl.State);
        AppendLog($"{_nodeName} - {Locale.Tr("game.day")} {ctrl.State.Day}");
        AppendLog(Locale.Tr("battle.day_phase_help"));

        if (_singleWaveMode)
        {
            var profile = VerticalSliceWaveData.GetProfile(_verticalSliceProfileId);
            _verticalSliceConfig = VerticalSliceWaveConfig.FromProfile(profile);
            var state = ctrl.State;
            state.Day = profile.StartDay;
            state.Hp = profile.StartHp;
            state.Gold = profile.StartGold;
            state.Threat = profile.StartThreat;
            state.LessonId = profile.LessonId;
            state.PracticeMode = profile.PracticeMode;

            AppendLog("Vertical Slice: survive one night wave.");
            AppendLog($"Profile: {_verticalSliceProfileId} ({profile.WaveSpawnTotal} enemies)");
            AppendLog("Controls: Enter submit, P pause/resume, R restart.");
            if (_verticalSliceConfig != null && ctrl.State.Phase == "day")
            {
                var startEvents = new List<string>();
                VerticalSliceWaveSim.StartSingleWave(ctrl.State, _verticalSliceConfig, startEvents);
                foreach (string evt in startEvents)
                    AppendLog(evt);
                SessionAnalytics.Instance.OnGameEvent(startEvents);
                OnStateChanged(ctrl.State);
                _singleWaveNightStarted = true;
            }
        }
        else
        {
            // Start battle tutorial for first-time players
            _battleTutorial = new BattleTutorial();
            _battleTutorial.Start();
        }
    }

    public override void OnExit()
    {
        if (_typingHandler != null)
        {
            _typingHandler.CharTyped -= OnCharTyped;
            _typingHandler.Detach(Game.Window);
        }
        var ctrl = GameController.Instance;
        ctrl.StateChanged -= OnStateChanged;
        ctrl.EventsEmitted -= OnEventsEmitted;
        _desktop = null;
        _panelOverlay = null;
    }

    public override void Update(GameTime gameTime)
    {
        _totalTime += (float)gameTime.ElapsedGameTime.TotalSeconds;

        _panelOverlay?.Update();

        // Process typing input only when no panel is active
        if (_panelOverlay == null || !_panelOverlay.HasActivePanel)
        {
            var kbState = Keyboard.GetState();
            if (_singleWaveMode && HandleSingleWaveControlInput(kbState))
            {
                _prevKeyboard = kbState;
            }
            else
            {
                if (!_singleWavePaused)
                    _typingHandler?.ProcessInput();

                // Tutorial controls take priority when active
                if (_battleTutorial != null && _battleTutorial.IsActive)
                {
                    if (kbState.IsKeyDown(Keys.Escape) && !_prevKeyboard.IsKeyDown(Keys.Escape))
                        _battleTutorial.Skip();
                    else if (kbState.IsKeyDown(Keys.Enter) && !_prevKeyboard.IsKeyDown(Keys.Enter))
                        _battleTutorial.AdvanceDialogue();
                    else if (kbState.IsKeyDown(Keys.Space) && !_prevKeyboard.IsKeyDown(Keys.Space))
                        _battleTutorial.AdvanceDialogue();
                }
                else if (!_singleWavePaused && KeybindManager.Instance.IsActionPressed("submit", kbState, _prevKeyboard))
                {
                    SubmitInput();
                }
            }

            _prevKeyboard = kbState;
        }

        // Apply game speed multiplier
        float speedMul = GameController.Instance.State.SpeedMultiplier;
        if (speedMul <= 0f) speedMul = 1f;

        // Tick spell cooldowns
        SpellSystem.Instance.UpdateCooldowns((float)gameTime.ElapsedGameTime.TotalSeconds * speedMul);

        if (_singleWaveMode && _verticalSliceConfig != null && !_gameEnded && !_singleWavePaused)
            RunVerticalSliceStep((float)gameTime.ElapsedGameTime.TotalSeconds * speedMul, null);

        // Update visual renderers
        var vp = Game.GraphicsDevice.Viewport;
        int kbHeight = _keyboardDisplay.TotalHeight;
        int battleH = vp.Height - 260 - kbHeight;
        _battleStage.SetBounds(new Rectangle(0, 0, vp.Width, Math.Max(200, battleH)));
        _battleStage.Update(gameTime, speedMul);
        _keyboardDisplay.Update(gameTime);

        // Detect enemy kills for visual effects and bestiary tracking
        var state = GameController.Instance.State;
        var currentKinds = new List<string>(state.Enemies.Count);
        foreach (var enemy in state.Enemies)
            currentKinds.Add(enemy.GetValueOrDefault("kind")?.ToString() ?? "");

        int currentEnemyCount = state.Enemies.Count;
        if (currentEnemyCount < _prevEnemyCount && _prevEnemyCount > 0)
        {
            // Identify which enemy kinds were killed by diffing previous vs current
            var remainingKinds = new List<string>(currentKinds);
            foreach (string kind in _prevEnemyKinds)
            {
                if (!remainingKinds.Remove(kind))
                {
                    // This kind was in prev but not current — it was killed
                    if (!string.IsNullOrEmpty(kind))
                        _bestiaryPanel?.RecordKill(kind);
                }
            }

            // Trigger visual effects
            int killed = _prevEnemyCount - currentEnemyCount;
            for (int i = 0; i < killed; i++)
            {
                var pos = _battleStage.GetEnemyPosition(currentEnemyCount + i, _prevEnemyCount);
                _battleStage.EnemyDeath(pos, ThemeColors.DamageRed);
                HitEffects.Instance.SpawnEnemyDeath(pos, ThemeColors.DamageRed);
                DamageNumbers.Instance.SpawnGold(pos, 5);
            }
        }
        _prevEnemyCount = currentEnemyCount;
        _prevEnemyKinds = currentKinds;

        // Detect new enemy spawns for animation
        var currentIds = new HashSet<int>();
        foreach (var enemy in state.Enemies)
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

        // Update expected key for keyboard display
        string prompt = state.NightPrompt;
        if (!string.IsNullOrEmpty(prompt))
            _keyboardDisplay.SetExpectedChar(prompt[0]);

        ScreenShake.Instance.Update(gameTime);
        HitPause.Instance.Update(gameTime);
        DamageNumbers.Instance.Update(gameTime);
        HitEffects.Instance.Update(gameTime);
        SceneTransition.Instance.Update(gameTime);
        NotificationManager.Instance.Update((float)gameTime.ElapsedGameTime.TotalSeconds);

        _panelOverlay?.Toast.Update((float)gameTime.ElapsedGameTime.TotalSeconds);
        _panelOverlay?.Achievement.Update((float)gameTime.ElapsedGameTime.TotalSeconds);
        _panelOverlay?.Combo.Update((float)gameTime.ElapsedGameTime.TotalSeconds);
        _battleTutorial?.Update((float)gameTime.ElapsedGameTime.TotalSeconds);

        CheckGameEnd();
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        var vp = Game.GraphicsDevice.Viewport;
        var state = GameController.Instance.State;

        // Apply screen shake
        var shakeOffset = ScreenShake.Instance.Offset;

        // Draw battle stage (top area)
        _battleStage.Draw(spriteBatch, state);

        // Draw damage numbers and hit effects
        DamageNumbers.Instance.Draw(spriteBatch, Game.DefaultFont);
        HitEffects.Instance.Draw(spriteBatch);

        // Draw keyboard display below battle stage
        int kbHeight = _keyboardDisplay.TotalHeight;
        int battleH = vp.Height - 260 - kbHeight;
        float kbY = Math.Max(200, battleH) + 10;
        _keyboardDisplay.Draw(spriteBatch, new Vector2(vp.Width * 0.5f - 220 + shakeOffset.X, kbY + shakeOffset.Y));

        // Draw Myra UI on top (HUD, event log, input)
        _desktop?.Render();

        // Draw panel overlays and tutorial
        spriteBatch.Begin();
        _panelOverlay?.DrawOverlays(spriteBatch, Game.DefaultFont, vp.Width, vp.Height);
        _battleTutorial?.Draw(spriteBatch, Game.DefaultFont, vp.Width, vp.Height);
        if (_singleWaveMode && _singleWavePaused)
            DrawSingleWavePauseOverlay(spriteBatch, vp.Width, vp.Height);
        spriteBatch.End();

        // Scene transition
        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }

    private void BuildUi()
    {
        var rootPanel = new Panel();
        var mainLayout = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };

        // Top HUD bar
        var hudBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceLg };
        _dayLabel = new Label { Text = $"{Locale.Tr("game.day")} 1", TextColor = ThemeColors.Accent };
        _phaseLabel = new Label { Text = $"{Locale.Tr("game.phase")}: day", TextColor = ThemeColors.AccentCyan };
        _hpLabel = new Label { Text = $"{Locale.Tr("resources.hp")}: 20", TextColor = ThemeColors.Success };
        _goldLabel = new Label { Text = $"{Locale.Tr("resources.gold")}: 0", TextColor = ThemeColors.ResourceGold };
        _enemyLabel = new Label { Text = $"{Locale.Tr("hud.enemies")}: 0", TextColor = ThemeColors.Error };

        hudBar.Widgets.Add(_dayLabel);
        hudBar.Widgets.Add(_phaseLabel);
        hudBar.Widgets.Add(_hpLabel);
        hudBar.Widgets.Add(_goldLabel);
        hudBar.Widgets.Add(_enemyLabel);
        mainLayout.Widgets.Add(hudBar);

        if (_singleWaveMode)
        {
            var sliceHudBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
            _waveLabel = new Label { Text = "Wave: 0/0", TextColor = ThemeColors.AccentBlue };
            _promptLabel = new Label { Text = "Prompt: -", TextColor = ThemeColors.TextDim };
            _timerLabel = new Label { Text = "Time: 0:00", TextColor = ThemeColors.AccentCyan };
            _typingStatsLabel = new Label { Text = "Words: 0  Misses: 0", TextColor = ThemeColors.TextDim };

            sliceHudBar.Widgets.Add(_waveLabel);
            sliceHudBar.Widgets.Add(_promptLabel);
            sliceHudBar.Widgets.Add(_timerLabel);
            sliceHudBar.Widgets.Add(_typingStatsLabel);
            mainLayout.Widgets.Add(sliceHudBar);
        }

        mainLayout.Widgets.Add(new HorizontalSeparator());

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
            Content = new Label { Text = Locale.Tr("actions.submit") },
            Width = 100,
            Height = DesignSystem.SizeButtonMd,
        };
        submitBtn.Click += (_, _) => SubmitInput();
        inputRow.Widgets.Add(submitBtn);

        mainLayout.Widgets.Add(inputRow);

        // Bottom: action buttons
        var bottomBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };

        void AddBtn(string label, Action action, int width = 80)
        {
            var btn = new Button
            {
                Content = new Label { Text = label },
                Width = width,
                Height = DesignSystem.SizeButtonSm,
            };
            btn.Click += (_, _) => action();
            bottomBar.Widgets.Add(btn);
        }

        AddBtn(Locale.Tr("actions.retreat"), () => ScreenManager.Pop(), 100);
        AddBtn(Locale.Tr("ui.help"), () => _panelOverlay?.OpenPanel(_helpPanel!));
        AddBtn(Locale.Tr("actions.status"), () => GameController.Instance.ApplyCommand("status"));
        AddBtn(Locale.Tr("panels.bestiary"), () => _panelOverlay?.OpenPanel(_bestiaryPanel!));
        AddBtn(Locale.Tr("ui.stats"), () => _panelOverlay?.OpenPanel(_statsPanel!));
        AddBtn(Locale.Tr("panels.save_load"), () => _panelOverlay?.OpenPanel(_saveLoadPanel!), 100);
        AddBtn(Locale.Tr("panels.upgrades"), () => _panelOverlay?.OpenPanel(_upgradesPanel!));
        AddBtn(Locale.Tr("panels.trade"), () => _panelOverlay?.OpenPanel(_tradePanel!));
        AddBtn(Locale.Tr("panels.damage_calculator"), () => _panelOverlay?.OpenPanel(_damageCalculatorPanel!), 100);
        AddBtn(Locale.Tr("panels.spells"), () => _panelOverlay?.OpenPanel(_spellPanel!));
        AddBtn(Locale.Tr("panels.targeting"), () =>
        {
            _targetingPanel?.Refresh(GameController.Instance.State);
            _panelOverlay?.OpenPanel(_targetingPanel!);
        });

        mainLayout.Widgets.Add(bottomBar);

        rootPanel.Widgets.Add(mainLayout);
        _desktop = new Desktop { Root = rootPanel };

        // Set up panel overlay with hotkeys
        _panelOverlay = new PanelOverlay(_desktop);
        _helpPanel = new HelpPanel();
        _bestiaryPanel = new BestiaryPanel();
        _statsPanel = new StatsPanel();
        _settingsPanel = new SettingsPanel();
        _questsPanel = new QuestsPanel();
        _achievementPanel = new AchievementPanel();
        _saveLoadPanel = new SaveLoadPanel();
        _upgradesPanel = new UpgradesPanel();
        _tradePanel = new TradePanel();
        _craftingPanel = new CraftingPanel();
        _buffsPanel = new BuffsPanel();
        _inventoryPanel = new InventoryPanel();
        _difficultyPanel = new DifficultyPanel();
        _damageCalculatorPanel = new DamageCalculatorPanel();
        _spellPanel = new SpellPanel();
        _targetingPanel = new TargetingPanel();

        _panelOverlay.Bind("panel_help", _helpPanel);
        _panelOverlay.Bind("panel_settings", _settingsPanel);
        _panelOverlay.Bind("panel_stats", _statsPanel);
        _panelOverlay.Bind("panel_bestiary", _bestiaryPanel);
        _panelOverlay.Bind(Keys.F5, _saveLoadPanel);
        _panelOverlay.Bind("panel_quests", _questsPanel);
        _panelOverlay.Bind(Keys.F7, _upgradesPanel);
        _panelOverlay.Bind(Keys.F8, _tradePanel);
        _panelOverlay.Bind("panel_achievements", _achievementPanel);
        _panelOverlay.Bind("panel_buffs", _buffsPanel);
        _panelOverlay.Bind("panel_inventory", _inventoryPanel);
        _panelOverlay.Bind("panel_difficulty", _difficultyPanel);
        _panelOverlay.Bind("panel_damage_calc", _damageCalculatorPanel);
        _panelOverlay.Bind("panel_spells", _spellPanel);
        _panelOverlay.Bind("panel_targeting", _targetingPanel);
    }

    private void SubmitInput()
    {
        if (_singleWaveMode && _singleWavePaused)
            return;

        string text = _typingInput?.Text?.Trim() ?? "";
        if (string.IsNullOrEmpty(text)) return;

        if (_typingInput != null)
            _typingInput.Text = "";

        if (_singleWaveMode && _verticalSliceConfig != null)
        {
            RunVerticalSliceStep(0f, text);
            SessionAnalytics.Instance.RecordEvent("word_typed");
            CheckGameEnd();
            return;
        }

        var state = GameController.Instance.State;

        // Check if input matches a spell keyword before normal processing
        if (state.Phase == "night" && SpellSystem.IsSpellKeyword(text))
        {
            var (success, message) = SpellSystem.Instance.TryCast(state, text);
            if (!string.IsNullOrEmpty(message))
                AppendLog(message);
            if (success)
            {
                SessionAnalytics.Instance.RecordEvent("spell_cast");
                _spellPanel?.Refresh(state);
            }
            CheckGameEnd();
            return;
        }

        if (state.Phase == "night")
        {
            // Fire projectile toward nearest enemy on submit
            if (state.Enemies.Count > 0)
            {
                var targetPos = _battleStage.GetEnemyPosition(0, state.Enemies.Count);
                _battleStage.FireProjectile(_battleStage.CastlePosition, targetPos, ThemeColors.AccentCyan);
                AudioManager.Instance.PlaySfx(AudioManager.Sfx.TowerShot);

                // Flash the targeted enemy
                if (state.Enemies[0].TryGetValue("id", out var idObj))
                    _battleStage.FlashEnemy(Convert.ToInt32(idObj));
            }

            var intent = SimIntents.Make("defend_input", new() { ["text"] = text });
            GameController.Instance.ApplyIntent(intent);
            SessionAnalytics.Instance.OnGameEvent(GameController.Instance.LastEvents);
            SessionAnalytics.Instance.RecordEvent("word_typed");
            _battleTutorial?.FireTrigger("first_word_typed");
        }
        else
        {
            GameController.Instance.ApplyCommand(text);
            SessionAnalytics.Instance.OnGameEvent(GameController.Instance.LastEvents);
        }

        CheckGameEnd();
    }

    private void RunVerticalSliceStep(float deltaSeconds, string? typedInput)
    {
        if (!_singleWaveMode || _verticalSliceConfig == null || _gameEnded)
            return;

        var events = new List<string>();
        VerticalSliceWaveSim.Step(
            GameController.Instance.State,
            _verticalSliceConfig,
            deltaSeconds,
            typedInput,
            events);

        if (events.Count > 0)
        {
            foreach (string evt in events)
                AppendLog(evt);
            SessionAnalytics.Instance.OnGameEvent(events);
        }

        OnStateChanged(GameController.Instance.State);
    }

    private bool HandleSingleWaveControlInput(KeyboardState kbState)
    {
        if (!_singleWaveMode || _gameEnded)
            return false;

        if (IsKeyPressed(kbState, Keys.P))
        {
            _singleWavePaused = !_singleWavePaused;
            AppendLog(_singleWavePaused ? "Paused." : "Resumed.");
            return true;
        }

        if (_singleWavePaused && IsKeyPressed(kbState, Keys.Enter))
        {
            _singleWavePaused = false;
            AppendLog("Resumed.");
            return true;
        }

        if (IsKeyPressed(kbState, Keys.R))
        {
            RestartSingleWaveRun();
            return true;
        }

        return false;
    }

    private bool IsKeyPressed(KeyboardState current, Keys key)
    {
        return current.IsKeyDown(key) && !_prevKeyboard.IsKeyDown(key);
    }

    private void RestartSingleWaveRun()
    {
        if (_gameEnded)
            return;

        _gameEnded = true;
        AppendLog("Restarting vertical slice...");

        SceneTransition.Instance.BattleTransition(() =>
        {
            string seedPrefix = _returnToCampaignMapOnSummary ? "campaign_retry" : "vertical_slice";
            GameController.Instance.NewGame($"{seedPrefix}_{DateTime.UtcNow.Ticks}");
            ScreenManager.Pop();
            ScreenManager.Push(new BattlefieldScreen(
                Game,
                ScreenManager,
                _nodeIndex,
                _nodeName,
                singleWaveMode: true,
                verticalSliceProfileId: _verticalSliceProfileId,
                campaignSummaryHandoff: BuildCampaignSummaryHandoff()));
        });
    }

    private void CheckGameEnd()
    {
        if (_gameEnded) return;

        var state = GameController.Instance.State;
        if (_singleWaveMode)
        {
            if (state.Phase == "game_over")
            {
                _gameEnded = true;
                var milestones = Milestones.CheckNewMilestones(state);
                _earnedMilestones.AddRange(milestones);
                ScreenManager.Push(new RunSummaryScreen(
                    Game,
                    ScreenManager,
                    isVictory: false,
                    nodeIndex: _nodeIndex,
                    nodeName: _nodeName,
                    returnToCampaignMapOnSummary: _returnToCampaignMapOnSummary,
                    verticalSliceProfileId: _verticalSliceProfileId,
                    campaignSummaryHandoff: BuildCampaignSummaryHandoff()));
                return;
            }

            if (_singleWaveNightStarted &&
                state.Phase == "day" &&
                state.NightSpawnRemaining <= 0 &&
                state.Enemies.Count == 0)
            {
                _gameEnded = true;
                var milestones = Milestones.CheckNewMilestones(state);
                _earnedMilestones.AddRange(milestones);
                ScreenManager.Push(new RunSummaryScreen(
                    Game,
                    ScreenManager,
                    isVictory: true,
                    nodeIndex: _nodeIndex,
                    nodeName: _nodeName,
                    returnToCampaignMapOnSummary: _returnToCampaignMapOnSummary,
                    verticalSliceProfileId: _verticalSliceProfileId,
                    campaignSummaryHandoff: BuildCampaignSummaryHandoff()));
                return;
            }
        }

        if (state.Phase == "victory")
        {
            _gameEnded = true;
            var milestones = Milestones.CheckNewMilestones(state);
            _earnedMilestones.AddRange(milestones);
            var screen = new VictoryScreen(Game, ScreenManager, _nodeIndex, _nodeName, state, _earnedMilestones);
            ScreenManager.Push(screen);
            ScreenManager.Push(new RunSummaryScreen(Game, ScreenManager, isVictory: true));
        }
        else if (state.Phase == "game_over")
        {
            _gameEnded = true;
            var milestones = Milestones.CheckNewMilestones(state);
            _earnedMilestones.AddRange(milestones);
            var screen = new DefeatScreen(Game, ScreenManager, _nodeIndex, _nodeName, state, _earnedMilestones);
            ScreenManager.Push(screen);
            ScreenManager.Push(new RunSummaryScreen(Game, ScreenManager, isVictory: false));
        }
    }

    private void OnCharTyped(char c)
    {
        _keyboardDisplay.FlashKey(c);
        SessionAnalytics.Instance.RecordEvent("char_typed");
    }

    private void OnStateChanged(GameState state)
    {
        if (_dayLabel != null) _dayLabel.Text = $"{Locale.Tr("game.day")} {state.Day}";
        if (_phaseLabel != null) _phaseLabel.Text = $"{Locale.Tr("game.phase")}: {state.Phase}";
        if (_hpLabel != null)
        {
            _hpLabel.Text = $"{Locale.Tr("resources.hp")}: {state.Hp}";
            _hpLabel.TextColor = state.Hp > 10 ? ThemeColors.Success : state.Hp > 5 ? ThemeColors.Warning : ThemeColors.Error;
        }
        if (_goldLabel != null) _goldLabel.Text = $"{Locale.Tr("resources.gold")}: {state.Gold}";
        if (_enemyLabel != null) _enemyLabel.Text = $"{Locale.Tr("hud.enemies")}: {state.Enemies.Count}";

        if (_singleWaveMode)
        {
            if (_phaseLabel != null)
                _phaseLabel.Text = $"{Locale.Tr("game.phase")}: {state.Phase} (single-wave)";

            int total = Math.Max(0, state.NightWaveTotal);
            int spawned = Math.Max(0, total - state.NightSpawnRemaining);
            if (_waveLabel != null)
                _waveLabel.Text = $"Wave: {spawned}/{total}  Active: {state.Enemies.Count}";

            string promptText = string.IsNullOrEmpty(state.NightPrompt) ? "-" : state.NightPrompt;
            if (_promptLabel != null)
                _promptLabel.Text = $"Prompt: {promptText}";

            float runClock = ReadMetricFloat(state, "vs_run_clock_sec", 0f);
            if (_timerLabel != null)
                _timerLabel.Text = $"Time: {FormatSeconds(runClock)}";

            int wordsTyped = ReadMetricInt(state, "battle_words_typed", 0);
            int misses = ReadMetricInt(state, "vs_miss_count", 0);
            if (_typingStatsLabel != null)
                _typingStatsLabel.Text = $"Words: {wordsTyped}  Misses: {misses}";
        }

        // Screen shake on castle damage
        if (_prevHp > 0 && state.Hp < _prevHp)
        {
            int damage = _prevHp - state.Hp;
            if (damage >= 3)
                ScreenShake.Instance.ShakeHeavy();
            else
                ScreenShake.Instance.ShakeMedium();

            // Hit pause on big damage
            if (damage >= 5)
                HitPause.Instance.PauseMedium();

            // Visual effect at castle
            DamageNumbers.Instance.SpawnDamage(_battleStage.CastlePosition, damage);
            HitEffects.Instance.SpawnDamageFlash(_battleStage.CastlePosition);
            _battleStage.FlashCastle();

            _battleTutorial?.FireTrigger("castle_damaged");
        }
        _prevHp = state.Hp;

        // Update combo display
        int combo = TypingMetrics.GetComboCount(state);
        _battleStage.SetCombo(combo);
        SessionAnalytics.Instance.RecordEvent("combo", combo);

        // Check milestones on state change
        var newMilestones = Milestones.CheckNewMilestones(state);
        foreach (string m in newMilestones)
        {
            _earnedMilestones.Add(m);
            var def = Milestones.GetMilestone(m);
            if (def != null)
                AppendLog($"Milestone: {def.Name} - {def.Description}");
        }

        // Tutorial triggers based on state
        if (state.Threat > 0)
            _battleTutorial?.FireTrigger("threat_shown");
        if (state.MaxComboEver > 0)
            _battleTutorial?.FireTrigger("combo_achieved");
        if (state.Phase == "night" && state.NightSpawnRemaining == 0 && state.Enemies.Count <= 2)
            _battleTutorial?.FireTrigger("near_victory");
    }

    private void OnEventsEmitted(List<string> events)
    {
        foreach (string evt in events)
            AppendLog(evt);
    }

    private void AppendLog(string message)
    {
        if (_eventLog == null) return;
        string current = _eventLog.Text ?? "";
        if (!string.IsNullOrEmpty(current))
            current += "\n";
        _eventLog.Text = current + message;
    }

    private static string FormatSeconds(float value)
    {
        int total = Math.Max(0, (int)MathF.Floor(value));
        int minutes = total / 60;
        int seconds = total % 60;
        return $"{minutes}:{seconds:D2}";
    }

    private static int ReadMetricInt(GameState state, string key, int fallback = 0)
    {
        if (!state.TypingMetrics.TryGetValue(key, out var value) || value == null)
            return fallback;
        if (value is int i)
            return i;
        return int.TryParse(value.ToString(), out int parsed) ? parsed : fallback;
    }

    private static float ReadMetricFloat(GameState state, string key, float fallback = 0f)
    {
        if (!state.TypingMetrics.TryGetValue(key, out var value) || value == null)
            return fallback;
        if (value is float f)
            return f;
        if (value is double d)
            return (float)d;
        return float.TryParse(value.ToString(), out float parsed) ? parsed : fallback;
    }

    private CampaignProgressionService.CampaignSummaryHandoff BuildCampaignSummaryHandoff()
    {
        return CampaignProgressionService.CampaignSummaryHandoff.Create(
            _returnToCampaignMapOnSummary,
            _campaignNodeId,
            _campaignNodeRewardGold);
    }

    private void DrawSingleWavePauseOverlay(SpriteBatch spriteBatch, int width, int height)
    {
        const string title = "PAUSED";
        const string subtitle = "Press P or Enter to resume, R to restart";

        var font = Game.DefaultFont;
        var titleSize = font.MeasureString(title);
        var subtitleSize = font.MeasureString(subtitle);

        var titlePos = new Vector2((width - titleSize.X) * 0.5f, height * 0.45f);
        var subtitlePos = new Vector2((width - subtitleSize.X) * 0.5f, titlePos.Y + 34f);

        spriteBatch.DrawString(font, title, titlePos, ThemeColors.Accent);
        spriteBatch.DrawString(font, subtitle, subtitlePos, ThemeColors.Text);
    }
}
