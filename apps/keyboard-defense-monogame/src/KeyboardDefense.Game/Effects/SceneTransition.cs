using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.Effects;

/// <summary>
/// Screen transition effects (fade, wipe, etc).
/// Ported from game/scene_transition.gd (265 lines).
/// </summary>
public class SceneTransition : IDisposable
{
    /// <summary>
    /// Supported full-screen transition overlay styles.
    /// </summary>
    public enum TransitionType
    {
        Fade, FadeWhite, WipeLeft, WipeRight, WipeUp, WipeDown
    }

    private enum Phase { None, FadeOut, FadeIn }

    private static SceneTransition? _instance;

    /// <summary>
    /// Gets the singleton transition controller instance.
    /// </summary>
    public static SceneTransition Instance => _instance ??= new();

    private const float DefaultDuration = 0.4f;

    private Phase _phase = Phase.None;
    private TransitionType _type = TransitionType.Fade;
    private float _elapsed;
    private float _duration;
    private float _progress; // 0 = no overlay, 1 = full overlay
    private Action? _midpointCallback;
    private Texture2D? _pixel;

    /// <summary>
    /// Occurs when a transition begins its fade-out phase.
    /// </summary>
    public event Action? TransitionStarted;

    /// <summary>
    /// Occurs when a transition reaches full overlay and invokes midpoint work.
    /// </summary>
    public event Action? TransitionMidpoint;

    /// <summary>
    /// Occurs when a transition completes its fade-in phase and clears the overlay.
    /// </summary>
    public event Action? TransitionFinished;

    /// <summary>
    /// Gets a value indicating whether any transition phase is currently active.
    /// </summary>
    public bool IsTransitioning => _phase != Phase.None;

    /// <summary>
    /// Initializes the transition renderer resources.
    /// </summary>
    /// <param name="device">Graphics device used to create a 1x1 white pixel texture for overlays.</param>
    public void Initialize(GraphicsDevice device)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
    }

    /// <summary>
    /// Starts a two-phase transition that linearly fades or wipes out and back in over the provided total duration.
    /// </summary>
    /// <param name="type">Transition visual style to render.</param>
    /// <param name="duration">Total transition duration in seconds, split evenly between fade-out and fade-in phases.</param>
    /// <param name="midpointCallback">Optional callback invoked at full overlay between phases.</param>
    public void StartTransition(TransitionType type, float duration, Action? midpointCallback = null)
    {
        if (_phase != Phase.None) return;

        // Reduce transition duration when reduced motion is enabled
        var sm = KeyboardDefenseGame.Instance?.SettingsManager;
        if (sm != null && sm.ReducedMotion)
            duration = Math.Min(duration * 0.1f, 0.05f);

        _type = type;
        _duration = duration > 0 ? duration : DefaultDuration;
        _elapsed = 0f;
        _progress = 0f;
        _phase = Phase.FadeOut;
        _midpointCallback = midpointCallback;
        TransitionStarted?.Invoke();
    }

    /// <summary>
    /// Starts a transition using the supplied type and duration.
    /// </summary>
    /// <param name="type">Transition visual style to render.</param>
    /// <param name="duration">Total transition duration in seconds.</param>
    public void FadeOut(TransitionType type = TransitionType.Fade, float duration = DefaultDuration)
    {
        StartTransition(type, duration);
    }

    /// <summary>
    /// Starts the standard battle transition with a short black fade and optional midpoint callback.
    /// </summary>
    /// <param name="callback">Optional callback invoked at transition midpoint.</param>
    public void BattleTransition(Action? callback = null)
    {
        StartTransition(TransitionType.Fade, 0.3f, callback);
    }

    /// <summary>
    /// Starts the standard menu transition with a quick black fade and optional midpoint callback.
    /// </summary>
    /// <param name="callback">Optional callback invoked at transition midpoint.</param>
    public void MenuTransition(Action? callback = null)
    {
        StartTransition(TransitionType.Fade, 0.25f, callback);
    }

    /// <summary>
    /// Advances the active transition phase using elapsed frame time.
    /// </summary>
    /// <param name="gameTime">Frame timing information used to accumulate transition progress.</param>
    public void Update(GameTime gameTime)
    {
        if (_phase == Phase.None) return;

        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        _elapsed += dt;
        float halfDuration = _duration * 0.5f;

        if (_phase == Phase.FadeOut)
        {
            _progress = MathHelper.Clamp(_elapsed / halfDuration, 0f, 1f);
            if (_elapsed >= halfDuration)
            {
                _progress = 1f;
                _phase = Phase.FadeIn;
                _elapsed = 0f;
                _midpointCallback?.Invoke();
                _midpointCallback = null;
                TransitionMidpoint?.Invoke();
            }
        }
        else if (_phase == Phase.FadeIn)
        {
            _progress = MathHelper.Clamp(1f - _elapsed / halfDuration, 0f, 1f);
            if (_elapsed >= halfDuration)
            {
                _progress = 0f;
                _phase = Phase.None;
                TransitionFinished?.Invoke();
            }
        }
    }

    /// <summary>
    /// Draws the transition overlay for the current progress and transition type.
    /// </summary>
    /// <param name="spriteBatch">Sprite batch used to render the overlay.</param>
    /// <param name="viewport">Current viewport rectangle covered by the transition effect.</param>
    public void Draw(SpriteBatch spriteBatch, Rectangle viewport)
    {
        if (_phase == Phase.None || _pixel == null || _progress <= 0f) return;

        Color overlayColor = _type == TransitionType.FadeWhite
            ? Color.White * _progress
            : Color.Black * _progress;

        spriteBatch.Begin(blendState: BlendState.AlphaBlend);

        switch (_type)
        {
            case TransitionType.Fade:
            case TransitionType.FadeWhite:
                spriteBatch.Draw(_pixel, viewport, overlayColor);
                break;

            case TransitionType.WipeLeft:
            {
                int w = (int)(viewport.Width * _progress);
                spriteBatch.Draw(_pixel, new Rectangle(0, 0, w, viewport.Height), overlayColor);
                break;
            }
            case TransitionType.WipeRight:
            {
                int w = (int)(viewport.Width * _progress);
                spriteBatch.Draw(_pixel, new Rectangle(viewport.Width - w, 0, w, viewport.Height), overlayColor);
                break;
            }
            case TransitionType.WipeUp:
            {
                int h = (int)(viewport.Height * _progress);
                spriteBatch.Draw(_pixel, new Rectangle(0, 0, viewport.Width, h), overlayColor);
                break;
            }
            case TransitionType.WipeDown:
            {
                int h = (int)(viewport.Height * _progress);
                spriteBatch.Draw(_pixel, new Rectangle(0, viewport.Height - h, viewport.Width, h), overlayColor);
                break;
            }
        }

        spriteBatch.End();
    }

    public void Dispose()
    {
        _pixel?.Dispose();
        _pixel = null;
    }
}
