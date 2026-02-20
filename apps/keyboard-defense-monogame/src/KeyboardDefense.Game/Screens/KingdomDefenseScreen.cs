using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Game.Effects;
using KeyboardDefense.Game.Input;
using KeyboardDefense.Game.Rendering;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;
using KeyboardDefense.Game.UI.Components;

namespace KeyboardDefense.Game.Screens;

/// <summary>
/// Kingdom Defense mode - RTS with build/explore/night defense cycle.
/// Ported from game/kingdom_defense.gd.
/// </summary>
public class KingdomDefenseScreen : GameScreen
{
    private Desktop? _desktop;
    private Label? _phaseLabel;
    private Label? _hpLabel;
    private Label? _dayLabel;
    private Label? _goldLabel;
    private Label? _apLabel;
    private Label? _threatLabel;
    private Label? _eventLog;
    private TextBox? _commandInput;
    private TypingInput? _typingHandler;
    private PanelOverlay? _panelOverlay;

    private readonly GridRenderer _gridRenderer = new();
    private readonly MinimapRenderer _minimapRenderer = new();

    private BestiaryPanel? _bestiaryPanel;
    private StatsPanel? _statsPanel;
    private SettingsPanel? _settingsPanel;
    private SkillsPanel? _skillsPanel;
    private QuestsPanel? _questsPanel;
    private EquipmentPanel? _equipmentPanel;
    private ShopPanel? _shopPanel;
    private AchievementPanel? _achievementPanel;
    private LootPanel? _lootPanel;
    private HelpPanel? _helpPanel;
    private UpgradesPanel? _upgradesPanel;
    private TradePanel? _tradePanel;
    private CraftingPanel? _craftingPanel;
    private BuffsPanel? _buffsPanel;
    private InventoryPanel? _inventoryPanel;
    private DifficultyPanel? _difficultyPanel;
    private ExpeditionPanel? _expeditionPanel;
    private DiplomacyPanel? _diplomacyPanel;
    private ResearchPanel? _researchPanel;
    private CitizensPanel? _citizensPanel;
    private WorkersPanel? _workersPanel;
    private KeybindPanel? _keybindPanel;
    private DamageCalculatorPanel? _damageCalculatorPanel;
    private AutoTowerPanel? _autoTowerPanel;
    private DailyChallengesPanel? _dailyChallengesPanel;
    private TargetingPanel? _targetingPanel;

    private OnboardingOverlay? _onboarding;

    private KeyboardState _prevKeyboard;
    private bool _gameEnded;

    public KingdomDefenseScreen(KeyboardDefenseGame game, ScreenManager screenManager)
        : base(game, screenManager) { }

    public override void OnEnter()
    {
        _typingHandler = new TypingInput();
        _typingHandler.Attach(Game.Window);

        // Initialize renderers with graphics device and font
        _gridRenderer.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        _minimapRenderer.Initialize(Game.GraphicsDevice);

        // Start session analytics
        SessionAnalytics.Instance.StartSession();

        var ctrl = GameController.Instance;
        ctrl.NewGame($"kingdom_{DateTime.Now.Ticks}");
        ctrl.StateChanged += OnStateChanged;
        ctrl.EventsEmitted += OnEventsEmitted;

        BuildUi();
        OnStateChanged(ctrl.State);
        AppendLog(Locale.Tr("kingdom.started"));
        AppendLog(Locale.Tr("kingdom.commands_help"));
        AppendLog(Locale.Tr("kingdom.type_help"));

        // Start onboarding for first-time players
        _onboarding = new OnboardingOverlay();
        _onboarding.Start();
    }

    public override void OnExit()
    {
        _typingHandler?.Detach(Game.Window);
        var ctrl = GameController.Instance;
        ctrl.StateChanged -= OnStateChanged;
        ctrl.EventsEmitted -= OnEventsEmitted;
        _desktop = null;
        _panelOverlay = null;
    }

    public override void Update(GameTime gameTime)
    {
        _panelOverlay?.Update();

        if (_panelOverlay == null || !_panelOverlay.HasActivePanel)
        {
            _typingHandler?.ProcessInput();

            var kbState = Keyboard.GetState();
            if (KeybindManager.Instance.IsActionPressed("submit", kbState, _prevKeyboard))
            {
                SubmitCommand();
            }

            // Tab to dismiss onboarding overlay, Space to acknowledge current step
            if (kbState.IsKeyDown(Keys.Tab) && !_prevKeyboard.IsKeyDown(Keys.Tab))
                _onboarding?.Dismiss();
            if (kbState.IsKeyDown(Keys.Space) && !_prevKeyboard.IsKeyDown(Keys.Space))
                _onboarding?.Acknowledge();

            _prevKeyboard = kbState;
        }

        // Update onboarding and renderers
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        _gridRenderer.Update(dt);
        _onboarding?.Update(dt);
        _onboarding?.CheckState(GameController.Instance.State);

        ScreenShake.Instance.Update(gameTime);
        HitPause.Instance.Update(gameTime);
        DamageNumbers.Instance.Update(gameTime);
        HitEffects.Instance.Update(gameTime);
        SceneTransition.Instance.Update(gameTime);
        NotificationManager.Instance.Update((float)gameTime.ElapsedGameTime.TotalSeconds);

        _panelOverlay?.Toast.Update((float)gameTime.ElapsedGameTime.TotalSeconds);
        _panelOverlay?.Achievement.Update((float)gameTime.ElapsedGameTime.TotalSeconds);
        _panelOverlay?.Combo.Update((float)gameTime.ElapsedGameTime.TotalSeconds);
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        var vp = Game.GraphicsDevice.Viewport;
        var state = GameController.Instance.State;

        // Apply screen shake offset
        var shakeOffset = ScreenShake.Instance.Offset;
        var cameraTransform = Matrix.CreateTranslation(shakeOffset.X, shakeOffset.Y, 0);

        // Draw grid in the main area (offset below HUD)
        var gridArea = new Rectangle(0, 60, vp.Width - 220, vp.Height - 140);
        _gridRenderer.Origin = new Vector2(gridArea.X + 10, gridArea.Y + 10);
        _gridRenderer.Draw(spriteBatch, state, cameraTransform, gridArea);

        // Draw minimap in top-right corner
        spriteBatch.Begin(blendState: BlendState.AlphaBlend, samplerState: SamplerState.PointClamp);
        _minimapRenderer.Draw(spriteBatch, state, new Vector2(vp.Width - 210, 65));
        spriteBatch.End();

        // Draw damage numbers and hit effects
        DamageNumbers.Instance.Draw(spriteBatch, Game.DefaultFont, cameraTransform);
        HitEffects.Instance.Draw(spriteBatch, cameraTransform);

        // Draw Myra UI on top
        _desktop?.Render();

        // Draw panel overlays and onboarding on top of everything
        spriteBatch.Begin();
        _panelOverlay?.DrawOverlays(spriteBatch, Game.DefaultFont, vp.Width, vp.Height);
        _onboarding?.Draw(spriteBatch, Game.DefaultFont, vp.Width, vp.Height);
        spriteBatch.End();

        // Draw scene transition overlay
        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }

    private void BuildUi()
    {
        var rootPanel = new Panel();
        var mainLayout = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };

        // Top HUD
        var hudBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        _dayLabel = new Label { Text = $"{Locale.Tr("game.day")} 1", TextColor = ThemeColors.Accent };
        _phaseLabel = new Label { Text = $"{Locale.Tr("game.phase")}: day", TextColor = ThemeColors.AccentCyan };
        _hpLabel = new Label { Text = $"{Locale.Tr("resources.hp")}: 20", TextColor = ThemeColors.Success };
        _apLabel = new Label { Text = $"{Locale.Tr("resources.ap")}: 3", TextColor = ThemeColors.AccentBlue };
        _goldLabel = new Label { Text = $"{Locale.Tr("resources.gold")}: 0", TextColor = ThemeColors.ResourceGold };
        _threatLabel = new Label { Text = $"{Locale.Tr("hud.threat")}: 0", TextColor = ThemeColors.Threat };

        hudBar.Widgets.Add(_dayLabel);
        hudBar.Widgets.Add(_phaseLabel);
        hudBar.Widgets.Add(_hpLabel);
        hudBar.Widgets.Add(_apLabel);
        hudBar.Widgets.Add(_goldLabel);
        hudBar.Widgets.Add(_threatLabel);
        mainLayout.Widgets.Add(hudBar);
        mainLayout.Widgets.Add(new HorizontalSeparator());

        // Event log area
        _eventLog = new Label
        {
            Text = "",
            TextColor = ThemeColors.Text,
            Wrap = true,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        var scrollViewer = new ScrollViewer
        {
            Content = _eventLog,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        mainLayout.Widgets.Add(scrollViewer);
        mainLayout.Widgets.Add(new HorizontalSeparator());

        // Command input
        var inputRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        inputRow.Widgets.Add(new Label { Text = "> ", TextColor = ThemeColors.AccentCyan });
        _commandInput = new TextBox { HorizontalAlignment = HorizontalAlignment.Stretch };
        inputRow.Widgets.Add(_commandInput);

        var submitBtn = new Button
        {
            Content = new Label { Text = Locale.Tr("actions.submit") },
            Width = 100,
            Height = DesignSystem.SizeButtonMd,
        };
        submitBtn.Click += (_, _) => SubmitCommand();
        inputRow.Widgets.Add(submitBtn);
        mainLayout.Widgets.Add(inputRow);

        // Action buttons (row 1)
        var actionBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };

        void AddBtn(string label, Action action, int width = 90)
        {
            var btn = new Button
            {
                Content = new Label { Text = label },
                Width = width,
                Height = DesignSystem.SizeButtonSm,
            };
            btn.Click += (_, _) => action();
            actionBar.Widgets.Add(btn);
        }

        AddBtn(Locale.Tr("actions.explore"), () => GameController.Instance.ApplyCommand("explore"));
        AddBtn(Locale.Tr("actions.end_day"), () => GameController.Instance.ApplyCommand("end"));
        AddBtn(Locale.Tr("actions.status"), () => GameController.Instance.ApplyCommand("status"));
        AddBtn(Locale.Tr("ui.help"), () => GameController.Instance.ApplyCommand("help"));
        AddBtn(Locale.Tr("actions.retreat"), () => ScreenManager.Pop());
        mainLayout.Widgets.Add(actionBar);

        // Panel buttons (row 2)
        var panelBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };

        void AddPanelBtn(string label, BasePanel panel, int width = 90)
        {
            var btn = new Button
            {
                Content = new Label { Text = label },
                Width = width,
                Height = DesignSystem.SizeButtonSm,
            };
            btn.Click += (_, _) => _panelOverlay?.OpenPanel(panel);
            panelBar.Widgets.Add(btn);
        }

        // Create panels
        _helpPanel = new HelpPanel();
        _bestiaryPanel = new BestiaryPanel();
        _statsPanel = new StatsPanel();
        _settingsPanel = new SettingsPanel();
        _skillsPanel = new SkillsPanel();
        _questsPanel = new QuestsPanel();
        _equipmentPanel = new EquipmentPanel();
        _shopPanel = new ShopPanel();
        _achievementPanel = new AchievementPanel();
        _lootPanel = new LootPanel();
        _upgradesPanel = new UpgradesPanel();
        _tradePanel = new TradePanel();
        _craftingPanel = new CraftingPanel();
        _buffsPanel = new BuffsPanel();
        _inventoryPanel = new InventoryPanel();
        _difficultyPanel = new DifficultyPanel();
        _expeditionPanel = new ExpeditionPanel();
        _diplomacyPanel = new DiplomacyPanel();
        _researchPanel = new ResearchPanel();
        _citizensPanel = new CitizensPanel();
        _workersPanel = new WorkersPanel();
        _keybindPanel = new KeybindPanel();
        _damageCalculatorPanel = new DamageCalculatorPanel();
        _autoTowerPanel = new AutoTowerPanel();
        _dailyChallengesPanel = new DailyChallengesPanel();
        _targetingPanel = new TargetingPanel();

        AddPanelBtn(Locale.Tr("panels.bestiary"), _bestiaryPanel);
        AddPanelBtn(Locale.Tr("panels.skills"), _skillsPanel);
        AddPanelBtn(Locale.Tr("panels.quests"), _questsPanel);
        AddPanelBtn(Locale.Tr("panels.equipment"), _equipmentPanel);
        AddPanelBtn(Locale.Tr("panels.shop"), _shopPanel);
        AddPanelBtn(Locale.Tr("panels.loot"), _lootPanel);
        mainLayout.Widgets.Add(panelBar);

        // Panel buttons (row 3: kingdom management)
        var mgmtBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        void AddMgmtBtn(string label, BasePanel panel, int width = 90)
        {
            var btn = new Button
            {
                Content = new Label { Text = label },
                Width = width,
                Height = DesignSystem.SizeButtonSm,
            };
            btn.Click += (_, _) => _panelOverlay?.OpenPanel(panel);
            mgmtBar.Widgets.Add(btn);
        }
        AddMgmtBtn(Locale.Tr("panels.expeditions"), _expeditionPanel, 100);
        AddMgmtBtn(Locale.Tr("panels.diplomacy"), _diplomacyPanel);
        AddMgmtBtn(Locale.Tr("panels.research"), _researchPanel);
        AddMgmtBtn(Locale.Tr("panels.citizens"), _citizensPanel);
        AddMgmtBtn(Locale.Tr("panels.workers"), _workersPanel);
        AddMgmtBtn(Locale.Tr("panels.key_bindings"), _keybindPanel);
        AddMgmtBtn(Locale.Tr("panels.damage_calculator"), _damageCalculatorPanel, 110);
        AddMgmtBtn(Locale.Tr("panels.auto_tower"), _autoTowerPanel);
        AddMgmtBtn(Locale.Tr("panels.daily_challenges"), _dailyChallengesPanel, 110);
        {
            var targetBtn = new Button
            {
                Content = new Label { Text = Locale.Tr("panels.targeting") },
                Width = 90,
                Height = DesignSystem.SizeButtonSm,
            };
            targetBtn.Click += (_, _) =>
            {
                _targetingPanel?.Refresh(GameController.Instance.State);
                _panelOverlay?.OpenPanel(_targetingPanel!);
            };
            mgmtBar.Widgets.Add(targetBtn);
        }
        mainLayout.Widgets.Add(mgmtBar);

        rootPanel.Widgets.Add(mainLayout);
        _desktop = new Desktop { Root = rootPanel };

        // Set up panel overlay with rebindable hotkeys
        _panelOverlay = new PanelOverlay(_desktop);
        _panelOverlay.Bind("panel_help", _helpPanel);
        _panelOverlay.Bind("panel_settings", _settingsPanel);
        _panelOverlay.Bind("panel_stats", _statsPanel);
        _panelOverlay.Bind("panel_bestiary", _bestiaryPanel);
        _panelOverlay.Bind("panel_skills", _skillsPanel);
        _panelOverlay.Bind("panel_quests", _questsPanel);
        _panelOverlay.Bind("panel_equipment", _equipmentPanel);
        _panelOverlay.Bind("panel_shop", _shopPanel);
        _panelOverlay.Bind("panel_achievements", _achievementPanel);
        _panelOverlay.Bind("panel_buffs", _buffsPanel);
        _panelOverlay.Bind("panel_inventory", _inventoryPanel);
        _panelOverlay.Bind("panel_difficulty", _difficultyPanel);

        // Kingdom management panels
        _panelOverlay.Bind("panel_expeditions", _expeditionPanel);
        _panelOverlay.Bind("panel_diplomacy", _diplomacyPanel);
        _panelOverlay.Bind("panel_research", _researchPanel);
        _panelOverlay.Bind("panel_citizens", _citizensPanel);
        _panelOverlay.Bind("panel_workers", _workersPanel);
        _panelOverlay.Bind("panel_keybinds", _keybindPanel);
        _panelOverlay.Bind("panel_damage_calc", _damageCalculatorPanel);
        _panelOverlay.Bind("panel_auto_tower", _autoTowerPanel);
        _panelOverlay.Bind("panel_daily_challenges", _dailyChallengesPanel);
        _panelOverlay.Bind("panel_targeting", _targetingPanel);
    }

    private void SubmitCommand()
    {
        string text = _commandInput?.Text?.Trim() ?? "";
        if (string.IsNullOrEmpty(text)) return;
        if (_commandInput != null) _commandInput.Text = "";

        // Track chars typed for analytics
        SessionAnalytics.Instance.RecordEvent("char_typed", text.Length);

        var state = GameController.Instance.State;
        if (state.Phase == "night")
        {
            var intent = SimIntents.Make("defend_input", new() { ["text"] = text });
            GameController.Instance.ApplyIntent(intent);
            SessionAnalytics.Instance.OnGameEvent(GameController.Instance.LastEvents);
            SessionAnalytics.Instance.RecordEvent("word_typed");
        }
        else
        {
            GameController.Instance.ApplyCommand(text);
            SessionAnalytics.Instance.OnGameEvent(GameController.Instance.LastEvents);

            // Track onboarding flags from commands
            if (text.Equals("help", StringComparison.OrdinalIgnoreCase))
                _onboarding?.SetFlag("used_help");
            if (text.StartsWith("gather", StringComparison.OrdinalIgnoreCase))
                _onboarding?.SetFlag("did_gather");
            if (text.StartsWith("build", StringComparison.OrdinalIgnoreCase))
                _onboarding?.SetFlag("did_build");
        }

        CheckGameEnd();
    }

    private void CheckGameEnd()
    {
        if (_gameEnded) return;

        var state = GameController.Instance.State;
        if (state.Phase == "victory")
        {
            _gameEnded = true;
            ScreenManager.Push(new RunSummaryScreen(Game, ScreenManager, isVictory: true));
        }
        else if (state.Phase == "game_over")
        {
            _gameEnded = true;
            ScreenManager.Push(new RunSummaryScreen(Game, ScreenManager, isVictory: false));
        }
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
        if (_apLabel != null) _apLabel.Text = $"{Locale.Tr("resources.ap")}: {state.Ap}";
        if (_goldLabel != null) _goldLabel.Text = $"{Locale.Tr("resources.gold")}: {state.Gold}";
        if (_threatLabel != null) _threatLabel.Text = $"{Locale.Tr("hud.threat")}: {state.Threat}";
    }

    private void OnEventsEmitted(List<string> events)
    {
        foreach (string evt in events) AppendLog(evt);
    }

    private void AppendLog(string message)
    {
        if (_eventLog == null) return;
        string current = _eventLog.Text ?? "";
        if (!string.IsNullOrEmpty(current)) current += "\n";
        _eventLog.Text = current + message;
    }
}
