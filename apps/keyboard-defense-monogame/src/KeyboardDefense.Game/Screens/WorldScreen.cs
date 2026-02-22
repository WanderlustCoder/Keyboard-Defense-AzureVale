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
using KeyboardDefense.Game.Audio;
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
    private Panel? _hudBgPanel;

    // Renderers
    private readonly WorldCamera _camera = new();
    private readonly GridRenderer _gridRenderer = new();
    private readonly MinimapRenderer _minimapRenderer = new();
    private readonly PlayerRenderer _playerRenderer = new();
    private readonly DayNightOverlay _dayNightOverlay = new();
    private readonly CombatVfx _combatVfx = new();
    private readonly CombatTransition _combatTransition = new();
    private readonly InlineCombatOverlay _inlineCombatOverlay = new();
    private readonly HarvestChallengeOverlay _harvestChallengeOverlay = new();
    private readonly QuestTrackerHud _questTrackerHud = new();
    private readonly WorldMapRenderer _worldMapRenderer = new();

    // Shared pixel texture for SpriteBatch overlays
    private Texture2D? _pixel;

    // Panels
    private HelpPanel? _helpPanel;
    private SettingsPanel? _settingsPanel;
    private StatsPanel? _statsPanel;
    private BestiaryPanel? _bestiaryPanel;
    private UpgradesPanel? _upgradesPanel;
    private InventoryPanel? _inventoryPanel;
    private SaveLoadPanel? _saveLoadPanel;
    private DialogueBox? _dialogueBox;
    private QuestsPanel? _questsPanel;
    private DailyChallengesPanel? _dailyChallengesPanel;
    private DamageCalculatorPanel? _damageCalcPanel;
    private AutoTowerPanel? _autoTowerPanel;

    // Input row (for toggling visibility by mode)
    private HorizontalStackPanel? _inputRow;

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

    // Audio state tracking
    private string _lastActivityMode = "";

    public WorldScreen(KeyboardDefenseGame game, ScreenManager screenManager)
        : base(game, screenManager) { }

    public override void OnEnter()
    {
        _typingHandler = new TypingInput();
        _typingHandler.Attach(Game.Window);

        // Shared pixel texture
        _pixel = new Texture2D(Game.GraphicsDevice, 1, 1);
        _pixel.SetData(new[] { Color.White });

        // Initialize tilesets and renderers
        TilesetManager.Instance.Initialize(Game.GraphicsDevice, AssetLoader.Instance.TextureRoot);
        _gridRenderer.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        _minimapRenderer.Initialize(Game.GraphicsDevice);
        _playerRenderer.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        _dayNightOverlay.Initialize(Game.GraphicsDevice);
        _gridRenderer.Vfx = _combatVfx;
        _combatTransition.Initialize(Game.GraphicsDevice);
        _inlineCombatOverlay.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        _harvestChallengeOverlay.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        _questTrackerHud.Initialize(Game.GraphicsDevice, Game.DefaultFont);

        // Initialize chunk-based world map renderer
        string chunkDir = System.IO.Path.Combine(System.AppContext.BaseDirectory, "Content", "Textures", "world");
        _worldMapRenderer.Initialize(Game.GraphicsDevice, chunkDir);

        // Use 32px tiles to match spec tile_size; zoom 1.5 to compensate visually
        _gridRenderer.CellSize = 32;
        _playerRenderer.CellSize = 32;
        _gridRenderer.UseChunkBackground = _worldMapRenderer.HasChunks;

        var state = GameController.Instance.State;
        var vp = Game.GraphicsDevice.Viewport;
        _camera.Initialize(vp.Width, vp.Height, state.MapW, state.MapH, _gridRenderer.CellSize);
        _camera.Zoom = 1.5f;
        _camera.SnapTo(state.PlayerPos.X, state.PlayerPos.Y);

        // Start session analytics
        SessionAnalytics.Instance.StartSession();

        var ctrl = GameController.Instance;
        ctrl.StateChanged += OnStateChanged;
        ctrl.EventsEmitted += OnEventsEmitted;

        BuildUi();
        OnStateChanged(ctrl.State);
        AppendLog("You awaken at the castle. Use WASD to explore. E to interact. B to build.");

        // Start exploration music
        _lastActivityMode = state.ActivityMode;
        AudioManager.Instance.PlayMusic(AudioManager.MusicTrack.Calm);
    }

    public override void OnExit()
    {
        _typingHandler?.Detach(Game.Window);
        var ctrl = GameController.Instance;
        ctrl.StateChanged -= OnStateChanged;
        ctrl.EventsEmitted -= OnEventsEmitted;
        _desktop = null;
        _panelOverlay = null;

        AudioManager.Instance.StopMusic();
    }

    public override void Update(GameTime gameTime)
    {
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        var state = GameController.Instance.State;

        _panelOverlay?.Update();
        _panelOverlay?.UpdateAnimations(dt);

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
                    _harvestChallengeOverlay.Hide();
                    AppendLog("Harvest cancelled.");
                    AudioManager.Instance.PlaySfx(AudioManager.Sfx.UiCancel);
                }
            }

            _prevKeyboard = kb;
        }

        // WorldTick drives time, threat, encounters
        var tickResult = WorldTick.Tick(state, dt);
        if (tickResult.TryGetValue("events", out var eventsObj) && eventsObj is List<string> events)
        {
            foreach (string evt in events)
            {
                AppendLog(evt);
                PlayEventSfx(evt);
            }
        }

        // Tick resource node cooldowns
        ResourceChallenge.TickCooldowns(state, dt);

        // Switch music when activity mode changes
        UpdateMusicTrack(state);

        // Update partial typing progress for inline combat word coloring
        if (state.ActivityMode == "encounter")
        {
            string currentInput = _typingInput?.Text ?? "";
            InlineCombat.UpdatePartialProgress(state, currentInput);
        }

        // Update camera
        var vp = Game.GraphicsDevice.Viewport;
        _camera.SetViewport(vp.Width, vp.Height);
        _camera.Follow(state.PlayerPos.X, state.PlayerPos.Y, dt);

        // Update renderers
        _gridRenderer.Update(dt);
        _playerRenderer.Update(dt);
        _combatVfx.Update(dt);
        _combatTransition.Update(dt);
        _inlineCombatOverlay.Update(dt, state);
        _harvestChallengeOverlay.Update(dt);

        // Update input row visibility based on activity mode
        UpdateInputRowVisibility(state);

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

        // Draw pre-rendered chunk background (if available)
        _worldMapRenderer.Draw(spriteBatch, cameraTransform);

        // Update visible range for chunk-aware fog culling
        _gridRenderer.VisibleRange = _camera.GetVisibleTileRange();

        // Draw grid (entities, structures, fog — terrain skipped when chunks are used)
        _gridRenderer.Draw(spriteBatch, state, cameraTransform, new Rectangle(0, 0, vp.Width, vp.Height));

        // Draw player avatar on top of grid
        spriteBatch.Begin(
            transformMatrix: cameraTransform,
            samplerState: SamplerState.PointClamp,
            blendState: BlendState.AlphaBlend);
        _playerRenderer.Draw(spriteBatch, state.PlayerPos.X, state.PlayerPos.Y, state.PlayerFacing);
        spriteBatch.End();

        // Draw combat VFX (floating damage numbers)
        spriteBatch.Begin(
            transformMatrix: cameraTransform,
            samplerState: SamplerState.PointClamp,
            blendState: BlendState.AlphaBlend);
        _combatVfx.Draw(spriteBatch, Game.DefaultFont);
        spriteBatch.End();

        // Day/night overlay
        _dayNightOverlay.Draw(spriteBatch, state.TimeOfDay, vp.Width, vp.Height);

        // Combat transition vignette
        spriteBatch.Begin(blendState: BlendState.AlphaBlend);
        _combatTransition.Draw(spriteBatch, vp.Width, vp.Height);
        spriteBatch.End();

        // Draw minimap in top-right corner
        spriteBatch.Begin(blendState: BlendState.AlphaBlend, samplerState: SamplerState.PointClamp);
        _minimapRenderer.Draw(spriteBatch, state, new Vector2(vp.Width - 210, 10));
        spriteBatch.End();

        // Inline combat overlay (combo, banner, timers)
        spriteBatch.Begin(blendState: BlendState.AlphaBlend);
        _inlineCombatOverlay.Draw(spriteBatch, state, vp.Width, vp.Height);
        spriteBatch.End();

        // Harvest challenge overlay
        if (state.ActivityMode == "harvest_challenge")
        {
            string currentInput = _typingInput?.Text ?? "";
            spriteBatch.Begin(blendState: BlendState.AlphaBlend);
            _harvestChallengeOverlay.Draw(spriteBatch, currentInput, vp.Width, vp.Height);
            spriteBatch.End();
        }

        // Quest tracker HUD
        spriteBatch.Begin(blendState: BlendState.AlphaBlend);
        _questTrackerHud.Draw(spriteBatch, state, vp.Width, vp.Height);
        spriteBatch.End();

        // Background dim when panel is open
        if (_panelOverlay != null && _pixel != null)
        {
            spriteBatch.Begin(blendState: BlendState.AlphaBlend);
            _panelOverlay.DrawBackgroundDim(spriteBatch, _pixel, vp.Width, vp.Height);
            spriteBatch.End();
        }

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
            AudioManager.Instance.PlaySfx(AudioManager.Sfx.UiOpen);
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
                AudioManager.Instance.PlayUiConfirm();

                // Build dialogue lines and show in DialogueBox
                string speaker = npcResult.GetValueOrDefault("speaker")?.ToString() ?? "NPC";
                string npcType = npcResult.GetValueOrDefault("npc_type")?.ToString() ?? "";

                if (npcResult.GetValueOrDefault("lines") is List<string> lines && _dialogueBox != null)
                {
                    // Convert to DialogueLine records for the dialogue box
                    var dialogueLines = new List<DialogueLine>();
                    foreach (string line in lines)
                    {
                        // Lines often come as "Name: message" — parse speaker if present
                        int colonIdx = line.IndexOf(':');
                        if (colonIdx > 0 && colonIdx < 20)
                        {
                            dialogueLines.Add(new DialogueLine(
                                line[..colonIdx].Trim(),
                                line[(colonIdx + 1)..].Trim()));
                        }
                        else
                        {
                            dialogueLines.Add(new DialogueLine(speaker, line));
                        }
                    }

                    _dialogueBox.SetSpeakerPortrait(npcType);
                    _dialogueBox.StartDialogue(dialogueLines);

                    // Also log for history
                    foreach (string line in lines)
                        AppendLog(line);
                }

                // Auto-complete ready quests when talking to NPCs
                var questEvents = NpcInteraction.CompleteReadyQuests(state);
                foreach (string evt in questEvents)
                {
                    AppendLog(evt);
                    AudioManager.Instance.PlaySfx(AudioManager.Sfx.QuestComplete);
                }
                return;
            }

            // Then try resource harvest
            var harvestResult = ResourceChallenge.StartChallenge(state);
            if (harvestResult != null)
            {
                string nodeName = harvestResult.GetValueOrDefault("node_name")?.ToString() ?? "node";
                string word = harvestResult.GetValueOrDefault("word")?.ToString() ?? "";
                string resource = harvestResult.GetValueOrDefault("resource")?.ToString() ?? "wood";
                AppendLog($"Harvesting {nodeName}! Type: {word}");
                AudioManager.Instance.PlaySfx(AudioManager.Sfx.Gather);
                _harvestChallengeOverlay.Show(word, nodeName, resource);
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
            AudioManager.Instance.PlaySfx(AudioManager.Sfx.UiCancel);
            return;
        }

        // Left/Right cycle building selection
        if (IsKeyPressed(kb, Keys.Left) || IsKeyPressed(kb, Keys.A))
        {
            _buildMenuIndex = (_buildMenuIndex - 1 + BuildMenuItems.Length) % BuildMenuItems.Length;
            AppendLog($"Selected: {BuildMenuItems[_buildMenuIndex]}");
            AudioManager.Instance.PlayUiHover();
        }
        else if (IsKeyPressed(kb, Keys.Right) || IsKeyPressed(kb, Keys.D))
        {
            _buildMenuIndex = (_buildMenuIndex + 1) % BuildMenuItems.Length;
            AppendLog($"Selected: {BuildMenuItems[_buildMenuIndex]}");
            AudioManager.Instance.PlayUiHover();
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
            AudioManager.Instance.PlaySfx(building == "tower"
                ? AudioManager.Sfx.TowerBuild
                : AudioManager.Sfx.Build);
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
        AudioManager.Instance.PlaySfx(AudioManager.Sfx.Explore, -0.3f);
    }

    private void SubmitTyping()
    {
        string text = _typingInput?.Text?.Trim() ?? "";
        if (string.IsNullOrEmpty(text)) return;
        if (_typingInput != null) _typingInput.Text = "";

        var state = GameController.Instance.State;

        if (state.ActivityMode == "encounter")
        {
            int hpBefore = state.EncounterEnemies.Count > 0
                ? Convert.ToInt32(state.EncounterEnemies[0].GetValueOrDefault("hp", 0))
                : 0;
            int enemyCountBefore = state.EncounterEnemies.Count;

            var events = InlineCombat.ProcessTyping(state, text);
            foreach (string evt in events)
                AppendLog(evt);
            SessionAnalytics.Instance.RecordEvent("word_typed");

            // VFX: check what happened
            if (events.Count > 0 && !events[0].StartsWith("Miss"))
            {
                // Find the target enemy position for floating text
                // Parse damage from event string
                var playerWorldPos = _gridRenderer.TileCenter(state.PlayerPos);
                var targetPos = playerWorldPos + new Vector2(48, 0);

                // Extract damage number from event text
                int damage = 0;
                foreach (string evt in events)
                {
                    int parenIdx = evt.LastIndexOf('(');
                    int spaceIdx = evt.LastIndexOf(" damage");
                    if (parenIdx >= 0 && spaceIdx > parenIdx)
                    {
                        string numStr = evt.Substring(parenIdx + 1, spaceIdx - parenIdx - 1);
                        int.TryParse(numStr, out damage);
                    }
                }

                bool killed = enemyCountBefore > state.EncounterEnemies.Count;
                int combo = Core.Typing.TypingMetrics.GetComboCount(state);

                if (damage > 0)
                {
                    _combatVfx.ShowDamage(targetPos, damage, combo >= 5);
                    AudioManager.Instance.PlaySfx(AudioManager.Sfx.EnemyHit);
                }

                // Flash the first encounter enemy (the one that was hit)
                if (state.EncounterEnemies.Count > 0)
                {
                    int eid = Convert.ToInt32(state.EncounterEnemies[0].GetValueOrDefault("id", 0));
                    _combatVfx.FlashEnemy(eid);
                }

                if (killed)
                {
                    _combatVfx.OnEnemyKilled(combo);
                    _combatVfx.CheckComboAnnouncement(combo, _panelOverlay!.Combo);
                    AudioManager.Instance.PlayEnemyDeath();

                    if (combo > 1)
                        AudioManager.Instance.PlayComboUp();

                    // Show gold reward as floating text
                    foreach (string evt in events)
                    {
                        if (evt.Contains("gold"))
                        {
                            _combatVfx.ShowText(targetPos + new Vector2(0, 20), evt.Split('!')[0] + "!", ThemeColors.GoldAccent);
                            AudioManager.Instance.PlaySfx(AudioManager.Sfx.GoldPickup);
                            break;
                        }
                    }
                }
            }
            else if (events.Count > 0)
            {
                AudioManager.Instance.PlaySfx(AudioManager.Sfx.MissWhiff);
            }

            CheckDailyChallenges(state);
            CheckQuestCompletions(state);
        }
        else if (state.ActivityMode == "harvest_challenge")
        {
            var events = ResourceChallenge.ProcessChallengeInput(state, text);
            foreach (string evt in events)
                AppendLog(evt);
            SessionAnalytics.Instance.RecordEvent("word_typed");
            AudioManager.Instance.PlayWordComplete();
            _harvestChallengeOverlay.Hide();
        }
        else if (state.ActivityMode == "wave_assault")
        {
            var intent = SimIntents.Make("defend_input", new() { ["text"] = text });
            GameController.Instance.ApplyIntent(intent);
            SessionAnalytics.Instance.OnGameEvent(GameController.Instance.LastEvents);
            SessionAnalytics.Instance.RecordEvent("word_typed");
            CheckDailyChallenges(state);
            CheckQuestCompletions(state);
        }
    }

    private void UpdateMusicTrack(GameState state)
    {
        if (state.ActivityMode == _lastActivityMode) return;

        // Trigger combat transition effects on mode change
        switch (state.ActivityMode)
        {
            case "encounter":
                _combatTransition.TriggerEnter();
                break;
            case "exploration" when _lastActivityMode == "encounter":
                _combatTransition.TriggerExit();
                _inlineCombatOverlay.Reset();
                break;
        }

        var audio = AudioManager.Instance;
        switch (state.ActivityMode)
        {
            case "exploration":
                audio.StopDucking();
                audio.PlayMusic(AudioManager.MusicTrack.Calm);
                break;
            case "encounter":
                audio.StartDucking();
                audio.PlayMusic(AudioManager.MusicTrack.Battle);
                break;
            case "wave_assault":
                audio.StartDucking();
                audio.PlayMusic(AudioManager.MusicTrack.BattleTense);
                break;
            case "harvest_challenge":
                // Keep current music, just duck slightly
                audio.StartDucking();
                break;
        }

        _lastActivityMode = state.ActivityMode;
    }

    private void UpdateInputRowVisibility(GameState state)
    {
        if (_inputRow == null) return;

        // Show input row during combat/typing modes, hide during exploration
        bool showInput = state.ActivityMode is "encounter" or "wave_assault" or "harvest_challenge";
        _inputRow.Visible = showInput;
    }

    private static void PlayEventSfx(string evt)
    {
        var audio = AudioManager.Instance;

        if (evt.Contains("WAVE ASSAULT"))
            audio.PlaySfx(AudioManager.Sfx.WaveStart);
        else if (evt.Contains("Wave repelled"))
            audio.PlaySfx(AudioManager.Sfx.WaveComplete);
        else if (evt.Contains("Encounter!"))
            audio.PlaySfx(AudioManager.Sfx.EnemySpawn);
        else if (evt.Contains("dawn") || evt.Contains("Dawn"))
            audio.PlaySfx(AudioManager.Sfx.DawnBreak);
        else if (evt.Contains("dusk") || evt.Contains("Dusk") || evt.Contains("nightfall"))
            audio.PlaySfx(AudioManager.Sfx.NightFall);
        else if (evt.Contains("level up") || evt.Contains("Level up"))
            audio.PlaySfx(AudioManager.Sfx.LevelUp);
    }

    private void BuildUi()
    {
        var rootPanel = new Panel();
        var mainLayout = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };

        // Top HUD bar with dark semi-transparent background
        _hudBgPanel = new Panel
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Height = 32,
            Background = new Myra.Graphics2D.Brushes.SolidBrush(Color.Black * 0.5f),
        };
        var hudBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        _dayLabel = new Label { Text = "Day 1", TextColor = ThemeColors.Accent };
        _hpLabel = new Label { Text = "HP: 10", TextColor = ThemeColors.Success };
        _goldLabel = new Label { Text = "Gold: 0", TextColor = ThemeColors.GoldAccent };
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
        _hudBgPanel.Widgets.Add(hudBar);
        mainLayout.Widgets.Add(_hudBgPanel);
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
        _inputRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm, Visible = false };
        _inputRow.Widgets.Add(new Label { Text = "> ", TextColor = ThemeColors.AccentCyan });
        _typingInput = new TextBox { HorizontalAlignment = HorizontalAlignment.Stretch };
        _inputRow.Widgets.Add(_typingInput);
        var submitBtn = new Button
        {
            Content = new Label { Text = Locale.Tr("actions.submit") },
            Width = 100,
            Height = DesignSystem.SizeButtonMd,
        };
        submitBtn.Click += (_, _) => SubmitTyping();
        _inputRow.Widgets.Add(submitBtn);

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
        AddBtn("Challenges", () => {
            _dailyChallengesPanel?.Refresh(GameController.Instance.State);
            _panelOverlay?.OpenPanel(_dailyChallengesPanel!);
        }, 100);
        AddBtn("Towers", () => _panelOverlay?.OpenPanel(_autoTowerPanel!));
        AddBtn("Calc", () => {
            _damageCalcPanel?.Refresh(GameController.Instance.State);
            _panelOverlay?.OpenPanel(_damageCalcPanel!);
        });

        // Layout: HUD at top, grid takes center, log + input + buttons at bottom
        var bottomPanel = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        bottomPanel.VerticalAlignment = VerticalAlignment.Bottom;
        bottomPanel.Widgets.Add(scrollViewer);
        bottomPanel.Widgets.Add(_inputRow);
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
        _dialogueBox = new DialogueBox();
        _questsPanel = new QuestsPanel();
        _dailyChallengesPanel = new DailyChallengesPanel();
        _damageCalcPanel = new DamageCalculatorPanel();
        _autoTowerPanel = new AutoTowerPanel();

        _panelOverlay.Bind("panel_help", _helpPanel);
        _panelOverlay.Bind("panel_settings", _settingsPanel);
        _panelOverlay.Bind("panel_stats", _statsPanel);
        _panelOverlay.Bind("panel_bestiary", _bestiaryPanel);
        _panelOverlay.Bind(Keys.F5, _saveLoadPanel);
        _panelOverlay.Bind(Keys.F7, _upgradesPanel);
        _panelOverlay.Bind("panel_inventory", _inventoryPanel);
        _panelOverlay.Bind("panel_quests", _questsPanel);
        _panelOverlay.Bind("panel_challenges", _dailyChallengesPanel);
        _panelOverlay.Bind("panel_damage_calc", _damageCalcPanel);
        _panelOverlay.Bind("panel_auto_tower", _autoTowerPanel);

        // Register dialogue box as a panel (not key-bound, opened programmatically)
        rootPanel.Widgets.Add(_dialogueBox.RootWidget);
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

    private void CheckDailyChallenges(GameState state)
    {
        var completed = DailyChallenges.CheckProgress(state);
        foreach (string challengeId in completed)
        {
            var result = DailyChallenges.CompleteChallenge(state, challengeId);
            if (result.GetValueOrDefault("ok") is true)
            {
                string msg = result.GetValueOrDefault("message")?.ToString() ?? "Challenge complete!";
                AppendLog(msg);
                _panelOverlay?.Toast.Show(new Notification
                {
                    Message = msg,
                    Type = NotificationManager.NotificationType.Achievement,
                    Duration = 4f,
                });
                AudioManager.Instance.PlaySfx(AudioManager.Sfx.LevelUp);
            }
        }
    }

    private void CheckQuestCompletions(GameState state)
    {
        var events = WorldQuests.CheckCompletions(state);
        foreach (string evt in events)
        {
            AppendLog(evt);
            _panelOverlay?.Toast.Show(new Notification
            {
                Message = evt,
                Type = NotificationManager.NotificationType.Success,
                Duration = 5f,
            });
            AudioManager.Instance.PlaySfx(AudioManager.Sfx.LevelUp);
        }
    }
}
