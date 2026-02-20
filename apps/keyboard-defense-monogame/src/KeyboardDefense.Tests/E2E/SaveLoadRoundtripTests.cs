using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.E2E;

/// <summary>
/// Comprehensive save/load round-trip tests exercising full game state.
/// </summary>
public class SaveLoadE2ETests
{
    [Fact]
    public void SaveLoad_MidCampaign_PreservesScalars()
    {
        var sim = new GameSimulator("save_mid");
        sim.RunCampaign(3);

        // Save
        string json = SaveManager.StateToJson(sim.State);
        Assert.NotEmpty(json);

        // Load
        var (ok, loaded, error) = SaveManager.StateFromJson(json);
        Assert.True(ok, $"Load failed: {error}");

        Assert.Equal(sim.State.Day, loaded!.Day);
        Assert.Equal(sim.State.Phase, loaded.Phase);
        Assert.Equal(sim.State.Hp, loaded.Hp);
        Assert.Equal(sim.State.Gold, loaded.Gold);
    }

    [Fact]
    public void SaveLoad_NightPhase_PreservesNightState()
    {
        var sim = new GameSimulator("save_night");
        sim.EndDay();
        Assert.Equal("night", sim.State.Phase);

        string json = SaveManager.StateToJson(sim.State);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.Equal("night", loaded!.Phase);
        Assert.Equal(sim.State.NightPrompt, loaded.NightPrompt);
        Assert.Equal(sim.State.NightSpawnRemaining, loaded.NightSpawnRemaining);
        Assert.Equal(sim.State.NightWaveTotal, loaded.NightWaveTotal);
    }

    [Fact]
    public void SaveLoad_HighDay_PreservesProgress()
    {
        var state = DefaultState.Create("save_high", true);
        state.Day = 25;
        state.Gold = 5000;
        state.Threat = 8;

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.Equal(25, loaded!.Day);
        Assert.Equal(5000, loaded.Gold);
        Assert.Equal(8, loaded.Threat);
    }

    [Fact]
    public void SaveLoad_JsonContainsCollections()
    {
        var sim = new GameSimulator("save_collections");
        sim.Gather("wood");
        sim.Gather("stone");

        string json = SaveManager.StateToJson(sim.State);

        Assert.Contains("resources", json);
        Assert.Contains("terrain", json);
        Assert.Contains("buildings", json);
        Assert.Contains("discovered", json);
    }

    [Fact]
    public void SaveLoad_EmptyState_RoundTrips()
    {
        var state = new GameState();
        state.Day = 1;
        state.Phase = "day";
        state.Hp = 20;

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.Equal(1, loaded!.Day);
        Assert.Equal("day", loaded.Phase);
        Assert.Equal(20, loaded.Hp);
    }

    [Fact]
    public void SaveLoad_WithEnemies_SerializesEnemyData()
    {
        var sim = new GameSimulator("save_enemies");
        sim.EndDay();
        sim.SpawnEnemies();

        string json = SaveManager.StateToJson(sim.State);
        Assert.Contains("enemies", json);

        if (sim.State.Enemies.Count > 0)
        {
            string word = sim.FirstEnemyWord() ?? "";
            if (!string.IsNullOrEmpty(word))
                Assert.Contains(word, json);
        }
    }

    [Fact]
    public void SaveLoad_LessonId_RoundTrips()
    {
        var state = DefaultState.Create("save_lesson_rt", true);
        state.LessonId = "home_row";

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.Equal("home_row", loaded!.LessonId);
    }

    [Fact]
    public void SaveLoad_LessonId_Preserved()
    {
        var state = DefaultState.Create("save_lesson", true);
        state.LessonId = "top_row";

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.Equal("top_row", loaded!.LessonId);
    }

    [Fact]
    public void SaveLoad_MultipleSlots_Independent()
    {
        var state1 = DefaultState.Create("slot_1", true);
        state1.Day = 5;
        state1.Gold = 100;

        var state2 = DefaultState.Create("slot_2", true);
        state2.Day = 15;
        state2.Gold = 2000;

        string json1 = SaveManager.StateToJson(state1);
        string json2 = SaveManager.StateToJson(state2);

        var (ok1, loaded1, _) = SaveManager.StateFromJson(json1);
        var (ok2, loaded2, _) = SaveManager.StateFromJson(json2);

        Assert.True(ok1 && ok2);
        Assert.Equal(5, loaded1!.Day);
        Assert.Equal(15, loaded2!.Day);
        Assert.Equal(100, loaded1.Gold);
        Assert.Equal(2000, loaded2.Gold);
    }

    [Fact]
    public void SaveLoad_InvalidVersion_Rejected()
    {
        string json = "{\"version\":999,\"day\":1,\"phase\":\"day\"}";
        var (ok, _, error) = SaveManager.StateFromJson(json);

        Assert.False(ok);
        Assert.Contains("newer", error!);
    }
}
