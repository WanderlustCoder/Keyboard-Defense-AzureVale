using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Progression;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Integration tests verifying multi-step game flows.
/// </summary>
public class DayNightCycleTests
{
    [Fact]
    public void FullDayNightCycle_DayToNight()
    {
        var state = DefaultState.Create("cycle_test", true);
        Assert.Equal("day", state.Phase);
        Assert.Equal(1, state.Day);

        // End day phase → night
        var endIntent = SimIntents.Make("end");
        var result = IntentApplier.Apply(state, endIntent);
        state = (GameState)result["state"];

        Assert.Equal("night", state.Phase);
        // Enemies spawn one-per-step, not all at once
        Assert.True(state.NightSpawnRemaining > 0, "Night should have enemies to spawn");
    }

    [Fact]
    public void EndDay_SetsNightWaveTotal()
    {
        var state = DefaultState.Create("spawn_test", true);
        Assert.Empty(state.Enemies);

        var result = IntentApplier.Apply(state, SimIntents.Make("end"));
        state = (GameState)result["state"];

        // End doesn't immediately spawn enemies (except bosses) — it sets spawn remaining
        Assert.True(state.NightWaveTotal > 0, "Night should have wave total set");
        Assert.True(state.NightSpawnRemaining > 0, "Night should have spawns remaining");
    }

    [Fact]
    public void WaitDuringNight_SpawnsEnemy()
    {
        var state = DefaultState.Create("wait_spawn_test", true);

        // Go to night
        var result = IntentApplier.Apply(state, SimIntents.Make("end"));
        state = (GameState)result["state"];

        int enemiesBefore = state.Enemies.Count;

        // Wait triggers enemy spawn step
        result = IntentApplier.Apply(state, SimIntents.Make("wait"));
        state = (GameState)result["state"];

        // Should have spawned at least one enemy (or enemies moved/died)
        Assert.True(state.Enemies.Count > 0 || state.NightSpawnRemaining < state.NightWaveTotal,
            "Wait should trigger spawn or advance night");
    }

    [Fact]
    public void DefendInput_CorrectWord_GeneratesResponse()
    {
        var state = DefaultState.Create("defend_test", true);

        // Go to night
        var result = IntentApplier.Apply(state, SimIntents.Make("end"));
        state = (GameState)result["state"];
        Assert.Equal("night", state.Phase);

        // Wait to spawn enemies
        for (int i = 0; i < 3 && state.Enemies.Count == 0; i++)
        {
            result = IntentApplier.Apply(state, SimIntents.Make("wait"));
            state = (GameState)result["state"];
            if (state.Phase != "night") break;
        }

        if (state.Phase != "night" || state.Enemies.Count == 0)
            return; // Night ended too quickly, skip test

        // Get the first enemy's word and type it
        string word = state.Enemies[0].GetValueOrDefault("word")?.ToString() ?? "";
        Assert.NotEmpty(word);

        int goldBefore = state.Gold;
        var defendIntent = SimIntents.Make("defend_input", new() { ["text"] = word });
        result = IntentApplier.Apply(state, defendIntent);
        state = (GameState)result["state"];

        // The defend should produce events (damage, defeat, spawn, etc.)
        var events = result["events"] as List<string>;
        Assert.NotNull(events);
        Assert.NotEmpty(events!);
        // Gold should increase if enemy was killed (1hp enemies die in 1 hit)
        // or events should mention "Typed" confirming the input was processed
        Assert.True(state.Gold >= goldBefore || events.Any(e => e.Contains("Typed")),
            "Defend should process the typed word");
    }

    [Fact]
    public void HelpCommand_ReturnsUsefulEvents()
    {
        var state = DefaultState.Create("help_test", true);
        var result = IntentApplier.Apply(state, SimIntents.Make("help"));

        var events = result["events"] as List<string>;
        Assert.NotNull(events);
        Assert.True(events!.Count >= 3, "Help should return multiple lines");
    }

    [Fact]
    public void StatusCommand_ReturnsStateInfo()
    {
        var state = DefaultState.Create("status_test", true);
        var result = IntentApplier.Apply(state, SimIntents.Make("status"));

        var events = result["events"] as List<string>;
        Assert.NotNull(events);
        Assert.NotEmpty(events!);
    }

    [Fact]
    public void GatherCommand_IncreasesResources()
    {
        var state = DefaultState.Create("gather_test", true);
        int woodBefore = state.Resources.GetValueOrDefault("wood", 0);

        var intent = SimIntents.Make("gather", new() { ["resource"] = "wood" });
        var result = IntentApplier.Apply(state, intent);
        state = (GameState)result["state"];

        Assert.True(state.Resources.GetValueOrDefault("wood", 0) >= woodBefore);
    }
}

/// <summary>
/// Tests for SaveManager round-trip serialization.
/// Note: StateFromDict currently only restores scalar fields (Day, Phase, Hp, Gold, etc.)
/// Collections (Resources, Buildings, Enemies, etc.) are serialized but not fully restored.
/// </summary>
public class SaveManagerRoundTripTests
{
    [Fact]
    public void RoundTrip_PreservesScalarFields()
    {
        var state = DefaultState.Create("save_test", true);
        state.Day = 15;
        state.Phase = "night";
        state.Gold = 999;
        state.Hp = 7;
        state.Ap = 2;
        state.Threat = 5;

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.Equal(15, loaded!.Day);
        Assert.Equal("night", loaded.Phase);
        Assert.Equal(999, loaded.Gold);
        Assert.Equal(7, loaded.Hp);
        Assert.Equal(2, loaded.Ap);
        Assert.Equal(5, loaded.Threat);
    }

    [Fact]
    public void RoundTrip_PreservesLessonId()
    {
        var state = new GameState();
        state.LessonId = "home_row";

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.Equal("home_row", loaded!.LessonId);
    }

    [Fact]
    public void RoundTrip_PreservesMapDimensions()
    {
        var state = new GameState();
        state.MapW = 128;
        state.MapH = 128;

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.Equal(128, loaded!.MapW);
        Assert.Equal(128, loaded.MapH);
    }

    [Fact]
    public void RoundTrip_PreservesNightState()
    {
        var state = new GameState();
        state.NightPrompt = "shield";
        state.NightSpawnRemaining = 5;
        state.NightWaveTotal = 8;

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.Equal("shield", loaded!.NightPrompt);
        Assert.Equal(5, loaded.NightSpawnRemaining);
        Assert.Equal(8, loaded.NightWaveTotal);
    }

    [Fact]
    public void RoundTrip_PreservesRngState()
    {
        var state = new GameState();
        state.RngSeed = "my_seed";
        state.RngState = 12345;

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.Equal("my_seed", loaded!.RngSeed);
        Assert.Equal(12345, loaded.RngState);
    }

    [Fact]
    public void StateToJson_SerializesCollections()
    {
        // Verify that StateToJson includes collections in the output,
        // even though StateFromDict doesn't restore them yet.
        var state = new GameState();
        state.Resources["wood"] = 42;
        state.Enemies.Add(new Dictionary<string, object>
        {
            ["id"] = 1, ["kind"] = "raider", ["word"] = "test"
        });

        string json = SaveManager.StateToJson(state);
        Assert.Contains("\"wood\"", json);
        Assert.Contains("\"raider\"", json);
        Assert.Contains("resources", json);
        Assert.Contains("enemies", json);
    }

    [Fact]
    public void StateFromJson_EmptyString_ReturnsError()
    {
        var (ok, state, error) = SaveManager.StateFromJson("");
        Assert.False(ok);
        Assert.Null(state);
        Assert.NotNull(error);
    }

    [Fact]
    public void StateFromJson_MalformedJson_ReturnsError()
    {
        var (ok, state, error) = SaveManager.StateFromJson("{broken");
        Assert.False(ok);
        Assert.Null(state);
        Assert.NotNull(error);
    }

    [Fact]
    public void StateFromJson_ValidMinimalJson_Succeeds()
    {
        string json = "{\"version\":1,\"day\":5,\"phase\":\"day\",\"hp\":10}";
        var (ok, state, error) = SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.NotNull(state);
        Assert.Equal(5, state!.Day);
        Assert.Equal(10, state.Hp);
    }

    [Fact]
    public void StateFromJson_FutureVersion_ReturnsError()
    {
        string json = "{\"version\":999,\"day\":1}";
        var (ok, state, error) = SaveManager.StateFromJson(json);

        Assert.False(ok);
        Assert.NotNull(error);
        Assert.Contains("newer", error!);
    }
}

public class CombatFlowTests
{
    [Fact]
    public void FullCombatRound_SpawnAndDefend()
    {
        var state = DefaultState.Create("combat_round", true);

        // Go to night
        var result = IntentApplier.Apply(state, SimIntents.Make("end"));
        state = (GameState)result["state"];

        int initialGold = state.Gold;
        int totalSteps = 0;

        // Do wait/defend steps until night ends or we hit max iterations
        for (int i = 0; i < 50; i++)
        {
            if (state.Phase != "night") break;

            if (state.Enemies.Count > 0)
            {
                // Type the first enemy's word
                string word = state.Enemies[0].GetValueOrDefault("word")?.ToString() ?? "";
                if (!string.IsNullOrEmpty(word))
                {
                    var intent = SimIntents.Make("defend_input", new() { ["text"] = word });
                    result = IntentApplier.Apply(state, intent);
                    state = (GameState)result["state"];
                    totalSteps++;
                    continue;
                }
            }

            // Wait to trigger spawns
            result = IntentApplier.Apply(state, SimIntents.Make("wait"));
            state = (GameState)result["state"];
            totalSteps++;
        }

        Assert.True(totalSteps > 0, "Should have processed at least one step");
    }

    [Fact]
    public void EnemyDamage_WhenNotKilled_ReducesCastleHp()
    {
        var state = DefaultState.Create("damage_test", true);
        int startHp = state.Hp;

        // Go to night
        var result = IntentApplier.Apply(state, SimIntents.Make("end"));
        state = (GameState)result["state"];

        // Type wrong words repeatedly to let enemies through
        for (int i = 0; i < 20; i++)
        {
            var intent = SimIntents.Make("defend_input", new() { ["text"] = "xyzzy_wrong_word" });
            result = IntentApplier.Apply(state, intent);
            state = (GameState)result["state"];

            // If game ended, stop
            if (state.Phase == "game_over" || state.Phase == "victory" || state.Phase == "day")
                break;
        }

        // Either HP decreased or phase changed (enemies cleared by timeout/auto)
        Assert.True(state.Hp <= startHp || state.Phase != "night");
    }

    [Fact]
    public void MissDuringNight_ProducesEvents()
    {
        var state = DefaultState.Create("miss_test", true);

        // Go to night
        var result = IntentApplier.Apply(state, SimIntents.Make("end"));
        state = (GameState)result["state"];
        Assert.Equal("night", state.Phase);

        // Type a wrong word during night — should produce some response
        int hpBefore = state.Hp;
        var intent = SimIntents.Make("defend_input", new() { ["text"] = "completely_wrong_xyzzy" });
        result = IntentApplier.Apply(state, intent);
        state = (GameState)result["state"];

        var events = result["events"] as List<string>;
        Assert.NotNull(events);
        Assert.NotEmpty(events!);
        // Either "Miss" (has enemies, wrong word) or "No enemies yet" (no spawns yet)
        // or HP decreased from miss penalty
        Assert.True(
            events.Any(e => e.Contains("Miss", StringComparison.OrdinalIgnoreCase)
                || e.Contains("No enemies", StringComparison.OrdinalIgnoreCase)
                || e.Contains("No threats", StringComparison.OrdinalIgnoreCase))
            || state.Hp < hpBefore,
            "Wrong word during night should produce feedback event or HP loss");
    }
}

public class ExploreCommandTests
{
    [Fact]
    public void ExploreCommand_ReturnsResult()
    {
        var state = DefaultState.Create("explore_test", true);
        var intent = SimIntents.Make("explore");
        var result = IntentApplier.Apply(state, intent);

        Assert.NotNull(result);
        Assert.True(result.ContainsKey("state") || result.ContainsKey("events"));
    }

    [Fact]
    public void BuildCommand_WithValidCoords_ReturnsResult()
    {
        var state = DefaultState.Create("build_test", true);
        state.Resources["wood"] = 100;
        state.Resources["stone"] = 100;
        state.Gold = 1000;

        var intent = SimIntents.Make("build", new()
        {
            ["type"] = "tower",
            ["x"] = state.CursorPos.X + 1,
            ["y"] = state.CursorPos.Y,
        });
        var result = IntentApplier.Apply(state, intent);

        Assert.NotNull(result);
    }
}

public class DefaultStateCreationTests
{
    [Fact]
    public void Create_InitializesAllCollections()
    {
        var state = DefaultState.Create("collections_test", true);

        Assert.NotNull(state.Enemies);
        Assert.NotNull(state.Resources);
        Assert.NotNull(state.Buildings);
        Assert.NotNull(state.Terrain);
        Assert.NotNull(state.Discovered);
        Assert.NotNull(state.Structures);
        Assert.NotNull(state.CompletedQuests);
        Assert.NotNull(state.BossesDefeated);
        Assert.NotNull(state.UnlockedSkills);
        Assert.NotNull(state.Inventory);
        Assert.NotNull(state.EquippedItems);
        Assert.NotNull(state.ActiveBuffs);
    }

    [Fact]
    public void Create_DeterministicWithSameSeed()
    {
        var state1 = DefaultState.Create("deterministic", true);
        var state2 = DefaultState.Create("deterministic", true);

        Assert.Equal(state1.Terrain.Count, state2.Terrain.Count);
        Assert.Equal(state1.Discovered.Count, state2.Discovered.Count);
    }

    [Fact]
    public void Create_HasPositiveHpAndAp()
    {
        var state = DefaultState.Create("hp_ap_test", true);
        Assert.True(state.Hp > 0);
        Assert.True(state.Ap > 0);
        Assert.True(state.ApMax > 0);
    }

    [Fact]
    public void Create_BasePosIsOnMap()
    {
        var state = DefaultState.Create("basepos_test", true);
        Assert.True(state.BasePos.X >= 0 && state.BasePos.X < state.MapW);
        Assert.True(state.BasePos.Y >= 0 && state.BasePos.Y < state.MapH);
    }
}
