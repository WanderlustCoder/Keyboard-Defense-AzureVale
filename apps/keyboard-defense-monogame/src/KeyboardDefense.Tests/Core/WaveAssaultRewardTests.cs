using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.Progression;

namespace KeyboardDefense.Tests.Core;

public class WaveAssaultRewardTests : IDisposable
{
    public WaveAssaultRewardTests()
    {
        TypingProfile.Instance.Reset();
    }

    public void Dispose()
    {
        TypingProfile.Instance.Reset();
    }

    private static GameState CreateWaveState(int waveSize)
    {
        var state = new GameState
        {
            MapW = 16,
            MapH = 16,
            Hp = 20,
            Phase = "night",
            ActivityMode = "wave_assault",
            RngSeed = "wave_test",
            LessonId = "full_alpha",
        };
        state.BasePos = new GridPoint(8, 8);
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;
        state.Terrain.Clear();
        for (int i = 0; i < state.MapW * state.MapH; i++)
            state.Terrain.Add("plains");
        state.NightWaveTotal = waveSize;
        state.NightSpawnRemaining = 0; // all enemies already defeated
        state.Enemies.Clear();
        return state;
    }

    // Test 1: EndWaveAssault awards gold
    [Fact]
    public void EndWaveAssault_AwardsGold()
    {
        // A wave of size 4 should give WaveBaseGold (10) + 4 * WavePerEnemyGold (3) = 22 gold
        var state = CreateWaveState(4);
        int goldBefore = state.Gold;

        // Trigger wave end via WorldTick
        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.True(state.Gold > goldBefore);
        int expectedGold = WorldTick.WaveBaseGold + 4 * WorldTick.WavePerEnemyGold;
        Assert.Equal(expectedGold, state.Gold - goldBefore);
    }

    // Test 2: EndWaveAssault awards resources (wood, stone, food)
    [Fact]
    public void EndWaveAssault_AwardsResources()
    {
        var state = CreateWaveState(6);
        int woodBefore = state.Resources.GetValueOrDefault("wood", 0);
        int stoneBefore = state.Resources.GetValueOrDefault("stone", 0);
        int foodBefore = state.Resources.GetValueOrDefault("food", 0);

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.True(state.Resources["wood"] > woodBefore);
        Assert.True(state.Resources["stone"] > stoneBefore);
        Assert.True(state.Resources["food"] > foodBefore);
    }

    // Test 3: EndWaveAssault increments WavesSurvived
    [Fact]
    public void EndWaveAssault_IncrementsWavesSurvived()
    {
        var state = CreateWaveState(3);
        Assert.Equal(0, state.WavesSurvived);

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.Equal(1, state.WavesSurvived);
    }

    // Test 4: EndWaveAssault resets activity mode to exploration
    [Fact]
    public void EndWaveAssault_ResetsToExploration()
    {
        var state = CreateWaveState(3);
        Assert.Equal("wave_assault", state.ActivityMode);

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.Equal("exploration", state.ActivityMode);
        Assert.Equal("day", state.Phase);
    }

    // Test 5: EndWaveAssault sets wave cooldown
    [Fact]
    public void EndWaveAssault_SetsWaveCooldown()
    {
        var state = CreateWaveState(3);

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.True(state.WaveCooldown > 0);
    }

    // Test 6: EndWaveAssault increments Day
    [Fact]
    public void EndWaveAssault_IncrementsDay()
    {
        var state = CreateWaveState(3);
        int dayBefore = state.Day;

        WorldTick.Tick(state, WorldTick.WorldTickInterval);

        Assert.Equal(dayBefore + 1, state.Day);
    }

    // Test 7: Larger waves give more gold
    [Fact]
    public void EndWaveAssault_LargerWave_MoreGold()
    {
        var smallWave = CreateWaveState(2);
        var largeWave = CreateWaveState(8);

        WorldTick.Tick(smallWave, WorldTick.WorldTickInterval);
        WorldTick.Tick(largeWave, WorldTick.WorldTickInterval);

        Assert.True(largeWave.Gold > smallWave.Gold);
    }

    // Test 8: WavesSurvived serialization roundtrip
    [Fact]
    public void WavesSurvived_SerializationRoundtrip()
    {
        var state = CreateWaveState(3);
        state.WavesSurvived = 5;

        // Use SaveManager to serialize and deserialize
        var dict = KeyboardDefense.Core.Data.SaveManager.StateToDict(state);
        var (ok, loaded, error) = KeyboardDefense.Core.Data.SaveManager.StateFromDict(dict);

        Assert.True(ok);
        Assert.NotNull(loaded);
        Assert.Equal(5, loaded!.WavesSurvived);
    }

    // Test 9: wave_defender quest condition type works
    [Fact]
    public void WaveDefenderQuest_TracksWavesSurvived()
    {
        var state = CreateWaveState(3);
        state.ActivityMode = "exploration"; // set back to exploration for quest check
        state.Phase = "day";
        state.WavesSurvived = 2;

        var (current, target) = WorldQuests.GetProgress(state, "wave_defender");
        Assert.Equal(2, current);
        Assert.Equal(3, target);
    }

    // Test 10: wave_defender quest completes at 3 waves
    [Fact]
    public void WaveDefenderQuest_CompletesAt3Waves()
    {
        var state = CreateWaveState(3);
        state.ActivityMode = "exploration";
        state.Phase = "day";
        state.WavesSurvived = 3;

        var events = WorldQuests.CheckCompletions(state);
        Assert.Contains(events, e => e.Contains("Wave Defender"));
        Assert.Contains("wave_defender", state.CompletedQuests);
    }

    // Test 11: wave event message is emitted
    [Fact]
    public void EndWaveAssault_EmitsRepelledEvent()
    {
        var state = CreateWaveState(3);
        var result = WorldTick.Tick(state, WorldTick.WorldTickInterval);
        var events = (List<string>)result["events"];
        Assert.Contains(events, e => e.Contains("Wave repelled"));
    }
}
