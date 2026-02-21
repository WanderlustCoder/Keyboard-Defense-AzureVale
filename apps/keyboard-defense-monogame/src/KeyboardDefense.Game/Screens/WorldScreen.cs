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
using KeyboardDefense.Core.World;
using KeyboardDefense.Game.Effects;
using KeyboardDefense.Game.Input;
using KeyboardDefense.Game.Rendering;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;
using KeyboardDefense.Game.UI.Components;

namespace KeyboardDefense.Game.Screens;

/// <summary>
/// Open-world screen with WASD avatar movement, camera follow,
/// terrain rendering, WorldTick integration, building placement,
/// resource harvesting, and day/night cycle.
/// </summary>
public class WorldScreen : GameScreen
{
    private Desktop? _desktop;
    private PanelOverlay? _panelOverlay;
    private TypingInput? _typingHandler;
    private TextBox? _typingInput;
    private Label? _eventLog;

    // HUD labels
    private Label? _dayLabel;
    private Label? _hpLabel;
    private Label? _goldLabel;
    private Label? _threatLabel;
    private Label? _zoneLabel;
    private Label? _timeLabel;
    private Label? _modeLabel;

    // Renderers
    private readonly WorldCamera _camera = new();
    private readonly GridRenderer _gridRenderer = new();
    private readonly MinimapRenderer _minimapRenderer = new();
    private readonly PlayerRenderer _playerRenderer = new();
    private readonly DayNightOverlay _dayNightOverlay = new();

    // Panels
    private HelpPanel? _helpPanel;
    private SettingsPanel? _settingsPanel;
    private StatsPanel? _statsPanel;
    private BestiaryPanel? _bestiaryPanel;
    private UpgradesPanel? _upgradesPanel;
    private InventoryPanel? _inventoryPanel;
    private SaveLoadPanel? _saveLoadPanel;

    // Movement
    private KeyboardState _prevKeyboard;
    private float _moveRepeatTimer;
    private const float MoveRepeatDelay = 0.15f;
    private const float MoveRepeatRate = 0.08f;
    private bool _moveHeld;
    private int _heldDx;
    private int _heldDy;

    // Building placement
    private bool _buildMode;
    private int _buildMenuIndex;
    private static readonly string[] BuildMenuItems =
        { "wall", "tower", "farm", "lumber", "quarry", "market", "barracks" };

    public WorldScreen(KeyboardDefenseGame game, ScreenManager screenManager)
        : base(game, screenManager) { }

    public override void OnEnter()
    {
        _typingHandler = new TypingInput();
        _typingHandler.Attach(Game.Window);

        // Initialize renderers
        _gridRenderer.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        _minimapRenderer.Initialize(Game.GraphicsDevice);
        _playerRenderer.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        _playerRenderer.CellSize = _gridRenderer.CellSize;
        _dayNightOverlay.Initialize(Game.GraphicsDevice);

        var state = GameController.Instance.State;
        var vp = Game.GraphicsDevice.Viewport;
        _camera.Initialize(vp.Width, vp.Height, state.MapW, state.MapH, _gridRenderer.CellSize);
        _camera.SnapTo(state.PlayerPos.X, state.PlayerPos.Y);

        // Start session analytics
        SessionAnalytics.Instance.StartSession();

        var ctrl = GameController.Instance;
        ctrl.StateChanged += OnStateChanged;
        ctrl.EventsEmitted += OnEventsEmitted;

        BuildUi();
        OnStateChanged(ctrl.State);
        AppendLog("You awaken at the castle. Use WASD to explore. E to interact. B to build.");
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
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        var state = GameController.Instance.State;

        _panelOverlay?.Update();

        if (_panelOverlay == null || !_panelOverlay.HasActivePanel)
        {
            var kb = Keyboard.GetState();

            if (_buildMode)
            {
                HandleBuildInput(kb);
            }
            else if (state.ActivityMode == "exploration")
            {
                HandleMovementInput(kb, dt);
                HandleExplorationActions(kb);
            }
            else if (state.ActivityMode == "encounter" || state.ActivityMode == "wave_assault"
                     || state.ActivityMode == "harvest_challenge")
            {
                _typingHandler?.ProcessInput();
                if (KeybindManager.Instance.IsActionPressed("submit", kb, _prevKeyboard))
                    SubmitTyping();

                // Escape cancels harvest challenge
                if (state.ActivityMode == "harvest_challenge" && IsKeyPressed(kb, Keys.Escape))
                {
                    ResourceChallenge.CancelChallenge(state);
                    AppendLog("Harvest cancelled.");
                }
            }

            _prevKeyboard = kb;
        }

        // WorldTick drives time, threat, encounters
        var tickResult = WorldTick.Tick(state, dt);
        if (tickResult.TryGetValue("events", out var eventsObj) && eventsObj is List<string> events)
        {
            foreach (string evt in events)
                AppendLog(evt);
        }

        // Tick resource node cooldowns
        ResourceChallenge.TickCooldowns(state, dt);

        // Update camera
        var vp = Game.GraphicsDevice.Viewport;
        _camera.SetViewport(vp.Width, vp.Height);
        _camera.Follow(state.PlayerPos.X, state.PlayerPos.Y, dt);

        // Update renderers
        _gridRenderer.Update(dt);
        _playerRenderer.Update(dt);

        // Update HUD
        OnStateChanged(state);

        ScreenShake.Instance.Update(gameTime);
        SceneTransition.Instance.Update(gameTime);
        NotificationManager.Instance.Update(dt);

        _panelOverlay?.Toast.Update(dt);
        _panelOverlay?.Achievement.Update(dt);
        _panelOverlay?.Combo.Update(dt);
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        var vp = Game.GraphicsDevice.Viewport;
        var state = GameController.Instance.State;
        var shakeOffset = ScreenShake.Instance.Offset;

        // Camera transform with screen shake
        var cameraTransform = _camera.GetTransform()
            * Matrix.CreateTranslation(shakeOffset.X, shakeOffset.Y, 0);

        // Draw grid (terrain, structures, enemies)
        _gridRenderer.Draw(spriteBatch, state, cameraTransform, new Rectangle(0, 0, vp.Width, vp.Height));

        // Draw player avatar on top of grid
        spriteBatch.Begin(
            transformMatrix: cameraTransform,
            samplerState: SamplerState.PointClamp,
            blendState: BlendState.AlphaBlend);
        _playerRenderer.Draw(spriteBatch, state.PlayerPos.X, state.PlayerPos.Y, state.PlayerFacing);
        spriteBatch.End();

        // Day/night overlay
        _dayNightOverlay.Draw(spriteBatch, state.TimeOfDay, vp.Width, vp.Height);

        // Draw minimap in top-right corner
        spriteBatch.Begin(blendState: BlendState.AlphaBlend, samplerState: SamplerState.PointClamp);
        _minimapRenderer.Draw(spriteBatch, state, new Vector2(vp.Width - 210, 10));
        spriteBatch.End();

        // Draw Myra UI (HUD overlay)
        _desktop?.Render();

        // Draw panel overlays
        spriteBatch.Begin();
        _panelOverlay?.DrawOverlays(spriteBatch, Game.DefaultFont, vp.Width, vp.Height);
        spriteBatch.End();

        // Scene transition overlay
        SceneTransition.Instance.Draw(spriteBatch, new Rectangle(0, 0, vp.Width, vp.Height));
    }

    private void HandleMovementInput(KeyboardState kb, float dt)
    {
        int dx = 0, dy = 0;

        if (kb.IsKeyDown(Keys.W) || kb.IsKeyDown(Keys.Up)) dy = -1;
        else if (kb.IsKeyDown(Keys.S) || kb.IsKeyDown(Keys.Down)) dy = 1;
        else if (kb.IsKeyDown(Keys.A) || kb.IsKeyDown(Keys.Left)) dx = -1;
        else if (kb.IsKeyDown(Keys.D) || kb.IsKeyDown(Keys.Right)) dx = 1;

        if (dx == 0 && dy == 0)
        {
            _moveHeld = false;
            _moveRepeatTimer = 0f;
            return;
        }

        // New direction or first press
        if (!_moveHeld || dx != _heldDx || dy != _heldDy)
        {
            _moveHeld = true;
            _heldDx = dx;
            _heldDy = dy;
            _moveRepeatTimer = MoveRepeatDelay;
            ApplyMovePlayer(dx, dy);
            return;
        }

        // Held — repeat after delay
        _moveRepeatTimer -= dt;
        if (_moveRepeatTimer <= 0)
        {
            _moveRepeatTimer = MoveRepeatRate;
            ApplyMovePlayer(dx, dy);
        }
    }

    private void HandleExplorationActions(KeyboardState kb)
    {
        // B = toggle build mode
        if (IsKeyPressed(kb, Keys.B))
        {
            _buildMode = true;
            _buildMenuIndex = 0;
            AppendLog("BUILD MODE: Use Left/Right to select, Enter to place, Escape to cancel.");
            AppendLog($"Selected: {BuildMenuItems[_buildMenuIndex]}");
            return;
        }

        // E = interact (NPC first, then harvest resource node)
        if (IsKeyPressed(kb, Keys.E))
        {
            var state = GameController.Instance.State;

            // Try NPC interaction first
            var npcResult = NpcInteraction.TryInteract(state);
            if (npcResult != null)
            {
                if (npcResult.GetValueOrDefault("lines") is List<string> lines)
                {
                    foreach (string line in lines)
                        AppendLog(line);
                }
                // Auto-complete ready quests when talking to NPCs
                var questEvents = NpcInteraction.CompleteReadyQuests(state);
                foreach (string evt in questEvents)
                    AppendLog(evt);
                return;
            }

            // Then try resource harvest
            var harvestResult = ResourceChallenge.StartChallenge(state);
            if (harvestResult != null)
            {
                string nodeName = harvestResult.GetValueOrDefault("node_name")?.ToString() ?? "node";
                string word = harvestResult.GetValueOrDefault("word")?.ToString() ?? "";
                AppendLog($"Harvesting {nodeName}! Type: {word}");
            }
            else
            {
                AppendLog("Nothing to interact with here.");
            }
        }
    }

    private void HandleBuildInput(KeyboardState kb)
    {
        // Escape exits build mode
        if (IsKeyPressed(kb, Keys.Escape))
        {
            _buildMode = false;
            AppendLog("Build mode cancelled.");
            return;
        }

        // Left/Right cycle building selection
        if (IsKeyPressed(kb, Keys.Left) || IsKeyPressed(kb, Keys.A))
        {
            _buildMenuIndex = (_buildMenuIndex - 1 + BuildMenuItems.Length) % BuildMenuItems.Length;
            AppendLog($"Selected: {BuildMenuItems[_buildMenuIndex]}");
        }
        else if (IsKeyPressed(kb, Keys.Right) || IsKeyPressed(kb, Keys.D))
        {
            _buildMenuIndex = (_buildMenuIndex + 1) % BuildMenuItems.Length;
            AppendLog($"Selected: {BuildMenuItems[_buildMenuIndex]}");
        }

        // Enter/Space places the building at player position
        if (IsKeyPressed(kb, Keys.Enter) || IsKeyPressed(kb, Keys.Space))
        {
            string building = BuildMenuItems[_buildMenuIndex];
            var state = GameController.Instance.State;
            var intent = SimIntents.Make("build", new()
            {
                ["building"] = building,
                ["x"] = state.PlayerPos.X,
                ["y"] = state.PlayerPos.Y,
            });
            GameController.Instance.ApplyIntent(intent);
            _buildMode = false;
        }
    }

    private bool IsKeyPressed(KeyboardState kb, Keys key)
    {
        return kb.IsKeyDown(key) && !_prevKeyboard.IsKeyDown(key);
    }

    private void ApplyMovePlayer(int dx, int dy)
    {
        var intent = SimIntents.Make("move_player", new()
        {
            ["dx"] = dx,
            ["dy"] = dy,
        });
        GameController.Instance.ApplyIntent(intent);
    }

    private void SubmitTyping()
    {
        string text = _typingInput?.Text?.Trim() ?? "";
        if (string.IsNullOrEmpty(text)) return;
        if (_typingInput != null) _typingInput.Text = "";

        var state = GameController.Instance.State;

        if (state.ActivityMode == "encounter")
        {
            var events = InlineCombat.ProcessTyping(state, text);
            foreach (string evt in events)
                AppendLog(evt);
            SessionAnalytics.Instance.RecordEvent("word_typed");
        }
        else if (state.ActivityMode == "harvest_challenge")
        {
            var events = ResourceChallenge.ProcessChallengeInput(state, text);
            foreach (string evt in events)
                AppendLog(evt);
            SessionAnalytics.Instance.RecordEvent("word_typed");
        }
        else if (state.ActivityMode == "wave_assault")
        {
            var intent = SimIntents.Make("defend_input", new() { ["text"] = text });
            GameController.Instance.ApplyIntent(intent);
            SessionAnalytics.Instance.OnGameEvent(GameController.Instance.LastEvents);
            SessionAnalytics.Instance.RecordEvent("word_typed");
        }
    }

    private void BuildUi()
    {
        var rootPanel = new Panel();
        var mainLayout = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };

        // Top HUD bar
        var hudBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        _dayLabel = new Label { Text = "Day 1", TextColor = ThemeColors.Accent };
        _hpLabel = new Label { Text = "HP: 10", TextColor = ThemeColors.Success };
        _goldLabel = new Label { Text = "Gold: 0", TextColor = ThemeColors.ResourceGold };
        _threatLabel = new Label { Text = "Threat: 0%", TextColor = ThemeColors.Threat };
        _zoneLabel = new Label { Text = "Zone: Safe", TextColor = ThemeColors.AccentCyan };
        _timeLabel = new Label { Text = "Time: Dawn", TextColor = ThemeColors.AccentBlue };
        _modeLabel = new Label { Text = "Exploring", TextColor = ThemeColors.Accent };

        hudBar.Widgets.Add(_dayLabel);
        hudBar.Widgets.Add(_hpLabel);
        hudBar.Widgets.Add(_goldLabel);
        hudBar.Widgets.Add(_threatLabel);
        hudBar.Widgets.Add(_zoneLabel);
        hudBar.Widgets.Add(_timeLabel);
        hudBar.Widgets.Add(_modeLabel);
        mainLayout.Widgets.Add(hudBar);
        mainLayout.Widgets.Add(new HorizontalSeparator());

        // Event log at bottom
        _eventLog = new Label
        {
            Text = "",
            TextColor = ThemeColors.Text,
            Wrap = true,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Bottom,
        };

        var scrollViewer = new ScrollViewer
        {
            Content = _eventLog,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Height = 100,
            VerticalAlignment = VerticalAlignment.Bottom,
        };

        // Typing input (shown during encounters/challenges)
        var inputRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        inputRow.Widgets.Add(new Label { Text = "> ", TextColor = ThemeColors.AccentCyan });
        _typingInput = new TextBox { HorizontalAlignment = HorizontalAlignment.Stretch };
        inputRow.Widgets.Add(_typingInput);
        var submitBtn = new Button
        {
            Content = new Label { Text = Locale.Tr("actions.submit") },
            Width = 100,
            Height = DesignSystem.SizeButtonMd,
        };
        submitBtn.Click += (_, _) => SubmitTyping();
        inputRow.Widgets.Add(submitBtn);

        // Bottom bar with action buttons
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

        AddBtn("Retreat", () => ScreenManager.Pop(), 80);
        AddBtn("Help", () => _panelOverlay?.OpenPanel(_helpPanel!));
        AddBtn("Status", () => GameController.Instance.ApplyCommand("status"));
        AddBtn("Save", () => _panelOverlay?.OpenPanel(_saveLoadPanel!));

        // Layout: HUD at top, grid takes center, log + input + buttons at bottom
        var bottomPanel = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        bottomPanel.VerticalAlignment = VerticalAlignment.Bottom;
        bottomPanel.Widgets.Add(scrollViewer);
        bottomPanel.Widgets.Add(inputRow);
        bottomPanel.Widgets.Add(bottomBar);

        rootPanel.Widgets.Add(mainLayout);
        rootPanel.Widgets.Add(bottomPanel);

        _desktop = new Desktop { Root = rootPanel };

        // Set up panels
        _panelOverlay = new PanelOverlay(_desktop);
        _helpPanel = new HelpPanel();
        _settingsPanel = new SettingsPanel();
        _statsPanel = new StatsPanel();
        _bestiaryPanel = new BestiaryPanel();
        _upgradesPanel = new UpgradesPanel();
        _inventoryPanel = new InventoryPanel();
        _saveLoadPanel = new SaveLoadPanel();

        _panelOverlay.Bind("panel_help", _helpPanel);
        _panelOverlay.Bind("panel_settings", _settingsPanel);
        _panelOverlay.Bind("panel_stats", _statsPanel);
        _panelOverlay.Bind("panel_bestiary", _bestiaryPanel);
        _panelOverlay.Bind(Keys.F5, _saveLoadPanel);
        _panelOverlay.Bind(Keys.F7, _upgradesPanel);
        _panelOverlay.Bind("panel_inventory", _inventoryPanel);
    }

    private void OnStateChanged(GameState state)
    {
        if (_dayLabel != null) _dayLabel.Text = $"Day {state.Day}";
        if (_hpLabel != null)
        {
            _hpLabel.Text = $"HP: {state.Hp}";
            _hpLabel.TextColor = state.Hp > 10 ? ThemeColors.Success : state.Hp > 5 ? ThemeColors.Warning : ThemeColors.Error;
        }
        if (_goldLabel != null) _goldLabel.Text = $"Gold: {state.Gold}";
        if (_threatLabel != null) _threatLabel.Text = $"Threat: {(int)(state.ThreatLevel * 100)}%";
        if (_zoneLabel != null)
        {
            string zone = SimMap.GetZoneAt(state, state.PlayerPos);
            _zoneLabel.Text = $"Zone: {SimMap.GetZoneName(zone)}";
        }
        if (_timeLabel != null) _timeLabel.Text = $"Time: {GetTimeOfDayName(state.TimeOfDay)}";
        if (_modeLabel != null) _modeLabel.Text = state.ActivityMode switch
        {
            "exploration" => _buildMode ? "BUILD MODE" : "Exploring",
            "encounter" => "COMBAT!",
            "wave_assault" => "WAVE ASSAULT!",
            "harvest_challenge" => "HARVESTING",
            _ => state.ActivityMode,
        };
    }

    private static string GetTimeOfDayName(float time) => time switch
    {
        < 0.15f => "Night",
        < 0.30f => "Dawn",
        < 0.70f => "Day",
        < 0.85f => "Dusk",
        _ => "Night",
    };

    private void OnEventsEmitted(List<string> events)
    {
        foreach (string evt in events) AppendLog(evt);
    }

    private void AppendLog(string message)
    {
        if (_eventLog == null) return;
        string current = _eventLog.Text ?? "";
        if (!string.IsNullOrEmpty(current)) current += "\n";
        // Keep last 20 lines
        var lines = (current + message).Split('\n');
        if (lines.Length > 20)
        {
            current = string.Join('\n', lines[^20..]);
            _eventLog.Text = current;
        }
        else
        {
            _eventLog.Text = current + message;
        }
    }
}
