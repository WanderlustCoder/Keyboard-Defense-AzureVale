using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Myra.Graphics2D.UI;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI.Components;

namespace KeyboardDefense.Game.UI;

/// <summary>
/// Manages overlay panels with keyboard shortcuts.
/// Screens add their desired panels, and PanelOverlay handles
/// toggling, Escape-to-close, and mutual exclusion.
/// </summary>
public class PanelOverlay
{
    private readonly Panel _rootPanel;
    private readonly List<PanelBinding> _bindings = new();
    private BasePanel? _activePanel;
    private KeyboardState _prevKeyboard;
    private float _dimAlpha;

    private record PanelBinding(string? Action, Keys? FallbackKey, BasePanel Panel);

    // SpriteBatch-drawn overlays
    public NotificationToast Toast { get; } = new();
    public AchievementPopup Achievement { get; } = new();
    public ComboAnnouncement Combo { get; } = new();

    public PanelOverlay(Desktop desktop)
    {
        // Desktop.Root must be a Panel for us to add widgets to it
        _rootPanel = desktop.Root as Panel ?? throw new InvalidOperationException("Desktop.Root must be a Panel");
    }

    /// <summary>Bind a panel to a KeybindManager action (rebindable).</summary>
    public void Bind(string action, BasePanel panel)
    {
        _bindings.Add(new PanelBinding(action, null, panel));
        RegisterPanel(panel);
    }

    /// <summary>Bind a panel to a fixed key (not rebindable, for screen-specific panels).</summary>
    public void Bind(Keys key, BasePanel panel)
    {
        _bindings.Add(new PanelBinding(null, key, panel));
        RegisterPanel(panel);
    }

    private void RegisterPanel(BasePanel panel)
    {
        panel.Closed += () =>
        {
            if (_activePanel == panel) _activePanel = null;
        };
        _rootPanel.Widgets.Add(panel.RootWidget);
    }

    public void Update()
    {
        var kb = Keyboard.GetState();
        var mgr = KeybindManager.Instance;

        // If keybind panel is actively rebinding, delegate all input to it
        if (_activePanel is KeybindPanel kbPanel && kbPanel.IsRebinding)
        {
            kbPanel.UpdateInput();
            _prevKeyboard = kb;
            return;
        }

        // Cancel closes active panel
        if (mgr.IsActionPressed("cancel", kb, _prevKeyboard) && _activePanel != null)
        {
            _activePanel.Close();
            _activePanel = null;
            _prevKeyboard = kb;
            return;
        }

        // Check bound keys (action-based or raw key)
        foreach (var binding in _bindings)
        {
            bool pressed = binding.Action != null
                ? mgr.IsActionPressed(binding.Action, kb, _prevKeyboard)
                : binding.FallbackKey.HasValue && IsKeyPressed(kb, binding.FallbackKey.Value);

            if (pressed)
            {
                if (_activePanel == binding.Panel)
                {
                    binding.Panel.Close();
                    _activePanel = null;
                }
                else
                {
                    _activePanel?.Close();
                    RefreshPanel(binding.Panel);
                    binding.Panel.Open();
                    _activePanel = binding.Panel;
                }
                break;
            }
        }

        _prevKeyboard = kb;
    }

    public void OpenPanel(BasePanel panel)
    {
        _activePanel?.Close();
        RefreshPanel(panel);
        panel.Open();
        _activePanel = panel;
    }

    /// <summary>Update panel animations and background dim.</summary>
    public void UpdateAnimations(float deltaTime)
    {
        float dimTarget = _activePanel != null ? 0.4f : 0f;
        _dimAlpha = MathHelper.Lerp(_dimAlpha, dimTarget, Math.Min(1f, deltaTime * 8f));

        foreach (var binding in _bindings)
            binding.Panel.UpdateAnimation(deltaTime);
    }

    /// <summary>
    /// Draw background dim when a panel is open.
    /// Call between grid rendering and Myra desktop with its own SpriteBatch block.
    /// </summary>
    public void DrawBackgroundDim(SpriteBatch spriteBatch, Texture2D pixel, int screenWidth, int screenHeight)
    {
        if (_dimAlpha < 0.01f) return;
        spriteBatch.Draw(pixel, new Rectangle(0, 0, screenWidth, screenHeight),
            Color.Black * _dimAlpha);
    }

    /// <summary>
    /// Draw SpriteBatch-based overlays (toast, achievement popup, combo text).
    /// Call between spriteBatch.Begin() and spriteBatch.End().
    /// </summary>
    public void DrawOverlays(SpriteBatch spriteBatch, SpriteFont? font, int screenWidth, int screenHeight)
    {
        Toast.Draw(spriteBatch, font, screenWidth);
        Achievement.Draw(spriteBatch, font, screenWidth, screenHeight);
        Combo.Draw(spriteBatch, font, screenWidth, screenHeight);
    }

    public bool HasActivePanel => _activePanel != null;

    private bool IsKeyPressed(KeyboardState current, Keys key)
        => current.IsKeyDown(key) && !_prevKeyboard.IsKeyDown(key);

    private static void RefreshPanel(BasePanel panel)
    {
        var state = GameController.Instance.State;
        switch (panel)
        {
            case BestiaryPanel b:
                b.Refresh(state);
                break;
            case StatsPanel s:
                s.Refresh(state);
                break;
            case SkillsPanel sk:
                sk.Refresh(state);
                break;
            case QuestsPanel q:
                q.Refresh(state);
                break;
            case AchievementPanel a:
                a.Refresh(state);
                break;
            case LootPanel l:
                l.Refresh(state);
                break;
            case EquipmentPanel eq:
                eq.Refresh(state);
                break;
            case ShopPanel sh:
                sh.Refresh(state);
                break;
            case UpgradesPanel up:
                up.Refresh(state);
                break;
            case TradePanel tr:
                tr.Refresh(state);
                break;
            case CraftingPanel cr:
                cr.Refresh(state);
                break;
            case DifficultyPanel df:
                df.Refresh(state);
                break;
            case BuffsPanel bf:
                bf.Refresh(state);
                break;
            case InventoryPanel inv:
                inv.Refresh(state);
                break;
            case ExpeditionPanel exp:
                exp.Refresh(state);
                break;
            case DiplomacyPanel dip:
                dip.Refresh(state);
                break;
            case ResearchPanel res:
                res.Refresh(state);
                break;
            case CitizensPanel cit:
                cit.Refresh(state);
                break;
            case WorkersPanel wrk:
                wrk.Refresh(state);
                break;
            case KeybindPanel kb:
                kb.Refresh();
                break;
            case DamageCalculatorPanel dc:
                dc.Refresh(state);
                break;
            case DailyChallengesPanel daily:
                daily.Refresh(state);
                break;
            case SpellPanel sp:
                sp.Refresh(state);
                break;
            // HelpPanel is static, no refresh needed
        }
    }
}
