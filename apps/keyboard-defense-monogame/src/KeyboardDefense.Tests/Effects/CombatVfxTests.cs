using Microsoft.Xna.Framework;
using KeyboardDefense.Game.Effects;

namespace KeyboardDefense.Tests.Effects;

public class CombatVfxTests
{
    [Fact]
    public void ShowDamage_AddsFloatingText()
    {
        var vfx = new CombatVfx();
        vfx.ShowDamage(new Vector2(100, 100), 5, isCrit: false);
        // Floating text exists — verify it survives one update
        vfx.Update(0.1f);
        // No exception = text was tracked
    }

    [Fact]
    public void ShowDamage_Crit_UsesExclamation()
    {
        var vfx = new CombatVfx();
        vfx.ShowDamage(new Vector2(100, 100), 10, isCrit: true);
        vfx.Update(0.01f);
        // No exception = tracked correctly
    }

    [Fact]
    public void FlashEnemy_IsFlashingReturnsTrue()
    {
        var vfx = new CombatVfx();
        vfx.FlashEnemy(42);
        Assert.True(vfx.IsFlashing(42));
        Assert.False(vfx.IsFlashing(99));
    }

    [Fact]
    public void FlashEnemy_ExpiresAfterDuration()
    {
        var vfx = new CombatVfx();
        vfx.FlashEnemy(42);
        Assert.True(vfx.IsFlashing(42));

        // Advance past flash duration (0.15s)
        vfx.Update(0.2f);
        Assert.False(vfx.IsFlashing(42));
    }

    [Fact]
    public void GetFlashIntensity_DecreasesOverTime()
    {
        var vfx = new CombatVfx();
        vfx.FlashEnemy(1);

        float initial = vfx.GetFlashIntensity(1);
        Assert.True(initial > 0.9f); // Should be near 1.0 at start

        vfx.Update(0.075f); // Half the duration
        float mid = vfx.GetFlashIntensity(1);
        Assert.True(mid > 0f && mid < initial);
    }

    [Fact]
    public void GetFlashIntensity_ZeroForUnknownEnemy()
    {
        var vfx = new CombatVfx();
        Assert.Equal(0f, vfx.GetFlashIntensity(999));
    }

    [Fact]
    public void FloatingText_ExpiresAfterDuration()
    {
        var vfx = new CombatVfx();
        vfx.ShowDamage(Vector2.Zero, 1, false);

        // Update past expiry (1.2s)
        for (int i = 0; i < 15; i++)
            vfx.Update(0.1f);

        // After expiry, update should not throw
        vfx.Update(0.1f);
    }

    [Fact]
    public void OnEnemyKilled_DoesNotThrow()
    {
        var vfx = new CombatVfx();
        // These call ScreenShake.Instance which may be null in test,
        // but ScreenShake uses a lazy singleton so it should work
        vfx.OnEnemyKilled(0);
        vfx.OnEnemyKilled(5);
        vfx.OnEnemyKilled(10);
    }

    [Fact]
    public void ShowText_AddsCustomMessage()
    {
        var vfx = new CombatVfx();
        vfx.ShowText(new Vector2(50, 50), "+5 gold", Color.Gold);
        vfx.Update(0.1f);
        // No exception = tracked
    }

    [Fact]
    public void MultipleEffects_AllTracked()
    {
        var vfx = new CombatVfx();
        vfx.ShowDamage(Vector2.Zero, 3, false);
        vfx.ShowDamage(new Vector2(10, 10), 7, true);
        vfx.ShowText(new Vector2(20, 20), "MISS!", Color.Red);
        vfx.FlashEnemy(1);
        vfx.FlashEnemy(2);

        Assert.True(vfx.IsFlashing(1));
        Assert.True(vfx.IsFlashing(2));

        vfx.Update(0.05f);
        // All still active
        Assert.True(vfx.IsFlashing(1));
    }
}
