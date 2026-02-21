using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.E2E;

public class OpenWorldFlowTests
{
    private static GameState CreateWorldState(string seed = "e2e_test")
    {
        var state = DefaultState.Create(seed);
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    // --- Full Loop: Spawn → Move → Encounter → Combat → Defeat → Continue ---

    [Fact]
    public void FullLoop_SpawnMoveEncounterDefeatContinue()
    {
        var state = CreateWorldState();

        // 1. Spawn — player starts at base
        Assert.Equal(state.BasePos, state.PlayerPos);
        Assert.Equal("exploration", state.ActivityMode);

        // 2. Move — walk right
        var result = IntentApplier.Apply(state,
            SimIntents.Make("move_player", new() { ["dx"] = 1, ["dy"] = 0 }));
        state = (GameState)result["state"];
        Assert.Equal(state.BasePos.X + 1, state.PlayerPos.X);

        // 3. Trigger encounter — manually place enemy near player
        state.RoamingEnemies.Clear();
        var enemyPos = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y);
        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = state.EnemyNextId++,
            ["kind"] = "scout",
            ["pos"] = enemyPos,
            ["hp"] = 1,
            ["tier"] = 0,
        });

        // Tick to trigger encounter
        state.WorldTickAccum = 1.5f; // enough for one tick
        var tickResult = WorldTick.Tick(state, 0);
        Assert.Equal("encounter", state.ActivityMode);
        Assert.NotEmpty(state.EncounterEnemies);

        // 4. Combat — type the word to defeat enemy
        string word = state.EncounterEnemies[0].GetValueOrDefault("word")?.ToString() ?? "";
        Assert.False(string.IsNullOrEmpty(word));

        var combatEvents = InlineCombat.ProcessTyping(state, word);
        Assert.NotEmpty(combatEvents);

        // 5. Encounter cleared — back to exploration
        Assert.Equal("exploration", state.ActivityMode);
        Assert.Empty(state.EncounterEnemies);
        Assert.True(state.EnemiesDefeated >= 1);
    }

    // --- Resource Gathering Flow ---

    [Fact]
    public void ResourceFlow_HarvestNodeWithTypingChallenge()
    {
        var state = CreateWorldState();

        // Place a resource node at player position
        int nodeIdx = SimMap.Idx(state.PlayerPos.X, state.PlayerPos.Y, state.MapW);
        state.ResourceNodes[nodeIdx] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove",
            ["pos"] = state.PlayerPos,
            ["zone"] = "safe",
            ["cooldown"] = 0f,
        };

        int woodBefore = state.Resources.GetValueOrDefault("wood", 0);

        // Start harvest challenge
        var challenge = ResourceChallenge.StartChallenge(state);
        Assert.NotNull(challenge);
        Assert.Equal("harvest_challenge", state.ActivityMode);

        // Type the challenge word
        string word = challenge!["word"].ToString()!;
        var events = ResourceChallenge.ProcessChallengeInput(state, word);

        // Resources gained, back to exploration
        Assert.Equal("exploration", state.ActivityMode);
        Assert.True(state.Resources.GetValueOrDefault("wood", 0) > woodBefore);
    }

    // --- Quest Flow ---

    [Fact]
    public void QuestFlow_BuildTowerCompletesQuest()
    {
        var state = CreateWorldState();
        Assert.DoesNotContain("first_tower", state.CompletedQuests);

        // Build a tower
        var pos = new GridPoint(state.BasePos.X + 2, state.BasePos.Y);
        int idx = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Terrain[idx] = SimMap.TerrainPlains;
        state.Discovered.Add(idx);

        var buildResult = IntentApplier.Apply(state, SimIntents.Make("build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y,
        }));
        state = (GameState)buildResult["state"];

        // Check quest completion via WorldQuests
        var (current, target) = WorldQuests.GetProgress(state, "first_tower");
        Assert.True(current >= target, $"first_tower quest: {current}/{target}");

        // Complete quest
        var questEvents = WorldQuests.CheckCompletions(state);
        Assert.Contains("first_tower", state.CompletedQuests);
    }

    // --- Save/Load Roundtrip ---

    [Fact]
    public void SaveLoad_PreservesOpenWorldState()
    {
        var state = CreateWorldState();
        state.TimeOfDay = 0.6f;
        state.ActivityMode = "exploration";
        state.ThreatLevel = 0.35f;
        state.EnemiesDefeated = 7;
        state.MaxComboEver = 12;
        state.CompletedQuests.Add("first_tower");
        state.SkillPoints = 3;

        // Serialize to JSON and back
        string json = SaveManager.StateToJson(state);
        var (ok, loaded, error) = SaveManager.StateFromJson(json);

        Assert.True(ok, error ?? "Save/load failed");
        Assert.NotNull(loaded);

        Assert.Equal(state.PlayerPos, loaded!.PlayerPos);
        Assert.Equal(state.PlayerFacing, loaded.PlayerFacing);
        Assert.Equal(0.6f, loaded.TimeOfDay, 0.01);
        Assert.Equal("exploration", loaded.ActivityMode);
        Assert.Equal(0.35f, loaded.ThreatLevel, 0.01);
        Assert.Equal(7, loaded.EnemiesDefeated);
        Assert.Equal(12, loaded.MaxComboEver);
        Assert.Contains("first_tower", loaded.CompletedQuests);
        Assert.Equal(3, loaded.SkillPoints);
    }

    [Fact]
    public void SaveLoad_PreservesRoamingEnemies()
    {
        var state = CreateWorldState();

        // Verify roaming enemies survive serialization
        int enemyCount = state.RoamingEnemies.Count;
        Assert.True(enemyCount > 0);

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);
        Assert.True(ok);

        Assert.Equal(enemyCount, loaded!.RoamingEnemies.Count);
    }

    [Fact]
    public void SaveLoad_PreservesNpcs()
    {
        var state = CreateWorldState();
        int npcCount = state.Npcs.Count;
        Assert.True(npcCount > 0);

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, _) = SaveManager.StateFromJson(json);
        Assert.True(ok);

        Assert.Equal(npcCount, loaded!.Npcs.Count);
    }

    // --- NPC Interaction Flow ---

    [Fact]
    public void NpcFlow_InteractWithTrainer()
    {
        var state = CreateWorldState();

        // Place trainer NPC adjacent to player
        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "trainer",
            ["pos"] = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y),
            ["name"] = "Master Galen",
        });

        var result = NpcInteraction.TryInteract(state);
        Assert.NotNull(result);
        Assert.Equal("trainer", result!["npc_type"]?.ToString());

        var lines = result["lines"] as List<string>;
        Assert.NotNull(lines);
        Assert.NotEmpty(lines!);
    }

    // --- Day/Night Cycle ---

    [Fact]
    public void DayNightCycle_TimeAdvancesWithWorldTick()
    {
        var state = CreateWorldState();
        float initialTime = state.TimeOfDay;

        // Accumulate enough for several world ticks
        state.WorldTickAccum = 5.0f;
        WorldTick.Tick(state, 0);

        Assert.NotEqual(initialTime, state.TimeOfDay);
    }

    // --- Wave Assault ---

    [Fact]
    public void WaveAssault_TriggersAtHighThreat()
    {
        var state = CreateWorldState();
        state.ThreatLevel = 0.85f;
        state.WaveCooldown = 0;
        state.WorldTickAccum = 1.5f;

        WorldTick.Tick(state, 0);

        Assert.Equal("wave_assault", state.ActivityMode);
    }

    // --- Movement Chained Exploration ---

    [Fact]
    public void MovementChain_WalkAndDiscoverNewTiles()
    {
        var state = CreateWorldState();
        int initialDiscovered = state.Discovered.Count;

        // Move far from base to discover new tiles
        for (int i = 0; i < 8; i++)
        {
            var result = IntentApplier.Apply(state,
                SimIntents.Make("move_player", new() { ["dx"] = 1, ["dy"] = 0 }));
            state = (GameState)result["state"];
        }

        Assert.True(state.Discovered.Count > initialDiscovered,
            "Walking should discover new tiles");
        Assert.Equal(state.BasePos.X + 8, state.PlayerPos.X);
    }
}
