using KeyboardDefense.Game.Rendering;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Rendering;

/// <summary>
/// Tests for HudPainter and HudBarOverlay (non-draw logic).
/// Draw methods require a GraphicsDevice so we test initialization guards and state.
/// </summary>
public class HudOverlayTests
{
    [Fact]
    public void HudPainter_IsReady_FalseBeforeInitialize()
    {
        var painter = new HudPainter();
        Assert.False(painter.IsReady);
        Assert.Null(painter.Font);
    }

    [Fact]
    public void HudBarOverlay_CanInstantiate()
    {
        var overlay = new HudBarOverlay();
        Assert.NotNull(overlay);
        Assert.False(overlay.BuildMode);
    }

    [Fact]
    public void HudBarOverlay_BuildMode_CanToggle()
    {
        var overlay = new HudBarOverlay();
        overlay.BuildMode = true;
        Assert.True(overlay.BuildMode);
        overlay.BuildMode = false;
        Assert.False(overlay.BuildMode);
    }

    [Fact]
    public void MinimapRenderer_ViewportRange_DefaultNull()
    {
        var renderer = new MinimapRenderer();
        Assert.Null(renderer.ViewportRange);
    }

    [Fact]
    public void MinimapRenderer_ViewportRange_CanSet()
    {
        var renderer = new MinimapRenderer();
        renderer.ViewportRange = (5, 5, 20, 20);
        Assert.NotNull(renderer.ViewportRange);
        Assert.Equal((5, 5, 20, 20), renderer.ViewportRange.Value);
    }

    [Fact]
    public void MinimapRenderer_DefaultSize_Is200()
    {
        var renderer = new MinimapRenderer();
        Assert.Equal(200, renderer.MinimapSize);
        Assert.Equal(2, renderer.BorderWidth);
    }

    [Fact]
    public void InlineCombatOverlay_Reset_ClearsCombo()
    {
        var overlay = new InlineCombatOverlay();
        overlay.Reset();
        // No exception — internal state cleared
    }

    [Fact]
    public void InlineCombatOverlay_Update_IgnoresNonEncounter()
    {
        var overlay = new InlineCombatOverlay();
        var state = new GameState();
        state.ActivityMode = "exploration";
        overlay.Update(0.1f, state);
        // No exception — skips encounter-only logic
    }
}
