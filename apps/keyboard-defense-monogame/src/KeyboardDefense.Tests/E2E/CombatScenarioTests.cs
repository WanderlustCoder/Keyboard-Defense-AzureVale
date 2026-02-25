using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.E2E;

public class CombatScenarioTests
{
    [Fact]
    public void FullWaveDefense_FromSetupToVictory_ReachesDawn()
    {
        var sim = new GameSimulator("combat_wave_victory");
        int startGold = sim.State.Gold;

        sim.EndDay();
        Assert.Equal("night", sim.State.Phase);

        var result = sim.RunNightToCompletion(maxSteps: 200);

        Assert.Equal("day", result.EndPhase);
        Assert.True(result.EnemiesKilled > 0, "Expected at least one enemy defeat.");
        Assert.True(result.WordsTyped > 0, "Expected at least one typed word.");
        Assert.True(result.EndHp > 0, "Expected to survive the wave.");
        Assert.True(sim.State.Gold >= startGold, "Gold should not decrease after a successful defense.");
        Assert.Contains(sim.AllEvents, e => e.Contains("Dawn breaks.", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void DefeatScenario_EnemiesOverwhelmDefenses_EndsInGameOver()
    {
        var sim = new GameSimulator("combat_wave_defeat");
        sim.State.Structures.Clear();
        sim.State.Hp = 4;

        sim.EndDay();
        Assert.Equal("night", sim.State.Phase);

        sim.State.Enemies.Clear();
        sim.State.NightSpawnRemaining = 0;
        sim.State.NightWaveTotal = 1;
        sim.State.Enemies.Add(new Dictionary<string, object>
        {
            ["id"] = 9001,
            ["word"] = "warlord",
            ["hp"] = 50,
            ["max_hp"] = 50,
            ["dist"] = 1,
            ["damage"] = 4,
            ["gold"] = 0,
            ["alive"] = true,
        });

        var events = sim.Wait();

        Assert.Equal("game_over", sim.State.Phase);
        Assert.Equal(0, sim.State.Hp);
        Assert.Contains(events, e => e.Contains("Enemy reached the base!", StringComparison.OrdinalIgnoreCase));
        Assert.Contains(sim.AllEvents, e => e.Contains("Game Over.", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void TowerPlacementSynergy_KillBoxBoostChangesLethality()
    {
        var state = CreateSynergyState(TowerTypes.Cannon, TowerTypes.Frost);
        var active = SynergyDetector.DetectActiveSynergies(state);
        Assert.Contains("kill_box", active);

        int baseDamage = TowerTypes.GetTowerData(TowerTypes.Cannon)!.Damage;
        double multiplier = SynergyDetector.GetSynergyDamageMultiplier(active);
        int boostedDamage = ScaleDamage(baseDamage, multiplier);

        var withoutSynergy = new List<Dictionary<string, object>> { CreateCombatEnemy(id: 1, hp: 8, word: "ash") };
        var withSynergy = new List<Dictionary<string, object>> { CreateCombatEnemy(id: 2, hp: 8, word: "ash") };

        TowerCombat.ProcessSingleAttack(
            state,
            CreateTower(name: "Siege Cannon", category: "single", damage: baseDamage, damageType: "siege"),
            withoutSynergy,
            new List<string>());

        TowerCombat.ProcessSingleAttack(
            state,
            CreateTower(name: "Siege Cannon", category: "single", damage: boostedDamage, damageType: "siege"),
            withSynergy,
            new List<string>());

        Assert.Equal(2, EnemyHp(withoutSynergy[0]));
        Assert.True(EnemyHp(withSynergy[0]) <= 0);
        Assert.True(IsAlive(withoutSynergy[0]));
        Assert.False(IsAlive(withSynergy[0]));
    }

    [Fact]
    public void TowerPlacementSynergy_StackingArrowRainWithKillBoxImprovesOutcome()
    {
        var killBoxState = CreateSynergyState(TowerTypes.Cannon, TowerTypes.Frost);
        var stackedState = CreateSynergyState(
            TowerTypes.Cannon,
            TowerTypes.Frost,
            TowerTypes.Arrow,
            TowerTypes.Arrow,
            TowerTypes.Arrow);

        var killBoxSynergies = SynergyDetector.DetectActiveSynergies(killBoxState);
        var stackedSynergies = SynergyDetector.DetectActiveSynergies(stackedState);

        Assert.Contains("kill_box", killBoxSynergies);
        Assert.Contains("kill_box", stackedSynergies);
        Assert.Contains("arrow_rain", stackedSynergies);

        double killBoxMultiplier = SynergyDetector.GetSynergyDamageMultiplier(killBoxSynergies);
        double stackedMultiplier = SynergyDetector.GetSynergyDamageMultiplier(stackedSynergies);
        Assert.True(stackedMultiplier > killBoxMultiplier);

        int baseDamage = TowerTypes.GetTowerData(TowerTypes.Cannon)!.Damage;
        int killBoxDamage = ScaleDamage(baseDamage, killBoxMultiplier);
        int stackedDamage = ScaleDamage(baseDamage, stackedMultiplier);

        var killBoxEnemy = new List<Dictionary<string, object>> { CreateCombatEnemy(id: 3, hp: 9, word: "elm") };
        var stackedEnemy = new List<Dictionary<string, object>> { CreateCombatEnemy(id: 4, hp: 9, word: "elm") };

        TowerCombat.ProcessSingleAttack(
            killBoxState,
            CreateTower(name: "Siege Cannon", category: "single", damage: killBoxDamage, damageType: "siege"),
            killBoxEnemy,
            new List<string>());

        TowerCombat.ProcessSingleAttack(
            stackedState,
            CreateTower(name: "Siege Cannon", category: "single", damage: stackedDamage, damageType: "siege"),
            stackedEnemy,
            new List<string>());

        Assert.True(EnemyHp(killBoxEnemy[0]) > 0);
        Assert.True(EnemyHp(stackedEnemy[0]) <= 0);
    }

    [Fact]
    public void SpecialCommand_OverchargeDoublesTowerDamageDuringCombat()
    {
        var command = SpecialCommands.GetCommand("overcharge");
        Assert.NotNull(command);
        Assert.True(SpecialCommands.IsValidCommand("overcharge"));
        Assert.Contains("overcharge", SpecialCommands.GetUnlockedCommands(command!.UnlockLevel));

        int baseDamage = TowerTypes.GetTowerData(TowerTypes.Arrow)!.Damage;
        int overchargedDamage = baseDamage * 2;

        var normalEnemy = new List<Dictionary<string, object>> { CreateCombatEnemy(id: 5, hp: 6, word: "pine") };
        var overchargedEnemy = new List<Dictionary<string, object>> { CreateCombatEnemy(id: 6, hp: 6, word: "pine") };

        TowerCombat.ProcessSingleAttack(
            new GameState(),
            CreateTower(name: "Arrow Tower", category: "single", damage: baseDamage, damageType: "physical"),
            normalEnemy,
            new List<string>());

        TowerCombat.ProcessSingleAttack(
            new GameState(),
            CreateTower(name: "Arrow Tower", category: "single", damage: overchargedDamage, damageType: "physical"),
            overchargedEnemy,
            new List<string>());

        Assert.Equal(3, EnemyHp(normalEnemy[0]));
        Assert.True(EnemyHp(overchargedEnemy[0]) <= 0);
    }

    [Fact]
    public void AutoTargetingPriority_ChangingModeRetargetsAutoTowerAttacks()
    {
        var original = AutoTowerTypes.Towers[AutoTowerTypes.Sentry];

        try
        {
            var nearestState = CreateAutoCombatState(AutoTowerTypes.Sentry);
            nearestState.Enemies.Add(CreateAutoEnemy(101, new GridPoint(1, 0), hp: 10, maxHp: 10));
            nearestState.Enemies.Add(CreateAutoEnemy(102, new GridPoint(3, 0), hp: 30, maxHp: 30));

            var nearestEvents = AutoTowerCombat.ProcessAutoTowers(nearestState, delta: 0.016);

            Assert.Single(nearestEvents);
            Assert.Equal(101, Convert.ToInt32(nearestEvents[0]["target_id"]));
            Assert.Equal(5, EnemyHp(nearestState.Enemies[0]));
            Assert.Equal(30, EnemyHp(nearestState.Enemies[1]));

            AutoTowerTypes.Towers[AutoTowerTypes.Sentry] =
                original with { Targeting = AutoTowerTypes.AutoTargetMode.HighestHp };

            var highestHpState = CreateAutoCombatState(AutoTowerTypes.Sentry);
            highestHpState.Enemies.Add(CreateAutoEnemy(101, new GridPoint(1, 0), hp: 10, maxHp: 10));
            highestHpState.Enemies.Add(CreateAutoEnemy(102, new GridPoint(3, 0), hp: 30, maxHp: 30));

            var highestEvents = AutoTowerCombat.ProcessAutoTowers(highestHpState, delta: 0.016);

            Assert.Single(highestEvents);
            Assert.Equal(102, Convert.ToInt32(highestEvents[0]["target_id"]));
            Assert.Equal(10, EnemyHp(highestHpState.Enemies[0]));
            Assert.Equal(25, EnemyHp(highestHpState.Enemies[1]));
        }
        finally
        {
            AutoTowerTypes.Towers[AutoTowerTypes.Sentry] = original;
        }
    }

    [Fact]
    public void AutoTargetingPriority_SmartModePrefersHighThreatTarget()
    {
        var state = new GameState
        {
            MapW = 10,
            Enemies = new List<Dictionary<string, object>>(),
        };

        int towerIndex = new GridPoint(0, 0).ToIndex(state.MapW);
        state.Enemies.Add(CreateAutoEnemy(201, new GridPoint(1, 0), hp: 18, maxHp: 18, speed: 1.0, damage: 1, kind: "scout"));
        state.Enemies.Add(CreateAutoEnemy(202, new GridPoint(4, 0), hp: 70, maxHp: 100, speed: 2.5, damage: 6, kind: "boss_warlord"));

        var nearest = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Nearest,
            range: 5,
            count: 1);
        var smart = AutoTargeting.PickTargets(
            state,
            towerIndex,
            AutoTowerTypes.AutoTargetMode.Smart,
            range: 5,
            count: 1);

        Assert.Equal(201, Convert.ToInt32(nearest[0]["id"]));
        Assert.Equal(202, Convert.ToInt32(smart[0]["id"]));
    }

    [Fact]
    public void EnemyAndTowerTypeDefinitions_InfluenceDamageOutcome()
    {
        var armored = EnemyTypes.Get("armored");
        Assert.NotNull(armored);

        var arrow = TowerTypes.GetTowerData(TowerTypes.Arrow)!;
        var purifier = TowerTypes.GetTowerData(TowerTypes.Purifier)!;

        var physicalEnemy = new List<Dictionary<string, object>>
        {
            CreateCombatEnemy(id: 301, hp: armored!.Hp, armor: armored.Armor, word: "ore"),
        };
        var purifierEnemy = new List<Dictionary<string, object>>
        {
            CreateCombatEnemy(id: 302, hp: armored.Hp, armor: armored.Armor, word: "ore"),
        };

        TowerCombat.ProcessSingleAttack(
            new GameState(),
            CreateTower(name: arrow.Name, category: "single", damage: arrow.Damage, damageType: "physical"),
            physicalEnemy,
            new List<string>());

        TowerCombat.ProcessSingleAttack(
            new GameState(),
            CreateTower(
                name: purifier.Name,
                category: "single",
                damage: purifier.Damage,
                damageType: purifier.DmgType.ToString().ToLowerInvariant()),
            purifierEnemy,
            new List<string>());

        int physicalDamage = armored.Hp - EnemyHp(physicalEnemy[0]);
        int purifierDamage = armored.Hp - EnemyHp(purifierEnemy[0]);

        Assert.Equal(1, physicalDamage);
        Assert.Equal(7, purifierDamage);
        Assert.True(purifierDamage > physicalDamage);
    }

    private static GameState CreateSynergyState(params string[] towerTypes)
    {
        var state = new GameState();
        state.Structures.Clear();

        for (int i = 0; i < towerTypes.Length; i++)
            state.Structures[i] = towerTypes[i];

        return state;
    }

    private static GameState CreateAutoCombatState(string towerType)
    {
        const int mapWidth = 10;
        int towerIndex = new GridPoint(0, 0).ToIndex(mapWidth);

        return new GameState
        {
            MapW = mapWidth,
            Structures = new Dictionary<int, string>
            {
                [towerIndex] = towerType,
            },
            Enemies = new List<Dictionary<string, object>>(),
            TowerCooldowns = new Dictionary<int, int>(),
        };
    }

    private static Dictionary<string, object> CreateTower(
        string name,
        string category,
        int damage,
        int x = 0,
        int y = 0,
        string targetMode = "nearest",
        string damageType = "physical")
    {
        return new Dictionary<string, object>
        {
            ["name"] = name,
            ["category"] = category,
            ["x"] = x,
            ["y"] = y,
            ["damage"] = damage,
            ["target_mode"] = targetMode,
            ["damage_type"] = damageType,
            ["multi_count"] = 2,
            ["aoe_radius"] = 2,
            ["chain_jumps"] = 3,
            ["chain_range"] = 3,
        };
    }

    private static Dictionary<string, object> CreateCombatEnemy(
        int id,
        int hp,
        string word,
        int x = 1,
        int y = 0,
        int armor = 0)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["x"] = x,
            ["y"] = y,
            ["hp"] = hp,
            ["max_hp"] = hp,
            ["armor"] = armor,
            ["alive"] = true,
            ["word"] = word,
            ["affix"] = "",
            ["effects"] = new List<Dictionary<string, object>>(),
        };
    }

    private static Dictionary<string, object> CreateAutoEnemy(
        int id,
        GridPoint pos,
        int hp,
        int maxHp,
        double speed = 1.0,
        int damage = 1,
        string kind = "")
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["pos"] = pos,
            ["hp"] = hp,
            ["max_hp"] = maxHp,
            ["speed"] = speed,
            ["damage"] = damage,
            ["kind"] = kind,
        };
    }

    private static int ScaleDamage(int baseDamage, double multiplier)
        => Math.Max(1, (int)Math.Floor(baseDamage * multiplier));

    private static int EnemyHp(Dictionary<string, object> enemy)
        => Convert.ToInt32(enemy.GetValueOrDefault("hp", 0));

    private static bool IsAlive(Dictionary<string, object> enemy)
        => Convert.ToBoolean(enemy.GetValueOrDefault("alive", true));
}
