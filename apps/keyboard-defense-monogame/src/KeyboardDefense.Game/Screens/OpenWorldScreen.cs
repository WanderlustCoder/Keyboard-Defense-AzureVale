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
/// Open world exploration mode with map, cursor movement, and events.
/// Ported from game/open_world.gd.
/// </summary>
public class OpenWorldScreen : GameScreen
{
    private Desktop? _desktop;
    private Label? _phaseLabel;
    private Label? _hpLabel;
    private Label? _posLabel;
    private Label? _eventLog;
    private TextBox? _commandInput;
    private TypingInput? _typingHandler;
    private PanelOverlay? _panelOverlay;

    private readonly GridRenderer _gridRenderer = new();
    private readonly MinimapRenderer _minimapRenderer = new();

    private BestiaryPanel? _bestiaryPanel;
    private StatsPanel? _statsPanel;
    private SettingsPanel? _settingsPanel;
    private QuestsPanel? _questsPanel;
    private EquipmentPanel? _equipmentPanel;
    private HelpPanel? _helpPanel;
    private UpgradesPanel? _upgradesPanel;
    private TradePanel? _tradePanel;
    private BuffsPanel? _buffsPanel;
    private InventoryPanel? _inventoryPanel;

    private KeyboardState _prevKeyboard;

    public OpenWorldScreen(KeyboardDefenseGame game, ScreenManager screenManager)
        : base(game, screenManager) { }

    public override void OnEnter()
    {
        _typingHandler = new TypingInput();
        _typingHandler.Attach(Game.Window);

        // Initialize renderers
        _gridRenderer.Initialize(Game.GraphicsDevice, Game.DefaultFont);
        _minimapRenderer.Initialize(Game.GraphicsDevice);

        var ctrl = GameController.Instance;
        ctrl.NewGame($"openworld_{DateTime.Now.Ticks}");
        ctrl.StateChanged += OnStateChanged;
        ctrl.EventsEmitted += OnEventsEmitted;

        BuildUi();
        OnStateChanged(ctrl.State);
        AppendLog(Locale.Tr("openworld.intro"));
        AppendLog(Locale.Tr("openworld.controls"));
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
            _prevKeyboard = kbState;
        }

        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        _gridRenderer.Update(dt);
        NotificationManager.Instance.Update(dt);
        _panelOverlay?.Toast.Update(dt);
    }

    public override void Draw(GameTime gameTime, SpriteBatch spriteBatch)
    {
        var vp = Game.GraphicsDevice.Viewport;
        var state = GameController.Instance.State;

        // Draw grid in the main area
        var gridArea = new Rectangle(0, 50, vp.Width - 220, vp.Height - 120);
        _gridRenderer.Origin = new Vector2(gridArea.X + 10, gridArea.Y + 10);
        _gridRenderer.Draw(spriteBatch, state, Matrix.Identity, gridArea);

        // Draw minimap in top-right corner
        spriteBatch.Begin(blendState: BlendState.AlphaBlend, samplerState: SamplerState.PointClamp);
        _minimapRenderer.Draw(spriteBatch, state, new Vector2(vp.Width - 210, 55));
        spriteBatch.End();

        // Draw Myra UI on top
        _desktop?.Render();

        // Draw panel overlays
        spriteBatch.Begin();
        _panelOverlay?.DrawOverlays(spriteBatch, Game.DefaultFont, vp.Width, vp.Height);
        spriteBatch.End();
    }

    private void BuildUi()
    {
        var rootPanel = new Panel();
        var layout = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };

        // HUD
        var hudBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        _phaseLabel = new Label { Text = $"{Locale.Tr("game.phase")}: day", TextColor = ThemeColors.AccentCyan };
        _hpLabel = new Label { Text = $"{Locale.Tr("resources.hp")}: 20", TextColor = ThemeColors.Success };
        _posLabel = new Label { Text = $"{Locale.Tr("hud.pos")}: (0,0)", TextColor = ThemeColors.TextDim };
        hudBar.Widgets.Add(_phaseLabel);
        hudBar.Widgets.Add(_hpLabel);
        hudBar.Widgets.Add(_posLabel);
        layout.Widgets.Add(hudBar);
        layout.Widgets.Add(new HorizontalSeparator());

        // Event log
        _eventLog = new Label
        {
            Text = "",
            TextColor = ThemeColors.Text,
            Wrap = true,
        };
        var scrollViewer = new ScrollViewer
        {
            Content = _eventLog,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        layout.Widgets.Add(scrollViewer);
        layout.Widgets.Add(new HorizontalSeparator());

        // Command input
        var inputRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        inputRow.Widgets.Add(new Label { Text = "> ", TextColor = ThemeColors.AccentCyan });
        _commandInput = new TextBox { HorizontalAlignment = HorizontalAlignment.Stretch };
        inputRow.Widgets.Add(_commandInput);
        var submitBtn = new Button
        {
            Content = new Label { Text = Locale.Tr("actions.go") },
            Width = 60,
            Height = DesignSystem.SizeButtonMd,
        };
        submitBtn.Click += (_, _) => SubmitCommand();
        inputRow.Widgets.Add(submitBtn);
        layout.Widgets.Add(inputRow);

        // Navigation + panel buttons
        var navBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };

        void AddBtn(string label, Action action, int width = 80)
        {
            var btn = new Button
            {
                Content = new Label { Text = label },
                Width = width,
                Height = DesignSystem.SizeButtonSm,
            };
            btn.Click += (_, _) => action();
            navBar.Widgets.Add(btn);
        }

        AddBtn("N", () => GameController.Instance.ApplyCommand("cursor up"));
        AddBtn("S", () => GameController.Instance.ApplyCommand("cursor down"));
        AddBtn("W", () => GameController.Instance.ApplyCommand("cursor left"));
        AddBtn("E", () => GameController.Instance.ApplyCommand("cursor right"));
        AddBtn(Locale.Tr("actions.inspect"), () => GameController.Instance.ApplyCommand("inspect"));
        AddBtn(Locale.Tr("ui.back"), () => ScreenManager.Pop());
        layout.Widgets.Add(navBar);

        rootPanel.Widgets.Add(layout);
        _desktop = new Desktop { Root = rootPanel };

        // Create panels
        _helpPanel = new HelpPanel();
        _bestiaryPanel = new BestiaryPanel();
        _statsPanel = new StatsPanel();
        _settingsPanel = new SettingsPanel();
        _questsPanel = new QuestsPanel();
        _equipmentPanel = new EquipmentPanel();
        _upgradesPanel = new UpgradesPanel();
        _tradePanel = new TradePanel();
        _buffsPanel = new BuffsPanel();
        _inventoryPanel = new InventoryPanel();

        // Set up panel overlay with hotkeys
        _panelOverlay = new PanelOverlay(_desktop);
        _panelOverlay.Bind("panel_help", _helpPanel);
        _panelOverlay.Bind("panel_settings", _settingsPanel);
        _panelOverlay.Bind("panel_stats", _statsPanel);
        _panelOverlay.Bind("panel_bestiary", _bestiaryPanel);
        _panelOverlay.Bind("panel_quests", _questsPanel);
        _panelOverlay.Bind("panel_equipment", _equipmentPanel);
        _panelOverlay.Bind(Keys.F8, _tradePanel);
        _panelOverlay.Bind("panel_buffs", _buffsPanel);
        _panelOverlay.Bind("panel_inventory", _inventoryPanel);
    }

    private void SubmitCommand()
    {
        string text = _commandInput?.Text?.Trim() ?? "";
        if (string.IsNullOrEmpty(text)) return;
        if (_commandInput != null) _commandInput.Text = "";

        var state = GameController.Instance.State;
        if (state.Phase == "night")
        {
            var intent = SimIntents.Make("defend_input", new() { ["text"] = text });
            GameController.Instance.ApplyIntent(intent);
        }
        else
        {
            GameController.Instance.ApplyCommand(text);
        }
    }

    private void OnStateChanged(GameState state)
    {
        if (_phaseLabel != null) _phaseLabel.Text = $"{Locale.Tr("game.phase")}: {state.Phase}";
        if (_hpLabel != null) _hpLabel.Text = $"{Locale.Tr("resources.hp")}: {state.Hp}";
        if (_posLabel != null) _posLabel.Text = $"{Locale.Tr("hud.pos")}: ({state.CursorPos.X},{state.CursorPos.Y})";
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
